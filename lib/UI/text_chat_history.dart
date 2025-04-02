// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
//
// class TextChatHistory extends StatefulWidget {
//   final String sessionId;
//
//   const TextChatHistory({super.key, required this.sessionId});
//
//   @override
//   _TextChatHistoryState createState() => _TextChatHistoryState();
// }
//
// class _TextChatHistoryState extends State<TextChatHistory> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final ScrollController _scrollController = ScrollController();
//   final TextEditingController _controller = TextEditingController();
//   late User _user;
//   bool _isThinking = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _user = FirebaseAuth.instance.currentUser!;
//     _controller.addListener(_scrollToInput);
//   }
//
//   @override
//   void dispose() {
//     _controller.removeListener(_scrollToInput);
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }
//
//   void _scrollToBottom() {
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }
//
//   void _scrollToInput() {
//     if (_scrollController.hasClients) {
//       _scrollController.animateTo(
//         _scrollController.position.maxScrollExtent,
//         duration: Duration(milliseconds: 300),
//         curve: Curves.easeOut,
//       );
//     }
//   }
//
//   Future<void> generateStory(String userMessage) async {
//     if (userMessage.trim().isEmpty) return;
//
//     final userChatRef = _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(widget.sessionId);
//
//     try {
//       await userChatRef.collection('messages').add({
//         'sender': 'user',
//         'message': userMessage,
//         'timestamp': FieldValue.serverTimestamp(),
//       });
//
//       _scrollToBottom();
//       setState(() => _isThinking = true);
//
//       const apiKey = 'AIzaSyA11gq9jkuuoIPBkE_RWTO8K1M_J8q9dg0';
//       final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
//       String previousContext = await _getConversationHistory();
//
//       String prompt = '''
// $previousContext
//
// User: "$userMessage"
//
// Act as Thera AI, a therapy agent. Keep responses natural, concise (2-3 sentences, under 50 words). Expand only if explicitly asked. If unrelated, say: 'Thera AI for therapy. Focus on your well-being.' If asked your name, respond: 'I am Thera AI, a therapy agent."''';
//
//       final response = await model.generateContent([Content.text(prompt)]);
//       String? aiResponse = response.text;
//
//       if (aiResponse != null) {
//         await userChatRef.collection('messages').add({
//           'sender': 'ai',
//           'message': aiResponse,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//       }
//
//       _scrollToBottom();
//     } catch (e) {
//       print('Error generating content: $e');
//     } finally {
//       if (mounted) {
//         setState(() => _isThinking = false);
//       }
//     }
//   }
//
//   Future<String> _getConversationHistory() async {
//     final snapshot = await _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(widget.sessionId)
//         .collection('messages')
//         .orderBy('timestamp', descending: false)
//         .limit(5)
//         .get();
//
//     List<String> conversationHistory = [];
//     snapshot.docs.forEach((doc) {
//       conversationHistory.add("${doc['sender']}: ${doc['message']}");
//     });
//
//     return conversationHistory.join('\n');
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     double deviceHeight = MediaQuery.of(context).size.height;
//     double deviceWidth = MediaQuery.of(context).size.width;
//
//     return Scaffold(
//       backgroundColor: const Color(0xff070a12),
//       appBar: AppBar(
//         backgroundColor: const Color(0xff070a12),
//         elevation: 0,
//         toolbarHeight: deviceHeight * 0.08,
//         centerTitle: true,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back_ios,
//               color: Colors.white, size: deviceHeight * 0.025),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         title: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               "Thera",
//               style: TextStyle(
//                   color: Colors.white,
//                   fontSize: deviceHeight * 0.025,
//                   fontWeight: FontWeight.bold),
//             ),
//             SizedBox(width: 4),
//             Container(
//               padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
//               decoration: BoxDecoration(
//                 color: Color(0xffe8fd52),
//                 borderRadius: BorderRadius.circular(6),
//               ),
//               child: Text(
//                 "AI",
//                 style: TextStyle(
//                     color: Colors.black,
//                     fontSize: deviceHeight * 0.020,
//                     fontWeight: FontWeight.bold),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           CircleAvatar(
//               radius: deviceHeight * 0.025,
//               backgroundColor: Colors.white,
//               backgroundImage: AssetImage("assets/images/ai_profile.webp")),
//           SizedBox(width: 10),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream: _firestore
//                   .collection('users')
//                   .doc(_user.email)
//                   .collection('chats')
//                   .doc(widget.sessionId)
//                   .collection('messages')
//                   .orderBy('timestamp', descending: false)
//                   .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//                   return Center(
//                     child: CircularProgressIndicator(
//                      color: Color(0xffe8fd52),
//                     ),
//                   );
//                 }
//
//                 final chatDocs = snapshot.data!.docs;
//                 WidgetsBinding.instance
//                     .addPostFrameCallback((_) => _scrollToBottom());
//
//                 return ListView.builder(
//                   controller: _scrollController,
//                   padding: EdgeInsets.symmetric(horizontal: 10),
//                   itemCount: chatDocs.length + (_isThinking ? 1 : 0),
//                   itemBuilder: (context, index) {
//                     if (index == chatDocs.length && _isThinking) {
//                       return Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child: LoadingDots(),
//                         ),
//                       );
//                     }
//
//                     final message = chatDocs[index];
//                     final String sender = message['sender'];
//                     bool isUser = sender == 'user';
//
//                     return Align(
//                       alignment:
//                       isUser ? Alignment.centerRight : Alignment.centerLeft,
//                       child: Container(
//                         margin: const EdgeInsets.symmetric(vertical: 5),
//                         padding: const EdgeInsets.all(12),
//                         constraints: BoxConstraints(
//                           maxWidth: isUser ? deviceWidth * 0.75 : deviceWidth * 1.0,
//                         ),
//                         decoration: BoxDecoration(
//                           color: isUser ? Colors.blueGrey[900] : Colors.transparent,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           message['message'],
//                           style: const TextStyle(color: Colors.white, fontSize: 16),
//                         ),
//                       ),
//                     );
//                   },
//                 );
//               },
//             ),
//           ),
//           Container(
//             padding: EdgeInsets.all(10),
//             color: const Color(0xff070a12),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     keyboardType: TextInputType.multiline,
//                     maxLines: 6,
//                     minLines: 1,
//                     style: TextStyle(color: Colors.white),
//                     decoration: InputDecoration(
//                       hintText: 'Ask anything to your AI therapist..',
//                       hintStyle: TextStyle(color: Color(0xff707073)),
//                       border: InputBorder.none,
//                       filled: true,
//                       fillColor: Color(0xff1f2229),
//                       contentPadding: EdgeInsets.symmetric(
//                         horizontal: 15,
//                         vertical: 10,
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(width: 10),
//                 FloatingActionButton(
//                   shape: CircleBorder(),
//                   backgroundColor:
//                   _isThinking ? Colors.grey : Color(0xffe8fd52),
//                   onPressed: _isThinking
//                       ? null
//                       : () {
//                     final userMessage = _controller.text.trim();
//                     if (userMessage.isNotEmpty) {
//                       _controller.clear();
//                       generateStory(userMessage);
//                     }
//                   },
//                   child: Center(
//                     child: Image.asset("assets/images/send.png", height: 25),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class LoadingDots extends StatefulWidget {
//   @override
//   _LoadingDotsState createState() => _LoadingDotsState();
// }
//
// class _LoadingDotsState extends State<LoadingDots>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<double> _animation;
//
//   @override
//   void initState() {
//     super.initState();
//     _controller = AnimationController(
//       duration: Duration(milliseconds: 700),
//       vsync: this,
//     )..repeat();
//     _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: List.generate(3, (index) {
//         return AnimatedBuilder(
//           animation: _animation,
//           builder: (context, child) {
//             return Opacity(
//               opacity: (1 - ((_animation.value - index * 0.3).abs() % 1)).clamp(
//                 0.0,
//                 1.0,
//               ),
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 2),
//                 child: Container(
//                   width: 10,
//                   height: 10,
//                   decoration: BoxDecoration(
//                     color: Color(0xffffffff), // Changed to theme color
//                     shape: BoxShape.circle,
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       }),
//     );
//   }
//
//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'apikey.dart';
import 'connectivity_provider.dart';

class TextChatHistory extends StatefulWidget {
  final String sessionId;

  const TextChatHistory({super.key, required this.sessionId});

  @override
  _TextChatHistoryState createState() => _TextChatHistoryState();
}

class _TextChatHistoryState extends State<TextChatHistory> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  late User _user;
  bool _isThinking = false;
  bool hasAccess = false; // Add hasAccess variable

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
    _user = FirebaseAuth.instance.currentUser!;
    _checkUserAccess(); // Check access on initialization
    _controller.addListener(_scrollToInput);
    _fetchApiKey();
  }

  @override
  void dispose() {
    _controller.removeListener(_scrollToInput);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Check user access based on free session or subscription dates
  Future<void> _checkUserAccess() async {
    try {
      final userDocRef = _firestore.collection('users').doc(_user.email);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Fetch the dates as Timestamp from Firestore
        final freeSessionStartDate = data['free_session_start_date'] as Timestamp?;
        final freeSessionEndDate = data['free_session_end_date'] as Timestamp?;
        final subscriptionStartDate = data['subscription_start_date'] as Timestamp?;
        final subscriptionEndDate = data['subscription_end_date'] as Timestamp?;

        // Get current timestamp
        final currentTimestamp = Timestamp.now();

        // Check free session period
        if (freeSessionStartDate != null && freeSessionEndDate != null) {
          if (currentTimestamp.toDate().isAfter(freeSessionStartDate.toDate()) &&
              currentTimestamp.toDate().isBefore(freeSessionEndDate.toDate())) {
            setState(() {
              hasAccess = true;
            });
            return;
          }
        }

        // Check subscription period
        if (subscriptionStartDate != null && subscriptionEndDate != null) {
          if (currentTimestamp.toDate().isAfter(subscriptionStartDate.toDate()) &&
              currentTimestamp.toDate().isBefore(subscriptionEndDate.toDate())) {
            setState(() {
              hasAccess = true;
            });
            return;
          }
        }

        // If neither condition is met, hasAccess remains false
        setState(() {
          hasAccess = false;
        });
      } else {
        setState(() {
          hasAccess = false; // No document means no access
        });
      }
    } catch (e) {
      print('Error checking access: $e');
      setState(() {
        hasAccess = false; // Default to no access on error
      });
    }
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToInput() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> generateStory(String userMessage) async {
    if (!hasAccess || userMessage.trim().isEmpty) return; // Prevent generation if no access

    final userChatRef = _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(widget.sessionId);

    try {
      await userChatRef.collection('messages').add({
        'sender': 'user',
        'message': userMessage,
        'timestamp': FieldValue.serverTimestamp(),
      });

      _scrollToBottom();
      setState(() => _isThinking = true);

      String apiKey = _apikey;
      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      String previousContext = await _getConversationHistory();

      String prompt = '''
$previousContext

User: "$userMessage"

Act as Thera AI, a therapy agent. Your responses should be natural, concise (2-3 sentences, under 50 words), and strictly related to therapeutic conversations. You are NOT to ask questions unless the user explicitly asks you to. If the user asks a question that is NOT directly related to therapy or well-being, respond ONLY with: 'I'm Thera AI for therapy. Focus on your well-being.' Do not attempt to answer unrelated questions. If the user explicitly asks you to expand on a topic, then you may provide more detailed information. If asked your name, respond: 'I am Thera AI, a therapy agent."''';

      final response = await model.generateContent([Content.text(prompt)]);
      String? aiResponse = response.text;

      if (aiResponse != null) {
        await userChatRef.collection('messages').add({
          'sender': 'ai',
          'message': aiResponse,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      _scrollToBottom();
    } catch (e) {
      print('Error generating content: $e');
    } finally {
      if (mounted) {
        setState(() => _isThinking = false);
      }
    }
  }

  Future<String> _getConversationHistory() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(widget.sessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(5)
        .get();

    List<String> conversationHistory = [];
    snapshot.docs.forEach((doc) {
      conversationHistory.add("${doc['sender']}: ${doc['message']}");
    });

    return conversationHistory.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;
    double deviceWidth = MediaQuery.of(context).size.width;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        if (connectivityProvider.isOffline) {
          return NoInternetScreen(); // Or show a snackbar, etc.
        }
        return Scaffold(
          backgroundColor: const Color(0xff070a12),
          appBar: AppBar(
            backgroundColor: const Color(0xff070a12),
            elevation: 0,
            toolbarHeight: deviceHeight * 0.08,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios,
                  color: Colors.white, size: deviceHeight * 0.025),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Thera",
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: deviceHeight * 0.025,
                      fontWeight: FontWeight.bold),
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
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            actions: [
              CircleAvatar(
                  radius: deviceHeight * 0.025,
                  backgroundColor: Colors.white,
                  backgroundImage: AssetImage("assets/images/ai_profile.webp")),
              SizedBox(width: 10),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('users')
                      .doc(_user.email)
                      .collection('chats')
                      .doc(widget.sessionId)
                      .collection('messages')
                      .orderBy('timestamp', descending: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Color(0xffe8fd52),
                        ),
                      );
                    }

                    final chatDocs = snapshot.data!.docs;
                    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      itemCount: chatDocs.length + (_isThinking ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == chatDocs.length && _isThinking) {
                          return Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: LoadingDots(),
                            ),
                          );
                        }

                        final message = chatDocs[index];
                        final String sender = message['sender'];
                        bool isUser = sender == 'user';

                        return Align(
                          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth: isUser ? deviceWidth * 0.75 : deviceWidth * 1.0,
                            ),
                            decoration: BoxDecoration(
                              color: isUser ? Colors.blueGrey[900] : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message['message'],
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              hasAccess
                  ? _buildInputField(deviceHeight, deviceWidth) // Show input if user has access
                  : _buildNoAccessMessage(deviceHeight), // Show no access message if no access
            ],
          ),
        );

      },
    );

  }

  // Input field and send button
  Widget _buildInputField(double deviceHeight, double deviceWidth) {
    return Container(
      padding: EdgeInsets.all(10),
      color: const Color(0xff070a12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              cursorColor: Color(0xffe8fd52),
              controller: _controller,
              keyboardType: TextInputType.multiline,
              maxLines: 6,
              minLines: 1,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask anything to your AI therapist...',
                hintStyle: TextStyle(color: Color(0xff707073)),
                border: InputBorder.none,
                filled: true,
                fillColor: Color(0xff1f2229),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          FloatingActionButton(
            shape: CircleBorder(),
            backgroundColor: _isThinking ? Colors.grey : Color(0xffe8fd52),
            onPressed: _isThinking
                ? null
                : () {
              final userMessage = _controller.text.trim();
              if (userMessage.isNotEmpty) {
                _controller.clear();
                generateStory(userMessage);
              }
            },
            child: Center(
              child: Image.asset("assets/images/send.png", height: 25),
            ),
          ),
        ],
      ),
    );
  }

  // No access message
  Widget _buildNoAccessMessage(double deviceHeight) {
    return Container(
      padding: EdgeInsets.all(10),
      color: const Color(0xff070a12),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(deviceHeight * 0.01),
            ),
            padding: EdgeInsets.symmetric(
                vertical: deviceHeight * 0.01, horizontal: deviceHeight * 0.018),
            child: Text(
              "Your free 7-day trial has expired or you are not subscribed.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: deviceHeight * 0.020,
              ),
            ),
          ),
          SizedBox(height: deviceHeight * 0.01),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.circular(deviceHeight * 0.01),
            ),
            padding: EdgeInsets.symmetric(
                vertical: deviceHeight * 0.01, horizontal: deviceHeight * 0.018),
            child: Text(
              "Please subscribe to continue messaging with Thera AI.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: deviceHeight * 0.020,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LoadingDots extends StatefulWidget {
  @override
  _LoadingDotsState createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;



  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 700),
      vsync: this,
    )..repeat();
    _animation = Tween(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Opacity(
              opacity: (1 - ((_animation.value - index * 0.3).abs() % 1)).clamp(0.0, 1.0),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: Color(0xffffffff),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}