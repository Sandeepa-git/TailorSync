import re

content = open('temp_wizard_fixed2.dart', 'r', encoding='utf-8').read()

# 1. Add services.dart
if 'import \'package:flutter/services.dart\';' not in content:
    content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:flutter/services.dart\';')

# 2. Fix the background gradient colors
content = content.replace('colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],', 'colors: [Color(0xFF283593), Color(0xFF1A237E), Color(0xFF0D1042)],')
content = content.replace('backgroundColor: const Color(0xFF0F172A),', 'backgroundColor: const Color(0xFF0D1042),')

# 3. Fix context pop
content = content.replace('onPressed: () => context.pop()', 'onPressed: () { if (context.canPop()) context.pop(); else context.go(\'/orders\'); }')

# 4. Fix Step 3 Keyboard Type & Validation
old_input = '''keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),'''
new_input = '''keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\\d*\\.?\\d*')),
                        ],
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),'''
content = content.replace(old_input, new_input)

# 5. Fix placeholder for Step 3 in _getDefaultTemplateForCategory
content = content.replace("{'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true}", "{'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': '18'}")
content = content.replace("{'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true}", "{'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': '175'}")
content = content.replace("{'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true}", "{'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true, 'placeholder': '55'}")
content = content.replace("{'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true}", "{'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true, 'placeholder': '32'}")
content = content.replace("{'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false}", "{'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false, 'placeholder': '20'}")
content = content.replace("{'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false}", "{'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false, 'placeholder': '38'}")

# Write it out
open('frontend/flutter_app/lib/features/orders/presentation/screens/new_order_wizard.dart', 'w', encoding='utf-8').write(content)
