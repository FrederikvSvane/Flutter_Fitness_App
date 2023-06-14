import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

import '../classes/FoodApi.dart';

class DBHelper {
  static Future<Database> getDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'meal_database.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE meals(id INTEGER PRIMARY KEY, barcode INTEGER, nameComponent TEXT, calories REAL, proteins REAL, mealType TEXT, date TEXT)',
        );
        await db.execute(
            'CREATE TABLE exercises(id INTEGER PRIMARY KEY, name TEXT, sets INTEGER, reps INTEGER, weight REAL, date TEXT)',
        );
        await db.execute(
          'CREATE TABLE workouts(id INTEGER PRIMARY KEY, name TEXT, date TEXT)',
        );
      },
    );
  }

  static Future<void> insertMeal(Map<String, dynamic> mealData) async {
    final db = await getDatabase();
    await db.insert(
      'meals',
      mealData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<void> insertMockData() async {
    if (kDebugMode) {
      final db = await getDatabase();

      // Clear existing data from the 'meals' table
      await db.delete('meals');

      // Insert some mock data for testing.
      for (var i = 0; i < 30; i++) {
        for (var j = 0; j < 4; j++) {
          final mealData = {
            'barcode': 1234567890 + i * 10 + j,
            'nameComponent': 'Mock Meal ${i * 4 + j}',
            'calories': 500.0 + (i * 10 + j) + Random().nextInt(100),
            'proteins': 20.0 + (i + j) + Random().nextInt(10),
            'mealType': j == 0
                ? 'Breakfast'
                : j == 1
                    ? 'Lunch'
                    : j == 2
                        ? 'Dinner'
                        : 'Snacks',
            'date': DateTime.now().subtract(Duration(days: i)).toString(),
          };
          await insertMeal(mealData);
        }
      }
    }
  }
  static Future<void> insertExercise(Map<String, dynamic> exerciseData) async {
    final db = await getDatabase();
    await db.insert(
      'exercises',
      exerciseData,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<List<Map<String, dynamic>>> getAllMeals() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query('meals');
    return maps;
  }

  //Remove meal from database
  static Future<void> removeMeal(int id) async {
    final db = await getDatabase();
    await db.delete(
      'meals',
      where: "id = ?",
      whereArgs: [id],
    );
  }

  //Get meal by id
  static Future<List<Map<String, dynamic>>> getMealById(int id) async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      where: "id = ?",
      whereArgs: [id],
    );
    return maps;
  }

  static Future<FoodApi?> getLatestMeal() async {
    final db = await getDatabase();
    final List<Map<String, dynamic>> maps = await db.query(
      'meals',
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return FoodApi(
        id: maps[0]['id'],
        barcode: maps[0]['barcode'],
        nameComponent: maps[0]['nameComponent'],
        calories: maps[0]['calories'],
        proteins: maps[0]['proteins'],
        mealType: maps[0]['mealType'],
        date: maps[0]['date'],
      );
    }
    return null; // Returns null if there are no entries in the database.
  }

  getDB() {
    return getDatabase();
  }

  static Future<List<Map<String, dynamic>>> getCaloriesForDateRange(
      DateTime before, DateTime after) async {
    final db = await getDatabase();

    List<Map<String, dynamic>> meals = await db.rawQuery('''
      SELECT date(date) as date, SUM(calories) as totalCalories 
      FROM meals 
      WHERE date(date) BETWEEN date(?) AND date(?)
      GROUP BY date(date)
    ''', [
      before.toIso8601String(),
      after.toIso8601String(),
    ]);

    return meals;
  }

  static Future<List<Map<String, dynamic>>> getProteinsForDateRange(
      DateTime before, DateTime after) async {
    final db = await getDatabase();

    List<Map<String, dynamic>> meals = await db.rawQuery('''
    SELECT date(date) as date, SUM(proteins) as totalProteins
    FROM meals 
    WHERE date(date) BETWEEN date(?) AND date(?)
    GROUP BY date(date)

  ''', [
      before.toIso8601String(),
      after.toIso8601String(),
    ]);

    return meals;
  }

  static Future<List<Map<String, dynamic>>> getExercises() async {
    final db = await getDatabase();

    // Execute the query
    final List<Map<String, dynamic>> maps = await db.query('exercises');
    await db.delete('exercises');
    return maps;
  }
}
