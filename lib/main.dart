import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'messages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: Messages(), // Add your translation here
      locale: const Locale('en', 'US'), // Translations will be displayed in that locale
      fallbackLocale: const Locale('en', 'US'), // Specify the fallback locale in case an invalid locale is selected.
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}

class CounterController extends GetxController {
  var count = 0.obs;

  void increment() {
    count++;
  }

  void changeLanguage(String lang, String country) {
    var locale = Locale(lang, country);
    Get.updateLocale(locale);
  }
}

class MyHomePage extends StatelessWidget {
  final CounterController c = Get.put(CounterController());

  MyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text('title'.tr),
        actions: [
          IconButton(
            onPressed: () {
              if (Get.locale?.languageCode == 'en') {
                c.changeLanguage('de', 'DE');
              } else {
                c.changeLanguage('en', 'US');
              }
            },
            icon: const Icon(Icons.language),
            tooltip: 'change_lang'.tr,
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('message'.tr),
            Obx(() => Text(
                  '${c.count}',
                  style: Theme.of(context).textTheme.headlineMedium,
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: c.increment,
        tooltip: 'increment'.tr,
        child: const Icon(Icons.add),
      ),
    );
  }
}
