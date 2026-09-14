import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:software_house_erp/features/projects/tasks/data/repositories/tasks_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Check project_tasks table in Supabase', () async {
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
      print('Fetching project_tasks using TasksRepositoryImpl...');
      // Pass null database since _useSupabase is true and db won't be accessed
      final repo = TasksRepositoryImpl(null as dynamic);
      final tasks = await repo.getTasks();
      print('Fetch successful! Record count: ${tasks.length}');
      for (var task in tasks) {
        print('Task: ${task.title}, Status: ${task.status}, Assignee: ${task.assigneeName}');
      }
    } catch (e) {
      print('Error fetching project_tasks: $e');
    }
  });
}
