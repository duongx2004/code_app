import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Test để kiểm tra logic _getDifficultyColor và _getDifficultyIcon
void main() {
  group('Difficulty Display Tests', () {
    test('getDifficultyColor returns correct color for "dễ"', () {
      final color = _getDifficultyColor('dễ');
      expect(color, equals(Colors.green));
    });

    test('getDifficultyColor returns correct color for "trung bình"', () {
      final color = _getDifficultyColor('trung bình');
      expect(color, equals(Colors.orange));
    });

    test('getDifficultyColor returns correct color for "khó"', () {
      final color = _getDifficultyColor('khó');
      expect(color, equals(Colors.red));
    });

    test('getDifficultyColor returns grey for unknown difficulty', () {
      final color = _getDifficultyColor('unknown');
      expect(color, equals(Colors.grey));
    });

    test('getDifficultyIcon returns correct icon for "dễ"', () {
      final icon = _getDifficultyIcon('dễ');
      expect(icon, equals(Icons.sentiment_satisfied));
    });

    test('getDifficultyIcon returns correct icon for "trung bình"', () {
      final icon = _getDifficultyIcon('trung bình');
      expect(icon, equals(Icons.sentiment_neutral));
    });

    test('getDifficultyIcon returns correct icon for "khó"', () {
      final icon = _getDifficultyIcon('khó');
      expect(icon, equals(Icons.sentiment_dissatisfied));
    });

    test('getDifficultyIcon returns help icon for unknown difficulty', () {
      final icon = _getDifficultyIcon('unknown');
      expect(icon, equals(Icons.help_outline));
    });

    test('getDifficultyColor handles case insensitive input', () {
      expect(_getDifficultyColor('DỄ'), equals(Colors.green));
      expect(_getDifficultyColor('TRUNG BÌNH'), equals(Colors.orange));
      expect(_getDifficultyColor('KHÓ'), equals(Colors.red));
    });
  });
}

// Sao chép các hàm helper từ FillBlankExerciseScreen
Color _getDifficultyColor(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'dễ':
      return Colors.green;
    case 'trung bình':
      return Colors.orange;
    case 'khó':
      return Colors.red;
    default:
      return Colors.grey;
  }
}

IconData _getDifficultyIcon(String difficulty) {
  switch (difficulty.toLowerCase()) {
    case 'dễ':
      return Icons.sentiment_satisfied;
    case 'trung bình':
      return Icons.sentiment_neutral;
    case 'khó':
      return Icons.sentiment_dissatisfied;
    default:
      return Icons.help_outline;
  }
}
