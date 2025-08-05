import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'contactus.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await initializeDateFormatting();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Body Contest',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFF121212),
        // 다크 배경
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFD4AF37), // 골드
          secondary: Colors.redAccent, // 강조색
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
        ),
      ),

      home: const ContestYearPage(),
    );
  }
}

class ContestYearPage extends StatefulWidget {
  const ContestYearPage({super.key});

  @override
  State<ContestYearPage> createState() => _ContestYearPageState();
}

class _ContestYearPageState extends State<ContestYearPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<String>> _events = {};
  String _selectedEventText = '';

  @override
  void initState() {
    super.initState();
    _loadEvents();
    //saveWNBFAsiaEvents(); // WNBF 아시아 대회 데이터 저장
  }

  // Future<void> saveWNBFAsiaEvents() async {
  //   List<Map<String, dynamic>> contests = [
  //     {
  //       "title": "WNBF World Championships - Pro Qualifier & Pro Show",
  //       "date": DateTime(2025, 11, 22),
  //       "region": "미국",
  //       "venue": "로스앤젤레스",
  //     },
  //   ];
  //   // 🔹 월별로 그룹화
  //   Map<int, List<Map<String, dynamic>>> monthGrouped = {};
  //   for (var comp in contests) {
  //     int month = (comp["date"] as DateTime).month;
  //     monthGrouped.putIfAbsent(month, () => []);
  //     monthGrouped[month]!.add(comp);
  //   }
  //
  //   // 🔹 Firestore에 기존 데이터 유지 + 새 데이터 추가
  //   for (var entry in monthGrouped.entries) {
  //     int month = entry.key;
  //
  //     List<Map<String, dynamic>> monthContests = entry.value.map((comp) {
  //       return {
  //         '날짜': DateFormat('yyyy년 M월 d일').format(comp["date"] as DateTime),
  //         '대회이름': comp["title"],
  //         '대회지역': comp["region"],
  //         '대회장소': comp["venue"],
  //       };
  //     }).toList();
  //
  //     await FirebaseFirestore.instance
  //         .collection('contest-2025')
  //         .doc("${month}월")
  //         .set({
  //       "대회목록": FieldValue.arrayUnion(monthContests)
  //     }, SetOptions(merge: true));
  //
  //     print("✅ ${month}월 데이터 기존값 유지 + 새 값 추가 완료");
  //   }
  // }

  // Firestore에서 대회 날짜 불러오기
  Future<void> _loadEvents() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('contest-2025')
        .get();

    Map<DateTime, List<String>> eventMap = {};

    for (var doc in snapshot.docs) {
      final contests = List<Map<String, dynamic>>.from(doc['대회목록']);
      for (var comp in contests) {
        final date = DateFormat('yyyy년 M월 d일').parse(comp['날짜']);
        final dayKey = DateTime(date.year, date.month, date.day);
        if (eventMap[dayKey] == null) {
          eventMap[dayKey] = [];
        }
        eventMap[dayKey]!.add(comp['대회이름']);
      }
    }

    setState(() {
      _events = eventMap;
    });
  }

  List<String> _getEventsForDay(DateTime day) {
    return _events[DateTime(day.year, day.month, day.day)] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "🏆 2025 대회 일정",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton.icon(
            onPressed: () {
              // 문의하기 페이지로 이동하거나 메일 보내기 기능 연결
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InquiryPage(), // 문의 페이지
                ),
              );
            },
            icon: const Icon(Icons.mail_outline, color: Colors.amber),
            label: const Text(
              "문의하기",
              style: TextStyle(
                color: Colors.amber,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),

      body: Column(
        children: [
          if (_selectedEventText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedEventText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      //overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // 상단 캘린더
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.50,
            child: TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              locale: 'ko_KR',
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;

                  final events = _getEventsForDay(selectedDay);
                  if (events.isNotEmpty) {
                    _selectedEventText = events.join(', ');
                  } else {
                    _selectedEventText = '해당 날짜에 대회가 없습니다.';
                  }
                });
              },

              eventLoader: _getEventsForDay,
              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: Color(0xFFD4AF37), // 골드
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: Colors.redAccent, // 선택 날짜 빨강
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: Colors.white),
                weekendTextStyle: const TextStyle(color: Colors.white70),
              ),
              headerStyle: const HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                leftChevronIcon: Icon(Icons.chevron_left, color: Colors.white),
                rightChevronIcon: Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ),
            ),
          ),

          const Divider(),

          // 하단 월 버튼 그리드
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                itemCount: 12, // 2월~12월
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, index) {
                  final month = "${index + 1}월";
                  final List<List<Color>> gradients = [
                    [const Color(0xFFD4AF37), const Color(0xFFFFD700)],
                  ];
                  final colors = gradients[index % gradients.length];

                  return GestureDetector(
                    onTap: () {
                      // 여기에 MonthContestPage로 이동 가능
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MonthContestPage(monthName: month),
                        ),
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            size: 30,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            month,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 월 상세 페이지 (해당 월 대회 리스트)
class MonthContestPage extends StatelessWidget {
  final String monthName;

  const MonthContestPage({super.key, required this.monthName});

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "$monthName 대회",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('contest-2025')
            .doc(monthName)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("대회 데이터가 없습니다."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final contests = List<Map<String, dynamic>>.from(data["대회목록"]);

          return ListView.builder(
            itemCount: contests.length,
            itemBuilder: (context, index) {
              final comp = contests[index];
              final dateStr = comp['날짜'];
              final date = DateFormat('yyyy년 M월 d일').parse(dateStr);
              final dDay = date.difference(DateTime.now()).inDays;

              Color boxColor;
              if (dDay <= 10 && dDay >= 0) {
                boxColor = Colors.redAccent; // 10일 전
              } else if (dDay > 0) {
                boxColor = Colors.lightGreen; // 아직 남았지만 10일 전은 아님
              } else {
                boxColor = Colors.grey.shade500; // 이미 지난 대회
              }

              return GestureDetector(
                onTap: () {
                  final String? url = comp['url'];
                  if (url != null && url.isNotEmpty) {
                    _launchURL(url);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 왼쪽 날짜 / D-Day 박스
                      Container(
                        width: 80,
                        decoration: BoxDecoration(
                          color: boxColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              DateFormat('M월\nd일').format(date),
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.2,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              dDay >= 0 ? "D-$dDay" : "종료",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // 오른쪽 대회 정보
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                comp['대회이름'],
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 16,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      "${comp['대회지역']} · ${comp['대회장소']}",
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
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
            },
          );
        },
      ),
    );
  }
}
