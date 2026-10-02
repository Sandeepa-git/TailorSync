import re

file_path = r"c:\Users\Sandeepa\Desktop\TailorSync\frontend\flutter_app\lib\features\orders\presentation\screens\new_order_wizard.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Update _stepTitles
old_titles = """  final List<String> _stepTitles = [
    'Customer', 'Garment', 'Priority Input', 'Prediction Method', 'AI Prediction', 
    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'
  ];"""
new_titles = """  final List<String> _stepTitles = [
    'Customer', 'Prediction Method', 'Garment', 'Priority Input', 'AI Prediction', 
    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'
  ];
  String? _predictionMethod;"""
content = content.replace(old_titles, new_titles)

# 2. Update _garmentTypes
old_garments = """  final List<Map<String, dynamic>> _garmentTypes = [
    {'name': 'Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
  ];"""
new_garments = """  final List<Map<String, dynamic>> _allGarmentTypes = [
    {'name': 'Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
    {'name': 'Jacket', 'icon': Icons.accessibility_new, 'color': Color(0xFFE91E63)},
    {'name': 'Dress', 'icon': Icons.woman, 'color': Color(0xFF9C27B0)},
    {'name': 'Skirt', 'icon': Icons.dry_cleaning, 'color': Color(0xFF00BCD4)},
  ];

  List<Map<String, dynamic>> get _garmentTypes {
      if (_predictionMethod == 'CUSTOM_ML') {
          return _allGarmentTypes.where((g) => g['name'] == 'Shirt' || g['name'] == 'Trouser').toList();
      }
      return _allGarmentTypes;
  }"""
content = content.replace(old_garments, new_garments)

# 3. Add _runPrediction method before _nextStep
run_pred = """
  Future<void> _runPrediction() async {
    setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
    try {
      final api = ref.read(apiClientProvider);
      if (_predictionMethod == 'CUSTOM_ML') {
          final req = <String, dynamic>{'garment_type': _selectedGarment!.toLowerCase()};
          _confirmedMeasurements.forEach((k, v) { req[k.toLowerCase()] = double.parse(v); });
          final resp = await api.predictMeasurements(req);
          setState(() {
            _aiPredictions = List<Map<String, dynamic>>.from(resp.data['options'] ?? []);
            _aiPredictionLoading = false;
          });
      } else {
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
      }
    } catch (e) {
      setState(() {
        _aiPredictionError = "Prediction failed: $e";
        _aiPredictionLoading = false;
      });
    }
  }

  // --- Step Navigation Logic ---"""
content = content.replace("  // --- Step Navigation Logic ---", run_pred)

# 4. Update _nextStep
old_next_step = """  // --- Step Navigation Logic ---
  Future<void> _nextStep() async {
    final api = ref.read(apiClientProvider);
    
    if (_currentStep == 0 && _selectedCustomerId == null) {
      _showSnack('⚠️ Please select a customer'); return;
    } 
    
    if (_currentStep == 1) {
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
    }
    
        if (_currentStep == 2) {
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
    
    if (_currentStep == 4) {
       // Validate that all necessary measurements are filled (either manual or AI)
    }"""
new_next_step = """  // --- Step Navigation Logic ---
  Future<void> _nextStep() async {
    final api = ref.read(apiClientProvider);
    
    if (_currentStep == 0 && _selectedCustomerId == null) {
      _showSnack('⚠️ Please select a customer'); return;
    } 
    
    if (_currentStep == 1) {
       if (_predictionMethod == null) {
          _showSnack('⚠️ Please select a prediction method'); return;
       }
       setState(() { _currentStep++; });
       return;
    }
    
    if (_currentStep == 2) {
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
    }
    
    if (_currentStep == 3) {
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
      
      _runPrediction();
      return;
    }
    
    if (_currentStep == 4) {
       // Validate that all necessary measurements are filled (either manual or AI)
    }"""
content = content.replace(old_next_step, new_next_step)

# 5. Update _buildStepContent
old_build_step = """  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildCustomerStep();
      case 1: return _buildGarmentStep();
      case 2: return _buildPriorityInputStep();
      case 3: return _buildPredictionMethodStep();
      case 4: return _buildAiPredictionStep();
      case 5: return _buildPreferencesStep();
      case 6: return _buildFabricRecStep();
      case 7: return _buildEstimationStep();
      case 8: return _buildAssignStep();
      default: return const SizedBox.shrink();
    }
  }"""
new_build_step = """  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildCustomerStep();
      case 1: return _buildPredictionMethodStep();
      case 2: return _buildGarmentStep();
      case 3: return _buildPriorityInputStep();
      case 4: return _buildAiPredictionStep();
      case 5: return _buildPreferencesStep();
      case 6: return _buildFabricRecStep();
      case 7: return _buildEstimationStep();
      case 8: return _buildAssignStep();
      default: return const SizedBox.shrink();
    }
  }"""
content = content.replace(old_build_step, new_build_step)

# 6. Update _buildPredictionMethodStep
method_step_pattern = re.compile(r"  // --- Step 4: Prediction Method ---.*?Widget _buildPredictionMethodStep\(\) \{.*?^\s*\}\n", re.MULTILINE | re.DOTALL)
new_method_step = """  // --- Step 1: Prediction Method ---
  Widget _buildPredictionMethodStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Select Prediction Model', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text('Choose how you want AI to assist with measurements.', style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        
        // Foundry
        GestureDetector(
          onTap: () => setState(() => _predictionMethod = 'FOUNDRY'),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _predictionMethod == 'FOUNDRY' ? const Color(0xFF1565C0).withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _predictionMethod == 'FOUNDRY' ? const Color(0xFF1565C0) : Colors.black12, width: _predictionMethod == 'FOUNDRY' ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, size: 40, color: _predictionMethod == 'FOUNDRY' ? const Color(0xFF1565C0) : Colors.black54),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Foundry', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Full clothing prediction. Uses existing AI model with all supported clothing categories.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                if (_predictionMethod == 'FOUNDRY') const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Custom ML
        GestureDetector(
          onTap: () => setState(() {
             _predictionMethod = 'CUSTOM_ML';
             if (_selectedGarment != 'Shirt' && _selectedGarment != 'Trouser') {
                 _selectedGarment = null;
             }
          }),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _predictionMethod == 'CUSTOM_ML' ? const Color(0xFF1565C0).withOpacity(0.1) : Colors.black.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _predictionMethod == 'CUSTOM_ML' ? const Color(0xFF1565C0) : Colors.black12, width: _predictionMethod == 'CUSTOM_ML' ? 2 : 1),
            ),
            child: Row(
              children: [
                Icon(Icons.flash_on, size: 40, color: _predictionMethod == 'CUSTOM_ML' ? const Color(0xFF1565C0) : Colors.black54),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Custom ML Model', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
                      const SizedBox(height: 4),
                      Text('Our trained internal model. Currently supports ONLY Shirts and Trousers.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 13)),
                    ],
                  ),
                ),
                if (_predictionMethod == 'CUSTOM_ML') const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
              ],
            ),
          ),
        ),
      ],
    );
  }
"""
content = method_step_pattern.sub(new_method_step, content)

# 7. Update Footer condition
old_footer = """  Widget _buildFooter() {
    bool isLoading = _aiPredictionLoading || _fabricRecLoading || _fabricEstLoading || _loadingInit || _loadingTemplate;
    if (isLoading || _currentStep == 3) return const SizedBox.shrink();"""
new_footer = """  Widget _buildFooter() {
    bool isLoading = _aiPredictionLoading || _fabricRecLoading || _fabricEstLoading || _loadingInit || _loadingTemplate;
    if (isLoading) return const SizedBox.shrink();"""
content = content.replace(old_footer, new_footer)

# 8. Update _saveOrder
old_save_order = """      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
        'priority': 'Medium',
        'style_preferences': {'occasion': _occasion, 'weather': _weather, 'fabric_feel': _fabricPreferences, 'fit': _fit},
      };"""
new_save_order = """      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
        'prediction_method': _predictionMethod,
        'priority': 'Medium',
        'style_preferences': {'occasion': _occasion, 'weather': _weather, 'fabric_feel': _fabricPreferences, 'fit': _fit},
      };"""
content = content.replace(old_save_order, new_save_order)

# 9. Update _summaryRow inside Assign Step
old_summary = """                 _summaryRow('Customer', _selectedCustomerName ?? ''),
                 _summaryRow('Garment', _selectedGarment ?? ''),
                 _summaryRow('Fabric', _fabricRecommendations.isNotEmpty && _selectedFabricIndex != null ? _fabricRecommendations[_selectedFabricIndex!]['fabric_name'] : 'N/A'),"""
new_summary = """                 _summaryRow('Customer', _selectedCustomerName ?? ''),
                 _summaryRow('Prediction Model', _predictionMethod == 'FOUNDRY' ? 'AI Foundry' : 'Custom ML Model'),
                 _summaryRow('Garment', _selectedGarment ?? ''),
                 _summaryRow('Fabric', _fabricRecommendations.isNotEmpty && _selectedFabricIndex != null ? _fabricRecommendations[_selectedFabricIndex!]['fabric_name'] : 'N/A'),"""
content = content.replace(old_summary, new_summary)


with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Update complete")
