import os

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
# I will find the exact string bounds of this function.
start_idx = content.find("Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {")
end_idx = content.find("  // Step 4: AI Predictions", start_idx)

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

"""
content = content[:start_idx] + new_def_tmpl + content[end_idx:]


# 4. Step logic for Garment (Step 1)
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
# We want to replace everything from "if (_currentStep == 2) {" until "return;\n    }"
start_idx_step2 = content.find("if (_currentStep == 2) {")
end_idx_step2 = content.find("if (_currentStep == 3) {", start_idx_step2)

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
    }
    
    """
content = content[:start_idx_step2] + step_2_new + content[end_idx_step2:]

# Update the rest of the step indices in _nextStep
content = content.replace("if (_currentStep == 6) {", "if (_currentStep == 7) {")
content = content.replace("if (_currentStep == 5) {", "if (_currentStep == 6) {")
content = content.replace("if (_currentStep == 4) {", "if (_currentStep == 5) {")
content = content.replace("if (_currentStep == 3) {", "if (_currentStep == 4) {")

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

# Add _buildPredictionMethodStep and replace AI Prediction Review step
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
                List<Map<String, dynamic>> preds = List<Map<String, dynamic>>.from(resp.data['predictions'] ?? []);
                _aiPredictions = [];
                for (var p in preds) {
                    Map<String, dynamic> measurements = {};
                    measurements[p['measurement']] = double.tryParse(p['recommended'].toString()) ?? 0.0;
                    _aiPredictions.add({
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

new_ai_pred = """  // --- Step 5: AI Prediction Review ---
  Widget _buildAiPredictionStep() {
    if (_aiPredictionLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF1565C0).withOpacity(0.3), boxShadow: [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.5), blurRadius: 30)]),
                child: const Icon(Icons.auto_awesome, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 32),
            Text('Generating Predictions...', style: GoogleFonts.outfit(fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Using AI to predict the best measurements.', style: GoogleFonts.inter(color: Colors.black87)),
          ],
        ),
      );
    }
    
    if (_aiPredictionError != null) {
      return Center(child: Text(_aiPredictionError!, style: const TextStyle(color: Colors.redAccent)));
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Prediction Results', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text("Select an option below. You can edit the values after selecting.", style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          flex: 3,
          child: ListView.builder(
            itemCount: _aiPredictions.length,
            itemBuilder: (ctx, i) {
              final p = _aiPredictions[i];
              final measurements = p['measurements'] as Map<String, dynamic>;
              final isSelected = _selectedOptionIndex == i;
              
              return GestureDetector(
                onTap: () {
                   setState(() {
                       _selectedOptionIndex = i;
                       measurements.forEach((k, v) {
                           _confirmedMeasurements[k] = v.toString();
                           _isAiGenerated[k] = true;
                       });
                   });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF1565C0).withOpacity(0.1) : Colors.black.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.black12, width: isSelected ? 2 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Option ${p['option_number']} - ${p['source']}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFF1565C0) : Colors.black87, fontSize: 16)),
                          if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
                        ],
                      ),
                      if (p['support_percent'] != null) ...[
                        const SizedBox(height: 4),
                        Text('Support: ${p['support_percent']}%', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: measurements.entries.map((e) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6), border: Border.all(color: Colors.black12)),
                          child: Text('${e.key.replaceAll('_', ' ').toUpperCase()}: ${e.value}', style: GoogleFonts.inter(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_selectedOptionIndex != null) ...[
           const SizedBox(height: 16),
           Text('Edit Selected Measurements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
           const SizedBox(height: 12),
           Expanded(
             flex: 2,
             child: ListView(
               children: _confirmedMeasurements.keys.map((k) {
                 if (_measurementTemplate?['fields']?.any((f) => f['field_name'].toString().toLowerCase() == k.toLowerCase()) ?? false) {
                     return const SizedBox.shrink();
                 }
                 return Padding(
                   padding: const EdgeInsets.only(bottom: 8.0),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text(k.replaceAll('_', ' ').toUpperCase(), style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w600)),
                       SizedBox(
                         width: 100,
                         child: TextFormField(
                           initialValue: _confirmedMeasurements[k],
                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
                           style: const TextStyle(color: Colors.black87),
                           decoration: InputDecoration(
                             isDense: true,
                             filled: true, fillColor: Colors.black.withOpacity(0.05),
                             border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                           ),
                           onChanged: (val) {
                              _confirmedMeasurements[k] = val;
                           },
                         ),
                       ),
                     ],
                   ),
                 );
               }).toList(),
             ),
           ),
        ],
      ],
    );
  }
"""

start_ai_pred = content.find("  // --- Step 4: AI Prediction Review ---")
end_ai_pred = content.find("  // --- Step 5: Preferences ---", start_ai_pred)

content = content[:start_ai_pred] + prediction_method_step + "\n" + new_ai_pred + "\n" + content[end_ai_pred:]

if "int? _selectedOptionIndex;" not in content:
    content = content.replace("bool _aiPredictionLoading = false;", "bool _aiPredictionLoading = false;\n  int? _selectedOptionIndex;")

# Hide footer on Step 3
content = content.replace("    if (isLoading) return const SizedBox.shrink();", "    if (isLoading || _currentStep == 3) return const SizedBox.shrink();")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Dart file fixed!")
