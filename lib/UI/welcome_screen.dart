import 'package:ai_therapist/UI/personal_details.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'connectivity_provider.dart';
import 'homeScreen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Google Sign-In method
  Future<User?> signInWithGoogle(BuildContext context) async {
    try {
      print("🟢 Starting Google Sign-In process...");

      // Trigger Google Sign-In flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ Google Sign-In canceled.");
        return null; // User canceled sign-in
      }

      print("✅ Google Sign-In successful. Fetching authentication...");

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        print("✅ Firebase authentication successful for ${user.email}.");

        // Fetch Firestore user data
        print("🔍 Checking if user exists in Firestore...");
        DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(user.email).get();

        if (userDoc.exists && userDoc.data() != null) {
          print("✅ User exists in Firestore. Navigating to HomeScreen...");
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
            );
          }
        } else {
          print("🚨 User does NOT exist in Firestore. Navigating to PersonalDetails...");
          if (context.mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => PersonalDetails()),
            );
          }
        }
      }

      return user;
    } catch (e) {
      print("Google Sign-In error: $e");
      return null;
    }
  }




  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.sizeOf(context).height;
    double deviceWidth = MediaQuery.sizeOf(context).width;

    return Consumer<ConnectivityProvider>(
      builder: (context, connectivityProvider, child) {
        if (connectivityProvider.isOffline) {
          return NoInternetScreen(); // Or show a snackbar, etc.
        }
        return Scaffold(
          body: Stack(
            children: [
              // Background Image moved further up WITHOUT changing its size
              Positioned(
                top: -deviceHeight * 0.15, // Moves image up by 15% of screen height
                left: 0,
                right: 0,
                child: Container(
                  height: deviceHeight * 1.15,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/welcome_image.jpg"),
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter, // Ensures main part is visible
                    ),
                  ),
                ),
              ),

              // Gradient Overlay (Keeps same black effect)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black,
                      Colors.black.withOpacity(0.95),
                      Colors.black.withOpacity(0.9),
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.75),
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: [0.0, 0.1, 0.2, 0.3, 0.45, 0.55, 0.7, 1.0],
                  ),
                ),
              ),

              // Bottom Content
              Positioned(
                bottom: deviceHeight * 0.12,
                left: deviceWidth * 0.05,
                right: deviceWidth * 0.05,
                child: Column(
                  children: [

                    Image.asset("assets/images/brain.png", scale: 7.0,),
                    SizedBox(height: deviceHeight * 0.015),
                    Text(
                      "Your AI Therapist, Anytime, Anywhere.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85), // Slightly dim for soft effect
                        fontSize: deviceHeight * 0.018, // Smaller than Welcome text
                        fontWeight: FontWeight.w300, // Light weight
                        letterSpacing: 1.2, // Modern spacing
                      ),
                    ),
                    SizedBox(height: deviceHeight * 0.040),

                    Container(
                      height: deviceHeight * 0.065,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 0.4), // White border
                      ),
                      child: Center(
                        child: Text(
                          "Welcome to TheraAI",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: deviceHeight * 0.024,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: deviceHeight * 0.02),

                    // Get Started Button
                    GestureDetector(
                      onTap: (){
                        signInWithGoogle(context);
                        // Navigator.push(context, MaterialPageRoute(builder: (context)=> PersonalDetails()));
                      },
                      child: Container(
                        height: deviceHeight * 0.065,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Color(0xffe8fd52),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/images/google.png", height: deviceHeight*0.025,),
                              SizedBox(width: 10,),
                              Text(
                                "Sign up with Google",
                                style: TextStyle(
                                  color: Color(0xff2e3032),
                                  fontWeight: FontWeight.w900,
                                  fontSize: deviceHeight * 0.018,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

  }
}
