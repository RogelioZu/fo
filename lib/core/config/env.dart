import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Variables de entorno de Finding Out.
/// Lee las credenciales desde el archivo .env (no hardcodeadas).
class Env {
  Env._();

  static String get supabaseUrl => dotenv.env['SUPABASE_URL']!;
  static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY']!;
  static String get googleMapsApiKey => dotenv.env['GOOGLE_MAPS_API_KEY']!;
}
