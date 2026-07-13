import 'models.dart';

class MockData {
  static final List<ExamCategory> examCategories = [
    ExamCategory(
      id: 'c1',
      title: 'Engineering',
      exams: [
        Exam(id: 'e1', name: 'JEE Mains', logoUrl: 'assets/jee.png', yearRange: '2015-2023'),
        Exam(id: 'e2', name: 'JEE Advance', logoUrl: 'assets/jee.png', yearRange: '2015-2023'),
        Exam(id: 'e3', name: 'WBJEE', logoUrl: 'assets/wbjee.png', yearRange: '2018-2023'),
      ],
    ),
    ExamCategory(
      id: 'c2',
      title: 'Medical',
      exams: [
        Exam(id: 'e4', name: 'NEET', logoUrl: 'assets/neet.png', yearRange: '2016-2023'),
      ],
    ),
    ExamCategory(
      id: 'c3',
      title: 'Boards Exam',
      exams: [
        Exam(id: 'e5', name: 'CBSE 10', logoUrl: 'assets/cbse.png', yearRange: '2010-2023'),
        Exam(id: 'e6', name: 'CBSE 12', logoUrl: 'assets/cbse.png', yearRange: '2010-2023'),
      ],
    ),
    ExamCategory(
      id: 'c4',
      title: 'Government Exams',
      exams: [
        Exam(id: 'e7', name: 'SSC CGL', logoUrl: 'assets/ssc.png', yearRange: '2015-2023'),
        Exam(id: 'e8', name: 'SSC CHSL', logoUrl: 'assets/ssc.png', yearRange: '2015-2023'),
      ],
    ),
  ];

  static final List<Question> sampleQuestions = [
    Question(
      id: 'q1',
      text: 'What is the SI unit of force?',
      options: ['Newton', 'Joule', 'Watt', 'Pascal'],
      correctOptionIndex: 0,
    ),
    Question(
      id: 'q2',
      text: 'Which of the following is a noble gas?',
      options: ['Oxygen', 'Nitrogen', 'Helium', 'Carbon Dioxide'],
      correctOptionIndex: 2,
    ),
    Question(
      id: 'q3',
      text: 'Solve for x: 2x + 5 = 15',
      options: ['5', '10', '15', '20'],
      correctOptionIndex: 0,
    ),
  ];
}
