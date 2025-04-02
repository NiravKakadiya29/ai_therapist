// import 'dart:async';
// import 'package:animated_text_kit/animated_text_kit.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:speech_to_text/speech_to_text.dart' as stt;
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:uuid/uuid.dart';
// import 'package:flutter_tts/flutter_tts.dart';
// import 'package:google_generative_ai/google_generative_ai.dart';
//
// class VoiceChatScreen extends StatefulWidget {
//   const VoiceChatScreen({super.key});
//
//   @override
//   State<VoiceChatScreen> createState() => _VoiceChatScreenState();
// }
//
// class _VoiceChatScreenState extends State<VoiceChatScreen> {
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
//   final _user = FirebaseAuth.instance.currentUser!;
//   final ScrollController _scrollController = ScrollController();
//   final stt.SpeechToText _speech = stt.SpeechToText();
//   final FlutterTts _tts = FlutterTts();
//   bool _isMuted = false;
//   String _lastSpokenText = ""; // Store the last spoken text
//   bool _isThinking = false;
//   bool _isSpeechAvailable = false;
//   bool _stopListeningCalled = false;
//   bool _speechFinished = false; // Add speech finished flag // Add speech finished flag
//   bool _isListening = false;
//   String _text = "";
//   String _aiResponse = ""; // Store AI's response progressively
//   String _chatSessionId = Uuid().v4();
//   bool _isSpeaking = false; // To track if AI is speaking
//   Timer? _silenceTimer;
//
//
//   // Method to generate the chat title from the first user message
//   String _generateChatTitle(String firstMessage) {
//     List<String> words = firstMessage.split(' ');
//     if (words.length <= 3) return firstMessage; // If short, use as title
//     return words.take(3).join(' ') + '...'; // Generate a concise title
//   }
//
//   Timer? _listeningTimer;
//   bool _timerActive = false;
//
//   @override
//   void initState() {
//     super.initState();
//     Future.delayed(Duration(milliseconds: 500), () {
//       _initializeSpeech();
//     });
//   }
//
//   void _reInitializeSpeech() async {
//     if (_speech.isAvailable) {
//       _speech.cancel();
//     }
//     _initializeSpeech();
//   }
//
//
//   Future<bool> _initializeSpeech() async {
//     _isSpeechAvailable = await _speech.initialize(
//       onError: (error) {
//         if (mounted) {
//           print("${DateTime.now()} Speech recognition error: $error");
//           print("${DateTime.now()} Setting _isListening to false from onError");
//           _setListeningState(false);
//           _isSpeechAvailable = false;
//         }
//       },
//     );
//     if (!_isSpeechAvailable) {
//       print("${DateTime.now()} Speech recognition is not available.");
//     }
//     return _isSpeechAvailable;
//   }
//
//   void _toggleRecording() async {
//     if (!_isSpeechAvailable) {
//       bool isSpeechInitialized = await _initializeSpeech();
//       if (!isSpeechInitialized) {
//         print("speech is not available");
//         return;
//       }
//     }
//
//     if (_isListening) {
//       _stopListening();
//     } else {
//       _startListening();
//     }
//   }
//
//   void _startListening() {
//     if (_isListening) {
//       print("${DateTime.now()} _startListening called but _isListening is already true");
//       return;
//     }
//
//     print("${DateTime.now()} _startListening called");
//     _setListeningState(true);
//     _text = "";
//     _aiResponse = "";
//     _stopListeningCalled = false;
//     _speechFinished = false;
//
//     _speech.listen(
//       onResult: (result) {
//         print(
//             "Speech Result: ${result.recognizedWords}, final: ${result.finalResult}");
//         setState(() {
//           _text = result.recognizedWords;
//         });
//         if (result.finalResult) {
//           print("${DateTime.now()} onResult: final: true");
//           _speechFinished = true;
//           _processSpeech();
//         } else {
//           _resetSilenceTimer();
//         }
//       },
//       listenMode: stt.ListenMode.dictation,
//       listenFor: Duration(minutes: 1),
//       pauseFor: Duration(seconds: 5),
//       partialResults: true,
//     );
//     _startSilenceTimer();
//   }
//
//   void _stopListening() {
//     if (_stopListeningCalled) {
//       print("${DateTime.now()} _stopListening already called");
//       return;
//     }
//     _stopListeningCalled = true;
//
//     if (!_isListening) {
//       print("${DateTime.now()} _stopListening called but _isListening is already false");
//       return;
//     }
//     print("${DateTime.now()} _stopListening called");
//     _speech.stop().then((_) {
//       if (_speechFinished == false) {
//         _processSpeech();
//       }
//     });
//     _cancelSilenceTimer();
//   }
//
//   void _processSpeech() {
//     _setListeningState(false);
//     if (_text.isNotEmpty) {
//       print("${DateTime.now()} calling generateStory with: $_text");
//       generateStory(_text);
//     } else {
//       print("${DateTime.now()} _text is empty, not calling generateStory");
//     }
//   }
//
//   void _setListeningState(bool listening) {
//     if (mounted) {
//       setState(() {
//         print("${DateTime.now()} Setting _isListening to $listening");
//         _isListening = listening;
//       });
//     }
//   }
//
//
//   void _startSilenceTimer(){
//     _cancelSilenceTimer();
//     _silenceTimer = Timer(Duration(seconds: 5), (){
//       if(_isListening){
//         print("${DateTime.now()} silence timer stopped recording");
//         _stopListening();
//       }
//     });
//   }
//
//   void _cancelSilenceTimer(){
//     _silenceTimer?.cancel();
//     _silenceTimer = null;
//   }
//
//   void _resetSilenceTimer(){
//     _cancelSilenceTimer();
//     _startSilenceTimer();
//   }
//
//
//
//
//
//
//   void _scrollToBottom() {
//     Future.delayed(Duration(milliseconds: 100), () {
//       if (_scrollController.hasClients) {
//         _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
//       }
//     });
//   }
//
//
//
//
//
//   void _stopListeningTimer() {
//     _listeningTimer?.cancel();
//     _timerActive = false;
//   }
//
//   @override
//   void dispose() {
//     if (_speech.isAvailable) {
//       _speech.cancel();
//     }
//     _stopListeningTimer();
//     super.dispose();
//   }
//
//   Future<void> generateStory(String userMessage) async {
//
//     print("${DateTime.now()} generateStory started with: $userMessage"); // Log
//     if (userMessage.trim().isEmpty) {
//       print("${DateTime.now()} generateStory: userMessage is empty"); //Log
//       return;
//     }
//
//
//     final userVoiceRef = _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId);
//
//     try {
//       final chatDoc = await userVoiceRef.get();
//
//       if (!chatDoc.exists) {
//         await userVoiceRef.set({
//           'sessionStart': FieldValue.serverTimestamp(),
//           'timestamp': FieldValue.serverTimestamp(),
//           'title': userMessage,
//         });
//       }
//
//       if (chatDoc.exists &&
//           (chatDoc.data()?['title'] == "New Chat" ||
//               chatDoc.data()?['title'] == null)) {
//         String generatedTitle = _generateChatTitle(userMessage);
//         await userVoiceRef.update({'title': generatedTitle});
//       }
//
//       await _storeMessages(userMessage, ""); // Store user message immediately
//
//       _scrollToBottom();
//       setState(() => _isThinking = true);
//
//       String previousContext = await _getConversationHistory();
//
//       String prompt = '''
// $previousContext
//
// User: "$userMessage"
//
// Act as Thera AI, a therapy agent. Keep responses natural, concise (2-3 sentences, under 50 words). Expand only if explicitly asked. If unrelated, say: 'Thera AI for therapy. Focus on your well-being.' If asked your name, respond: 'I am Thera AI, a therapy agent."''';
//
//       final model = GenerativeModel(
//         model: 'gemini-1.5-flash',
//         apiKey: 'AIzaSyA11gq9jkuuoIPBkE_RWTO8K1M_J8q9dg0',
//       );
//
//       final response = await model.generateContent([Content.text(prompt)]);
//       String? aiResponse = response.text;
//
//       if (aiResponse != null) {
//         await _storeMessages("", aiResponse); // Store AI response
//         _simulateAiTyping(aiResponse); // Simulate typing AI's response
//         _playAudio(aiResponse);
//       }
//       _scrollToBottom();
//     } catch (e) {
//       print('Error generating content: $e');
//     } finally {
//       if(mounted){
//         setState(() => _isThinking = false);
//       }
//     }
//   }
//
//   // Simulate the AI's response typing effect
//   void _simulateAiTyping(String aiResponse) async {
//     if (!mounted)
//       return; // Prevent updates if the widget is no longer in the tree
//
//     String newResponse =
//         ""; // Store progressive response without excessive setState calls
//
//     setState(() {
//       _aiResponse = ""; // Reset AI's response once at the start
//     });
//
//     if (!_isMuted) {
//       await _tts.setLanguage("en-US");
//       await _tts.setSpeechRate(0.5);
//       await _tts.speak(aiResponse);
//     }
//
//     for (int i = 0; i < aiResponse.length; i++) {
//       await Future.delayed(Duration(milliseconds: 50)); // Control typing speed
//
//       newResponse = aiResponse.substring(0, i + 1); // Update text progressively
//
//       if (!mounted) return; // Ensure the widget is still active
//
//       // Only update UI when text has actually changed and if not muted
//       if (newResponse != _aiResponse) {
//         setState(() {
//           _aiResponse = newResponse;
//         });
//       }
//     }
//     print("${DateTime.now()} generateStory finished"); // Log
//   }
//
//   Set<String> storedMessages =
//   {}; // Store messages temporarily within this session
//
//   Future<void> _storeMessages(String userMessage, String aiResponse) async {
//     final userVoiceRef = _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId)
//         .collection('messages');
//
//     try {
//       if (userMessage.isNotEmpty) {
//         await userVoiceRef.add({
//           'sender': 'user',
//           'message': userMessage,
//           'timestamp': FieldValue.serverTimestamp(),
//         }).then((_) {
//           print("User message stored successfully: $userMessage");
//         }).catchError((error) {
//           print("Error storing user message: $error");
//         });
//       }
//
//       if (aiResponse.isNotEmpty) {
//         await userVoiceRef.add({
//           'sender': 'ai',
//           'message': aiResponse,
//           'timestamp': FieldValue.serverTimestamp(),
//         }).then((_) {
//           print("AI message stored successfully: $aiResponse");
//         }).catchError((error) {
//           print("Error storing AI message: $error");
//         });
//       }
//     } catch (e) {
//       print("Error in _storeMessages: $e");
//     }
//   }
//
//
//   Future<String> _getConversationHistory() async {
//     final messages = await _firestore
//         .collection('users')
//         .doc(_user.email)
//         .collection('chats')
//         .doc(_chatSessionId)
//         .collection('messages')
//         .orderBy('timestamp', descending: true)
//         .limit(5)
//         .get();
//
//     if (messages.docs.isEmpty) return "";
//
//     return messages.docs
//         .map((doc) => "${doc['sender']}: ${doc['message']}")
//         .toList()
//         .reversed
//         .join("\n");
//   }
//
//   void _playAudio(String text) async {
//     _lastSpokenText = text; // Store the text before speaking
//     if (!_isMuted) {
//       _isSpeaking = true;
//       await _tts.setLanguage("en-US");
//       await _tts.setVoice({"name": "en-us-x-iol-local", "locale": "en-US"}); // Set to a male voice
//       await _tts.setSpeechRate(0.5);
//       await _tts.speak(text);
//       _isSpeaking = false;
//     }
//   }
//
//   void _toggleMute() {
//     bool wasMuted = _isMuted; // Store the previous state
//     _isMuted = !_isMuted; // Toggle mute state
//
//     if (wasMuted != _isMuted) {
//       setState(() {}); // Only trigger rebuild if there's a change
//     }
//
//     if (_isMuted) {
//       _tts.stop();
//     } else if (_lastSpokenText.isNotEmpty) {
//       _tts.speak(_lastSpokenText);
//     }
//   }
//
//   Set<String> _animatedMessageIds = {};
//
//   @override
//   Widget build(BuildContext context) {
//     double deviceHeight = MediaQuery.of(context).size.height;
//     return Scaffold(
//       backgroundColor: Color(0xff070a12),
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
//
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             Expanded(
//               child: StreamBuilder<QuerySnapshot>(
//                 stream:
//                 FirebaseFirestore.instance
//                     .collection('users')
//                     .doc(_user.email)
//                     .collection('chats')
//                     .doc(_chatSessionId)
//                     .collection('messages')
//                     .orderBy('timestamp', descending: false)
//                     .snapshots(),
//                 builder: (context, snapshot) {
//                   if (!snapshot.hasData) {
//                     return Center(
//                       child: CircularProgressIndicator(
//                         color: Color(0xffe8fd52),
//                       ),
//                     );
//                   }
//
//                   var messages = snapshot.data!.docs;
//
//                   // Scroll to the bottom when the list is built or updated
//                   WidgetsBinding.instance.addPostFrameCallback((_) {
//                     if (_scrollController.hasClients) {
//                       _scrollController.jumpTo(
//                         _scrollController.position.maxScrollExtent,
//                       );
//                     }
//                   });
//
//                   if (messages.isEmpty) {
//                     return Center(
//                       child: Container(
//                         width: double.infinity, // Take full width
//                         height: double.infinity, // Take full height
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
//                                 padding: EdgeInsets.symmetric(
//                                   vertical: deviceHeight * 0.01,
//                                   horizontal: deviceHeight * 0.018,
//                                 ),
//                                 child: Text(
//                                   textAlign: TextAlign.center,
//                                   "Start a conversation by tapping the mic!",
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
//                                 padding: EdgeInsets.symmetric(
//                                   vertical: deviceHeight * 0.01,
//                                   horizontal: deviceHeight * 0.018,
//                                 ),
//                                 child: Text(
//                                   textAlign: TextAlign.center,
//                                   "Your AI therapist is here to listen, support, and guide you through your thoughts. Speak freely, and let your journey to self-discovery begin.",
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
//                                 padding: EdgeInsets.symmetric(
//                                   vertical: deviceHeight * 0.01,
//                                   horizontal: deviceHeight * 0.018,
//                                 ),
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
//                     );
//                   }
//
//                   return ListView.builder(
//                     controller: _scrollController,
//                     itemCount: messages.length + (_isThinking ? 1 : 0), // Add 1 for LoadingDots if thinking
//                     itemBuilder: (context, index) {
//                       if (_isThinking && index == messages.length) {
//                         // Show LoadingDots at the end
//                         return Align(
//                           alignment: Alignment.centerLeft, // Align to left like AI messages
//                           child: Padding(
//                             padding: const EdgeInsets.all(12.0),
//                             child: LoadingDots(),
//                           ),
//                         );
//                       }
//
//                       var message = messages[index].data() as Map<String, dynamic>?;
//                       if (message == null) return SizedBox();
//
//                       var messageText = message['message'] ?? "";
//                       var sender = message['sender'] ?? "";
//                       var messageId = messages[index].id;
//
//                       bool isUser = sender == "user";
//                       bool isAI = sender == "ai";
//                       bool isLatestMessage = index == messages.length - 1;
//
//                       return Align(
//                         alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                         child: Container(
//                           margin: EdgeInsets.symmetric(vertical: 5),
//                           padding: EdgeInsets.all(12),
//                           constraints: BoxConstraints(
//                             maxWidth: isUser ? MediaQuery.of(context).size.width * 0.75 : MediaQuery.of(context).size.width * 1,
//                           ),
//                           decoration: BoxDecoration(
//                             color: isUser ? Colors.blueGrey[900] : Colors.transparent,
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                           child: isLatestMessage && !_animatedMessageIds.contains(messageId)
//                               ? AnimatedTextKit(
//                             animatedTexts: [
//                               TypewriterAnimatedText(
//                                 cursor: "",
//                                 messageText,
//                                 textStyle: TextStyle(color: Colors.white, fontSize: 16),
//                                 speed: Duration(milliseconds: 50),
//                               ),
//                             ],
//                             totalRepeatCount: 1,
//                             isRepeatingAnimation: false,
//                             onFinished: () {
//                               setState(() {
//                                 _animatedMessageIds.add(messageId);
//                               });
//                             },
//                           )
//                               : Text(
//                             messageText,
//                             style: TextStyle(color: Colors.white, fontSize: 16),
//                           ),
//                         ),
//                       );
//                     },
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//       ),
//
//       bottomNavigationBar: Container(
//         decoration: BoxDecoration(
//             color:  Colors.grey.withAlpha(30),
//             borderRadius: BorderRadius.only(
//               topLeft: Radius.circular(deviceHeight*0.03),
//               topRight: Radius.circular(deviceHeight*0.03), // Corrected line
//             )
//         ),
//         height: deviceHeight*0.1,
//         width: double.maxFinite,
//         child: Padding(
//           padding: EdgeInsets.symmetric(horizontal: deviceHeight*0.02, vertical: deviceHeight*0.01),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//             children: [
//               FloatingActionButton(
//                 heroTag: "recording",
//                 backgroundColor:  _isListening ? Colors.red[50] : Color(0xffe8fd52),
//                 onPressed: _toggleRecording,
//                 child: Icon(
//                   _isListening ? Icons.stop : Icons.mic,
//                   color: Colors.black,
//                 ),
//               ),
//
//               Container(
//                 decoration: BoxDecoration(
//                     color: Colors.transparent,
//                     borderRadius: BorderRadius.circular(deviceHeight*0.01)
//                 ),
//                 child: Padding(
//                   padding: EdgeInsets.symmetric(horizontal: deviceHeight*0.02, vertical: deviceHeight*0.005),
//                   child: Text(textAlign: TextAlign.center,"Tap mic to start therapy...", style: TextStyle(color: Colors.white60, fontSize: deviceHeight*0.018),),
//                 ),
//               ),
//
//               FloatingActionButton(
//                 heroTag: "mute",
//                 backgroundColor:  _isMuted ? Colors.red[50] : Color(0xffe8fd52),
//                 onPressed: _toggleMute,
//                 child: Icon(
//                   _isMuted ? Icons.volume_off : Icons.volume_up,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//
//       // floatingActionButton: Column(
//       //   mainAxisAlignment: MainAxisAlignment.end,
//       //   children: [
//       //     FloatingActionButton(
//       //       heroTag: "recording",
//       //       backgroundColor: Color(0xffe8fd52),
//       //       onPressed: _toggleRecording,
//       //       child: Icon(
//       //         _isListening ? Icons.stop : Icons.mic,
//       //         color: Colors.black,
//       //       ),
//       //     ),
//       //     SizedBox(height: 16),
//       //     FloatingActionButton(
//       //       heroTag: "mute",
//       //       backgroundColor: Color(0xffe8fd52),
//       //       onPressed: _toggleMute,
//       //       child: Icon(
//       //         _isMuted ? Icons.volume_off : Icons.volume_up,
//       //         color: Colors.black,
//       //       ),
//       //     ),
//       //   ],
//       // ),
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



import 'dart:async';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../main.dart';
import 'apikey.dart';
import 'connectivity_provider.dart';

class VoiceChatScreen extends StatefulWidget {
  const VoiceChatScreen({super.key});

  @override
  State<VoiceChatScreen> createState() => _VoiceChatScreenState();
}

class _VoiceChatScreenState extends State<VoiceChatScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _user = FirebaseAuth.instance.currentUser!;
  final ScrollController _scrollController = ScrollController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isMuted = false;
  String _lastSpokenText = "";
  bool _isThinking = false;
  bool _isSpeechAvailable = false;
  bool _stopListeningCalled = false;
  bool _speechFinished = false;
  bool _isListening = false;
  String _text = "";
  String _aiResponse = "";
  String _chatSessionId = Uuid().v4();
  bool _isSpeaking = false;
  Timer? _silenceTimer;
  Timer? _listeningTimer;
  bool _timerActive = false;
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
    _fetchApiKey();
    _checkUserAccess(); // Check access on initialization
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeSpeech();
    });
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

  String _generateChatTitle(String firstMessage) {
    List<String> words = firstMessage.split(' ');
    if (words.length <= 3) return firstMessage;
    return words.take(3).join(' ') + '...';
  }

  void _reInitializeSpeech() async {
    if (_speech.isAvailable) {
      _speech.cancel();
    }
    _initializeSpeech();
  }

  Future<bool> _initializeSpeech() async {
    _isSpeechAvailable = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          print("${DateTime.now()} Speech recognition error: $error");
          _setListeningState(false);
          _isSpeechAvailable = false;
        }
      },
    );
    if (!_isSpeechAvailable) {
      print("${DateTime.now()} Speech recognition is not available.");
    }
    return _isSpeechAvailable;
  }

  void _toggleRecording() async {
    if (!hasAccess) return; // Prevent recording if no access
    if (!_isSpeechAvailable) {
      bool isSpeechInitialized = await _initializeSpeech();
      if (!isSpeechInitialized) {
        print("speech is not available");
        return;
      }
    }

    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _startListening() {
    if (_isListening) {
      print("${DateTime.now()} _startListening called but _isListening is already true");
      return;
    }

    print("${DateTime.now()} _startListening called");
    _setListeningState(true);
    _text = "";
    _aiResponse = "";
    _stopListeningCalled = false;
    _speechFinished = false;

    _speech.listen(
      onResult: (result) {
        print("Speech Result: ${result.recognizedWords}, final: ${result.finalResult}");
        setState(() {
          _text = result.recognizedWords;
        });
        if (result.finalResult) {
          print("${DateTime.now()} onResult: final: true");
          _speechFinished = true;
          _processSpeech();
        } else {
          _resetSilenceTimer();
        }
      },
      listenMode: stt.ListenMode.dictation,
      listenFor: Duration(minutes: 1),
      pauseFor: Duration(seconds: 5),
      partialResults: true,
    );
    _startSilenceTimer();
  }

  void _stopListening() {
    if (_stopListeningCalled) {
      print("${DateTime.now()} _stopListening already called");
      return;
    }
    _stopListeningCalled = true;

    if (!_isListening) {
      print("${DateTime.now()} _stopListening called but _isListening is already false");
      return;
    }
    print("${DateTime.now()} _stopListening called");
    _speech.stop().then((_) {
      if (_speechFinished == false) {
        _processSpeech();
      }
    });
    _cancelSilenceTimer();
  }

  void _processSpeech() {
    _setListeningState(false);
    if (_text.isNotEmpty) {
      print("${DateTime.now()} calling generateStory with: $_text");
      generateStory(_text);
    } else {
      print("${DateTime.now()} _text is empty, not calling generateStory");
    }
  }

  void _setListeningState(bool listening) {
    if (mounted) {
      setState(() {
        print("${DateTime.now()} Setting _isListening to $listening");
        _isListening = listening;
      });
    }
  }

  void _startSilenceTimer() {
    _cancelSilenceTimer();
    _silenceTimer = Timer(Duration(seconds: 5), () {
      if (_isListening) {
        print("${DateTime.now()} silence timer stopped recording");
        _stopListening();
      }
    });
  }

  void _cancelSilenceTimer() {
    _silenceTimer?.cancel();
    _silenceTimer = null;
  }

  void _resetSilenceTimer() {
    _cancelSilenceTimer();
    _startSilenceTimer();
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _stopListeningTimer() {
    _listeningTimer?.cancel();
    _timerActive = false;
  }

  @override
  void dispose() {
    if (_speech.isAvailable) {
      _speech.cancel();
    }
    _stopListeningTimer();
    super.dispose();
  }

  Future<void> generateStory(String userMessage) async {
    if (!hasAccess) return; // Prevent generation if no access

    print("${DateTime.now()} generateStory started with: $userMessage");
    if (userMessage.trim().isEmpty) {
      print("${DateTime.now()} generateStory: userMessage is empty");
      return;
    }

    final userVoiceRef = _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(_chatSessionId);

    try {
      final chatDoc = await userVoiceRef.get();

      if (!chatDoc.exists) {
        await userVoiceRef.set({
          'sessionStart': FieldValue.serverTimestamp(),
          'timestamp': FieldValue.serverTimestamp(),
          'title': userMessage,
        });
      }

      if (chatDoc.exists &&
          (chatDoc.data()?['title'] == "New Chat" || chatDoc.data()?['title'] == null)) {
        String generatedTitle = _generateChatTitle(userMessage);
        await userVoiceRef.update({'title': generatedTitle});
      }

      await _storeMessages(userMessage, "");

      _scrollToBottom();
      setState(() => _isThinking = true);

      String previousContext = await _getConversationHistory();

      String prompt = '''
$previousContext

User: "$userMessage"

Act as Thera AI, a therapy agent. Your responses should be natural, concise (2-3 sentences, under 50 words), and strictly related to therapeutic conversations. You are NOT to ask questions unless the user explicitly asks you to. If the user asks a question that is NOT directly related to therapy or well-being, respond ONLY with: 'I'm Thera AI for therapy. Focus on your well-being.' Do not attempt to answer unrelated questions. If the user explicitly asks you to expand on a topic, then you may provide more detailed information. If asked your name, respond: 'I am Thera AI, a therapy agent."''';

      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apikey,
      );

      final response = await model.generateContent([Content.text(prompt)]);
      String? aiResponse = response.text;

      if (aiResponse != null) {
        await _storeMessages("", aiResponse);
        _simulateAiTyping(aiResponse);
        _playAudio(aiResponse);
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

  void _simulateAiTyping(String aiResponse) async {
    if (!mounted) return;

    String newResponse = "";
    setState(() {
      _aiResponse = "";
    });

    if (!_isMuted) {
      await _tts.setLanguage("en-US");
      await _tts.setSpeechRate(0.5);
      await _tts.speak(aiResponse);
    }

    for (int i = 0; i < aiResponse.length; i++) {
      await Future.delayed(Duration(milliseconds: 50));
      newResponse = aiResponse.substring(0, i + 1);
      if (!mounted) return;
      if (newResponse != _aiResponse) {
        setState(() {
          _aiResponse = newResponse;
        });
      }
    }
    print("${DateTime.now()} generateStory finished");
  }

  Set<String> storedMessages = {};

  Future<void> _storeMessages(String userMessage, String aiResponse) async {
    final userVoiceRef = _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(_chatSessionId)
        .collection('messages');

    try {
      if (userMessage.isNotEmpty) {
        await userVoiceRef.add({
          'sender': 'user',
          'message': userMessage,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      if (aiResponse.isNotEmpty) {
        await userVoiceRef.add({
          'sender': 'ai',
          'message': aiResponse,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Error in _storeMessages: $e");
    }
  }

  Future<String> _getConversationHistory() async {
    final messages = await _firestore
        .collection('users')
        .doc(_user.email)
        .collection('chats')
        .doc(_chatSessionId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(5)
        .get();

    if (messages.docs.isEmpty)

    return "";

    return messages.docs
        .map((doc) => "${doc['sender']}: ${doc['message']}")
        .toList()
        .reversed
        .join("\n");
  }

  void _playAudio(String text) async {
    _lastSpokenText = text;
    if (!_isMuted) {
      _isSpeaking = true;
      await _tts.setLanguage("en-US");
      await _tts.setVoice({"name": "en-us-x-iol-local", "locale": "en-US"});
      await _tts.setSpeechRate(0.5);
      await _tts.speak(text);
      _isSpeaking = false;
    }
  }

  void _toggleMute() {
    bool wasMuted = _isMuted;
    _isMuted = !_isMuted;
    if (wasMuted != _isMuted) {
      setState(() {});
    }
    if (_isMuted) {
      _tts.stop();
    } else if (_lastSpokenText.isNotEmpty) {
      _tts.speak(_lastSpokenText);
    }
  }

  Set<String> _animatedMessageIds = {};

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        if (connectivityProvider.isOffline) {
          return NoInternetScreen(); // Or show a snackbar, etc.
        }
        return Scaffold(
          backgroundColor: Color(0xff070a12),
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
              ? _buildChatUI(deviceHeight) // Normal UI if user has access
              : _buildNoAccessUI(deviceHeight), // No access UI
        );

      },
    );

  }

  // Normal chat UI
  Widget _buildChatUI(double deviceHeight) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
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
                    child: CircularProgressIndicator(
                      color: Color(0xffe8fd52),
                    ),
                  );
                }

                var messages = snapshot.data!.docs;

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                  }
                });

                if (messages.isEmpty) {
                  return Center(
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
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
                                vertical: deviceHeight * 0.01,
                                horizontal: deviceHeight * 0.018,
                              ),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Start a conversation by tapping the mic!",
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
                                vertical: deviceHeight * 0.01,
                                horizontal: deviceHeight * 0.018,
                              ),
                              child: Text(
                                textAlign: TextAlign.center,
                                "Your AI therapist is here to listen, support, and guide you through your thoughts. Speak freely, and let your journey to self-discovery begin.",
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
                                vertical: deviceHeight * 0.01,
                                horizontal: deviceHeight * 0.018,
                              ),
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
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: messages.length + (_isThinking ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isThinking && index == messages.length) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: LoadingDots(),
                        ),
                      );
                    }

                    var message = messages[index].data() as Map<String, dynamic>?;
                    if (message == null) return SizedBox();

                    var messageText = message['message'] ?? "";
                    var sender = message['sender'] ?? "";
                    var messageId = messages[index].id;

                    bool isUser = sender == "user";
                    bool isLatestMessage = index == messages.length - 1;

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
                        child: isLatestMessage && !_animatedMessageIds.contains(messageId)
                            ? AnimatedTextKit(
                          animatedTexts: [
                            TypewriterAnimatedText(
                              cursor: "",
                              messageText,
                              textStyle: TextStyle(color: Colors.white, fontSize: 16),
                              speed: Duration(milliseconds: 50),
                            ),
                          ],
                          totalRepeatCount: 1,
                          isRepeatingAnimation: false,
                          onFinished: () {
                            setState(() {
                              _animatedMessageIds.add(messageId);
                            });
                          },
                        )
                            : Text(
                          messageText,
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
            decoration: BoxDecoration(
              color: Colors.grey.withAlpha(30),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(deviceHeight * 0.02),
                topRight: Radius.circular(deviceHeight * 0.02),
                bottomLeft: Radius.circular(deviceHeight * 0.02),
                bottomRight: Radius.circular(deviceHeight * 0.02),
              ),
            ),
            height: deviceHeight * 0.1,
            width: double.maxFinite,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: deviceHeight * 0.02, vertical: deviceHeight * 0.01),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FloatingActionButton(
                    heroTag: "recording",
                    backgroundColor: _isListening ? Colors.red[50] : Color(0xffe8fd52),
                    onPressed: _toggleRecording,
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(deviceHeight * 0.01),
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: deviceHeight * 0.02, vertical: deviceHeight * 0.005),
                      child: Text(
                        textAlign: TextAlign.center,
                        "Tap mic to start therapy...",
                        style: TextStyle(color: Colors.white60, fontSize: deviceHeight * 0.018),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: "mute",
                    backgroundColor: _isMuted ? Colors.red[50] : Color(0xffe8fd52),
                    onPressed: _toggleMute,
                    child: Icon(
                      _isMuted ? Icons.volume_off : Icons.volume_up,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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