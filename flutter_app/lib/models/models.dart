class ExamCategory {
  final String id;
  final String title;
  final List<Exam> exams;

  ExamCategory({required this.id, required this.title, required this.exams});
}

class Exam {
  final String id;
  final String name;
  final String logoUrl;
  final String? yearRange;

  Exam({required this.id, required this.name, required this.logoUrl, this.yearRange});
}

class Question {
  final String id;
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final int positiveMarks;
  final int negativeMarks;

  Question({
    required this.id,
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    this.positiveMarks = 4,
    this.negativeMarks = 1,
  });
}
