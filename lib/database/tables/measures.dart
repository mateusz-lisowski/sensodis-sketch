part of '../app_database.dart';

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
