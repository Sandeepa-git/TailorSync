import re

content = open('temp_wizard_light_utf8.dart', 'r', encoding='utf-8').read()

# 1. Add services.dart
if 'import \'package:flutter/services.dart\';' not in content:
    content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:flutter/services.dart\';')

# 2. Replace primary accent color
content = content.replace('Color(0xFF6366F1)', 'Color(0xFF1565C0)')

# 3. Replace the button with a gradient container
old_button = '''          ElevatedButton(
            onPressed: _saving ? null : (_currentStep == _stepTitles.length - 1 ? _saveOrder : _nextStep),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
              shadowColor: const Color(0xFF1565C0).withOpacity(0.5),
            ),
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                           : Text(_currentStep == _stepTitles.length - 1 ? 'Save Order' : 'Continue', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),'''

new_button = '''          Container(
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
          ),'''

content = content.replace(old_button, new_button)

# 4. Fix context pop
content = content.replace('onPressed: () => context.pop()', 'onPressed: () { if (context.canPop()) context.pop(); else context.go(\'/orders\'); }')

# 5. Fix Step 3 Keyboard Type & Validation
old_input = '''keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),'''
new_input = '''keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\\d*\\.?\\d*')),
                        ],
                        style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),'''
content = content.replace(old_input, new_input)

# 6. Fix placeholder for Step 3 in _getDefaultTemplateForCategory
content = content.replace("{'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true}", "{'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': '18'}")
content = content.replace("{'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true}", "{'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': '175'}")
content = content.replace("{'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true}", "{'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true, 'placeholder': '55'}")
content = content.replace("{'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true}", "{'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true, 'placeholder': '32'}")
content = content.replace("{'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false}", "{'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false, 'placeholder': '20'}")
content = content.replace("{'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false}", "{'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false, 'placeholder': '38'}")

# Write it out
open('frontend/flutter_app/lib/features/orders/presentation/screens/new_order_wizard.dart', 'w', encoding='utf-8').write(content)
