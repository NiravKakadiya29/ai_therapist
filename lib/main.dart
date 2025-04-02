// import 'package:ai_therapist/UI/homeScreen.dart';
// import 'package:ai_therapist/UI/voice_chat_screen.dart';
// import 'package:ai_therapist/UI/welcome_screen.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter/services.dart';
//
// import 'UI/personal_details.dart';
//
// void main() async {
//   SystemChrome.setSystemUIOverlayStyle(
//     SystemUiOverlayStyle(
//       statusBarColor: Colors.transparent, // Transparent status bar
//       statusBarIconBrightness:
//           Brightness.dark, // Change to Brightness.dark for dark icons
//     ),
//   );
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: FirebaseOptions(
//       apiKey: "AIzaSyAMEYJcHThGoHgJmZEiDvEo-yowdSKraVA",
//       appId: "1:548096831016:android:0a8403bbbe778974878f1d",
//       messagingSenderId: "548096831016",
//       projectId: "ai-therapist-e673c",
//     ),
//   );
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Thera AI',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(primaryColor: const Color(0xffe8fd52)),
//       home: StreamBuilder<User?>(
//         stream: FirebaseAuth.instance.authStateChanges(),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.active) {
//             if (snapshot.hasData) {
//               User? user = snapshot.data;
//
//               // Check if user data exists in Firestore
//               return FutureBuilder<DocumentSnapshot>(
//                 future:
//                     FirebaseFirestore.instance
//                         .collection('users')
//                         .doc(
//                           FirebaseAuth.instance.currentUser?.email.toString(),
//                         )
//                         .get(),
//                 builder: (context, userSnapshot) {
//                   if (userSnapshot.connectionState == ConnectionState.waiting) {
//                     return AnnotatedRegion<SystemUiOverlayStyle>(
//                       value: SystemUiOverlayStyle(
//                         statusBarColor: Colors.transparent, // Keep it transparent for a seamless look
//                         statusBarIconBrightness: Brightness.light, // Light icons for dark background
//                       ),
//                       child: Scaffold(
//                         backgroundColor: Color(0xff070a12),
//                         body: Center(
//                           child: CircularProgressIndicator(color: Color(0xffe8fd52)),
//                         ),
//                       ),
//                     );
//                   }
//                   if (userSnapshot.hasData && userSnapshot.data!.exists) {
//                     return HomeScreen(); // User data exists, go to HomeScreen
//                   } else {
//                     return PersonalDetails(); // User data does not exist, go to PersonalDetails
//                   }
//                 },
//               );
//             } else {
//               return WelcomeScreen(); // No user logged in
//             }
//           }
//
//           // Show a loading screen while checking auth state
//           return AnnotatedRegion<SystemUiOverlayStyle>(
//             value: SystemUiOverlayStyle(
//               statusBarColor: Colors.transparent, // Keep it transparent for a seamless look
//               statusBarIconBrightness: Brightness.light, // Light icons for dark background
//             ),
//             child: Scaffold(
//               backgroundColor: Color(0xff070a12),
//               body: Center(
//                 child: CircularProgressIndicator(color: Color(0xffe8fd52)),
//               ),
//             ),
//           );
//
//         },
//       ),
//     );
//   }
// }


import 'package:ai_therapist/UI/homeScreen.dart';
import 'package:ai_therapist/UI/welcome_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'UI/connectivity_provider.dart';
import 'UI/personal_details.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyAMEYJcHThGoHgJmZEiDvEo-yowdSKraVA",
      appId: "1:548096831016:android:0a8403bbbe778974878f1d",
      messagingSenderId: "548096831016",
      projectId: "ai-therapist-e673c",
    ),
  );

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ChangeNotifierProvider( // Wrap MyApp with ChangeNotifierProvider
      create: (context) => ConnectivityProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thera AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: const Color(0xffe8fd52)),
      home: Consumer<ConnectivityProvider>( // Use Consumer to access ConnectivityProvider
        builder: (context, connectivityProvider, child) {
          if (connectivityProvider.isOffline) {
            return NoInternetScreen();
          }
          return StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.email.toString())
                        .get(),
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return LoadingScreen();
                      }
                      if (userSnapshot.hasData && userSnapshot.data!.exists) {
                        return HomeScreen();
                      } else {
                        return PersonalDetails();
                      }
                    },
                  );
                } else {
                  return WelcomeScreen();
                }
              }
              return LoadingScreen();
            },
          );
        },
      ),
    );
  }
}

class NoInternetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff070a12),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/no_internet.png', width: 200, height: 200),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Please check your Internet! You are offline.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoadingScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xff070a12),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xffe8fd52)),
      ),
    );
  }
}




