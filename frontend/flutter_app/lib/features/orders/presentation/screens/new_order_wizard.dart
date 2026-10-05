import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../../ui/ui.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../presentation/providers/orders_provider.dart';
import '../../blueprints/garment_blueprints.dart';

class NewOrderWizard extends ConsumerStatefulWidget {
  const NewOrderWizard({super.key});

  @override
  ConsumerState<NewOrderWizard> createState() => _NewOrderWizardState();
}

class _NewOrderWizardState extends ConsumerState<NewOrderWizard> with TickerProviderStateMixin {
  int _currentStep = 0;
  bool _saving = false;
  Map<String, dynamic>? _user;
  List<dynamic> _staffList = [];
  bool _loadingInit = true;
  
  late AnimationController _pulseController;
  
  final List<String> _stepTitles = [
    'Customer', 'Prediction Method', 'Garment', 'Priority Input', 'AI Prediction', 
    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'
  ];
  String? _predictionMethod;
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _loadInitData();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    for (var ctrl in _measurementControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _customMeasurementControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }
  Future<void> _loadInitData() async {
    try {
      final api = ref.read(apiClientProvider);
      // Perf: fire both independent requests together.
      final results = await Future.wait([api.getMe(), api.listStaff()]);
      final userResp = results[0];
      final staffResp = results[1];
      if (mounted) {
        setState(() {
          _user = userResp.data;
          List<dynamic> fetchedStaff = staffResp.data ?? [];
          
          // Ensure current user is in the assignable list
          if (_user != null) {
            bool userInList = fetchedStaff.any((s) => s['id'] == _user!['id']);
            if (!userInList) {
               fetchedStaff.insert(0, _user!);
            }
          }
          
          _staffList = fetchedStaff;

          if (_user?['role'] == 'staff' || _user?['role'] == 'STAFF') {
            _selectedStaffId = _user?['id'];
          } else if (_staffList.isNotEmpty) {
            _selectedStaffId = _staffList.first['id'];
          } else {
            _selectedStaffId = _user?['id'];
          }
          _loadingInit = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loadingInit = false);
    }
  }
  // --- State for Steps ---
  // Step 1: Customer
  int? _selectedCustomerId;
  String? _selectedCustomerName;
  String _customerSearch = '';
  // Step 2: Garment
  String? _selectedGarment;
  final List<Map<String, dynamic>> _allGarmentTypes = [
    {'name': 'Long Sleeve Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Short Sleeve Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Long Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
    {'name': 'Short Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
    {'name': 'Jacket', 'icon': Icons.accessibility_new, 'color': Color(0xFFE91E63)},
    {'name': 'Dress', 'icon': Icons.woman, 'color': Color(0xFF9C27B0)},
    {'name': 'Skirt', 'icon': Icons.dry_cleaning, 'color': Color(0xFF00BCD4)},
  ];
  List<Map<String, dynamic>> get _garmentTypes {
      if (_predictionMethod == 'CUSTOM_ML') {
          return _allGarmentTypes.where((g) => g['name'].contains('Shirt') || g['name'].contains('Trouser')).toList();
      }
      return _allGarmentTypes;
  }
  // Step 3: Priority Measurements
  Map<String, dynamic>? _measurementTemplate;
  bool _loadingTemplate = false;
  final Map<int, TextEditingController> _measurementControllers = {}
;
  
  // Custom added measurements
  final List<Map<String, dynamic>> _customMeasurements = [];
  final Map<int, TextEditingController> _customMeasurementControllers = {}
;
  int _customMeasurementCounter = 0;
  
    Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {
      List<Map<String, dynamic>> fields = [];
      if (cat.contains('Shirt')) {
        fields = [
          {'id': 1, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 9.5', 'help': 'Shoulder width'},
          {'id': 2, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 29', 'help': 'Shirt length (not body height)'},
          {'id': 3, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 38', 'help': 'Around the chest'},
        ];
      } else if (cat.contains('Trouser')) {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 32', 'help': 'Trouser length (not body height)'},
          {'id': 2, 'field_name': 'Waist', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 32', 'help': 'Around the waist'},
          {'id': 3, 'field_name': 'Seat', 'unit': 'in', 'is_required': true, 'placeholder': 'e.g. 36', 'help': 'Around the hips/seat'},
        ];
      }
      return {'category_name': cat, 'fields': fields};
  }
  // Step 4: AI Predictions
  List<Map<String, dynamic>> _aiPredictions = [];
  Map<String, String> _confirmedMeasurements = {}
;
  Map<String, bool> _isAiGenerated = {}
;
  bool _aiPredictionLoading = false;
  int? _selectedOptionIndex;
  String? _aiPredictionError;
  // Step 5: Style Preferences
  String _occasion = 'Everyday / Casual';
  String _weather = 'Warm';
  final List<String> _fabricPreferences = ['Soft', 'Breathable'];
  String _fit = 'Regular Fit';
  // Step 6: Fabric Recommendations
  List<Map<String, dynamic>> _fabricRecommendations = [];
  int? _selectedFabricIndex;
  bool _fabricRecLoading = false;
  String? _fabricRecError;
  // Step 7: Fabric Estimation
  Map<String, dynamic>? _fabricEstimation;
  bool _fabricEstLoading = false;
  String? _fabricEstError;
  TextEditingController _manualQuantityCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController(); // optional order price (LKR)
  // Step 8: Assign
  int? _selectedStaffId = 1;
 

  Future<void> _runPrediction() async {
    setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
    try {
      final api = ref.read(apiClientProvider);
      if (_predictionMethod == 'CUSTOM_ML') {
          String mlType = _selectedGarment!.contains('Shirt') ? 'shirt' : 'trouser';
          final req = <String, dynamic>{'garment_type': mlType};
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
            double? toNum(dynamic v) =>
                double.tryParse(RegExp(r'-?\d+(\.\d+)?').firstMatch(v?.toString() ?? '')?.group(0) ?? '');

            // One card with ALL recommended values, plus up to two alternative
            // sets built from each measurement's alternatives.
            final recommended = <String, dynamic>{};
            final alt1 = <String, dynamic>{};
            final alt2 = <String, dynamic>{};
            for (final p in preds) {
              final name = p['measurement']?.toString();
              if (name == null || name.isEmpty) continue;
              final rec = toNum(p['recommended']) ?? 0.0;
              recommended[name] = rec;
              final alts = (p['alternatives'] as List?) ?? const [];
              alt1[name] = alts.isNotEmpty ? (toNum(alts[0]) ?? rec) : rec;
              alt2[name] = alts.length > 1 ? (toNum(alts[1]) ?? rec) : rec;
            }

            _aiPredictions = [];
            if (recommended.isNotEmpty) {
              _aiPredictions.add({'option_number': 1, 'source': 'Recommended Measurements', 'support_percent': null, 'measurements': recommended});
              bool differs(Map<String, dynamic> m) => m.entries.any((e) => e.value != recommended[e.key]);
              if (differs(alt1)) {
                _aiPredictions.add({'option_number': 2, 'source': 'Alternative 1', 'support_percent': null, 'measurements': alt1});
              }
              if (differs(alt2) && alt2.toString() != alt1.toString()) {
                _aiPredictions.add({'option_number': 3, 'source': 'Alternative 2', 'support_percent': null, 'measurements': alt2});
              }
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
  // --- Step Navigation Logic ---
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
         String mlType = _selectedGarment!.contains('Shirt') ? 'shirt' : (_selectedGarment!.contains('Trouser') ? 'trouser' : _selectedGarment!.toLowerCase());
         final rangesResp = await api.getMeasurementInputRanges(mlType);
         final ranges = rangesResp.data['ranges'] as Map<String, dynamic>;
         for (var f in _measurementTemplate!['fields']) {
             final fieldName = (f['field_name'] as String).toLowerCase();
             final rangeData = ranges[fieldName];
             if (rangeData != null) {
                 f['min'] = rangeData['min'];
                 f['max'] = rangeData['max'];
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
    }

    if (_currentStep == 5) {
      setState(() { _fabricRecLoading = true; _fabricRecError = null; _currentStep++; });
      try {
        final resp = await api.recommendFabric({
          'garment_type': _selectedGarment,
          'occasion': _occasion,
          'weather': _weather,
          'fabric_preferences': _fabricPreferences,
          'fit': _fit
        });
        setState(() {
          _fabricRecommendations = List<Map<String, dynamic>>.from(resp.data['recommendations'] ?? []);
          _selectedFabricIndex = null;
          _fabricRecLoading = false;
        });
      } catch (e) {
        String errorMsg = "Fabric AI unavailable.";
        if (e is DioException && e.response?.data != null && e.response!.data is Map && (e.response!.data as Map).containsKey('detail')) {
            errorMsg = (e.response!.data as Map)['detail'].toString();
        }
        setState(() { _fabricRecError = errorMsg; _fabricRecLoading = false; });
      }
      return;
    }

    if (_currentStep == 6) {
      if (_selectedFabricIndex == null && _fabricRecError == null) {
        _showSnack('⚠️ Please select a fabric recommendation'); return;
      }
      String selectedFabric = "Manual Fabric";
      if (_selectedFabricIndex != null && _fabricRecommendations.isNotEmpty) {
         selectedFabric = _fabricRecommendations[_selectedFabricIndex!]['fabric_name'];
      }
      
      setState(() { _fabricEstLoading = true; _fabricEstError = null; _currentStep++; });
      try {
        final resp = await api.estimateFabric({
          'garment_type': _selectedGarment,
          'fabric': selectedFabric,
          'measurements': _confirmedMeasurements
        });
        setState(() {
          _fabricEstimation = resp.data;
          if (_fabricEstimation != null && _fabricEstimation!['recommended_quantity_meters'] != null) {
              _manualQuantityCtrl.text = _fabricEstimation!['recommended_quantity_meters'].toString();
          }
          _fabricEstLoading = false;
        });
      } catch (e) {
        String errorMsg = "Fabric estimation unavailable.";
        if (e is DioException && e.response?.data != null && e.response!.data is Map && (e.response!.data as Map).containsKey('detail')) {
            errorMsg = (e.response!.data as Map)['detail'].toString();
        }
        setState(() { _fabricEstError = errorMsg; _fabricEstLoading = false; });
      }
      return;
    }

    if (_currentStep == 7) {
        if (_manualQuantityCtrl.text.isEmpty || double.tryParse(_manualQuantityCtrl.text) == null) {
            _showSnack('⚠️ Please enter a valid quantity'); return;
        }
    }

    setState(() { _currentStep++; });
  }
  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  // ── UI-only state ──────────────────────────────────────────────
  int _lastStep = 0; // used to pick the slide direction

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
        'prediction_method': _predictionMethod,
        'priority': 'Medium',
        'style_preferences': {'occasion': _occasion, 'weather': _weather, 'fabric_feel': _fabricPreferences, 'fit': _fit},
      };
      if (_selectedStaffId != null) body['staff_id'] = _selectedStaffId;
      
      final mList = <Map<String, dynamic>>[];
      _confirmedMeasurements.forEach((k, v) {
          mList.add({'field_name': k, 'value': double.tryParse(v) ?? 0.0, 'is_ai_generated': _isAiGenerated[k] ?? false});
      });
      body['measurements'] = mList;
      
      if (_selectedFabricIndex != null && _fabricRecommendations.isNotEmpty) {
        body['selected_fabric'] = _fabricRecommendations[_selectedFabricIndex!]['fabric_name'];
      }
      body['fabric_estimation'] = {'recommended_quantity_meters': double.tryParse(_manualQuantityCtrl.text) ?? 2.0};
      final price = double.tryParse(_priceCtrl.text.replaceAll(',', '').trim());
      if (price != null && price > 0) body['total_price'] = price;

      await api.createOrder(body);
      ref.invalidate(ordersProvider);
      ref.read(refreshTriggerProvider.notifier).state++; // refresh dashboard, reports, inventory badge
      if (mounted) context.go('/orders');
    } catch (e) {
      _showSnack('Failed to save order: $e');
    }
    if (mounted) setState(() => _saving = false);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: context.status.danger),
            const SizedBox(width: Space.sm),
            Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600))),
          ],
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    final forward = _currentStep >= _lastStep;
    _lastStep = _currentStep;
    final pad = context.pagePadding;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentStep > 0) {
          _prevStep();
        } else {
          context.go('/home');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Close wizard',
            icon: const Icon(Icons.close_rounded),
            onPressed: () {
              context.go('/home');
            },
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome_rounded, size: 20, color: context.colors.primary),
              const SizedBox(width: Space.xs),
              const Flexible(child: Text('TailorSync AI Wizard', overflow: TextOverflow.ellipsis)),
            ],
          ),
          centerTitle: true,
        ),
        body: AmbientBackground(
          child: SafeArea(
            top: false,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusScope.of(context).unfocus(),
              child: MaxWidthBox(
                maxWidth: MaxWidth.content,
                child: Column(
                  children: [
                    _buildStepper(),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: Motion.of(context, Motion.long),
                        switchInCurve: Motion.emphasizedDecelerate,
                        switchOutCurve: Motion.exit,
                        transitionBuilder: (w, anim) {
                          final incoming = w.key == ValueKey<int>(_currentStep);
                          final dir = (forward ? 1.0 : -1.0) * (incoming ? 1 : -1);
                          return FadeTransition(
                            opacity: anim,
                            child: SlideTransition(
                              position: Tween<Offset>(begin: Offset(0.08 * dir, 0), end: Offset.zero).animate(anim),
                              child: w,
                            ),
                          );
                        },
                        child: Container(
                          key: ValueKey<int>(_currentStep),
                          padding: EdgeInsets.fromLTRB(pad, Space.sm, pad, 0),
                          child: _buildStepContent(),
                        ),
                      ),
                    ),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    final cs = context.colors;
    final pad = context.pagePadding;
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, Space.xs, pad, Space.sm),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${_currentStep + 1} of ${_stepTitles.length}',
                style: context.text.labelMedium?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(width: Space.sm),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: AnimatedSwitcher(
                    duration: Motion.of(context, Motion.medium),
                    transitionBuilder: (w, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim),
                        child: w,
                      ),
                    ),
                    child: Text(
                      _stepTitles[_currentStep],
                      key: ValueKey<int>(_currentStep),
                      style: context.text.titleSmall?.copyWith(color: cs.primary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.sm),
          Semantics(
            label: 'Step ${_currentStep + 1} of ${_stepTitles.length}: ${_stepTitles[_currentStep]}',
            child: Row(
              children: List.generate(_stepTitles.length, (index) {
                final isActive = index <= _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  flex: isCurrent ? 3 : 2,
                  child: AnimatedContainer(
                    duration: Motion.of(context, Motion.medium),
                    curve: Motion.emphasized,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: isCurrent ? 6 : 4,
                    decoration: BoxDecoration(
                      color: isActive ? cs.primary : cs.outlineVariant.withValues(alpha: 0.6),
                      borderRadius: Radii.brPill,
                      boxShadow: isCurrent ? [BoxShadow(color: cs.primary.withValues(alpha: 0.4), blurRadius: 6)] : null,
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
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
  }

  // Shared heading used by every step.
  Widget _stepHeader(String title, [String? subtitle, IconData? icon]) {
    return EntranceFade(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: context.colors.primary),
                  const SizedBox(width: Space.xs),
                ],
                Expanded(child: Text(title, style: context.text.headlineSmall)),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: Space.xxs),
              Text(subtitle, style: context.text.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }

  // Selectable card used by several steps.
  Widget _selectCard({
    required bool selected,
    required VoidCallback onTap,
    required Widget child,
    Color? accent,
    EdgeInsetsGeometry padding = const EdgeInsets.all(Space.md),
  }) {
    final cs = context.colors;
    final a = accent ?? cs.primary;
    return Semantics(
      selected: selected,
      button: true,
      child: Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.short),
          curve: Motion.standard,
          padding: padding,
          decoration: BoxDecoration(
            color: selected ? a.withValues(alpha: context.isDark ? 0.20 : 0.10) : cs.surfaceContainerLowest,
            borderRadius: Radii.brLg,
            border: Border.all(color: selected ? a : cs.outlineVariant.withValues(alpha: 0.6), width: selected ? 2 : 1),
            boxShadow: selected ? [BoxShadow(color: a.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))] : Shadows.soft(cs),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _check(bool on, [Color? color]) => AnimatedScale(
        scale: on ? 1 : 0,
        duration: Motion.of(context, Motion.short),
        curve: Motion.spring,
        child: Icon(Icons.check_circle_rounded, color: color ?? context.colors.primary),
      );

  Widget _aiLoader({required IconData icon, required Color color, required String title, required String subtitle}) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeTransition(
              opacity: Tween<double>(begin: 0.85, end: 1).animate(_pulseController),
              child: StitchLoader(size: 104, color: color, center: Icon(icon, color: color, size: 30)),
            ),
            const SizedBox(height: Space.xl),
            Text(title, textAlign: TextAlign.center, style: context.text.titleLarge),
            const SizedBox(height: Space.xs),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.lg),
              child: Text(subtitle, textAlign: TextAlign.center, style: context.text.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inlineError(String text) => Center(
        child: EmptyState(icon: Icons.cloud_off_rounded, title: 'Something went wrong', message: text),
      );

  // --- Step 1: Customer ---
  Widget _buildCustomerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader('Who is this order for?', 'Select an existing client or create a new profile.'),
        TextField(
          onChanged: (v) => setState(() => _customerSearch = v),
          textInputAction: TextInputAction.search,
          decoration: const InputDecoration(
            hintText: 'Search by name or phone...',
            prefixIcon: Icon(Icons.search_rounded),
          ),
        ),
        const SizedBox(height: Space.md),
        Expanded(
          child: Consumer(builder: (ctx, ref, child) {
            final customersAsync = ref.watch(customersProvider);
            return customersAsync.when(
              data: (customers) {
                final filtered = customers.where((c) => c.name.toLowerCase().contains(_customerSearch.toLowerCase()) || (c.phone ?? '').contains(_customerSearch)).toList();
                if (filtered.isEmpty) {
                  return EmptyState(
                    icon: Icons.person_search_rounded,
                    title: 'No customers found',
                    actionLabel: 'Create New Customer',
                    actionIcon: Icons.person_add_alt_1_rounded,
                    onAction: () => context.push('/customers/new'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.only(bottom: Space.md),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: Space.sm),
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final isSelected = _selectedCustomerId == c.id;
                    return EntranceFade.indexed(
                      i,
                      child: _selectCard(
                        selected: isSelected,
                        onTap: () => setState(() { _selectedCustomerId = c.id; _selectedCustomerName = c.name; }),
                        padding: const EdgeInsets.all(Space.sm + 2),
                        child: Row(
                          children: [
                            InitialsAvatar(name: c.name),
                            const SizedBox(width: Space.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.name, style: context.text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(c.phone ?? 'No phone', style: context.text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                            _check(isSelected),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: ScissorLoader()),
              error: (e, _) => const Center(child: Text('Error loading customers')),
            );
          }),
        ),
      ],
    );
  }

  // --- Step 2: Garment ---
  Widget _buildGarmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader('What are we making?', 'Our AI will tailor the measurement flow based on this choice.'),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: Space.md),
            gridDelegate: adaptiveGrid(maxTileWidth: 200, mainAxisExtent: context.isSmallPhone ? 120 : 136, spacing: context.gridGap),
            itemCount: _garmentTypes.length,
            itemBuilder: (ctx, i) {
              final g = _garmentTypes[i];
              final isSelected = _selectedGarment == g['name'];
              final Color color = g['color'];
              return EntranceFade.indexed(
                i,
                child: _selectCard(
                  selected: isSelected,
                  accent: color,
                  onTap: () => setState(() => _selectedGarment = g['name']),
                  padding: const EdgeInsets.all(Space.sm),
                  child: Stack(
                    children: [
                      Positioned(top: 0, right: 0, child: _check(isSelected, color)),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedScale(
                              scale: isSelected ? 1.12 : 1,
                              duration: Motion.of(context, Motion.medium),
                              curve: Motion.spring,
                              child: IconBadge(icon: g['icon'], color: color, size: 52),
                            ),
                            const SizedBox(height: Space.sm),
                            Text(
                              g['name'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.labelLarge?.copyWith(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Step 1: Prediction Method ---
  Widget _buildPredictionMethodStep() {
    Widget option({
      required bool selected,
      required VoidCallback onTap,
      required IconData icon,
      required String title,
      required String body,
      required Color color,
    }) {
      return _selectCard(
        selected: selected,
        accent: color,
        onTap: onTap,
        padding: const EdgeInsets.all(Space.md + 4),
        child: Row(
          children: [
            IconBadge(icon: icon, color: color, size: 52),
            const SizedBox(width: Space.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: context.text.titleMedium),
                  const SizedBox(height: Space.xxs),
                  Text(body, style: context.text.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            _check(selected, color),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Space.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader('Select Prediction Model', 'Choose how you want AI to assist with measurements.'),
          EntranceFade.indexed(
            1,
            child: option(
              selected: _predictionMethod == 'FOUNDRY',
              onTap: () => setState(() => _predictionMethod = 'FOUNDRY'),
              icon: Icons.psychology_rounded,
              title: 'AI Foundry',
              body: 'Full clothing prediction. Uses existing AI model with all supported clothing categories.',
              color: context.colors.tertiary,
            ),
          ),
          const SizedBox(height: Space.md),
          EntranceFade.indexed(
            2,
            child: option(
              selected: _predictionMethod == 'CUSTOM_ML',
              onTap: () => setState(() {
                 _predictionMethod = 'CUSTOM_ML';
                 if (!(_selectedGarment?.contains('Shirt') ?? false) && !(_selectedGarment?.contains('Trouser') ?? false)) {
                     _selectedGarment = null;
                 }
              }),
              icon: Icons.bolt_rounded,
              title: 'Custom ML Model',
              body: 'Our trained internal model. Currently supports ONLY Shirts and Trousers.',
              color: context.status.success,
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Priority Input ---
  Widget _buildPriorityInputStep() {
    if (_loadingTemplate) return const Center(child: ScissorLoader());
    
    final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();
    final requiredFields = fields.where((f) => f['is_required'] == true).toList();
    final optionalFields = fields.where((f) => f['is_required'] != true).toList();
    
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader(
            'Measurements Input',
            'Provide required measurements. Optional ones can be left blank, and AI can suggest them.',
            Icons.auto_awesome_rounded,
          ),
          if (requiredFields.isNotEmpty) ...[
            Text('Required Measurements', style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            ...requiredFields.map((f) => _buildMeasurementRow(f, true)),
            const SizedBox(height: Space.md),
          ],
          if (optionalFields.isNotEmpty) ...[
            Text('Optional Measurements', style: context.text.titleSmall),
            const SizedBox(height: Space.sm),
            ...optionalFields.map((f) => _buildMeasurementRow(f, false)),
            const SizedBox(height: Space.md),
          ],
          AnimatedSize(
            duration: Motion.of(context, Motion.medium),
            curve: Motion.emphasized,
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_customMeasurements.isNotEmpty) ...[
                  Text('Custom Measurements', style: context.text.titleSmall),
                  const SizedBox(height: Space.sm),
                  ..._customMeasurements.map((f) => _buildCustomMeasurementRow(f)),
                  const SizedBox(height: Space.md),
                ],
              ],
            ),
          ),
          Center(
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _customMeasurementCounter++;
                  final newId = 1000 + _customMeasurementCounter;
                  _customMeasurements.add({'id': newId, 'field_name': ''});
                  _customMeasurementControllers[newId] = TextEditingController();
                });
              },
              icon: const Icon(Icons.add_circle_outline_rounded),
              label: const Text('Add Other Measurement'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementRow(Map<String, dynamic> f, bool isRequired) {
    final cs = context.colors;
    final fieldW = context.responsive<double>(xs: 104, sm: 116, md: 128);
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: TsCard(
        shadow: false,
        padding: const EdgeInsets.fromLTRB(Space.md, Space.sm, Space.sm, Space.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          f['field_name'],
                          style: context.text.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRequired) Text(' *', style: TextStyle(fontWeight: FontWeight.w800, color: cs.error)),
                    ],
                  ),
                  Text(
                    [
                      if (f['help'] != null) f['help'],
                      if (f['min'] != null && f['max'] != null) '${f['min']}–${f['max']} in',
                      if (f['help'] == null) (isRequired ? 'Required' : 'Optional'),
                    ].join(' · '),
                    style: context.text.labelSmall?.copyWith(color: isRequired ? cs.primary : cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: Space.xs),
            SizedBox(
              width: fieldW,
              child: TextField(
                controller: _measurementControllers[f['id']],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: context.text.titleSmall,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: f['placeholder'] ?? 'e.g. 10.5',
                  hintStyle: context.text.bodySmall,
                  suffixText: f['unit'],
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: Space.xs, vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomMeasurementRow(Map<String, dynamic> f) {
    final id = f['id'] as int;
    return Padding(
      key: ValueKey('custom-$id'),
      padding: const EdgeInsets.only(bottom: Space.sm),
      child: EntranceFade(
        child: TsCard(
          shadow: false,
          padding: const EdgeInsets.fromLTRB(Space.md, Space.xs, Space.xxs, Space.xs),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    final idx = _customMeasurements.indexWhere((m) => m['id'] == id);
                    if (idx != -1) _customMeasurements[idx]['field_name'] = val;
                  },
                  textCapitalization: TextCapitalization.words,
                  style: context.text.titleSmall,
                  decoration: const InputDecoration(
                    hintText: 'Measurement Name',
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
              SizedBox(
                width: context.responsive<double>(xs: 88, md: 104),
                child: TextField(
                  controller: _customMeasurementControllers[id],
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                  ],
                  style: context.text.titleSmall,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0.0',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: Space.xs, vertical: 12),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove measurement',
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  setState(() {
                    _customMeasurements.removeWhere((m) => m['id'] == id);
                    _customMeasurementControllers.remove(id)?.dispose();
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }


  // --- Step 5: AI Prediction Review ---
  Widget _buildAiPredictionStep() {
    if (_aiPredictionLoading) {
      return _aiLoader(
        icon: _predictionMethod == 'FOUNDRY' ? Icons.auto_awesome_rounded : Icons.memory_rounded,
        color: _predictionMethod == 'FOUNDRY' ? context.colors.tertiary : context.status.success,
        title: _predictionMethod == 'FOUNDRY' ? 'Microsoft Foundry is Thinking...' : 'Running Custom ML...',
        subtitle: _predictionMethod == 'FOUNDRY'
            ? 'Analyzing dataset context to generate perfect measurements.'
            : 'Processing garment features through the predictive model.',
      );
    }
    
    if (_aiPredictionError != null) {
      return _inlineError(_aiPredictionError!);
    }
    
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader('Prediction Results', 'Select an option below. You can edit the values after selecting.'),
        Expanded(
          flex: 3,
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: Space.sm),
            itemCount: _aiPredictions.length,
            itemBuilder: (ctx, i) {
              final p = _aiPredictions[i];
              final measurements = p['measurements'] as Map<String, dynamic>;
              final isSelected = _selectedOptionIndex == i;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: EntranceFade.indexed(
                  i,
                  child: _selectCard(
                    selected: isSelected,
                    onTap: () {
                       setState(() {
                           _selectedOptionIndex = i;
                           measurements.forEach((k, v) {
                               if (v.toString() != '0' && v.toString() != '0.0') {
                                   _confirmedMeasurements[k] = v.toString();
                                   _isAiGenerated[k] = true;
                               }
                           });
                       });
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                _predictionMethod == 'FOUNDRY'
                                    ? '${p['source']}'
                                    : 'Option ${p['option_number']} - ${p['source']}',
                                style: context.text.titleSmall?.copyWith(color: isSelected ? cs.primary : null),
                              ),
                            ),
                            _check(isSelected),
                          ],
                        ),
                        if (p['support_percent'] != null) ...[
                          const SizedBox(height: Space.xxs),
                          StatusPill(label: 'Support: ${p['support_percent']}%', color: context.status.success, dense: true),
                        ],
                        const SizedBox(height: Space.sm),
                        Wrap(
                          spacing: Space.xs,
                          runSpacing: Space.xs,
                          children: measurements.entries
                              .where((e) => e.value.toString() != '0' && e.value.toString() != '0.0')
                              .map((e) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: cs.surfaceContainerHigh,
                                      borderRadius: Radii.brPill,
                                    ),
                                    child: Text(
                                      '${e.key.replaceAll('_', ' ').toUpperCase()}: ${e.value}',
                                      style: context.text.labelSmall?.copyWith(color: cs.onSurface),
                                    ),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        AnimatedSize(
          duration: Motion.of(context, Motion.medium),
          curve: Motion.emphasized,
          child: _selectedOptionIndex != null
              ? Padding(
                  padding: const EdgeInsets.only(top: Space.xs, bottom: Space.sm),
                  child: TsButton.secondary(
                    label: 'Edit Measurements',
                    icon: Icons.edit_rounded,
                    onPressed: _showEditMeasurementsDialog,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  void _showEditMeasurementsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(modalCtx).viewInsets.bottom),
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                constraints: BoxConstraints(maxHeight: MediaQuery.of(modalCtx).size.height * 0.8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Edit Measurements', style: Theme.of(modalCtx).textTheme.titleLarge),
                        IconButton(tooltip: 'Close', icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(modalCtx)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Adjust the AI recommendations manually if needed.', style: Theme.of(modalCtx).textTheme.bodyMedium),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: _confirmedMeasurements.keys.map((k) {
                          if (_measurementTemplate?['fields']?.any((f) => f['field_name'].toString().toLowerCase() == k.toLowerCase()) ?? false) {
                              return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(k.replaceAll('_', ' ').toUpperCase(), style: Theme.of(modalCtx).textTheme.titleSmall)),
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    initialValue: _confirmedMeasurements[k],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: 'Rec: ${_confirmedMeasurements[k]}',
                                    ),
                                    onChanged: (val) {
                                       setState(() {
                                           _confirmedMeasurements[k] = val;
                                       });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(modalCtx),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Step 5: Preferences ---
  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepHeader('Style & Fit', 'Tell the AI about the occasion so it can recommend the right fabric.'),
          EntranceFade.indexed(1, child: _buildChipSelector('Occasion', ['Everyday / Casual', 'Office / Work', 'Wedding', 'Party'], _occasion, (v) => setState(()=> _occasion = v))),
          const SizedBox(height: Space.lg),
          EntranceFade.indexed(2, child: _buildChipSelector('Weather', ['Warm', 'Hot', 'Cold', 'Humid'], _weather, (v) => setState(()=> _weather = v))),
          const SizedBox(height: Space.lg),
          EntranceFade.indexed(3, child: _buildChipSelector('Fit', ['Regular Fit', 'Slim Fit', 'Modern Fit'], _fit, (v) => setState(()=> _fit = v))),
        ],
      ),
    );
  }

  Widget _buildChipSelector(String title, List<String> options, String selected, Function(String) onSelect) {
    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: context.text.titleSmall),
        const SizedBox(height: Space.sm),
        Wrap(
          spacing: Space.xs, runSpacing: Space.xs,
          children: options.map((opt) {
            final isSel = selected == opt;
            return Semantics(
              selected: isSel,
              button: true,
              child: Pressable(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onSelect(opt);
                },
                child: AnimatedContainer(
                  duration: Motion.of(context, Motion.short),
                  curve: Motion.standard,
                  constraints: const BoxConstraints(minHeight: 44),
                  padding: const EdgeInsets.symmetric(horizontal: Space.md, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSel ? cs.primary : cs.surfaceContainerLowest,
                    borderRadius: Radii.brPill,
                    border: Border.all(color: isSel ? cs.primary : cs.outlineVariant),
                    boxShadow: isSel ? [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))] : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSize(
                        duration: Motion.of(context, Motion.short),
                        child: isSel
                            ? Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(Icons.check_rounded, size: 16, color: cs.onPrimary),
                              )
                            : const SizedBox.shrink(),
                      ),
                      Text(
                        opt,
                        style: context.text.labelLarge?.copyWith(
                          color: isSel ? cs.onPrimary : cs.onSurface,
                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Step 6: Fabric Rec ---
  Widget _buildFabricRecStep() {
    if (_fabricRecLoading) {
      return _aiLoader(
        icon: Icons.style_rounded,
        color: context.colors.tertiary,
        title: 'Analyzing Preferences...',
        subtitle: 'Curating the best fabric options for your style.',
      );
    }
    if (_fabricRecError != null) return _inlineError(_fabricRecError!);

    final cs = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _stepHeader('Top Fabrics', 'Pick the fabric that suits this order best.'),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: Space.md),
            itemCount: _fabricRecommendations.length,
            itemBuilder: (ctx, i) {
              final rec = _fabricRecommendations[i];
              final isSel = _selectedFabricIndex == i;
              final pct = num.tryParse('${rec['suitability_percentage']}') ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: Space.sm),
                child: EntranceFade.indexed(
                  i,
                  child: _selectCard(
                    selected: isSel,
                    onTap: () => setState(() => _selectedFabricIndex = i),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: (pct / 100).clamp(0, 1).toDouble()),
                                duration: Motion.of(context, const Duration(milliseconds: 800)),
                                curve: Motion.emphasizedDecelerate,
                                builder: (context, v, _) => SizedBox.expand(
                                  child: CircularProgressIndicator(
                                    value: v,
                                    strokeWidth: 5,
                                    color: cs.primary,
                                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                              Text('${rec['suitability_percentage']}%', style: context.text.labelLarge?.copyWith(color: cs.primary)),
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(rec['fabric_name'] ?? '', style: context.text.titleMedium),
                              const SizedBox(height: Space.xxs),
                              Text(rec['reason'] ?? '', style: context.text.bodySmall),
                              if (rec['stock_status'] != null) ...[
                                const SizedBox(height: Space.xs),
                                _stockPill(rec),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: Space.xs),
                        _check(isSel),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Step 7: Estimation ---
  Widget _buildEstimationStep() {
    if (_fabricEstLoading) {
      return _aiLoader(
        icon: Icons.straighten_rounded,
        color: context.status.success,
        title: 'Estimating Required Fabric...',
        subtitle: 'Calculating exact meterage based on measurements.',
      );
    }
    
    final cs = context.colors;
    final meters = num.tryParse('${_fabricEstimation?['recommended_quantity_meters'] ?? '2.0'}');
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _stepHeader('Fabric Estimate', 'Review the AI estimate or override it.'),
          EntranceFade(
            delay: Motion.staggerStep,
            child: TsCard(
              gradient: Gradients.hero(cs),
              padding: EdgeInsets.all(context.isSmallPhone ? Space.lg : Space.xl),
              child: Column(
                children: [
                  const Icon(Icons.straighten_rounded, size: 48, color: Colors.white),
                  const SizedBox(height: Space.sm),
                  Text('Fabric Required', style: context.text.titleMedium?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
                  const SizedBox(height: Space.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: meters == null
                        ? Text('${_fabricEstimation?['recommended_quantity_meters'] ?? '2.0'} Meters',
                            style: context.text.displaySmall?.copyWith(color: Colors.white))
                        : AnimatedCount(
                            value: meters,
                            decimals: meters is int ? 0 : 2,
                            suffix: ' Meters',
                            style: context.text.displaySmall?.copyWith(color: Colors.white),
                          ),
                  ),
                  if (_fabricEstimation != null && _fabricEstimation!['estimated_range'] != null)
                    Text(
                      'Range: ${_fabricEstimation!['estimated_range']['min']} - ${_fabricEstimation!['estimated_range']['max']} m',
                      style: context.text.bodyMedium?.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.lg),
          EntranceFade(
            delay: Motion.staggerStep * 2,
            child: TextField(
              controller: _manualQuantityCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textInputAction: TextInputAction.done,
              scrollPadding: const EdgeInsets.only(bottom: 160),
              decoration: const InputDecoration(
                labelText: 'Override Quantity (m)',
                prefixIcon: Icon(Icons.edit_note_rounded),
                suffixText: 'm',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 8: Assign ---
  Widget _buildAssignStep() {
    final cs = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
        _stepHeader('Assign & Save', 'Double-check the order before saving.'),
        EntranceFade(
          delay: Motion.staggerStep,
          child: TsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.receipt_long_rounded, color: cs.primary, size: 20),
                    const SizedBox(width: Space.xs),
                    Text('Order Summary', style: context.text.titleSmall),
                  ],
                ),
                const SizedBox(height: Space.sm),
                _summaryRow('Customer', _selectedCustomerName ?? ''),
                _summaryRow('Prediction Model', _predictionMethod == 'FOUNDRY' ? 'AI Foundry' : 'Custom ML Model'),
                _summaryRow('Garment', _selectedGarment ?? ''),
                _summaryRow('Fabric', _fabricRecommendations.isNotEmpty && _selectedFabricIndex != null ? _fabricRecommendations[_selectedFabricIndex!]['fabric_name'] : 'N/A'),
                _summaryRow('Quantity', '${_manualQuantityCtrl.text} meters'),
                if (_priceCtrl.text.trim().isNotEmpty) _summaryRow('Price', 'LKR ${_priceCtrl.text.trim()}'),
              ],
            ),
          ),
        ),
        const SizedBox(height: Space.lg),
        Text('Order Price (optional)', style: context.text.titleSmall),
        const SizedBox(height: Space.sm),
        TextField(
          controller: _priceCtrl,
          onChanged: (_) => setState(() {}),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.payments_outlined),
            prefixText: 'LKR ',
            hintText: 'e.g. 4500',
            helperText: 'Used for revenue in Reports',
          ),
        ),
        const SizedBox(height: Space.lg),
        Text('Assign to Staff', style: context.text.titleSmall),
        const SizedBox(height: Space.sm),
        _staffList.isEmpty
          ? Text('No staff available', style: TextStyle(color: cs.error))
          : DropdownButtonFormField<int>(
              value: _staffList.any((s) => s['id'] == _selectedStaffId) ? _selectedStaffId : null,
              isExpanded: true,
              borderRadius: Radii.brMd,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.person_pin_outlined)),
              items: _staffList.map((s) => DropdownMenuItem<int>(
                value: s['id'],
                child: Text(s['full_name'] ?? s['name'] ?? 'Unknown', overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: (v) => setState(() => _selectedStaffId = v),
            ),
        const SizedBox(height: Space.lg),
        _sectionTitle(Icons.straighten_rounded, 'Body Measurements'),
        const SizedBox(height: Space.sm),
        _buildBodyMeasurementsCard(),
        const SizedBox(height: Space.lg),
        _sectionTitle(Icons.architecture_rounded, 'Cutting Blueprint'),
        const SizedBox(height: Space.sm),
        GarmentBlueprintSection(
          garment: _selectedGarment ?? '',
          measurements: _confirmedMeasurements,
        ),
      ],
      ),
    );
  }

  Widget _sectionTitle(IconData icon, String text) {
    final cs = context.colors;
    return Row(
      children: [
        Icon(icon, size: 20, color: cs.primary),
        const SizedBox(width: Space.xs),
        Text(text, style: context.text.titleSmall),
      ],
    );
  }

  /// All finalized measurements of this order (entered + AI-predicted).
  Widget _buildBodyMeasurementsCard() {
    final cs = context.colors;
    String pretty(String k) => k
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
    final entries = _confirmedMeasurements.entries
        .where((e) => e.value.trim().isNotEmpty && e.value.trim() != '0' && e.value.trim() != '0.0')
        .toList();
    if (entries.isEmpty) {
      return TsCard(shadow: false, child: Text('No measurements recorded.', style: context.text.bodySmall));
    }
    return TsCard(
      padding: const EdgeInsets.all(Space.sm),
      child: Wrap(
        spacing: Space.xs,
        runSpacing: Space.xs,
        children: [
          for (final e in entries)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: Space.sm, vertical: Space.xs),
              decoration: BoxDecoration(color: cs.surfaceContainerHigh, borderRadius: Radii.brSm),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAiGenerated[e.key] == true) ...[
                    Icon(Icons.auto_awesome_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 4),
                  ],
                  Text('${pretty(e.key)}: ', style: context.text.bodySmall),
                  Text('${e.value}"', style: context.text.titleSmall),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Inventory badge shown under each AI fabric recommendation.
  Widget _stockPill(Map<String, dynamic> rec) {
    final st = context.status;
    final m = (rec['stock_m'] as num?)?.toDouble() ?? 0;
    final txt = m.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    final (Color c, String label, IconData icon) = switch (rec['stock_status']) {
      'ok' => (st.success, '$txt m in stock', Icons.inventory_2_rounded),
      'low' => (st.warning, 'Low: $txt m left', Icons.warning_amber_rounded),
      'out' => (st.danger, 'Out of stock', Icons.error_outline_rounded),
      _ => (context.colors.onSurfaceVariant, 'Stock not tracked', Icons.help_outline_rounded),
    };
    return StatusPill(label: label, icon: icon, color: c, dense: true);
  }

  Widget _summaryRow(String k, String v) {
      return Padding(
          padding: const EdgeInsets.symmetric(vertical: Space.xxs + 2),
          child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(k, style: context.text.bodyMedium),
                  const SizedBox(width: Space.md),
                  Expanded(
                    child: Text(
                      v,
                      style: context.text.titleSmall,
                      textAlign: TextAlign.right,
                    ),
                  ),
              ]
          )
      );
  }

  // --- Footer ---
  Widget _buildFooter() {
    bool isLoading = _aiPredictionLoading || _fabricRecLoading || _fabricEstLoading || _loadingInit || _loadingTemplate;
    final cs = context.colors;
    final isLast = _currentStep == _stepTitles.length - 1;

    return AnimatedSlide(
      offset: isLoading ? const Offset(0, 1) : Offset.zero,
      duration: Motion.of(context, Motion.medium),
      curve: Motion.emphasized,
      child: AnimatedOpacity(
        opacity: isLoading ? 0 : 1,
        duration: Motion.of(context, Motion.short),
        child: IgnorePointer(
          ignoring: isLoading,
          child: ClipRect(
            child: RepaintBoundary(
              child: Container(
                padding: EdgeInsets.fromLTRB(context.pagePadding, Space.sm, context.pagePadding, Space.md),
                decoration: BoxDecoration(
                  color: cs.surface.withValues(alpha: 0.97),
                  border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    AnimatedSize(
                      duration: Motion.of(context, Motion.short),
                      child: _currentStep > 0
                          ? Padding(
                              padding: const EdgeInsets.only(right: Space.sm),
                              child: TextButton.icon(
                                onPressed: _prevStep,
                                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                                label: const Text('Back'),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: TsButton(
                        label: isLast ? 'Save Order' : 'Continue',
                        icon: isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        loading: _saving,
                        onPressed: _saving ? null : (_currentStep == _stepTitles.length - 1 ? _saveOrder : _nextStep),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
