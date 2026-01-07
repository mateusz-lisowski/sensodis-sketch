part of '../app_database.dart';

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
