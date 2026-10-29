class SupabaseConfig {
  /// Supabase Project URL (configured via --dart-define=SUPABASE_URL=... or fallback)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://aynalwnbwjgpvsvcqxzi.supabase.co',
  );

  /// Supabase anon/publishable key (configured via --dart-define=SUPABASE_ANON_KEY=... or fallback)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF5bmFsd25id2pncHZzdmNxeHppIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAwNTc0MzQsImV4cCI6MjEwNTYzMzQzNH0.JeoPRli6YVB8ymGwdfFPzPHcFtNvftsdt6xeQMvQKTI',
  );

  /// Alias for Supabase 2.x publishableKey standard
  static String get publishableKey => anonKey;

  /// Helper to check if credentials have been provided
  static bool get isConfigured =>
      url.isNotEmpty &&
      anonKey.isNotEmpty &&
      url.startsWith('https://');
}

