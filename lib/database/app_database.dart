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
  TextColumn get rawData => text()();
  BoolColumn get backedUp => boolean().withDefault(const Constant(false))();
}

@DataClassName('BackupLogEntity')
class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sensorId => text().references(Sensors, #id)();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get statusCode => integer()();
  TextColumn get response => text()();
}

@DriftDatabase(tables: [Sensors, Measures, BackupLogs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 6;

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
        if (from < 4) {
          await m.addColumn(measures, measures.backedUp);
        }
        if (from < 5) {
          await m.addColumn(measures, measures.rawData);
        }
        if (from < 6) {
          await m.createTable(backupLogs);
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

  Future<List<SensorEntity>> getFavoriteSensors() {
    return (select(sensors)..where((t) => t.isFavorite.equals(true))).get();
  }

  Future<void> deleteSensor(String id) {
    return transaction(() async {
      await (delete(backupLogs)..where((t) => t.sensorId.equals(id))).go();
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
      String rawData,
      ) {
    return transaction(() async {
      await into(measures).insert(MeasuresCompanion.insert(
        sensorId: sensorId,
        temperature: temperature,
        humidity: Value(humidity),
        batteryLevel: batteryLevel,
        timestamp: timestamp,
        rssi: rssi,
        rawData: rawData,
      ));

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

  Stream<List<MeasureEntity>> getSensorHistory(String sensorId) {
    return (select(measures)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  Future<MeasureEntity?> getLastMeasureForSensor(String sensorId) {
    return (select(measures)
          ..where((t) => t.sensorId.equals(sensorId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<void> updateMeasureBackedUp(int measureId, bool backedUp) {
    return (update(measures)..where((t) => t.id.equals(measureId)))
        .write(MeasuresCompanion(backedUp: Value(backedUp)));
  }

  Future<int> addBackupLog(
      {required String sensorId,
      required DateTime timestamp,
      required int statusCode,
      required String response}) {
    return into(backupLogs).insert(BackupLogsCompanion.insert(
      sensorId: sensorId,
      timestamp: timestamp,
      statusCode: statusCode,
      response: response,
    ));
  }

  Future<List<BackupLogEntity>> getBackupLogs(String sensorId) {
    return (select(backupLogs)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ]))
        .get();
  }

  Stream<List<BackupLogEntity>> watchBackupLogs(String sensorId) {
    return (select(backupLogs)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ]))
        .watch();
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'db.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
