// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'changed_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChangedFile _$ChangedFileFromJson(Map<String, dynamic> json) => ChangedFile(
      name: json['name'] as String,
      originalPath: json['originalPath'] as String,
      changedPath: json['changedPath'] as String,
      md5Hash: json['md5Hash'] as String,
    );

Map<String, dynamic> _$ChangedFileToJson(ChangedFile instance) =>
    <String, dynamic>{
      'name': instance.name,
      'originalPath': instance.originalPath,
      'changedPath': instance.changedPath,
      'md5Hash': instance.md5Hash,
    };
