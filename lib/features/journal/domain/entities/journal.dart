import 'package:equatable/equatable.dart';

class Journal extends Equatable {
  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;
  final String? homepageUrl;
  final String? publisher;

  const Journal({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.citedByCount,
    this.homepageUrl,
    this.publisher,
  });

  @override
  List<Object?> get props => [
    id,
    displayName,
    worksCount,
    citedByCount,
    homepageUrl,
    publisher,
  ];
}
