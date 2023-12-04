// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pool.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PoolImpl _$$PoolImplFromJson(Map<String, dynamic> json) => _$PoolImpl(
      id: json['id'] as int,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      creatorId: json['creator_id'] as int,
      description: json['description'] as String,
      isActive: json['is_active'] as bool,
      category: $enumDecode(_$CategoryEnumMap, json['category']),
      postIds:
          (json['post_ids'] as List<dynamic>).map((e) => e as int).toList(),
      creatorName: json['creator_name'] as String,
      postCount: json['post_count'] as int,
    );

Map<String, dynamic> _$$PoolImplToJson(_$PoolImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
      'creator_id': instance.creatorId,
      'description': instance.description,
      'is_active': instance.isActive,
      'category': _$CategoryEnumMap[instance.category]!,
      'post_ids': instance.postIds,
      'creator_name': instance.creatorName,
      'post_count': instance.postCount,
    };

const _$CategoryEnumMap = {
  Category.series: 'series',
  Category.collection: 'collection',
};
