import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../main.dart';
import 'connectivity_provider.dart';
import 'homeScreen.dart';

class SubscriptionPage extends StatefulWidget {
  const SubscriptionPage({super.key});

  @override
  _SubscriptionPageState createState() => _SubscriptionPageState();
}

class _SubscriptionPageState extends State<SubscriptionPage> {
  late PageController _pageController;
  double currentPage = 0;
  late Razorpay _razorpay;
  String? razorpayKey;
  int? perMonth;
  int? perYear = 0;
  int? mobilenumber = 0;
  bool isLoading = true;

  Future<void> fetchSubscriptionData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('subscriptions')
              .doc('pricing')
              .get();

      if (doc.exists) {
        setState(() {
          razorpayKey = doc['key'];
          perMonth = doc['per_month'];
          perYear = doc['per_year'];
        });
      } else {
        debugPrint("Document does not exist");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(FirebaseAuth.instance.currentUser!.email.toString())
              .get();

      if (doc.exists) {
        setState(() {
          mobilenumber = doc['mobile_number'];
        });
      } else {
        debugPrint("Document does not exist");
      }
    } catch (e) {
      debugPrint("Error fetching data: $e");
    }
  }

  Future<void> fetchData() async {
    try {
      await Future.wait([fetchUserData(), fetchSubscriptionData()]);
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching all data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  void initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint("✅ Payment Successful: ${response.paymentId}");
    String userEmail = FirebaseAuth.instance.currentUser!.email.toString();
    var startDate = FieldValue.serverTimestamp();

    FirebaseFirestore.instance
        .collection('users')
        .doc(userEmail)
        .update({
      'subscription_start_date': startDate,
      'subscription_type': currentPage.round() == 0 ? 'monthly' : 'yearly',
      'payment_id': response.paymentId,
    })
        .then((value) async {
      debugPrint("Initial subscription update successful");
      DocumentSnapshot doc =
      await FirebaseFirestore.instance.collection('users').doc(userEmail).get();

      if (doc.exists) {
        Timestamp startTimestamp = doc['subscription_start_date'] as Timestamp;
        DateTime startDateTime = startTimestamp.toDate();
        DateTime endDateTime;
        bool isMonthly = currentPage.round() == 0;

        if (isMonthly) {
          endDateTime = DateTime(
            startDateTime.year,
            startDateTime.month + 1,
            startDateTime.day,
            startDateTime.hour,
            startDateTime.minute,
            startDateTime.second,
          );
        } else {
          endDateTime = DateTime(
            startDateTime.year + 1,
            startDateTime.month,
            startDateTime.day,
            startDateTime.hour,
            startDateTime.minute,
            startDateTime.second,
          );
        }

        await FirebaseFirestore.instance.collection('users').doc(userEmail).update({
          'subscription_end_date': Timestamp.fromDate(endDateTime),
        });

        debugPrint("Subscription dates fully updated");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Payment successful! Subscription activated.'),
              backgroundColor: Colors.green,
            ),
          );

          // **🔄 Refreshing the Screen**
          Future.delayed(Duration(seconds: 1), () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => SubscriptionPage()), // Replace with your screen
            );
          });
        }
      }
    })
        .catchError((error) {
      debugPrint("Failed to update subscription dates: $error");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Payment successful but failed to update subscription: $error',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint("❌ Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("⚡ External Wallet Selected: ${response.walletName}");
  }

  void makePayment(int price) {
    var options = {
      'key': razorpayKey,
      'amount': price * 100,
      'name': 'Thera AI',
      'description':
          'Get full access to our premium AI therapist anytime, anywhere.',
      'prefill': {
        'contact': mobilenumber,
        'email': FirebaseAuth.instance.currentUser!.email.toString(),
      },
      'theme': {'color': '#070a12'},
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error is generated: $e");
    }
  }

  bool hasAccess = false; // Initialize hasAccess as false
  String subscriptionType = "";
  String subscriptionStartDate = "";
  String subscriptionEndDate = "";

  Future<void> _checkUserAccess() async {
    try {
      final userDocRef = FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.email);
      final userDoc = await userDocRef.get();

      if (userDoc.exists) {
        final data = userDoc.data()!;

        // Fetch subscription dates from Firestore
        final subscriptionStartDate =
            data['subscription_start_date'] as Timestamp?;
        final subscriptionEndDate = data['subscription_end_date'] as Timestamp?;
        final subscriptionType =
            data['subscription_type'] ??
            "Unknown"; // Default value if not found

        // Get current timestamp
        final currentTimestamp = Timestamp.now();

        // Check if the subscription is active
        if (subscriptionStartDate != null &&
            subscriptionEndDate != null &&
            currentTimestamp.toDate().isAfter(subscriptionStartDate.toDate()) &&
            currentTimestamp.toDate().isBefore(subscriptionEndDate.toDate())) {
          // Format dates
          String formattedStartDate = DateFormat(
            'MMMM d, yyyy',
          ).format(subscriptionStartDate.toDate());
          String formattedEndDate = DateFormat(
            'MMMM d, yyyy',
          ).format(subscriptionEndDate.toDate());

          setState(() {
            hasAccess = true;
            this.subscriptionType = subscriptionType;
            this.subscriptionStartDate = formattedStartDate;
            this.subscriptionEndDate = formattedEndDate;
          });
        } else {
          setState(() {
            hasAccess = false;
          });
        }
      } else {
        setState(() {
          hasAccess = false;
        });
      }
    } catch (e) {
      print('Error checking access: $e');
      setState(() {
        hasAccess = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUserAccess();
    _pageController = PageController(viewportFraction: 0.85);
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page!;
      });
    });
    initializeRazorpay();
    fetchData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double deviceHeight = MediaQuery.of(context).size.height;

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
          body:
          isLoading
              ? Center(
            child: CircularProgressIndicator(color: Color(0xffe8fd52)),
          )
              : hasAccess == true
              ? Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.grey.withAlpha(40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "Congratulations! You have already subscribed",
                      style: TextStyle(
                        color: Color(0xffffffff),
                        fontSize: deviceHeight * 0.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: deviceHeight * 0.035),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Subscription Plan",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2
                              ),
                            ),
                            SizedBox(height: deviceHeight*0.015,),
                            Text(
                              "Start Date",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2
                              ),
                            ),
                            SizedBox(height: deviceHeight*0.015,),
                            Text(
                              "End Date",
                              style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w600,
                                  height: 1.2
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              subscriptionType,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2
                              ),
                            ),
                            SizedBox(height: deviceHeight*0.015,),
                            Text(
                              subscriptionStartDate,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2
                              ),
                            ),
                            SizedBox(height: deviceHeight*0.015,),
                            Text(
                              subscriptionEndDate,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: deviceHeight * 0.02,
                                  fontWeight: FontWeight.w500,
                                  height: 1.2
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: deviceHeight*0.03,),
                    Image.asset("assets/images/boy.png", height: deviceHeight*0.2,),
                    GestureDetector(
                      onTap: (){
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => HomeScreen()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      child: Container(
                        width: double.maxFinite,
                        decoration: BoxDecoration(
                            color: Color(0xffe8fd52),
                            borderRadius: BorderRadius.circular(10)
                        ),
                        child: Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: deviceHeight*0.02),
                          child: Text("Go to Home Page", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: deviceHeight*0.02),),
                        )),
                      ),
                    )
                  ],
                ),
              ),
            ),
          )
              : Column(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: deviceHeight * 0.02,
                  right: deviceHeight * 0.02,
                  top: deviceHeight * 0.04,
                ),
                child: Text(
                  "Choose Your Subscription Plan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: deviceHeight * 0.02,
                  right: deviceHeight * 0.02,
                ),
                child: Text(
                  "Select the plan that best suits your needs.",
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: deviceHeight * 0.03),
              SizedBox(
                height: deviceHeight * 0.5,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: 2,
                  itemBuilder: (context, index) {
                    double scale =
                    currentPage.round() == index ? 1.05 : 0.95;

                    return Transform.scale(
                      scale: scale,
                      child: SubscriptionCard(
                        onTap: () {
                          makePayment(index == 0 ? perMonth! : perYear!);
                        },
                        title: index == 0 ? "Monthly Plan" : "Yearly Plan",
                        price:
                        index == 0
                            ? perMonth.toString()
                            : perYear.toString(),
                        duration: index == 0 ? "month" : "year",
                        features: [
                          {
                            "text": "AI Therapy Sessions",
                            "isAvailable": true,
                          },
                          {"text": "24/7 Access", "isAvailable": true},
                          {"text": "Premium Support", "isAvailable": true},
                          {
                            "text":
                            index == 0
                                ? "0 Months Free"
                                : "2 Months Free",
                            "isAvailable": index == 1,
                          },
                        ],
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: deviceHeight * 0.03),
              Container(
                height: deviceHeight * 0.005,
                width: deviceHeight * 0.1,
                decoration: BoxDecoration(
                  color: Colors.white60,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        );
      },
    );

  }
}

class SubscriptionCard extends StatelessWidget {
  final String title;
  final String price;
  final List<Map<String, dynamic>> features;
  final String duration;
  final VoidCallback onTap;

  const SubscriptionCard({
    super.key,
    required this.title,
    required this.price,
    required this.features,
    required this.duration,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    double deviceWidth = MediaQuery.of(context).size.width;
    double deviceHeight = MediaQuery.of(context).size.height;

    return Container(
      width: deviceWidth * 0.9,
      margin: EdgeInsets.symmetric(
        horizontal: deviceWidth * 0.025,
        vertical: 10,
      ),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withAlpha(35),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: deviceHeight * 0.3,
          maxHeight: deviceHeight * 0.8,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: deviceHeight * 0.02),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: deviceHeight * 0.025,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: deviceHeight * 0.008),
              Text(
                "Get full access to our premium AI therapist anytime, anywhere.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: deviceHeight * 0.018,
                ),
              ),
              SizedBox(height: deviceHeight * 0.012),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "\$",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: price,
                      style: TextStyle(
                        color: const Color(0xffe8fd52),
                        fontSize: deviceHeight * 0.030,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextSpan(
                      text: " / $duration",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: deviceHeight * 0.010),
              GestureDetector(
                onTap: onTap,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: deviceHeight * 0.012),
                  decoration: BoxDecoration(
                    color: const Color(0xffe8fd52),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Shimmer.fromColors(
                      baseColor: Colors.black,
                      highlightColor: Colors.white60,
                      period: const Duration(milliseconds: 1200),
                      child: Text(
                        "Subscribe Now",
                        style: TextStyle(
                          fontSize: deviceHeight * 0.020,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: deviceHeight * 0.015),
              const Divider(color: Colors.white30),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children:
                    features.map((feature) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            Icon(
                              feature['isAvailable']
                                  ? Icons.check
                                  : Icons.close,
                              color:
                                  feature['isAvailable']
                                      ? const Color(0xffe8fd52)
                                      : Colors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                feature['text'],
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 16,
                                  fontWeight:
                                      feature['isAvailable']
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
