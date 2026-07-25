import '../../domain/entities/trend.dart';

class PublicationTrendModel extends PublicationTrend {
  const PublicationTrendModel({required super.year, required super.count});

  factory PublicationTrendModel.fromJson(Map<String, dynamic> json) {
    return PublicationTrendModel(
      year: json['year'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'year': year, 'count': count};
  }
}

class CitationTrendModel extends CitationTrend {
  const CitationTrendModel({required super.year, required super.count});

  factory CitationTrendModel.fromJson(Map<String, dynamic> json) {
    return CitationTrendModel(
      year: json['year'] as int? ?? 0,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'year': year, 'count': count};
  }
}
