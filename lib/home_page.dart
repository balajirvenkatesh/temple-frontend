import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Need to add this
import 'dart:convert'; // Need to add this for json.decode
import 'person_form_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic>? _people;
  bool _isLoading = false;

  // Function to fetch data from your backend
  Future<void> _fetchPersonDetails() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Note: 'localhost' often fails on Android Emulators.
      // Use '10.0.2.2' for Android or your machine's local IP.
      final response = await http.get(
        Uri.parse('https://temple-t3w3.onrender.com/person'),
      );

      if (response.statusCode == 200) {
        setState(() {
          _people = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      // Ensure the widget is still mounted before showing SnackBar
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error fetching data: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                // Navigate to Home Page and clear the stack
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false, // This clears the navigation history
                );
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Icon(Icons.home),
              ),
            ),
            const SizedBox(width: 20),
            const Text('Home'),
          ],
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepPurple),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Person'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                _fetchPersonDetails();
              },
            ),
            ListTile(
              leading: const Icon(Icons.money_off),
              title: const Text('Expense'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Donations'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonFormScreen(),
                  ),
                );
              },
              child: const Text('Create Person'),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PersonFormScreen(),
                  ),
                );
              },
              child: const Text('Show Person List'),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _people == null
                ? const Center(
                    child: Text('Welcome! Select "Person" from the sidebar.'),
                  )
                : ListView.builder(
                    itemCount: _people!.length,
                    itemBuilder: (context, index) {
                      final person = _people![index];
                      return ListTile(
                        title: Text(
                          person['firstName'] + " " + person['lastName'] ??
                              'No Name',
                        ),
                        subtitle: Text(person['email'] ?? 'No Email'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
