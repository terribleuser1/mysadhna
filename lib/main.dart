import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ============================================================================
// 1. DATA MODELS
// ============================================================================
class PreacherItem {
  final String id;
  final String codeSuffix;
  final String displayTitle;
  final bool isActive;

  const PreacherItem({
    required this.id,
    required this.codeSuffix,
    required this.displayTitle,
    this.isActive = true,
  });

  factory PreacherItem.fromMap(Map<String, dynamic> map) {
    return PreacherItem(
      id: map['id']?.toString() ?? '',
      codeSuffix: map['code_suffix']?.toString() ?? '',
      displayTitle: map['display_title']?.toString() ?? 'Preacher',
      isActive: map['is_active'] == true,
    );
  }
}

class AdminStats {
  final int devotees;
  final int preachers;
  final int entries;
  final List<DevoteeProfileItem> devoteesList;
  final List<PreacherItem> preachersList;

  const AdminStats({
    required this.devotees,
    required this.preachers,
    required this.entries,
    required this.devoteesList,
    required this.preachersList,
  });
}

class DevoteeProfileItem {
  final String id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String profession;
  final String education;
  final String address;
  final bool hideName;
  final String role;
  final String? preacherId;
  final String preacherTitle;

  const DevoteeProfileItem({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.profession,
    required this.education,
    required this.address,
    required this.hideName,
    required this.role,
    required this.preacherId,
    required this.preacherTitle,
  });
}

class PersonalStats {
  final double totalPoints;
  final double avgPoints;
  final int totalRounds;
  final int count;
  final bool hasLoggedToday;
  final DailyLogData? todayEntry;
  final List<DailyLogData> recent;

  const PersonalStats({
    required this.totalPoints,
    required this.avgPoints,
    required this.totalRounds,
    required this.count,
    required this.hasLoggedToday,
    required this.todayEntry,
    required this.recent,
  });
}

class DailyLogData {
  final String id;
  final String entryDate;
  final String wakeUpTime;
  final String bedTime;
  final int chantingRounds;
  final int spBookReadingMinutes;
  final int spLectureMinutes;
  final int otherHearingMinutes;
  final double calculatedScore;

  const DailyLogData({
    required this.id,
    required this.entryDate,
    required this.wakeUpTime,
    required this.bedTime,
    required this.chantingRounds,
    required this.spBookReadingMinutes,
    required this.spLectureMinutes,
    required this.otherHearingMinutes,
    required this.calculatedScore,
  });
}

class LeaderboardAggregatedRow {
  final String userId;
  final String name;
  final String preacherSuffix;
  final String? preacherId;
  final double totalScore;
  final double avgScore;
  final int totalRounds;
  final int entriesCount;

  LeaderboardAggregatedRow({
    required this.userId,
    required this.name,
    required this.preacherSuffix,
    required this.preacherId,
    required this.totalScore,
    required this.avgScore,
    required this.totalRounds,
    required this.entriesCount,
  });
}

// ============================================================================
// 2. ENTRY POINT & THEME
// ============================================================================
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mtduhncyvcmzgekekieq.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10ZHVobmN5dmNtemdla2VraWVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyODA5OTcsImV4cCI6MjEwODg1Njk5N30.QFJvYZDEyPqeQkWJyBV1r8djjkkXXoY3LGuuz4EpdxU',
  );

  runApp(const MySadhnaApp());
}

final supabase = Supabase.instance.client;

class AppColors {
  static const Color saffronPrimary = Color(0xFFFF9933);
  static const Color saffronDark = Color(0xFFCC5500);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color creamBg = Color(0xFFFCF9F2);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF2C2523);
  static const Color textMuted = Color(0xFF7A6E65);
  static const Color sacredRed = Color(0xFFB71C1C);
  static const Color borderSubtle = Color(0xFFE8DFD8);
}

class MySadhnaApp extends StatelessWidget {
  const MySadhnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Sadhna',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.creamBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.saffronPrimary,
          primary: AppColors.saffronPrimary,
          secondary: AppColors.saffronDark,
          surface: AppColors.cardBg,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.creamBg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.outfit(
            color: AppColors.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: const IconThemeData(color: AppColors.textDark),
        ),
      ),
      home: const AuthGate(),
    );
  }
}

// ============================================================================
// 3. LOGO & BRANDING
// ============================================================================
class MSMonogramLogo extends StatelessWidget {
  final double size;
  const MSMonogramLogo({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [AppColors.saffronPrimary, AppColors.saffronDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffronPrimary.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'MS',
          style: GoogleFonts.cinzel(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.42,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 4. AUTH GATE
// ============================================================================
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    supabase.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        _showUpdatePasswordDialog();
      }
    });
  }

  void _showUpdatePasswordDialog() {
    final newPasswordController = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Set New Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your new password below (at least 6 characters):',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline, color: AppColors.saffronDark),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newPass = newPasswordController.text.trim();
                if (newPass.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      backgroundColor: AppColors.sacredRed,
                      content: Text('Password must be at least 6 characters long.'),
                    ),
                  );
                  return;
                }
                try {
                  await supabase.auth.updateUser(
                    UserAttributes(password: newPass),
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Password updated successfully!'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.sacredRed,
                        content: Text(e.toString()),
                      ),
                    );
                  }
                }
              },
              child: const Text('Save New Password'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = supabase.auth.currentSession;
        if (session != null) {
          return const MainNavigationScaffold();
        }
        return const OnboardingScreen();
      },
    );
  }
}

// ============================================================================
// 5. ONBOARDING & REGISTRATION (With Enter-to-Next & OTP Verification)
// ============================================================================
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKeyStep0 = GlobalKey<FormState>();
  final _formKeyStep1 = GlobalKey<FormState>();

  int _currentStep = 0;
  bool _isLoginMode = false;
  bool _isLoading = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _educationController = TextEditingController();
  final _addressController = TextEditingController();

  final int _age = 25;
  final String _gender = 'male';
  String? _selectedPreacherId;
  List<PreacherItem> _preachersList = [];

  @override
  void initState() {
    super.initState();
    _fetchPreachers();
  }

  Future<void> _fetchPreachers() async {
    try {
      final response = await supabase
          .from('preachers')
          .select('id, code_suffix, display_title, is_active')
          .eq('is_active', true);

      final List<dynamic> raw = response as List<dynamic>;
      setState(() {
        _preachersList = raw.map((e) => PreacherItem.fromMap(e as Map<String, dynamic>)).toList();
        if (_preachersList.isNotEmpty) {
          _selectedPreacherId = _preachersList.first.id;
        }
      });
    } catch (_) {}
  }

  void _showForgotPasswordDialog() {
    final resetEmailCtrl = TextEditingController(text: _emailController.text.trim());
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter your registered email address. A password recovery link will be sent to your inbox.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resetEmailCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.saffronDark),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final email = resetEmailCtrl.text.trim();
                if (email.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await supabase.auth.resetPasswordForEmail(email);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text('Password reset link sent! Check your email.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.sacredRed,
                        content: Text(e.toString()),
                      ),
                    );
                  }
                }
              },
              child: const Text('Send Reset Link'),
            ),
          ],
        );
      },
    );
  }

  void _showOtpVerificationDialog(String email, String password) {
    final otpController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setOtpState) {
            return AlertDialog(
              title: const Text('Verify Email OTP'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'We sent a 6-digit verification code to $email. Please enter it below to complete registration.',
                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: '6-Digit OTP',
                      prefixIcon: Icon(Icons.security, color: AppColors.saffronDark),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronDark,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isVerifying
                      ? null
                      : () async {
                          final token = otpController.text.trim();
                          if (token.length < 6) return;
                          setOtpState(() => isVerifying = true);
                          try {
                            final res = await supabase.auth.verifyOTP(
                              email: email,
                              token: token,
                              type: OtpType.signup,
                            );

                            final userId = res.user?.id ?? supabase.auth.currentUser?.id;
                            if (userId != null) {
                              await supabase.from('profiles').upsert({
                                'id': userId,
                                'role': 'counselee',
                                'preacher_id': _selectedPreacherId,
                                'full_name': _nameController.text.trim(),
                                'email': email,
                                'phone_number': _phoneController.text.trim(),
                                'gender': _gender,
                                'age': _age,
                                'profession': _professionController.text.trim(),
                                'education': _educationController.text.trim(),
                                'address': _addressController.text.trim(),
                                'hide_name_on_leaderboard': false,
                                'is_approved': true,
                              });
                            }
                            if (ctx.mounted) Navigator.pop(ctx);
                          } catch (e) {
                            setOtpState(() => isVerifying = false);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: AppColors.sacredRed,
                                  content: Text('Verification failed: ${e.toString()}'),
                                ),
                              );
                            }
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify & Complete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String? _validateRequired(String? val, String fieldName) {
    if (val == null || val.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val.trim())) return 'Enter a valid email';
    return null;
  }

  String? _validatePhone(String? val) {
    if (val == null || val.trim().isEmpty) return 'Phone number is required';
    if (val.replaceAll(RegExp(r'[^0-9]'), '').length < 10) return 'Enter at least 10 digits';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.trim().isEmpty) return 'Password is required';
    if (val.trim().length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    try {
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        if (_selectedPreacherId == null) throw Exception('Please select an assigned Preacher.');

        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final authRes = await supabase.auth.signUp(
          email: email,
          password: password,
        );

        if (authRes.session == null) {
          // Email confirmation is required by Supabase: trigger OTP prompt
          _showOtpVerificationDialog(email, password);
        } else {
          // If auto-confirm is enabled in Supabase, create profile row directly
          final userId = authRes.user?.id;
          if (userId != null) {
            await supabase.from('profiles').insert({
              'id': userId,
              'role': 'counselee',
              'preacher_id': _selectedPreacherId,
              'full_name': _nameController.text.trim(),
              'email': email,
              'phone_number': _phoneController.text.trim(),
              'gender': _gender,
              'age': _age,
              'profession': _professionController.text.trim(),
              'education': _educationController.text.trim(),
              'address': _addressController.text.trim(),
              'hide_name_on_leaderboard': false,
              'is_approved': true,
            });
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 700;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 480 : size.width),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const MSMonogramLogo(size: 64).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text('My Sadhna', style: GoogleFonts.cinzel(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text('In Service of ISKCON', style: GoogleFonts.outfit(fontSize: 13, color: AppColors.saffronDark, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(color: AppColors.creamBg, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: !_isLoginMode ? AppColors.saffronPrimary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text('Register', style: TextStyle(fontWeight: FontWeight.bold, color: !_isLoginMode ? Colors.white : AppColors.textMuted)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _isLoginMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(color: _isLoginMode ? AppColors.saffronPrimary : Colors.transparent, borderRadius: BorderRadius.circular(12)),
                            alignment: Alignment.center,
                            child: Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold, color: _isLoginMode ? Colors.white : AppColors.textMuted)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoginMode) ...[
                  _buildInput(
                    controller: _emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    validator: _validateEmail,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  _buildInput(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    validator: _validatePassword,
                    obscure: true,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleAuth(),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _showForgotPasswordDialog,
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(color: AppColors.saffronDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ] else ...[
                  if (_currentStep == 0)
                    Form(
                      key: _formKeyStep0,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildInput(
                            controller: _nameController,
                            label: 'Full / Initiated Name',
                            icon: Icons.person_outline,
                            validator: (v) => _validateRequired(v, 'Name'),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _phoneController,
                            label: 'Phone / WhatsApp',
                            icon: Icons.phone_outlined,
                            validator: _validatePhone,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            validator: _validateEmail,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _passwordController,
                            label: 'Create Password (6+ chars)',
                            icon: Icons.lock_outline,
                            validator: _validatePassword,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (_formKeyStep0.currentState?.validate() ?? false) {
                                setState(() => _currentStep++);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  else if (_currentStep == 1)
                    Form(
                      key: _formKeyStep1,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        children: [
                          _buildInput(
                            controller: _professionController,
                            label: 'Profession',
                            icon: Icons.work_outline,
                            validator: (v) => _validateRequired(v, 'Profession'),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _educationController,
                            label: 'Qualification',
                            icon: Icons.school,
                            validator: (v) => _validateRequired(v, 'Education'),
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: 14),
                          _buildInput(
                            controller: _addressController,
                            label: 'Address / City',
                            icon: Icons.location_on_outlined,
                            validator: (v) => _validateRequired(v, 'Address'),
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (_formKeyStep1.currentState?.validate() ?? false) {
                                setState(() => _currentStep++);
                              }
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPreacherId,
                      decoration: InputDecoration(
                        labelText: 'Assigned Preacher',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.temple_hindu_outlined, color: AppColors.saffronDark),
                      ),
                      items: _preachersList.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))).toList(),
                      onChanged: (val) => setState(() => _selectedPreacherId = val),
                    ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.saffronPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isLoading
                        ? null
                        : () {
                            if (_isLoginMode) {
                              _handleAuth();
                            } else {
                              if (_currentStep == 0 && (_formKeyStep0.currentState?.validate() ?? false)) {
                                setState(() => _currentStep++);
                              } else if (_currentStep == 1 && (_formKeyStep1.currentState?.validate() ?? false)) {
                                setState(() => _currentStep++);
                              } else if (_currentStep == 2) {
                                _handleAuth();
                              }
                            }
                          },
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isLoginMode
                                ? 'Sign In'
                                : (_currentStep < 2 ? 'Next Step' : 'Complete Registration'),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                if (!_isLoginMode && _currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: const Text('Back to previous step', style: TextStyle(color: AppColors.textMuted)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String? Function(String?) validator,
    bool obscure = false,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.saffronDark),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ============================================================================
// 6. MAIN NAVIGATION SCAFFOLD (Role-Aware: Super Admin, Preacher, Counselee)
// ============================================================================
class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  String _userRole = 'counselee';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await supabase.from('profiles').select('role').eq('id', user.id).single();
        setState(() {
          _userRole = profile['role']?.toString() ?? 'counselee';
          _isLoading = false;
        });
        return;
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final bool isSuperAdmin = _userRole == 'super_admin';
    final bool isPreacher = _userRole == 'preacher';

    List<Widget> screens;
    List<NavigationDestination> destinations;

    if (isSuperAdmin) {
      screens = const [
        SuperAdminConsoleScreen(),
        LeaderboardScreen(),
        ProfileDashboardScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.saffronDark), label: 'Admin Console'),
        NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    } else if (isPreacher) {
      screens = const [
        PreacherConsoleScreen(),
        LeaderboardScreen(),
        ProfileDashboardScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.temple_hindu_outlined), selectedIcon: Icon(Icons.temple_hindu, color: AppColors.saffronDark), label: 'Counselees'),
        NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    } else {
      screens = const [
        DevoteeSelfDashboardScreen(),
        LeaderboardScreen(),
        ProfileDashboardScreen(),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.saffronDark), label: 'Home Dashboard'),
        NavigationDestination(icon: Icon(Icons.leaderboard_outlined), selectedIcon: Icon(Icons.leaderboard, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    }

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.saffronPrimary.withValues(alpha: 0.2),
        destinations: destinations,
      ),
    );
  }
}

// ============================================================================
// 7. DEVOTEE SELF DASHBOARD
// ============================================================================
class DevoteeSelfDashboardScreen extends StatefulWidget {
  const DevoteeSelfDashboardScreen({super.key});

  @override
  State<DevoteeSelfDashboardScreen> createState() => _DevoteeSelfDashboardScreenState();
}

class _DevoteeSelfDashboardScreenState extends State<DevoteeSelfDashboardScreen> {
  late Future<PersonalStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  void _refreshStats() {
    final user = supabase.auth.currentUser;
    setState(() {
      _statsFuture = _fetchPersonalStats(user?.id);
    });
  }

  Future<PersonalStats> _fetchPersonalStats(String? userId) async {
    if (userId == null) {
      return const PersonalStats(totalPoints: 0, avgPoints: 0, totalRounds: 0, count: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
    try {
      final res = await supabase
          .from('sadhana_entries')
          .select('id, entry_date, wake_up_time, bed_time, chanting_rounds, sp_book_reading_minutes, sp_lecture_hearing_minutes, other_hearing_minutes, calculated_score')
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .limit(30);

      final List<dynamic> raw = res as List<dynamic>;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      double total = 0;
      int rounds = 0;
      DailyLogData? todayRecord;
      final List<DailyLogData> entries = [];

      for (final r in raw) {
        final data = DailyLogData(
          id: r['id']?.toString() ?? '',
          entryDate: r['entry_date']?.toString() ?? '',
          wakeUpTime: r['wake_up_time']?.toString() ?? '04:00:00',
          bedTime: r['bed_time']?.toString() ?? '21:45:00',
          chantingRounds: (r['chanting_rounds'] as num?)?.toInt() ?? 0,
          spBookReadingMinutes: (r['sp_book_reading_minutes'] as num?)?.toInt() ?? 0,
          spLectureMinutes: (r['sp_lecture_hearing_minutes'] as num?)?.toInt() ?? 0,
          otherHearingMinutes: (r['other_hearing_minutes'] as num?)?.toInt() ?? 0,
          calculatedScore: (r['calculated_score'] as num?)?.toDouble() ?? 0.0,
        );

        entries.add(data);
        total += data.calculatedScore;
        rounds += data.chantingRounds;

        if (data.entryDate == todayStr) {
          todayRecord = data;
        }
      }

      return PersonalStats(
        totalPoints: total,
        avgPoints: entries.isEmpty ? 0 : total / entries.length,
        totalRounds: rounds,
        count: entries.length,
        hasLoggedToday: todayRecord != null,
        todayEntry: todayRecord,
        recent: entries,
      );
    } catch (_) {
      return const PersonalStats(totalPoints: 0, avgPoints: 0, totalRounds: 0, count: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sadhana Journey'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats),
        ],
      ),
      body: FutureBuilder<PersonalStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? const PersonalStats(totalPoints: 0, avgPoints: 0, totalRounds: 0, count: 0, hasLoggedToday: false, todayEntry: null, recent: []);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.saffronPrimary, AppColors.saffronDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(color: AppColors.saffronPrimary.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CUMULATIVE SADHANA SCORE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('${stats.totalPoints.toStringAsFixed(1)} pts',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Avg: ${stats.avgPoints.toStringAsFixed(1)} pts / day  •  ${stats.count} Days Tracked', style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                    const MSMonogramLogo(size: 52),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: stats.hasLoggedToday ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                  border: Border.all(color: stats.hasLoggedToday ? Colors.green.shade300 : AppColors.saffronPrimary.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: stats.hasLoggedToday ? Colors.green : AppColors.saffronPrimary,
                      foregroundColor: Colors.white,
                      child: Icon(stats.hasLoggedToday ? Icons.check : Icons.edit_calendar),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stats.hasLoggedToday ? "Today's Sadhana Offered" : "Today's Sadhana Pending",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            stats.hasLoggedToday
                                ? 'Score: ${stats.todayEntry?.calculatedScore.toStringAsFixed(1)} pts • Tap to modify'
                                : 'Log before 24h window expires',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: stats.hasLoggedToday ? Colors.green.shade700 : AppColors.saffronDark,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DailySadhanaEntryScreen(existingRecord: stats.todayEntry),
                          ),
                        );
                        if (result == true) _refreshStats();
                      },
                      child: Text(stats.hasLoggedToday ? 'Edit Log' : 'Report Now'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Japa Rounds', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${stats.totalRounds}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Streak & Logs', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                            const SizedBox(height: 6),
                            Text('${stats.count} Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Recent Sadhana History', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 12),
              if (stats.recent.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No daily entries recorded yet. Tap "Report Now" above to begin.')),
                  ),
                )
              else
                ...stats.recent.map((e) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.creamBg,
                        child: Icon(Icons.check_circle, color: Colors.green),
                      ),
                      title: Text('Date: ${e.entryDate}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Rounds: ${e.chantingRounds} • Reading: ${e.spBookReadingMinutes}m • Hearing: ${e.spLectureMinutes}m'),
                      trailing: Text(
                        '${e.calculatedScore.toStringAsFixed(1)} pts',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark, fontSize: 15),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 8. DAILY SADHANA FORM
// ============================================================================
class DailySadhanaEntryScreen extends StatefulWidget {
  final DailyLogData? existingRecord;
  const DailySadhanaEntryScreen({super.key, this.existingRecord});

  @override
  State<DailySadhanaEntryScreen> createState() => _DailySadhanaEntryScreenState();
}

class _DailySadhanaEntryScreenState extends State<DailySadhanaEntryScreen> {
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 4, minute: 0);
  TimeOfDay _bedTime = const TimeOfDay(hour: 21, minute: 45);

  int _rounds = 16;
  int _spReadingMinutes = 45;
  int _spLectureMinutes = 30;
  int _otherHearingMinutes = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingRecord != null) {
      final rec = widget.existingRecord!;
      _selectedDate = DateTime.tryParse(rec.entryDate) ?? DateTime.now();
      _rounds = rec.chantingRounds;
      _spReadingMinutes = rec.spBookReadingMinutes;
      _spLectureMinutes = rec.spLectureMinutes;
      _otherHearingMinutes = rec.otherHearingMinutes;

      final wakeParts = rec.wakeUpTime.split(':');
      if (wakeParts.length >= 2) {
        _wakeUpTime = TimeOfDay(hour: int.tryParse(wakeParts[0]) ?? 4, minute: int.tryParse(wakeParts[1]) ?? 0);
      }
      final bedParts = rec.bedTime.split(':');
      if (bedParts.length >= 2) {
        _bedTime = TimeOfDay(hour: int.tryParse(bedParts[0]) ?? 21, minute: int.tryParse(bedParts[1]) ?? 45);
      }
    }
  }

  double _calculateLiveScore() {
    double wakeScore = 0;
    final wakeMins = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    if (wakeMins <= 4 * 60) {
      wakeScore = 25;
    } else if (wakeMins <= 4 * 60 + 30) {
      wakeScore = 20;
    } else if (wakeMins <= 5 * 60) {
      wakeScore = 15;
    } else if (wakeMins <= 5 * 60 + 30) {
      wakeScore = 10;
    } else if (wakeMins <= 6 * 60) {
      wakeScore = 5;
    }

    final baseJapa = min(35.0, _rounds * (35.0 / 16.0));
    final bonusJapa = _rounds > 16 ? min(10.0, (_rounds - 16) * 1.25) : 0.0;
    final readingScore = min(20.0, (_spReadingMinutes / 45.0) * 20.0);
    final hearingScore = min(10.0, ((_spLectureMinutes + (_otherHearingMinutes * 0.5)) / 45.0) * 10.0);

    double bedScore = 0;
    final bedMins = _bedTime.hour * 60 + _bedTime.minute;
    if (bedMins <= 22 * 60 && bedMins >= 18 * 60) {
      bedScore = 10;
    } else if (bedMins <= 22 * 60 + 30 && bedMins >= 18 * 60) {
      bedScore = 7;
    } else if (bedMins <= 23 * 60 && bedMins >= 18 * 60) {
      bedScore = 4;
    }

    return wakeScore + baseJapa + bonusJapa + readingScore + hearingScore + bedScore;
  }

  Future<void> _submitDailySadhana() async {
    setState(() => _isSaving = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final score = _calculateLiveScore();
    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      await supabase.from('sadhana_entries').upsert({
        'user_id': user.id,
        'entry_date': dateString,
        'wake_up_time': '${_wakeUpTime.hour.toString().padLeft(2, '0')}:${_wakeUpTime.minute.toString().padLeft(2, '0')}:00',
        'bed_time': '${_bedTime.hour.toString().padLeft(2, '0')}:${_bedTime.minute.toString().padLeft(2, '0')}:00',
        'chanting_rounds': _rounds,
        'sp_book_reading_minutes': _spReadingMinutes,
        'sp_lecture_hearing_minutes': _spLectureMinutes,
        'other_hearing_minutes': _otherHearingMinutes,
        'calculated_score': score,
        'last_modified_timestamp': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, entry_date');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Hari Bol! Sadhana offering recorded successfully.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final liveScore = _calculateLiveScore();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingRecord != null ? 'Edit Sadhana Record' : 'Record Daily Sadhana'),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.saffronPrimary, AppColors.saffronDark]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('OFFERING SCORE PREVIEW', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.2)),
                        Text('${liveScore.toStringAsFixed(1)} pts',
                            style: GoogleFonts.outfit(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const MSMonogramLogo(size: 46),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  title: const Text('Logging For Date', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
                  trailing: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Today')),
                      ButtonSegment(value: 1, label: Text('Yesterday')),
                    ],
                    selected: {DateTime.now().day == _selectedDate.day ? 0 : 1},
                    onSelectionChanged: (val) {
                      setState(() {
                        _selectedDate = DateTime.now().subtract(Duration(days: val.first));
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _timePickerCard(
                      label: 'Wake-up Time',
                      time: _wakeUpTime,
                      icon: Icons.wb_sunny_outlined,
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _wakeUpTime);
                        if (picked != null) setState(() => _wakeUpTime = picked);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _timePickerCard(
                      label: 'Bedtime',
                      time: _bedTime,
                      icon: Icons.bedtime_outlined,
                      onTap: () async {
                        final picked = await showTimePicker(context: context, initialTime: _bedTime);
                        if (picked != null) setState(() => _bedTime = picked);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _stepperCard(
                label: 'Japa Meditation Rounds',
                subtitle: 'Target: 16+ rounds (Bonus points above 16)',
                value: _rounds,
                step: 1,
                min: 0,
                max: 64,
                onChanged: (v) => setState(() => _rounds = v),
              ),
              const SizedBox(height: 12),
              _stepperCard(
                label: 'SP Book Reading',
                subtitle: 'Target: 45+ minutes',
                unit: 'mins',
                value: _spReadingMinutes,
                step: 15,
                min: 0,
                max: 240,
                onChanged: (v) => setState(() => _spReadingMinutes = v),
              ),
              const SizedBox(height: 12),
              _stepperCard(
                label: 'SP Lecture Hearing',
                subtitle: 'Target: 45+ minutes',
                unit: 'mins',
                value: _spLectureMinutes,
                step: 15,
                min: 0,
                max: 240,
                onChanged: (v) => setState(() => _spLectureMinutes = v),
              ),
              const SizedBox(height: 12),
              _stepperCard(
                label: 'Other Spiritual Hearing',
                subtitle: 'Half-weighted marks toward hearing target',
                unit: 'mins',
                value: _otherHearingMinutes,
                step: 15,
                min: 0,
                max: 240,
                onChanged: (v) => setState(() => _otherHearingMinutes = v),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronDark,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _submitDailySadhana,
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          widget.existingRecord != null ? 'Update Offering' : 'Submit Daily Offering',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timePickerCard({
    required String label,
    required TimeOfDay time,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final formatStr = '${time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.saffronDark, size: 20),
                  const SizedBox(width: 8),
                  Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(formatStr, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              const Text('Tap to change', style: TextStyle(color: AppColors.saffronDark, fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepperCard({
    required String label,
    required String subtitle,
    required int value,
    required int step,
    required int min,
    required int max,
    String? unit,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.saffronDark),
                  onPressed: value > min ? () => onChanged(value - step < min ? min : value - step) : null,
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 50),
                  alignment: Alignment.center,
                  child: Text(
                    unit != null ? '$value $unit' : '$value',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.saffronDark),
                  onPressed: value < max ? () => onChanged(value + step > max ? max : value + step) : null,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 9. SUPER ADMIN CONSOLE (With Devotee & Preacher Management)
// ============================================================================
class SuperAdminConsoleScreen extends StatefulWidget {
  const SuperAdminConsoleScreen({super.key});

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen> {
  late Future<AdminStats> _adminFuture;
  int _selectedDirectoryTab = 0; // 0: Devotees, 1: Preachers

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _adminFuture = _fetchStats();
    });
  }

  Future<AdminStats> _fetchStats() async {
    try {
      final devoteesCount = await supabase.from('profiles').count(CountOption.exact);
      final preachersCount = await supabase.from('preachers').count(CountOption.exact);
      final entriesCount = await supabase.from('sadhana_entries').count(CountOption.exact);

      final pRes = await supabase.from('preachers').select('id, code_suffix, display_title, is_active').order('created_at', ascending: false);
      final pList = (pRes as List<dynamic>).map((e) => PreacherItem.fromMap(e as Map<String, dynamic>)).toList();

      final dRes = await supabase
          .from('profiles')
          .select('id, full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, role, preacher_id, preachers(display_title)')
          .order('created_at', ascending: false);

      final dList = (dRes as List<dynamic>).map((e) {
        final map = e as Map<String, dynamic>;
        final pr = map['preachers'] as Map<String, dynamic>?;
        return DevoteeProfileItem(
          id: map['id']?.toString() ?? '',
          fullName: map['full_name']?.toString() ?? 'Devotee',
          email: map['email']?.toString() ?? '',
          phoneNumber: map['phone_number']?.toString() ?? '',
          profession: map['profession']?.toString() ?? '',
          education: map['education']?.toString() ?? '',
          address: map['address']?.toString() ?? '',
          hideName: map['hide_name_on_leaderboard'] == true,
          role: map['role']?.toString() ?? 'counselee',
          preacherId: map['preacher_id']?.toString(),
          preacherTitle: pr?['display_title']?.toString() ?? 'None',
        );
      }).toList();

      return AdminStats(
        devotees: devoteesCount,
        preachers: preachersCount,
        entries: entriesCount,
        devoteesList: dList,
        preachersList: pList,
      );
    } catch (_) {
      return const AdminStats(devotees: 0, preachers: 0, entries: 0, devoteesList: [], preachersList: []);
    }
  }

  void _showAddPreacherDialog() {
    final titleCtrl = TextEditingController();
    final suffixCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add New Counsellor / Preacher'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Display Title (e.g. HG Radheshyam Das)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: suffixCtrl,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(labelText: 'Code Suffix (e.g. RSD)', border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final suffix = suffixCtrl.text.trim();
                if (title.isEmpty || suffix.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await supabase.from('preachers').insert({
                    'display_title': title,
                    'code_suffix': suffix,
                    'is_active': true,
                  });
                  _refresh();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Add Preacher'),
            ),
          ],
        );
      },
    );
  }

  void _showEditPreacherDialog(PreacherItem preacher) {
    final titleCtrl = TextEditingController(text: preacher.displayTitle);
    final suffixCtrl = TextEditingController(text: preacher.codeSuffix);
    bool isActive = preacher.isActive;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Edit Preacher: ${preacher.codeSuffix}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Display Title', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: suffixCtrl,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(labelText: 'Code Suffix', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active Status'),
                    subtitle: const Text('Inactive preachers are hidden from registration dropdowns'),
                    value: isActive,
                    onChanged: (val) => setDialogState(() => isActive = val),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    style: TextButton.styleFrom(foregroundColor: AppColors.sacredRed),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Preacher Record'),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Confirm Deletion'),
                          content: Text('Delete ${preacher.displayTitle}? If counselees are assigned to this preacher, unassign them first.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.sacredRed, foregroundColor: Colors.white),
                              onPressed: () => Navigator.pop(c, true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirm == true) {
                        Navigator.pop(ctx);
                        try {
                          await supabase.from('preachers').delete().eq('id', preacher.id);
                          _refresh();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())));
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    await supabase.from('preachers').update({
                      'display_title': titleCtrl.text.trim(),
                      'code_suffix': suffixCtrl.text.trim(),
                      'is_active': isActive,
                    }).eq('id', preacher.id);
                    _refresh();
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showAddDevoteeDialog(List<PreacherItem> preachers) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final eduCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String? selectedPreacherId = preachers.isNotEmpty ? preachers.first.id : null;
    String selectedRole = 'counselee';

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Devotee'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: emailCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: passwordCtrl, textInputAction: TextInputAction.next, obscureText: true, decoration: const InputDecoration(labelText: 'Initial Password (6+ chars)', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: phoneCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: profCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: eduCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Educational Qualification', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      TextField(controller: addrCtrl, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Residential Address', border: OutlineInputBorder())),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'counselee', child: Text('Counselee / Devotee')),
                          DropdownMenuItem(value: 'preacher', child: Text('Preacher / Counsellor')),
                          DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedRole = v ?? selectedRole),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPreacherId,
                        decoration: const InputDecoration(labelText: 'Assign Preacher Group', border: OutlineInputBorder()),
                        items: preachers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))).toList(),
                        onChanged: (v) => setDialogState(() => selectedPreacherId = v),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                  onPressed: () async {
                    final email = emailCtrl.text.trim();
                    final password = passwordCtrl.text.trim();
                    if (email.isEmpty || password.length < 6) return;
                    Navigator.pop(ctx);
                    try {
                      final authRes = await supabase.auth.signUp(email: email, password: password);
                      final uid = authRes.user?.id;
                      if (uid != null) {
                        await supabase.from('profiles').upsert({
                          'id': uid,
                          'full_name': nameCtrl.text.trim(),
                          'email': email,
                          'phone_number': phoneCtrl.text.trim(),
                          'profession': profCtrl.text.trim(),
                          'education': eduCtrl.text.trim(),
                          'address': addrCtrl.text.trim(),
                          'role': selectedRole,
                          'preacher_id': selectedPreacherId,
                          'hide_name_on_leaderboard': false,
                          'is_approved': true,
                        });
                        _refresh();
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())));
                      }
                    }
                  },
                  child: const Text('Create Devotee'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDevoteeDialog(DevoteeProfileItem devotee, List<PreacherItem> preachers) {
    String selectedRole = devotee.role;
    String? selectedPreacherId = devotee.preacherId;
    bool hideName = devotee.hideName;

    final nameCtrl = TextEditingController(text: devotee.fullName);
    final emailCtrl = TextEditingController(text: devotee.email);
    final phoneCtrl = TextEditingController(text: devotee.phoneNumber);
    final profCtrl = TextEditingController(text: devotee.profession);
    final eduCtrl = TextEditingController(text: devotee.education);
    final addrCtrl = TextEditingController(text: devotee.address);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Admin Edit: ${devotee.fullName}'),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: emailCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Login Email Address', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: profCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Profession / Occupation', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: eduCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(labelText: 'Educational Qualification', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: addrCtrl,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(labelText: 'Residential Address', border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedRole,
                        decoration: const InputDecoration(labelText: 'System Role', border: OutlineInputBorder()),
                        items: const [
                          DropdownMenuItem(value: 'counselee', child: Text('Counselee / Devotee')),
                          DropdownMenuItem(value: 'preacher', child: Text('Preacher / Counsellor')),
                          DropdownMenuItem(value: 'super_admin', child: Text('Super Admin')),
                        ],
                        onChanged: (v) => setDialogState(() => selectedRole = v ?? selectedRole),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: selectedPreacherId,
                        decoration: const InputDecoration(labelText: 'Assign Preacher Group', border: OutlineInputBorder()),
                        items: preachers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))).toList(),
                        onChanged: (v) => setDialogState(() => selectedPreacherId = v),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Hide Name on Leaderboards'),
                        subtitle: const Text('Mask devotee identity as Anonymous'),
                        value: hideName,
                        onChanged: (val) => setDialogState(() => hideName = val),
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.sacredRed),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Delete Devotee Permanently'),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Confirm Deletion'),
                              content: Text('Are you sure you want to delete ${devotee.fullName}? All their sadhana logs will be permanently removed.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.sacredRed, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(c, true),
                                  child: const Text('Delete Permanently'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            Navigator.pop(ctx);
                            try {
                              await supabase.from('profiles').delete().eq('id', devotee.id);
                              _refresh();
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(backgroundColor: AppColors.sacredRed, content: Text('Delete failed: ${e.toString()}')),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final newEmail = emailCtrl.text.trim();

                    // If email has changed, call database RPC to update auth.users
                    if (newEmail.isNotEmpty && newEmail != devotee.email) {
                      try {
                        await supabase.rpc('admin_update_user_email', params: {
                          'target_user_id': devotee.id,
                          'new_email': newEmail,
                        });
                      } catch (_) {}
                    }

                    await supabase.from('profiles').update({
                      'full_name': nameCtrl.text.trim(),
                      'email': newEmail,
                      'phone_number': phoneCtrl.text.trim(),
                      'profession': profCtrl.text.trim(),
                      'education': eduCtrl.text.trim(),
                      'address': addrCtrl.text.trim(),
                      'role': selectedRole,
                      'preacher_id': selectedPreacherId,
                      'hide_name_on_leaderboard': hideName,
                    }).eq('id', devotee.id);

                    _refresh();
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
      ),
      body: FutureBuilder<AdminStats>(
        future: _adminFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? const AdminStats(devotees: 0, preachers: 0, entries: 0, devoteesList: [], preachersList: []);

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [AppColors.textDark, Color(0xFF4A403A)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ADMINISTRATION CONTROLS', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
                    const SizedBox(height: 6),
                    Text('Global Platform Oversight', style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    const Text('Manage devotees, preachers, login credentials, and assigned spiritual circles.',
                        style: TextStyle(color: Colors.white60, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  _statCard('Devotees', '${stats.devotees}', Icons.groups),
                  const SizedBox(width: 12),
                  _statCard('Preachers', '${stats.preachers}', Icons.temple_hindu),
                  const SizedBox(width: 12),
                  _statCard('Sadhana Logs', '${stats.entries}', Icons.history_edu),
                ],
              ),
              const SizedBox(height: 24),

              // Directory Switcher & Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Devotees')),
                      ButtonSegment(value: 1, label: Text('Preachers / Counsellors')),
                    ],
                    selected: {_selectedDirectoryTab},
                    onSelectionChanged: (val) => setState(() => _selectedDirectoryTab = val.first),
                  ),
                  if (_selectedDirectoryTab == 0)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Devotee'),
                      onPressed: () => _showAddDevoteeDialog(stats.preachersList),
                    )
                  else
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Preacher'),
                      onPressed: _showAddPreacherDialog,
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (_selectedDirectoryTab == 0) ...[
                if (stats.devoteesList.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No devotees found.')))
                else
                  ...stats.devoteesList.map((d) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: d.role == 'super_admin' ? AppColors.sacredRed : (d.role == 'preacher' ? Colors.deepPurple : AppColors.saffronPrimary),
                          foregroundColor: Colors.white,
                          child: Text(d.fullName.isNotEmpty ? d.fullName[0].toUpperCase() : 'D'),
                        ),
                        title: Text(d.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: ${d.email}\nRole: ${d.role} • Preacher: ${d.preacherTitle}'),
                        isThreeLine: true,
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_note, color: AppColors.saffronDark),
                          onPressed: () => _showEditDevoteeDialog(d, stats.preachersList),
                        ),
                      ),
                    );
                  }),
              ] else ...[
                if (stats.preachersList.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No preachers found. Tap "Add Preacher" above.')))
                else
                  ...stats.preachersList.map((p) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: p.isActive ? Colors.green : Colors.grey,
                          foregroundColor: Colors.white,
                          child: const Icon(Icons.temple_hindu, size: 20),
                        ),
                        title: Text(p.displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Suffix: ${p.codeSuffix} • Status: ${p.isActive ? "Active" : "Inactive"}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.saffronDark),
                          onPressed: () => _showEditPreacherDialog(p),
                        ),
                      ),
                    );
                  }),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.saffronDark, size: 24),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 10. PREACHER CONSOLE (Preacher Login View With Assigned Counselees)
// ============================================================================
class PreacherConsoleScreen extends StatefulWidget {
  const PreacherConsoleScreen({super.key});

  @override
  State<PreacherConsoleScreen> createState() => _PreacherConsoleScreenState();
}

class _PreacherConsoleScreenState extends State<PreacherConsoleScreen> {
  List<DevoteeProfileItem> _counselees = [];
  bool _isLoading = true;
  String? _preacherId;

  @override
  void initState() {
    super.initState();
    _fetchCounselees();
  }

  Future<void> _fetchCounselees() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final pr = await supabase.from('profiles').select('preacher_id').eq('id', user.id).single();
      _preacherId = pr['preacher_id']?.toString();

      if (_preacherId != null) {
        final res = await supabase
            .from('profiles')
            .select('id, full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, role, preacher_id')
            .eq('preacher_id', _preacherId!)
            .order('full_name', ascending: true);

        final list = (res as List<dynamic>).map((e) {
          final m = e as Map<String, dynamic>;
          return DevoteeProfileItem(
            id: m['id']?.toString() ?? '',
            fullName: m['full_name']?.toString() ?? 'Devotee',
            email: m['email']?.toString() ?? '',
            phoneNumber: m['phone_number']?.toString() ?? '',
            profession: m['profession']?.toString() ?? '',
            education: m['education']?.toString() ?? '',
            address: m['address']?.toString() ?? '',
            hideName: m['hide_name_on_leaderboard'] == true,
            role: m['role']?.toString() ?? 'counselee',
            preacherId: m['preacher_id']?.toString(),
            preacherTitle: 'My Group',
          );
        }).toList();

        setState(() {
          _counselees = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCounseleeDialog() {
    if (_preacherId == null) return;

    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Add Counselee to My Circle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, textInputAction: TextInputAction.next, obscureText: true, decoration: const InputDecoration(labelText: 'Initial Password (6+ chars)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'WhatsApp Phone Number', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () async {
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();
                if (email.isEmpty || pass.length < 6) return;
                Navigator.pop(ctx);
                try {
                  final authRes = await supabase.auth.signUp(email: email, password: pass);
                  final uid = authRes.user?.id;
                  if (uid != null) {
                    await supabase.from('profiles').upsert({
                      'id': uid,
                      'full_name': nameCtrl.text.trim(),
                      'email': email,
                      'phone_number': phoneCtrl.text.trim(),
                      'role': 'counselee',
                      'preacher_id': _preacherId,
                      'is_approved': true,
                      'hide_name_on_leaderboard': false,
                    });
                    _fetchCounselees();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Register Devotee'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preacher Console'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCounselees),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Counselees (${_counselees.length})', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                      icon: const Icon(Icons.person_add, size: 18),
                      label: const Text('Add Devotee'),
                      onPressed: _showAddCounseleeDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_counselees.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No counselees assigned to your group yet.')))
                else
                  ..._counselees.map((c) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          child: Text(c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : 'D'),
                        ),
                        title: Text(c.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Email: ${c.email}\nPhone: ${c.phoneNumber.isNotEmpty ? c.phoneNumber : "Not provided"}'),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

// ============================================================================
// 11. AGGREGATED LEADERBOARD
// ============================================================================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  int _tier = 0;
  String? _currentUserPreacherId;

  @override
  void initState() {
    super.initState();
    _fetchCurrentUserPreacher();
  }

  Future<void> _fetchCurrentUserPreacher() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await supabase.from('profiles').select('preacher_id').eq('id', user.id).single();
        setState(() {
          _currentUserPreacherId = profile['preacher_id']?.toString();
        });
      } catch (_) {}
    }
  }

  Future<List<LeaderboardAggregatedRow>> _fetchAggregatedLeaderboard() async {
    try {
      final response = await supabase
          .from('sadhana_entries')
          .select('user_id, chanting_rounds, calculated_score, profiles(role, full_name, preacher_id, hide_name_on_leaderboard, preachers(code_suffix))');

      final List<dynamic> raw = response as List<dynamic>;
      final Map<String, LeaderboardAggregatedRow> aggregated = {};

      for (final item in raw) {
        final map = item as Map<String, dynamic>;
        final profile = map['profiles'] as Map<String, dynamic>?;

        if (profile?['role'] == 'super_admin') continue;

        final String uId = map['user_id']?.toString() ?? '';
        final String? preacherId = profile?['preacher_id']?.toString();

        if (_tier == 0 && _currentUserPreacherId != null) {
          if (preacherId != _currentUserPreacherId) continue;
        }

        final preacher = profile?['preachers'] as Map<String, dynamic>?;
        final bool isAnon = profile?['hide_name_on_leaderboard'] == true;
        final String name = isAnon ? 'Anonymous Devotee' : (profile?['full_name']?.toString() ?? 'Devotee');
        final String suffix = preacher != null ? ' - ${preacher['code_suffix']}' : '';
        final double score = (map['calculated_score'] as num?)?.toDouble() ?? 0.0;
        final int rounds = (map['chanting_rounds'] as num?)?.toInt() ?? 0;

        if (aggregated.containsKey(uId)) {
          final existing = aggregated[uId]!;
          aggregated[uId] = LeaderboardAggregatedRow(
            userId: uId,
            name: name,
            preacherSuffix: suffix,
            preacherId: preacherId,
            totalScore: existing.totalScore + score,
            avgScore: (existing.totalScore + score) / (existing.entriesCount + 1),
            totalRounds: existing.totalRounds + rounds,
            entriesCount: existing.entriesCount + 1,
          );
        } else {
          aggregated[uId] = LeaderboardAggregatedRow(
            userId: uId,
            name: name,
            preacherSuffix: suffix,
            preacherId: preacherId,
            totalScore: score,
            avgScore: score,
            totalRounds: rounds,
            entriesCount: 1,
          );
        }
      }

      final list = aggregated.values.toList();
      list.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sadhana Standings')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text("Preacher's Circle")),
                    ButtonSegment(value: 1, label: Text('Global Devotees')),
                  ],
                  selected: {_tier},
                  onSelectionChanged: (val) => setState(() => _tier = val.first),
                ),
              ),
              Expanded(
                child: FutureBuilder<List<LeaderboardAggregatedRow>>(
                  future: _fetchAggregatedLeaderboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final list = snapshot.data ?? [];
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          _tier == 0
                              ? "No devotee records found for your Preacher's group."
                              : 'No sadhana entries recorded yet globally.',
                          style: const TextStyle(color: AppColors.textMuted),
                        ),
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = list[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: index == 0
                                ? AppColors.goldAccent
                                : (index < 3 ? AppColors.saffronPrimary : Colors.grey.shade200),
                            foregroundColor: index < 3 ? Colors.white : Colors.black87,
                            child: Text('${index + 1}'),
                          ),
                          title: Text(
                            '${item.name}${item.preacherSuffix}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          subtitle: Text(
                            'Total Rounds: ${item.totalRounds} • ${item.entriesCount} Logged Offerings',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${item.totalScore.toStringAsFixed(1)} pts',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark, fontSize: 16),
                              ),
                              Text(
                                'Avg: ${item.avgScore.toStringAsFixed(1)}',
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 12. PROFILE & SETTINGS (With Self Email & Data Modification)
// ============================================================================
class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final res = await supabase
            .from('profiles')
            .select('full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, preachers(display_title, code_suffix)')
            .eq('id', user.id)
            .single();
        if (mounted) {
          setState(() {
            _profileData = res;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showEditProfileDialog() {
    final user = supabase.auth.currentUser;
    if (user == null || _profileData == null) return;

    final nameCtrl = TextEditingController(text: _profileData!['full_name'] ?? '');
    final emailCtrl = TextEditingController(text: user.email ?? '');
    final phoneCtrl = TextEditingController(text: _profileData!['phone_number'] ?? '');
    final profCtrl = TextEditingController(text: _profileData!['profession'] ?? '');
    final eduCtrl = TextEditingController(text: _profileData!['education'] ?? '');
    final addrCtrl = TextEditingController(text: _profileData!['address'] ?? '');
    bool hideName = _profileData!['hide_name_on_leaderboard'] ?? false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                left: 24,
                right: 24,
                top: 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Edit Personal Details', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextField(controller: nameCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: emailCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Registered Email Address', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: phoneCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'WhatsApp Phone', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: profCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: eduCtrl, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'Qualification', border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: addrCtrl, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'Full Address', border: OutlineInputBorder())),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Hide Name on Leaderboards'),
                      subtitle: const Text('Shows as "Anonymous Devotee" to others'),
                      value: hideName,
                      onChanged: (val) => setSheetState(() => hideName = val),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final newEmail = emailCtrl.text.trim();

                          if (newEmail.isNotEmpty && newEmail != user.email) {
                            try {
                              await supabase.auth.updateUser(UserAttributes(email: newEmail));
                            } catch (_) {}
                          }

                          await supabase.from('profiles').update({
                            'full_name': nameCtrl.text.trim(),
                            'email': newEmail,
                            'phone_number': phoneCtrl.text.trim(),
                            'profession': profCtrl.text.trim(),
                            'education': eduCtrl.text.trim(),
                            'address': addrCtrl.text.trim(),
                            'hide_name_on_leaderboard': hideName,
                          }).eq('id', user.id);

                          _fetchProfile();
                        },
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final pr = _profileData?['preachers'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Center(child: MSMonogramLogo(size: 80)),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  _profileData?['full_name'] ?? 'Devotee',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user?.email ?? '',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _infoRow('Phone', _profileData?['phone_number'] ?? 'Not set'),
                      const Divider(),
                      _infoRow('Profession', _profileData?['profession'] ?? 'Not set'),
                      const Divider(),
                      _infoRow('Qualification', _profileData?['education'] ?? 'Not set'),
                      const Divider(),
                      _infoRow('Address', _profileData?['address'] ?? 'Not set'),
                      const Divider(),
                      _infoRow('Preacher', pr != null ? '${pr['display_title']} (${pr['code_suffix']})' : 'None'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile Details', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: _showEditProfileDialog,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sacredRed,
                  side: const BorderSide(color: AppColors.sacredRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async => await supabase.auth.signOut(),
                child: const Text('Sign Out'),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }
}