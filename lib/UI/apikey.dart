import 'package:cloud_firestore/cloud_firestore.dart';

class ApiService {
  static Future<String?> fetchApiKey() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('ai api') // Make sure the collection name is correct
          .limit(1) // Get only the first document
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        print("Api key is ${doc['apikey']}");
        return doc['apikey']; // Ensure the document has the 'apikey' field
      }

      return null;
    } catch (e) {
      print("Error fetching API key: $e");
      return null;
    }
  }
}

