class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );
  static const String logoBucket = 'restaurant-logos';
  static const bool publicBucket = true;

  static bool get isConfigured {
    return url.isNotEmpty && anonKey.isNotEmpty;
  }
}
