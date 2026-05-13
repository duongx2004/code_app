const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const MYSQL_HOST = process.env.MYSQL_HOST || '127.0.0.1';
const MYSQL_PORT = Number(process.env.MYSQL_PORT || 3306);
const MYSQL_USER = process.env.MYSQL_USER || 'root';
const MYSQL_PASSWORD = process.env.MYSQL_PASSWORD || '';
const MYSQL_DATABASE = process.env.MYSQL_DATABASE || 'code_app';

async function createSampleFillBlankExercises() {
  let connection;

  try {
    connection = await mysql.createConnection({
      host: MYSQL_HOST,
      port: MYSQL_PORT,
      user: MYSQL_USER,
      password: MYSQL_PASSWORD,
      database: MYSQL_DATABASE,
    });

    console.log('Connected to database');

    // Insert sample exercise
    await connection.execute(
      'INSERT INTO fill_blank_exercises (id, title, content, difficulty, hint) VALUES (?, ?, ?, ?, ?)',
      [
        'sample_1',
        'Giới thiệu về biến trong Dart',
        'Trong Dart, để khai báo một biến, chúng ta sử dụng từ khóa _____ hoặc _____. Ví dụ: _____ myVariable = "Hello";',
        'cơ bản',
        'Biến dùng để lưu trữ dữ liệu'
      ]
    );

    // Insert answers
    await connection.execute(
      'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
      ['sample_1', 0, JSON.stringify(['var']), 'Từ khóa khai báo biến']
    );

    await connection.execute(
      'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
      ['sample_1', 1, JSON.stringify(['String']), 'Kiểu dữ liệu chuỗi']
    );

    await connection.execute(
      'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
      ['sample_1', 2, JSON.stringify(['String']), 'Kiểu dữ liệu của biến']
    );

    console.log('Sample fill blank exercise created successfully');

  } catch (error) {
    console.error('Error:', error);
  } finally {
    if (connection) {
      await connection.end();
    }
  }
}

createSampleFillBlankExercises();