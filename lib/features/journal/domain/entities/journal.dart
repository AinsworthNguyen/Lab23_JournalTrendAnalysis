import 'package:equatable/equatable.dart';

class Journal extends Equatable {
  final String id;
  final String displayName;
  final int worksCount;
  final int citedByCount;
  final String type;
  final String? homepageUrl;
  final String? publisher;

  const Journal({
    required this.id,
    required this.displayName,
    required this.worksCount,
    required this.citedByCount,
    this.type = 'journal',
    this.homepageUrl,
    this.publisher,
  });

  bool get isConference => type == 'conference';

  @override
  List<Object?> get props => [id, displayName, worksCount, citedByCount, type, homepageUrl, publisher];
}
