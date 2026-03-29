import 'package:equatable/equatable.dart';

/// Modelo de evento completo para Finding Out.
///
/// Mapea 1:1 con la tabla `events` en Supabase.
class Event extends Equatable {
  final String? id;
  final String creatorId;
  final String title;
  final String? description;
  final String categoryId;
  final String? imageUrl;
  final double? locationLat;
  final double? locationLng;
  final String? address;
  final DateTime startDate;
  final DateTime? endDate;
  final String status; // 'draft', 'published', 'cancelled'
  final List<String> tags;
  final bool isPublic;
  final bool allowComments;
  final bool isFree;
  final int? maxCapacity;
  final DateTime? createdAt;

  const Event({
    this.id,
    required this.creatorId,
    required this.title,
    this.description,
    required this.categoryId,
    this.imageUrl,
    this.locationLat,
    this.locationLng,
    this.address,
    required this.startDate,
    this.endDate,
    this.status = 'published',
    this.tags = const [],
    this.isPublic = true,
    this.allowComments = true,
    this.isFree = true,
    this.maxCapacity,
    this.createdAt,
  });

  /// Crea un Event desde un JSON de Supabase.
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] as String?,
      creatorId: json['creator_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      categoryId: json['category_id'] as String,
      imageUrl: json['image_url'] as String?,
      locationLat: (json['location_lat'] as num?)?.toDouble(),
      locationLng: (json['location_lng'] as num?)?.toDouble(),
      address: json['address'] as String?,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      status: json['status'] as String? ?? 'published',
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isPublic: json['is_public'] as bool? ?? true,
      allowComments: json['allow_comments'] as bool? ?? true,
      isFree: json['is_free'] as bool? ?? true,
      maxCapacity: json['max_capacity'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  /// Convierte a JSON para Supabase insert/update.
  /// No incluye `id` ni `created_at` (los genera el servidor).
  Map<String, dynamic> toJson() {
    return {
      'creator_id': creatorId,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'image_url': imageUrl,
      'location_lat': locationLat,
      'location_lng': locationLng,
      'address': address,
      'start_date': startDate.toIso8601String(),
      if (endDate != null) 'end_date': endDate!.toIso8601String(),
      'status': status,
      'tags': tags,
      'is_public': isPublic,
      'allow_comments': allowComments,
      'is_free': isFree,
      if (maxCapacity != null) 'max_capacity': maxCapacity,
    };
  }

  /// Copia con cambios.
  Event copyWith({
    String? id,
    String? creatorId,
    String? title,
    String? description,
    String? categoryId,
    String? imageUrl,
    double? locationLat,
    double? locationLng,
    String? address,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    List<String>? tags,
    bool? isPublic,
    bool? allowComments,
    bool? isFree,
    int? maxCapacity,
    DateTime? createdAt,
  }) {
    return Event(
      id: id ?? this.id,
      creatorId: creatorId ?? this.creatorId,
      title: title ?? this.title,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      imageUrl: imageUrl ?? this.imageUrl,
      locationLat: locationLat ?? this.locationLat,
      locationLng: locationLng ?? this.locationLng,
      address: address ?? this.address,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      allowComments: allowComments ?? this.allowComments,
      isFree: isFree ?? this.isFree,
      maxCapacity: maxCapacity ?? this.maxCapacity,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        creatorId,
        title,
        description,
        categoryId,
        imageUrl,
        locationLat,
        locationLng,
        address,
        startDate,
        endDate,
        status,
        tags,
        isPublic,
        allowComments,
        isFree,
        maxCapacity,
        createdAt,
      ];
}
