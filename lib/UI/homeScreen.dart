import 'package:ai_therapist/UI/profile_page.dart';
import 'package:ai_therapist/UI/quick_prompt_chatting.dart';
import 'package:ai_therapist/UI/subscription_page.dart';
import 'package:ai_therapist/UI/text_chat_history.dart';
import 'package:ai_therapist/UI/text_chat_history_list.dart';
import 'package:ai_therapist/UI/text_chat_screen.dart';
import 'package:ai_therapist/UI/voice_chat_screen.dart';
import 'package:ai_therapist/UI/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

import 'apikey.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Color> iconColors = [
    Color(0xffe8fd52),
    Color(0xffc09ff8),
    Color(0xffffc4dd),
  ];

  bool isDataLoaded = false; // Flag to track if data is loaded
  List<FlSpot> moodData = [
    FlSpot(1, 3),
    FlSpot(2, 3),
    FlSpot(3, 3),
    FlSpot(4, 3),
    FlSpot(5, 3),
    FlSpot(6, 3),
    FlSpot(7, 3),
  ]; // Initial empty moodData

  Future<void> fetchAndAnalyzeMoods(String userEmail) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Set default values before fetching data
      setState(() {
        isDataLoaded = false;
        moodData = List.generate(
          7,
          (index) => FlSpot(index + 1.0, 3),
        ); // Default to Neutral mood
      });

      final QuerySnapshot sessionSnapshot =
          await firestore
              .collection('users')
              .doc(userEmail)
              .collection('chats')
              .orderBy('timestamp', descending: true)
              .limit(7)
              .get();

      if (sessionSnapshot.docs.isEmpty) {
        print("No chat sessions found.");
        setState(() {
          isDataLoaded = true;
        });
        return;
      }

      List<int> moodRatings = [];

      for (var sessionDoc in sessionSnapshot.docs) {
        String sessionId = sessionDoc.id;

        final QuerySnapshot chatSnapshot =
            await firestore
                .collection('users')
                .doc(userEmail)
                .collection('chats')
                .doc(sessionId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(7)
                .get();

        List<String> messages =
            chatSnapshot.docs
                .map((doc) => doc['message'] ?? '')
                .cast<String>()
                .toList();

        if (messages.isNotEmpty) {
          int mood = await getMoodAnalysisFromGemini(messages.join("\n"));
          moodRatings.add(mood);
        } else {
          moodRatings.add(3);
        }
      }

      moodRatings = moodRatings.reversed.toList();

      List<FlSpot> newMoodData = [];
      for (int i = 0; i < moodRatings.length; i++) {
        newMoodData.add(FlSpot(i + 1.0, moodRatings[i].toDouble()));
      }

      setState(() {
        moodData = newMoodData;
        isDataLoaded = true;
      });
    } catch (e) {
      print("Error fetching and analyzing moods: $e");
      setState(() {
        isDataLoaded = true;
      });
    }
  }



  // Function to analyze mood using Gemini API
  Future<int> getMoodAnalysisFromGemini(String chatHistory) async {
    String apiKey = _apikey;

    final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
    final String prompt = '''
Analyze the mood based on the following chat messages:
$chatHistory

Rate the overall mood on a scale from 1 to 5:
1 = Very Sad
2 = Sad
3 = Neutral
4 = Happy
5 = Very Happy

Return only the number as a response.
''';

    try {
      final response = await model.generateContent([Content.text(prompt)]);
      String? aiResponse = response.text?.trim();

      int moodRating =
          int.tryParse(aiResponse ?? "3") ?? 3; // Default to Neutral (3)
      return moodRating;
    } catch (e) {
      print("Error calling Gemini API: $e");
      return 3; // Default to Neutral on error
    }
  }

  String username = "";

  void fetchUserName() async {
    try {
      // Get the current user's email
      String userEmail = FirebaseAuth.instance.currentUser!.email.toString();

      // Fetch the user document from Firestore
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userEmail)
              .get();

      // Check if the document exists and has the 'name' field
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          username =
              ", " +
              (data['name'] as String) +
              "?"; // Update the username with setState
        });
      } else {
        setState(() {
          username = ""; // Set to null if no name is found
        });
      }
    } catch (e) {
      print('Error fetching username: $e');
      setState(() {
        username = ""; // Set to null on error
      });
    }
  }

  String _apikey = "";
  Future<void> _fetchApiKey() async {
    String? key = await ApiService.fetchApiKey();
    if (key != null) {
      setState(() {
        _apikey = key;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserName();
    _fetchApiKey();
    // fetchAndAnalyzeMoods(FirebaseAuth.instance.currentUser!.email.toString());
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.sizeOf(context).height;
    double deviceWidth = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: Color(0xff070a12),
      appBar: AppBar(
        backgroundColor: Color(0xff070a12),
        elevation: 0,
        toolbarHeight: deviceHeight * 0.08,
        centerTitle: true,
        // ✅ Ensures title stays in center
        leading: Builder(
          // ✅ Adds menu icon to open drawer
          builder:
              (context) => IconButton(
                icon: Icon(Icons.menu, color: Color(0xffcccccb), size: 24),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min, // ✅ Prevents Row from expanding
          children: [
            Text(
              "Thera",
              style: TextStyle(
                color: Colors.white,
                fontSize: deviceHeight * 0.025,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 4),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Color(0xffe8fd52),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                "AI",
                style: TextStyle(
                  color: Colors.black,
                  fontSize: deviceHeight * 0.020,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SubscriptionPage()),
              );
            },
            child: Container(
              height: deviceHeight * 0.035,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFd4af37), // Rich Gold
                    Color(0xFFFFC107), // Deep Gold/Yellow
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(deviceHeight * 0.008),
              ),
              child: Stack(
                children: [
                  // Shimmer Effect
                  Positioned.fill(
                    child: Shimmer.fromColors(
                      baseColor: Colors.transparent,
                      highlightColor: Colors.white.withOpacity(0.5),
                      period: Duration(seconds: 2),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.2),
                              Colors.white.withOpacity(0.6),
                              Colors.white.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Subscribe Text
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: deviceHeight * 0.01,
                      ),
                      child: Text(
                        "Subscribe",
                        style: TextStyle(
                          color: Colors.black, // Best contrast with gold
                          fontSize: deviceHeight * 0.014,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: deviceWidth * 0.02),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
            child: CircleAvatar(
              radius: deviceHeight * 0.022,
              // backgroundColor: Colors.grey.withAlpha(30),
              // child: Text(
              //   username.length >= 4 ? username.substring(2, 4).toUpperCase() : username,
              //   style: TextStyle(
              //     fontWeight: FontWeight.w900,
              //     color: Color(0xffe8fd52),
              //     fontSize: deviceHeight*0.022
              //   ),
              // ),
              backgroundColor: Color(0xff070a12),
              backgroundImage: AssetImage(
                'assets/images/profile_image.png',
              ),
            ),
          ),
          SizedBox(width: 10),
        ],
      ),

      drawer: SafeArea(
        child: Drawer(
          backgroundColor: Color(0xff070a12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Brand Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.03),
                decoration: BoxDecoration(
                  color: Colors.grey.withAlpha(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Thera",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: deviceHeight * 0.025,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Color(0xffe8fd52),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "AI",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: deviceHeight * 0.020,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Chat History Title
              Padding(
                padding: EdgeInsets.all(deviceHeight * 0.02),
                child: Text(
                  "Your Chat History",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: deviceHeight * 0.018,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              SizedBox(height: deviceHeight * 0.02),

              // Chat History List
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(FirebaseAuth.instance.currentUser!.email.toString())
                      .collection('chats')
                      .orderBy("timestamp", descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                          child: CircularProgressIndicator(color: Color(0xffe8fd52)));
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No chat history available",
                          style: TextStyle(
                              color: Colors.white, fontSize: deviceHeight * 0.02),
                        ),
                      );
                    }

                    var chats = snapshot.data!.docs;
                    final iconColors = [
                      Color(0xffffc4dd),
                      Color(0xffc09ff8),
                      Color(0xffe8fd52),
                      Color(0xffff9999),
                      Color(0xffb3c8ff),
                      Color(0xffa3f7bf),
                      Color(0xffffb997),
                      Color(0xff7de7eb),
                      Color(0xffffd166),
                    ];

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: deviceHeight * 0.02),
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        var chat = chats[index];
                        String sessionId = chat.id;
                        String chatTitle = chat['title'];

                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TextChatHistory(sessionId: sessionId),
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    height: deviceHeight * 0.035,
                                    width: deviceHeight * 0.035,
                                    decoration: BoxDecoration(
                                      color: iconColors[index % iconColors.length],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.history_outlined,
                                      color: Color(0xff070a12),
                                      size: deviceHeight * 0.02,
                                    ),
                                  ),
                                  SizedBox(width: deviceWidth * 0.02),
                                  Expanded(
                                    child: Text(
                                      chatTitle,
                                      style: TextStyle(
                                        color: Color(0xffcccccb),
                                        fontSize: 16,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              Divider(
                                height: deviceHeight * 0.025,
                                color: Colors.transparent,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Logout Button & Version Info
              Padding(
                padding: EdgeInsets.all(deviceHeight * 0.02),
                child: Column(
                  children: [
                    // Divider(color: Colors.grey.withOpacity(0.15), height: deviceHeight*0.05,),
                    Container(height: deviceHeight*0.020),
                    GestureDetector(
                      onTap: () async {
                        await GoogleSignIn().signOut();
                        await FirebaseAuth.instance.signOut();

                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => WelcomeScreen()),
                              (route) => false,
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.015),
                        decoration: BoxDecoration(
                          color: Color(0xffe8fd52),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.logout, color: Colors.black, size: deviceHeight * 0.02),
                            SizedBox(width: 8),
                            Text(
                              "Logout",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: deviceHeight * 0.020,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: deviceHeight * 0.02),

                    // Version Text
                    Center(
                      child: Text(
                        "v 1.0.1",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: deviceHeight * 0.016,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),


      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.02),
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: deviceHeight * 0.025),
              Padding(
                padding: EdgeInsets.all(deviceHeight * 0.02),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  // Slower for smoother feel
                  transitionBuilder: (
                    Widget child,
                    Animation<double> animation,
                  ) {
                    return FadeTransition(opacity: animation, child: child);
                  },
                  child: Text(
                    "How may I help you\ntoday${username ?? ', User?'}",
                    key: ValueKey(username),
                    style: TextStyle(
                      color: const Color(0xffcccccb),
                      fontSize: deviceHeight * 0.035,
                    ),
                  ),
                ),
              ),
              SizedBox(height: deviceHeight * 0.025),

              SizedBox(height: deviceHeight * 0.02),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                // Keeps elements close without screen padding
                children: [
                  // Left Column with one Container
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextChatScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: deviceWidth * 0.48, // Adjusted width
                          height: deviceHeight * 0.25,
                          decoration: BoxDecoration(
                            color: Color(0xffe8fd52),
                            borderRadius: BorderRadius.circular(
                              deviceHeight * 0.03,
                            ),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.03,
                              vertical: deviceHeight * 0.02,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: deviceHeight * 0.05,
                                      width: deviceHeight * 0.05,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(60),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.chat_outlined,
                                        color: Color(0xff070a12),
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.arrow_down_left,
                                      color: Color(0xff070a12),
                                      size: deviceHeight * 0.032,
                                    ),
                                  ],
                                ),
                                Text(
                                  "Text\nchat AI",
                                  style: TextStyle(
                                    height: 1,
                                    color: Color(0xff070a12),
                                    fontSize: deviceHeight * 0.04,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => VoiceChatScreen(),
                            ),
                          );
                        },
                        child: Container(
                          width: deviceWidth * 0.46,
                          height: deviceHeight * 0.12,
                          margin: EdgeInsets.only(bottom: deviceHeight * 0.01),
                          // Decreased space
                          decoration: BoxDecoration(
                            color: Color(0xffc09ff8),
                            borderRadius: BorderRadius.circular(
                              deviceHeight * 0.03,
                            ),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.03,
                              vertical: deviceHeight * 0.02,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: deviceHeight * 0.040,
                                      width: deviceHeight * 0.040,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(60),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.mic_none_outlined,
                                        color: Color(0xff070a12),
                                        size: deviceHeight * 0.028,
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.arrow_down_left,
                                      color: Color(0xff070a12),
                                      size: deviceHeight * 0.020,
                                    ),
                                  ],
                                ),
                                Text(
                                  "Voice Assistant",
                                  style: TextStyle(
                                    height: 1,
                                    color: Color(0xff070a12),
                                    fontSize: deviceHeight * 0.02,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => TextChatHistoryList(),
                            ),
                          );
                        },
                        child: Container(
                          width: deviceWidth * 0.46,
                          height: deviceHeight * 0.12,
                          decoration: BoxDecoration(
                            color: Color(0xffffc4dd),
                            borderRadius: BorderRadius.circular(
                              deviceHeight * 0.03,
                            ),
                            border: Border.all(color: Colors.black, width: 2),
                          ),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: deviceWidth * 0.03,
                              vertical: deviceHeight * 0.02,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      height: deviceHeight * 0.040,
                                      width: deviceHeight * 0.040,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withAlpha(60),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.history,
                                        color: Color(0xff070a12),
                                      ),
                                    ),
                                    Icon(
                                      CupertinoIcons.arrow_down_left,
                                      color: Color(0xff070a12),
                                      size: deviceHeight * 0.020,
                                    ),
                                  ],
                                ),
                                Text(
                                  "Chat history",
                                  style: TextStyle(
                                    height: 1,
                                    color: Color(0xff070a12),
                                    fontSize: deviceHeight * 0.02,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: deviceHeight * 0.01),

                      Container(),
                    ],
                  ),
                ],
              ),

              SizedBox(height: deviceHeight * 0.025),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03),
                child: Text(
                  "Your last 7 Chat's mood Graph",
                  style: TextStyle(
                    color: Color(0xff9d9d9d),
                    fontWeight: FontWeight.w500,
                    fontSize: deviceHeight * 0.022,
                  ),
                ),
              ),

              SizedBox(height: deviceHeight * 0.05),

              // ye nich vale container ko fix kar bhai
              Container(
                height: 300,
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
                child: Stack(
                  children: [
                    // Your LineChart widget
                    LineChart(
                      LineChartData(
                        minX: 1,
                        maxX: 7,
                        minY: 1,
                        maxY: 5,
                        lineBarsData: [
                          LineChartBarData(
                            spots: moodData,
                            isCurved: true,
                            gradient: LinearGradient(
                              colors: [Colors.purpleAccent, Colors.blueAccent],
                            ),
                            barWidth: 3,
                            isStrokeCapRound: true,
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purpleAccent.withOpacity(0.4),
                                  Colors.blueAccent.withOpacity(0.1),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 4,
                                  color: Colors.white,
                                  strokeWidth: 2,
                                  strokeColor: Colors.blueAccent,
                                );
                              },
                            ),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine:
                              (value) => FlLine(
                                color: Colors.white30,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                          getDrawingVerticalLine:
                              (value) => FlLine(
                                color: Colors.white30,
                                strokeWidth: 1,
                                dashArray: [5, 5],
                              ),
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 1:
                                    return Text(
                                      "😢",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    );
                                  case 2:
                                    return Text(
                                      "☹️",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    );
                                  case 3:
                                    return Text(
                                      "😐",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    );
                                  case 4:
                                    return Text(
                                      "😊",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    );
                                  case 5:
                                    return Text(
                                      "😁",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    );
                                  default:
                                    return Container();
                                }
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 1 && value.toInt() <= 7) {
                                  return Text(
                                    "Chat ${value.toInt()}",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }
                                return Container();
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        lineTouchData: LineTouchData(
                          enabled: true,
                          touchTooltipData: LineTouchTooltipData(
                            fitInsideHorizontally: true,
                            fitInsideVertically: true,
                            tooltipPadding: const EdgeInsets.all(8),
                            tooltipRoundedRadius: 8,
                            tooltipBorder: BorderSide(
                              color: Colors.white,
                              width: 1,
                            ),
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((touchedSpot) {
                                String emoji = "";
                                switch (touchedSpot.y.toInt()) {
                                  case 1:
                                    emoji = "😢"; // Very sad
                                    break;
                                  case 2:
                                    emoji = "☹️"; // Sad
                                    break;
                                  case 3:
                                    emoji = "😐"; // Neutral
                                    break;
                                  case 4:
                                    emoji = "😊"; // Happy
                                    break;
                                  case 5:
                                    emoji = "😁"; // Very happy
                                    break;
                                  default:
                                    emoji = "❓"; // Unknown case
                                }

                                return LineTooltipItem(
                                  "Mood: $emoji",
                                  TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                          getTouchedSpotIndicator: (barData, spotIndexes) {
                            return spotIndexes.map((index) {
                              return TouchedSpotIndicatorData(
                                FlLine(
                                  color: Colors.white,
                                  strokeWidth: 0.5, // ✅ Thin line when touched
                                  dashArray: [2, 2], // ✅ Dashed effect
                                ),
                                FlDotData(show: false),
                              );
                            }).toList();
                          },
                          touchSpotThreshold: 10,
                          handleBuiltInTouches: true,
                        ),
                      ),
                    ),
                    // Show loading animation if moodData is empty
                    // if (moodData.isEmpty)
                    //   Center(
                    //     child: CircularProgressIndicator(
                    //       valueColor: AlwaysStoppedAnimation<Color>(Color(0xffe8fd52)),
                    //     ),
                    //   ),
                  ],
                ),
              ),

              SizedBox(height: deviceHeight * 0.02),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.03),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Quick prompts",
                      style: TextStyle(
                        color: Color(0xff9d9d9d),
                        fontWeight: FontWeight.w500,
                        fontSize: deviceHeight * 0.022,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: deviceHeight * 0.02),

              SizedBox(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('quick prompts')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffe8fd52),
                        ),
                      );
                    }

                    if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                      return Text("No quick prompts available.");
                    }

                    final quickPrompts =
                        snapshot.data!.docs.map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data() as Map<String, dynamic>;
                          return {
                            'prompt': data['prompt'] as String ?? 'No Prompt',
                          };
                        }).toList();

                    return SizedBox(
                      child: ListView.builder(
                        physics: NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: quickPrompts.length,
                        itemBuilder: (context, index) {
                          final prompt =
                              quickPrompts[index]['prompt'].toString();
                          final iconColor =
                              iconColors[index %
                                  iconColors.length]; // Get color from list

                          return Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: deviceHeight * 0.005,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => QuickPromptChatting(
                                          initialMessage:
                                              "I want help in $prompt",
                                        ),
                                  ),
                                );
                              },
                              child: Container(
                                height: deviceHeight * 0.06,
                                decoration: BoxDecoration(
                                  color: Colors.grey.withAlpha(10),
                                  borderRadius: BorderRadius.circular(
                                    deviceHeight * 0.008,
                                  ),
                                ),
                                child: Center(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: deviceWidth * 0.02,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: deviceHeight * 0.035,
                                              width: deviceHeight * 0.035,
                                              decoration: BoxDecoration(
                                                color: iconColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.chat,
                                                color: Color(0xff070a12),
                                                size: deviceHeight * 0.02,
                                              ),
                                            ),
                                            SizedBox(width: deviceWidth * 0.02),
                                            Text(
                                              prompt,
                                              style: TextStyle(
                                                color: Color(0xffcccccb),
                                                fontSize: deviceHeight * 0.018,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Icon(
                                          CupertinoIcons.arrow_down_left,
                                          color: Color(0xffcccccb),
                                          size: deviceHeight * 0.020,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: deviceHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
