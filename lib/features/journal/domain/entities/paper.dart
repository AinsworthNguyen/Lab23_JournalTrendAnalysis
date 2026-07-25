import 'package:equatable/equatable.dart';

class Paper extends Equatable {
  final String id;
  final String title;
  final int publicationYear;
  final int citationCount;
  final String? doi;
  final List<String> authors;
  final List<String> concepts;
  final String? abstractText;
  final String? journalName;
  final bool isOpenAccess;

  const Paper({
    required this.id,
    required this.title,
    required this.publicationYear,
    required this.citationCount,
    this.doi,
    required this.authors,
    required this.concepts,
    this.abstractText,
    this.journalName,
    required this.isOpenAccess,
  });

  @override
  List<Object?> get props => [
    id,
    title,
    publicationYear,
    citationCount,
    doi,
    authors,
    concepts,
    abstractText,
    journalName,
    isOpenAccess,
  ];
}
