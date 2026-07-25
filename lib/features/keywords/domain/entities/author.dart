import 'package:equatable/equatable.dart';

class Author extends Equatable {
  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;
  final String? lastKnownInstitution;

  const Author({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.citedByCount,
    this.lastKnownInstitution,
  });

  @override
  List<Object?> get props => [
    id,
    displayName,
    worksCount,
    citedByCount,
    lastKnownInstitution,
  ];
}
