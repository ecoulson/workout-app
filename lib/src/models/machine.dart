import 'package:json_annotation/json_annotation.dart';

part 'machine.g.dart';

@JsonSerializable()
class Machine {
  Machine(this.id, this.type, this.brand);

  int id;
  String type;
  String brand;

  factory Machine.fromJson(Map<String, dynamic> json) =>
      _$MachineFromJson(json);

  Map<String, dynamic> toJson() => _$MachineToJson(this);
}
