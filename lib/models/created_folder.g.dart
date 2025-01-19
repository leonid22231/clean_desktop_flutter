// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'created_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreatedFolder _$CreatedFolderFromJson(Map<String, dynamic> json) =>
    CreatedFolder(
      rootPath: json['rootPath'] as String,
      creatingTime:
          Duration(microseconds: (json['creatingTime'] as num).toInt()),
      createdDate: DateTime.parse(json['createdDate'] as String),
      changedFiles: (json['changedFiles'] as List<dynamic>)
          .map((e) => ChangedFile.fromJson(e as Map<String, dynamic>))
          .toList(),
      path: json['path'] as String,
    );

Map<String, dynamic> _$CreatedFolderToJson(CreatedFolder instance) =>
    <String, dynamic>{
      'rootPath': instance.rootPath,
      'path': instance.path,
      'creatingTime': instance.creatingTime.inMicroseconds,
      'createdDate': instance.createdDate.toIso8601String(),
      'changedFiles': instance.changedFiles,
    };
