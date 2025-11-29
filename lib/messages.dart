import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'hello': 'Hello World',
          'title': 'Sensodis',
          'message': 'You have pushed the button this many times:',
          'increment': 'Increment',
          'change_lang': 'Change Language',
          'username': 'Username',
          'password': 'Password',
          'login': 'Login',
          'welcome': 'Welcome to Sensodis',
        },
        'de_DE': {
          'hello': 'Hallo Welt',
          'title': 'Sensodis',
          'message': 'Du hast den Knopf so oft gedrückt:',
          'increment': 'Erhöhen',
          'change_lang': 'Sprache ändern',
          'username': 'Benutzername',
          'password': 'Passwort',
          'login': 'Anmelden',
          'welcome': 'Willkommen bei Sensodis',
        }
      };
}
