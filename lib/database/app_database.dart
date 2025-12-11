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
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MeasureEntity')
class Measures extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sensorId => text().references(Sensors, #id)();
  RealColumn get temperature => real()();
  RealColumn get humidity => real().nullable()();
  IntColumn get batteryLevel => integer()();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get rssi => integer()();
}

@DriftDatabase(tables: [Sensors, Measures])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(measures);
        }
        if (from < 3) {
          await m.addColumn(sensors, sensors.isFavorite);
        }
      },
    );
  }

  Future<int> insertSensor(SensorEntity sensor) {
    return into(sensors).insert(sensor, mode: InsertMode.insertOrReplace);
  }

  Future<List<SensorEntity>> getAllSensors() {
    return select(sensors).get();
  }

  Future<void> deleteSensor(String id) {
    return transaction(() async {
      await (delete(measures)..where((t) => t.sensorId.equals(id))).go();
      await (delete(sensors)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<void> addMeasure(
      String sensorId,
      double temperature,
      double? humidity,
      int batteryLevel,
      DateTime timestamp,
      int rssi,
      ) {
    return transaction(() async {
      await into(measures).insert(MeasuresCompanion.insert(
        sensorId: sensorId,
        temperature: temperature,
        humidity: Value(humidity),
        batteryLevel: batteryLevel,
        timestamp: timestamp,
        rssi: rssi,
      ));

      // Check count and keep only last 100
      // We want to keep the newest 100 records.
      // DELETE FROM measures WHERE sensorId = ? AND id NOT IN (
      //   SELECT id FROM measures WHERE sensorId = ? ORDER BY timestamp DESC LIMIT 100
      // )

      final subquery = selectOnly(measures)
        ..addColumns([measures.id])
        ..where(measures.sensorId.equals(sensorId))
        ..orderBy([OrderingTerm(expression: measures.timestamp, mode: OrderingMode.desc)])
        ..limit(100);

      await (delete(measures)
        ..where((t) =>
        t.sensorId.equals(sensorId) & t.id.isNotInQuery(subquery)))
          .go();
    });
  }

  Future<List<MeasureEntity>> getSensorHistory(String sensorId) {
    return (select(measures)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy(
          [(t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)]))
        .get();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
