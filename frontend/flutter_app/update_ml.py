import os
import re

file_path = "c:/Users/Sandeepa/Desktop/TailorSync/frontend/flutter_app/lib/features/orders/presentation/screens/new_order_wizard.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update step titles
old_titles = "'Customer', 'Garment', 'Priority Input', 'AI Prediction', \n    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'"
new_titles = "'Customer', 'Garment', 'Priority Input', 'Prediction Method', 'AI Prediction', \n    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'"
content = content.replace(old_titles, new_titles)

# 2. Update garment types to just Shirt and Trouser
old_garments = """  final List<Map<String, dynamic>> _garmentTypes = [
    {'name': 'Short Sleeve Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Long Sleeve Shirt', 'icon': Icons.dry_cleaning, 'color': Color(0xFF4CAF50)},
    {'name': 'Short Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF6584)},
    {'name': 'Long Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
    {'name': 'Dresses', 'icon': Icons.woman, 'color': Color(0xFF9B59B6)},
    {'name': 'Suits', 'icon': Icons.work, 'color': Color(0xFF34495E)},
    {'name': 'Jackets', 'icon': Icons.layers, 'color': Color(0xFFE67E22)},
    {'name': 'Coats', 'icon': Icons.ac_unit, 'color': Color(0xFF2980B9)},
  ];"""
new_garments = """  final List<Map<String, dynamic>> _garmentTypes = [
    {'name': 'Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
  ];"""
content = content.replace(old_garments, new_garments)

# 3. Update _getDefaultTemplateForCategory
# I will just regex replace the entire method body
import textwrap

old_def_tmpl = """  Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {"""
new_def_tmpl = """  Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {
      List<Map<String, dynamic>> fields = [];
      if (cat == 'Shirt') {
        fields = [
          {'id': 1, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 18.0'},
          {'id': 2, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 68.0'},
          {'id': 3, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 40.0'},
        ];
      } else if (cat == 'Trouser') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 68.0'},
          {'id': 2, 'field_name': 'Waist', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 34.0'},
          {'id': 3, 'field_name': 'Seat', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 40.0'},
        ];
      }
      return {'category_name': cat, 'fields': fields};
  }
  
  Map<String, dynamic> _dummy_for_regex() {"""
content = re.sub(r'  Map<String, dynamic> _getDefaultTemplateForCategory\(String cat\) \{.*?(?=  // Step 4)', new_def_tmpl + '\n', content, flags=re.DOTALL)


# 4. Step logic for Garment (Step 1) -> Priority Input (Step 2)
# Fetch the input ranges
step_1_old = """    if (_currentStep == 1) {
      if (_selectedGarment == null) { _showSnack('⚠️ Please select a garment'); return; }
      setState(() { _loadingTemplate = true; _currentStep++; });
      
      // Always use the refined client-side template for accurate garment-specific measurements
      _measurementTemplate = _getDefaultTemplateForCategory(_selectedGarment!);
      
      _measurementControllers.clear();
      _customMeasurements.clear();
      _customMeasurementControllers.clear();
      final fields = _measurementTemplate!['fields'] as List;
      for (var f in fields) { _measurementControllers[f['id']] = TextEditingController(); }
      setState(() { _loadingTemplate = false; });
      return;
    }"""
step_1_new = """    if (_currentStep == 1) {
      if (_selectedGarment == null) { _showSnack('⚠️ Please select a garment'); return; }
      setState(() { _loadingTemplate = true; _currentStep++; });
      
      _measurementTemplate = _getDefaultTemplateForCategory(_selectedGarment!);
      
      try {
         final rangesResp = await api.getMeasurementInputRanges(_selectedGarment!.toLowerCase());
         final ranges = rangesResp.data['ranges'] as Map<String, dynamic>;
         for (var f in _measurementTemplate!['fields']) {
             final fieldName = (f['field_name'] as String).toLowerCase();
             final rangeData = ranges[fieldName];
             if (rangeData != null) {
                 f['min'] = rangeData['min'];
                 f['max'] = rangeData['max'];
                 f['placeholder'] = '${rangeData['min']} - ${rangeData['max']}';
             }
         }
      } catch(e) {
         print("Failed to fetch ranges: $e");
      }
      
      _measurementControllers.clear();
      _customMeasurements.clear();
      _customMeasurementControllers.clear();
      final fields = _measurementTemplate!['fields'] as List;
      for (var f in fields) { _measurementControllers[f['id']] = TextEditingController(); }
      setState(() { _loadingTemplate = false; });
      return;
    }"""
content = content.replace(step_1_old, step_1_new)

# 5. Step 2 (Priority Input) validation
# Old validation calls predictMeasurements and goes to Step 3 (AI Prediction)
# New validation should just go to Step 3 (Prediction Method)
step_2_old_regex = r'    if \(_currentStep == 2\) \{.*?return;\n    \}'
step_2_new = """    if (_currentStep == 2) {
      final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();
      final priorityFields = fields.where((f) => f['is_required'] == true).toList();
          
      final missing = <String>[];
      final enteredMeasures = <String, String>{};
      
      for (var f in priorityFields) {
        final id = f['id'] as int;
        final text = _measurementControllers[id]?.text.trim() ?? '';
        if (text.isEmpty || double.tryParse(text) == null) {
          missing.add(f['field_name']);
        }
      }
      if (missing.isNotEmpty) {
        _showSnack('⚠️ Required: ${missing.join(", ")}'); return;
      }
      
      for (var f in fields) {
        final id = f['id'] as int;
        final name = f['field_name'] as String;
        final min = f['min'] as double?;
        final max = f['max'] as double?;
        final text = _measurementControllers[id]?.text.trim() ?? '';
        
        if (text.isNotEmpty) {
          final val = double.tryParse(text);
          if (val != null && min != null && max != null) {
            if (val < min || val > max) {
              _showSnack('⚠️ $name must be between $min and $max inches.');
              return;
            }
          }
          enteredMeasures[name] = text;
          _confirmedMeasurements[name] = text;
          _isAiGenerated[name] = false;
        }
      }
      
      for (var custom in _customMeasurements) {
        final id = custom['id'] as int;
        final name = custom['field_name'] as String;
        final text = _customMeasurementControllers[id]?.text.trim() ?? '';
        if (name.isNotEmpty && text.isNotEmpty) {
          enteredMeasures[name] = text;
          _confirmedMeasurements[name] = text;
          _isAiGenerated[name] = false;
        }
      }
      
      setState(() { _currentStep++; });
      return;
    }"""
content = re.sub(step_2_old_regex, step_2_new, content, flags=re.DOTALL)

# Update the rest of the step indices in _nextStep
content = content.replace("if (_currentStep == 3)", "if (_currentStep == 4)")
content = content.replace("if (_currentStep == 4)", "if (_currentStep == 5)")
content = content.replace("if (_currentStep == 5)", "if (_currentStep == 6)")
content = content.replace("if (_currentStep == 6)", "if (_currentStep == 7)")

# Replace the step builder
builder_old = """      case 2: return _buildPriorityInputStep();
      case 3: return _buildAiPredictionStep();
      case 4: return _buildPreferencesStep();
      case 5: return _buildFabricRecStep();
      case 6: return _buildEstimationStep();
      case 7: return _buildAssignStep();"""
builder_new = """      case 2: return _buildPriorityInputStep();
      case 3: return _buildPredictionMethodStep();
      case 4: return _buildAiPredictionStep();
      case 5: return _buildPreferencesStep();
      case 6: return _buildFabricRecStep();
      case 7: return _buildEstimationStep();
      case 8: return _buildAssignStep();"""
content = content.replace(builder_old, builder_new)

# Add _buildPredictionMethodStep
prediction_method_step = """
  // --- Step 4: Prediction Method ---
  Widget _buildPredictionMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Prediction Model', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text('Choose how you want AI to assist with measurements.', style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        
        // Fast ML Predict
        GestureDetector(
          onTap: () async {
            setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
            try {
              final api = ref.read(apiClientProvider);
              final req = {'garment_type': _selectedGarment!.toLowerCase()};
              
              // Pass the exact lowercase names required by ML
              _confirmedMeasurements.forEach((k, v) { req[k.toLowerCase()] = double.parse(v); });
              
              final resp = await api.predictMeasurements(req);
              setState(() {
                _aiPredictions = List<Map<String, dynamic>>.from(resp.data['options'] ?? []);
                _aiPredictionLoading = false;
              });
            } catch (e) {
              setState(() {
                _aiPredictionError = "Prediction failed: $e";
                _aiPredictionLoading = false;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1565C0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.flash_on, size: 40, color: Color(0xFF1565C0)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Predict', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF1565C0))),
                      const SizedBox(height: 4),
                      Text('Fast measurement prediction using the trained local Machine Learning model.', style: GoogleFonts.inter(color: Colors.black87, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        
        // Gen AI Help
        GestureDetector(
          onTap: () async {
            setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
            try {
              final api = ref.read(apiClientProvider);
              final req = {'garment_type': _selectedGarment, 'measurements': _confirmedMeasurements};
              final resp = await api.predictMeasurementsFoundry(req);
              
              setState(() {
                // Adapt Foundry output format to match ML output format (options)
                List<Map<String, dynamic>> preds = List<Map<String, dynamic>>.from(resp.data['predictions'] ?? []);
                _aiPredictions = [];
                for (var p in preds) {
                    Map<String, dynamic> measurements = {};
                    measurements[p['measurement']] = double.tryParse(p['recommended'].toString()) ?? 0.0;
                    _aiPredictions.append({
                        'option_number': 1,
                        'source': 'Foundry Gen AI',
                        'support_percent': null,
                        'measurements': measurements
                    });
                }
                _aiPredictionLoading = false;
              });
            } catch (e) {
              setState(() {
                _aiPredictionError = "Gen AI Help failed: $e";
                _aiPredictionLoading = false;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                const Icon(Icons.psychology, size: 40, color: Colors.black54),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Gen AI Help', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Advanced measurement assistance using Microsoft Foundry. This may take up to a minute.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
"""
content = content.replace("// --- Step 4: AI Prediction Review ---", prediction_method_step + "\n  // --- Step 5: AI Prediction Review ---")

# Replace AI Prediction results step rendering
ai_pred_old = r'    return Column\(\n      crossAxisAlignment: CrossAxisAlignment.start,\n      children: \[\n        Text\(\'AI Predictions Review\'.*?\]\,\n    \)\;'
ai_pred_new = """    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prediction Results', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text("Select an option below. You can edit the values before saving.", style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _aiPredictions.length,
            itemBuilder: (ctx, i) {
              final p = _aiPredictions[i];
              final measurements = p['measurements'] as Map<String, dynamic>;
              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [const Color(0xFF1565C0).withOpacity(0.1), Colors.black.withOpacity(0.02)]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Option ${p['option_number']} - ${p['source']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                    if (p['support_percent'] != null)
                      Text('Support: ${p['support_percent']}%', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),
                    ...measurements.entries.map((e) => Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(color: Colors.black87, fontSize: 14)),
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: TextEditingController(text: e.value.toString()),
                            onChanged: (val) {
                                _confirmedMeasurements[e.key] = val;
                                _isAiGenerated[e.key] = true;
                            },
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
                          ),
                        ),
                      ],
                    )).toList(),
                    const SizedBox(height: 12),
                    ElevatedButton(
                       onPressed: () {
                           measurements.forEach((k, v) {
                               _confirmedMeasurements[k] = v.toString();
                               _isAiGenerated[k] = true;
                           });
                           _showSnack('Option selected and values populated.');
                       },
                       child: const Text('Select this Option')
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );"""
content = re.sub(ai_pred_old, ai_pred_new, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Dart file successfully updated!")
