import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AiService {
  late final GenerativeModel _model;
  late final String _apiKey;

  AiService() {
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    final firebaseKey = dotenv.env['FIREBASE_API_KEY'];
    
    _apiKey = (geminiKey != null && geminiKey.trim().isNotEmpty) ? geminiKey : (firebaseKey ?? '');
    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> generateResponse(
    String prompt, {
    List<int>? imageBytes,
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final List<Part> parts = [];
      const systemInstruction = "You are a friendly and expert science/math tutor. Solve the question provided in the image step-by-step. "
          "Important: Format all mathematical formulas, equations, and expressions using standard LaTeX notation. "
          "Use double dollar signs '\$\$...\$\$' for block equations on separate lines, and single dollar signs '\$...\$' for inline math expressions inside text. "
          "Do NOT use any Markdown formatting like asterisks (**) for bolding. Use plain text formatting only. "
          "Provide a clear, detailed, and simple explanation of the solution without unnecessary line breaks.";
      
      parts.add(TextPart(systemInstruction));
      if (prompt.trim().isNotEmpty) {
        parts.add(TextPart("Additional context/question: $prompt"));
      } else {
        parts.add(TextPart("Please solve the question in this image step-by-step with clear explanation."));
      }

      if (imageBytes != null) {
        parts.add(DataPart(mimeType, Uint8List.fromList(imageBytes)));
      }

      final content = [Content.multi(parts)];
      
      try {
        final response = await _model.generateContent(content);
        return response.text ?? 'Sorry, I could not generate an answer.';
      } catch (e) {
        final errorStr = e.toString();
        // Fallback to gemini-2.5-pro if flash fails
        if (errorStr.contains("gemini-2.5-flash") && errorStr.contains("not found")) {
          debugPrint("Fallback to gemini-2.5-pro");
          final fallbackModel = GenerativeModel(
            model: 'gemini-2.5-pro',
            apiKey: _apiKey,
          );
          final response = await fallbackModel.generateContent(content);
          return response.text ?? 'Sorry, I could not generate an answer.';
        }
        rethrow;
      }
    } catch (e) {
      return 'Error querying Gemini AI: $e';
    }
  }
}

final aiService = AiService();
