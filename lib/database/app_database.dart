import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';
part 'tables/sensors.dart';
part 'tables/measures.dart';
part 'tables/backup_logs.dart';

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

  /// Paginated history fetch for lazy loading
  Future<List<MeasureEntity>> getSensorHistoryPage(String sensorId, {int limit = 50, int offset = 0}) {
    return (select(measures)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(limit, offset: offset))
        .get();
  }

  /// Stream of the latest measure (limit 1) so UI can prepend newly inserted measures
  Stream<MeasureEntity?> watchLatestMeasureForSensor(String sensorId) {
    return (select(measures)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(1))
        .watchSingleOrNull();
  }

  /// Watch a page/window of measures so UI can reflect updates to existing measures
  Stream<List<MeasureEntity>> watchSensorHistoryPage(String sensorId, {int limit = 50, int offset = 0}) {
    return (select(measures)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(limit, offset: offset))
        .watch();
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

  /// Paginated backup logs fetch for lazy loading
  Future<List<BackupLogEntity>> getBackupLogsPage(String sensorId, {int limit = 50, int offset = 0}) {
    return (select(backupLogs)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(limit, offset: offset))
        .get();
  }

  /// Stream of the latest backup log (limit 1) so UI can prepend newly inserted logs
  Stream<BackupLogEntity?> watchLatestBackupLogForSensor(String sensorId) {
    return (select(backupLogs)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(1))
        .watchSingleOrNull();
  }

  /// Watch a page/window of backup logs so UI can reflect updates to existing logs
  Stream<List<BackupLogEntity>> watchBackupLogsPage(String sensorId, {int limit = 50, int offset = 0}) {
    return (select(backupLogs)
      ..where((t) => t.sensorId.equals(sensorId))
      ..orderBy([
        (t) => OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc)
      ])
      ..limit(limit, offset: offset))
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
