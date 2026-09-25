class SupabaseConfig {
  /// Supabase Project URL
  static const String url = 'https://aynalwnbwjgpvsvcqxzi.supabase.co';

  /// Supabase anon/public key
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5bmFsd25id2pncHZzdmNxeHppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwNTc0MzQsImV4cCI6MjEwNTYzMzQzNH0.JeoPRli6YVB8ymGwdfFPzPHcFtNvftsdt6xeQMvQKTI';

  /// Helper to check if credentials have been provided
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('https://');
}
