import 'package:ai_therapist/UI/text_chat_history.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'connectivity_provider.dart';

class TextChatHistoryList extends StatefulWidget {
  const TextChatHistoryList({super.key});

  @override
  State<TextChatHistoryList> createState() => _TextChatHistoryListState();
}

class _TextChatHistoryListState extends State<TextChatHistoryList> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final List<Color> iconColors = [
    const Color(0xffe8fd52),
    const Color(0xffc09ff8),
    const Color(0xffffc4dd),
  ];

  Future<void> _deleteChatSession(String sessionId) async {
    try {
      final chatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.email.toString())
          .collection('chats')
          .doc(sessionId);
      final messagesRef = chatRef.collection('messages');
      final messagesSnapshot = await messagesRef.get();
      final batch = FirebaseFirestore.instance.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      await chatRef.delete();
      print("Chat session $sessionId deleted successfully");
    } catch (e) {
      print("Error deleting chat session $sessionId: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to delete chat: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.sizeOf(context).height;
    double deviceWidth = MediaQuery.sizeOf(context).width;
    User? _user = _auth.currentUser;

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
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xffe8fd52),
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
                backgroundColor: Color(0xff070a12),
                backgroundImage: const AssetImage(
                  "assets/images/ai_profile.webp",
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          body:
          _user == null
              ? Center(
            child: Text(
              "User not logged in",
              style: TextStyle(
                color: Colors.white,
                fontSize: deviceHeight * 0.02,
              ),
            ),
          )
              : StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(FirebaseAuth.instance.currentUser!.email.toString())
                .collection('chats')
                .orderBy("timestamp", descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return  Center(child: CircularProgressIndicator(color: Color(0xffe8fd52),));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    "No chat history available",
                    style: TextStyle(color: Colors.white, fontSize: deviceHeight * 0.02),
                  ),
                );
              }
              var chats = snapshot.data!.docs;
              final iconColors = [
                const Color(0xffffc4dd), // Soft Pink
                const Color(0xffc09ff8), // Light Purple
                const Color(0xffe8fd52), // Vibrant Yellow-Green
                const Color(0xffff9999), // Soft Coral
                const Color(0xffb3c8ff), // Lavender Blue
                const Color(0xffa3f7bf), // Mint Green
                const Color(0xffffb997), // Peach
                const Color(0xff7de7eb), // Sky Cyan
                const Color(0xffffd166),
              ];

              return Padding(
                padding: EdgeInsets.all(deviceHeight * 0.02),
                child: MasonryGridView.count(
                  crossAxisCount: 2, // 2 columns
                  mainAxisSpacing: deviceHeight * 0.015,
                  crossAxisSpacing: deviceWidth * 0.02,
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
                            builder: (context) => TextChatHistory(sessionId: sessionId),
                          ),
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        transform: Matrix4.identity()..scale(1.0), // Subtle tap feedback
                        child: Container(
                          height: deviceHeight * 0.08, // Fixed height for consistency
                          decoration: BoxDecoration(
                            color: index % 2 == 0 ? Colors.grey.withAlpha(20) : Colors.grey.withAlpha(10),
                            borderRadius: BorderRadius.circular(deviceHeight * 0.015),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.02, vertical: deviceHeight * 0.01),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                height: deviceHeight * 0.035,
                                width: deviceHeight * 0.035,
                                decoration: BoxDecoration(
                                  color: iconColors[index % 9],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.history_outlined,
                                  color: const Color(0xff070a12),
                                  size: deviceHeight * 0.02,
                                ),
                              ),
                              SizedBox(width: deviceWidth * 0.02),
                              Expanded(
                                child: Text(
                                  chatTitle,
                                  style: const TextStyle(
                                    color: Color(0xffcccccb),
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              GestureDetector(
                                onTap: () async {
                                  bool? confirm = await showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: const Color(0xff1f2229),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(deviceHeight * 0.015),
                                      ),
                                      title: Text(
                                        "Delete Chat",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: deviceHeight * 0.025,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: Text(
                                        "Are you sure you want to delete '$chatTitle'?",
                                        style: TextStyle(
                                          color: const Color(0xffcccccb),
                                          fontSize: deviceHeight * 0.020,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, false),
                                          child: Text(
                                            "Cancel",
                                            style: TextStyle(
                                              color: const Color(0xffe8fd52),
                                              fontSize: deviceHeight * 0.020,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context, true),
                                          child: Text(
                                            "Delete",
                                            style: TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: deviceHeight * 0.020,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    await _deleteChatSession(sessionId);
                                  }
                                },
                                child: Icon(
                                  CupertinoIcons.delete_solid,
                                  color: const Color(0xffcccccb),
                                  size: deviceHeight * 0.025,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );

  }
}
