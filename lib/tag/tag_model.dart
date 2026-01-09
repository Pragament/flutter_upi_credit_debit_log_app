import 'package:hive_flutter/hive_flutter.dart';

part 'tag_model.g.dart';

@HiveType(typeId: 7)
class Tag extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;

  Tag({
    required this.id,
    required this.name,
  });

  factory Tag.fromMap(Map<String, dynamic> json) => Tag(
        id: json["id"],
        name: json["name"],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
      };
}
