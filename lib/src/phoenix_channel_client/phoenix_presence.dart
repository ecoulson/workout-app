import 'dart:convert';

import 'package:app/src/phoenix_channel_client/phoenix_channel.dart';

class PhoenixPresence {
  PhoenixChannel? channel;
  Map<String, dynamic>? opts;
  late PresenceEvents events;
  Map<String, Map<String, dynamic>>? state;
  List pendingDiffs = [];
  String? joinRef;
  late _PresenceCallers _caller;

  static void _noop(key, currentPresence, newPresence) {}

  PhoenixPresence(channel, {this.opts}) {
    opts ??= {};
    events = opts!['events'] ??
        PresenceEvents(PhoenixPresenceEvents.presenceState,
            PhoenixPresenceEvents.presenceDiff);
    state = {};
    joinRef = null;
    _caller = _PresenceCallers(onJoin: _noop, onLeave: _noop, onSync: () {});

    channel!.on(events.state, (newState) {
      joinRef = channel!.joinRef;
      state = Map<String, Map<String, dynamic>>.from(
          syncState(state, newState, _caller.onJoin, _caller.onLeave));

      for (var diff in pendingDiffs) {
        state = Map<String, Map<String, dynamic>>.from(
            syncDiff(state, diff, _caller.onJoin, _caller.onLeave));
      }

      pendingDiffs = [];
      _caller.onSync!();
    });

    channel!.on(events.diff, (diff) {
      if (inPendingSyncState) {
        pendingDiffs.add(diff);
      } else {
        state = Map<String, Map<String, dynamic>>.from(
            syncDiff(state, diff, _caller.onJoin, _caller.onLeave));
        _caller.onSync!();
      }
    });
  }

  onJoin(
          Function(dynamic key, dynamic currentPresence, dynamic newPresence)
              callback) =>
      _caller.onJoin = callback;

  onLeave(
          Function(dynamic key, dynamic currentPresence, dynamic newPresence)
              callback) =>
      _caller.onLeave = callback;

  onSync(Function() callback) => _caller.onSync = callback;

  list({Function? by}) => _list(state, by);

  get inPendingSyncState => joinRef == null || (joinRef != channel!.joinRef);

  static syncState(currentState, newState, onJoinCallback, onLeaveCallback) {
    var state = clone(currentState);
    var joins = {};
    var leaves = {};

    state.forEach((key, presence) {
      if (newState[key] == null) {
        leaves[key] = presence;
      }
    });

    newState.forEach((key, newPresence) {
      var currentPresence = state[key];
      if (currentPresence == null) {
        joins[key] = newPresence;
        return;
      }

      var newRefs = List<Map<String, dynamic>>.from(newPresence['metas'])
          .where((meta) => meta.containsKey('phx_ref'))
          .map((meta) => meta['phx_ref']);

      var curRefs = List<Map<String, dynamic>>.from(currentPresence['metas'])
          .where((meta) => meta.containsKey('phx_ref'))
          .map((meta) => meta['phx_ref']);

      var joinedMetas = newPresence['metas']
          .where((meta) => !curRefs.contains(meta['phx_ref']));
      var leftMetas = currentPresence['metas']
          .where((meta) => !newRefs.contains(meta['phx_ref']));

      if (joinedMetas.length > 0) {
        joins[key] = clone(newPresence);
        joins[key]['metas'] = List<Map<String, dynamic>>.from(joinedMetas);
      }

      if (leftMetas.length > 0) {
        leaves[key] = clone(currentPresence);
        leaves[key]['metas'] = List<Map<String, dynamic>>.from(leftMetas);
      }
    });

    return syncDiff(state, {'joins': joins, 'leaves': leaves}, onJoinCallback,
        onLeaveCallback);
  }

  static syncDiff(currentState, diffs, onJoinCallback, onLeaveCallback) {
    var joins = diffs['joins'] ?? {};
    var leaves = diffs['leaves'] ?? {};
    var state = clone(currentState);
    onJoinCallback ??= _noop;
    onLeaveCallback ??= _noop;

    joins.forEach((key, newPresence) {
      var currentPresence = state[key];
      state[key] = newPresence;
      if (currentPresence != null) {
        var joinedRefs = state[key]['metas']
            .where((Map<String, dynamic> meta) => meta.containsKey('phx_ref'))
            .map((Map<String, dynamic> meta) => meta['phx_ref']);

        var curMetas = List<Map<String, dynamic>>.from(currentPresence['metas']
            .where((meta) => !joinedRefs.contains(meta['phx_ref'])));
        state[key]['metas'].insertAll(0, curMetas);
      }
      onJoinCallback(key, currentPresence, newPresence);
    });

    leaves.forEach((key, leftPresence) {
      var currentPresence = state[key];
      if (currentPresence == null) {
        return;
      }

      var refsToRemove = List.from(leftPresence['metas'])
          .where((meta) => meta.containsKey('phx_ref'))
          .map((meta) => meta['phx_ref']);

      var currentPresenceMetas = List.from(currentPresence['metas']);
      currentPresenceMetas
          .removeWhere((meta) => refsToRemove.contains(meta['phx_ref']));
      currentPresence['metas'] = currentPresenceMetas;

      onLeaveCallback(key, currentPresence, leftPresence);

      if (currentPresence['metas'] == null ||
          currentPresence['metas'].length == 0) {
        state.remove(key);
      }
    });

    return state;
  }

  static _list(presences, chooser) {
    chooser ??= (key, pres) => pres;

    return List.from(presences.entries)
        .map((entry) => chooser(entry.key, entry.value));
  }

  static clone(object) {
    return jsonDecode(jsonEncode(object));
  }
}

class PhoenixPresenceEvents {
  static const presenceState = "presence_state";
  static const presenceDiff = "presence_diff";
}

class PresenceEvents {
  String state = "";
  String diff;
  PresenceEvents(state, this.diff);
}

class _PresenceCallers {
  Function(dynamic key, dynamic currentPresence, dynamic newPresence)? onJoin;
  Function(dynamic key, dynamic currentPresence, dynamic newPresence)? onLeave;
  Function()? onSync;
  _PresenceCallers({onJoin, this.onLeave, this.onSync});
}
