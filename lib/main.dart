import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

// ============================================================================
// 1. DATA MODELS & CONFIGURATION
// ============================================================================
// Installed build code on phone (increment this in pubspec when compiling)
const int kCurrentInstalledVersionCode = 4; // v1.0.3+4
const String kVercelApkDownloadUrl = 'https://my-sadhna.vercel.app/app.apk';

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
  final String? latestEntryDate;

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
    this.latestEntryDate,
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
  final int shlokasMemorized;
  final double calculatedScore;
  final bool isStreakFreeze;

  const DailyLogData({
    required this.id,
    required this.entryDate,
    required this.wakeUpTime,
    required this.bedTime,
    required this.chantingRounds,
    required this.spBookReadingMinutes,
    required this.spLectureMinutes,
    required this.otherHearingMinutes,
    required this.shlokasMemorized,
    required this.calculatedScore,
    this.isStreakFreeze = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entry_date': entryDate,
      'wake_up_time': wakeUpTime,
      'bed_time': bedTime,
      'chanting_rounds': chantingRounds,
      'sp_book_reading_minutes': spBookReadingMinutes,
      'sp_lecture_hearing_minutes': spLectureMinutes,
      'other_hearing_minutes': otherHearingMinutes,
      'shlokas_memorized': shlokasMemorized,
      'calculated_score': calculatedScore,
      'is_streak_freeze': isStreakFreeze,
    };
  }

  factory DailyLogData.fromMap(Map<String, dynamic> map) {
    return DailyLogData(
      id: map['id']?.toString() ?? '',
      entryDate: map['entry_date']?.toString() ?? '',
      wakeUpTime: map['wake_up_time']?.toString() ?? '04:00:00',
      bedTime: map['bed_time']?.toString() ?? '21:45:00',
      chantingRounds: (map['chanting_rounds'] as num?)?.toInt() ?? 0,
      spBookReadingMinutes: (map['sp_book_reading_minutes'] as num?)?.toInt() ?? 0,
      spLectureMinutes: (map['sp_lecture_hearing_minutes'] as num?)?.toInt() ?? 0,
      otherHearingMinutes: (map['other_hearing_minutes'] as num?)?.toInt() ?? 0,
      shlokasMemorized: (map['shlokas_memorized'] as num?)?.toInt() ?? 0,
      calculatedScore: (map['calculated_score'] as num?)?.toDouble() ?? 0.0,
      isStreakFreeze: map['is_streak_freeze'] == true,
    );
  }
}

class PersonalStats {
  final double totalSP;
  final double avgSP;
  final int totalRounds;
  final int count;
  final int currentStreak;
  final int longestStreak;
  final bool hasLoggedToday;
  final DailyLogData? todayEntry;
  final List<DailyLogData> recent;
  final String? counselorNote;
  final String? counselorTitle;
  final String? counselorId;

  const PersonalStats({
    required this.totalSP,
    required this.avgSP,
    required this.totalRounds,
    required this.count,
    required this.currentStreak,
    required this.longestStreak,
    required this.hasLoggedToday,
    required this.todayEntry,
    required this.recent,
    this.counselorNote,
    this.counselorTitle,
    this.counselorId,
  });
}

class RankingItem {
  final int rank;
  final String userId;
  final String devoteeName;
  final String preacherId;
  final String preacherTitle;
  final double totalSP;
  final int totalRounds;
  final bool isCurrentUser;
  final String badgeEmblem;

  RankingItem({
    required this.rank,
    required this.userId,
    required this.devoteeName,
    required this.preacherId,
    required this.preacherTitle,
    required this.totalSP,
    required this.totalRounds,
    required this.isCurrentUser,
    this.badgeEmblem = '📿',
  });

  factory RankingItem.fromMap(Map<String, dynamic> map) {
    final rounds = (map['total_rounds'] as num?)?.toInt() ?? 0;
    String badge = '🌱';
    if (rounds >= 1000) badge = '👑';
    else if (rounds >= 500) badge = '🔥';
    else if (rounds >= 100) badge = '📿';

    return RankingItem(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      userId: map['user_id']?.toString() ?? '',
      devoteeName: map['devotee_name']?.toString() ?? 'Devotee',
      preacherId: map['preacher_id']?.toString() ?? '',
      preacherTitle: map['preacher_title']?.toString() ?? 'Preacher Group',
      totalSP: (map['total_sp'] as num?)?.toDouble() ?? 0.0,
      totalRounds: rounds,
      isCurrentUser: map['is_current_user'] == true,
      badgeEmblem: badge,
    );
  }
}

class SacredBadge {
  final String titleEn;
  final String titleHi;
  final String descEn;
  final String descHi;
  final String icon;
  final bool isUnlocked;

  const SacredBadge({
    required this.titleEn,
    required this.titleHi,
    required this.descEn,
    required this.descHi,
    required this.icon,
    required this.isUnlocked,
  });
}

// Global Language Controller
final ValueNotifier<String> appLanguage = ValueNotifier<String>('en');

class AppStrings {
  static String tr(String key) {
    final isHi = appLanguage.value == 'hi';
    switch (key) {
      case 'app_title': return 'My Sadhna';
      case 'journey_title': return isHi ? 'मेरी साधना यात्रा' : 'My Sadhna Journey';
      case 'sukriti_points': return isHi ? 'सुकृति अंक (SP)' : 'Sukriti Points (SP)';
      case 'accumulated_sp': return isHi ? 'कुल अर्जित सुकृति अंक' : 'ACCUMULATED SUKRITI POINTS';
      case 'today_offered': return isHi ? 'आज की साधना अर्पित की गई' : "Today's Sadhana Offered";
      case 'today_pending': return isHi ? 'आज की साधना शेष है' : "Today's Sadhana Pending";
      case 'log_before_midnight': return isHi ? 'मध्यरात्रि से पूर्व समर्पण करें' : 'Log before midnight to earn Sukriti Points';
      case 'submit': return isHi ? 'समर्पण करें' : 'Submit';
      case 'edit_log': return isHi ? 'संशोधन करें' : 'Edit Log';
      case 'japa_rounds': return isHi ? 'जप माला संख्या' : 'Total Japa Rounds';
      case 'active_streak': return isHi ? 'निरंतर साधना' : 'Active Streak';
      case 'sacred_badges': return isHi ? 'साधना उपलब्धियां एवं बैज' : 'Sacred Milestones & Badges';
      case 'export_pdf': return isHi ? 'मासिक साधना पत्रक (PDF)' : 'Monthly Sadhana Card (PDF)';
      case 'recent_offerings': return isHi ? 'हालिया समर्पण इतिहास' : 'Recent Offerings';
      case 'record_sadhana': return isHi ? 'दैनिक साधना दर्ज करें' : 'Record Daily Sadhana';
      case 'top_rankings': return isHi ? 'शीर्ष साधक तालिका' : 'Top Rankings';
      case 'weekly_top': return isHi ? 'साप्ताहिक' : 'Weekly';
      case 'monthly_top': return isHi ? 'मासिक' : 'Monthly';
      case 'all_counselors': return isHi ? 'समस्त साधक' : 'All Circles';
      case 'my_counselor_only': return isHi ? 'मेरी भक्ति वृक्ष मंडली' : 'My Counselor Group';
      case 'your_standing': return isHi ? 'आपकी वर्तमान स्थिति' : 'YOUR CURRENT STANDING';
      case 'wake_time': return isHi ? 'जागरण समय' : 'Wake-up Time';
      case 'bed_time': return isHi ? 'शयन समय' : 'Bedtime';
      case 'sp_reading': return isHi ? 'प्रभुपाद ग्रंथ अध्ययन' : 'SP Book Reading';
      case 'sp_hearing': return isHi ? 'प्रभुपाद प्रवचन श्रवण' : 'SP Lecture Hearing';
      case 'other_hearing': return isHi ? 'अन्य आध्यात्मिक श्रवण / कीर्तन' : 'Other Spiritual Hearing';
      case 'shlokas': return isHi ? 'कंठस्थ किए गए श्लोक' : 'Shlokas Memorized Today';
      case 'profile': return isHi ? 'प्रोफ़ाइल' : 'Profile';
      case 'standings': return isHi ? 'स्थान' : 'Standings';
      case 'home': return isHi ? 'मुख्य पृष्ठ' : 'Home';
      case 'calendar_heatmap': return isHi ? 'मासिक साधना कैलेंडर' : 'Monthly Sadhana Heatmap';
      case 'counselor_guidance': return isHi ? 'काउंसलर मार्गदर्शन एवं आशीर्वाद' : 'Counselor Guidance & Blessings';
      case 'woke_up_now': return isHi ? 'अभी जागे (प्रणाम)' : 'Woke up just now (Pranam)';
      case 'sleeping_now': return isHi ? 'शयन समय' : 'Sleeping now';
      case 'streak_freeze': return isHi ? 'यात्रा / अस्वस्थ (Pass)' : 'Travel / Unwell Pass';
      case 'bhakti_wrapped': return isHi ? 'वार्षिक साधना सार (Wrapped)' : 'Bhakti Wrapped Summary';
      default: return key;
    }
  }
}

// ============================================================================
// 2. ENTRY POINT & THEME CONSTANTS
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
  static const Color saffronDark = Color(0xFFC04B00);
  static const Color goldAccent = Color(0xFFD97706);
  static const Color tulsiGreen = Color(0xFF1B4332);
  static const Color tulsiSoft = Color(0xFF2D6A4F);
  static const Color creamBg = Color(0xFFFAF9F6);
  static const Color cardBg = Colors.white;
  static const Color textDark = Color(0xFF1F1A17);
  static const Color textMuted = Color(0xFF6B5E55);
  static const Color sacredRed = Color(0xFF991B1B);
  static const Color borderSubtle = Color(0xFFE2D9D0);
}

class MySadhnaApp extends StatelessWidget {
  const MySadhnaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: appLanguage,
      builder: (context, lang, _) {
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
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.creamBg,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: TextStyle(
                color: AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              iconTheme: IconThemeData(color: AppColors.textDark),
            ),
          ),
          home: const AuthGate(),
        );
      },
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
// 4. AUTH GATE & BACKGROUND APP UPDATE CHECKER (App Only)
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
    // Prompt app updates only on real mobile devices (never web)
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForAppUpdate());
    }
  }

  Future<void> _checkForAppUpdate() async {
    try {
      // Check latest live code from Supabase app_config or fallback check
      final res = await supabase.from('app_config').select('latest_version_code').maybeSingle();
      final int latestCode = (res?['latest_version_code'] as num?)?.toInt() ?? (kCurrentInstalledVersionCode + 1);

      if (latestCode > kCurrentInstalledVersionCode && mounted) {
        showModalBottomSheet(
          context: context,
          isDismissible: false,
          enableDrag: false,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          builder: (ctx) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.upgrade_rounded, size: 54, color: AppColors.saffronDark),
                const SizedBox(height: 12),
                const Text(
                  'A fresh update of My Sadhna is ready with smoother performance.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, height: 1.4),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap below to update directly. Your recorded daily sadhana remains safe.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tulsiGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final uri = Uri.parse(kVercelApkDownloadUrl);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri, mode: LaunchMode.externalApplication);
                      }
                    },
                    child: const Text('Update Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (_) {}
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
// 5. ONBOARDING & REGISTRATION
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

  bool _obscureLoginPassword = true;
  bool _obscureRegisterPassword = true;

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

  Future<void> _handleAuth() async {
    setState(() => _isLoading = true);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await supabase.auth.signInWithPassword(email: email, password: password);
      } else {
        if (_selectedPreacherId == null) throw Exception('Please select an assigned Preacher.');

        final authRes = await supabase.auth.signUp(email: email, password: password);
        final userId = authRes.user?.id;
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
    final isHi = appLanguage.value == 'hi';

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                Align(
                  alignment: Alignment.topRight,
                  child: ActionChip(
                    backgroundColor: AppColors.creamBg,
                    side: const BorderSide(color: AppColors.borderSubtle),
                    avatar: const Icon(Icons.language, size: 16, color: AppColors.saffronDark),
                    label: Text(
                      isHi ? 'EN' : 'हिन्दी',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
                    ),
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      appLanguage.value = isHi ? 'en' : 'hi';
                    },
                  ),
                ),
                const SizedBox(height: 8),
                const MSMonogramLogo(size: 64).animate().scale(duration: 400.ms),
                const SizedBox(height: 16),
                Text('My Sadhna', style: GoogleFonts.cinzel(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                Text(isHi ? 'दैनिक साधना एवं सुकृति ट्रैकर' : 'Daily Sadhana & Sukriti Tracker', style: const TextStyle(fontSize: 13, color: AppColors.saffronDark, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
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
                            child: const Text('Register', style: TextStyle(fontWeight: FontWeight.bold)),
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
                            child: const Text('Sign In', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (_isLoginMode) ...[
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureLoginPassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffronDark),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureLoginPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                        onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onFieldSubmitted: (_) => _handleAuth(),
                  ),
                ] else ...[
                  if (_currentStep == 0)
                    Form(
                      key: _formKeyStep0,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Full / Initiated Name',
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: 'WhatsApp Phone Number',
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureRegisterPassword,
                            decoration: InputDecoration(
                              labelText: 'Create Password (6+ chars)',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffronDark),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureRegisterPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                                onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_currentStep == 1)
                    Form(
                      key: _formKeyStep1,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _professionController,
                            decoration: InputDecoration(labelText: 'Profession', prefixIcon: const Icon(Icons.work_outline, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _educationController,
                            decoration: InputDecoration(labelText: 'Education', prefixIcon: const Icon(Icons.school, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(labelText: 'Address', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
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
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    onPressed: _isLoading ? null : () {
                      if (_isLoginMode) {
                        _handleAuth();
                      } else {
                        if (_currentStep < 2) {
                          setState(() => _currentStep++);
                        } else {
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
}

// ============================================================================
// 6. MAIN NAVIGATION SCAFFOLD
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
      destinations = [
        const NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.saffronDark), label: 'Admin'),
        NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: const Icon(Icons.emoji_events, color: AppColors.saffronDark), label: AppStrings.tr('standings')),
        NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person, color: AppColors.saffronDark), label: AppStrings.tr('profile')),
      ];
    } else if (isPreacher) {
      screens = const [
        PreacherConsoleScreen(),
        LeaderboardScreen(),
        ProfileDashboardScreen(),
      ];
      destinations = [
        const NavigationDestination(icon: Icon(Icons.temple_hindu_outlined), selectedIcon: Icon(Icons.temple_hindu, color: AppColors.saffronDark), label: 'Counselees'),
        NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: const Icon(Icons.emoji_events, color: AppColors.saffronDark), label: AppStrings.tr('standings')),
        NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person, color: AppColors.saffronDark), label: AppStrings.tr('profile')),
      ];
    } else {
      screens = const [
        DevoteeSelfDashboardScreen(),
        LeaderboardScreen(),
        ProfileDashboardScreen(),
      ];
      destinations = [
        NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home, color: AppColors.saffronDark), label: AppStrings.tr('home')),
        NavigationDestination(icon: const Icon(Icons.emoji_events_outlined), selectedIcon: const Icon(Icons.emoji_events, color: AppColors.saffronDark), label: AppStrings.tr('standings')),
        NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person, color: AppColors.saffronDark), label: AppStrings.tr('profile')),
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
// 7. DEVOTEE SELF DASHBOARD (One-tap Awake/Sleep, Wrapped & Badges)
// ============================================================================
class DevoteeSelfDashboardScreen extends StatefulWidget {
  const DevoteeSelfDashboardScreen({super.key});

  @override
  State<DevoteeSelfDashboardScreen> createState() => _DevoteeSelfDashboardScreenState();
}

class _DevoteeSelfDashboardScreenState extends State<DevoteeSelfDashboardScreen> {
  late Future<PersonalStats> _statsFuture;
  String _userName = 'Devotee';
  bool _isFlushingOffline = false;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    _syncPendingOfflineEntries();
  }

  void _refreshStats() {
    final user = supabase.auth.currentUser;
    setState(() {
      _statsFuture = _fetchPersonalStats(user?.id);
    });
  }

  Future<void> _syncPendingOfflineEntries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingRaw = prefs.getStringList('pending_sadhana_queue') ?? [];
      if (pendingRaw.isEmpty) return;

      setState(() => _isFlushingOffline = true);
      final List<String> unSynced = [];

      for (final item in pendingRaw) {
        try {
          final Map<String, dynamic> data = jsonDecode(item);
          await supabase.from('sadhana_entries').upsert(data, onConflict: 'user_id, entry_date');
        } catch (_) {
          unSynced.add(item);
        }
      }

      await prefs.setStringList('pending_sadhana_queue', unSynced);
      if (mounted) {
        setState(() => _isFlushingOffline = false);
        _refreshStats();
      }
    } catch (_) {
      if (mounted) setState(() => _isFlushingOffline = false);
    }
  }

  Future<PersonalStats> _fetchPersonalStats(String? userId) async {
    if (userId == null) {
      return const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
    try {
      final userProf = await supabase.from('profiles').select('full_name, preacher_id, preachers(display_title)').eq('id', userId).single();
      _userName = userProf['full_name']?.toString() ?? 'Devotee';
      final pTitle = (userProf['preachers'] as Map<String, dynamic>?)?['display_title']?.toString();
      final pId = userProf['preacher_id']?.toString();

      final res = await supabase
          .from('sadhana_entries')
          .select('id, entry_date, wake_up_time, bed_time, chanting_rounds, sp_book_reading_minutes, sp_lecture_hearing_minutes, other_hearing_minutes, shlokas_memorized, calculated_score, is_streak_freeze')
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .limit(60);

      final List<dynamic> raw = res as List<dynamic>;
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      double total = 0;
      int rounds = 0;
      DailyLogData? todayRecord;
      final List<DailyLogData> entries = [];

      for (final r in raw) {
        final data = DailyLogData.fromMap(r as Map<String, dynamic>);
        entries.add(data);
        total += data.calculatedScore;
        rounds += data.chantingRounds;

        if (data.entryDate == todayStr) {
          todayRecord = data;
        }
      }

      int currentStreak = 0;
      DateTime checkDate = DateTime.now();
      if (todayRecord == null) {
        checkDate = checkDate.subtract(const Duration(days: 1));
      }

      final datesMap = {for (var e in entries) e.entryDate: e};
      while (true) {
        final dateKey = DateFormat('yyyy-MM-dd').format(checkDate);
        if (datesMap.containsKey(dateKey)) {
          currentStreak++;
          checkDate = checkDate.subtract(const Duration(days: 1));
        } else {
          break;
        }
      }

      String? note;
      try {
        final currentMonthStr = DateFormat('yyyy-MM').format(DateTime.now());
        final noteRes = await supabase.from('counselor_notes').select('note_text').eq('devotee_id', userId).eq('month_year', currentMonthStr).maybeSingle();
        note = noteRes?['note_text']?.toString();
      } catch (_) {}

      return PersonalStats(
        totalSP: total,
        avgSP: entries.isEmpty ? 0 : total / entries.length,
        totalRounds: rounds,
        count: entries.length,
        currentStreak: currentStreak,
        longestStreak: max(currentStreak, entries.length > 5 ? 7 : currentStreak),
        hasLoggedToday: todayRecord != null,
        todayEntry: todayRecord,
        recent: entries,
        counselorNote: note,
        counselorTitle: pTitle,
        counselorId: pId,
      );
    } catch (_) {
      return const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
  }

  Future<void> _quickTimestampWakeOrSleep(bool isWakeUp) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:00';

    try {
      final payload = isWakeUp ? {'wake_up_time': timeStr} : {'bed_time': timeStr};
      await supabase.from('sadhana_entries').upsert({
        'user_id': user.id,
        'entry_date': todayStr,
        ...payload,
        'last_modified_timestamp': now.toIso8601String(),
      }, onConflict: 'user_id, entry_date');

      HapticFeedback.mediumImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.tulsiGreen,
            content: Text(isWakeUp ? '🌅 Wake-up time confirmed ($timeStr)! Pranam.' : '🌙 Bedtime recorded ($timeStr). Good night!'),
          ),
        );
        _refreshStats();
      }
    } catch (_) {}
  }

  void _showBhaktiWrappedDialog(PersonalStats stats) {
    int totalReading = 0;
    for (var e in stats.recent) {
      totalReading += e.spBookReadingMinutes;
    }
    final totalHolyNames = stats.totalRounds * 108 * 16;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MSMonogramLogo(size: 60),
            const SizedBox(height: 12),
            Text('Bhakti Wrapped', style: GoogleFonts.cinzel(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
            Text('Spiritual Journey of $_userName', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
            const Divider(height: 24),
            _wrappedItem('📿 Holy Names Chanted', '${NumberFormat('#,##,###').format(totalHolyNames)} Names'),
            const SizedBox(height: 10),
            _wrappedItem('📖 Prabhupada Reading', '${(totalReading / 60).toStringAsFixed(1)} Hours'),
            const SizedBox(height: 10),
            _wrappedItem('🌟 Total Sukriti Points', '${stats.totalSP.toStringAsFixed(0)} SP'),
            const SizedBox(height: 10),
            _wrappedItem('🔥 Longest Active Streak', '${stats.longestStreak} Consecutive Days'),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Inspiring! Haribol'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _wrappedItem(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppColors.creamBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.borderSubtle)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHi = appLanguage.value == 'hi';

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.tr('journey_title')),
        actions: [
          ActionChip(
            backgroundColor: AppColors.creamBg,
            side: const BorderSide(color: AppColors.borderSubtle),
            avatar: const Icon(Icons.language, size: 16, color: AppColors.saffronDark),
            label: Text(
              isHi ? 'EN' : 'हिन्दी',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              appLanguage.value = isHi ? 'en' : 'hi';
            },
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<PersonalStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snapshot.data ?? const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);

              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // One-Tap Quick Wake Up / Sleep Bar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.saffronDark),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.wb_sunny, color: AppColors.saffronDark, size: 18),
                          label: Text(AppStrings.tr('woke_up_now'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                          onPressed: () => _quickTimestampWakeOrSleep(true),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.tulsiGreen),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.bedtime, color: AppColors.tulsiGreen, size: 18),
                          label: Text(AppStrings.tr('sleeping_now'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.tulsiGreen)),
                          onPressed: () => _quickTimestampWakeOrSleep(false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Accumulated SP Hero Card
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
                        BoxShadow(color: AppColors.saffronPrimary.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppStrings.tr('accumulated_sp'), style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Text(
                                  stats.totalSP.toStringAsFixed(0),
                                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                  child: const Text('SP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Avg: ${stats.avgSP.toStringAsFixed(1)} SP / day • ${stats.count} Days Active', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                        InkWell(
                          onTap: () => _showBhaktiWrappedDialog(stats),
                          child: const MSMonogramLogo(size: 54),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Today's Status Banner
                  Container(
                    decoration: BoxDecoration(
                      color: (stats.hasLoggedToday == true) ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                      border: Border.all(color: (stats.hasLoggedToday == true) ? const Color(0xFF10B981) : AppColors.saffronPrimary),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: (stats.hasLoggedToday == true) ? AppColors.tulsiGreen : AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          child: Icon((stats.hasLoggedToday == true) ? Icons.check_circle_outline : Icons.edit_calendar),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (stats.hasLoggedToday == true) ? AppStrings.tr('today_offered') : AppStrings.tr('today_pending'),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                (stats.hasLoggedToday == true)
                                    ? 'Score: ${stats.todayEntry?.calculatedScore.toStringAsFixed(1)} SP • Tap to modify'
                                    : AppStrings.tr('log_before_midnight'),
                                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: (stats.hasLoggedToday == true) ? AppColors.tulsiGreen : AppColors.saffronDark,
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
                          child: Text((stats.hasLoggedToday == true) ? AppStrings.tr('edit_log') : AppStrings.tr('submit')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Stats Row
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
                                Text(AppStrings.tr('japa_rounds'), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
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
                                Text(AppStrings.tr('active_streak'), style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                                const SizedBox(height: 6),
                                Text('🔥 ${stats.currentStreak} Days', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Bhakti Wrapped Shortcut Banner
                  InkWell(
                    onTap: () => _showBhaktiWrappedDialog(stats),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldAccent),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: AppColors.saffronDark, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(AppStrings.tr('bhakti_wrapped'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.saffronDark),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 8. DAILY ENTRY FORM (Slider Stepper + Streak Freeze Pass)
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

  int _rounds = 0;
  int _spReadingMinutes = 0;
  int _spLectureMinutes = 0;
  int _otherHearingMinutes = 0;
  int _shlokasMemorized = 0;
  bool _isStreakFreeze = false;
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
      _shlokasMemorized = rec.shlokasMemorized;
      _isStreakFreeze = rec.isStreakFreeze;

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

  double _calculateLiveSP() {
    if (_isStreakFreeze) return 50.0; // Flat protected pass score

    final wakeMins = _wakeUpTime.hour * 60 + _wakeUpTime.minute;
    double japaSP = 0.0;

    if (_rounds >= 16 && wakeMins <= (4 * 60 + 30)) {
      japaSP = 100.0;
    } else {
      japaSP = min(_rounds * 4.375, 70.0);
    }

    final readingSP = (_spReadingMinutes / 30.0) * 25.0;
    final hearingSP = ((_spLectureMinutes + _otherHearingMinutes) / 30.0) * 25.0;
    final shlokaSP = _shlokasMemorized * 50.0;

    return japaSP + readingSP + hearingSP + shlokaSP;
  }

  Future<void> _submitDailySadhana() async {
    setState(() => _isSaving = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final dateString = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final payload = {
      'user_id': user.id,
      'entry_date': dateString,
      'wake_up_time': '${_wakeUpTime.hour.toString().padLeft(2, '0')}:${_wakeUpTime.minute.toString().padLeft(2, '0')}:00',
      'bed_time': '${_bedTime.hour.toString().padLeft(2, '0')}:${_bedTime.minute.toString().padLeft(2, '0')}:00',
      'chanting_rounds': _rounds,
      'sp_book_reading_minutes': _spReadingMinutes,
      'sp_lecture_hearing_minutes': _spLectureMinutes,
      'other_hearing_minutes': _otherHearingMinutes,
      'shlokas_memorized': _shlokasMemorized,
      'calculated_score': _calculateLiveSP(),
      'is_streak_freeze': _isStreakFreeze,
      'last_modified_timestamp': DateTime.now().toIso8601String(),
    };

    try {
      await supabase.from('sadhana_entries').upsert(payload, onConflict: 'user_id, entry_date');

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.green, content: Text('Hari Bol! Daily Sadhana offering recorded successfully.')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      final pending = prefs.getStringList('pending_sadhana_queue') ?? [];
      pending.add(jsonEncode(payload));
      await prefs.setStringList('pending_sadhana_queue', pending);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(backgroundColor: Colors.orange, content: Text('Offline: Saved locally. Will auto-sync when online.')),
        );
        Navigator.pop(context, true);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSliderStepperCard({
    required String title,
    required String subtitle,
    required int value,
    required int min,
    required int max,
    required int step,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.borderSubtle),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.creamBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Text('$value $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: AppColors.saffronDark, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: AppColors.saffronPrimary,
                      inactiveTrackColor: Colors.grey.shade200,
                      thumbColor: AppColors.saffronDark,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                    ),
                    child: Slider(
                      value: value.toDouble(),
                      min: min.toDouble(),
                      max: max.toDouble(),
                      divisions: (max - min) ~/ step,
                      onChanged: (newVal) => onChanged(newVal.round()),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline, color: AppColors.saffronDark, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveSP = _calculateLiveSP();

    return Scaffold(
      appBar: AppBar(title: Text(widget.existingRecord != null ? 'Edit Sadhana Record' : AppStrings.tr('record_sadhana'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Sukriti Display
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
                        Text(AppStrings.tr('sukriti_points'), style: const TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(liveSP.toStringAsFixed(1), style: GoogleFonts.outfit(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 6),
                            const Text('SP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    const MSMonogramLogo(size: 46),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Streak Freeze / Health Pass Toggle
              SwitchListTile(
                value: _isStreakFreeze,
                activeColor: AppColors.saffronDark,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderSubtle)),
                title: Text(AppStrings.tr('streak_freeze'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: const Text('Preserves your active streak while unwell or on pilgrimage.', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                onChanged: (val) => setState(() => _isStreakFreeze = val),
              ),
              const SizedBox(height: 16),

              if (!_isStreakFreeze) ...[
                _buildSliderStepperCard(
                  title: 'Japa Meditation Rounds',
                  subtitle: 'Target: 16 rounds',
                  value: _rounds,
                  min: 0,
                  max: 64,
                  step: 1,
                  unit: 'rounds',
                  onChanged: (v) => setState(() => _rounds = v),
                ),
                const SizedBox(height: 10),
                _buildSliderStepperCard(
                  title: AppStrings.tr('sp_reading'),
                  subtitle: 'Target: 30–45 mins',
                  value: _spReadingMinutes,
                  min: 0,
                  max: 180,
                  step: 5,
                  unit: 'mins',
                  onChanged: (v) => setState(() => _spReadingMinutes = v),
                ),
                const SizedBox(height: 10),
                _buildSliderStepperCard(
                  title: AppStrings.tr('sp_hearing'),
                  subtitle: 'Target: 30–45 mins',
                  value: _spLectureMinutes,
                  min: 0,
                  max: 180,
                  step: 5,
                  unit: 'mins',
                  onChanged: (v) => setState(() => _spLectureMinutes = v),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  onPressed: _isSaving ? null : _submitDailySadhana,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.existingRecord != null ? 'Update Offering' : AppStrings.tr('submit'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
// 9. LEADERBOARD SCREEN (All Devotees vs My Counselor Group Toggle + Badges)
// ============================================================================
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _periodType = 'weekly';
  bool _filterMyCircleOnly = false;
  String? _myCounselorId;

  @override
  void initState() {
    super.initState();
    _fetchMyCounselorId();
  }

  Future<void> _fetchMyCounselorId() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final res = await supabase.from('profiles').select('preacher_id').eq('id', user.id).single();
        setState(() => _myCounselorId = res['preacher_id']?.toString());
      } catch (_) {}
    }
  }

  Future<List<RankingItem>> _fetchTopRankings() async {
    try {
      final res = await supabase.rpc('get_top_rankings', params: {'p_period_type': _periodType});
      final List<dynamic> data = res as List<dynamic>;
      final list = data.map((e) => RankingItem.fromMap(e as Map<String, dynamic>)).toList();

      if (_filterMyCircleOnly && _myCounselorId != null) {
        return list.where((item) => item.preacherId == _myCounselorId).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr('top_rankings'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: [ButtonSegment(value: 'weekly', label: Text(AppStrings.tr('weekly_top'))), ButtonSegment(value: 'monthly', label: Text(AppStrings.tr('monthly_top')))],
                        selected: {_periodType},
                        onSelectionChanged: (val) => setState(() => _periodType = val.first),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      selected: _filterMyCircleOnly,
                      label: Text(_filterMyCircleOnly ? 'My Circle' : 'All Circles'),
                      onSelected: (val) => setState(() => _filterMyCircleOnly = val),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<RankingItem>>(
                  future: _fetchTopRankings(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    final rankings = snapshot.data ?? [];
                    if (rankings.isEmpty) return const Center(child: Text('No sadhana offerings logged yet.', style: TextStyle(color: AppColors.textMuted)));

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: rankings.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = rankings[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: item.rank == 1 ? AppColors.goldAccent : (item.rank == 2 ? const Color(0xFFC0C0C0) : (item.rank == 3 ? const Color(0xFFCD7F32) : Colors.grey.shade200)),
                            foregroundColor: item.rank <= 3 ? Colors.white : Colors.black87,
                            child: Text('#${item.rank}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                          title: Row(
                            children: [
                              Text(item.isCurrentUser ? '${item.devoteeName} (You)' : item.devoteeName, style: TextStyle(fontWeight: item.isCurrentUser ? FontWeight.w900 : FontWeight.bold)),
                              const SizedBox(width: 6),
                              Text(item.badgeEmblem, style: const TextStyle(fontSize: 14)),
                            ],
                          ),
                          subtitle: Text('${item.totalRounds} Rounds • ${item.preacherTitle}'),
                          trailing: Text('${item.totalSP.toStringAsFixed(1)} SP', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.saffronDark, fontSize: 15)),
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
// 10. PROFILE SCREEN & WEB DOWNLOAD BANNER
// ============================================================================
class WebApkDownloadBanner extends StatelessWidget {
  const WebApkDownloadBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.android, color: AppColors.tulsiGreen, size: 28),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Get the Android App', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text('Install for offline sadhana tracking and instant daily access.', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final uri = Uri.base.resolve('downloads/my_sadhna.apk');
              await launchUrl(uri, webOnlyWindowName: '_self');
            },
            child: const Text('Download APK'),
          ),
        ],
      ),
    );
  }
}

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
        final res = await supabase.from('profiles').select('full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, preachers(display_title, code_suffix)').eq('id', user.id).single();
        if (mounted) setState(() { _profileData = res; _isLoading = false; });
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr('profile'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              const Center(child: MSMonogramLogo(size: 80)),
              const SizedBox(height: 16),
              Center(child: Text(_profileData?['full_name'] ?? 'Devotee', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
              Center(child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 14))),
              const SizedBox(height: 20),
              const WebApkDownloadBanner(),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.sacredRed, side: const BorderSide(color: AppColors.sacredRed), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async => await supabase.auth.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholders for SuperAdmin & Preacher consoles to maintain full compile compatibility
class SuperAdminConsoleScreen extends StatelessWidget {
  const SuperAdminConsoleScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Admin Console')), body: const Center(child: Text('Admin Dashboard Active')));
}

class PreacherConsoleScreen extends StatelessWidget {
  const PreacherConsoleScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('Preacher Console')), body: const Center(child: Text('Counselee Management Active')));
}
