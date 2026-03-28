import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:code_app/models/models.dart';

class DataService {
  static Future<List<Lesson>> loadLessons() async {
    final String response = await rootBundle.loadString('assets/data/lessons.json');
    final List<dynamic> data = json.decode(response);
    return data.map((json) => Lesson.fromJson(json)).toList();
  }
}