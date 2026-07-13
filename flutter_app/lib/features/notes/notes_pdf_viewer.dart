import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../widgets/animated_back_button.dart';

class NotesPdfViewerScreen extends StatelessWidget {
  final Map<String, dynamic> params;

  const NotesPdfViewerScreen({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    final pdfUrl = params['pdfUrl'] ?? '';
    final title = params['title'] ?? 'Notes';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: AnimatedBackButton(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: pdfUrl.isEmpty
          ? const Center(child: Text('Invalid PDF URL'))
          : SfPdfViewer.network(
              pdfUrl,
              canShowScrollHead: false,
              canShowScrollStatus: false,
              enableDocumentLinkAnnotation: false,
            ),
    );
  }
}
