import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers/api_provider.dart';

enum MessageType { user, assistant, system }
enum ContentType { text, image, loading, error }

class ChatMessage {
  final MessageType type;
  final ContentType contentType;
  final String? text;
  final Uint8List? imageBytes;
  final File? imageFile;
  final bool isInitialPhoto;

  ChatMessage({
    required this.type,
    required this.contentType,
    this.text,
    this.imageBytes,
    this.imageFile,
    this.isInitialPhoto = false,
  });
}

class StylePreviewScreen extends ConsumerStatefulWidget {
  const StylePreviewScreen({super.key});

  @override
  ConsumerState<StylePreviewScreen> createState() => _StylePreviewScreenState();
}

class _StylePreviewScreenState extends ConsumerState<StylePreviewScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _consentGiven = false;
  bool _isLoadingStyles = false;
  bool _isGenerating = false;
  
  List<dynamic> _garments = [];
  List<dynamic> _colors = [];
  String _selectedColorId = "white"; // Default color

  File? _originalPhoto;
  Uint8List? _latestResultBytes;
  int _editCount = 0;
  final int _maxEdits = 10;

  @override
  void initState() {
    super.initState();
    _startNewChat();
    _fetchStyles();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startNewChat() {
    setState(() {
      _messages = [
        ChatMessage(
          type: MessageType.assistant,
          contentType: ContentType.text,
          text: "Add a photo of the person to get started. This is a visual preview, not an exact fit.",
        )
      ];
      _originalPhoto = null;
      _latestResultBytes = null;
      _editCount = 0;
      _consentGiven = false;
      _isGenerating = false;
    });
  }

  Future<void> _fetchStyles() async {
    setState(() => _isLoadingStyles = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.dio.get('/style-preview/styles');
      if (response.statusCode == 200) {
        setState(() {
          _garments = response.data['garments'];
          _colors = response.data['colors'];
          if (_colors.isNotEmpty) _selectedColorId = _colors[0]['id'];
        });
      }
    } catch (e) {
      debugPrint("Failed to load styles: $e");
    } finally {
      setState(() => _isLoadingStyles = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!_consentGiven) {
      _showConsentDialog(source);
      return;
    }
    
    _processImagePick(source);
  }
  
  void _showConsentDialog(ImageSource source) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Photo Consent"),
        content: const Text("I agree to send this photo for the preview. It is not stored."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _consentGiven = true);
              _processImagePick(source);
            },
            child: const Text("I Agree"),
          ),
        ],
      ),
    );
  }

  Future<void> _processImagePick(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source);
      if (picked != null) {
        setState(() {
          _originalPhoto = File(picked.path);
          _messages.add(ChatMessage(
            type: MessageType.user,
            contentType: ContentType.image,
            imageFile: _originalPhoto,
            isInitialPhoto: true,
          ));
        });
        _scrollToBottom();
      }
    } catch (e) {
      _addSystemMessage("Failed to access camera or gallery. Please check permissions.");
    }
  }
  
  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.system,
        contentType: ContentType.text,
        text: text,
      ));
    });
    _scrollToBottom();
  }

  Future<void> _generateInitialPreview(String garmentId, String garmentLabel) async {
    if (_originalPhoto == null) return;
    
    final colorLabel = _colors.firstWhere((c) => c['id'] == _selectedColorId, orElse: () => {'label': _selectedColorId})['label'];
    final userText = "$garmentLabel in $colorLabel";
    
    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.user,
        contentType: ContentType.text,
        text: userText,
      ));
      _messages.add(ChatMessage(
        type: MessageType.assistant,
        contentType: ContentType.loading,
      ));
      _isGenerating = true;
    });
    _scrollToBottom();

    try {
      String filename = _originalPhoto!.path.split('/').last;
      FormData formData = FormData.fromMap({
        'garment_id': garmentId,
        'color_id': _selectedColorId,
        'photo': await MultipartFile.fromFile(_originalPhoto!.path, filename: filename),
      });

      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/style-preview/',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      _handleImageResponse(response);
    } catch (e) {
      _handleApiError(e, () => _generateInitialPreview(garmentId, garmentLabel));
    }
  }

  Future<void> _generateFollowUp(String instruction) async {
    if (_latestResultBytes == null || _originalPhoto == null || instruction.trim().isEmpty) return;
    if (_editCount >= _maxEdits) {
      _addSystemMessage("You have reached the maximum of $_maxEdits edits for this session. Please start a new photo.");
      return;
    }
    
    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.user,
        contentType: ContentType.text,
        text: instruction,
      ));
      _messages.add(ChatMessage(
        type: MessageType.assistant,
        contentType: ContentType.loading,
      ));
      _isGenerating = true;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      // Create temporary file for latest result bytes
      final tempDir = await getTemporaryDirectory();
      final latestImgFile = File('${tempDir.path}/latest_edit_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await latestImgFile.writeAsBytes(_latestResultBytes!);
      
      String origFilename = _originalPhoto!.path.split('/').last;
      String editFilename = latestImgFile.path.split('/').last;
      
      FormData formData = FormData.fromMap({
        'instruction': instruction,
        'image': await MultipartFile.fromFile(latestImgFile.path, filename: editFilename),
        'original': await MultipartFile.fromFile(_originalPhoto!.path, filename: origFilename),
      });

      final api = ref.read(apiClientProvider);
      final response = await api.dio.post(
        '/style-preview/edit',
        data: formData,
        options: Options(
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 90),
          sendTimeout: const Duration(seconds: 90),
        ),
      );

      _handleImageResponse(response);
    } catch (e) {
      _handleApiError(e, () => _generateFollowUp(instruction));
    }
  }

  void _handleImageResponse(Response response) {
    if (response.statusCode == 200) {
      final bytes = Uint8List.fromList(response.data as List<int>);
      setState(() {
        _messages.removeLast(); // Remove loading
        _latestResultBytes = bytes;
        _editCount++;
        _messages.add(ChatMessage(
          type: MessageType.assistant,
          contentType: ContentType.image,
          imageBytes: bytes,
        ));
        _isGenerating = false;
      });
      _scrollToBottom();
    }
  }

  void _handleApiError(dynamic e, VoidCallback retryCallback) {
    setState(() {
      _messages.removeLast(); // Remove loading
      _isGenerating = false;
    });
    
    String errorMsg = "Network error or timeout. Please try again.";
    if (e is DioException) {
      if (e.response?.statusCode == 413) {
        errorMsg = "Photo is too large. Please use an image under 8MB.";
      } else if (e.response?.statusCode == 429) {
        errorMsg = "The preview service is busy. Please try again in a minute.";
      } else if (e.response?.statusCode == 502) {
        errorMsg = "The AI model could not generate the image. Try a clearer, well-lit photo.";
      }
    }
    
    setState(() {
      _messages.add(ChatMessage(
        type: MessageType.system,
        contentType: ContentType.error,
        text: errorMsg,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  void _showZoomedImage(Uint8List bytes) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 1.0,
              maxScale: 4.0,
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveImage(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/tailorsync_style_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'My Style Preview from TailorSync!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share image')),
      );
    }
  }

  void _startOverWithOriginal() {
    if (_originalPhoto == null) return;
    setState(() {
      _latestResultBytes = null;
      _editCount = 0;
      // Keep only initial messages and the original photo
      _messages.removeWhere((m) => m.type != MessageType.assistant || m.isInitialPhoto == false);
      _messages = [
        ChatMessage(
          type: MessageType.assistant,
          contentType: ContentType.text,
          text: "Started over. Select a new style for this photo.",
        ),
        ChatMessage(
          type: MessageType.user,
          contentType: ContentType.image,
          imageFile: _originalPhoto,
          isInitialPhoto: true,
        )
      ];
    });
  }

  Widget _buildMessageBubble(ChatMessage message) {
    if (message.contentType == ContentType.loading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(height: 8),
              Text("Creating your preview... this can take up to a minute", style: TextStyle(color: Colors.grey[700], fontSize: 12)),
            ],
          ),
        ),
      );
    }
    
    if (message.type == MessageType.system || message.contentType == ContentType.error) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: message.contentType == ContentType.error ? Colors.red[50] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            message.text ?? '',
            style: TextStyle(
              fontSize: 12,
              color: message.contentType == ContentType.error ? Colors.red[800] : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    final isUser = message.type == MessageType.user;
    
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? Theme.of(context).primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(16).copyWith(
            bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
            bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.contentType == ContentType.text)
              Text(
                message.text!,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87),
              ),
            if (message.contentType == ContentType.image) ...[
              GestureDetector(
                onTap: () {
                  if (message.imageBytes != null) _showZoomedImage(message.imageBytes!);
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: message.imageBytes != null 
                    ? Image.memory(message.imageBytes!, fit: BoxFit.cover)
                    : (message.imageFile != null ? Image.file(message.imageFile!, fit: BoxFit.cover) : const SizedBox()),
                ),
              ),
              if (!isUser && message.imageBytes != null) ...[
                const SizedBox(height: 8),
                Text("Style preview, not exact fit", style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, size: 20),
                      onPressed: () => _saveImage(message.imageBytes!),
                      tooltip: "Share/Save",
                    ),
                  ],
                ),
              ],
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    if (_isGenerating || _isLoadingStyles) return const SizedBox.shrink();
    
    // Suggest garments if no initial photo is chosen yet
    if (_originalPhoto == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt, size: 18),
              label: const Text("Take Photo"),
              onPressed: () => _pickImage(ImageSource.camera),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              icon: const Icon(Icons.photo_library, size: 18),
              label: const Text("Gallery"),
              onPressed: () => _pickImage(ImageSource.gallery),
            ),
          ],
        ),
      );
    }
    
    // Suggest garments for first generation
    if (_latestResultBytes == null) {
      if (_garments.isEmpty) return const SizedBox.shrink();
      return Container(
        height: 50,
        margin: const EdgeInsets.only(bottom: 8),
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            // Color selector
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedColorId,
                items: _colors.map<DropdownMenuItem<String>>((c) {
                  return DropdownMenuItem<String>(
                    value: c['id'],
                    child: Text(c['label'], style: const TextStyle(fontSize: 13)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedColorId = val);
                },
              ),
            ),
            const SizedBox(width: 16),
            ..._garments.map((g) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                label: Text(g['label'], style: const TextStyle(fontSize: 12)),
                onPressed: () => _generateInitialPreview(g['id'], g['label']),
              ),
            )).toList(),
          ],
        ),
      );
    }
    
    // Suggest follow-ups
    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          "Change colour to black",
          "Make sleeves shorter",
          "Make it more fitted",
          "Try a patterned fabric",
        ].map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            onPressed: () => _generateFollowUp(s),
          ),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Try Your Style', style: TextStyle(fontSize: 18)),
            if (_editCount > 0)
              Text('Edits: $_editCount / $_maxEdits', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/home'),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'start_over') _startOverWithOriginal();
              if (value == 'new_photo') _startNewChat();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'start_over', child: Text('Start over with same photo')),
              const PopupMenuItem(value: 'new_photo', child: Text('Start new session')),
            ],
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
            ),
          ),
          _buildSuggestions(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, -1))],
            ),
            child: Row(
              children: [
                if (_originalPhoto == null) ...[
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.grey),
                    onPressed: _isGenerating ? null : () => _pickImage(ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library, color: Colors.grey),
                    onPressed: _isGenerating ? null : () => _pickImage(ImageSource.gallery),
                  ),
                ],
                Expanded(
                  child: TextField(
                    controller: _textController,
                    enabled: !_isGenerating && _originalPhoto != null && _latestResultBytes != null,
                    decoration: InputDecoration(
                      hintText: _latestResultBytes == null 
                        ? 'Select a garment first...' 
                        : 'Describe your edit...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[200],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    maxLength: 300,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (val) {
                      if (val.trim().isNotEmpty) _generateFollowUp(val);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blue),
                  onPressed: (_isGenerating || _latestResultBytes == null || _textController.text.trim().isEmpty)
                      ? null
                      : () => _generateFollowUp(_textController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
