import 'package:equatable/equatable.dart';

class PublicationTrend extends Equatable {
  final int year;
  final int count;

  const PublicationTrend({required this.year, required this.count});

  @override
  List<Object?> get props => [year, count];
}

class CitationTrend extends Equatable {
  final int year;
  final int count;

  const CitationTrend({required this.year, required this.count});

  @override
  List<Object?> get props => [year, count];
}
