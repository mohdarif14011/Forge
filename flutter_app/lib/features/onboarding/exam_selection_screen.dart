import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/models.dart';
import '../../models/mock_data.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/app_button.dart';
import '../../widgets/section_title.dart';
import '../../core/theme.dart';

class ExamSelectionScreen extends StatefulWidget {
  const ExamSelectionScreen({super.key});

  @override
  State<ExamSelectionScreen> createState() => _ExamSelectionScreenState();
}

class _ExamSelectionScreenState extends State<ExamSelectionScreen> {
  Exam? _selectedExam;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  const AnimatedBackButton(),
                  const Expanded(
                    child: Center(
                      child: SectionTitle(title: 'Select Exam'),
                    ),
                  ),
                  const SizedBox(width: 40), // Balance the back button
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                itemCount: MockData.examCategories.length,
                itemBuilder: (context, index) {
                  final category = MockData.examCategories[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          category.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.black,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: category.exams.map((exam) {
                          final isSelected = _selectedExam?.id == exam.id;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedExam = exam;
                              });
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: (MediaQuery.of(context).size.width - 44) / 2, // 2 columns
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryBlue : AppTheme.borderColor,
                                  width: 0.5,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Placeholder for logo since we don't have actual assets
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                      color: AppTheme.lightBackground,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.borderColor, width: 0.5),
                                    ),
                                    child: const Icon(Icons.school_outlined, color: AppTheme.black, size: 24),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    exam.name,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      color: isSelected ? AppTheme.primaryBlue : AppTheme.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                child: AppButton(
                  text: 'Continue',
                  type: _selectedExam != null ? AppButtonType.solid : AppButtonType.unselected,
                  onPressed: () {
                    if (_selectedExam != null) {
                      context.go('/home');
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
