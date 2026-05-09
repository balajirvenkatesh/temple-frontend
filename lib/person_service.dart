import 'dart:convert';
import 'package:http/http.dart' as http;

/// Model class to handle the Person response
class Person {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String createdAt;

  Person({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.createdAt,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'],
      firstName: json['firstName'],
      lastName: json['lastName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      createdAt: json['createdAt'],
    );
  }
}

class PersonService {
  // Use 10.0.2.2 instead of localhost if you are testing on an Android Emulator
  static const String _baseUrl = 'https://temple-t3w3.onrender.com/person';

  Future<Person?> createPerson({
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String dob,
    required int gender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "firstName": firstName,
          "lastName": lastName,
          "email": email,
          "phoneNumber": phoneNumber,
          "dateOfBirth": dob,
          "gender": gender,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Person.fromJson(jsonDecode(response.body));
      } else {
        print('Server Error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Network Error: $e');
      return null;
    }
  }
}