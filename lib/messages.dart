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
        'pl_PL': {
          'hello': 'Witaj Świecie',
          'title': 'Sensodis',
          'message': 'Nacisnąłeś przycisk tyle razy:',
          'increment': 'Zwiększ',
          'change_lang': 'Zmień język',
          'username': 'Nazwa użytkownika',
          'password': 'Hasło',
          'login': 'Zaloguj się',
          'welcome': 'Witamy w Sensodis',
          'dashboard': 'Panel główny',
          'temperature': 'Temperatura',
          'humidity': 'Wilgotność',
          'battery': 'Bateria',
          'scan_devices': 'Skanuj urządzenia',
          'no_devices': 'Nie znaleziono urządzeń',
          'add': 'Dodaj',
          'device_added': 'Urządzenie dodane do panelu',
          'scanning': 'Skanowanie...',
          'unknown_device': 'Nieznane urządzenie',
        }
      };
}
