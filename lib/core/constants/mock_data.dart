import '../../features/keywords/domain/entities/author.dart';
import '../../features/keywords/domain/entities/keyword.dart';
import '../../features/keywords/domain/entities/trend.dart';
import '../../features/journal/domain/entities/journal.dart';
import '../../features/journal/domain/entities/paper.dart';

class MockData {
  static const List<Author> mockAuthors = [
    Author(
      id: 'A5077297577',
      displayName: 'J. Smith',
      worksCount: 45,
      citedByCount: 1200,
      lastKnownInstitution: 'Harvard University',
    ),
    Author(
      id: 'A5120892063',
      displayName: 'M. Johnson',
      worksCount: 38,
      citedByCount: 950,
      lastKnownInstitution: 'Stanford University',
    ),
    Author(
      id: 'A5037491546',
      displayName: 'Y. Wang',
      worksCount: 52,
      citedByCount: 1500,
      lastKnownInstitution: 'Tsinghua University',
    ),
    Author(
      id: 'A5044512393',
      displayName: 'A. Garcia',
      worksCount: 30,
      citedByCount: 600,
      lastKnownInstitution: 'Massachusetts Institute of Technology',
    ),
    Author(
      id: 'A5063209659',
      displayName: 'K. Patel',
      worksCount: 28,
      citedByCount: 450,
      lastKnownInstitution: 'University of Oxford',
    ),
    Author(
      id: 'A5103423779',
      displayName: 'E. Dupont',
      worksCount: 22,
      citedByCount: 300,
      lastKnownInstitution: 'Sorbonne University',
    ),
    Author(
      id: 'A5010062957',
      displayName: 'H. Tanaka',
      worksCount: 35,
      citedByCount: 800,
      lastKnownInstitution: 'University of Tokyo',
    ),
  ];

  static const List<Keyword> mockTopKeywords = [
    Keyword(
      id: 'k1',
      displayName: 'Machine Learning',
      level: 2,
      worksCount: 150,
    ),
    Keyword(id: 'k2', displayName: 'Deep Learning', level: 2, worksCount: 120),
    Keyword(
      id: 'k3',
      displayName: 'Artificial Intelligence',
      level: 2,
      worksCount: 95,
    ),
    Keyword(id: 'k4', displayName: 'Neural Networks', level: 2, worksCount: 80),
    Keyword(id: 'k5', displayName: 'Computer Vision', level: 2, worksCount: 70),
    Keyword(
      id: 'k6',
      displayName: 'Natural Language Processing',
      level: 2,
      worksCount: 65,
    ),
  ];

  static const List<Keyword> mockEmergingKeywords = [
    Keyword(
      id: 'e1',
      displayName: 'Transformer Models',
      level: 3,
      worksCount: 45,
    ),
    Keyword(id: 'e2', displayName: 'Generative AI', level: 3, worksCount: 40),
    Keyword(
      id: 'e3',
      displayName: 'Reinforcement Learning',
      level: 3,
      worksCount: 35,
    ),
    Keyword(
      id: 'e4',
      displayName: 'Federated Learning',
      level: 3,
      worksCount: 30,
    ),
    Keyword(id: 'e5', displayName: 'Explainable AI', level: 3, worksCount: 25),
  ];

  static const List<PublicationTrend> mockPublicationTrends = [
    PublicationTrend(year: 2018, count: 45),
    PublicationTrend(year: 2019, count: 58),
    PublicationTrend(year: 2020, count: 72),
    PublicationTrend(year: 2021, count: 90),
    PublicationTrend(year: 2022, count: 115),
    PublicationTrend(year: 2023, count: 140),
    PublicationTrend(year: 2024, count: 165),
  ];

  static const List<CitationTrend> mockCitationTrends = [
    CitationTrend(year: 2018, count: 250),
    CitationTrend(year: 2019, count: 420),
    CitationTrend(year: 2020, count: 680),
    CitationTrend(year: 2021, count: 1100),
    CitationTrend(year: 2022, count: 1750),
    CitationTrend(year: 2023, count: 2600),
    CitationTrend(year: 2024, count: 3800),
  ];

  static const List<Journal> mockJournals = [
    Journal(
      id: 'J1',
      displayName:
          'IEEE Transactions on Pattern Analysis and Machine Intelligence',
      worksCount: 85,
      citedByCount: 3200,
      publisher: 'IEEE',
    ),
    Journal(
      id: 'J2',
      displayName: 'Journal of Machine Learning Research',
      worksCount: 70,
      citedByCount: 2800,
      publisher: 'JMLR Org',
    ),
    Journal(
      id: 'J3',
      displayName: 'Neural Computation',
      worksCount: 45,
      citedByCount: 1500,
      publisher: 'MIT Press',
    ),
    Journal(
      id: 'J4',
      displayName: 'Pattern Recognition',
      worksCount: 55,
      citedByCount: 1800,
      publisher: 'Elsevier',
    ),
    Journal(
      id: 'J5',
      displayName: 'IEEE Access',
      worksCount: 95,
      citedByCount: 2100,
      publisher: 'IEEE',
    ),
    Journal(
      id: 'J6',
      displayName: 'Nature Machine Intelligence',
      worksCount: 30,
      citedByCount: 1400,
      publisher: 'Springer Nature',
    ),
  ];

  static const List<Paper> mockPapers = [
    Paper(
      id: 'p1',
      title: 'Deep Learning Foundations and Applications',
      publicationYear: 2021,
      citationCount: 120,
      authors: ['J. Smith', 'M. Johnson'],
      doi: '10.1000/1',
      journalName:
          'IEEE Transactions on Pattern Analysis and Machine Intelligence',
      concepts: ['Machine Learning', 'Deep Learning'],
      isOpenAccess: true,
    ),
    Paper(
      id: 'p2',
      title: 'Attention-based Transformer Architectures',
      publicationYear: 2022,
      citationCount: 95,
      authors: ['Y. Wang', 'A. Garcia'],
      doi: '10.1000/2',
      journalName: 'Journal of Machine Learning Research',
      concepts: ['Deep Learning', 'Transformer Models'],
      isOpenAccess: true,
    ),
    Paper(
      id: 'p3',
      title: 'Generative AI and Creative Reasoning Advancements',
      publicationYear: 2023,
      citationCount: 75,
      authors: ['M. Johnson', 'Y. Wang'],
      doi: '10.1000/3',
      journalName: 'Nature Machine Intelligence',
      concepts: ['Machine Learning', 'Generative AI'],
      isOpenAccess: true,
    ),
    Paper(
      id: 'p4',
      title: 'Explainable Neural Network Architectures',
      publicationYear: 2023,
      citationCount: 40,
      authors: ['A. Garcia', 'K. Patel'],
      doi: '10.1000/4',
      journalName: 'Pattern Recognition',
      concepts: ['Explainable AI', 'Neural Networks'],
      isOpenAccess: true,
    ),
    Paper(
      id: 'p5',
      title: 'Decentralized Collaborative Systems and AI Ethics',
      publicationYear: 2024,
      citationCount: 20,
      authors: ['K. Patel', 'E. Dupont', 'H. Tanaka'],
      doi: '10.1000/5',
      journalName: 'IEEE Access',
      concepts: ['Artificial Intelligence'],
      isOpenAccess: true,
    ),
  ];
}
