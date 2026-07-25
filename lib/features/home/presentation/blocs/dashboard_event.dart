import 'package:equatable/equatable.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();

  @override
  List<Object?> get props => [];
}

class LoadDashboard extends DashboardEvent {}

class SyncDashboard extends DashboardEvent {}

class SelectConceptEvent extends DashboardEvent {
  final String conceptId;
  final String conceptName;

  const SelectConceptEvent({
    required this.conceptId,
    required this.conceptName,
  });

  @override
  List<Object?> get props => [conceptId, conceptName];
}
