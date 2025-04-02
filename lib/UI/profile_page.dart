import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import 'connectivity_provider.dart';
import 'homeScreen.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override

  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
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
    _fetchUserData();
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


  Future<void> updateUserDetails(BuildContext context, TextEditingController nameController, TextEditingController mobileController, TextEditingController ageController) async {
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


      // Create a user data map
      Map<String, dynamic> userData = {
        'name': name,
        'mobile_number': int.parse(mobileNumber),
        'age': age,
      };

      // Store user details in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.email).update(userData);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
            (Route<dynamic> route) => false,
      );

    } catch (e) {
      print("Error storing user details: $e");
    }
  }

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();


  void _fetchUserData() async {
    try {
      // Get the current user's email as the document ID
      String userEmail = FirebaseAuth.instance.currentUser!.email.toString();

      // Fetch the user document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userEmail)
          .get();

      // Check if the document exists and has data
      if (userDoc.exists && userDoc.data() != null) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        // Set the controller values from Firestore data
        setState(() {
          _nameController.text = data['name']?.toString() ?? '';
          _mobileNumberController.text = data['mobile_number']?.toString() ?? '';
          _ageController.text = data['age']?.toString() ?? '';
          _emailController.text = data['email']?.toString() ?? '';
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
      // Optionally set default values or show an error
      setState(() {
        _nameController.text = '';
        _mobileNumberController.text = '';
        _ageController.text = '';
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers to prevent memory leaks
    _nameController.dispose();
    _mobileNumberController.dispose();
    _ageController.dispose();
    super.dispose();
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

          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: deviceWidth * 0.05),
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: deviceHeight*0.04,),
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
                      "Edit your information below and continue your therapy",
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

                  SizedBox(height: deviceHeight*0.03,),
                  Align(
                    child: Text(
                      "Email",
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
                    readOnly: true,
                    controller: _emailController,
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
                      updateUserDetails(context, _nameController, _mobileNumberController, _ageController);
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
                          "Update",
                          style: TextStyle(
                            color: Color(0xff000000), // Changed text color to black for visibility
                            fontWeight: FontWeight.w900,
                            fontSize: deviceHeight * 0.020,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

  }
}
