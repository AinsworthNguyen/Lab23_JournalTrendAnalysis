import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../injection_container.dart';
import '../../../admin/data/datasources/user_activity_tracker.dart';
import '../../domain/repositories/report_repository.dart';
import 'report_state.dart';

@injectable
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._reportRepository) : super(ReportInitial());

  final ReportRepository _reportRepository;

  Future<void> exportReport({
    required final String conceptName,
    required final String fullName,
    required final int totalPublications,
    required final double avgCitations,
    required final int totalCitations,
    required final int activeYear,
    required final String topJournal,
    required final String topAuthor,
  }) async {
    emit(ReportGenerating());

    emit(ReportUploading());

    final result = await _reportRepository.generateAndUploadReport(
      conceptName: conceptName,
      fullName: fullName,
      totalPublications: totalPublications,
      avgCitations: avgCitations,
      totalCitations: totalCitations,
      activeYear: activeYear,
      topJournal: topJournal,
      topAuthor: topAuthor,
    );

    await result.fold(
      (final failure) async => emit(ReportFailure(failure.message)),
      (final url) async {
        try {
          if (getIt.isRegistered<IUserActivityTracker>()) {
            await getIt<IUserActivityTracker>().logPdfExport(conceptName);
          }
        } on Exception catch (_) {}
        emit(ReportUploadSuccess(url));
      },
    );
  }
}
