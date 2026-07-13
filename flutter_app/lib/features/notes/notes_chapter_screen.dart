import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';
import '../../core/theme.dart';

class NotesChapterScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const NotesChapterScreen({super.key, required this.params});

  @override
  State<NotesChapterScreen> createState() => _NotesChapterScreenState();
}

class _NotesChapterScreenState extends State<NotesChapterScreen> {
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final exam = widget.params['exam'];
    final subject = widget.params['subject'];
    if (exam == null || subject == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('notes')
          .where('examId', isEqualTo: exam['id'])
          .where('subject', isEqualTo: subject)
          .get();

      if (mounted) {
        setState(() {
          _notes = snapshot.docs.map((e) => e.data()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notes: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getThumbnailUrl(String pdfUrl) {
    if (pdfUrl.contains('res.cloudinary.com') && pdfUrl.endsWith('.pdf')) {
      String jpgUrl = pdfUrl.replaceAll(RegExp(r'\.pdf$'), '.jpg');
      if (!jpgUrl.contains('/upload/pg_')) {
        jpgUrl = jpgUrl.replaceFirst('/upload/', '/upload/w_400,f_jpg,q_auto,pg_1/');
      }
      return jpgUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.params['subject'] ?? 'Subject';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const AnimatedBackButton(),
                  Expanded(
                    child: Center(
                      child: SectionTitle(title: '$subject Notes'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue))
                : _notes.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined, size: 64, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            "No notes available.",
                            style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16.0),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.75, // Taller cards for cover images
                      ),
                      itemCount: _notes.length,
                      itemBuilder: (context, index) {
                        final note = _notes[index];
                        final pdfUrl = note['pdfUrl']?.toString() ?? '';
                        final thumbnailUrl = _getThumbnailUrl(pdfUrl);
                        final title = note['chapter']?.toString() ?? note['title']?.toString() ?? 'Note';
                        final pages = note['pages']?.toString() ?? 'Unknown';

                        return GestureDetector(
                          onTap: () {
                            if (pdfUrl.isNotEmpty) {
                              context.push('/notes/pdf', extra: {
                                'pdfUrl': pdfUrl,
                                'title': title,
                              });
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No PDF attached to this note.')),
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Cover Image Section
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: thumbnailUrl.isNotEmpty
                                      ? Image.network(
                                          thumbnailUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                            child: const Center(child: Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 40)),
                                          ),
                                        )
                                      : Container(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                          child: const Center(child: Icon(Icons.picture_as_pdf, color: AppTheme.primaryBlue, size: 40)),
                                        ),
                                  ),
                                ),
                                // Text Details Section
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          title,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(context).colorScheme.onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Row(
                                          children: [
                                            const Icon(Icons.pages_outlined, size: 14, color: Colors.grey),
                                            const SizedBox(width: 4),
                                            Text(
                                              '$pages Pages',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
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
        ),
      ),
    );
  }
}
