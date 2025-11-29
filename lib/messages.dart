import 'package:get/get.dart';

class Messages extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          'hello': 'Hello World',
          'title': 'Flutter Demo Home Page',
          'message': 'You have pushed the button this many times:',
          'increment': 'Increment',
          'change_lang': 'Change Language'
        },
        'de_DE': {
          'hello': 'Hallo Welt',
          'title': 'Flutter Demo Startseite',
          'message': 'Du hast den Knopf so oft gedrückt:',
          'increment': 'Erhöhen',
          'change_lang': 'Sprache ändern'
        }
      };
}
