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
          'dashboard': 'Dashboard',
          'temperature': 'Temperature',
          'humidity': 'Humidity',
          'battery': 'Battery',
          'scan_devices': 'Scan for Devices',
          'no_devices': 'No devices found',
          'add': 'Add',
          'device_added': 'Device added to dashboard',
          'scanning': 'Scanning...',
          'unknown_device': 'Unknown Device',
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
          'dashboard': 'Übersicht',
          'temperature': 'Temperatur',
          'humidity': 'Feuchtigkeit',
          'battery': 'Batterie',
          'scan_devices': 'Nach Geräten suchen',
          'no_devices': 'Keine Geräte gefunden',
          'add': 'Hinzufügen',
          'device_added': 'Gerät zur Übersicht hinzugefügt',
          'scanning': 'Suche...',
          'unknown_device': 'Unbekanntes Gerät',
        }
      };
}
