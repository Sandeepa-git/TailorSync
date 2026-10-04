import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../ui/ui.dart';
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
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: AnimatedSwitcher(
        duration: Motion.of(context, Motion.medium),
        child: state.isLoading
            ? const _AiThinking(key: ValueKey('loading'))
            : MaxWidthBox(
                key: const ValueKey('stepper'),
                maxWidth: MaxWidth.form,
                child: Stepper(
                    type: StepperType.vertical,
                    currentStep: state.currentStep,
                    physics: const BouncingScrollPhysics(),
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
                    controlsBuilder: (context, details) => Padding(
                      padding: const EdgeInsets.only(top: Space.md),
                      child: Wrap(
                        spacing: Space.xs,
                        runSpacing: Space.xs,
                        children: [
                          FilledButton.icon(
                            onPressed: details.onStepContinue,
                            icon: Icon(details.currentStep == 3 ? Icons.check_rounded : Icons.auto_awesome_rounded, size: 18),
                            label: Text(details.currentStep == 3 ? 'Finish' : 'Continue'),
                          ),
                          if (details.currentStep > 0)
                            TextButton(onPressed: details.onStepCancel, child: const Text('Back')),
                        ],
                      ),
                    ),
                    steps: [
                      _buildMeasurementStep(state, notifier),
                      _buildFabricStep(state, notifier),
                      _buildEstimateStep(state, notifier),
                      _buildSummaryStep(state),
                    ],
                  ),
              ),
      ),
    );
  }

  Step _buildMeasurementStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Measurement Prediction'),
      content: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Garment Type', prefixIcon: Icon(Icons.checkroom_rounded)),
              value: state.garmentType,
              isExpanded: true,
              items: ['Long Sleeve Shirt', 'Short Sleeve Shirt', 'Long Trouser', 'Short Trouser']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => notifier.setGarmentType(val!),
            ),
            const SizedBox(height: Space.md),
            Text('Enter known measurements (cm):', style: context.text.labelLarge),
            const SizedBox(height: Space.xs),
            _buildMeasurementField('height', state, notifier),
            _buildMeasurementField('chest', state, notifier),
            _buildMeasurementField('waist', state, notifier),
            if (state.error != null && state.currentStep == 0) _ErrorText(state.error!),
            if (state.measurementPredictions != null) ...[
              const SizedBox(height: Space.md),
              Text('AI Predictions', style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              ...state.measurementPredictions!.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: Space.xs),
                    child: EntranceFade.indexed(
                      e.key,
                      child: TsCard(
                        shadow: false,
                        padding: const EdgeInsets.all(Space.sm),
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const IconBadge(icon: Icons.straighten_rounded, size: 36),
                          title: Text('${e.value['measurement']}: ${e.value['recommended']} cm'),
                          subtitle: Text(e.value['reason']),
                        ),
                      ),
                    ),
                  )),
            ]
          ],
        ),
      ),
      isActive: state.currentStep >= 0,
      state: state.currentStep > 0 ? StepState.complete : StepState.indexed,
    );
  }

  Widget _buildMeasurementField(String key, AiWizardState state, AiWizardNotifier notifier) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextFormField(
        decoration: InputDecoration(labelText: key.toUpperCase(), suffixText: 'in'),
        initialValue: state.inputMeasurements[key],
        keyboardType: TextInputType.number,
        textInputAction: TextInputAction.next,
        onChanged: (val) => notifier.updateInputMeasurement(key, val),
      ),
    );
  }

  Step _buildFabricStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Fabric Recommendation'),
      content: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              decoration: const InputDecoration(labelText: 'Occasion (e.g. Wedding, Casual)', prefixIcon: Icon(Icons.celebration_outlined)),
              initialValue: state.occasion,
              onChanged: notifier.setOccasion,
            ),
            const SizedBox(height: Space.sm),
            TextFormField(
              decoration: const InputDecoration(labelText: 'Weather (e.g. Summer, Winter)', prefixIcon: Icon(Icons.wb_sunny_outlined)),
              initialValue: state.weather,
              onChanged: notifier.setWeather,
            ),
            const SizedBox(height: Space.sm),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(labelText: 'Fit', prefixIcon: Icon(Icons.accessibility_new_rounded)),
              value: state.fit,
              items: ['Regular', 'Slim', 'Loose']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (val) => notifier.setFit(val!),
            ),
            const SizedBox(height: Space.md),
            if (state.error != null && state.currentStep == 1) _ErrorText(state.error!),
            if (state.fabricRecommendations != null) ...[
              Text('AI Recommendations (Select One)', style: context.text.titleSmall),
              const SizedBox(height: Space.xs),
              ...state.fabricRecommendations!.map((f) {
                final selected = state.selectedFabric == f['fabric_name'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.xs),
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.short),
                    decoration: BoxDecoration(
                      borderRadius: Radii.brMd,
                      border: Border.all(
                        color: selected ? context.colors.primary : context.colors.outlineVariant,
                        width: selected ? 2 : 1,
                      ),
                      color: selected ? context.colors.primaryContainer.withValues(alpha: 0.4) : null,
                    ),
                    child: RadioListTile<String>(
                      shape: RoundedRectangleBorder(borderRadius: Radii.brMd),
                      title: Text('${f['fabric_name']} (${f['suitability_percentage']}%)'),
                      subtitle: Text(f['reason']),
                      value: f['fabric_name'],
                      groupValue: state.selectedFabric,
                      onChanged: (val) => notifier.selectFabric(val!),
                    ),
                  ),
                );
              }),
            ]
          ],
        ),
      ),
      isActive: state.currentStep >= 1,
      state: state.currentStep > 1 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildEstimateStep(AiWizardState state, AiWizardNotifier notifier) {
    return Step(
      title: const Text('Fabric Estimation'),
      content: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TsCard(
              shadow: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Selected Garment: ${state.garmentType}', style: context.text.bodyLarge),
                  const SizedBox(height: 4),
                  Text('Selected Fabric: ${state.selectedFabric ?? "None"}', style: context.text.bodyLarge),
                ],
              ),
            ),
            const SizedBox(height: Space.md),
            Text(
              'Press Continue to let AI estimate the required fabric length based on your measurements.',
              style: context.text.bodyMedium,
            ),
            if (state.error != null && state.currentStep == 2) _ErrorText(state.error!),
          ],
        ),
      ),
      isActive: state.currentStep >= 2,
      state: state.currentStep > 2 ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildSummaryStep(AiWizardState state) {
    return Step(
      title: const Text('Summary'),
      content: Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: SuccessCheck(size: 88)),
            const SizedBox(height: Space.sm),
            Center(child: Text('AI Flow Complete!', style: context.text.titleLarge)),
            const SizedBox(height: Space.md),
            Text('Garment: ${state.garmentType}'),
            Text('Fabric: ${state.selectedFabric}'),
            if (state.estimatedQuantity != null) ...[
              const SizedBox(height: Space.sm),
              Text(
                'Estimated Fabric Needed: ${state.estimatedQuantity} meters',
                style: context.text.titleMedium?.copyWith(color: context.status.success),
              ),
              Text('Range: ${state.minEstimate}m - ${state.maxEstimate}m'),
              Text('Reason: ${state.estimationReason}'),
            ]
          ],
        ),
      ),
      isActive: state.currentStep >= 3,
      state: StepState.complete,
    );
  }
}

class _ErrorText extends StatelessWidget {
  final String text;
  const _ErrorText(this.text);

  @override
  Widget build(BuildContext context) {
    return EntranceFade(
      offsetY: -0.2,
      child: Container(
        margin: const EdgeInsets.only(top: Space.xs),
        padding: const EdgeInsets.all(Space.sm),
        decoration: BoxDecoration(color: context.status.dangerContainer, borderRadius: Radii.brSm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline_rounded, size: 18, color: context.status.onDangerContainer),
            const SizedBox(width: Space.xs),
            Expanded(child: Text(text, style: context.text.bodySmall?.copyWith(color: context.status.onDangerContainer))),
          ],
        ),
      ),
    );
  }
}

class _AiThinking extends StatelessWidget {
  const _AiThinking({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StitchLoader(size: 104, color: context.colors.primary, center: Icon(Icons.auto_awesome_rounded, color: context.colors.primary, size: 30)),
          const SizedBox(height: Space.md),
          Text('AI is working on it…', style: context.text.titleMedium),
        ],
      ),
    );
  }
}
