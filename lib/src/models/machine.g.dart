// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'machine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Machine _$MachineFromJson(Map<String, dynamic> json) => Machine(
      json['id'] as int,
      json['type'] as String,
      json['brand'] as String,
    );

Map<String, dynamic> _$MachineToJson(Machine instance) => <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'brand': instance.brand,
    };
