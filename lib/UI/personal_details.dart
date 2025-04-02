import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'connectivity_provider.dart';
import 'homeScreen.dart';

class PersonalDetails extends StatefulWidget {
  const PersonalDetails({super.key});

  @override

  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  @override
  void initState() {
    super.initState();
    // Set status bar text to light (white icons and text)
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Transparent status bar
        statusBarIconBrightness: Brightness.light, // White icons
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );
  }

  void showErrorDialog(BuildContext context, String error) {
    showDialog(
      context: context,
      barrierDismissible: true, // Allows tapping outside to close
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xff1f2229), // Darker theme color
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.height * 0.02),
        ),
        elevation: 10, // Adds a shadow effect
        title: Icon(Icons.warning_amber_rounded, color: Color(0xffe8fd52), size: MediaQuery.of(context).size.height * 0.06),
        content: Text(
          error,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xffcccccb),
            fontSize: MediaQuery.of(context).size.height * 0.020,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }


  Future<void> storeUserDetails(
      BuildContext context,
      TextEditingController nameController,
      TextEditingController mobileController,
      TextEditingController ageController) async {
    try {
      // Get the current signed-in user
      final User? user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        print("No user signed in");
        return;
      }

      // Get the user details from controllers
      String name = nameController.text.trim();
      String mobileNumber = mobileController.text.trim();
      String age = ageController.text.trim();

      // Get the current date and time
      DateTime now = DateTime.now();

      // Subscription details
      DateTime pastDate = now.subtract(Duration(days: 1)); // Previous day
      DateTime freeSessionEnd = now.add(Duration(days: 7)); // 7 days after today

      // Create a user data map
      Map<String, dynamic> userData = {
        'name': name,
        'mobile_number': int.parse(mobileNumber),
        'age': age,
        'email': user.email,
        'payment_id': "",
        'subscription_type': "",
        'isSubscribed': false,
        'subscription_start_date': Timestamp.fromDate(pastDate), // Store as Timestamp
        'subscription_end_date': Timestamp.fromDate(pastDate),   // Store as Timestamp
        'free_session_start_date': Timestamp.fromDate(now),      // Store as Timestamp
        'free_session_end_date': Timestamp.fromDate(freeSessionEnd), // Store as Timestamp
      };

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.email).set(userData);

      // Navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      print("Error storing user details: $e");
    }
  }


  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();


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
          backgroundColor: Color(0xff070a12),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: deviceHeight*0.08,),
                  Text(
                    "Personal Details",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: deviceHeight * 0.030,
                    ),
                  ),
                  SizedBox(height: deviceHeight*0.01,),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
                    child: Text(
                      "Please fill your information below and continue your therapy",
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w900,
                        fontSize: deviceHeight * 0.015,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: deviceHeight*0.05,),
                  Align(
                    child: Text(
                      "Name",
                      style: TextStyle(
                        color: Color(0xffdcdcdc),
                        fontWeight: FontWeight.bold,
                        fontSize: deviceHeight * 0.018,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  SizedBox(height: deviceHeight*0.01,),
                  TextField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    cursorColor: Color(0xffe8fd52),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your name here',
                      hintStyle: TextStyle(color: Color(0xff707073)),
                      filled: true,
                      fillColor: Color(0xff1f2229), // ✅ Light Grey Background
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // ✅ Rectangle shape
                        borderSide: BorderSide(color: Color(0xf24262d), width: 2.0), // ✅ Grey border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xf24262d), width: 1.0), // ✅ Darker grey on focus
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),


                  SizedBox(height: deviceHeight*0.03,),
                  Align(
                    child: Text(
                      "Mobile Number",
                      style: TextStyle(
                        color: Color(0xffdcdcdc),
                        fontWeight: FontWeight.bold,
                        fontSize: deviceHeight * 0.018,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  SizedBox(height: deviceHeight*0.01,),
                  TextField(
                    controller: _mobileNumberController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    cursorColor: Color(0xffe8fd52),
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'Enter your mobile number here',
                      hintStyle: TextStyle(color: Color(0xff707073)),
                      filled: true,
                      fillColor: Color(0xff1f2229), // ✅ Light Grey Background
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // ✅ Rectangle shape
                        borderSide: BorderSide(color: Color(0xf24262d), width: 2.0), // ✅ Grey border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xf24262d), width: 1.0), // ✅ Darker grey on focus
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    ),
                  ),

                  SizedBox(height: deviceHeight*0.03,),
                  Align(
                    child: Text(
                      "Age",
                      style: TextStyle(
                        color: Color(0xffdcdcdc),
                        fontWeight: FontWeight.bold,
                        fontSize: deviceHeight * 0.018,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    alignment: Alignment.centerLeft,
                  ),
                  SizedBox(height: deviceHeight*0.01,),
                  TextField(
                    controller: _ageController,
                    maxLength: 2,
                    cursorColor: Color(0xffe8fd52),
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Enter your age here',
                      hintStyle: TextStyle(color: Color(0xff707073)),
                      filled: true,
                      fillColor: Color(0xff1f2229), // ✅ Light Grey Background
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // ✅ Rectangle shape
                        borderSide: BorderSide(color: Color(0xf24262d), width: 2.0), // ✅ Grey border
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Color(0xf24262d), width: 1.0), // ✅ Darker grey on focus
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                      counterText: '',
                    ),
                  ),

                  SizedBox(height: deviceHeight*0.05,),

                  GestureDetector(
                    onTap: () {
                      String name = _nameController.text.trim();
                      String mobile = _mobileNumberController.text.trim();
                      String age = _ageController.text.trim();

                      // Validation checks
                      if (name.isEmpty) {
                        showErrorDialog(context, "Name cannot be empty.");
                        return;
                      }

                      if (mobile.isEmpty) {
                        showErrorDialog(context, "Mobile number cannot be empty.");
                        return;
                      }

                      if (mobile.length < 10) {
                        showErrorDialog(context, "Mobile number must be at least 10 digits.");
                        return;
                      }

                      if (age.isEmpty) {
                        showErrorDialog(context, "Age cannot be empty.");
                        return;
                      }

                      if (age.length > 2) {
                        showErrorDialog(context, "Age must be a maximum of 2 digits.");
                        return;
                      }

                      // If all validations pass, proceed with storing user details
                      storeUserDetails(context, _nameController, _mobileNumberController, _ageController);
                    },
                    child: Container(
                      height: deviceHeight * 0.065,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xffe8fd52), // Background color (White)
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all( // Adding black border
                          color: Colors.black,
                          width: 1.5, // Border thickness
                        ),
                      ),
                      child: Center(
                        child: Text(
                          "Next",
                          style: TextStyle(
                            color: Color(0xff000000), // Changed text color to black for visibility
                            fontWeight: FontWeight.w900,
                            fontSize: deviceHeight * 0.020,
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: deviceHeight*0.02,),

                  RichText(
                    textAlign: TextAlign.center,

                    text: TextSpan(
                      style: TextStyle(color: Colors.black, fontSize: 16, height: 1.4),
                      children: [
                        TextSpan(text: "By continuing, you are agreeing to our", style: TextStyle(color: Colors.white)),
                        TextSpan(
                          text: "\nTerms & Conditions",
                          style: TextStyle(
                            color: Color(0xffe8fd52),
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              // TODO: Navigate to the Terms & Conditions page
                              print("Terms & Conditions tapped!");
                            },
                        ),
                        TextSpan(text: "."),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );


  }
}
