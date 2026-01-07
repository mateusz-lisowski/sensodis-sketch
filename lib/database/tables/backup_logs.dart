part of '../app_database.dart';

@DataClassName('BackupLogEntity')
class BackupLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get sensorId => text().references(Sensors, #id)();
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get statusCode => integer()();
  TextColumn get response => text()();
}
