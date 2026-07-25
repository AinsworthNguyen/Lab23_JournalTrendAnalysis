import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/firebase/firebase_storage_service.dart';
import '../../../../core/firebase/firebase_analytics_service.dart';
import '../../../../core/utils/pdf_report_service.dart';
import '../../domain/repositories/report_repository.dart';

@LazySingleton(as: ReportRepository)
class ReportRepositoryImpl implements ReportRepository {
  final PDFReportService _pdfReportService;
  final IFirebaseStorageService _storageService;
  final IFirebaseAnalyticsService _analyticsService;

  ReportRepositoryImpl({
    required PDFReportService pdfReportService,
    required IFirebaseStorageService storageService,
    required IFirebaseAnalyticsService analyticsService,
  }) : _pdfReportService = pdfReportService,
       _storageService = storageService,
       _analyticsService = analyticsService;

  @override
  Future<Either<Failure, String>> generateAndUploadReport({
    required String conceptName,
    required String fullName,
    required int totalPublications,
    required double avgCitations,
    required int totalCitations,
    required int activeYear,
    required String topJournal,
    required String topAuthor,
  }) async {
    try {
      final localPath = await _pdfReportService.generateDashboardReport(
        conceptName: conceptName,
        fullName: fullName,
        totalPublications: totalPublications,
        avgCitations: avgCitations,
        totalCitations: totalCitations,
        activeYear: activeYear,
        topJournal: topJournal,
        topAuthor: topAuthor,
      );

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final cleanName = fullName
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .replaceAll(' ', '_');
      final destinationPath = 'reports/${cleanName}_$timestamp.pdf';

      String downloadUrl;
      try {
        downloadUrl = await _storageService.uploadPdfReport(
          filePath: localPath,
          destinationPath: destinationPath,
        );
      } catch (_) {
        // Fallback to local file path if Storage is not configured or fails
        downloadUrl = 'file://$localPath';
      }

      await _analyticsService.logExportPdf(conceptName);

      return Right(downloadUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
