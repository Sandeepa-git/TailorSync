import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/providers/api_provider.dart';
import '../../../customers/presentation/providers/customers_provider.dart';
import '../../presentation/providers/orders_provider.dart';

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
    'Customer', 'Garment', 'Priority Input', 'AI Prediction', 
    'Preferences', 'Fabric Rec.', 'Estimation', 'Review & Assign'
  ];

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
      final userResp = await api.getMe();
      final staffResp = await api.listStaff();
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
  final List<Map<String, dynamic>> _garmentTypes = [
    {'name': 'Short Sleeve Shirt', 'icon': Icons.checkroom, 'color': Color(0xFF6C63FF)},
    {'name': 'Long Sleeve Shirt', 'icon': Icons.dry_cleaning, 'color': Color(0xFF4CAF50)},
    {'name': 'Short Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF6584)},
    {'name': 'Long Trouser', 'icon': Icons.straighten, 'color': Color(0xFFFF9F43)},
    {'name': 'Dresses', 'icon': Icons.woman, 'color': Color(0xFF9B59B6)},
    {'name': 'Suits', 'icon': Icons.work, 'color': Color(0xFF34495E)},
    {'name': 'Jackets', 'icon': Icons.layers, 'color': Color(0xFFE67E22)},
    {'name': 'Coats', 'icon': Icons.ac_unit, 'color': Color(0xFF2980B9)},
  ];

  // Step 3: Priority Measurements
  Map<String, dynamic>? _measurementTemplate;
  bool _loadingTemplate = false;
  final Map<int, TextEditingController> _measurementControllers = {};
  
  // Custom added measurements
  final List<Map<String, dynamic>> _customMeasurements = [];
  final Map<int, TextEditingController> _customMeasurementControllers = {};
  int _customMeasurementCounter = 0;
  
  Map<String, dynamic> _getDefaultTemplateForCategory(String cat) {
      List<Map<String, dynamic>> fields = [];
      
      if (cat == 'Short Sleeve Shirt') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': '40'},
          {'id': 3, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': '18'},
          {'id': 4, 'field_name': 'Collar Size', 'unit': 'in', 'is_required': true, 'placeholder': '15'},
          {'id': 5, 'field_name': 'Short Sleeve Length', 'unit': 'in', 'is_required': true, 'placeholder': '10'},
          {'id': 6, 'field_name': 'Sleeve Open', 'unit': 'in', 'is_required': false, 'placeholder': '12'},
        ];
      } else if (cat == 'Long Sleeve Shirt') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': '40'},
          {'id': 3, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': '18'},
          {'id': 4, 'field_name': 'Collar Size', 'unit': 'in', 'is_required': true, 'placeholder': '15'},
          {'id': 5, 'field_name': 'Long Sleeve Length', 'unit': 'in', 'is_required': true, 'placeholder': '25'},
          {'id': 6, 'field_name': 'Sleeve Open', 'unit': 'in', 'is_required': false, 'placeholder': '12'},
        ];
      } else if (cat.contains('Trouser')) {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Waist', 'unit': 'in', 'is_required': true, 'placeholder': '32'},
          {'id': 3, 'field_name': 'Height till Knee', 'unit': 'in', 'is_required': false, 'placeholder': '22'},
          {'id': 4, 'field_name': 'Round Knee', 'unit': 'in', 'is_required': false, 'placeholder': '16'},
          {'id': 5, 'field_name': 'Round End', 'unit': 'in', 'is_required': false, 'placeholder': '14'},
          {'id': 6, 'field_name': 'Seat', 'unit': 'in', 'is_required': false, 'placeholder': '38'},
          {'id': 7, 'field_name': 'Crotch', 'unit': 'in', 'is_required': false, 'placeholder': '24'},
        ];
        if (cat == 'Short Trouser') {
            fields.removeWhere((f) => f['field_name'] == 'Height till Knee' || f['field_name'] == 'Round End');
        }
      } else if (cat == 'Dresses') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '65'},
          {'id': 2, 'field_name': 'Bust', 'unit': 'in', 'is_required': true, 'placeholder': '36'},
          {'id': 3, 'field_name': 'Waist', 'unit': 'in', 'is_required': true, 'placeholder': '28'},
          {'id': 4, 'field_name': 'Hips', 'unit': 'in', 'is_required': true, 'placeholder': '38'},
          {'id': 5, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': false, 'placeholder': '16'},
          {'id': 6, 'field_name': 'Dress Length', 'unit': 'in', 'is_required': true, 'placeholder': '40'},
        ];
      } else if (cat == 'Suits') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': '42'},
          {'id': 3, 'field_name': 'Waist', 'unit': 'in', 'is_required': true, 'placeholder': '34'},
          {'id': 4, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': '19'},
          {'id': 5, 'field_name': 'Sleeve Length', 'unit': 'in', 'is_required': true, 'placeholder': '26'},
          {'id': 6, 'field_name': 'Trouser Waist', 'unit': 'in', 'is_required': true, 'placeholder': '34'},
          {'id': 7, 'field_name': 'Trouser Length', 'unit': 'in', 'is_required': true, 'placeholder': '40'},
        ];
      } else if (cat == 'Jackets' || cat == 'Coats') {
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': '42'},
          {'id': 3, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': true, 'placeholder': '19'},
          {'id': 4, 'field_name': 'Sleeve Length', 'unit': 'in', 'is_required': true, 'placeholder': '26'},
          {'id': 5, 'field_name': 'Jacket Length', 'unit': 'in', 'is_required': true, 'placeholder': '30'},
        ];
      } else {
        // Tops & Full Body
        fields = [
          {'id': 1, 'field_name': 'Height', 'unit': 'in', 'is_required': true, 'placeholder': '70'},
          {'id': 2, 'field_name': 'Chest', 'unit': 'in', 'is_required': true, 'placeholder': '40'},
          {'id': 3, 'field_name': 'Shoulder', 'unit': 'in', 'is_required': false, 'placeholder': '18'},
          {'id': 4, 'field_name': 'Waist', 'unit': 'in', 'is_required': false, 'placeholder': '32'},
          {'id': 5, 'field_name': 'Hips', 'unit': 'in', 'is_required': false, 'placeholder': '40'},
          {'id': 6, 'field_name': 'Sleeve Length', 'unit': 'in', 'is_required': false, 'placeholder': '25'},
        ];
      }

      return {
        'category_name': cat,
        'fields': fields
      };
  }

  // Step 4: AI Predictions
  List<Map<String, dynamic>> _aiPredictions = [];
  Map<String, String> _confirmedMeasurements = {};
  Map<String, bool> _isAiGenerated = {};
  bool _aiPredictionLoading = false;
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

  // Step 8: Assign
  int? _selectedStaffId = 1; 

  // --- Step Navigation Logic ---
  Future<void> _nextStep() async {
    final api = ref.read(apiClientProvider);
    
    if (_currentStep == 0 && _selectedCustomerId == null) {
      _showSnack('⚠️ Please select a customer'); return;
    } 
    
    if (_currentStep == 1) {
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
    }
    
    if (_currentStep == 2) {
      // Validate Priority Inputs
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
        final text = _measurementControllers[id]?.text.trim() ?? '';
        if (text.isNotEmpty) {
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

      setState(() { _aiPredictionLoading = true; _aiPredictionError = null; _currentStep++; });
      try {
        final resp = await api.predictMeasurements({'garment_type': _selectedGarment, 'measurements': enteredMeasures});
        setState(() {
          _aiPredictions = List<Map<String, dynamic>>.from(resp.data['predictions'] ?? []);
          // Auto-confirm AI predictions
          for (var p in _aiPredictions) {
             final m = p['measurement'] as String;
             if (!_confirmedMeasurements.containsKey(m)) {
                _confirmedMeasurements[m] = p['recommended'].toString();
                _isAiGenerated[m] = true;
             }
          }
          _aiPredictionLoading = false;
        });
      } catch (e) {
        String errorMsg = "AI unavailable. You can enter manually later.";
        if (e is DioException && e.response?.data != null && e.response!.data is Map && (e.response!.data as Map).containsKey('detail')) {
            errorMsg = (e.response!.data as Map)['detail'].toString();
        } else {
            errorMsg = e.toString();
        }
        setState(() {
          _aiPredictionError = errorMsg;
          _aiPredictionLoading = false;
        });
      }
      return;
    }
    
    if (_currentStep == 3) {
       // Validate that all necessary measurements are filled (either manual or AI)
    }

    if (_currentStep == 4) {
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

    if (_currentStep == 5) {
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

    if (_currentStep == 6) {
        if (_manualQuantityCtrl.text.isEmpty || double.tryParse(_manualQuantityCtrl.text) == null) {
            _showSnack('⚠️ Please enter a valid quantity'); return;
        }
    }

    setState(() { _currentStep++; });
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- Build Methods ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Premium Dark Mode Base
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close, color: Colors.black87), onPressed: () { context.go('/home'); }),
        title: Text('TailorSync AI Wizard', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black87)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF8FAFC)],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                _buildStepper(),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (w, anim) => FadeTransition(
                      opacity: anim, 
                      child: SlideTransition(position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim), child: w)
                    ),
                    child: Container(
                      key: ValueKey<int>(_currentStep),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: _buildStepContent(),
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Step ${_currentStep + 1} of ${_stepTitles.length}', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                transitionBuilder: (w, anim) => FadeTransition(
                  opacity: anim, 
                  child: SlideTransition(position: Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(anim), child: w)
                ),
                child: Text(_stepTitles[_currentStep], key: ValueKey<int>(_currentStep), style: GoogleFonts.outfit(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(_stepTitles.length, (index) {
              final isActive = index <= _currentStep;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  height: 4,
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1565C0) : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: isActive ? [BoxShadow(color: const Color(0xFF1565C0).withOpacity(0.5), blurRadius: 4)] : null,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0: return _buildCustomerStep();
      case 1: return _buildGarmentStep();
      case 2: return _buildPriorityInputStep();
      case 3: return _buildAiPredictionStep();
      case 4: return _buildPreferencesStep();
      case 5: return _buildFabricRecStep();
      case 6: return _buildEstimationStep();
      case 7: return _buildAssignStep();
      default: return const SizedBox.shrink();
    }
  }

  // --- Step 1: Customer ---
  Widget _buildCustomerStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Who is this order for?', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text('Select an existing client or create a new profile.', style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        TextField(
          onChanged: (v) => setState(() => _customerSearch = v),
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            hintText: 'Search by name or phone...',
            hintStyle: const TextStyle(color: Colors.black54),
            prefixIcon: const Icon(Icons.search, color: Colors.black54),
            filled: true,
            fillColor: Colors.black.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.black12)),
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Consumer(builder: (ctx, ref, child) {
            final customersAsync = ref.watch(customersProvider);
            return customersAsync.when(
              data: (customers) {
                final filtered = customers.where((c) => c.name.toLowerCase().contains(_customerSearch.toLowerCase()) || (c.phone ?? '').contains(_customerSearch)).toList();
                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final c = filtered[i];
                    final isSelected = _selectedCustomerId == c.id;
                    return GestureDetector(
                      onTap: () => setState(() { _selectedCustomerId = c.id; _selectedCustomerName = c.name; }),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1565C0).withOpacity(0.2) : Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? const Color(0xFF1565C0) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: isSelected ? const Color(0xFF1565C0) : Colors.black12, child: Text(c.name[0].toUpperCase(), style: const TextStyle(color: Colors.black87))),
                            const SizedBox(width: 16),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
                              Text(c.phone ?? 'No phone', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                            ])),
                            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
              error: (e, _) => const Text('Error loading customers', style: TextStyle(color: Colors.black87)),
            );
          }),
        ),
      ],
    );
  }

  // --- Step 2: Garment ---
  Widget _buildGarmentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What are we making?', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text('Our AI will tailor the measurement flow based on this choice.', style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.1),
            itemCount: _garmentTypes.length,
            itemBuilder: (ctx, i) {
              final g = _garmentTypes[i];
              final isSelected = _selectedGarment == g['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedGarment = g['name']),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? g['color'].withOpacity(0.2) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? g['color'] : Colors.transparent, width: 2),
                    boxShadow: isSelected ? [BoxShadow(color: g['color'].withOpacity(0.3), blurRadius: 12)] : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(g['icon'], size: 40, color: isSelected ? g['color'] : Colors.black54),
                      const SizedBox(height: 12),
                      Text(g['name'], textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
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

  // --- Step 3: Priority Input ---
  Widget _buildPriorityInputStep() {
    if (_loadingTemplate) return const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0)));
    
    final fields = (_measurementTemplate?['fields'] as List? ?? []).cast<Map<String, dynamic>>();
    final requiredFields = fields.where((f) => f['is_required'] == true).toList();
    final optionalFields = fields.where((f) => f['is_required'] != true).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF1565C0)),
            const SizedBox(width: 12),
            Text('Measurements Input', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
        const SizedBox(height: 8),
        Text('Provide required measurements. Optional ones can be left blank, and AI can suggest them.', style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (requiredFields.isNotEmpty) ...[
                  Text('Required Measurements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ...requiredFields.map((f) => _buildMeasurementRow(f, true)).toList(),
                  const SizedBox(height: 24),
                ],
                if (optionalFields.isNotEmpty) ...[
                  Text('Optional Measurements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ...optionalFields.map((f) => _buildMeasurementRow(f, false)).toList(),
                  const SizedBox(height: 24),
                ],
                if (_customMeasurements.isNotEmpty) ...[
                  Text('Custom Measurements', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                  const SizedBox(height: 12),
                  ..._customMeasurements.map((f) => _buildCustomMeasurementRow(f)).toList(),
                  const SizedBox(height: 24),
                ],
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
                    icon: const Icon(Icons.add, color: Color(0xFF1565C0)),
                    label: Text('+ Add Other Measurement', style: GoogleFonts.inter(color: const Color(0xFF1565C0), fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementRow(Map<String, dynamic> f, bool isRequired) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
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
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isRequired) Text(' *', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  ],
                ),
                if (isRequired) Text('Required', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF1565C0)))
                else Text('Optional', style: GoogleFonts.inter(fontSize: 11, color: Colors.black54)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _measurementControllers[f['id']],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: f['placeholder'] ?? 'e.g. 10.5', 
                hintStyle: const TextStyle(color: Colors.black38, fontSize: 13),
                suffixText: f['unit'], 
                suffixStyle: const TextStyle(color: Colors.black54, fontSize: 13),
                filled: true, 
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.black12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomMeasurementRow(Map<String, dynamic> f) {
    final id = f['id'] as int;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (val) {
                final idx = _customMeasurements.indexWhere((m) => m['id'] == id);
                if (idx != -1) _customMeasurements[idx]['field_name'] = val;
              },
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                hintText: 'Measurement Name',
                hintStyle: TextStyle(color: Colors.black38),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: TextField(
              controller: _customMeasurementControllers[id],
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: '0.0', hintStyle: const TextStyle(color: Colors.black38),
                filled: true, fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.black12)),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.black54),
            onPressed: () {
              setState(() {
                _customMeasurements.removeWhere((m) => m['id'] == id);
                _customMeasurementControllers.remove(id)?.dispose();
              });
            },
          ),
        ],
      ),
    );
  }

  // --- Step 4: AI Prediction Review ---
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
            Text('Synthesizing Dataset...', style: GoogleFonts.outfit(fontSize: 20, color: Colors.black87)),
            const SizedBox(height: 8),
            Text('Matching your inputs against standard global patterns.', style: GoogleFonts.inter(color: Colors.black87)),
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
        Text('AI Predictions Review', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 8),
        Text("You are in control. Adjust any predicted value if it doesn't look right.", style: GoogleFonts.inter(color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _aiPredictions.length,
            itemBuilder: (ctx, i) {
              final p = _aiPredictions[i];
              final mName = p['measurement'] as String;
              final isConfirmed = _confirmedMeasurements.containsKey(mName) && _confirmedMeasurements[mName]!.isNotEmpty;
              final displayValue = isConfirmed ? _confirmedMeasurements[mName]! : p['recommended'].toString();
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(mName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 16)),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: isConfirmed ? const Color(0xFF1565C0) : Colors.grey, borderRadius: BorderRadius.circular(20)),
                              child: Text(isConfirmed ? displayValue : 'Cleared', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            if (isConfirmed) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _confirmedMeasurements.remove(mName);
                                    _isAiGenerated.remove(mName);
                                  });
                                },
                                child: const Icon(Icons.close, color: Colors.redAccent, size: 20),
                              )
                            ] else ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _confirmedMeasurements[mName] = p['recommended'].toString();
                                    _isAiGenerated[mName] = true;
                                  });
                                },
                                child: const Icon(Icons.add_circle, color: Color(0xFF1565C0), size: 20),
                              )
                            ]
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(p['reason'] ?? 'AI predicted standard value.', style: GoogleFonts.inter(color: Colors.black54, fontSize: 12)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text('Alternatives: ', style: GoogleFonts.inter(color: Colors.black87, fontSize: 12)),
                        ...(p['alternatives'] as List? ?? []).map((alt) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => _confirmedMeasurements[mName] = alt.toString()),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
                              child: Text(alt.toString(), style: const TextStyle(color: Colors.black87)),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Step 5: Preferences ---
  Widget _buildPreferencesStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Style & Fit', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 24),
          _buildChipSelector('Occasion', ['Everyday / Casual', 'Office / Work', 'Wedding', 'Party'], _occasion, (v) => setState(()=> _occasion = v)),
          const SizedBox(height: 24),
          _buildChipSelector('Weather', ['Warm', 'Hot', 'Cold', 'Humid'], _weather, (v) => setState(()=> _weather = v)),
          const SizedBox(height: 24),
          _buildChipSelector('Fit', ['Regular Fit', 'Slim Fit', 'Modern Fit'], _fit, (v) => setState(()=> _fit = v)),
        ],
      ),
    );
  }

  Widget _buildChipSelector(String title, List<String> options, String selected, Function(String) onSelect) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black54)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12, runSpacing: 12,
          children: options.map((opt) {
            final isSel = selected == opt;
            return GestureDetector(
              onTap: () => onSelect(opt),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSel ? const Color(0xFF1565C0) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isSel ? const Color(0xFF1565C0) : Colors.black12),
                ),
                child: Text(opt, style: TextStyle(color: isSel ? Colors.white : Colors.black87, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF9B59B6).withOpacity(0.3), boxShadow: [BoxShadow(color: const Color(0xFF9B59B6).withOpacity(0.5), blurRadius: 30)]),
                child: const Icon(Icons.style, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 32),
            Text('Analyzing Preferences...', style: GoogleFonts.outfit(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Curating the best fabric options for your style.', style: GoogleFonts.inter(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    if (_fabricRecError != null) return Center(child: Text(_fabricRecError!, style: const TextStyle(color: Colors.red)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Top Fabrics', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: _fabricRecommendations.length,
            itemBuilder: (ctx, i) {
              final rec = _fabricRecommendations[i];
              final isSel = _selectedFabricIndex == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedFabricIndex = i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF1565C0).withOpacity(0.2) : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSel ? const Color(0xFF1565C0) : Colors.black12, width: 2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(color: const Color(0xFF1565C0), borderRadius: BorderRadius.circular(12)),
                        alignment: Alignment.center,
                        child: Text('${rec['suitability_percentage']}%', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec['fabric_name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 18)),
                            const SizedBox(height: 4),
                            Text(rec['reason'] ?? '', style: GoogleFonts.inter(color: Colors.black87, fontSize: 12)),
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

  // --- Step 7: Estimation ---
  Widget _buildEstimationStep() {
    if (_fabricEstLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeTransition(
              opacity: _pulseController,
              child: Container(
                width: 100, height: 100,
                decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF4CAF50).withOpacity(0.3), boxShadow: [BoxShadow(color: const Color(0xFF4CAF50).withOpacity(0.5), blurRadius: 30)]),
                child: const Icon(Icons.straighten, color: Colors.white, size: 50),
              ),
            ),
            const SizedBox(height: 32),
            Text('Estimating Required Fabric...', style: GoogleFonts.outfit(fontSize: 20, color: Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Calculating exact meterage based on measurements.', style: GoogleFonts.inter(color: Colors.black54), textAlign: TextAlign.center),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF1565C0).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.straighten, size: 60, color: Color(0xFF1565C0)),
              const SizedBox(height: 16),
              Text('Fabric Required', style: GoogleFonts.outfit(color: Colors.black87, fontSize: 18)),
              const SizedBox(height: 8),
              Text('${_fabricEstimation?['recommended_quantity_meters'] ?? '2.0'} Meters', style: GoogleFonts.outfit(color: Colors.black87, fontSize: 40, fontWeight: FontWeight.bold)),
              if (_fabricEstimation != null && _fabricEstimation!['estimated_range'] != null)
                Text('Range: ${_fabricEstimation!['estimated_range']['min']} - ${_fabricEstimation!['estimated_range']['max']} m', style: GoogleFonts.inter(color: Colors.black54)),
              const SizedBox(height: 24),
              TextField(
                controller: _manualQuantityCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Override Quantity (m)', labelStyle: const TextStyle(color: Colors.black54),
                  filled: true, fillColor: Colors.black.withOpacity(0.05),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Step 8: Assign ---
  Widget _buildAssignStep() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Text('Assign & Save', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 24),
        Container(
           padding: const EdgeInsets.all(16),
           decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
           child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Text('Order Summary', style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold)),
                 const SizedBox(height: 12),
                 _summaryRow('Customer', _selectedCustomerName ?? ''),
                 _summaryRow('Garment', _selectedGarment ?? ''),
                 _summaryRow('Fabric', _fabricRecommendations.isNotEmpty && _selectedFabricIndex != null ? _fabricRecommendations[_selectedFabricIndex!]['fabric_name'] : 'N/A'),
                 _summaryRow('Quantity', '${_manualQuantityCtrl.text} meters'),
              ],
           ),
        ),
        const SizedBox(height: 24),
        Text('Assign to Staff', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87)),
        const SizedBox(height: 12),
        _staffList.isEmpty 
          ? Text('No staff available', style: GoogleFonts.inter(color: Colors.redAccent))
          : DropdownButtonFormField<int>(
              value: _staffList.any((s) => s['id'] == _selectedStaffId) ? _selectedStaffId : null,
              dropdownColor: const Color(0xFFF8FAFC),
              style: const TextStyle(color: Colors.black87),
              decoration: InputDecoration(
                filled: true, fillColor: Colors.black.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.black12)),
              ),
              items: _staffList.map((s) => DropdownMenuItem<int>(
                value: s['id'],
                child: Text(s['full_name'] ?? s['name'] ?? 'Unknown', style: const TextStyle(color: Colors.black87)),
              )).toList(),
              onChanged: (v) => setState(() => _selectedStaffId = v),
            ),
      ],
      ),
    );
  }

  Widget _summaryRow(String k, String v) {
      return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(k, style: GoogleFonts.inter(color: Colors.black87)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      v, 
                      style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.bold),
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
    if (isLoading) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (_currentStep > 0)
            TextButton(onPressed: _prevStep, child: Text('Back', style: GoogleFonts.inter(color: Colors.black54, fontWeight: FontWeight.bold)))
          else const SizedBox(width: 60),
          
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF0D1042)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: const Color(0xFF1A237E).withOpacity(0.5), blurRadius: 8)],
            ),
            child: ElevatedButton(
              onPressed: _saving ? null : (_currentStep == _stepTitles.length - 1 ? _saveOrder : _nextStep),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                             : Text(_currentStep == _stepTitles.length - 1 ? 'Save Order' : 'Continue', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOrder() async {
    setState(() => _saving = true);
    try {
      final api = ref.read(apiClientProvider);
      final body = <String, dynamic>{
        'customer_id': _selectedCustomerId,
        'garment_type': _selectedGarment,
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

      await api.createOrder(body);
      ref.invalidate(ordersProvider);
      if (mounted) context.go('/orders');
    } catch (e) {
      _showSnack('Failed to save order: $e');
    }
    if (mounted) setState(() => _saving = false);
  }
}
