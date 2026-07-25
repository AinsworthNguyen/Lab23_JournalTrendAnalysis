import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/core/error/failures.dart';
import 'package:journal_trend_analysis/features/profile/domain/repositories/report_repository.dart';
import 'package:journal_trend_analysis/features/profile/presentation/blocs/report_cubit.dart';
import 'package:journal_trend_analysis/features/profile/presentation/blocs/report_state.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late ReportCubit reportCubit;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    reportCubit = ReportCubit(mockReportRepository);
  });

  tearDown(() {
    reportCubit.close();
  });

  group('ReportCubit Tests', () {
    test('initial state should be ReportInitial', () {
      expect(reportCubit.state, equals(ReportInitial()));
    });

    test(
      'should emit [ReportGenerating, ReportUploading, ReportUploadSuccess] when report generation and upload is successful',
      () async {
        when(
          () => mockReportRepository.generateAndUploadReport(
            conceptName: any(named: 'conceptName'),
            fullName: any(named: 'fullName'),
            totalPublications: any(named: 'totalPublications'),
            avgCitations: any(named: 'avgCitations'),
            totalCitations: any(named: 'totalCitations'),
            activeYear: any(named: 'activeYear'),
            topJournal: any(named: 'topJournal'),
            topAuthor: any(named: 'topAuthor'),
          ),
        ).thenAnswer(
          (_) async => const Right('https://firebase.storage/report.pdf'),
        );

        final expectation = expectLater(
          reportCubit.stream,
          emitsInOrder([
            ReportGenerating(),
            ReportUploading(),
            const ReportUploadSuccess('https://firebase.storage/report.pdf'),
          ]),
        );

        await reportCubit.exportReport(
          conceptName: 'Quantum Physics',
          fullName: 'John Doe',
          totalPublications: 100,
          avgCitations: 15.0,
          totalCitations: 1500,
          activeYear: 2023,
          topJournal: 'PRL',
          topAuthor: 'Einstein',
        );

        await expectation;
      },
    );

    test(
      'should emit [ReportGenerating, ReportUploading, ReportFailure] when report generation or upload fails',
      () async {
        when(
          () => mockReportRepository.generateAndUploadReport(
            conceptName: any(named: 'conceptName'),
            fullName: any(named: 'fullName'),
            totalPublications: any(named: 'totalPublications'),
            avgCitations: any(named: 'avgCitations'),
            totalCitations: any(named: 'totalCitations'),
            activeYear: any(named: 'activeYear'),
            topJournal: any(named: 'topJournal'),
            topAuthor: any(named: 'topAuthor'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Upload failed')));

        final expectation = expectLater(
          reportCubit.stream,
          emitsInOrder([
            ReportGenerating(),
            ReportUploading(),
            const ReportFailure('Upload failed'),
          ]),
        );

        await reportCubit.exportReport(
          conceptName: 'Quantum Physics',
          fullName: 'John Doe',
          totalPublications: 100,
          avgCitations: 15.0,
          totalCitations: 1500,
          activeYear: 2023,
          topJournal: 'PRL',
          topAuthor: 'Einstein',
        );

        await expectation;
      },
    );
  });
}
