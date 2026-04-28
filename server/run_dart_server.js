const http = require('http');
const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawn, execSync } = require('child_process');
const mysql = require('mysql2/promise');
const dotenv = require('dotenv');

dotenv.config();

const PORT = Number(process.env.PORT || 8080);
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
    quiz TEXT NOT NULL
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

      if (!id || !title || !content || !codeSample || !expectedOutput) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài học' });
        return;
      }

      await query(
        'INSERT INTO lessons (id, title, description, code_sample, expected_output, quiz) VALUES (?, ?, ?, ?, ?, ?)',
        [id, title, content, codeSample, expectedOutput, quiz],
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

      if (!title || !content || !codeSample || !expectedOutput) {
        sendJson(res, 400, { success: false, error: 'Thiếu thông tin bài học' });
        return;
      }

      await query(
        'UPDATE lessons SET title = ?, description = ?, code_sample = ?, expected_output = ?, quiz = ? WHERE id = ?',
        [title, content, codeSample, expectedOutput, quiz, id],
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
