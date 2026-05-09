import 'package:flutter/material.dart';
import 'person_service.dart'; // Import the service we created earlier
import 'home_page.dart';

class PersonFormScreen extends StatefulWidget {
  const PersonFormScreen({super.key});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _service = PersonService();
  
  // Controllers to retrieve text values
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController(text: '1991-10-01');
  
  int _selectedGender = 1; // 1 for Female (based on your API example)
  bool _isLoading = false;
// Inside person_form_screen.dart -> _submitData method

void _submitData() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  // We call the service
  final person = await _service.createPerson(
    firstName: _firstNameController.text,
    lastName: _lastNameController.text,
    email: _emailController.text,
    phoneNumber: _phoneController.text,
    dob: _dobController.text,
    gender: _selectedGender,
  );

  setState(() => _isLoading = false);

  if (person != null) {
    // SUCCESS: Navigate to Home Page and remove the login/form from the stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
      (route) => false, // This clears the navigation history
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to create person. Please try again.')),
    );
  }
}
  // void _submitData() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   setState(() => _isLoading = true);

  //   final person = await _service.createPerson(
  //     firstName: _firstNameController.text,
  //     lastName: _lastNameController.text,
  //     email: _emailController.text,
  //     phoneNumber: _phoneController.text,
  //     dob: _dobController.text,
  //     gender: _selectedGender,
  //   );

  //   setState(() => _isLoading = false);

  //   if (person != null) {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(content: Text('Success! Created Person ID: ${person.id}')),
  //     );
  //   } else {
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       const SnackBar(content: Text('Failed to create person. Check logs.')),
  //     );
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register Person')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Phone'),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<int>(
                    value: _selectedGender,
                    decoration: const InputDecoration(labelText: 'Gender'),
                    items: const [
                      DropdownMenuItem(value: 1, child: Text('Female')),
                      DropdownMenuItem(value: 0, child: Text('Male')),
                    ],
                    onChanged: (val) => setState(() => _selectedGender = val!),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('Submit'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}