import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme.dart';
import '../../widgets/animated_back_button.dart';
import '../../widgets/section_title.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  bool _isLoading = true;
  Map<String, dynamic>? _userData;

  // Controllers for editing
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _mobileCtrl = TextEditingController();
  final TextEditingController _examCtrl = TextEditingController();
  final TextEditingController _yearCtrl = TextEditingController();
  final TextEditingController _classCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _stateCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    if (_currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
      if (doc.exists) {
        _userData = doc.data();
        
        _nameCtrl.text = _userData?['name'] ?? _currentUser!.displayName ?? '';
        _mobileCtrl.text = _userData?['mobile'] ?? '';
        _examCtrl.text = _userData?['examNames'] ?? '';
        _yearCtrl.text = _userData?['year'] ?? '';
        _classCtrl.text = _userData?['class'] ?? '';
        _cityCtrl.text = _userData?['city'] ?? '';
        _stateCtrl.text = _userData?['state'] ?? '';
      }
    } catch (e) {
      debugPrint('Error fetching user: $e');
    }
    
    setState(() => _isLoading = false);
  }

  Future<void> _saveData() async {
    if (_currentUser == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).set({
        'name': _nameCtrl.text,
        'mobile': _mobileCtrl.text,
        'examNames': _examCtrl.text,
        'year': _yearCtrl.text,
        'class': _classCtrl.text,
        'city': _cityCtrl.text,
        'state': _stateCtrl.text,
        'email': _currentUser!.email, // Preserve email
        'lastLogin': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
      
      await _fetchUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving profile: $e')),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  void _showEditDialog(String title, List<Widget> fields) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          title: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: fields,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _saveData();
              },
              child: const Text('Save', style: TextStyle(color: AppTheme.primaryBlue)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 14),
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
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
                  AnimatedBackButton(onPressed: () => context.pop()),
                  const Expanded(
                    child: Center(
                      child: SectionTitle(title: 'Profile'),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: _currentUser?.photoURL != null
                            ? Image.network(
                                _currentUser!.photoURL!,
                                fit: BoxFit.cover,
                              )
                            : const Icon(CupertinoIcons.person_solid, size: 40, color: Colors.grey),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'User',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currentUser?.email ?? 'No email',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      // Your Details
                      _buildInfoCard(
                        title: 'Your details',
                        onEdit: () {
                          _showEditDialog('Edit Your details', [
                            _buildTextField('Name', _nameCtrl),
                            _buildTextField('Mobile', _mobileCtrl),
                          ]);
                        },
                        children: [
                          _buildInfoRow('Name', _nameCtrl.text),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('Email', _currentUser?.email ?? 'N/A'),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('Mobile', _mobileCtrl.text),
                        ],
                      ),
                      
                      const SizedBox(height: 16),

                      // Other Details
                      _buildInfoCard(
                        title: 'Other detail',
                        onEdit: () {
                          _showEditDialog('Edit Other detail', [
                            _buildTextField('Year or Appearance', _yearCtrl),
                            _buildTextField('Class', _classCtrl),
                            _buildTextField('City', _cityCtrl),
                            _buildTextField('State', _stateCtrl),
                          ]);
                        },
                        children: [
                          _buildInfoRow(
                            'Exams Names',
                            _examCtrl.text,
                            trailing: TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () async {
                                await context.push('/manage-exams');
                                _fetchUserData();
                              },
                              child: const Text('Manage', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('Year or appearance', _yearCtrl.text),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('Class', _classCtrl.text),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('City', _cityCtrl.text),
                          const Divider(height: 24, thickness: 0.5),
                          _buildInfoRow('State', _stateCtrl.text),
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
  }

  Widget _buildInfoCard({required String title, required VoidCallback onEdit, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerTheme.color ?? const Color(0xFFE5E7EB), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Theme.of(context).colorScheme.onSurface)),
              InkWell(
                onTap: onEdit,
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Text('Edit', style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Widget? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        if (trailing != null)
          trailing
        else
          Text(
            value.isNotEmpty ? value : '-',
            style: TextStyle(fontWeight: FontWeight.w500, color: Theme.of(context).colorScheme.onSurface),
          ),
      ],
    );
  }
}
