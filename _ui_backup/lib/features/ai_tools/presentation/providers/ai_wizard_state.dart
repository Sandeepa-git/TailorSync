import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../core/network/providers/api_provider.dart';

class AiWizardState {
  final int currentStep;
  final bool isLoading;
  final String? error;

  // Step 1: Measurements
  final String garmentType;
  final Map<String, String> inputMeasurements;
  final List<dynamic>? measurementPredictions;

  // Step 2: Fabric Recommendation
  final String occasion;
  final String weather;
  final List<String> fabricPreferences;
  final String fit;
  final List<dynamic>? fabricRecommendations;
  final String? selectedFabric;

  // Step 3: Estimation
  final double? estimatedQuantity;
  final double? minEstimate;
  final double? maxEstimate;
  final String? estimationReason;

  AiWizardState({
    this.currentStep = 0,
    this.isLoading = false,
    this.error,
    this.garmentType = 'Long Sleeve Shirt',
    this.inputMeasurements = const {},
    this.measurementPredictions,
    this.occasion = '',
    this.weather = '',
    this.fabricPreferences = const [],
    this.fit = 'Regular',
    this.fabricRecommendations,
    this.selectedFabric,
    this.estimatedQuantity,
    this.minEstimate,
    this.maxEstimate,
    this.estimationReason,
  });

  AiWizardState copyWith({
    int? currentStep,
    bool? isLoading,
    String? error,
    String? garmentType,
    Map<String, String>? inputMeasurements,
    List<dynamic>? measurementPredictions,
    String? occasion,
    String? weather,
    List<String>? fabricPreferences,
    String? fit,
    List<dynamic>? fabricRecommendations,
    String? selectedFabric,
    double? estimatedQuantity,
    double? minEstimate,
    double? maxEstimate,
    String? estimationReason,
  }) {
    return AiWizardState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      garmentType: garmentType ?? this.garmentType,
      inputMeasurements: inputMeasurements ?? this.inputMeasurements,
      measurementPredictions: measurementPredictions ?? this.measurementPredictions,
      occasion: occasion ?? this.occasion,
      weather: weather ?? this.weather,
      fabricPreferences: fabricPreferences ?? this.fabricPreferences,
      fit: fit ?? this.fit,
      fabricRecommendations: fabricRecommendations ?? this.fabricRecommendations,
      selectedFabric: selectedFabric ?? this.selectedFabric,
      estimatedQuantity: estimatedQuantity ?? this.estimatedQuantity,
      minEstimate: minEstimate ?? this.minEstimate,
      maxEstimate: maxEstimate ?? this.maxEstimate,
      estimationReason: estimationReason ?? this.estimationReason,
    );
  }
}

class AiWizardNotifier extends StateNotifier<AiWizardState> {
  final Ref ref;

  AiWizardNotifier(this.ref) : super(AiWizardState());

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  void updateInputMeasurement(String key, String value) {
    final updated = Map<String, String>.from(state.inputMeasurements);
    if (value.isEmpty) {
      updated.remove(key);
    } else {
      updated[key] = value;
    }
    state = state.copyWith(inputMeasurements: updated);
  }

  void setGarmentType(String type) {
    state = state.copyWith(garmentType: type);
  }

  void setOccasion(String occasion) => state = state.copyWith(occasion: occasion);
  void setWeather(String weather) => state = state.copyWith(weather: weather);
  void setFit(String fit) => state = state.copyWith(fit: fit);
  
  void toggleFabricPreference(String pref) {
    final prefs = List<String>.from(state.fabricPreferences);
    if (prefs.contains(pref)) {
      prefs.remove(pref);
    } else {
      prefs.add(pref);
    }
    state = state.copyWith(fabricPreferences: prefs);
  }

  void selectFabric(String fabric) {
    state = state.copyWith(selectedFabric: fabric);
  }

  Future<void> predictMeasurements() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.predictMeasurements({
        "garment_type": state.garmentType,
        "measurements": state.inputMeasurements,
      });
      state = state.copyWith(
        isLoading: false,
        measurementPredictions: response.data['predictions'],
        currentStep: 1, // Move to next step on success
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> recommendFabric() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.recommendFabric({
        "garment_type": state.garmentType,
        "occasion": state.occasion,
        "weather": state.weather,
        "fabric_preferences": state.fabricPreferences,
        "fit": state.fit,
      });
      state = state.copyWith(
        isLoading: false,
        fabricRecommendations: response.data['recommendations'],
        currentStep: 2, // Move to next step on success
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> estimateFabric() async {
    if (state.selectedFabric == null) {
      state = state.copyWith(error: "Please select a fabric first.");
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    try {
      final client = ref.read(apiClientProvider);
      
      // Combine manual inputs with predictions for full measurement map
      final fullMeasurements = Map<String, String>.from(state.inputMeasurements);
      if (state.measurementPredictions != null) {
        for (var p in state.measurementPredictions!) {
          fullMeasurements[p['measurement']] = p['recommended'].toString();
        }
      }

      final response = await client.estimateFabric({
        "garment_type": state.garmentType,
        "measurements": fullMeasurements,
        "fabric": state.selectedFabric,
      });
      
      final data = response.data;
      state = state.copyWith(
        isLoading: false,
        estimatedQuantity: (data['recommended_quantity_meters'] as num?)?.toDouble(),
        minEstimate: (data['estimated_range']?['min'] as num?)?.toDouble(),
        maxEstimate: (data['estimated_range']?['max'] as num?)?.toDouble(),
        estimationReason: data['reason'],
        currentStep: 3, // Final summary step
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final aiWizardProvider = StateNotifierProvider<AiWizardNotifier, AiWizardState>((ref) {
  return AiWizardNotifier(ref);
});
