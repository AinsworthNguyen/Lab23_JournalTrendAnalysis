import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/generate_random_name_usecase.dart';
import '../../domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/usecases/save_user_preferences_usecase.dart';
import 'personalization_event.dart';
import 'personalization_state.dart';

@injectable
class PersonalizationBloc
    extends Bloc<PersonalizationEvent, PersonalizationState> {
  final GetUserPreferencesUseCase _getUserPreferences;
  final SaveUserPreferencesUseCase _saveUserPreferences;
  final GenerateRandomNameUseCase _generateRandomName;

  PersonalizationBloc({
    required GetUserPreferencesUseCase getUserPreferences,
    required SaveUserPreferencesUseCase saveUserPreferences,
    required GenerateRandomNameUseCase generateRandomName,
  }) : _getUserPreferences = getUserPreferences,
       _saveUserPreferences = saveUserPreferences,
       _generateRandomName = generateRandomName,
       super(PersonalizationInitial()) {
    on<LoadUserPreferences>(_onLoadUserPreferences);
    on<GenerateRandomNameEvent>(_onGenerateRandomName);
    on<SavePreferencesEvent>(_onSavePreferences);
  }

  Future<void> _onLoadUserPreferences(
    LoadUserPreferences event,
    Emitter<PersonalizationState> emit,
  ) async {
    emit(PersonalizationLoading());
    final result = await _getUserPreferences(const NoParams());
    result.fold(
      (failure) => emit(const PersonalizationLoaded(preferences: null)),
      (preferences) => emit(PersonalizationLoaded(preferences: preferences)),
    );
  }

  Future<void> _onGenerateRandomName(
    GenerateRandomNameEvent event,
    Emitter<PersonalizationState> emit,
  ) async {
    emit(PersonalizationLoading());
    final result = await _generateRandomName(const NoParams());
    result.fold(
      (failure) => emit(PersonalizationFailure(failure.message)),
      (name) => emit(PersonalizationLoaded(generatedName: name)),
    );
  }

  Future<void> _onSavePreferences(
    SavePreferencesEvent event,
    Emitter<PersonalizationState> emit,
  ) async {
    emit(PersonalizationLoading());
    final result = await _saveUserPreferences(event.preferences);
    result.fold(
      (failure) => emit(PersonalizationFailure(failure.message)),
      (_) => emit(PersonalizationSuccess()),
    );
  }
}
