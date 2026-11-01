import 'dart:async';
import 'dart:math';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

const int kCurrentInstalledVersionCode = 20; // Match the new build number (+20)
const String kVercelApkDownloadUrl = 'https://my-sadhna.vercel.app/downloads/my_sadhna.apk';

final supabase = Supabase.instance.client;
final ValueNotifier<String> appLanguage = ValueNotifier<String>('en');




String formatIndianNumber(num count) {
  if (count >= 10000000) {
    return '${(count / 10000000).toStringAsFixed(1)} Cr';
  } else if (count >= 100000) {
    return '${(count / 100000).toStringAsFixed(1)} L';
  } else if (count >= 1000) {
    return '${(count / 1000).toStringAsFixed(1)} K';
  }
  return count.toString();
}

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
  final List<DevoteeProfileItem> devoteesList;
  final List<PreacherItem> preachersList;

  const AdminStats({
    required this.devotees,
    required this.preachers,
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
  final String? preacherId;
  final String preacherTitle;
  final String preacherSuffix;
  final double totalSp;
  double get totalSP => totalSp;
  final int totalRounds;
  final bool isCurrentUser;
  final String avatarBadge;

  RankingItem({
    required this.rank,
    required this.userId,
    required this.devoteeName,
    this.preacherId,
    required this.preacherTitle,
    required this.preacherSuffix,
    required this.totalSp,
    required this.totalRounds,
    required this.isCurrentUser,
    required this.avatarBadge,
  });

  factory RankingItem.fromMap(Map<String, dynamic> map) {
    return RankingItem(
      rank: int.tryParse(map['rank']?.toString() ?? '1') ?? 1,
      userId: map['user_id']?.toString() ?? '',
      devoteeName: map['devotee_name']?.toString() ?? 'Devotee',
      preacherId: map['preacher_id']?.toString(),
      preacherTitle: map['preacher_title']?.toString() ?? 'General Circle',
      preacherSuffix: map['preacher_suffix']?.toString() ?? 'GEN',
      totalSp: double.tryParse(map['total_sp']?.toString() ?? '0') ?? 0.0,
      totalRounds: int.tryParse(map['total_rounds']?.toString() ?? '0') ?? 0,
      isCurrentUser: map['is_current_user'] == true,
      avatarBadge: map['avatar_badge']?.toString() ?? '📿',
    );
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init: $e');
  }

  await Supabase.initialize(
    url: 'https://mtduhncyvcmzgekekieq.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10ZHVobmN5dmNtemdla2VraWVxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyODA5OTcsImV4cCI6MjEwODg1Njk5N30.QFJvYZDEyPqeQkWJyBV1r8djjkkXXoY3LGuuz4EpdxU',
  );

  
  // Request notification permissions for Android 13+ and iOS
  try {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      final user = supabase.auth.currentUser;
      if (token != null && user != null) {
        await supabase.from('profiles').update({'fcm_token': token}).eq('id', user.id);
      }
    }
  } catch (e) {
    debugPrint('FCM permission error: $e');
  }

  runApp(const MySadhnaApp());
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
              titleTextStyle: TextStyle(color: AppColors.textDark, fontSize: 19, fontWeight: FontWeight.bold),
              iconTheme: IconThemeData(color: AppColors.textDark),
            ),
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class NotificationBellIcon extends StatefulWidget {
  const NotificationBellIcon({super.key});

  @override
  State<NotificationBellIcon> createState() => _NotificationBellIconState();
}

class _NotificationBellIconState extends State<NotificationBellIcon> {
  int _unreadCount = 0;
  int _totalFeedCount = 0;

  @override
  void initState() {
    super.initState();
    _checkNotifications();
  }

  Future<void> _checkNotifications() async {
    try {
      final res = await supabase.rpc('get_user_notification_feed');
      if (mounted && res is List) {
        _totalFeedCount = res.length;
        final prefs = await SharedPreferences.getInstance();
        final lastSeenCount = prefs.getInt('last_seen_notice_count') ?? 0;
        final unread = _totalFeedCount > lastSeenCount ? (_totalFeedCount - lastSeenCount) : 0;
        setState(() => _unreadCount = unread);
      }
    } catch (_) {}
  }

  void _openInbox() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_seen_notice_count', _totalFeedCount);
    setState(() => _unreadCount = 0);
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationInboxSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded, size: 26),
          tooltip: 'Noticeboard',
          onPressed: _openInbox,
        ),
        if (_unreadCount > 0)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Color(0xFFDC2626), shape: BoxShape.circle),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                _unreadCount > 9 ? '9+' : '$_unreadCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

class NotificationInboxSheet extends StatefulWidget {
  const NotificationInboxSheet({super.key});

  @override
  State<NotificationInboxSheet> createState() => _NotificationInboxSheetState();
}

class _NotificationInboxSheetState extends State<NotificationInboxSheet> {
  late Future<List<dynamic>> _feedFuture;

  @override
  void initState() {
    super.initState();
    _feedFuture = _loadFeed();
  }

  Future<List<dynamic>> _loadFeed() async {
    try {
      final res = await supabase.rpc('get_user_notification_feed');
      return (res as List<dynamic>?) ?? [];
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 6),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: const [
                    Icon(Icons.campaign, color: Color(0xFFD97706)),
                    SizedBox(width: 8),
                    Text('Announcements & Notices', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _feedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snapshot.data ?? [];
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No announcements right now.', style: TextStyle(color: Colors.grey, fontSize: 14)),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = list[index];
                    final title = item['title']?.toString() ?? 'Notice';
                    final body = item['body']?.toString() ?? '';
                    final sender = item['sender_name']?.toString() ?? 'Admin';
                    final dateStr = item['created_at']?.toString() ?? '';
                    String displayDate = '';
                    if (dateStr.isNotEmpty) {
                      try {
                        final dt = DateTime.parse(dateStr).toLocal();
                        displayDate = '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      } catch (_) {
                        displayDate = dateStr;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF92400E))),
                              ),
                              Text(displayDate, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(body, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.person_pin, size: 14, color: Color(0xFFD97706)),
                              const SizedBox(width: 4),
                              Text(sender, style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFF78350F))),
                            ],
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
    );
  }
}

class NotificationBroadcastDialog extends StatefulWidget {
  final bool isAdmin;
  final String? preacherId;
  const NotificationBroadcastDialog({super.key, required this.isAdmin, this.preacherId});

  @override
  State<NotificationBroadcastDialog> createState() => _NotificationBroadcastDialogState();
}

class _NotificationBroadcastDialogState extends State<NotificationBroadcastDialog> {
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTarget = 'all';
  String? _selectedPreacherId;
  List<dynamic> _preachersList = [];
  bool _isLoadingPreachers = false;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.isAdmin) {
      _selectedTarget = 'all';
      _loadPreachersList();
    } else {
      _selectedTarget = 'my_counsellees';
    }
  }

  Future<void> _loadPreachersList() async {
    setState(() => _isLoadingPreachers = true);
    try {
      final res = await supabase.from('profiles').select('id, full_name').eq('role', 'preacher').order('full_name');
      if (mounted) {
        setState(() {
          _preachersList = (res as List<dynamic>?) ?? [];
          if (_preachersList.isNotEmpty) {
            _selectedPreacherId = _preachersList.first['id']?.toString();
          }
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingPreachers = false);
  }

  Future<void> _sendNotification() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();

    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter both title and message')));
      return;
    }

    setState(() => _isSending = true);

    try {
      final targetPreacherId = widget.isAdmin
          ? (_selectedTarget == 'specific_preacher_counsellees' ? _selectedPreacherId : widget.preacherId)
          : supabase.auth.currentUser?.id;

      final res = await supabase.rpc(
        'get_broadcast_tokens',
        params: {
          'p_target_group': _selectedTarget,
          'p_target_preacher_id': targetPreacherId,
        },
      );

      final tokens = (res as List<dynamic>?)
              ?.map((e) => e['fcm_token']?.toString())
              .where((t) => t != null && t.isNotEmpty)
              .cast<String>()
              .toSet()
              .toList() ?? [];

      await supabase.from('notification_broadcasts').insert({
        'sender_id': supabase.auth.currentUser?.id,
        'target_group': _selectedTarget,
        'target_preacher_id': targetPreacherId,
        'title': title,
        'body': body,
        'recipient_count': tokens.length,
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Notice broadcasted successfully! (${tokens.length} active push targets)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.campaign, color: Color(0xFFD97706)),
          SizedBox(width: 8),
          Text('Broadcast Notice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.isAdmin) ...[
              const Text('Target Audience:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedTarget,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('1. All Users (Entire App)')),
                  DropdownMenuItem(value: 'all_preachers', child: Text('2. All Preachers Only')),
                  DropdownMenuItem(value: 'all_counsellees', child: Text('3. All Counselees Across Circles')),
                  DropdownMenuItem(value: 'specific_preacher_counsellees', child: Text('4. Counselees of One Preacher')),
                  DropdownMenuItem(value: 'my_counsellees', child: Text('5. My Own Circle Devotees')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTarget = val);
                },
              ),
              if (_selectedTarget == 'specific_preacher_counsellees') ...[
                const SizedBox(height: 12),
                const Text('Choose Preacher:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                _isLoadingPreachers
                    ? const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()))
                    : DropdownButtonFormField<String>(
                        initialValue: _selectedPreacherId,
                        isExpanded: true,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: _preachersList.map((p) => DropdownMenuItem<String>(value: p['id'].toString(), child: Text(p['full_name']?.toString() ?? 'Preacher'))).toList(),
                        onChanged: (val) => setState(() => _selectedPreacherId = val),
                      ),
              ],
              const SizedBox(height: 14),
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.amber.shade200)),
                child: const Text('Audience: All Devotees in Your Circle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
              ),
              const SizedBox(height: 14),
            ],
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Notice Title', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _bodyController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Notice Message', border: OutlineInputBorder()),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: _isSending ? null : () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton.icon(
          onPressed: _isSending ? null : _sendNotification,
          icon: _isSending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send, size: 16),
          label: Text(_isSending ? 'Sending...' : 'Send'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
        ),
      ],
    );
  }
}

List<Widget> _buildCommonAppBarActions(BuildContext context, String currentRole) {
  final isPrivileged = currentRole == 'admin' || currentRole == 'super_admin' || currentRole == 'preacher';
  return [
    const NotificationBellIcon(),
    if (isPrivileged)
      IconButton(
        icon: const Icon(Icons.campaign_outlined),
        tooltip: 'Send Push Notification',
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => NotificationBroadcastDialog(
              isAdmin: currentRole == 'admin' || currentRole == 'super_admin',
              preacherId: supabase.auth.currentUser?.id,
            ),
          );
        },
      ),
  ];
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
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

class OnboardingDetailsScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const OnboardingDetailsScreen({super.key, required this.onCompleted});

  @override
  State<OnboardingDetailsScreen> createState() => _OnboardingDetailsScreenState();
}

class _OnboardingDetailsScreenState extends State<OnboardingDetailsScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _professionController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedPreacherId;
  List<dynamic> _preachers = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final profile = await supabase.from('profiles').select('full_name, phone_number, profession, address, preacher_id').eq('id', user.id).maybeSingle();
        if (profile != null) {
          _nameController.text = profile['full_name']?.toString() ?? user.userMetadata?['name'] ?? '';
          _phoneController.text = profile['phone_number']?.toString() ?? '';
          _professionController.text = profile['profession']?.toString() ?? '';
          _addressController.text = profile['address']?.toString() ?? '';
          _selectedPreacherId = profile['preacher_id']?.toString();
        }
      }

      final pRes = await supabase.from('preachers').select('id, display_title, code_suffix').eq('is_active', true);
      setState(() {
        _preachers = (pRes as List<dynamic>?) ?? [];
        if (_selectedPreacherId == null && _preachers.isNotEmpty) {
          _selectedPreacherId = _preachers.first['id'].toString();
        }
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveDetails() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your full name')));
      return;
    }
    if (_selectedPreacherId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select your assigned preacher')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final uid = supabase.auth.currentUser!.id;
      await supabase.from('profiles').update({
        'full_name': name,
        'phone_number': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        'profession': _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
        'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
        'preacher_id': _selectedPreacherId,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', uid);

      widget.onCompleted();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile'), automaticallyImplyLeading: false),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Hare Krishna! 🙏', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
              const SizedBox(height: 6),
              const Text('Please set your details and assigned counselor before entering.', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 24),
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Devotee / Full Name *', border: OutlineInputBorder(), prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 16),
              const Text('Assigned Preacher / Counselor *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _selectedPreacherId,
                isExpanded: true,
                decoration: const InputDecoration(border: OutlineInputBorder(), prefixIcon: Icon(Icons.temple_hindu)),
                items: _preachers.map((p) => DropdownMenuItem<String>(value: p['id'].toString(), child: Text('${p['display_title']} (${p['code_suffix']})'))).toList(),
                onChanged: (val) => setState(() => _selectedPreacherId = val),
              ),
              const SizedBox(height: 16),
              TextField(controller: _phoneController, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone Number (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 16),
              TextField(controller: _professionController, decoration: const InputDecoration(labelText: 'Profession (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.work_outline))),
              const SizedBox(height: 16),
              TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'City / Address (Optional)', border: OutlineInputBorder(), prefixIcon: Icon(Icons.location_on_outlined))),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveDetails,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFD97706), foregroundColor: Colors.white),
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text('Continue to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
  String? _updateNoticeMessage;
  String? _updateNoticeUrl;

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
    _checkPreLoginAnnouncements();
  }

  Future<void> _checkPreLoginAnnouncements() async {
    try {
      final res = await supabase
          .from('announcements')
          .select()
          .eq('type', 'update')
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (res != null && mounted) {
        final int targetBuild = res['min_version_code'] ?? 20;
        if (kCurrentInstalledVersionCode < targetBuild) {
          setState(() {
            _updateNoticeMessage = res['message'] ?? 'A new version is available.';
            _updateNoticeUrl = res['action_url'] ?? kVercelApkDownloadUrl;
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPreachers() async {
    try {
      final response = await supabase.from('preachers').select('id, code_suffix, display_title, is_active').eq('is_active', true);
      final List<dynamic> raw = response as List<dynamic>;
      setState(() {
        _preachersList = raw.map((e) => PreacherItem.fromMap(e as Map<String, dynamic>)).toList();
        if (_preachersList.isNotEmpty) _selectedPreacherId = _preachersList.first.id;
      });
    } catch (_) {}
  }

  Future<void> _handleGoogleSignIn() async {
    try {
      setState(() => _isLoading = true);
      await supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'mysadhna://login-callback',
        authScreenLaunchMode: kIsWeb
            ? LaunchMode.platformDefault
            : LaunchMode.inAppBrowserView,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString())),
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
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text(e.toString().replaceAll('Exception: ', ''))));
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            constraints: BoxConstraints(maxWidth: isDesktop ? 480 : size.width),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                const Text('My Sadhna', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                const Text('Daily Sadhana & Sukriti Tracker', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
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
                  if (_updateNoticeMessage != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      border: Border.all(color: AppColors.saffronDark),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _updateNoticeMessage!,
                          style: const TextStyle(color: Color(0xFF92400E), fontSize: 13, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.saffronDark,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Update App Now'),
                          onPressed: () async {
                            if (_updateNoticeUrl != null) {
                              final uri = Uri.parse(_updateNoticeUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri, mode: LaunchMode.externalApplication);
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(labelText: 'Email Address', prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
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
                          TextFormField(controller: _nameController, decoration: InputDecoration(labelText: 'Full / Initiated Name', prefixIcon: const Icon(Icons.person_outline, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                          const SizedBox(height: 14),
                          TextFormField(controller: _phoneController, decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                          const SizedBox(height: 14),
                          TextFormField(controller: _emailController, decoration: InputDecoration(labelText: 'Email Address', prefixIcon: const Icon(Icons.email_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscureRegisterPassword,
                            decoration: InputDecoration(
                              labelText: 'Password (6+ chars)',
                              prefixIcon: const Icon(Icons.lock_outline, color: AppColors.saffronDark),
                              suffixIcon: IconButton(icon: Icon(_obscureRegisterPassword ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted), onPressed: () => setState(() => _obscureRegisterPassword = !_obscureRegisterPassword)),
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
                          Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: AppColors.borderSubtle)),
                            child: ListTile(
                              leading: const Icon(Icons.cake_outlined, color: AppColors.saffronDark),
                              title: Text(_selectedDob == null ? 'Date of Birth (DOB)' : DateFormat('dd MMMM yyyy').format(_selectedDob!)),
                              trailing: const Icon(Icons.calendar_month, color: AppColors.saffronDark),
                              onTap: () async {
                                final picked = await showDatePicker(context: context, initialDate: DateTime(2000, 1, 1), firstDate: DateTime(1940), lastDate: DateTime.now());
                                if (picked != null) setState(() => _selectedDob = picked);
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(controller: _professionController, decoration: InputDecoration(labelText: 'Profession', prefixIcon: const Icon(Icons.work_outline, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                          const SizedBox(height: 14),
                          TextFormField(controller: _educationController, decoration: InputDecoration(labelText: 'Qualification', prefixIcon: const Icon(Icons.school, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                          const SizedBox(height: 14),
                          TextFormField(controller: _addressController, decoration: InputDecoration(labelText: 'City / Address', prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
                        ],
                      ),
                    )
                  else
                    DropdownButtonFormField<String>(
                      initialValue: _selectedPreacherId,
                      decoration: InputDecoration(labelText: 'Assigned Preacher', border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)), prefixIcon: const Icon(Icons.temple_hindu_outlined, color: AppColors.saffronDark)),
                      items: _preachersList.map((p) => DropdownMenuItem<String>(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))).toList(),
                      onChanged: (val) => setState(() => _selectedPreacherId = val),
                    ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary),
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
                    child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(_isLoginMode ? 'Sign In' : (_currentStep < 2 ? 'Next Step' : 'Complete Registration'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 46), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  icon: const Icon(Icons.account_circle, color: AppColors.saffronDark),
                  label: const Text('One-Tap Google Sign-In', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                  onPressed: _isLoading ? null : _handleGoogleSignIn,
                ),
                if (!_isLoginMode && _currentStep > 0)
                  TextButton(onPressed: () => setState(() => _currentStep--), child: const Text('Back to previous step', style: TextStyle(color: AppColors.textMuted))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MainNavigationScaffold extends StatefulWidget {
  const MainNavigationScaffold({super.key});

  @override
  State<MainNavigationScaffold> createState() => _MainNavigationScaffoldState();
}

class _MainNavigationScaffoldState extends State<MainNavigationScaffold> {
  int _currentIndex = 0;
  String _userRole = 'counselee';
  bool _isLoading = true;
  bool _needsOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkRoleAndProfile();
  }

  Future<void> _checkRoleAndProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final profile = await supabase.from('profiles').select('role, preacher_id').eq('id', user.id).maybeSingle();
        if (profile != null) {
          final role = profile['role']?.toString() ?? 'counselee';
          final pId = profile['preacher_id']?.toString();
          setState(() {
            _userRole = role;
            _needsOnboarding = (role == 'counselee' && (pId == null || pId.isEmpty));
            _isLoading = false;
          });
          return;
        }
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    if (_needsOnboarding) {
      return OnboardingDetailsScreen(
        onCompleted: () => setState(() => _needsOnboarding = false),
      );
    }

    final bool isSuperAdmin = _userRole == 'super_admin' || _userRole == 'admin';
    final bool isPreacher = _userRole == 'preacher';

    List<Widget> screens;
    List<NavigationDestination> destinations;

    if (isSuperAdmin) {
      screens = [
        SuperAdminConsoleScreen(userRole: _userRole),
        LeaderboardScreen(userRole: _userRole),
        ProfileDashboardScreen(userRole: _userRole),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.admin_panel_settings_outlined), selectedIcon: Icon(Icons.admin_panel_settings, color: AppColors.saffronDark), label: 'Admin'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    } else if (isPreacher) {
      screens = [
        PreacherConsoleScreen(userRole: _userRole),
        LeaderboardScreen(userRole: _userRole),
        ProfileDashboardScreen(userRole: _userRole),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.temple_hindu_outlined), selectedIcon: Icon(Icons.temple_hindu, color: AppColors.saffronDark), label: 'Counselees'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    } else {
      screens = [
        DevoteeSelfDashboardScreen(userRole: _userRole),
        LeaderboardScreen(userRole: _userRole),
        ProfileDashboardScreen(userRole: _userRole),
      ];
      destinations = const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home, color: AppColors.saffronDark), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events, color: AppColors.saffronDark), label: 'Standings'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person, color: AppColors.saffronDark), label: 'Profile'),
      ];
    }

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        indicatorColor: AppColors.saffronPrimary.withValues(alpha: 0.2),
        destinations: destinations,
      ),
    );
  }
}

class DevoteeSelfDashboardScreen extends StatefulWidget {
  final String userRole;
  const DevoteeSelfDashboardScreen({super.key, required this.userRole});

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
    setState(() => _statsFuture = _fetchPersonalStats(user?.id));
  }

  Future<PersonalStats> _fetchPersonalStats(String? userId) async {
    if (userId == null) {
      return const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
    try {
      final userProf = await supabase.from('profiles').select('full_name, preacher_id, avatar_badge, date_of_birth, preachers(display_title)').eq('id', userId).single();
      final pTitle = (userProf['preachers'] as Map<String, dynamic>?)?['display_title']?.toString();
      final pId = userProf['preacher_id']?.toString();
      final badge = userProf['avatar_badge']?.toString() ?? '📿';
      final dob = userProf['date_of_birth']?.toString();

      final res = await supabase
          .from('sadhana_entries')
          .select('id, entry_date, wake_up_time, bed_time, chanting_rounds, sp_book_reading_minutes, sp_lecture_hearing_minutes, other_hearing_minutes, shlokas_memorized, calculated_score, is_streak_freeze')
          .eq('user_id', userId)
          .order('entry_date', ascending: false)
          .limit(30);

      final List<dynamic> raw = (res as List<dynamic>?) ?? [];
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
        if (data.entryDate == todayStr) todayRecord = data;
      }

      int currentStreak = 0;
      DateTime checkDate = DateTime.now();
      if (todayRecord == null) checkDate = checkDate.subtract(const Duration(days: 1));

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
        counselorTitle: pTitle,
        counselorId: pId,
        avatarBadge: badge,
        dateOfBirth: dob,
      );
    } catch (_) {
      return const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);
    }
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.borderSubtle)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Monthly Sadhana Heatmap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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

              return Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: cellColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderCol, width: 1.2)),
                child: Text('$dayNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: entry != null ? AppColors.textDark : Colors.black45)),
              );
            }),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Sadhna Journey'),
        actions: [
          ..._buildCommonAppBarActions(context, widget.userRole),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: FutureBuilder<PersonalStats>(
            future: _statsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final stats = snapshot.data ?? const PersonalStats(totalSP: 0, avgSP: 0, totalRounds: 0, count: 0, currentStreak: 0, longestStreak: 0, hasLoggedToday: false, todayEntry: null, recent: []);

              final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
              final yestStr = DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 1)));
              final hasToday = stats.recent.any((e) => e.entryDate == todayStr);
              final hasYest = stats.recent.any((e) => e.entryDate == yestStr);
              final bool bothSubmitted = hasToday && hasYest;
              final namesCount = stats.totalRounds * 1728;

              
             return RefreshIndicator(
                onRefresh: () async {
                  _refreshStats();
                  await _statsFuture;
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.saffronPrimary, AppColors.saffronDark]),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('ACCUMULATED SUKRITI POINTS', style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(stats.totalSP.toStringAsFixed(0), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900)),
                          Text('Avg: ${stats.avgSP.toStringAsFixed(1)} SP / day • ${stats.count} Days Logged (Past 30 Days)', style: const TextStyle(color: Colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: stats.hasLoggedToday ? const Color(0xFFF0FDF4) : const Color(0xFFFFF7ED),
                        border: Border.all(color: stats.hasLoggedToday ? const Color(0xFF10B981) : AppColors.saffronPrimary),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: stats.hasLoggedToday ? AppColors.tulsiGreen : AppColors.saffronPrimary,
                            foregroundColor: Colors.white,
                            child: Icon(stats.hasLoggedToday ? Icons.check_circle_outline : Icons.edit_calendar),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bothSubmitted ? "Sadhana Offered (Today & Yesterday)" : (hasToday ? "Today Offered • Yesterday Pending" : "Today's Sadhana Pending"),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  stats.hasLoggedToday ? 'Offering recorded for today' : 'Log before midnight to keep your active streak',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: stats.hasLoggedToday ? AppColors.tulsiGreen : AppColors.saffronDark, foregroundColor: Colors.white),
                            onPressed: () async {
                              final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => DailySadhanaEntryScreen(existingRecord: stats.todayEntry)));
                              if (result == true) _refreshStats();
                            },
                            child: Text(bothSubmitted ? 'Edit Sadhna' : 'Submit Sadhna'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.local_fire_department, color: Color(0xFFEA580C), size: 20),
                                    SizedBox(width: 6),
                                    Text('Active Streak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${stats.currentStreak} Days', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFFEA580C))),
                                Text('Best: ${stats.longestStreak} Days', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: const [
                                    Icon(Icons.donut_large, color: AppColors.tulsiGreen, size: 20),
                                    SizedBox(width: 6),
                                    Text('30-Day Rounds', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('${stats.totalRounds}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.tulsiGreen)),
                                Text('${formatIndianNumber(namesCount)} Holy Names', style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildHeatmapGrid(stats.recent),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Sacred Milestones & Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              Text('Active: ${stats.avatarBadge}', style: const TextStyle(fontSize: 16)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              const Chip(avatar: Text('📿'), label: Text('Japa Sadhak')),
                              const Chip(avatar: Text('🌅'), label: Text('Brahma Muhurta')),
                              Chip(avatar: const Text('🔥'), label: Text('${stats.currentStreak}d Streak')),
                              if (stats.totalRounds >= 64) const Chip(avatar: Text('👑'), label: Text('Harinam Premi')),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 46),
                        side: const BorderSide(color: AppColors.saffronDark),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.picture_as_pdf, color: AppColors.saffronDark),
                      label: const Text('Download Monthly Sadhana PDF', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                      onPressed: () async {
                        try {
                          final doc = pw.Document();
                          doc.addPage(
                            pw.Page(
                              pageFormat: PdfPageFormat.a4,
                              build: (pw.Context ctx) {
                                return pw.Padding(
                                  padding: const pw.EdgeInsets.all(24),
                                  child: pw.Column(
                                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text('My Sadhna - Monthly Report', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                                      pw.SizedBox(height: 8),
                                      pw.Text('Total SP: ${stats.totalSP.toStringAsFixed(0)} | Total Rounds: ${stats.totalRounds} | Streak: ${stats.currentStreak} Days'),
                                      pw.Divider(thickness: 1),
                                      pw.SizedBox(height: 12),
                                      pw.TableHelper.fromTextArray(
                                        headers: ['Date', 'Wake Up', 'Bed Time', 'Rounds', 'SP Score'],
                                        data: stats.recent.map((e) => [
                                          e.entryDate,
                                          e.wakeUpTime,
                                          e.bedTime,
                                          '${e.chantingRounds}',
                                          e.calculatedScore.toStringAsFixed(1),
                                        ]).toList(),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                          await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => doc.save(), name: 'Sadhana_Report.pdf');
                        } catch (err) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate PDF: $err')));
                          }
                        }
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

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
  int _spReadingMinutes = 30;
  int _spLectureMinutes = 30;
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

  void _loadExistingOfferingForDate(DateTime date) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    try {
      final res = await supabase.from('sadhana_entries').select().eq('user_id', user.id).eq('entry_date', dateStr).maybeSingle();
      if (res != null) {
        final rec = DailyLogData.fromMap(res);
        setState(() {
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
        });
      } else {
        setState(() {
          _rounds = 16;
          _spReadingMinutes = 30;
          _spLectureMinutes = 30;
          _otherHearingMinutes = 0;
          _shlokasMemorized = 0;
          _isStreakFreeze = false;
          _wakeUpTime = const TimeOfDay(hour: 4, minute: 0);
          _bedTime = const TimeOfDay(hour: 21, minute: 45);
        });
      }
    } catch (_) {}
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(backgroundColor: Colors.green, content: Text('Sadhana offering recorded successfully!')));
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSliderStepperCard({
    required String title,
    required int value,
    required int min,
    required int max,
    required int step,
    required String unit,
    required ValueChanged<int> onChanged,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderSubtle)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('$value $unit', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
              ],
            ),
            Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: (max - min) ~/ step,
              onChanged: (newVal) => onChanged(newVal.round()),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yest = now.subtract(const Duration(days: 1));
    final bool isYesterday = DateUtils.isSameDay(_selectedDate, yest);

    return Scaffold(
      appBar: AppBar(title: Text(widget.existingRecord != null ? 'Edit Sadhana Record' : 'Record Daily Sadhana')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.creamBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
                child: Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Today (${DateFormat('dd MMM').format(now)})'),
                        selected: !isYesterday,
                        onSelected: (val) {
                          setState(() => _selectedDate = now);
                          _loadExistingOfferingForDate(now);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: Text('Yesterday (${DateFormat('dd MMM').format(yest)})'),
                        selected: isYesterday,
                        onSelected: (val) {
                          setState(() => _selectedDate = yest);
                          _loadExistingOfferingForDate(yest);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.borderSubtle)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _wakeUpTime);
                            if (picked != null) setState(() => _wakeUpTime = picked);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🌅 Wake-up Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(_wakeUpTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.saffronDark)),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 40, width: 1, color: AppColors.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 12)),
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(context: context, initialTime: _bedTime);
                            if (picked != null) setState(() => _bedTime = picked);
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('🌙 Bedtime', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(_bedTime.format(context), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.tulsiGreen)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildSliderStepperCard(title: 'Japa Meditation Rounds', value: _rounds, min: 0, max: 64, step: 1, unit: 'rounds', onChanged: (v) => setState(() => _rounds = v)),
              _buildSliderStepperCard(title: 'SP Book Reading', value: _spReadingMinutes, min: 0, max: 180, step: 5, unit: 'mins', onChanged: (v) => setState(() => _spReadingMinutes = v)),
              _buildSliderStepperCard(title: 'SP Lecture Hearing', value: _spLectureMinutes, min: 0, max: 180, step: 5, unit: 'mins', onChanged: (v) => setState(() => _spLectureMinutes = v)),
              _buildSliderStepperCard(title: 'Other Spiritual Hearing', value: _otherHearingMinutes, min: 0, max: 180, step: 5, unit: 'mins', onChanged: (v) => setState(() => _otherHearingMinutes = v)),
              _buildSliderStepperCard(title: 'Shlokas Memorized Today', value: _shlokasMemorized, min: 0, max: 20, step: 1, unit: 'verses', onChanged: (v) => setState(() => _shlokasMemorized = v)),
              const SizedBox(height: 20),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                  onPressed: _isSaving ? null : _submitDailySadhana,
                  child: _isSaving ? const CircularProgressIndicator(color: Colors.white) : Text(widget.existingRecord != null ? 'Update Offering' : 'Submit Offering', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SuperAdminConsoleScreen extends StatefulWidget {
  final String userRole;
  const SuperAdminConsoleScreen({super.key, required this.userRole});

  @override
  State<SuperAdminConsoleScreen> createState() => _SuperAdminConsoleScreenState();
}

class _SuperAdminConsoleScreenState extends State<SuperAdminConsoleScreen> with SingleTickerProviderStateMixin {
  late Future<AdminStats> _adminFuture;
  late TabController _tabController;
  String _searchFilter = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    setState(() => _adminFuture = _fetchStats());
  }

  Future<AdminStats> _fetchStats() async {
    try {
      final devoteesCount = await supabase.from('profiles').count(CountOption.exact);
      final preachersCount = await supabase.from('preachers').count(CountOption.exact);

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

      return AdminStats(devotees: devoteesCount, preachers: preachersCount, devoteesList: dList, preachersList: pList);
    } catch (_) {
      return const AdminStats(devotees: 0, preachers: 0, devoteesList: [], preachersList: []);
    }
  }

  
  void _showCreateCounseleeDialog(List<PreacherItem> preachers) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final eduCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    String? selectedPreacherId = preachers.isNotEmpty ? preachers.first.id : null;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Register New Counselee'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full / Initiated Name *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Google Login Email *', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPreacherId,
                  decoration: const InputDecoration(labelText: 'Assign Preacher Circle', border: OutlineInputBorder()),
                  items: preachers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))).toList(),
                  onChanged: (val) => setDlgState(() => selectedPreacherId = val),
                ),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Phone', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: profCtrl, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'Education', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'City / Address', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final email = emailCtrl.text.trim();
                if (name.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Email are required.')));
                  return;
                }
                try {
                  await supabase.rpc('admin_create_counselee', params: {
                    'p_full_name': name,
                    'p_email': email,
                    'p_phone_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'p_preacher_id': selectedPreacherId,
                    'p_profession': profCtrl.text.trim().isEmpty ? null : profCtrl.text.trim(),
                    'p_education': eduCtrl.text.trim().isEmpty ? null : eduCtrl.text.trim(),
                    'p_address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                  _refresh();
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Create Counselee'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrEditPreacherDialog([PreacherItem? existing]) {
    final titleCtrl = TextEditingController(text: existing?.displayTitle ?? '');
    final suffixCtrl = TextEditingController(text: existing?.codeSuffix ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing != null ? 'Edit Preacher Circle' : 'Add Preacher Circle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Display Name (e.g. Dayalu Gaura Das)', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: suffixCtrl, decoration: const InputDecoration(labelText: 'Code Suffix (e.g. DGD)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen, foregroundColor: Colors.white),
            onPressed: () async {
              final title = titleCtrl.text.trim();
              final suffix = suffixCtrl.text.trim();
              if (title.isNotEmpty && suffix.isNotEmpty) {
                if (existing != null) {
                  await supabase.from('preachers').update({'display_title': title, 'code_suffix': suffix}).eq('id', existing.id);
                } else {
                  await supabase.from('preachers').insert({'display_title': title, 'code_suffix': suffix, 'is_active': true});
                }
                if (ctx.mounted) Navigator.pop(ctx);
                _refresh();
              }
            },
            child: Text(existing != null ? 'Save Changes' : 'Add Circle'),
          ),
        ],
      ),
    );
  }

    void _showEditDevoteeDialog(DevoteeProfileItem devotee, List<PreacherItem> preachers) {
    final nameCtrl = TextEditingController(text: devotee.fullName);
    final emailCtrl = TextEditingController(text: devotee.email);
    final passCtrl = TextEditingController();
    final phoneCtrl = TextEditingController(text: devotee.phoneNumber);
    final profCtrl = TextEditingController(text: devotee.profession);
    final eduCtrl = TextEditingController(text: devotee.education);
    final addrCtrl = TextEditingController(text: devotee.address);
    final badgeCtrl = TextEditingController(text: devotee.avatarBadge);
    String selectedRole = devotee.role;
    String? selectedPreacher = devotee.preacherId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text('Edit Devotee: ${devotee.fullName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Login Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Reset Password (empty = unchanged)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: badgeCtrl, decoration: const InputDecoration(labelText: 'Emblem Badge (e.g. 📿, 🌸, 👑)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedRole,
                  decoration: const InputDecoration(labelText: 'Assigned Role', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'counselee', child: Text('Counselee')),
                    DropdownMenuItem(value: 'preacher', child: Text('Preacher')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (val) {
                    if (val != null) setDlgState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPreacher,
                  decoration: const InputDecoration(labelText: 'Counselor Circle', border: OutlineInputBorder()),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None / General')),
                    ...preachers.map((p) => DropdownMenuItem(value: p.id, child: Text('${p.displayTitle} (${p.codeSuffix})'))),
                  ],
                  onChanged: (val) => setDlgState(() => selectedPreacher = val),
                ),
                const SizedBox(height: 10),
                TextField(controller: profCtrl, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'Education', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  // Call admin credentials procedure if email or password was edited
                  if ((emailCtrl.text.trim().isNotEmpty && emailCtrl.text.trim() != devotee.email) || passCtrl.text.trim().isNotEmpty) {
                    await supabase.rpc('admin_update_user_credentials', params: {
                      'p_target_user_id': devotee.id,
                      'p_new_email': emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                      'p_new_password': passCtrl.text.trim().isNotEmpty ? passCtrl.text.trim() : null,
                    });
                  }
                  await supabase.from('profiles').update({
                    'full_name': nameCtrl.text.trim(),
                    'phone_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                    'profession': profCtrl.text.trim().isEmpty ? null : profCtrl.text.trim(),
                    'education': eduCtrl.text.trim().isEmpty ? null : eduCtrl.text.trim(),
                    'address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                    'avatar_badge': badgeCtrl.text.trim().isEmpty ? '📿' : badgeCtrl.text.trim(),
                    'role': selectedRole,
                    'preacher_id': selectedPreacher,
                  }).eq('id', devotee.id);

                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Devotee details updated successfully.')));
                    _refresh();
                  }
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Save Details'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console'),
        actions: [
          ..._buildCommonAppBarActions(context, widget.userRole),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.saffronDark,
          labelColor: AppColors.saffronDark,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Devotees'),
            Tab(icon: Icon(Icons.temple_hindu), text: 'Preachers & Circles'),
          ],
        ),
      ),
      body: FutureBuilder<AdminStats>(
        future: _adminFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final stats = snapshot.data ?? const AdminStats(devotees: 0, preachers: 0, devoteesList: [], preachersList: []);

          final filteredDevotees = stats.devoteesList.where((d) {
            if (_searchFilter.isEmpty) return true;
            final query = _searchFilter.toLowerCase();
            return d.fullName.toLowerCase().contains(query) || d.email.toLowerCase().contains(query) || d.phoneNumber.contains(query);
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.borderSubtle)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Devotees', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text('${stats.devotees}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.saffronDark)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                          icon: const Icon(Icons.person_add, size: 18),
                          label: const Text('Add Counselee', style: TextStyle(fontWeight: FontWeight.bold)),
                          onPressed: () => _showCreateCounseleeDialog(stats.preachersList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(hintText: 'Search devotees by name, email, phone...', prefixIcon: const Icon(Icons.search, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                    onChanged: (val) => setState(() => _searchFilter = val.trim()),
                  ),
                  const SizedBox(height: 14),
                  ...filteredDevotees.map((d) => Card(
                    child: ListTile(
                      title: Row(
                        children: [
                          Text(d.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Text(d.avatarBadge, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      subtitle: Text('Email: ${d.email}\nRole: ${d.role} • Circle: ${d.preacherTitle}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppColors.saffronDark, size: 28),
                        tooltip: 'Edit Devotee Details',
                        onPressed: () => _showEditDevoteeDialog(d, stats.preachersList),
                      ),
                    ),
                  )),
                ],
              ),
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Preacher / Counselor Circle'),
                    onPressed: () => _showAddOrEditPreacherDialog(),
                  ),
                  const SizedBox(height: 16),
                  ...stats.preachersList.map((p) => Card(
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: p.isActive ? AppColors.tulsiGreen : Colors.grey, foregroundColor: Colors.white, child: Text(p.codeSuffix)),
                      title: Text(p.displayTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Status: ${p.isActive ? "Active" : "Inactive"}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, size: 20), onPressed: () => _showAddOrEditPreacherDialog(p)),
                          Switch(
                            value: p.isActive,
                            onChanged: (val) async {
                              await supabase.from('preachers').update({'is_active': val}).eq('id', p.id);
                              _refresh();
                            },
                          ),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class PreacherConsoleScreen extends StatefulWidget {
  final String userRole;
  const PreacherConsoleScreen({super.key, required this.userRole});

  @override
  State<PreacherConsoleScreen> createState() => _PreacherConsoleScreenState();
}

class _PreacherConsoleScreenState extends State<PreacherConsoleScreen> {

  void _showPreacherAddCounseleeDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final profCtrl = TextEditingController();
    final addrCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Counselee to My Circle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full / Initiated Name *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Google Login Email *', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Phone', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: profCtrl, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
              const SizedBox(height: 10),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'City / Address', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final email = emailCtrl.text.trim();
              final messenger = ScaffoldMessenger.of(context);

              if (name.isEmpty || email.isEmpty) {
                messenger.showSnackBar(const SnackBar(content: Text('Name and Email are required.')));
                return;
              }
              try {
                await supabase.rpc('admin_create_counselee', params: {
                  'p_full_name': name,
                  'p_email': email,
                  'p_phone_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                  'p_preacher_id': supabase.auth.currentUser?.id,
                  'p_profession': profCtrl.text.trim().isEmpty ? null : profCtrl.text.trim(),
                  'p_address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                });
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) _fetchCounselees();
              } catch (e) {
                if (mounted) {
                  messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text('Add to Circle'),
          ),
        ],
      ),
    );
  }

  List<DevoteeProfileItem> _counselees = [];
  bool _isLoading = true;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _fetchCounselees();
  }

  Future<void> _fetchCounselees() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('profiles')
          .select('id, full_name, email, phone_number, profession, education, address, hide_name_on_leaderboard, role, preacher_id, avatar_badge, date_of_birth, sadhana_entries(entry_date)')
          .eq('preacher_id', user.id)
          .order('full_name', ascending: true);

      final list = ((res as List<dynamic>?) ?? []).map((e) {
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
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _counselees.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return c.fullName.toLowerCase().contains(q) || c.email.toLowerCase().contains(q) || c.phoneNumber.contains(q);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preacher Console'),
        actions: [
          ..._buildCommonAppBarActions(context, widget.userRole),
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
                    Text('My Counselees (${_counselees.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
                      icon: const Icon(Icons.person_add, size: 16),
                      label: const Text('Add Counselee'),
                      onPressed: () => _showPreacherAddCounseleeDialog(),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                TextField(
                  decoration: InputDecoration(hintText: 'Search counselees...', prefixIcon: const Icon(Icons.search, color: AppColors.saffronDark), border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                  onChanged: (val) => setState(() => _search = val.trim()),
                ),
                const SizedBox(height: 14),
                ...filtered.map((c) => Card(
                  child: ListTile(
                    title: Text('${c.fullName} ${c.avatarBadge}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Phone: ${c.phoneNumber.isNotEmpty ? c.phoneNumber : "None"}\nLatest Offering: ${c.latestEntryDate ?? "None recorded"}'),
                  ),
                )),
              ],
            ),
    );
  }
}

class LeaderboardScreen extends StatefulWidget {
  final String userRole;
  const LeaderboardScreen({super.key, required this.userRole});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  String _periodType = 'weekly';
  String? _selectedPreacherId;
  List<PreacherItem> _preachers = [];
  bool _hideMyName = false;
  late Future<List<RankingItem>> _rankingsFuture; // <--- ADD THIS

  void _refreshRankings() { // <--- ADD THIS HELPER
    setState(() {
      _rankingsFuture = _fetchTopRankings();
    });
  }

 @override
  void initState() {
    super.initState();
    _rankingsFuture = _fetchTopRankings(); // <--- ADD THIS LINE
    _fetchPreachersAndProfile();
  }

  Future<void> _fetchPreachersAndProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final p = await supabase.from('profiles').select('hide_name_on_leaderboard').eq('id', user.id).maybeSingle();
        if (p != null) setState(() => _hideMyName = p['hide_name_on_leaderboard'] == true);
      } catch (_) {}
    }
    try {
      final res = await supabase.from('preachers').select().eq('is_active', true);
      setState(() => _preachers = (res as List<dynamic>).map((e) => PreacherItem.fromMap(e as Map<String, dynamic>)).toList());
    } catch (_) {}
  }

  Future<List<RankingItem>> _fetchTopRankings() async {
    try {
      final res = await supabase.rpc('get_top_rankings', params: {
        'p_period_type': _periodType,
        'p_preacher_id': _selectedPreacherId,
      });
      final List<dynamic> data = (res as List<dynamic>?) ?? [];
      return data.map((e) => RankingItem.fromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Top Rankings'),
        actions: _buildCommonAppBarActions(context, widget.userRole),
      ),
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
                        segments: const [
                          ButtonSegment(value: 'weekly', label: Text('Weekly')),
                          ButtonSegment(value: 'monthly', label: Text('Monthly')),
                        ],
                        selected: {_periodType},
                        onSelectionChanged: (val) {
                          _periodType = val.first;
                          _refreshRankings();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String?>(
                      value: _selectedPreacherId,
                      hint: const Text('Global'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('All Circles (Global)')),
                        ..._preachers.map((p) => DropdownMenuItem(value: p.id, child: Text(p.codeSuffix))),
                      ],
                      onChanged: (val) {
                        _selectedPreacherId = val;
                        _refreshRankings();
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: FutureBuilder<List<RankingItem>>(
                  future: _rankingsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final rankings = snapshot.data ?? [];
                    if (rankings.isEmpty) {
                      return RefreshIndicator(
                        onRefresh: () async => _refreshRankings(),
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 120),
                            Center(child: Text('No sadhana offerings logged yet.')),
                          ],
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async => _refreshRankings(),
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: rankings.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = rankings[index];
                          return ListTile(
                            tileColor: item.isCurrentUser ? AppColors.saffronPrimary.withValues(alpha: 0.12) : null,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                            subtitle: Text('Circle: ${item.preacherSuffix} • ${item.totalRounds} Rounds'),
                            trailing: Text('${item.totalSP.toStringAsFixed(1)} SP', style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.saffronDark, fontSize: 15)),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.borderSubtle))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Hide My Full Name on Leaderboard', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(
                      value: _hideMyName,
                      onChanged: (val) async {
                        setState(() => _hideMyName = val);
                        final user = supabase.auth.currentUser;
                        if (user != null) {
                          await supabase.from('profiles').update({'hide_name_on_leaderboard': val}).eq('id', user.id);
                          if (mounted) setState(() {});
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class WebApkDownloadBanner extends StatelessWidget {
  const WebApkDownloadBanner({super.key});

  void _triggerDownload(BuildContext context) async {
    final apkUri = Uri.base.resolve('downloads/my_sadhna.apk');
    if (await canLaunchUrl(apkUri)) {
      await launchUrl(apkUri, mode: LaunchMode.externalApplication);
    } else {
      await launchUrl(Uri.parse(kVercelApkDownloadUrl), mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderSubtle)),
      child: Row(
        children: [
          const Icon(Icons.android, color: AppColors.tulsiGreen, size: 28),
          const SizedBox(width: 14),
          const Expanded(child: Text('Get the Android App for offline tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen, foregroundColor: Colors.white),
            onPressed: () => _triggerDownload(context),
            child: const Text('Download APK'),
          ),
        ],
      ),
    );
  }
}

class ProfileDashboardScreen extends StatefulWidget {
  final String userRole;
  const ProfileDashboardScreen({super.key, required this.userRole});

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
        final res = await supabase.from('profiles').select('full_name, email, phone_number, profession, education, address, avatar_badge, date_of_birth, role, preacher_id, preachers(display_title, code_suffix)').eq('id', user.id).single();
        if (mounted) setState(() { _profileData = res; _isLoading = false; });
        return;
      } catch (_) {}
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showAdminSecurityModal() {
    final emailCtrl = TextEditingController(text: supabase.auth.currentUser?.email ?? '');
    final passCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Admin Credentials'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password (6+ chars)', border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              try {
                if (emailCtrl.text.trim().isNotEmpty && emailCtrl.text.trim() != supabase.auth.currentUser?.email) {
                  await supabase.auth.updateUser(UserAttributes(email: emailCtrl.text.trim()));
                }
                if (passCtrl.text.trim().isNotEmpty) {
                  await supabase.auth.updateUser(UserAttributes(password: passCtrl.text.trim()));
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                messenger.showSnackBar(const SnackBar(content: Text('Credentials updated successfully.')));
              } catch (e) {
                messenger.showSnackBar(SnackBar(backgroundColor: AppColors.sacredRed, content: Text('Error: $e')));
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
  Future<void> _postAppUpdateAnnouncement({
    required String title,
    required String message,
    required String apkDownloadUrl,
    required int targetBuildCode,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await supabase
          .from('announcements')
          .update({'is_active': false})
          .eq('type', 'update');

      await supabase.from('announcements').insert({
        'title': title,
        'message': message,
        'type': 'update',
        'action_label': 'Download Update',
        'action_url': apkDownloadUrl,
        'min_version_code': targetBuildCode,
        'is_active': true,
      });

      messenger.showSnackBar(
        const SnackBar(content: Text('Update announcement published to all devices.')),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(backgroundColor: AppColors.sacredRed, content: Text('Error: $e')),
      );
    }
  }

  void _showCounseleeEditModal() async {
    final nameCtrl = TextEditingController(text: _profileData?['full_name'] ?? '');
    final phoneCtrl = TextEditingController(text: _profileData?['phone_number'] ?? '');
    final profCtrl = TextEditingController(text: _profileData?['profession'] ?? '');
    final eduCtrl = TextEditingController(text: _profileData?['education'] ?? '');
    final addrCtrl = TextEditingController(text: _profileData?['address'] ?? '');
    final emailCtrl = TextEditingController(text: supabase.auth.currentUser?.email ?? '');
    final passCtrl = TextEditingController();
    String? selectedPreacherId = _profileData?['preacher_id']?.toString();

    final List preachersList = [];
    try {
      final pRes = await supabase.from('preachers').select('id, display_title, code_suffix').eq('is_active', true);
      preachersList.addAll(pRes);
    } catch (_) {}

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDlgState) => AlertDialog(
          title: const Text('Edit Complete Profile Details'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full / Initiated Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Login Email Address', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'New Password (leave empty to keep current)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: selectedPreacherId,
                  decoration: const InputDecoration(labelText: 'Assigned Preacher / Counselor Circle', border: OutlineInputBorder()),
                  items: preachersList.map<DropdownMenuItem<String>>((p) => DropdownMenuItem<String>(
                    value: p['id'].toString(),
                    child: Text('${p['display_title']} (${p['code_suffix']})'),
                  )).toList(),
                  onChanged: (val) => setDlgState(() => selectedPreacherId = val),
                ),
                const SizedBox(height: 10),
                TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'WhatsApp Phone', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: profCtrl, decoration: const InputDecoration(labelText: 'Profession', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: eduCtrl, decoration: const InputDecoration(labelText: 'Qualification', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'City / Address', border: OutlineInputBorder())),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white),
              onPressed: () async {
                try {
                  final user = supabase.auth.currentUser;
                  if (user != null) {
                    if (emailCtrl.text.trim().isNotEmpty && emailCtrl.text.trim() != user.email) {
                      await supabase.auth.updateUser(UserAttributes(email: emailCtrl.text.trim()));
                    }
                    if (passCtrl.text.trim().isNotEmpty) {
                      await supabase.auth.updateUser(UserAttributes(password: passCtrl.text.trim()));
                    }
                    await supabase.from('profiles').update({
                      'full_name': nameCtrl.text.trim(),
                      'email': emailCtrl.text.trim(),
                      'phone_number': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
                      'profession': profCtrl.text.trim().isEmpty ? null : profCtrl.text.trim(),
                      'education': eduCtrl.text.trim().isEmpty ? null : eduCtrl.text.trim(),
                      'address': addrCtrl.text.trim().isEmpty ? null : addrCtrl.text.trim(),
                      'preacher_id': selectedPreacherId,
                    }).eq('id', user.id);

                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (mounted) {
                      _fetchProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile details updated successfully.')),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(backgroundColor: AppColors.sacredRed, content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Details'),
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

    final bool isSuperAdmin = widget.userRole == 'super_admin' || widget.userRole == 'admin';
    final pr = _profileData?['preachers'] as Map<String, dynamic>?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: _buildCommonAppBarActions(context, widget.userRole),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 550),
          padding: const EdgeInsets.all(24),
          child: ListView(
            children: [
              Center(
                child: Text(_profileData?['full_name'] ?? 'Devotee', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Center(child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 14))),
              const SizedBox(height: 20),
              if (isSuperAdmin) ...[
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronDark, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.security),
                  label: const Text('Change Admin Email / Password'),
                  onPressed: _showAdminSecurityModal,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.tulsiGreen, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                  icon: const Icon(Icons.campaign),
                  label: const Text('Broadcast App Update Notice'),
                  onPressed: () => _postAppUpdateAnnouncement(
                    title: '🚀 New Update Available (v1.0.19)',
                    message: 'A fresh update (Build 20) is live with bug fixes. Tap to update your app.',
                    apkDownloadUrl: 'https://my-sadhna-psi.vercel.app/downloads/my_sadhna.apk',
                    targetBuildCode: 20,
                  ),
                ),
              ] else ...[
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        ListTile(title: const Text('Emblem Badge'), trailing: Text(_profileData?['avatar_badge']?.toString() ?? '📿', style: const TextStyle(fontSize: 20))),
                        const Divider(),
                        ListTile(title: const Text('Phone'), trailing: Text(_profileData?['phone_number'] ?? 'Not set')),
                        const Divider(),
                        ListTile(title: const Text('Profession'), trailing: Text(_profileData?['profession'] ?? 'Not set')),
                        const Divider(),
                        ListTile(title: const Text('Address'), trailing: Text(_profileData?['address'] ?? 'Not set')),
                        const Divider(),
                        ListTile(title: const Text('Preacher Circle'), trailing: Text(pr != null ? '${pr['display_title']} (${pr['code_suffix']})' : 'None')),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.saffronPrimary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit My Profile Details'),
                  onPressed: _showCounseleeEditModal,
                ),
              ],
              const SizedBox(height: 16),
              const WebApkDownloadBanner(),
              const SizedBox(height: 20),
              OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.sacredRed, side: const BorderSide(color: AppColors.sacredRed), padding: const EdgeInsets.symmetric(vertical: 14)),
                onPressed: () async => await supabase.auth.signOut(),
                child: const Text('Sign Out'),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'My Sadhna v1.0.18 (Build $kCurrentInstalledVersionCode)',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}