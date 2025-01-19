import 'package:clean_desktop/models/changed_file.dart';
import 'package:json_annotation/json_annotation.dart';

part 'created_folder.g.dart';

@JsonSerializable()
class CreatedFolder extends JsonSerializable {
  String rootPath;
  String path;
  Duration creatingTime;
  DateTime createdDate;
  List<ChangedFile> changedFiles;

  CreatedFolder({
    required this.rootPath,
    required this.creatingTime,
    required this.createdDate,
    required this.changedFiles,
    required this.path,
  });

  String get title {
    return Uri.parse(path).pathSegments.lastWhere((s) => s.isNotEmpty);
  }

  factory CreatedFolder.fromJson(Map<String, dynamic> json) =>
      _$CreatedFolderFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$CreatedFolderToJson(this);
}
