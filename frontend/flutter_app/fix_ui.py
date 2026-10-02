import os
import re

file_path = "c:/Users/Sandeepa/Desktop/TailorSync/frontend/flutter_app/lib/features/orders/presentation/screens/new_order_wizard.dart"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# Add _selectedOptionIndex state
if "int? _selectedOptionIndex;" not in content:
    content = content.replace("bool _aiPredictionLoading = false;", "bool _aiPredictionLoading = false;\n  int? _selectedOptionIndex;")

old_ai_pred = r'  // --- Step 5: AI Prediction Review ---.*?(?=  // --- Step 5: Preferences ---)'
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
                 // only show fields that were predicted
                 if (_measurementTemplate?['fields']?.any((f) => f['field_name'].toString().toLowerCase() == k.toLowerCase()) ?? false) {
                     return const SizedBox.shrink(); // Hide the 3 required fields which are already in step 2
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
content = re.sub(old_ai_pred, new_ai_pred, content, flags=re.DOTALL)

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)

print("Dart file successfully updated with better UI!")
