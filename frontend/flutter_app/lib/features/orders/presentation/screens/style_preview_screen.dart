import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers/api_provider.dart';

class StylePreviewScreen extends ConsumerStatefulWidget {
  const StylePreviewScreen({super.key});

  @override
  ConsumerState<StylePreviewScreen> createState() => _StylePreviewScreenState();
}

class _StylePreviewScreenState extends ConsumerState<StylePreviewScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _consentGiven = false;
  
  List<dynamic> _garments = [];
  List<dynamic> _colors = [];
  String? _selectedGarmentId;
  String? _selectedColorId;
  
  bool _isLoading = false;
  bool _isGenerating = false;
  String? _errorMessage;
  
  // Cache for generated images: key is "path_garment_color"
  final Map<String, List<int>> _generatedCache = {};
  List<int>? _currentPreviewBytes;
  bool _showOriginal = false;

  @override
  void initState() {
    super.initState();
    _fetchStyles();
  }
  
  Future<void> _fetchStyles() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('/api/style-preview/styles');
      if (response.statusCode == 200) {
        setState(() {
          _garments = response.data['garments'];
          _colors = response.data['colors'];
          if (_garments.isNotEmpty) _selectedGarmentId = _garments[0]['id'];
          if (_colors.isNotEmpty) _selectedColorId = _colors[0]['id'];
        });
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load styles. Please check your connection.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _currentPreviewBytes = null; // reset preview for new image
          _errorMessage = null;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to pick image or permission denied.')),
      );
    }
  }

  Future<void> _generatePreview() async {
    if (_selectedImage == null || _selectedGarmentId == null || _selectedColorId == null) return;
    
    final cacheKey = '${_selectedImage!.path}_${_selectedGarmentId}_$_selectedColorId';
    if (_generatedCache.containsKey(cacheKey)) {
      setState(() {
        _currentPreviewBytes = _generatedCache[cacheKey];
      });
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      String filename = _selectedImage!.path.split('/').last;
      FormData formData = FormData.fromMap({
        'garment_id': _selectedGarmentId,
        'color_id': _selectedColorId,
        'photo': await MultipartFile.fromFile(_selectedImage!.path, filename: filename),
      });

      // Using Dio with extended timeout for image generation
      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/api/style-preview',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      if (response.statusCode == 200) {
        final bytes = response.data as List<int>;
        _generatedCache[cacheKey] = bytes;
        setState(() {
          _currentPreviewBytes = bytes;
        });
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 413) {
        _errorMessage = 'Photo is too large. Please use an image under 8MB.';
      } else if (e.response?.statusCode == 502) {
        _errorMessage = 'The AI model could not generate the image. Please try a different photo.';
      } else {
        _errorMessage = 'Network error or timeout. Please try again.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred.';
    } finally {
      setState(() => _isGenerating = false);
    }
  }

  Widget _buildGarmentSelection() {
    if (_garments.isEmpty) return const SizedBox.shrink();
    
    final selectedGarment = _garments.firstWhere((g) => g['id'] == _selectedGarmentId, orElse: () => _garments[0]);
    final needsFullBody = selectedGarment['needs_full_body'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Garment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _garments.map((g) {
            final isSelected = g['id'] == _selectedGarmentId;
            return ChoiceChip(
              label: Text(g['label']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedGarmentId = g['id']);
              },
            );
          }).toList(),
        ),
        if (needsFullBody)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text('For trousers, use a full-body photo.', style: GoogleFonts.inter(color: Colors.blue, fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildColorSelection() {
    if (_colors.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Color', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _colors.map((c) {
            final isSelected = c['id'] == _selectedColorId;
            return ChoiceChip(
              label: Text(c['label']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedColorId = c['id']);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try Your Style'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Preview how a style could look on you. This is a visual preview, not an exact fit.",
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 24),
                  
                  // Image Area
                  if (_selectedImage == null)
                    Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.person, size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Camera'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => _pickImage(ImageSource.gallery),
                                icon: const Icon(Icons.photo_library),
                                label: const Text('Gallery'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: _currentPreviewBytes != null && !_showOriginal
                              ? Image.memory(
                                  Uint8List.fromList(_currentPreviewBytes!), 
                                  height: 350,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(_selectedImage!, height: 350, fit: BoxFit.cover),
                        ),
                        if (_currentPreviewBytes != null)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Show Original'),
                              Switch(
                                value: _showOriginal,
                                onChanged: (val) => setState(() => _showOriginal = val),
                              ),
                            ],
                          ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                              _currentPreviewBytes = null;
                              _consentGiven = false;
                            });
                          },
                          child: const Text('Change Photo'),
                        ),
                      ],
                    ),

                  const SizedBox(height: 24),
                  
                  if (_selectedImage != null && _currentPreviewBytes == null)
                    CheckboxListTile(
                      title: const Text("I agree to send this photo for the preview. It is not stored."),
                      value: _consentGiven,
                      onChanged: (val) => setState(() => _consentGiven = val ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                    ),

                  const SizedBox(height: 24),
                  _buildGarmentSelection(),
                  const SizedBox(height: 24),
                  _buildColorSelection(),
                  
                  const SizedBox(height: 32),
                  
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red[50],
                      child: Column(
                        children: [
                          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                          TextButton(onPressed: _generatePreview, child: const Text('Retry'))
                        ],
                      ),
                    ),

                  if (_isGenerating)
                    Column(
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Creating your preview... this can take up to a minute',
                          style: GoogleFonts.inter(color: Colors.grey[700]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    )
                  else if (_currentPreviewBytes == null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: (_selectedImage != null && _consentGiven) ? _generatePreview : null,
                      child: const Text('Generate Preview', style: TextStyle(fontSize: 16)),
                    )
                  else
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentPreviewBytes = null;
                        });
                      },
                      child: const Text('Try another style'),
                    ),
                ],
              ),
            ),
    );
  }
}
