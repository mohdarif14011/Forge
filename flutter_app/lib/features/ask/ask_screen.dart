import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/services/ai_service.dart';
import 'package:flutter_math_fork/flutter_math.dart';

class AskScreen extends StatefulWidget {
  const AskScreen({super.key});

  @override
  State<AskScreen> createState() => _AskScreenState();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final String? imagePath;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.imagePath,
    required this.timestamp,
  });
}

class _AskScreenState extends State<AskScreen> {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isGenerating = false;
  final int _aiQuestionsUsed = 0;


  final List<ChatMessage> _chatMessages = [];

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _submitQuery() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload a picture of the question to get the solution!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final query = _queryController.text.trim();
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Check query limit removed

    // Append User Message
    final userMsg = ChatMessage(
      text: query.isEmpty ? 'Solved Image Question' : query,
      isUser: true,
      imagePath: _selectedImage!.path,
      timestamp: DateTime.now(),
    );

    setState(() {
      _chatMessages.add(userMsg);
      _isGenerating = true;
    });
    _scrollToBottom();

    // Cache image path and reset selection early for UI cleanliness
    final imageFile = _selectedImage!;
    setState(() {
      _selectedImage = null;
      _queryController.clear();
    });

    try {
      // 1. Read image bytes
      final imageBytes = await imageFile.readAsBytes();

      // 2. Query Gemini model via service
      final promptText = query.isEmpty 
          ? "Please solve the question in this image step-by-step with clear explanation." 
          : query;
          
      final responseText = await aiService.generateResponse(
        promptText,
        imageBytes: imageBytes,
      );

      // Append AI Response
      final aiMsg = ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        setState(() {
          _chatMessages.add(aiMsg);
        });
        _scrollToBottom();
      }

      // 3. Save to Firestore user profile history & update limits
      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      await userRef.update({
        'aiChatHistory': FieldValue.arrayUnion([
          {
            'query': query.isEmpty ? 'Solved Image Question' : query,
            'response': responseText,
            'timestamp': DateTime.now().toIso8601String(),
            'hasImage': true,
          }
        ]),
      });

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error solving doubt: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showHistorySheet() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useRootNavigator: true,
      useSafeArea: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Doubt History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final data = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    final List<dynamic> history = data['aiChatHistory'] as List<dynamic>? ?? [];

                    final List<Map<String, dynamic>> docs = history
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList();

                    docs.sort((a, b) {
                      final aTime = a['timestamp'] as String?;
                      final bTime = b['timestamp'] as String?;
                      if (aTime == null) return 1;
                      if (bTime == null) return -1;
                      return bTime.compareTo(aTime);
                    });

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.chat_bubble_text, size: 48, color: Colors.grey[300]),
                            const SizedBox(height: 12),
                            const Text('No doubt history found', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final item = docs[index];
                        return Card(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0.5,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                            title: Text(
                              item['query'] ?? 'Solved Image Question',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              item['response'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            leading: const Icon(CupertinoIcons.chat_bubble_text_fill, color: Colors.purple, size: 18),
                            trailing: const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
                            onTap: () {
                              setState(() {
                                _chatMessages.clear();
                                _chatMessages.add(ChatMessage(
                                  text: item['query'] ?? 'Solved Image Question',
                                  isUser: true,
                                  timestamp: DateTime.now(),
                                ));
                                _chatMessages.add(ChatMessage(
                                  text: item['response'] ?? '',
                                  isUser: false,
                                  timestamp: DateTime.now(),
                                ));
                              });
                              Navigator.pop(context);
                              _scrollToBottom();
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showImagePickerOptions() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: const Text('Upload Question Image'),
        message: const Text('Choose a source to upload your textbook doubt question.'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(ImageSource.gallery);
            },
            child: const Text('Gallery'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => context.pop(),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text.rich(
          TextSpan(
            children: [
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Icon(CupertinoIcons.sparkles, color: Theme.of(context).colorScheme.onSurface, size: 18),
              ),
              const WidgetSpan(child: SizedBox(width: 6)),
              TextSpan(
                text: 'Powered by Google Deepmind',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.clock, color: Theme.of(context).colorScheme.onSurface),
            onPressed: _showHistorySheet,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
              // Chat Content
              Expanded(
                child: _chatMessages.isEmpty
                    ? _buildChatGPTGreetingView(isDark)
                    : ListView.builder(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: _chatMessages.length + (_isGenerating ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _chatMessages.length) {
                            return _buildThinkingBubble();
                          }
                          return _buildChatBubble(_chatMessages[index], isDark);
                        },
                      ),
              ),

              // Floating attachment preview right above input pill
              if (_selectedImage != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  alignment: Alignment.centerLeft,
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 8, right: 8),
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.purple.withValues(alpha: 0.3), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10.0),
                          child: Image.file(_selectedImage!, fit: BoxFit.cover),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                          child: const Icon(CupertinoIcons.xmark, color: Colors.white, size: 10),
                        ),
                      ),
                    ],
                  ),
                ),

              // ChatGPT Input Pill
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Attachment Plus Button
                    GestureDetector(
                      onTap: _showImagePickerOptions,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          CupertinoIcons.plus,
                          color: Theme.of(context).colorScheme.onSurface,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text Input Field & Send Button Pill
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[200]!, width: 1),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _queryController,
                                textCapitalization: TextCapitalization.sentences,
                                style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurface),
                                decoration: const InputDecoration(
                                  hintText: 'Message Doubt Solver...',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),

                            // Send Button
                            GestureDetector(
                              onTap: _isGenerating ? null : _submitQuery,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (_selectedImage != null && !_isGenerating) ? (isDark ? Colors.white : Colors.black) : Colors.grey[300],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  CupertinoIcons.arrow_up,
                                  color: (_selectedImage != null && !_isGenerating) ? (isDark ? Colors.black : Colors.white) : Colors.grey[600],
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Helper prompt warning under the pill
              if (_selectedImage == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 6.0),
                  child: Text(
                    'Please attach an image of the question to start solving.',
                    style: TextStyle(color: Colors.grey, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
    );
  }

  Widget _buildChatGPTGreetingView(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.12),
          
          // ChatGPT Sparkling Circular Icon
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey[50],
              shape: BoxShape.circle,
              border: Border.all(color: isDark ? const Color(0xFF3C3C3C) : Colors.grey[100]!, width: 1.5),
            ),
            child: Icon(CupertinoIcons.sparkles, color: Theme.of(context).colorScheme.onSurface, size: 48),
          ),
          const SizedBox(height: 20),
          
          Text(
            'How can I help you today?',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Theme.of(context).colorScheme.onSurface),
          ),
            
          const SizedBox(height: 32),

          // Suggestion Action Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                _buildQuickActionCard(
                  icon: CupertinoIcons.camera_fill,
                  title: 'Solve textbook math problem',
                  subtitle: 'Take a snap of the equation to get explanations.',
                  onTap: _showImagePickerOptions,
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _buildQuickActionCard(
                  icon: CupertinoIcons.lab_flask_solid,
                  title: 'Explain chemistry diagrams',
                  subtitle: 'Upload any science diagram to solve it.',
                  onTap: _showImagePickerOptions,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    bool isDark = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.purple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ),
            const Icon(CupertinoIcons.chevron_right, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage message, bool isDark) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 16, left: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (message.imagePath != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(message.imagePath!), fit: BoxFit.cover),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2C2C2C) : Colors.black87,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                child: Text(
                  message.text,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // AI ChatGPT Response Bubble
      return Align(
        alignment: Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24, right: 32),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo Sparkles Circle
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.sparkles, color: Colors.purple, size: 14),
              ),
              const SizedBox(width: 10),
              
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AI Assistant',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple),
                    ),
                    const SizedBox(height: 4),
                    _buildFormattedText(message.text, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _cleanPlainText(String text) {
    return text
        .replaceAll(RegExp(r'^#+\s+', multiLine: true), '') // Remove Markdown headers
        .replaceAll('**', '') // Remove bold markers
        .replaceAll(RegExp(r'^\*\s+', multiLine: true), '• ') // Replace * bullets with •
        .replaceAll(RegExp(r'^-+\s+', multiLine: true), '• ') // Replace - bullets with •
        .replaceAll('--', ''); // Remove stray --
  }

  Widget _buildFormattedText(String text, bool isDark) {
    // Splits the text by block math ($$...$$) and inline math ($...$)
    final RegExp mathRegExp = RegExp(r'(\$\$.*?\$\$|\$.*?\$)', dotAll: true);
    final matches = mathRegExp.allMatches(text);
    
    if (matches.isEmpty) {
      return SelectableText(
        _cleanPlainText(text),
        style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? Colors.white : Colors.black87),
      );
    }
    
    final List<InlineSpan> spans = [];
    int lastIndex = 0;
    
    for (final match in matches) {
      // Plain text block before math expression
      if (match.start > lastIndex) {
        final plainText = text.substring(lastIndex, match.start);
        spans.add(TextSpan(
          text: _cleanPlainText(plainText),
          style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? Colors.white : Colors.black87),
        ));
      }
      
      // Math expression
      final mathText = match.group(0)!;
      final bool isBlock = mathText.startsWith('\$\$');
      final String formula = mathText.replaceAll('\$\$', '').replaceAll('\$', '').trim();
      
      try {
        final mathWidget = Math.tex(
          formula,
          textStyle: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
          onErrorFallback: (err) => Text(mathText, style: const TextStyle(color: Colors.red)),
        );

        if (isBlock) {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: mathWidget,
              ),
            ),
          ));
        } else {
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: mathWidget,
              ),
            ),
          ));
        }
      } catch (e) {
        spans.add(TextSpan(text: mathText, style: const TextStyle(color: Colors.red)));
      }
      
      lastIndex = match.end;
    }
    
    // Remaining plain text block
    if (lastIndex < text.length) {
      final plainText = text.substring(lastIndex);
      spans.add(TextSpan(
        text: _cleanPlainText(plainText),
        style: TextStyle(fontSize: 14, height: 1.45, color: isDark ? Colors.white : Colors.black87),
      ));
    }
    
    return SelectableText.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildThinkingBubble() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.sparkles, color: Colors.purple, size: 14),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Assistant',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.purple),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Thinking...',
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
