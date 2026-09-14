import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check employees table in Supabase', () async {
    HttpOverrides.global = null;
    SharedPreferences.setMockInitialValues({});
    print('Initializing Supabase client...');
    await Supabase.initialize(
      url: 'https://efmzdclqgqtkjdireicw.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVmbXpkY2xxZ3F0a2pkaXJlaWN3Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1NTg1MTUsImV4cCI6MjA5NjEzNDUxNX0.oZzw5ebR0HEIFWfCrgCPIwOWcFFvPVrISW38RoD9M9c',
    );

    final client = Supabase.instance.client;
    
    // Log in as admin
    await client.auth.signInWithPassword(
      email: 'admin@gmail.com',
      password: '123456',
    );
    print('Logged in successfully!');

    try {
      print('Fetching employees...');
      final response = await client.from('employees').select();
      print('Fetch successful! Record count: ${response.length}');
      for (var row in response) {
        print('Employee: ${row['name']}, Designation: ${row['designation']}, Department: ${row['department']}');
      }
    } catch (e) {
      print('Error fetching employees: $e');
    }
  });
}
