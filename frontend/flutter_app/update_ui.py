import os
import re

file_path = "c:/Users/Sandeepa/Desktop/TailorSync/frontend/flutter_app/lib/features/orders/presentation/screens/new_order_wizard.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Fix the close button
content = content.replace(
    "onPressed: () => context.pop()",
    "onPressed: () { if (context.canPop()) context.pop(); else context.go('/orders'); }"
)

# Convert dark mode colors to light mode
content = content.replace("Color(0xFF0F172A)", "Colors.white")
content = content.replace("Color(0xFF1E1B4B)", "Color(0xFFF8FAFC)")
content = content.replace("Colors.white54", "Colors.black54")
content = content.replace("Colors.white70", "Colors.black87")
content = content.replace("Colors.white30", "Colors.black38")
content = content.replace("Colors.white10", "Colors.black12")
content = content.replace("Colors.white.withOpacity(0.05)", "Colors.black.withOpacity(0.05)")
content = content.replace("Colors.white.withOpacity(0.1)", "Colors.black.withOpacity(0.1)")
content = content.replace("Colors.white.withOpacity(0.02)", "Colors.black.withOpacity(0.02)")
content = content.replace("Colors.white", "Colors.black87")

# Fix primary colors that shouldn't have been turned to black (e.g. text on blue buttons)
content = content.replace("color: Colors.black87, strokeWidth: 2", "color: Colors.white, strokeWidth: 2")
content = content.replace(
    "Text(_currentStep == _stepTitles.length - 1 ? 'Save Order' : 'Continue', style: GoogleFonts.inter(color: Colors.black87",
    "Text(_currentStep == _stepTitles.length - 1 ? 'Save Order' : 'Continue', style: GoogleFonts.inter(color: Colors.white"
)
content = content.replace(
    "child: Text('${rec['suitability_percentage']}%', style: GoogleFonts.outfit(color: Colors.black87",
    "child: Text('${rec['suitability_percentage']}%', style: GoogleFonts.outfit(color: Colors.white"
)
content = content.replace("color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(20)),\n                          child: Text(_confirmedMeasurements[mName] ?? p['recommended'].toString(), style: GoogleFonts.inter(color: Colors.black87", "color: const Color(0xFF6366F1), borderRadius: BorderRadius.circular(20)),\n                          child: Text(_confirmedMeasurements[mName] ?? p['recommended'].toString(), style: GoogleFonts.inter(color: Colors.white")
content = content.replace("const Icon(Icons.auto_awesome, color: Colors.black87", "const Icon(Icons.auto_awesome, color: Colors.white")

# TextField placeholder fixes
content = content.replace("Colors.black26", "Colors.grey.shade100")
content = content.replace("borderSide: BorderSide.none", "borderSide: BorderSide(color: Colors.black12)")

# Update the default template to have placeholders
old_template = """        'fields': [
          {'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true},
          {'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true},
          {'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true},
          {'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true},
          {'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false},
          {'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false},
        ]"""
new_template = """        'fields': [
          {'id': 1, 'field_name': 'Shoulder Length', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 18'},
          {'id': 2, 'field_name': 'Height', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 175'},
          {'id': 3, 'field_name': 'Height Till Knee', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 55'},
          {'id': 4, 'field_name': 'Waist', 'unit': 'cm', 'is_required': true, 'placeholder': 'e.g. 32'},
          {'id': 5, 'field_name': 'Round Knee', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 20'},
          {'id': 6, 'field_name': 'Seat', 'unit': 'cm', 'is_required': false, 'placeholder': 'e.g. 38'},
        ]"""
content = content.replace(old_template, new_template)

# Use placeholder in hintText
content = content.replace("hintText: '0.0',", "hintText: f['placeholder'] ?? '0.0',")

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("UI successfully updated to light mode and close button fixed!")
