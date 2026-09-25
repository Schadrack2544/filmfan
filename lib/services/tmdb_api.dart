import 'package:flutter_dotenv/flutter_dotenv.dart';

String requireTmdbApiKey() {
  final fromDefine = const String.fromEnvironment('TMDB_API_KEY');
  if (fromDefine.isNotEmpty) {
    return fromDefine;
  }

  final fromDotEnv = dotenv.env['TMDB_API_KEY'] ?? '';
  if (fromDotEnv.isNotEmpty) {
    return fromDotEnv;
  }

  throw StateError(
    'TMDB_API_KEY is not configured. Add it to .env or build with '
    '--dart-define=TMDB_API_KEY=your_key.',
  );
}
