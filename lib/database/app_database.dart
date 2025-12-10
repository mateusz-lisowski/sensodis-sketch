import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

@DataClassName('SensorEntity')
class Sensors extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get temperature => real()();
  RealColumn get humidity => real().nullable()();
  IntColumn get batteryLevel => integer()();
  DateTimeColumn get lastUpdated => dateTime()();
  IntColumn get rssi => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Sensors])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  Future<int> insertSensor(SensorEntity sensor) {
    return into(sensors).insert(sensor, mode: InsertMode.insertOrReplace);
  }

  Future<List<SensorEntity>> getAllSensors() {
    return select(sensors).get();
  }

  Future<int> deleteSensor(String id) {
    return (delete(sensors)..where((t) => t.id.equals(id))).go();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
