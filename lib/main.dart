import 'dart:async';
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
import 'package:connectivity_plus/connectivity_plus.dart';

// ============================================================================
// 1. DATA MODELS & GLOBAL CONFIGURATION
// ============================================================================
const int kCurrentInstalledVersionCode = 5; // v1.0.4+5
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
  final String avatarBadge;
  final String? dateOfBirth;

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
    this.avatarBadge = '📿',
    this.dateOfBirth,
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
  final String avatarBadge;
  final String? dateOfBirth;

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
    this.avatarBadge = '📿',
    this.dateOfBirth,
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
  final String avatarBadge;

  RankingItem({
    required this.rank,
    required this.userId,
    required this.devoteeName,
    required this.preacherId,
    required this.preacherTitle,
    required this.totalSP,
    required this.totalRounds,
    required this.isCurrentUser,
    this.avatarBadge = '📿',
  });

  factory RankingItem.fromMap(Map<String, dynamic> map) {
    return RankingItem(
      rank: (map['rank'] as num?)?.toInt() ?? 0,
      userId: map['user_id']?.toString() ?? '',
      devoteeName: map['devotee_name']?.toString() ?? 'Devotee',
      preacherId: map['preacher_id']?.toString() ?? '',
      preacherTitle: map['preacher_title']?.toString() ?? '',
      totalSP: (map['total_sp'] as num?)?.toDouble() ?? 0.0,
      totalRounds: (map['total_rounds'] as num?)?.toInt() ?? 0,
      isCurrentUser: map['is_current_user'] == true,
      avatarBadge: map['avatar_badge']?.toString() ?? '📿',
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
      case 'nistha_trend': return isHi ? 'निष्ठा एवं साधना तुलना' : 'Nistha Spiritual Growth Trend';
      case 'register_tab': return isHi ? 'पंजीकरण' : 'Register';
      case 'signin_tab': return isHi ? 'लॉग इन' : 'Sign In';
      case 'email_label': return isHi ? 'ईमेल पता' : 'Email Address';
      case 'password_label': return isHi ? 'पासवर्ड' : 'Password';
      case 'name_label': return isHi ? 'पूरा / दीक्षित नाम' : 'Full / Initiated Name';
      case 'phone_label': return isHi ? 'व्हाट्सएप फोन नंबर' : 'WhatsApp Phone Number';
      case 'create_password_label': return isHi ? 'पासवर्ड बनाएं (6+ अक्षर)' : 'Create Password (6+ chars)';
      case 'remember_password_tip': return isHi ? '💡 टिप: कृपया अपना पासवर्ड सुरक्षित रखें या कहीं नोट कर लें।' : '💡 Tip: Please remember or write down your password safely.';
      case 'dob_label': return isHi ? 'जन्म तिथि (DOB)' : 'Date of Birth (DOB)';
      case 'profession_label': return isHi ? 'व्यवसाय / पेशा' : 'Profession';
      case 'education_label': return isHi ? 'योग्यता / शिक्षा' : 'Qualification';
      case 'address_label': return isHi ? 'शहर / पता' : 'City / Address';
      case 'assigned_preacher': return isHi ? 'निर्धारित प्रचारक / काउंसलर' : 'Assigned Preacher';
      case 'next_step': return isHi ? 'अगला कदम' : 'Next Step';
      case 'complete_registration': return isHi ? 'पंजीकरण पूर्ण करें' : 'Complete Registration';
      case 'back_step': return isHi ? 'पिछले चरण पर वापस जाएं' : 'Back to previous step';
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
// 4. AUTH GATE & APP-ONLY IN-APP UPDATE ENGINE
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
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkForAppUpdate());
    }
  }

  Future<void> _checkForAppUpdate() async {
    try {
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
// 5. ONBOARDING & REGISTRATION (With Date of Birth Picker)
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

  DateTime? _selectedDob;
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

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'mysadhna://login-callback',
      );
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
            'date_of_birth': _selectedDob != null ? DateFormat('yyyy-MM-dd').format(_selectedDob!) : null,
            'profession': _professionController.text.trim(),
            'education': _educationController.text.trim(),
            'address': _addressController.text.trim(),
            'avatar_badge': '📿',
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
                            child: Text(AppStrings.tr('register_tab'), style: TextStyle(fontWeight: FontWeight.bold, color: !_isLoginMode ? Colors.white : AppColors.textMuted)),
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
                            child: Text(AppStrings.tr('signin_tab'), style: TextStyle(fontWeight: FontWeight.bold, color: _isLoginMode ? Colors.white : AppColors.textMuted)),
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
                      labelText: AppStrings.tr('email_label'),
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscureLoginPassword,
                    decoration: InputDecoration(
                      labelText: AppStrings.tr('password_label'),
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
                              labelText: AppStrings.tr('name_label'),
                              prefixIcon: const Icon(Icons.person_outline, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('phone_label'),
                              prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('email_label'),
                              prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureRegisterPassword,
                            decoration: InputDecoration(
                              labelText: AppStrings.tr('create_password_label'),
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffronDark),
                              suffixIcon: IconButton(
                                icon: Icon(_obscureRegisterPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted),
                                onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword),
                              ),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              AppStrings.tr('remember_password_tip'),
                              style: const TextStyle(fontSize: 11, color: AppColors.saffronDark, fontWeight: FontWeight.w600),
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
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.borderSubtle)),
                            child: ListTile(
                              leading: const Icon(Icons.cake_outlined, color: AppColors.saffronDark),
                              title: Text(
                                _selectedDob == null
                                    ? AppStrings.tr('dob_label')
                                    : '${DateFormat('dd MMMM yyyy').format(_selectedDob!)}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: _selectedDob == null ? FontWeight.normal : FontWeight.bold,
                                  color: _selectedDob == null ? AppColors.textMuted : AppColors.textDark,
                                ),
                              ),
                              trailing: const Icon(Icons.calendar_month, color: AppColors.saffronDark),
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime(2000, 1, 1),
                                  firstDate: DateTime(1940),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setState(() => _selectedDob = picked);
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _professionController,
                            decoration: InputDecoration(labelText: AppStrings.tr('profession_label'), prefixIcon: const Icon(Icons.work_outline, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _educationController,
                            decoration: InputDecoration(labelText: AppStrings.tr('education_label'), prefixIcon: const Icon(Icons.school, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressController,
                            decoration: InputDecoration(labelText: AppStrings.tr('address_label'), prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                          ),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPreacherId,
                      decoration: InputDecoration(
                        labelText: AppStrings.tr('assigned_preacher'),
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
                                ? AppStrings.tr('signin_tab')
                                : (_currentStep < 2 ? AppStrings.tr('next_step') : AppStrings.tr('complete_registration')),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    side: const BorderSide(color: AppColors.borderSubtle),
                  ),
                  icon: const Icon(Icons.account_circle, color: AppColors.saffronDark),
                  label: const Text('One-Tap Google Sign-In', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ),
                if (!_isLoginMode && _currentStep > 0)
                  TextButton(
                    onPressed: () => setState(() => _currentStep--),
                    child: Text(AppStrings.tr('back_step'), style: const TextStyle(color: AppColors.textMuted)),
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
// 7. DEVOTEE DASHBOARD (Heatmap, Badges, Nistha Growth & Background Auto-Sync)
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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _refreshStats();
    _syncPendingOfflineEntries();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        _syncPendingOfflineEntries();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
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
      final userProf = await supabase.from('profiles').select('full_name, preacher_id, avatar_badge, date_of_birth, preachers(display_title)').eq('id', userId).single();
      _userName = userProf['full_name']?.toString() ?? 'Devotee';
      final pTitle = (userProf['preachers'] as Map<String, dynamic>?)?['display_title']?.toString();
      final pId = userProf['preacher_id']?.toString();
      final badge = userProf['avatar_badge']?.toString() ?? '📿';
      final dob = userProf['date_of_birth']?.toString();

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
        avatarBadge: badge,
        dateOfBirth: dob,
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
            content: Text(isWakeUp ? '🌅 Wake-up confirmed ($timeStr)! Pranam.' : '🌙 Bedtime recorded ($timeStr). Good night!'),
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
            Text('Spiritual Journey of $_userName ${stats.avatarBadge}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

  Widget _buildNisthaGrowthCard(List<DailyLogData> entries) {
    int currentWeekRounds = 0;
    int prevWeekRounds = 0;
    int currentWeekMins = 0;
    int prevWeekMins = 0;

    for (int i = 0; i < entries.length; i++) {
      if (i < 7) {
        currentWeekRounds += entries[i].chantingRounds;
        currentWeekMins += (entries[i].spBookReadingMinutes + entries[i].spLectureMinutes);
      } else if (i < 14) {
        prevWeekRounds += entries[i].chantingRounds;
        prevWeekMins += (entries[i].spBookReadingMinutes + entries[i].spLectureMinutes);
      }
    }

    final roundsDiff = currentWeekRounds - prevWeekRounds;
    final minsDiff = currentWeekMins - prevWeekMins;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: AppColors.saffronDark, size: 20),
              const SizedBox(width: 8),
              Text(AppStrings.tr('nistha_trend'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nisthaPill('7-Day Japa', '$currentWeekRounds rds', roundsDiff >= 0 ? '+$roundsDiff rds vs last wk' : '$roundsDiff rds vs last wk', roundsDiff >= 0),
              _nisthaPill('Study & Hearing', '${currentWeekMins}m', minsDiff >= 0 ? '+$minsDiff m vs last wk' : '$minsDiff m vs last wk', minsDiff >= 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _nisthaPill(String title, String value, String sub, bool isPositive) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isPositive ? AppColors.tulsiGreen : AppColors.sacredRed)),
      ],
    );
  }

  List<SacredBadge> _evaluateBadges(PersonalStats stats) {
    int brahmaMuhurtaCount = 0;
    int totalShlokas = 0;
    int totalReadingMins = 0;

    for (final e in stats.recent) {
      try {
        final parts = e.wakeUpTime.split(':');
        if (parts.length >= 2) {
          final hour = int.tryParse(parts[0]) ?? 6;
          final minute = int.tryParse(parts[1]) ?? 0;
          if (hour < 4 || (hour == 4 && minute <= 30)) {
            brahmaMuhurtaCount++;
          }
        }
      } catch (_) {}
      totalShlokas += e.shlokasMemorized;
      totalReadingMins += e.spBookReadingMinutes;
    }

    return [
      SacredBadge(
        titleEn: 'Brahma-muhurta Warrior',
        titleHi: 'ब्रह्म मुहूर्त साधक',
        descEn: 'Woke up before 4:30 AM for 7+ days',
        descHi: '7 दिन या अधिक प्रातः 4:30 बजे से पूर्व जागरण',
        icon: '🌅',
        isUnlocked: brahmaMuhurtaCount >= 7,
      ),
      SacredBadge(
        titleEn: 'Nishtha Sadhaka',
        titleHi: 'निष्ठावान साधक',
        descEn: 'Maintained 7+ days consecutive active sadhana streak',
        descHi: '7 दिनों तक लगातार नियमित साधना का समर्पण',
        icon: '🔥',
        isUnlocked: stats.currentStreak >= 7,
      ),
      SacredBadge(
        titleEn: 'Swadhyaya Ratna',
        titleHi: 'स्वाध्याय रत्न',
        descEn: 'Completed 5+ hours of Srila Prabhupada book reading',
        descHi: 'प्रभुपाद ग्रंथ अध्ययन के 300 मिनट पूर्ण किए',
        icon: '📖',
        isUnlocked: totalReadingMins >= 300,
      ),
      SacredBadge(
        titleEn: 'Shloka Smriti',
        titleHi: 'श्लोक स्मृति',
        descEn: 'Memorized 3+ sacred verses',
        descHi: '3 या अधिक पवित्र श्लोक कंठस्थ किए',
        icon: '📜',
        isUnlocked: totalShlokas >= 3,
      ),
    ];
  }

  Widget _buildHeatmapGrid(List<DailyLogData> entries) {
    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final monthName = DateFormat('MMMM yyyy').format(now);

    final Map<int, DailyLogData> dayMap = {};
    for (final e in entries) {
      try {
        final parsed = DateTime.parse(e.entryDate);
        if (parsed.year == now.year && parsed.month == now.month) {
          dayMap[parsed.day] = e;
        }
      } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppStrings.tr('calendar_heatmap'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textDark)),
              Text(monthName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.saffronDark)),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(daysInMonth, (index) {
              final dayNum = index + 1;
              final entry = dayMap[dayNum];
              final isPast = dayNum <= now.day;

              Color cellColor = Colors.grey.shade100;
              Color borderCol = AppColors.borderSubtle;
              if (entry != null) {
                if (entry.isStreakFreeze) {
                  cellColor = const Color(0xFFE0F2FE);
                  borderCol = const Color(0xFF38BDF8);
                } else if (entry.calculatedScore >= 70) {
                  cellColor = const Color(0xFFD1FAE5);
                  borderCol = const Color(0xFF10B981);
                } else {
                  cellColor = const Color(0xFFFEF3C7);
                  borderCol = const Color(0xFFF59E0B);
                }
              } else if (isPast) {
                cellColor = const Color(0xFFFEE2E2);
                borderCol = const Color(0xFFFCA5A5);
              }

              return Tooltip(
                message: entry != null ? (entry.isStreakFreeze ? 'Day $dayNum: Travel / Unwell Pass' : 'Day $dayNum: ${entry.calculatedScore.toStringAsFixed(1)} SP (${entry.chantingRounds} rds)') : 'Day $dayNum: No log',
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderCol, width: 1.2),
                  ),
                  child: Text(
                    '$dayNum',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: entry != null ? AppColors.textDark : Colors.black45,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legendDot(const Color(0xFFD1FAE5), 'Full (70+ SP)'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFFEF3C7), 'Partial'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFE0F2FE), 'Pass'),
              const SizedBox(width: 12),
              _legendDot(const Color(0xFFFEE2E2), 'Missed'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: Colors.black26))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
      ],
    );
  }

  Future<void> _generatePdfReport(PersonalStats stats) async {
    final fontBase = await PdfGoogleFonts.outfitRegular();
    final fontBold = await PdfGoogleFonts.outfitBold();

    final pdf = pw.Document(
      theme: pw.ThemeData.withFont(base: fontBase, bold: fontBold),
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('MY SADHNA - MONTHLY REPORT', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange900)),
                        pw.Text('Devotee: $_userName ${stats.avatarBadge}', style: const pw.TextStyle(fontSize: 14)),
                        pw.Text('Date Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.deepOrange)),
                      child: pw.Text('${stats.totalSP.toStringAsFixed(0)} SP', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.deepOrange)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 16),
                pw.Divider(),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total Days Logged: ${stats.count}'),
                    pw.Text('Total Japa Rounds: ${stats.totalRounds}'),
                    pw.Text('Active Streak: ${stats.currentStreak} Days'),
                    pw.Text('Avg SP/Day: ${stats.avgSP.toStringAsFixed(1)}'),
                  ],
                ),
                pw.SizedBox(height: 18),
                pw.Text('Daily Sadhana Record Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.TableHelper.fromTextArray(
                  headers: ['Date', 'Wake', 'Rounds', 'Read (m)', 'Hear (m)', 'Shlokas', 'SP'],
                  data: stats.recent.take(15).map((e) => [
                    e.entryDate,
                    e.wakeUpTime.length >= 5 ? e.wakeUpTime.substring(0, 5) : e.wakeUpTime,
                    '${e.chantingRounds}',
                    '${e.spBookReadingMinutes}',
                    '${e.spLectureMinutes}',
                    '${e.shlokasMemorized}',
                    e.calculatedScore.toStringAsFixed(1),
                  ]).toList(),
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                  headerDecoration: const pw.BoxDecoration(color: PdfColors.deepOrange800),
                  cellAlignment: pw.Alignment.centerLeft,
                ),
                if (stats.counselorNote != null && stats.counselorNote!.isNotEmpty) ...[
                  pw.SizedBox(height: 16),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(color: PdfColors.amber50, border: pw.Border.all(color: PdfColors.amber800)),
                    child: pw.Text('Counselor Remarks: "${stats.counselorNote}"', style: pw.TextStyle(fontSize: 11, fontStyle: pw.FontStyle.italic, color: PdfColors.amber900)),
                  ),
                ],
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(children: [pw.Container(width: 150, height: 1, color: PdfColors.grey600), pw.SizedBox(height: 4), pw.Text("Devotee's Signature")]),
                    pw.Column(children: [pw.Container(width: 150, height: 1, color: PdfColors.grey600), pw.SizedBox(height: 4), pw.Text("Counselor's Blessings")]),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
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
              final badges = _evaluateBadges(stats);

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

                  // Counselor Guidance Note Banner
                  if (stats.counselorNote != null && stats.counselorNote!.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.goldAccent, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.volunteer_activism, color: AppColors.saffronDark, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(AppStrings.tr('counselor_guidance'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.saffronDark)),
                                const SizedBox(height: 4),
                                Text(
                                  '"${stats.counselorNote}"',
                                  style: const TextStyle(fontSize: 13, height: 1.4, fontStyle: FontStyle.italic, color: AppColors.textDark),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Hero Accumulated SP Banner
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

                  // Nistha Growth Trend Card
                  _buildNisthaGrowthCard(stats.recent),
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

                  // Heatmap Grid
                  _buildHeatmapGrid(stats.recent),
                  const SizedBox(height: 18),

                  // PDF Export Button
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.saffronDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.saffronDark),
                    label: Text(AppStrings.tr('export_pdf'), style: const TextStyle(color: AppColors.saffronDark, fontWeight: FontWeight.bold)),
                    onPressed: () => _generatePdfReport(stats),
                  ),
                  const SizedBox(height: 24),

                  // Sacred Milestones & Badges
                  Text(AppStrings.tr('sacred_badges'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: badges.map((b) {
                      return Container(
                        width: MediaQuery.of(context).size.width > 750 ? 360 : double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: b.isUnlocked ? const Color(0xFFFFFBEB) : Colors.white,
                          border: Border.all(
                            color: b.isUnlocked ? const Color(0xFFD97706) : AppColors.borderSubtle,
                            width: b.isUnlocked ? 1.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Text(b.icon, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    isHi ? b.titleHi : b.titleEn,
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: b.isUnlocked ? AppColors.textDark : Colors.grey),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isHi ? b.descHi : b.descEn,
                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (b.isUnlocked)
                              const Icon(Icons.verified, color: AppColors.goldAccent, size: 20),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Recent Offerings
                  Text(AppStrings.tr('recent_offerings'), style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 12),
                  if (stats.recent.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(child: Text(isHi ? 'कोई प्रविष्टि नहीं मिली।' : 'No daily entries recorded yet.')),
                      ),
                    )
                  else
                    ...stats.recent.map((e) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: e.isStreakFreeze ? const Color(0xFFE0F2FE) : AppColors.creamBg,
                            child: Icon(e.isStreakFreeze ? Icons.health_and_safety : Icons.check_circle, color: e.isStreakFreeze ? const Color(0xFF0284C7) : AppColors.tulsiGreen),
                          ),
                          title: Text(e.entryDate, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(e.isStreakFreeze ? 'Pass Day (Streak preserved)' : 'Rounds: ${e.chantingRounds} • Reading: ${e.spBookReadingMinutes}m • Hearing: ${e.spLectureMinutes}m • Shlokas: ${e.shlokasMemorized}'),
                          trailing: Text(
                            '${e.calculatedScore.toStringAsFixed(1)} SP',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark, fontSize: 15),
                          ),
                        ),
                      );
                    }),
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
// 8. DAILY ENTRY FORM (Symmetric Sliders + Streak Freeze Pass)
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
    if (_isStreakFreeze) return 50.0;

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

  void _showDirectValueDialog({
    required String title,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onSubmitted,
  }) {
    final textController = TextEditingController(text: '$currentValue');
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Enter $title'),
          content: TextField(
            controller: textController,
            keyboardType: TextInputType.number,
            autofocus: true,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              labelText: 'Direct Value ($min - $max)',
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () {
                final parsed = int.tryParse(textController.text.trim()) ?? currentValue;
                onSubmitted(parsed.clamp(min, max));
                Navigator.pop(ctx);
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
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
                InkWell(
                  onTap: () => _showDirectValueDialog(
                    title: title,
                    currentValue: value,
                    min: min,
                    max: max,
                    onSubmitted: onChanged,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.creamBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderSubtle),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('$value $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
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

  Widget _timeCard({required String label, required TimeOfDay time, required IconData icon, String? subtitle, required VoidCallback onTap}) {
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
              Row(children: [Icon(icon, color: AppColors.saffronDark, size: 20), const SizedBox(width: 8), Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))]),
              const SizedBox(height: 8),
              Text(formatStr, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 4),
              Text(subtitle ?? 'Tap to change', style: const TextStyle(color: AppColors.saffronDark, fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
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
                Row(
                  children: [
                    Expanded(
                      child: _timeCard(
                        label: AppStrings.tr('wake_time'),
                        time: _wakeUpTime,
                        icon: Icons.wb_sunny_outlined,
                        subtitle: _wakeUpTime.hour < 4 || (_wakeUpTime.hour == 4 && _wakeUpTime.minute <= 30) ? 'Brahma-muhurta' : null,
                        onTap: () async {
                          final picked = await showTimePicker(context: context, initialTime: _wakeUpTime);
                          if (picked != null) setState(() => _wakeUpTime = picked);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _timeCard(
                        label: AppStrings.tr('bed_time'),
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
                _buildSliderStepperCard(
                  title: 'Japa Meditation Rounds',
                  subtitle: 'Target: 16 rounds (Tap number to type)',
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
                  subtitle: 'Target: 30–45 mins (25 SP per 30m)',
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
                  subtitle: 'Target: 30–45 mins (25 SP per 30m)',
                  value: _spLectureMinutes,
                  min: 0,
                  max: 180,
                  step: 5,
                  unit: 'mins',
                  onChanged: (v) => setState(() => _spLectureMinutes = v),
                ),
                const SizedBox(height: 10),
                _buildSliderStepperCard(
                  title: AppStrings.tr('other_hearing'),
                  subtitle: 'Kirtan / Katha (25 SP per 30m)',
                  value: _otherHearingMinutes,
                  min: 0,
                  max: 180,
                  step: 5,
                  unit: 'mins',
                  onChanged: (v) => setState(() => _otherHearingMinutes = v),
                ),
                const SizedBox(height: 10),
                _buildSliderStepperCard(
                  title: AppStrings.tr('shlokas'),
                  subtitle: '+50 SP earned per memorized verse',
                  value: _shlokasMemorized,
                  min: 0,
                  max: 20,
                  step: 1,
                  unit: 'shlokas',
                  onChanged: (v) => setState(() => _shlokasMemorized = v),
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
// 9. SUPER ADMIN CONSOLE
// ============================================================================
class SuperAdminConsoleScreen extends StatefulWidget {
  const SuperAdminConsoleScreen({super.key});

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen> {
  late Future<AdminStats> _adminFuture;
  String _searchFilter = '';

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
          .select('id, full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, role, preacher_id, avatar_badge, date_of_birth, preachers(display_title)')
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
          avatarBadge: map['avatar_badge']?.toString() ?? '📿',
          dateOfBirth: map['date_of_birth']?.toString(),
        );
      }).toList();

      return AdminStats(devotees: devoteesCount, preachers: preachersCount, entries: entriesCount, devoteesList: dList, preachersList: pList);
    } catch (_) {
      return const AdminStats(devotees: 0, preachers: 0, entries: 0, devoteesList: [], preachersList: []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Super Admin Console'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)]),
      body: FutureBuilder<AdminStats>(
        future: _adminFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data ?? const AdminStats(devotees: 0, preachers: 0, entries: 0, devoteesList: [], preachersList: []);

          final filteredDevotees = stats.devoteesList.where((d) {
            if (_searchFilter.isEmpty) return true;
            final query = _searchFilter.toLowerCase();
            return d.fullName.toLowerCase().contains(query) || d.email.toLowerCase().contains(query) || d.phoneNumber.contains(query);
          }).toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextField(
                decoration: InputDecoration(hintText: 'Search devotees...', prefixIcon: const Icon(Icons.search, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                onChanged: (val) => setState(() => _searchFilter = val.trim()),
              ),
              const SizedBox(height: 16),
              ...filteredDevotees.map((d) => Card(
                child: ListTile(
                  title: Text('${d.fullName} ${d.avatarBadge}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Email: ${d.email} • Role: ${d.role} • Preacher: ${d.preacherTitle}'),
                ),
              )),
            ],
          );
        },
      ),
    );
  }
}

// ============================================================================
// 10. PREACHER CONSOLE (Birthday Display, Direct Calls & WhatsApp)
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
  String _search = '';
  final DateTime _reportMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

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
            .select('id, full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, role, preacher_id, avatar_badge, date_of_birth, sadhana_entries(entry_date)')
            .eq('preacher_id', _preacherId!)
            .order('full_name', ascending: true);

        final list = (res as List<dynamic>).map((e) {
          final m = e as Map<String, dynamic>;
          final entries = (m['sadhana_entries'] as List<dynamic>?) ?? [];
          String? lastDate;
          if (entries.isNotEmpty) {
            entries.sort((a, b) => (b['entry_date'] ?? '').toString().compareTo((a['entry_date'] ?? '').toString()));
            lastDate = entries.first['entry_date']?.toString();
          }

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
            latestEntryDate: lastDate,
            avatarBadge: m['avatar_badge']?.toString() ?? '📿',
            dateOfBirth: m['date_of_birth']?.toString(),
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

  int _calculateDaysInactive(String? latestDate) {
    if (latestDate == null || latestDate.isEmpty) return 999;
    try {
      final last = DateTime.parse(latestDate);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day).difference(DateTime(last.year, last.month, last.day)).inDays;
    } catch (_) {
      return 999;
    }
  }

  void _callDevotee(String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleanPhone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: cleanPhone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _openWhatsAppBlank(String rawPhone) async {
    String cleanDigits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.isEmpty) return;
    if (cleanDigits.length == 10) cleanDigits = '91$cleanDigits';
    final uri = Uri.parse('https://wa.me/$cleanDigits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showCounseleeMonthlyReport(DevoteeProfileItem devotee) {
    DateTime selectedMonth = DateTime(_reportMonth.year, _reportMonth.month, 1);
    final noteCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startStr = DateFormat('yyyy-MM-dd').format(selectedMonth);
            final nextMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
            final endStr = DateFormat('yyyy-MM-dd').format(nextMonth.subtract(const Duration(days: 1)));
            final monthKey = DateFormat('yyyy-MM').format(selectedMonth);

            return Container(
              height: MediaQuery.of(context).size.height * 0.88,
              padding: const EdgeInsets.all(20),
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
                            Text('${devotee.fullName} ${devotee.avatarBadge}', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                            Text('Sadhana Report for ${DateFormat('MMMM yyyy').format(selectedMonth)}', style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note, color: AppColors.saffronDark, size: 28),
                        tooltip: 'Leave Counselor Guidance Note',
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (dCtx) => AlertDialog(
                              title: Text('Guidance for ${devotee.fullName}'),
                              content: TextField(
                                controller: noteCtrl,
                                maxLines: 4,
                                decoration: const InputDecoration(hintText: 'Enter spiritual guidance for this month...', border: OutlineInputBorder()),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                                  onPressed: () async {
                                    final text = noteCtrl.text.trim();
                                    if (text.isEmpty) return;
                                    final user = supabase.auth.currentUser;
                                    await supabase.from('counselor_notes').upsert({
                                      'devotee_id': devotee.id,
                                      'preacher_id': user?.id ?? '',
                                      'month_year': monthKey,
                                      'note_text': text,
                                      'updated_at': DateTime.now().toIso8601String(),
                                    }, onConflict: 'devotee_id, month_year');
                                    if (dCtx.mounted) Navigator.pop(dCtx);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Guidance note saved for devotee!')));
                                    }
                                  },
                                  child: const Text('Save Note'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  Expanded(
                    child: FutureBuilder(
                      future: supabase
                          .from('sadhana_entries')
                          .select('entry_date, wake_up_time, bed_time, chanting_rounds, sp_book_reading_minutes, sp_lecture_hearing_minutes, other_hearing_minutes, shlokas_memorized, calculated_score')
                          .eq('user_id', devotee.id)
                          .gte('entry_date', startStr)
                          .lte('entry_date', endStr)
                          .order('entry_date', ascending: true),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                        final List<dynamic> records = (snapshot.data as List<dynamic>?) ?? [];
                        if (records.isEmpty) return Center(child: Text('No sadhana logs found for ${DateFormat('MMMM yyyy').format(selectedMonth)}.'));

                        double totalSP = 0;
                        int totalRounds = 0;
                        for (final r in records) {
                          totalSP += (r['calculated_score'] as num?)?.toDouble() ?? 0.0;
                          totalRounds += (r['chanting_rounds'] as num?)?.toInt() ?? 0;
                        }

                        return Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: AppColors.creamBg, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Text('Days: ${records.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                  Text('Rounds: $totalRounds', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                                  Text('SP: ${totalSP.toStringAsFixed(1)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.tulsiGreen)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                itemCount: records.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (context, idx) {
                                  final rec = records[idx] as Map<String, dynamic>;
                                  final wake = rec['wake_up_time']?.toString() ?? '';
                                  final wakeDisplay = wake.length >= 5 ? wake.substring(0, 5) : wake;
                                  return ListTile(
                                    title: Text(rec['entry_date']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    subtitle: Text('Wake: $wakeDisplay • Japa: ${rec['chanting_rounds']} rds • Read: ${rec['sp_book_reading_minutes']}m • Hear: ${rec['sp_lecture_hearing_minutes']}m'),
                                    trailing: Text('${(rec['calculated_score'] as num?)?.toStringAsFixed(1) ?? '0'} SP', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _counselees.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return c.fullName.toLowerCase().contains(q) || c.email.toLowerCase().contains(q) || c.phoneNumber.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Preacher Console'), actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchCounselees)]),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('My Counselees (${_counselees.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(hintText: 'Search counselees...', prefixIcon: const Icon(Icons.search, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No counselees found.')))
                else
                  ...filtered.map((c) {
                    final daysInactive = _calculateDaysInactive(c.latestEntryDate);
                    final isInactive = daysInactive >= 3;

                    String birthdayText = 'Birthday: Not set';
                    if (c.dateOfBirth != null && c.dateOfBirth!.isNotEmpty) {
                      try {
                        birthdayText = '🎂 Birthday: ${DateFormat('dd MMMM').format(DateTime.parse(c.dateOfBirth!))}';
                      } catch (_) {}
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        onTap: () => _showCounseleeMonthlyReport(c),
                        leading: CircleAvatar(
                          backgroundColor: isInactive ? AppColors.sacredRed : AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          child: Text(c.fullName.isNotEmpty ? c.fullName[0].toUpperCase() : 'D'),
                        ),
                        title: Row(
                          children: [
                            Flexible(child: Text('${c.fullName} ${c.avatarBadge}', style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                            if (isInactive) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(6), border: Border.all(color: AppColors.sacredRed)),
                                child: Text(
                                  daysInactive > 60 ? 'Inactive' : '⚠️ ${daysInactive}d Missed',
                                  style: const TextStyle(color: AppColors.sacredRed, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                        subtitle: Text('Phone: ${c.phoneNumber.isNotEmpty ? c.phoneNumber : "No phone"}\n$birthdayText\nLatest: ${c.latestEntryDate ?? "No entries yet"}'),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.call, color: AppColors.tulsiGreen), tooltip: 'Direct Call', onPressed: () => _callDevotee(c.phoneNumber)),
                            IconButton(icon: const Icon(Icons.chat_bubble_outline, color: Color(0xFF25D366)), tooltip: 'WhatsApp Chat', onPressed: () => _openWhatsAppBlank(c.phoneNumber)),
                            const Icon(Icons.chevron_right, color: Colors.grey),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
    );
  }
}

// ============================================================================
// 11. TOP RANKINGS SCREEN (Circle Filter & Badges)
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
                              Text(item.avatarBadge, style: const TextStyle(fontSize: 16)),
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
// 12. WEB APK DOWNLOAD BANNER (Hidden on native APKs)
// ============================================================================
class WebApkDownloadBanner extends StatelessWidget {
  const WebApkDownloadBanner({super.key});

  void _triggerDownloadAndShowDialog(BuildContext context) async {
    final apkUri = Uri.base.resolve('downloads/my_sadhna.apk');
    try {
      await launchUrl(
        apkUri,
        mode: LaunchMode.externalApplication,
        webOnlyWindowName: '_self',
      );
    } catch (_) {
      await launchUrl(apkUri, webOnlyWindowName: '_blank');
    }

    if (context.mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.tulsiGreen, size: 28),
              SizedBox(width: 10),
              Text('Thanks for Downloading!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Your download for My Sadhna Android App has started.',
                style: TextStyle(fontSize: 14, color: AppColors.textDark),
              ),
              const SizedBox(height: 16),
              const Text(
                'How to install:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.saffronDark),
              ),
              const SizedBox(height: 8),
              _buildStepRow('1', 'Open the downloaded my_sadhna.apk file from your notification bar or Downloads folder.'),
              const SizedBox(height: 6),
              _buildStepRow('2', 'If prompted by Chrome or Files, tap Settings and allow "Install unknown apps".'),
              const SizedBox(height: 6),
              _buildStepRow('3', 'Tap Install to complete setup and start offering your daily sadhana.'),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronDark,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it!'),
            ),
          ],
        ),
      );
    }
  }

  static Widget _buildStepRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.saffronPrimary.withValues(alpha: 0.2),
          child: Text(number, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12, height: 1.35, color: AppColors.textMuted))),
      ],
    );
  }

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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: const Icon(Icons.android, color: AppColors.tulsiGreen, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Get the Android App',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark),
                ),
                SizedBox(height: 2),
                Text(
                  'Install for offline sadhana tracking and instant daily access.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tulsiGreen,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Download APK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            onPressed: () => _triggerDownloadAndShowDialog(context),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 13. PROFILE & SETTINGS (Tap to edit DOB directly for existing profiles)
// ============================================================================
class ProfileDashboardScreen extends StatefulWidget {
  const ProfileDashboardScreen({super.key});

  @override
  State<ProfileDashboardScreen> createState() => _ProfileDashboardScreenState();
}

class _ProfileDashboardScreenState extends State<ProfileDashboardScreen> {
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;

  final List<String> _sacredBadges = ['📿', '🌱', '🔥', '👑', '🪷', '🦚', '☀️', '🕊️'];

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final res = await supabase.from('profiles').select('full_name, email, phone_number, profession, education, address, avatar_badge, date_of_birth, hide_name_on_leaderboard, preachers(display_title, code_suffix)').eq('id', user.id).single();
        if (mounted) setState(() { _profileData = res; _isLoading = false; });
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _updateDateOfBirth() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    DateTime initial = DateTime(2000, 1, 1);
    final currentStr = _profileData?['date_of_birth']?.toString();
    if (currentStr != null && currentStr.isNotEmpty) {
      final parsed = DateTime.tryParse(currentStr);
      if (parsed != null) initial = parsed;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      final dobStr = DateFormat('yyyy-MM-dd').format(picked);
      try {
        await supabase.from('profiles').update({'date_of_birth': dobStr}).eq('id', user.id);
        HapticFeedback.mediumImpact();
        setState(() {
          if (_profileData != null) _profileData!['date_of_birth'] = dobStr;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: AppColors.tulsiGreen, content: Text('Date of birth updated to ${DateFormat('dd MMMM yyyy').format(picked)}!')),
          );
        }
      } catch (_) {}
    }
  }

  Future<void> _updateAvatarBadge(String badge) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    try {
      await supabase.from('profiles').update({'avatar_badge': badge}).eq('id', user.id);
      HapticFeedback.selectionClick();
      setState(() {
        if (_profileData != null) _profileData!['avatar_badge'] = badge;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.tulsiGreen, content: Text('Sacred emblem updated to $badge')));
      }
    } catch (_) {}
  }

  void _showBadgePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Your Sacred Emblem / Tilak Badge', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('This emblem will show beside your name in circles and standings.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _sacredBadges.map((badge) {
                final isSelected = (_profileData?['avatar_badge'] ?? '📿') == badge;
                return InkWell(
                  onTap: () {
                    Navigator.pop(ctx);
                    _updateAvatarBadge(badge);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.saffronPrimary.withValues(alpha: 0.15) : AppColors.creamBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.saffronDark : AppColors.borderSubtle, width: isSelected ? 2 : 1),
                    ),
                    child: Text(badge, style: const TextStyle(fontSize: 26)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final pr = _profileData?['preachers'] as Map<String, dynamic>?;
    final currentBadge = _profileData?['avatar_badge']?.toString() ?? '📿';
    final dobRaw = _profileData?['date_of_birth']?.toString();
    String dobDisplay = 'Tap to set Birthday';
    if (dobRaw != null && dobRaw.isNotEmpty) {
      try {
        dobDisplay = DateFormat('dd MMMM yyyy').format(DateTime.parse(dobRaw));
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppStrings.tr('profile'))),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Center(
                child: Stack(
                  children: [
                    const MSMonogramLogo(size: 80),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _showBadgePickerSheet,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: Text(currentBadge, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_profileData?['full_name'] ?? 'Devotee', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    InkWell(onTap: _showBadgePickerSheet, child: Text(currentBadge, style: const TextStyle(fontSize: 20))),
                  ],
                ),
              ),
              Center(child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 14))),
              const SizedBox(height: 20),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Emblem Badge', currentBadge, onTap: _showBadgePickerSheet, showEditIcon: true),
                      const Divider(),
                      _row('Date of Birth', dobDisplay, onTap: _updateDateOfBirth, showEditIcon: true),
                      const Divider(),
                      _row('Phone', _profileData?['phone_number'] ?? 'Not set'),
                      const Divider(),
                      _row('Profession', _profileData?['profession'] ?? 'Not set'),
                      const Divider(),
                      _row('Address', _profileData?['address'] ?? 'Not set'),
                      const Divider(),
                      _row('Preacher', pr != null ? '${pr['display_title']} (${pr['code_suffix']})' : 'None'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const WebApkDownloadBanner(),
              const SizedBox(height: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.sacredRed,
                  side: const BorderSide(color: AppColors.sacredRed),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async => await supabase.auth.signOut(),
                child: const Text('Sign Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {VoidCallback? onTap, bool showEditIcon = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: onTap != null ? AppColors.saffronDark : AppColors.textDark,
                  ),
                ),
                if (showEditIcon) ...[
                  const SizedBox(width: 6),
                  const Icon(Icons.edit, size: 14, color: AppColors.saffronDark),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
