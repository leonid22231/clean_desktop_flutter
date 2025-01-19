import 'package:json_annotation/json_annotation.dart';

part 'changed_file.g.dart';

@JsonSerializable()
class ChangedFile extends JsonSerializable{
  String name;
  String originalPath;
  String changedPath;
  String md5Hash;

  ChangedFile({
    required this.name,
    required this.originalPath,
    required this.changedPath,
    required this.md5Hash,
  });
  
  factory ChangedFile.fromJson(Map<String, dynamic> json) =>
      _$ChangedFileFromJson(json);
      
  @override
  Map<String, dynamic> toJson() => _$ChangedFileToJson(this);
}
