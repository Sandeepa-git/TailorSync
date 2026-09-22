import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/ai_wizard_state.dart';

class AiToolsScreen extends ConsumerWidget {
  const AiToolsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiWizardProvider);
    final notifier = ref.read(aiWizardProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Tailoring Assistant'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stepper(
              type: StepperType.vertical,
              currentStep: state.currentStep,
              onStepContinue: () {
                if (state.currentStep == 0) notifier.predictMeasurements();
                else if (state.currentStep == 1) notifier.recommendFabric();
                else if (state.currentStep == 2) notifier.estimateFabric();
                else context.go('/home'); // Finish
              },
              onStepCancel: () {
                if (state.currentStep > 0) {
                  notifier.setStep(state.currentStep - 1);
                }
              },
              steps: [
                _buildMeasurementStep(state, notifier),
                _buildFabricStep(state, notifier),
                _buildEstimateStep(state, notifier),
                _buildSummaryStep(state),
              ],
            ),
    );
  }

  Step _buildMeasurementStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Measurement Prediction'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Select Garment Type:'),
          DropdownButton<String>(
            value: state.garmentType,
            items: ['Long Sleeve Shirt', 'Short Sleeve Shirt', 'Long Trouser', 'Short Trouser']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => notifier.setGarmentType(val!),
          ),
          const SizedBox(height: 16),
          const Text('Enter known measurements (cm):'),
          _buildMeasurementField('height', state, notifier),
          _buildMeasurementField('chest', state, notifier),
          _buildMeasurementField('waist', state, notifier),
          if (state.error != null && state.currentStep == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
          if (state.measurementPredictions != null) ...[
            const SizedBox(height: 16),
            const Text('AI Predictions:', style: TextStyle(fontWeight: FontWeight.bold)),
            ...state.measurementPredictions!.map((p) => ListTile(
                  title: Text('${p['measurement']}: ${p['recommended']} cm'),
                  subtitle: Text(p['reason']),
                )),
          ]
        ],
      ),
      isActive: state.currentStep >= 0,
      state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildMeasurementField(String key, AiWizardState state, AiWizardNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: key.toUpperCase()),
        initialValue: state.inputMeasurements[key],
        keyboardType: TextInputType.number,
        onChanged: (val) => notifier.updateInputMeasurement(key, val),
      ),
    );
  }

  Step _buildFabricStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Fabric Recommendation'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            decoration: const InputDecoration(labelText: 'Occasion (e.g. Wedding, Casual)'),
            initialValue: state.occasion,
            onChanged: notifier.setOccasion,
          ),
          TextFormField(
            decoration: const InputDecoration(labelText: 'Weather (e.g. Summer, Winter)'),
            initialValue: state.weather,
            onChanged: notifier.setWeather,
          ),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: 'Fit'),
            value: state.fit,
            items: ['Regular', 'Slim', 'Loose']
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
            onChanged: (val) => notifier.setFit(val!),
          ),
          const SizedBox(height: 16),
          if (state.error != null && state.currentStep == 1)
            Text(state.error!, style: const TextStyle(color: Colors.red)),
          if (state.fabricRecommendations != null) ...[
            const Text('AI Recommendations (Select One):', style: TextStyle(fontWeight: FontWeight.bold)),
            ...state.fabricRecommendations!.map((f) => RadioListTile<String>(
                  title: Text('${f['fabric_name']} (${f['suitability_percentage']}%)'),
                  subtitle: Text(f['reason']),
                  value: f['fabric_name'],
                  groupValue: state.selectedFabric,
                  onChanged: (val) => notifier.selectFabric(val!),
                )),
          ]
        ],
      ),
      isActive: state.currentStep >= 1,
      state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildEstimateStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Fabric Estimation'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selected Garment: ${state.garmentType}'),
          Text('Selected Fabric: ${state.selectedFabric ?? "None"}'),
          const SizedBox(height: 16),
          const Text('Press Continue to let AI estimate the required fabric length based on your measurements.'),
          if (state.error != null && state.currentStep == 2)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(state.error!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
      isActive: state.currentStep >= 2,
      state: state.currentStep > 2 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildSummaryStep(AiWizardState state) {
    return Step(
      title: const Text('Summary'),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🎉 AI Flow Complete!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Text('Garment: ${state.garmentType}'),
          Text('Fabric: ${state.selectedFabric}'),
          if (state.estimatedQuantity != null) ...[
            const SizedBox(height: 8),
            Text('Estimated Fabric Needed: ${state.estimatedQuantity} meters', 
                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 16)),
            Text('Range: ${state.minEstimate}m - ${state.maxEstimate}m'),
            Text('Reason: ${state.estimationReason}'),
          ]
        ],
      ),
      isActive: state.currentStep >= 3,
      state: StepState.complete,
    );
  }
}
