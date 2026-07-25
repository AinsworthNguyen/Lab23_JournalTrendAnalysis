import 'package:equatable/equatable.dart';
import '../../../journal/domain/entities/paper.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();

  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final String name;
  final String interest;
  final String conceptId;
  final DateTime? lastSync;
  final int totalPublications;
  final double avgCitations;
  final int totalCitations;
  final int activeYear;
  final String topJournal;
  final String topAuthor;
  final String mostInfluentialPaper;
  final List<Paper> papers;
  final bool isSyncing;

  const DashboardLoaded({
    required this.name,
    required this.interest,
    required this.conceptId,
    this.lastSync,
    required this.totalPublications,
    required this.avgCitations,
    required this.totalCitations,
    required this.activeYear,
    required this.topJournal,
    required this.topAuthor,
    required this.mostInfluentialPaper,
    required this.papers,
    this.isSyncing = false,
  });

  DashboardLoaded copyWith({
    String? name,
    String? interest,
    String? conceptId,
    DateTime? lastSync,
    int? totalPublications,
    double? avgCitations,
    int? totalCitations,
    int? activeYear,
    String? topJournal,
    String? topAuthor,
    String? mostInfluentialPaper,
    List<Paper>? papers,
    bool? isSyncing,
  }) {
    return DashboardLoaded(
      name: name ?? this.name,
      interest: interest ?? this.interest,
      conceptId: conceptId ?? this.conceptId,
      lastSync: lastSync ?? this.lastSync,
      totalPublications: totalPublications ?? this.totalPublications,
      avgCitations: avgCitations ?? this.avgCitations,
      totalCitations: totalCitations ?? this.totalCitations,
      activeYear: activeYear ?? this.activeYear,
      topJournal: topJournal ?? this.topJournal,
      topAuthor: topAuthor ?? this.topAuthor,
      mostInfluentialPaper: mostInfluentialPaper ?? this.mostInfluentialPaper,
      papers: papers ?? this.papers,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }

  @override
  List<Object?> get props => [
    name,
    interest,
    conceptId,
    lastSync,
    totalPublications,
    avgCitations,
    totalCitations,
    activeYear,
    topJournal,
    topAuthor,
    mostInfluentialPaper,
    papers,
    isSyncing,
  ];
}

class DashboardFailure extends DashboardState {
  final String message;

  const DashboardFailure(this.message);

  @override
  List<Object?> get props => [message];
}
