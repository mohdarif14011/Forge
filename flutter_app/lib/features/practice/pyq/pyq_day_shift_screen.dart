import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../widgets/animated_back_button.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/section_title.dart';

class PyqDayShiftScreen extends StatefulWidget {
  final Map<String, dynamic> params;
  const PyqDayShiftScreen({super.key, this.params = const {}});

  @override
  State<PyqDayShiftScreen> createState() => _PyqDayShiftScreenState();
}

class _PyqDayShiftScreenState extends State<PyqDayShiftScreen> {
  List<Map<String, dynamic>> _days = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchShifts();
  }

  Future<void> _fetchShifts() async {
    final examId = widget.params['examId'];
    final year = widget.params['year'];
    
    if (examId == null || year == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('questions')
          .where('type', isEqualTo: 'pyq')
          .where('examId', isEqualTo: examId)
          .where('year', isEqualTo: year)
          .get();
          
      // Group by date and shift
      Map<String, Set<String>> dateShifts = {};
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        String date = data['date'] ?? 'Unknown Date';
        if (date.isEmpty) date = 'Unknown Date';
        
        String shift = data['shift'] ?? 'Unknown Shift';
        if (shift.isEmpty) shift = 'Unknown Shift';
        
        String lower = shift.toLowerCase();
        if (lower == '1' || lower == 'shift 1' || lower == 'morning' || lower == 'morning shift') {
          shift = 'Morning Shift';
        } else if (lower == '2' || lower == 'shift 2' || lower == 'evening' || lower == 'evening shift') {
          shift = 'Evening Shift';
        } else if (!lower.startsWith('shift') && !lower.endsWith('shift') && shift != 'Unknown Shift') {
          shift = 'Shift $shift';
        }
        
        if (!dateShifts.containsKey(date)) {
          dateShifts[date] = {};
        }
        dateShifts[date]!.add(shift);
      }
      
      final List<Map<String, dynamic>> parsedDays = dateShifts.entries.map((e) {
        return {
          'date': e.key,
          'shifts': e.value.toList()..sort(),
        };
      }).toList();
      
      parsedDays.sort((a, b) => a['date'].compareTo(b['date']));

      setState(() {
        _days = parsedDays;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

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
                      child: SectionTitle(title: 'Select Shift'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _days.isEmpty
                  ? const Center(child: Text("No shifts found for this year."))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _days.length,
                      itemBuilder: (context, index) {
                        final day = _days[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                day['date'],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: (day['shifts'] as List<String>).map((shift) {
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: AppButton(
                                        text: shift,
                                        type: AppButtonType.outlined,
                                        onPressed: () {
                                          context.push('/test/start', extra: {
                                            ...widget.params,
                                            'date': day['date'],
                                            'shift': shift,
                                          });
                                        },
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
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
