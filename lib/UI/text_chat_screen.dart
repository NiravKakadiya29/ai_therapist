// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
// import 'package:uuid/uuid.dart';
// import 'package:intl/intl.dart';
//
//
// class TextChatScreen extends StatefulWidget {
//   final bool isNewChat;
//
//   const TextChatScreen({super.key, this.isNewChat = false});
//
//   // const TextChatScreen({super.key});
//
//   @override
//   State<TextChatScreen> createState() => _TextChatScreenState();
// }
//
// class _TextChatScreenState extends State<TextChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   late User _user;
//   String? _chatSessionId;
//   bool _isThinking = false;
//
//
//   @override
//   void initState() {
//     super.initState();
//     _user = _auth.currentUser!;
//     // _getOrCreateChatSession();
//     _prepareNewChatSession();
//   }
//
//   String _generateChatTitle(String firstMessage) {
//     List<String> words = firstMessage.split(' ');
//     if (words.length <= 3) return firstMessage; // If short, use as title
//
//     return words.take(3).join(' ') + '...'; // Generate a concise title
//   }
//
//   // Auto-scroll to the latest message
//   void _scrollToBottom() {
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }
//
//   Future<void> _prepareNewChatSession() async {
//     // Generate a new chat session ID but don't store it yet
//     _chatSessionId = Uuid().v4();
//   }
//
//   Future<void> generateStory(String userMessage) async {
//     if (userMessage.trim().isEmpty) return;
//
//     final userChatRef = _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId);
//
//     try {
//       final chatDoc = await userChatRef.get();
//
//       // Create a new session in Firestore only if it doesn't exist
//       if (!chatDoc.exists) {
//         await userChatRef.set({
//           'sessionStart': FieldValue.serverTimestamp(),
//           'timestamp': FieldValue.serverTimestamp(),
//           'title': userMessage, // Store first message as title
//         });
//       }
//
//       // Ensure the title is set only once (on the first message)
//       if (chatDoc.exists && (chatDoc.data()?['title'] == "New Chat" || chatDoc.data()?['title'] == null)) {
//         String generatedTitle = _generateChatTitle(userMessage);
//         await userChatRef.update({'title': generatedTitle});
//       }
//
//       // Store the user’s message
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
//       // Constructing a dynamic prompt
//       String prompt = '''
// $previousContext
//
// User: "$userMessage"
//
// Act as Thera AI, a therapy agent. Keep responses natural, concise (2-3 sentences, under 50 words). Expand only if explicitly asked. If unrelated, say: 'Thera AI for therapy. Focus on your well-being.' If asked your name, respond: 'I am Thera AI, a therapy agent."''';
//
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
//       setState(() => _isThinking = false);
//     }
//   }
//
//   Future<void> _storeMessages(String userMessage, String aiResponse) async {
//     await _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId)
//         .collection('messages')
//         .add({
//           'sender': 'user',
//           'message': userMessage,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//
//     await _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId)
//         .collection('messages')
//         .add({
//           'sender': 'ai',
//           'message': aiResponse,
//           'timestamp': FieldValue.serverTimestamp(),
//         });
//   }
//
//   Future<String> _getConversationHistory() async {
//     final snapshot =
//         await _firestore
//             .collection('users')
//             .doc(_user.email)
//             .collection('chats')
//             .doc(_chatSessionId)
//             .collection('messages')
//             .orderBy('timestamp', descending: false)
//             .limit(5)
//             .get();
//
//     List<String> conversationHistory = [];
//     snapshot.docs.forEach((doc) {
//       conversationHistory.add(doc['message']);
//     });
//
//     return conversationHistory.join('\n');
//   }
//
//   // Future<void> _getOrCreateChatSession() async {
//   //   final userChatRef = _firestore
//   //       .collection('users')
//   //       .doc(_user.email)
//   //       .collection('chats');
//   //
//   //   if (widget.isNewChat) {
//   //     // Create a new chat session
//   //     _chatSessionId = Uuid().v4();
//   //     await userChatRef.doc(_chatSessionId).set({
//   //       'sessionStart': FieldValue.serverTimestamp(),
//   //       'timestamp': FieldValue.serverTimestamp(),
//   //       'title': "New Chat",
//   //     });
//   //   } else {
//   //     // Fetch the latest existing chat session
//   //     final existingSession =
//   //     await userChatRef
//   //         .orderBy('sessionStart', descending: true)
//   //         .limit(1)
//   //         .get();
//   //     if (existingSession.docs.isNotEmpty) {
//   //       _chatSessionId = existingSession.docs.first.id;
//   //     } else {
//   //       // If no existing session, create a new one
//   //       _chatSessionId = Uuid().v4();
//   //       await userChatRef.doc(_chatSessionId).set({
//   //         'sessionStart': FieldValue.serverTimestamp(),
//   //         'timestamp': FieldValue.serverTimestamp(),
//   //         'title': "New Chat",
//   //       });
//   //     }
//   //   }
//   // }
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
//           icon: Icon(
//             Icons.arrow_back_ios,
//             color: Colors.white,
//             size: deviceHeight * 0.025,
//           ),
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
//                 color: Colors.white,
//                 fontSize: deviceHeight * 0.025,
//                 fontWeight: FontWeight.bold,
//               ),
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
//                   color: Colors.black,
//                   fontSize: deviceHeight * 0.020,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           CircleAvatar(
//             radius: deviceHeight * 0.025,
//             backgroundColor: Colors.white,
//             backgroundImage: AssetImage("assets/images/ai_profile.webp"),
//           ),
//           SizedBox(width: 10),
//         ],
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: StreamBuilder<QuerySnapshot>(
//               stream:
//                   _firestore
//                       .collection('users')
//                       .doc(_user.email)
//                       .collection('chats')
//                       .doc(_chatSessionId)
//                       .collection('messages')
//                       .orderBy('timestamp', descending: false)
//                       .snapshots(),
//               builder: (context, snapshot) {
//                 if (!snapshot.hasData) {
//                   return Center(child: CircularProgressIndicator(color: Color(0xffe8fd52),));
//                 }
//
//                 final chatDocs = snapshot.data!.docs;
//
//
//                 if (chatDocs.isEmpty){
//                   return Center(
//                     child: SingleChildScrollView(
//                       physics: BouncingScrollPhysics(),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           crossAxisAlignment: CrossAxisAlignment.center,
//                           children: [
//                             CircleAvatar(
//                               radius: deviceHeight * 0.05, // Adjust size
//                               backgroundColor: Colors.grey.withAlpha(
//                                 30,
//                               ), // Example color
//                               child: Image.asset(
//                                 "assets/images/brain.png",
//                                 height: deviceHeight * 0.045,
//                               ),
//                             ),
//                             SizedBox(height: deviceHeight * 0.02),
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.withAlpha(30),
//                                 borderRadius: BorderRadius.circular(
//                                   deviceHeight * 0.01,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(vertical: deviceHeight*0.01, horizontal: deviceHeight*0.018),
//                                 child: Text(
//                                   textAlign: TextAlign.center,
//                                   "Start a conversation by typing the question!",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: deviceHeight * 0.020,
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//                             SizedBox(height: deviceHeight * 0.02),
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.withAlpha(30),
//                                 borderRadius: BorderRadius.circular(
//                                   deviceHeight * 0.01,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(vertical: deviceHeight*0.01, horizontal: deviceHeight*0.018),
//                                 child: Text(
//                                   textAlign: TextAlign.center,
//                                   "Your AI therapist is here to support, and guide you through your thoughts. ask freely, and let your journey to self-discovery begin.",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: deviceHeight * 0.020,
//                                   ),
//                                 ),
//                               ),
//                             ),
//
//                             SizedBox(height: deviceHeight * 0.02),
//                             Container(
//                               decoration: BoxDecoration(
//                                 color: Colors.grey.withAlpha(30),
//                                 borderRadius: BorderRadius.circular(
//                                   deviceHeight * 0.01,
//                                 ),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(vertical: deviceHeight*0.01, horizontal: deviceHeight*0.018),
//                                 child: Text(
//                                   textAlign: TextAlign.center,
//                                   "Feel free to express your emotions, concerns, or ideas. Your TheraAI is designed to provide meaningful and insightful responses to help you reflect.",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontWeight: FontWeight.w500,
//                                     fontSize: deviceHeight * 0.020,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   );
//                 }
//
//                 WidgetsBinding.instance.addPostFrameCallback(
//                   (_) => _scrollToBottom(),
//                 );
//
//                 return ListView.builder(
//                   controller: _scrollController,
//                   padding: EdgeInsets.symmetric(horizontal: 10),
//                   itemCount: chatDocs.length + (_isThinking ? 1 : 0),
//                   // Add extra space for animation
//                   itemBuilder: (context, index) {
//                     if (index == chatDocs.length && _isThinking) {
//                       return Padding(
//                         padding: EdgeInsets.all(8.0),
//                         child: Align(
//                           alignment: Alignment.centerLeft,
//                           child:
//                               LoadingDots(), // Show animation when AI is thinking
//                         ),
//                       );
//                     }
//
//                     final message = chatDocs[index];
//                     final bool isUser = message['sender'] == 'user';
//
//                     return Align(
//                       alignment:
//                           isUser ? Alignment.centerRight : Alignment.centerLeft,
//                       child: Container(
//                         margin: EdgeInsets.symmetric(vertical: 5),
//                         padding: EdgeInsets.all(12),
//                         constraints: BoxConstraints(
//                           maxWidth:
//                               isUser
//                                   ? MediaQuery.of(context).size.width * 0.75
//                                   : MediaQuery.of(context).size.width * 1,
//                         ),
//                         decoration: BoxDecoration(
//                           color:
//                               isUser
//                                   ? Colors.blueGrey[900]
//                                   : Colors.transparent,
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         child: Text(
//                           message['message'],
//                           style: TextStyle(color: Colors.white, fontSize: 16),
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
//                     // enabled: !_isThinking, // Disable input when AI is thinking
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
//                       _isThinking
//                           ? Colors.grey
//                           : Color(0xffe8fd52), // Disable button color
//                   onPressed:
//                       _isThinking
//                           ? null // Disable button click
//                           : () {
//                             final userMessage = _controller.text.trim();
//                             if (userMessage.isNotEmpty) {
//                               _controller.clear();
//                               generateStory(userMessage);
//                             }
//                           },
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
//                     color: Colors.white,
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
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import 'apikey.dart';
import 'connectivity_provider.dart';

class TextChatScreen extends StatefulWidget {
  final bool isNewChat;

  const TextChatScreen({super.key, this.isNewChat = false});

  @override
  State<TextChatScreen> createState() => _TextChatScreenState();
}

class _TextChatScreenState extends State<TextChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late User _user;
  String? _chatSessionId;
  bool _isThinking = false;
  bool hasAccess = false; // Initialize hasAccess as false

  String _apikey = "";
  Future<void> _fetchApiKey() async {
    String? key = await ApiService.fetchApiKey();
    print("Api key is $key");
    if (key != null) {
      setState(() {
        _apikey = key;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _fetchApiKey();
    _checkUserAccess(); // Check access when the screen initializes
    _prepareNewChatSession();
  }

  // Function to check user access based on timestamps
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


  String _generateChatTitle(String firstMessage) {
    List<String> words = firstMessage.split(' ');
    if (words.length <= 3) return firstMessage;

    return words.take(3).join(' ') + '...';
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  Future<void> _prepareNewChatSession() async {
    _chatSessionId = Uuid().v4();
  }

  Future<void> generateStory(String userMessage) async {
    if (userMessage.trim().isEmpty || !hasAccess) return;

    final userChatRef = _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(_chatSessionId);

    try {
      final chatDoc = await userChatRef.get();

      if (!chatDoc.exists) {
        await userChatRef.set({
          'sessionStart': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
          'title': userMessage,
        });
      }

      if (chatDoc.exists && (chatDoc.data()?['title'] == "New Chat" || chatDoc.data()?['title'] == null)) {
        String generatedTitle = _generateChatTitle(userMessage);
        await userChatRef.update({'title': generatedTitle});
      }

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
      setState(() => _isThinking = false);
    }
  }

  Future<String> _getConversationHistory() async {
    final snapshot = await _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(_chatSessionId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .limit(5)
        .get();

    List<String> conversationHistory = [];
    snapshot.docs.forEach((doc) {
      conversationHistory.add(doc['message']);
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
              icon: Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: deviceHeight * 0.025,
              ),
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
              CircleAvatar(
                radius: deviceHeight * 0.025,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage("assets/images/ai_profile.webp"),
              ),
              SizedBox(width: 10),
            ],
          ),
          body: hasAccess
              ? _buildChatUI(deviceHeight, deviceWidth) // Normal UI if user has access
              : _buildNoAccessUI(deviceHeight), // No access UI
        );
      },
    );

  }

  // Normal chat UI
  Widget _buildChatUI(double deviceHeight, double deviceWidth) {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _firestore
                .collection('users')
                .doc(_user.email)
                .collection('chats')
                .doc(_chatSessionId)
                .collection('messages')
                .orderBy('timestamp', descending: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: Color(0xffe8fd52)));
              }

              final chatDocs = snapshot.data!.docs;

              if (chatDocs.isEmpty) {
                return Center(
                  child: SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: deviceHeight * 0.05,
                            backgroundColor: Colors.grey.withAlpha(30),
                            child: Image.asset(
                              "assets/images/brain.png",
                              height: deviceHeight * 0.045,
                            ),
                          ),
                          SizedBox(height: deviceHeight * 0.02),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius:
                              BorderRadius.circular(deviceHeight * 0.01),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: deviceHeight * 0.01,
                                  horizontal: deviceHeight * 0.018),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Start a conversation by typing the question!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: deviceHeight * 0.020,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: deviceHeight * 0.02),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius:
                              BorderRadius.circular(deviceHeight * 0.01),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: deviceHeight * 0.01,
                                  horizontal: deviceHeight * 0.018),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Your AI therapist is here to support, and guide you through your thoughts. Ask freely, and let your journey to self-discovery begin.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: deviceHeight * 0.020,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: deviceHeight * 0.02),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.grey.withAlpha(30),
                              borderRadius:
                              BorderRadius.circular(deviceHeight * 0.01),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: deviceHeight * 0.01,
                                  horizontal: deviceHeight * 0.018),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Feel free to express your emotions, concerns, or ideas. Your TheraAI is designed to provide meaningful and insightful responses to help you reflect.",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: deviceHeight * 0.020,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

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
                  final bool isUser = message['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: EdgeInsets.symmetric(vertical: 5),
                      padding: EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: isUser
                            ? MediaQuery.of(context).size.width * 0.75
                            : MediaQuery.of(context).size.width * 1,
                      ),
                      decoration: BoxDecoration(
                        color: isUser ? Colors.blueGrey[900] : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        message['message'],
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
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
                    hintText: 'Ask anything to your AI therapist..',
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
        ),
      ],
    );
  }

  // No access UI
  Widget _buildNoAccessUI(double deviceHeight) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: deviceHeight * 0.05,
              backgroundColor: Colors.grey.withAlpha(30),
              child: Image.asset(
                "assets/images/brain.png",
                height: deviceHeight * 0.045,
              ),
            ),
            SizedBox(height: deviceHeight * 0.02),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(deviceHeight * 0.01),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: deviceHeight * 0.01, horizontal: deviceHeight * 0.018),
                child: Text(
                  textAlign: TextAlign.center,
                  "Your free 7-day trial has expired or you are not subscribed.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: deviceHeight * 0.020,
                  ),
                ),
              ),
            ),
            SizedBox(height: deviceHeight * 0.02),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(30),
                borderRadius: BorderRadius.circular(deviceHeight * 0.01),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    vertical: deviceHeight * 0.01, horizontal: deviceHeight * 0.018),
                child: Text(
                  textAlign: TextAlign.center,
                  "Please subscribe to continue messaging with Thera AI.",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: deviceHeight * 0.020,
                  ),
                ),
              ),
            ),
          ],
        ),
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
                    color: Colors.white,
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