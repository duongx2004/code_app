const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, execSync } = require('child_process');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const PORT = 8081;
const MAX_CODE_SIZE = Number(process.env.MAX_CODE_SIZE || 100_000);
const MAX_INPUT_SIZE = Number(process.env.MAX_INPUT_SIZE || 20_000);
const MAX_TIMEOUT_SECONDS = Number(process.env.MAX_TIMEOUT_SECONDS || 15);
const HOST = process.env.HOST || '0.0.0.0';
const MYSQL_HOST = process.env.MYSQL_HOST || '127.0.0.1';
const MYSQL_PORT = Number(process.env.MYSQL_PORT || 3306);
const MYSQL_USER = process.env.MYSQL_USER || 'root';
const MYSQL_PASSWORD = process.env.MYSQL_PASSWORD || '';
const MYSQL_DATABASE = process.env.MYSQL_DATABASE || 'code_app';
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'admin@admin.com';
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || 'admin123';
const ADMIN_DISPLAY_NAME = process.env.ADMIN_DISPLAY_NAME || 'Admin';

function sendJson(res, statusCode, payload) {
  const body = JSON.stringify(payload);
  res.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'Content-Type',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  });
  res.end(body);
}

function readRequestBody(req) {
  return new Promise((resolve, reject) => {
    let raw = '';

    req.on('data', (chunk) => {
      raw += chunk.toString('utf8');
      if (raw.length > 2 * MAX_CODE_SIZE) {
        reject(new Error('Request body too large'));
        req.destroy();
      }
    });

    req.on('end', () => resolve(raw));
    req.on('error', reject);
  });
}

function normalizeTimeout(value) {
  const parsed = Number(value);
  if (!Number.isFinite(parsed) || parsed <= 0) {
    return 5;
  }
  return Math.min(Math.max(Math.floor(parsed), 1), MAX_TIMEOUT_SECONDS);
}

function tryRemoveDir(dirPath) {
  try {
    fs.rmSync(dirPath, { recursive: true, force: true });
  } catch (_) {
    // best effort cleanup
  }
}

function findDartExecutable() {
  const explicitPath = process.env.DART_PATH || process.env.DART_CMD || process.env.DART;
  if (explicitPath && fs.existsSync(explicitPath)) {
    return explicitPath;
  }

  try {
    if (process.platform === 'win32') {
      const found = execSync('where dart', { encoding: 'utf8' })
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
      if (found.length > 0 && fs.existsSync(found[0])) {
        return found[0];
      }
    } else {
      const found = execSync('which dart', { encoding: 'utf8' })
        .split(/\r?\n/)
        .map((line) => line.trim())
        .filter(Boolean);
      if (found.length > 0 && fs.existsSync(found[0])) {
        return found[0];
      }
    }
  } catch (_) {
    // ignore, fallback to default
  }

  return 'dart';
}

const DART_EXECUTABLE = findDartExecutable();
console.log(`Using Dart executable: ${DART_EXECUTABLE}`);

async function createDatabaseIfMissing() {
  const connection = await mysql.createConnection({
    host: MYSQL_HOST,
    port: MYSQL_PORT,
    user: MYSQL_USER,
    password: MYSQL_PASSWORD,
  });
  await connection.query('CREATE DATABASE IF NOT EXISTS `' + MYSQL_DATABASE + '`');
  await connection.end();
}

let pool;

async function query(sql, params = []) {
  const [rows] = await pool.query(sql, params);
  return rows;
}

async function initDatabase() {
  await createDatabaseIfMissing();
  pool = mysql.createPool({
    host: MYSQL_HOST,
    port: MYSQL_PORT,
    user: MYSQL_USER,
    password: MYSQL_PASSWORD,
    database: MYSQL_DATABASE,
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
  });

  await query(`CREATE TABLE IF NOT EXISTS users (
    email VARCHAR(255) PRIMARY KEY,
    password VARCHAR(255) NOT NULL,
    display_name VARCHAR(255) NOT NULL,
    is_admin BOOLEAN NOT NULL DEFAULT FALSE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  try {
    await query('ALTER TABLE users ADD COLUMN is_admin BOOLEAN NOT NULL DEFAULT FALSE');
  } catch (error) {
    // ignore if the column already exists or migration is not needed
  }

  await query(`CREATE TABLE IF NOT EXISTS exercises (
    id VARCHAR(255) PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    input_format TEXT NOT NULL,
    output_format TEXT NOT NULL,
    difficulty VARCHAR(100) NOT NULL,
    hint TEXT,
    time_limit INT NOT NULL
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  await query(`CREATE TABLE IF NOT EXISTS test_cases (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exercise_id VARCHAR(255) NOT NULL,
    input TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  await query(`CREATE TABLE IF NOT EXISTS lessons (
    id VARCHAR(255) PRIMARY KEY,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    code_sample TEXT NOT NULL,
    expected_output TEXT NOT NULL,
    quiz TEXT NOT NULL,
    exercises TEXT NOT NULL DEFAULT '[]'
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  try {
    await query("ALTER TABLE lessons ADD COLUMN exercises TEXT NOT NULL DEFAULT '[]'");
  } catch (error) {
    // ignore if the column already exists or migration is not needed
  }

  // Thêm bảng cho tiến độ người dùng
  await query(`CREATE TABLE IF NOT EXISTS user_progress (
    user_email VARCHAR(255) NOT NULL,
    lesson_id VARCHAR(255),
    exercise_id VARCHAR(255),
    type ENUM('lesson', 'exercise') NOT NULL,
    completed BOOLEAN DEFAULT FALSE,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (user_email, lesson_id, exercise_id),
    FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE,
    FOREIGN KEY (lesson_id) REFERENCES lessons(id) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES exercises(id) ON DELETE CASCADE,
    CHECK ((lesson_id IS NOT NULL AND exercise_id IS NULL) OR (lesson_id IS NULL AND exercise_id IS NOT NULL))
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  // Thêm bảng cho bài tập điền vào chỗ trống
  await query(`CREATE TABLE IF NOT EXISTS fill_blank_exercises (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    content TEXT NOT NULL,
    difficulty ENUM('cơ bản', 'trung bình', 'nâng cao') DEFAULT 'cơ bản',
    hint TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  await query(`CREATE TABLE IF NOT EXISTS fill_blank_answers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    exercise_id VARCHAR(50) NOT NULL,
    blank_index INT NOT NULL,
    correct_answers JSON NOT NULL,
    hint TEXT,
    FOREIGN KEY (exercise_id) REFERENCES fill_blank_exercises(id) ON DELETE CASCADE,
    UNIQUE KEY unique_blank (exercise_id, blank_index)
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  await query(`CREATE TABLE IF NOT EXISTS user_fill_blank_progress (
    user_email VARCHAR(255) NOT NULL,
    exercise_id VARCHAR(50) NOT NULL,
    score INT DEFAULT 0,
    total_blanks INT DEFAULT 0,
    completed BOOLEAN DEFAULT FALSE,
    last_attempt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (user_email, exercise_id),
    FOREIGN KEY (user_email) REFERENCES users(email) ON DELETE CASCADE,
    FOREIGN KEY (exercise_id) REFERENCES fill_blank_exercises(id) ON DELETE CASCADE
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  await query(`CREATE TABLE IF NOT EXISTS quizzes (
    id VARCHAR(50) PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    questions JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
  ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4`);

  const adminExists = await query('SELECT 1 FROM users WHERE email = ? LIMIT 1', [ADMIN_EMAIL]);
  if (adminExists.length === 0) {
    await query(
      'INSERT INTO users (email, password, display_name, is_admin) VALUES (?, ?, ?, ?)',
      [ADMIN_EMAIL, ADMIN_PASSWORD, ADMIN_DISPLAY_NAME, true],
    );
    console.log(`Default admin created: ${ADMIN_EMAIL}`);
  }

  const existingCount = await query('SELECT COUNT(*) as count FROM exercises');
  const count = Array.isArray(existingCount) && existingCount.length > 0 ? existingCount[0].count : 0;
  if (count === 0) {
    const exercisesFile = path.join(__dirname, '..', 'assets', 'data', 'exercises.json');
    if (fs.existsSync(exercisesFile)) {
      const content = fs.readFileSync(exercisesFile, 'utf8');
      const exercises = JSON.parse(content);
      for (const exercise of exercises) {
        await query(
          'INSERT INTO exercises (id, title, description, input_format, output_format, difficulty, hint, time_limit) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
          [
            exercise.id,
            exercise.title,
            exercise.description,
            exercise.input,
            exercise.output,
            exercise.difficulty || 'cơ bản',
            exercise.hint || null,
            exercise.time_limit || 30,
          ],
        );
        const testCases = exercise.test_cases || [];
        for (const testCase of testCases) {
          await query(
            'INSERT INTO test_cases (exercise_id, input, expected_output) VALUES (?, ?, ?)',
            [exercise.id, testCase.input, testCase.output],
          );
        }
      }
    }
  }

  const lessonCountResult = await query('SELECT COUNT(*) as count FROM lessons');
  const lessonCount = Array.isArray(lessonCountResult) && lessonCountResult.length > 0 ? lessonCountResult[0].count : 0;
  if (lessonCount === 0) {
    const lessonsFile = path.join(__dirname, '..', 'assets', 'data', 'lessons.json');
    if (fs.existsSync(lessonsFile)) {
      const content = fs.readFileSync(lessonsFile, 'utf8');
      const lessons = JSON.parse(content);
      for (const lesson of lessons) {
        await query(
          'INSERT INTO lessons (id, title, description, code_sample, expected_output, quiz) VALUES (?, ?, ?, ?, ?, ?)',
          [
            lesson.id,
            lesson.title,
            lesson.content,
            lesson.codeSample,
            lesson.expectedOutput,
            JSON.stringify(lesson.quiz || []),
          ],
        );
      }
    }
  }

  const quizCountResult = await query('SELECT COUNT(*) as count FROM quizzes');
  const quizCount = Array.isArray(quizCountResult) && quizCountResult.length > 0 ? quizCountResult[0].count : 0;
  if (quizCount === 0) {
    const quizzesFile = path.join(__dirname, '..', 'assets', 'data', 'quizzes.json');
    if (fs.existsSync(quizzesFile)) {
      const content = fs.readFileSync(quizzesFile, 'utf8');
      const quizzes = JSON.parse(content);
      for (const quiz of quizzes) {
        await query(
          'INSERT INTO quizzes (id, title, description, questions) VALUES (?, ?, ?, ?)',
          [
            quiz.id,
            quiz.title,
            quiz.description,
            JSON.stringify(quiz.questions || []),
          ],
        );
      }
    }
  }

  // Thêm dữ liệu mẫu cho bài tập điền vào chỗ trống
  const fillBlankCountResult = await query('SELECT COUNT(*) as count FROM fill_blank_exercises');
  const fillBlankCount = Array.isArray(fillBlankCountResult) && fillBlankCountResult.length > 0 ? fillBlankCountResult[0].count : 0;
  if (fillBlankCount === 0) {
    const fillBlankExercises = [
      {
        id: 'fb001',
        title: 'Khai báo biến',
        content: 'Trong Dart, để khai báo một biến, chúng ta sử dụng từ khóa _____. Ví dụ: _____ name = "Dart";',
        difficulty: 'cơ bản',
        hint: 'Từ khóa khai báo biến',
        blanks: [
          { correctAnswers: ['var', 'VAR'], hint: 'Từ khóa khai báo biến' },
          { correctAnswers: ['var', 'VAR'], hint: 'Cùng từ khóa var' }
        ]
      },
      {
        id: 'fb002',
        title: 'Hàm trong Dart',
        content: 'Để khai báo một hàm không trả về giá trị, chúng ta sử dụng từ khóa _____. Ví dụ: _____ void sayHello() { print("Hello"); }',
        difficulty: 'cơ bản',
        hint: 'Từ khóa khai báo hàm',
        blanks: [
          { correctAnswers: ['void', 'VOID'], hint: 'Từ khóa khai báo hàm' },
          { correctAnswers: ['void', 'VOID'], hint: 'Kiểu trả về không có giá trị' }
        ]
      },
      {
        id: 'fb003',
        title: 'Cấu trúc điều khiển',
        content: 'Trong Dart, để thực hiện một khối code khi điều kiện đúng, chúng ta sử dụng _____. Cú pháp: _____ (condition) { code }',
        difficulty: 'cơ bản',
        hint: 'Cấu trúc điều kiện',
        blanks: [
          { correctAnswers: ['if', 'IF'], hint: 'Câu lệnh điều kiện' },
          { correctAnswers: ['if', 'IF'], hint: 'Cùng từ khóa if' }
        ]
      },
      {
        id: 'fb004',
        title: 'Vòng lặp',
        content: 'Để lặp qua các phần tử của một List, chúng ta có thể sử dụng _____. Ví dụ: for (var item in _____) { print(item); }',
        difficulty: 'cơ bản',
        hint: 'Vòng lặp for-in',
        blanks: [
          { correctAnswers: ['for', 'FOR'], hint: 'Vòng lặp for' },
          { correctAnswers: ['list', 'myList', 'items'], hint: 'Tên biến List' }
        ]
      },
      {
        id: 'fb005',
        title: 'List trong Dart',
        content: 'Để tạo một List có thể thay đổi, chúng ta sử dụng _____. Ví dụ: _____ numbers = [1, 2, 3];',
        difficulty: 'cơ bản',
        hint: 'Khai báo List',
        blanks: [
          { correctAnswers: ['List', 'var'], hint: 'Khai báo List' },
          { correctAnswers: ['List', 'var'], hint: 'Cùng từ khóa List' }
        ]
      },
      {
        id: 'fb006',
        title: 'Map trong Dart',
        content: 'Để tạo một Map, chúng ta sử dụng _____. Ví dụ: _____ person = {"name": "John", "age": 30};',
        difficulty: 'cơ bản',
        hint: 'Khai báo Map',
        blanks: [
          { correctAnswers: ['Map', 'var'], hint: 'Khai báo Map' },
          { correctAnswers: ['Map', 'var'], hint: 'Cùng từ khóa Map' }
        ]
      },
      {
        id: 'fb007',
        title: 'Class và Object',
        content: 'Để định nghĩa một class trong Dart, chúng ta sử dụng từ khóa _____. Ví dụ: _____ Person { String name; }',
        difficulty: 'trung bình',
        hint: 'Định nghĩa class',
        blanks: [
          { correctAnswers: ['class', 'CLASS'], hint: 'Từ khóa class' },
          { correctAnswers: ['class', 'CLASS'], hint: 'Cùng từ khóa class' }
        ]
      },
      {
        id: 'fb008',
        title: 'Constructor',
        content: 'Trong Dart, constructor mặc định có tên giống với _____. Ví dụ: Person() { }',
        difficulty: 'trung bình',
        hint: 'Tên constructor',
        blanks: [
          { correctAnswers: ['class', 'tên class'], hint: 'Tên của class' }
        ]
      },
      {
        id: 'fb009',
        title: 'Async Programming',
        content: 'Để khai báo một hàm bất đồng bộ, chúng ta sử dụng từ khóa _____. Ví dụ: _____ void fetchData() async { }',
        difficulty: 'trung bình',
        hint: 'Hàm async',
        blanks: [
          { correctAnswers: ['async', 'ASYNC'], hint: 'Từ khóa async' }
        ]
      },
      {
        id: 'fb010',
        title: 'Future',
        content: 'Để chờ kết quả của một Future, chúng ta sử dụng _____. Ví dụ: var result = _____ future;',
        difficulty: 'trung bình',
        hint: 'Đợi Future',
        blanks: [
          { correctAnswers: ['await', 'AWAIT'], hint: 'Từ khóa await' }
        ]
      },
      {
        id: 'fb011',
        title: 'Null Safety',
        content: 'Để khai báo một biến có thể null, chúng ta thêm _____. Ví dụ: String? _____ = null;',
        difficulty: 'trung bình',
        hint: 'Ký hiệu nullable',
        blanks: [
          { correctAnswers: ['?', '\\?'], hint: 'Ký hiệu nullable' },
          { correctAnswers: ['name', 'variable'], hint: 'Tên biến' }
        ]
      },
      {
        id: 'fb012',
        title: 'String Interpolation',
        content: 'Để chèn giá trị biến vào String, chúng ta sử dụng _____. Ví dụ: "Hello _____!"',
        difficulty: 'cơ bản',
        hint: 'Chèn biến vào string',
        blanks: [
          { correctAnswers: ['\\$variable', '\\${variable}'], hint: 'String interpolation' }
        ]
      },
      {
        id: 'fb013',
        title: 'Exception Handling',
        content: 'Để bắt exception, chúng ta sử dụng _____. Ví dụ: try { code } _____ (e) { handle }',
        difficulty: 'trung bình',
        hint: 'Xử lý ngoại lệ',
        blanks: [
          { correctAnswers: ['catch', 'CATCH'], hint: 'Từ khóa catch' }
        ]
      },
      {
        id: 'fb014',
        title: 'Getters và Setters',
        content: 'Để định nghĩa một getter, chúng ta sử dụng từ khóa _____. Ví dụ: String get _____ => _name;',
        difficulty: 'trung bình',
        hint: 'Getter method',
        blanks: [
          { correctAnswers: ['get', 'GET'], hint: 'Từ khóa get' },
          { correctAnswers: ['fullName', 'name'], hint: 'Tên getter' }
        ]
      },
      {
        id: 'fb015',
        title: 'Inheritance',
        content: 'Để kế thừa từ một class, chúng ta sử dụng từ khóa _____. Ví dụ: class Dog _____ Animal { }',
        difficulty: 'nâng cao',
        hint: 'Kế thừa class',
        blanks: [
          { correctAnswers: ['extends', 'EXTENDS'], hint: 'Từ khóa extends' }
        ]
      },
      {
        id: 'fb016',
        title: 'Abstract Class',
        content: 'Để định nghĩa một abstract class, chúng ta sử dụng từ khóa _____. Ví dụ: _____ class Shape { }',
        difficulty: 'nâng cao',
        hint: 'Class trừu tượng',
        blanks: [
          { correctAnswers: ['abstract', 'ABSTRACT'], hint: 'Từ khóa abstract' }
        ]
      },
      {
        id: 'fb017',
        title: 'Mixin',
        content: 'Để sử dụng mixin, chúng ta sử dụng từ khóa _____. Ví dụ: class A _____ B { }',
        difficulty: 'nâng cao',
        hint: 'Mixin trong Dart',
        blanks: [
          { correctAnswers: ['with', 'WITH'], hint: 'Từ khóa with' }
        ]
      },
      {
        id: 'fb018',
        title: 'Generic Types',
        content: 'Để tạo một List với kiểu cụ thể, chúng ta sử dụng _____. Ví dụ: List<_____> numbers = [];',
        difficulty: 'trung bình',
        hint: 'Kiểu generic',
        blanks: [
          { correctAnswers: ['int', 'String', 'double'], hint: 'Kiểu dữ liệu' }
        ]
      },
      {
        id: 'fb019',
        title: 'Enum',
        content: 'Để định nghĩa enum, chúng ta sử dụng từ khóa _____. Ví dụ: _____ Status { active, inactive }',
        difficulty: 'trung bình',
        hint: 'Định nghĩa enum',
        blanks: [
          { correctAnswers: ['enum', 'ENUM'], hint: 'Từ khóa enum' }
        ]
      },
      {
        id: 'fb020',
        title: 'Switch Statement',
        content: 'Trong switch, để xử lý trường hợp mặc định, chúng ta sử dụng _____. Ví dụ: _____ { doSomething(); }',
        difficulty: 'cơ bản',
        hint: 'Trường hợp mặc định',
        blanks: [
          { correctAnswers: ['default', 'DEFAULT'], hint: 'Từ khóa default' }
        ]
      }
    ];

    for (const exercise of fillBlankExercises) {
      await query(
        'INSERT INTO fill_blank_exercises (id, title, content, difficulty, hint) VALUES (?, ?, ?, ?, ?)',
        [exercise.id, exercise.title, exercise.content, exercise.difficulty, exercise.hint]
      );

      for (let i = 0; i < exercise.blanks.length; i++) {
        const blank = exercise.blanks[i];
        await query(
          'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
          [exercise.id, i, JSON.stringify(blank.correctAnswers), blank.hint]
        );
      }
    }
  }
}

async function runDartCode({ code, input, timeout }) {
  const tempRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'dart-runner-'));
  const scriptPath = path.join(tempRoot, 'main.dart');
  const safeInput = typeof input === 'string' ? input : '';
  const safeCode = typeof code === 'string' ? code : '';
  const timeoutSeconds = normalizeTimeout(timeout);

  const blockedPatterns = [
    /Process\./i,
    /File\./i,
    /File\(/i,
    /Directory\./i,
    /Directory\(/i,
    /Socket\./i,
    /HttpClient\./i,
    /HttpServer\./i,
    /ServerSocket\./i,
    /RandomAccessFile\./i,
    /Platform\./i,
  ];

  if (blockedPatterns.some((pattern) => pattern.test(safeCode))) {
    tryRemoveDir(tempRoot);
    return {
      stdout: '',
      stderr: 'Code chứa API hệ thống bị chặn bởi server sandbox.',
      exitCode: 1,
      timedOut: false,
      error: 'Security policy rejected the submitted code.',
    };
  }

  if (Buffer.byteLength(safeCode, 'utf8') > MAX_CODE_SIZE) {
    tryRemoveDir(tempRoot);
    return {
      stdout: '',
      stderr: '',
      exitCode: 1,
      timedOut: false,
      error: 'Code quá lớn.',
    };
  }

  if (Buffer.byteLength(safeInput, 'utf8') > MAX_INPUT_SIZE) {
    tryRemoveDir(tempRoot);
    return {
      stdout: '',
      stderr: '',
      exitCode: 1,
      timedOut: false,
      error: 'Input quá lớn.',
    };
  }

  fs.writeFileSync(scriptPath, safeCode, 'utf8');

  return new Promise((resolve) => {
    let stdout = '';
    let stderr = '';
    let timedOut = false;
    let finished = false;

    const child = spawn(DART_EXECUTABLE, [scriptPath], {
      cwd: tempRoot,
      shell: false,
      windowsHide: true,
      stdio: ['pipe', 'pipe', 'pipe'],
      env: {
        PATH: process.env.PATH || '',
        HOME: tempRoot,
        TMP: tempRoot,
        TEMP: tempRoot,
        TMPDIR: tempRoot,
      },
    });

    const timer = setTimeout(() => {
      timedOut = true;
      child.kill('SIGKILL');
    }, timeoutSeconds * 1000);

    child.stdout.on('data', (chunk) => {
      stdout += chunk.toString('utf8');
    });

    child.stderr.on('data', (chunk) => {
      stderr += chunk.toString('utf8');
    });

    child.on('error', (error) => {
      if (finished) {
        return;
      }
      finished = true;
      clearTimeout(timer);
      tryRemoveDir(tempRoot);
      resolve({
        stdout,
        stderr,
        exitCode: null,
        timedOut: false,
        error: `Không thể khởi chạy Dart: ${error.message}`,
      });
    });

    child.on('close', (exitCode) => {
      if (finished) {
        return;
      }
      finished = true;
      clearTimeout(timer);
      tryRemoveDir(tempRoot);
      resolve({
        stdout,
        stderr,
        exitCode: timedOut ? null : exitCode,
        timedOut,
        error: timedOut ? 'Code chạy quá thời gian cho phép.' : null,
      });
    });

    if (safeInput.length > 0) {
      child.stdin.write(safeInput);
      if (!safeInput.endsWith('\n')) {
        child.stdin.write('\n');
      }
    }
    child.stdin.end();
  });
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  if (req.method === 'GET' && req.url === '/health') {
    sendJson(res, 200, { ok: true });
    return;
  }

  if (req.method === 'POST' && req.url === '/run_dart') {
    try {
      const body = await readRequestBody(req);
      let payload;

      try {
        payload = body ? JSON.parse(body) : {};
      } catch (_) {
        sendJson(res, 400, { error: 'JSON không hợp lệ' });
        return;
      }

      const result = await runDartCode({
        code: payload.code,
        input: payload.input,
        timeout: payload.timeout,
      });

      const statusCode = result.error ? 400 : 200;
      sendJson(res, statusCode, result);
      return;
    } catch (error) {
      sendJson(res, 500, {
        stdout: '',
        stderr: '',
        exitCode: null,
        timedOut: false,
        error: error.message || 'Lỗi server không xác định',
      });
      return;
    }
  }

  if (req.url === '/api/health' && req.method === 'GET') {
    sendJson(res, 200, { ok: true });
    return;
  }

  if (req.url === '/api/register' && req.method === 'POST') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const email = String(payload.email || '').trim();
      const password = String(payload.password || '');
      const displayName = String(payload.display_name || '').trim();

      if (!email || !password || !displayName) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin đăng ký' });
        return;
      }

      const existing = await query('SELECT 1 FROM users WHERE email = ? LIMIT 1', [email]);
      if (existing.length > 0) {
        sendJson(res, 409, { success: false, error: 'Email đã tồn tại' });
        return;
      }

      await query(
        'INSERT INTO users (email, password, display_name, is_admin) VALUES (?, ?, ?, FALSE)',
        [email, password, displayName],
      );

      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi đăng ký' });
      return;
    }
  }

  if (req.url === '/api/login' && req.method === 'POST') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const email = String(payload.email || '').trim();
      const password = String(payload.password || '');

      if (!email || !password) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin đăng nhập' });
        return;
      }

      const rows = await query('SELECT display_name, password, is_admin FROM users WHERE email = ? LIMIT 1', [email]);
      if (rows.length === 0 || rows[0].password !== password) {
        sendJson(res, 401, { success: false, error: 'Sai email hoặc mật khẩu' });
        return;
      }

      sendJson(res, 200, {
        success: true,
        display_name: rows[0].display_name,
        is_admin: Boolean(rows[0].is_admin),
      });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi đăng nhập' });
      return;
    }
  }

  if (req.url === '/api/update_profile' && req.method === 'POST') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const email = String(payload.email || '').trim();
      const displayName = String(payload.display_name || '').trim();
      const password = payload.password ? String(payload.password) : null;

      if (!email || !displayName) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin cập nhật' });
        return;
      }

      const updates = [];
      const params = [];
      updates.push('display_name = ?');
      params.push(displayName);
      if (password) {
        updates.push('password = ?');
        params.push(password);
      }
      params.push(email);

      await query(`UPDATE users SET ${updates.join(', ')} WHERE email = ?`, params);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật profile' });
      return;
    }
  }

  if (req.method === 'GET' && req.url === '/api/users') {
    try {
      const users = await query('SELECT email, display_name, is_admin FROM users ORDER BY email');
      sendJson(res, 200, {
        users: users.map((user) => ({
          email: user.email,
          display_name: user.display_name,
          is_admin: Boolean(user.is_admin),
        })),
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy danh sách người dùng' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/users') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const email = String(payload.email || '').trim();
      const password = String(payload.password || '');
      const displayName = String(payload.display_name || '').trim();
      const isAdmin = payload.is_admin === true;

      if (!email || !password || !displayName) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin người dùng' });
        return;
      }

      const existing = await query('SELECT 1 FROM users WHERE email = ? LIMIT 1', [email]);
      if (existing.length > 0) {
        sendJson(res, 409, { success: false, error: 'Email đã tồn tại' });
        return;
      }

      await query(
        'INSERT INTO users (email, password, display_name, is_admin) VALUES (?, ?, ?, ?)',
        [email, password, displayName, isAdmin],
      );

      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tạo người dùng' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url.startsWith('/api/users/')) {
    try {
      const email = decodeURIComponent(req.url.replace('/api/users/', ''));
      await query('DELETE FROM users WHERE email = ?', [email]);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi xóa người dùng' });
      return;
    }
  }

  if (req.method === 'PUT' && req.url.startsWith('/api/users/')) {
    try {
      const email = decodeURIComponent(req.url.replace('/api/users/', ''));
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const displayName = String(payload.display_name || '').trim();
      const isAdmin = payload.is_admin === true;
      const password = payload.password ? String(payload.password) : null;

      if (!displayName) {
        sendJson(res, 400, { success: false, error: 'Thiếu tên hiển thị' });
        return;
      }

      let queryStr = 'UPDATE users SET display_name = ?, is_admin = ? WHERE email = ?';
      let params = [displayName, isAdmin, email];

      if (password) {
        queryStr = 'UPDATE users SET display_name = ?, is_admin = ?, password = ? WHERE email = ?';
        params = [displayName, isAdmin, password, email];
      }

      const result = await query(queryStr, params);
      if (result.affectedRows === 0) {
        sendJson(res, 404, { success: false, error: 'Không tìm thấy người dùng' });
        return;
      }

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật người dùng' });
      return;
    }
  }

  if (req.method === 'GET' && req.url === '/api/lessons') {
    try {
      const lessons = await query('SELECT * FROM lessons ORDER BY id');
      sendJson(res, 200, {
        lessons: lessons.map((lesson) => ({
          id: lesson.id,
          title: lesson.title,
          content: lesson.description,
          codeSample: lesson.code_sample,
          expectedOutput: lesson.expected_output,
          quiz: JSON.parse(lesson.quiz || '[]'),
          exercises: JSON.parse(lesson.exercises || '[]'),
        })),
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy danh sách bài học' });
      return;
    }
  }

  if (req.method === 'GET' && req.url.startsWith('/api/lessons/')) {
    try {
      const id = req.url.replace('/api/lessons/', '');
      const rows = await query('SELECT * FROM lessons WHERE id = ? LIMIT 1', [id]);
      if (rows.length === 0) {
        sendJson(res, 404, { error: 'Không tìm thấy bài học' });
        return;
      }
      const lesson = rows[0];
      sendJson(res, 200, {
        lesson: {
          id: lesson.id,
          title: lesson.title,
          content: lesson.description,
          codeSample: lesson.code_sample,
          expectedOutput: lesson.expected_output,
          quiz: JSON.parse(lesson.quiz || '[]'),
        },
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy bài học' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/lessons') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const id = String(payload.id || '').trim();
      const title = String(payload.title || '').trim();
      const content = String(payload.content || '').trim();
      const codeSample = String(payload.codeSample || '').trim();
      const expectedOutput = String(payload.expectedOutput || '').trim();
      const quiz = JSON.stringify(payload.quiz ?? []);
      const exercises = JSON.stringify(payload.exercises ?? []);

      if (!id || !title || !content) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài học' });
        return;
      }

      await query(
        'INSERT INTO lessons (id, title, description, code_sample, expected_output, quiz, exercises) VALUES (?, ?, ?, ?, ?, ?, ?)',
        [id, title, content, codeSample, expectedOutput, quiz, exercises],
      );
      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tạo bài học' });
      return;
    }
  }

  if (req.method === 'PUT' && req.url.startsWith('/api/lessons/')) {
    try {
      const id = req.url.replace('/api/lessons/', '');
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const title = String(payload.title || '').trim();
      const content = String(payload.content || '').trim();
      const codeSample = String(payload.codeSample || '').trim();
      const expectedOutput = String(payload.expectedOutput || '').trim();
      const quiz = JSON.stringify(payload.quiz ?? []);
      const exercises = JSON.stringify(payload.exercises ?? []);

      if (!title || !content) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài học' });
        return;
      }

      await query(
        'UPDATE lessons SET title = ?, description = ?, code_sample = ?, expected_output = ?, quiz = ?, exercises = ? WHERE id = ?',
        [title, content, codeSample, expectedOutput, quiz, exercises, id],
      );
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật bài học' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url.startsWith('/api/lessons/')) {
    try {
      const id = req.url.replace('/api/lessons/', '');
      await query('DELETE FROM lessons WHERE id = ?', [id]);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi xóa bài học' });
      return;
    }
  }

  if (req.method === 'GET' && req.url === '/api/quizzes') {
    try {
      const quizzes = await query('SELECT * FROM quizzes ORDER BY id');
      sendJson(res, 200, {
        quizzes: quizzes.map((quiz) => ({
          id: quiz.id,
          title: quiz.title,
          description: quiz.description,
          questions: JSON.parse(quiz.questions || '[]'),
        })),
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy danh sách quiz' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/quizzes') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const id = String(payload.id || '').trim();
      const title = String(payload.title || '').trim();
      const description = String(payload.description || '').trim();
      const questions = JSON.stringify(payload.questions || []);

      if (!id || !title || !description) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin quiz' });
        return;
      }

      await query(
        'INSERT INTO quizzes (id, title, description, questions) VALUES (?, ?, ?, ?)',
        [id, title, description, questions],
      );

      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tạo quiz' });
      return;
    }
  }

  if (req.method === 'PUT' && req.url.startsWith('/api/quizzes/')) {
    try {
      const id = req.url.replace('/api/quizzes/', '');
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const title = String(payload.title || '').trim();
      const description = String(payload.description || '').trim();
      const questions = JSON.stringify(payload.questions || []);

      if (!title || !description) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin quiz' });
        return;
      }

      const result = await query(
        'UPDATE quizzes SET title = ?, description = ?, questions = ? WHERE id = ?',
        [title, description, questions, id],
      );

      if (result.affectedRows === 0) {
        sendJson(res, 404, { success: false, error: 'Không tìm thấy quiz' });
        return;
      }

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật quiz' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url.startsWith('/api/quizzes/')) {
    try {
      const id = req.url.replace('/api/quizzes/', '');
      await query('DELETE FROM quizzes WHERE id = ?', [id]);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi xóa quiz' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/admin/load-sample-data') {
    try {
      // Load lessons sample data
      const lessonsFile = path.join(__dirname, '..', 'assets', 'data', 'lessons.json');
      if (fs.existsSync(lessonsFile)) {
        const content = fs.readFileSync(lessonsFile, 'utf8');
        const lessons = JSON.parse(content);
        for (const lesson of lessons) {
          const existing = await query('SELECT 1 FROM lessons WHERE id = ? LIMIT 1', [lesson.id]);
          if (existing.length === 0) {
            await query(
              'INSERT INTO lessons (id, title, description, code_sample, expected_output, quiz) VALUES (?, ?, ?, ?, ?, ?)',
              [
                lesson.id,
                lesson.title,
                lesson.content,
                lesson.codeSample,
                lesson.expectedOutput,
                JSON.stringify(lesson.quiz || []),
              ],
            );
          }
        }
      }

      // Load quizzes sample data
      const quizzesFile = path.join(__dirname, '..', 'assets', 'data', 'quizzes.json');
      if (fs.existsSync(quizzesFile)) {
        // Xóa tất cả quiz cũ
        await query('DELETE FROM quizzes');
        const content = fs.readFileSync(quizzesFile, 'utf8');
        const quizzes = JSON.parse(content);
        for (const quiz of quizzes) {
          await query(
            'INSERT INTO quizzes (id, title, description, questions) VALUES (?, ?, ?, ?)',
            [
              quiz.id,
              quiz.title,
              quiz.description,
              JSON.stringify(quiz.questions || []),
            ],
          );
        }
      }

      // Load exercises sample data
      const exercisesFile = path.join(__dirname, '..', 'assets', 'data', 'exercises.json');
      if (fs.existsSync(exercisesFile)) {
        const content = fs.readFileSync(exercisesFile, 'utf8');
        const exercises = JSON.parse(content);
        for (const exercise of exercises) {
          const existing = await query('SELECT 1 FROM exercises WHERE id = ? LIMIT 1', [exercise.id]);
          if (existing.length === 0) {
            await query(
              'INSERT INTO exercises (id, title, description, input_format, output_format, difficulty, hint, time_limit) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
              [
                exercise.id,
                exercise.title,
                exercise.description,
                exercise.input,
                exercise.output,
                exercise.difficulty || 'cơ bản',
                exercise.hint || null,
                exercise.time_limit || 30,
              ],
            );
            const testCases = exercise.test_cases || [];
            for (const testCase of testCases) {
              await query(
                'INSERT INTO test_cases (exercise_id, input, expected_output) VALUES (?, ?, ?)',
                [exercise.id, testCase.input, testCase.output],
              );
            }
          }
        }
      }

      sendJson(res, 200, { success: true, message: 'Dữ liệu mẫu đã được tải' });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tải dữ liệu mẫu' });
      return;
    }
  }

  if (req.method === 'GET' && req.url === '/api/exercises') {
    try {
      const exercises = await query('SELECT * FROM exercises ORDER BY id');
      const result = [];
      for (const exercise of exercises) {
        const testCases = await query('SELECT input, expected_output FROM test_cases WHERE exercise_id = ?', [exercise.id]);
        result.push({
          id: exercise.id,
          title: exercise.title,
          description: exercise.description,
          input: exercise.input_format,
          output: exercise.output_format,
          difficulty: exercise.difficulty,
          hint: exercise.hint,
          time_limit: exercise.time_limit,
          test_cases: testCases.map((tc) => ({
            input: tc.input,
            output: tc.expected_output,
          })),
        });
      }
      sendJson(res, 200, { exercises: result });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy danh sách bài tập' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/exercises') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const id = String(payload.id || '').trim();
      const title = String(payload.title || '').trim();
      const description = String(payload.description || '').trim();
      const inputFormat = String(payload.input || '').trim();
      const outputFormat = String(payload.output || '').trim();
      const difficulty = String(payload.difficulty || '').trim();
      const hint = payload.hint ? String(payload.hint) : null;
      const timeLimit = Number(payload.time_limit || 30);
      const testCases = payload.test_cases || [];

      if (!id || !title || !description || !inputFormat || !outputFormat || !difficulty) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài tập' });
        return;
      }

      await query(
        'INSERT INTO exercises (id, title, description, input_format, output_format, difficulty, hint, time_limit) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
        [id, title, description, inputFormat, outputFormat, difficulty, hint, timeLimit],
      );
      for (const testCase of testCases) {
        await query(
          'INSERT INTO test_cases (exercise_id, input, expected_output) VALUES (?, ?, ?)',
          [id, String(testCase.input || ''), String(testCase.output || '')],
        );
      }
      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tạo bài tập' });
      return;
    }
  }

  if (req.method === 'PUT' && req.url.startsWith('/api/exercises/')) {
    try {
      const id = req.url.replace('/api/exercises/', '');
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const title = String(payload.title || '').trim();
      const description = String(payload.description || '').trim();
      const inputFormat = String(payload.input || '').trim();
      const outputFormat = String(payload.output || '').trim();
      const difficulty = String(payload.difficulty || '').trim();
      const hint = payload.hint ? String(payload.hint) : null;
      const timeLimit = Number(payload.time_limit || 30);
      const testCases = payload.test_cases || [];

      if (!title || !description || !inputFormat || !outputFormat || !difficulty) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài tập' });
        return;
      }

      await query(
        'UPDATE exercises SET title = ?, description = ?, input_format = ?, output_format = ?, difficulty = ?, hint = ?, time_limit = ? WHERE id = ?',
        [title, description, inputFormat, outputFormat, difficulty, hint, timeLimit, id],
      );
      await query('DELETE FROM test_cases WHERE exercise_id = ?', [id]);
      for (const testCase of testCases) {
        await query(
          'INSERT INTO test_cases (exercise_id, input, expected_output) VALUES (?, ?, ?)',
          [id, String(testCase.input || ''), String(testCase.output || '')],
        );
      }
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật bài tập' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url.startsWith('/api/exercises/')) {
    try {
      const id = req.url.replace('/api/exercises/', '');
      await query('DELETE FROM test_cases WHERE exercise_id = ?', [id]);
      await query('DELETE FROM exercises WHERE id = ?', [id]);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi xóa bài tập' });
      return;
    }
  }

  const exerciseIdMatch = req.method === 'GET' && req.url.startsWith('/api/exercises/');
  if (exerciseIdMatch) {
    try {
      const id = req.url.replace('/api/exercises/', '');
      const rows = await query('SELECT * FROM exercises WHERE id = ? LIMIT 1', [id]);
      if (rows.length === 0) {
        sendJson(res, 404, { error: 'Không tìm thấy bài tập' });
        return;
      }
      const exercise = rows[0];
      const testCases = await query('SELECT input, expected_output FROM test_cases WHERE exercise_id = ?', [id]);
      sendJson(res, 200, {
        exercise: {
          id: exercise.id,
          title: exercise.title,
          description: exercise.description,
          input: exercise.input_format,
          output: exercise.output_format,
          difficulty: exercise.difficulty,
          hint: exercise.hint,
          time_limit: exercise.time_limit,
          test_cases: testCases.map((tc) => ({
            input: tc.input,
            output: tc.expected_output,
          })),
        },
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy bài tập' });
      return;
    }
  }

  // Routes cho bài tập điền vào chỗ trống
  if (req.method === 'GET' && req.url === '/api/fill-blank/exercises') {
    try {
      const exercises = await query('SELECT id, title, difficulty, hint FROM fill_blank_exercises ORDER BY id');
      sendJson(res, 200, { exercises });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy danh sách bài tập điền vào chỗ trống' });
      return;
    }
  }

  if (req.method === 'GET' && req.url.startsWith('/api/fill-blank/exercises/')) {
    try {
      const id = req.url.replace('/api/fill-blank/exercises/', '');
      const rows = await query('SELECT id, title, content, difficulty, hint FROM fill_blank_exercises WHERE id = ? LIMIT 1', [id]);
      if (rows.length === 0) {
        sendJson(res, 404, { error: 'Không tìm thấy bài tập điền vào chỗ trống' });
        return;
      }
      const exercise = rows[0];
      const answers = await query('SELECT blank_index, correct_answers, hint FROM fill_blank_answers WHERE exercise_id = ? ORDER BY blank_index', [id]);
      sendJson(res, 200, {
        exercise: {
          id: exercise.id,
          title: exercise.title,
          content: exercise.content,
          difficulty: exercise.difficulty,
          hint: exercise.hint,
          blanks: answers.map(a => ({ index: a.blank_index, correctAnswers: JSON.parse(a.correct_answers || '[]'), hint: a.hint }))
        }
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy bài tập điền vào chỗ trống' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/fill-blank/check') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const exerciseId = String(payload.exerciseId || '').trim();
      const userEmail = String(payload.userEmail || '').trim();
      const answers = payload.answers || [];

      if (!exerciseId || !userEmail || !Array.isArray(answers)) {
        sendJson(res, 400, { error: 'Thiếu thông tin kiểm tra' });
        return;
      }

      // Lấy đáp án đúng
      const correctAnswers = await query('SELECT blank_index, correct_answers FROM fill_blank_answers WHERE exercise_id = ? ORDER BY blank_index', [exerciseId]);
      const totalBlanks = correctAnswers.length;
      let score = 0;
      const results = [];

      for (let i = 0; i < totalBlanks; i++) {
        const correct = correctAnswers.find(ca => ca.blank_index === i);
        const userAnswer = answers[i] ? String(answers[i]).trim().toLowerCase() : '';
        const correctList = JSON.parse(correct.correct_answers || '[]').map(a => String(a).trim().toLowerCase());
        const isCorrect = correctList.includes(userAnswer);
        if (isCorrect) score++;
        results.push({
          blankIndex: i,
          userAnswer: answers[i] || '',
          isCorrect,
          correctAnswers: JSON.parse(correct.correct_answers || '[]')
        });
      }

      const completed = score === totalBlanks;

      // Lưu tiến độ
      await query(`
        INSERT INTO user_fill_blank_progress (user_email, exercise_id, score, total_blanks, completed)
        VALUES (?, ?, ?, ?, ?)
        ON DUPLICATE KEY UPDATE score = VALUES(score), total_blanks = VALUES(total_blanks), completed = VALUES(completed), last_attempt = CURRENT_TIMESTAMP
      `, [userEmail, exerciseId, score, totalBlanks, completed]);

      sendJson(res, 200, {
        score,
        totalBlanks,
        completed,
        results
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi kiểm tra bài tập' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/admin/fill-blank') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const id = String(payload.id || '').trim();
      const title = String(payload.title || '').trim();
      const content = String(payload.content || '').trim();
      const difficulty = String(payload.difficulty || 'cơ bản').trim();
      const hint = payload.hint ? String(payload.hint) : null;
      const blanks = payload.blanks || [];

      if (!id || !title || !content || !Array.isArray(blanks)) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài tập' });
        return;
      }

      await query(
        'INSERT INTO fill_blank_exercises (id, title, content, difficulty, hint) VALUES (?, ?, ?, ?, ?)',
        [id, title, content, difficulty, hint]
      );

      for (let i = 0; i < blanks.length; i++) {
        const blank = blanks[i];
        const correctAnswers = JSON.stringify(blank.correctAnswers || []);
        const blankHint = blank.hint ? String(blank.hint) : null;
        await query(
          'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
          [id, i, correctAnswers, blankHint]
        );
      }

      sendJson(res, 201, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi tạo bài tập điền vào chỗ trống' });
      return;
    }
  }

  if (req.method === 'PUT' && req.url.startsWith('/api/admin/fill-blank/')) {
    try {
      const id = req.url.replace('/api/admin/fill-blank/', '');
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const title = String(payload.title || '').trim();
      const content = String(payload.content || '').trim();
      const difficulty = String(payload.difficulty || 'cơ bản').trim();
      const hint = payload.hint ? String(payload.hint) : null;
      const blanks = payload.blanks || [];

      if (!title || !content || !Array.isArray(blanks)) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài tập' });
        return;
      }

      await query(
        'UPDATE fill_blank_exercises SET title = ?, content = ?, difficulty = ?, hint = ? WHERE id = ?',
        [title, content, difficulty, hint, id]
      );

      await query('DELETE FROM fill_blank_answers WHERE exercise_id = ?', [id]);

      for (let i = 0; i < blanks.length; i++) {
        const blank = blanks[i];
        const correctAnswers = JSON.stringify(blank.correctAnswers || []);
        const blankHint = blank.hint ? String(blank.hint) : null;
        await query(
          'INSERT INTO fill_blank_answers (exercise_id, blank_index, correct_answers, hint) VALUES (?, ?, ?, ?)',
          [id, i, correctAnswers, blankHint]
        );
      }

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi cập nhật bài tập điền vào chỗ trống' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url.startsWith('/api/admin/fill-blank/')) {
    try {
      const id = req.url.replace('/api/admin/fill-blank/', '');
      await query('DELETE FROM fill_blank_answers WHERE exercise_id = ?', [id]);
      await query('DELETE FROM fill_blank_exercises WHERE id = ?', [id]);
      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { success: false, error: error.message || 'Lỗi xóa bài tập điền vào chỗ trống' });
      return;
    }
  }

  // Routes cho progress
  if (req.method === 'GET' && req.url === '/api/progress') {
    try {
      const userEmail = req.headers['user-email'];
      if (!userEmail) {
        sendJson(res, 401, { error: 'Chưa đăng nhập' });
        return;
      }

      const progress = await query(
        'SELECT lesson_id, exercise_id, `type` FROM user_progress WHERE user_email = ? AND completed = TRUE',
        [userEmail]
      );

      const completedLessons = progress.filter(p => p.type === 'lesson').map(p => p.lesson_id);
      const completedExercises = progress.filter(p => p.type === 'exercise').map(p => p.exercise_id);

      sendJson(res, 200, {
        completed_lessons: completedLessons,
        completed_exercises: completedExercises,
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy tiến độ' });
      return;
    }
  }

  if (req.method === 'POST' && req.url === '/api/progress') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const userEmail = payload.user_email;
      const type = payload.type; // 'lesson' or 'exercise'
      const id = payload.id; // lesson_id or exercise_id

      if (!userEmail || !type || !id) {
        sendJson(res, 400, { error: 'Thiếu thông tin' });
        return;
      }

      // Use INSERT ... ON DUPLICATE KEY UPDATE to avoid constraint errors
      const lessonId = type === 'lesson' ? id : null;
      const exerciseId = type === 'exercise' ? id : null;

      await query(
        `INSERT INTO user_progress (user_email, lesson_id, exercise_id, \`type\`, completed, completed_at)
         VALUES (?, ?, ?, ?, TRUE, CURRENT_TIMESTAMP)
         ON DUPLICATE KEY UPDATE completed = TRUE, completed_at = CURRENT_TIMESTAMP`,
        [userEmail, lessonId, exerciseId, type]
      );

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lưu tiến độ' });
      return;
    }
  }

  if (req.method === 'DELETE' && req.url === '/api/progress') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const userEmail = payload.user_email;
      const type = payload.type;
      const id = payload.id;

      if (!userEmail || !type || !id) {
        sendJson(res, 400, { error: 'Thiếu thông tin' });
        return;
      }

      const column = type === 'lesson' ? 'lesson_id' : 'exercise_id';
      await query(
        `DELETE FROM user_progress WHERE user_email = ? AND ${column} = ? AND \`type\` = ?`,
        [userEmail, id, type]
      );

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi xóa tiến độ' });
      return;
    }
  }

  // API sync offline progress
  if (req.method === 'POST' && req.url === '/api/progress/sync') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const userEmail = payload.user_email;
      const type = payload.type; // 'lesson', 'exercise', 'fill_blank'
      const id = payload.id;
      const timestamp = payload.timestamp;

      if (!userEmail || !type || !id) {
        sendJson(res, 400, { error: 'Thiếu thông tin' });
        return;
      }

      // Use INSERT ... ON DUPLICATE KEY UPDATE to handle both insert and update
      if (type === 'fill_blank') {
        // Handle fill_blank progress (different table)
        await query(
          `INSERT INTO user_fill_blank_progress (user_email, exercise_id, score, total_blanks, completed, completed_at)
           VALUES (?, ?, 100, 1, TRUE, ?)
           ON DUPLICATE KEY UPDATE completed = TRUE, completed_at = VALUES(completed_at)`,
          [userEmail, id, timestamp]
        );
      } else {
        // Handle lesson and exercise progress
        const lessonId = type === 'lesson' ? id : null;
        const exerciseId = type === 'exercise' ? id : null;

        await query(
          `INSERT INTO user_progress (user_email, lesson_id, exercise_id, \`type\`, completed, completed_at)
           VALUES (?, ?, ?, ?, TRUE, ?)
           ON DUPLICATE KEY UPDATE completed = TRUE, completed_at = VALUES(completed_at)`,
          [userEmail, lessonId, exerciseId, type, timestamp]
        );
      }

      sendJson(res, 200, { success: true });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi đồng bộ tiến độ' });
      return;
    }
  }

  // Routes cho fill-blank progress
  if (req.method === 'GET' && req.url === '/api/fill-blank/progress') {
    try {
      const userEmail = req.headers['user-email'];
      if (!userEmail) {
        sendJson(res, 401, { error: 'Chưa đăng nhập' });
        return;
      }

      const progress = await query(
        'SELECT exercise_id, score, total_blanks, completed FROM user_fill_blank_progress WHERE user_email = ?',
        [userEmail]
      );

      sendJson(res, 200, {
        fill_blank_progress: progress,
      });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi lấy tiến độ fill-blank' });
      return;
    }
  }

  // API xóa tiến độ hàng loạt
  if (req.method === 'DELETE' && req.url === '/api/admin/clear-progress') {
    try {
      const body = await readRequestBody(req);
      const payload = JSON.parse(body);
      const type = payload.type; // 'all', 'exercises', 'fill_blank'

      if (!type) {
        sendJson(res, 400, { error: 'Thiếu loại tiến độ cần xóa' });
        return;
      }

      if (type === 'all') {
        // Xóa tất cả tiến độ
        await query('DELETE FROM user_progress');
        await query('DELETE FROM user_fill_blank_progress');
      } else if (type === 'exercises') {
        // Xóa tiến độ bài tập code
        await query('DELETE FROM user_progress WHERE type = ?', ['exercise']);
      } else if (type === 'fill_blank') {
        // Xóa tiến độ bài tập điền chỗ trống
        await query('DELETE FROM user_fill_blank_progress');
      }

      sendJson(res, 200, { success: true, message: `Đã xóa tiến độ ${type}` });
      return;
    } catch (error) {
      sendJson(res, 500, { error: error.message || 'Lỗi xóa tiến độ' });
      return;
    }
  }

  sendJson(res, 404, { error: 'Không tìm thấy endpoint' });
});

(async () => {
  try {
    await initDatabase();
    server.listen(PORT, HOST, () => {
      console.log(`Dart runner server listening on http://${HOST}:${PORT}`);
    });
  } catch (error) {
    console.error('Không thể khởi tạo database MySQL:', error);
    process.exit(1);
  }
})();
