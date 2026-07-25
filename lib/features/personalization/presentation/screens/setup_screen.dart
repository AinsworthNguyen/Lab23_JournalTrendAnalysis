import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../injection_container.dart';
import '../../../../core/constants/admin_accounts.dart';
import '../../../../core/firebase/firebase_auth_service.dart';
import '../../domain/entities/user_preferences.dart';
import '../blocs/personalization_bloc.dart';
import '../blocs/personalization_event.dart';
import '../blocs/personalization_state.dart';

class Concept {
  final String id;
  final String name;
  const Concept(this.id, this.name);
}

const List<Concept> _popularConcepts = [
  Concept('C41008148', 'Computer Science'),
  Concept('C154945302', 'Artificial Intelligence'),
  Concept('C119857082', 'Machine Learning'),
  Concept('C2522767166', 'Data Science'),
  Concept('C121332964', 'Physics'),
  Concept('C33923547', 'Mathematics'),
  Concept('C86803240', 'Biology'),
  Concept('C71924100', 'Medicine'),
  Concept('C185592680', 'Chemistry'),
  Concept('C127413603', 'Engineering'),
  Concept('C162324750', 'Economics'),
  Concept('C15744967', 'Psychology'),
  Concept('C144024400', 'Sociology'),
  Concept('C138885662', 'Philosophy'),
  Concept('C192562407', 'Materials Science'),
];

class PersonalizationSetupScreen extends StatefulWidget {
  const PersonalizationSetupScreen({super.key});

  @override
  State<PersonalizationSetupScreen> createState() => _PersonalizationSetupScreenState();
}

class _PersonalizationSetupScreenState extends State<PersonalizationSetupScreen> {
  final _nameController = TextEditingController();
  final _searchController = TextEditingController();
  Concept? _selectedConcept;
  List<Concept> _filteredConcepts = List.from(_popularConcepts);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredConcepts = _popularConcepts.where((concept) {
        return concept.name.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider<PersonalizationBloc>(
      create: (context) => getIt<PersonalizationBloc>()..add(LoadUserPreferences()),
      child: Scaffold(
        body: BlocConsumer<PersonalizationBloc, PersonalizationState>(
          listener: (context, state) {
            if (state is PersonalizationSuccess) {
              context.go('/home');
            } else if (state is PersonalizationLoaded && state.preferences != null) {
              final prefs = state.preferences!;
              _nameController.text = prefs.fullName;
              _selectedConcept = _popularConcepts.firstWhere(
                (c) => c.id == prefs.interestConceptId,
                orElse: () => Concept(prefs.interestConceptId, prefs.interestConceptName),
              );
              setState(() {});
            } else if (state is PersonalizationLoaded && state.generatedName != null) {
              _nameController.text = state.generatedName!;
            } else if (state is PersonalizationFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message)),
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is PersonalizationLoading;

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 40.0),
                    // Header Section
                    Text(
                      'setup.title'.tr(),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      'setup.subtitle'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48.0),

                    // Full Name Input
                    Text(
                      'setup.name_label'.tr(),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: 'setup.name_hint'.tr(),
                        prefixIcon: const Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 12.0),

                    // Generate Pseudonym Button
                    OutlinedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () {
                              context.read<PersonalizationBloc>().add(GenerateRandomNameEvent());
                            },
                      icon: const Icon(Icons.auto_awesome_outlined),
                      label: Text('setup.button_generate'.tr()),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32.0),

                    // Research Interest Input
                    Text(
                      'setup.interest_label'.tr(),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8.0),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'setup.interest_hint'.tr(),
                        prefixIcon: const Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12.0),

                    // Suggestions Grid/List
                    Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12.0),
                      clipBehavior: Clip.hardEdge,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                          ),
                        ),
                        child: ListView.builder(
                        itemCount: _filteredConcepts.length,
                        itemBuilder: (context, index) {
                          final concept = _filteredConcepts[index];
                          final isSelected = _selectedConcept?.id == concept.id;
                          return ListTile(
                            leading: Icon(
                              isSelected ? Icons.check_circle : Icons.science_outlined,
                              color: isSelected ? theme.colorScheme.primary : null,
                            ),
                            title: Text(
                              concept.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                            selected: isSelected,
                            onTap: () {
                              setState(() {
                                _selectedConcept = concept;
                              });
                            },
                          );
                        },
                      ),
                    ),
                    ),
                    const SizedBox(height: 48.0),

                    // Save Preferences Button
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final name = _nameController.text.trim();
                              if (name.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('setup.name_error'.tr())),
                                );
                                return;
                              }
                              if (_selectedConcept == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('setup.interest_error'.tr())),
                                );
                                return;
                              }

                              final authService = getIt<IFirebaseAuthService>();
                              final currentUser = authService.currentUser;
                              final email = currentUser?.email ?? '';
                              final photoUrl = currentUser?.photoURL ?? '';
                              final role = AdminAccounts.roleForEmail(email);

                              final prefs = UserPreferences(
                                fullName: name,
                                email: email,
                                photoUrl: photoUrl,
                                interestConceptId: _selectedConcept!.id,
                                interestConceptName: _selectedConcept!.name,
                                role: role,
                              );

                              context.read<PersonalizationBloc>().add(SavePreferencesEvent(prefs));
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 4,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 20.0,
                              width: 20.0,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'setup.button_save'.tr(),
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                    const SizedBox(height: 12.0),
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () {
                              final authService = getIt<IFirebaseAuthService>();
                              final currentUser = authService.currentUser;
                              final email = currentUser?.email ?? '';
                              final photoUrl = currentUser?.photoURL ?? '';
                              final role = AdminAccounts.roleForEmail(email);

                              // Default/Guest profile values
                              final guestPrefs = UserPreferences(
                                fullName: 'Guest Researcher',
                                email: email,
                                photoUrl: photoUrl,
                                interestConceptId: 'C41008148', // Computer Science
                                interestConceptName: 'Computer Science',
                                role: role,
                              );

                              context.read<PersonalizationBloc>().add(SavePreferencesEvent(guestPrefs));
                            },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14.0),
                      ),
                      child: Text(
                        'setup.button_skip'.tr(),
                        style: TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
