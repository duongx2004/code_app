const fs = require('fs');
const path = require('path');

// Đọc file templates
const templatesPath = path.join(__dirname, '..', 'exercise_templates.json');
const templates = JSON.parse(fs.readFileSync(templatesPath, 'utf8'));

// Import các bài tập vào database qua API
async function importExercises() {
  const exercises = templates.code_exercises;

  console.log(`Importing ${exercises.length} exercises...`);

  for (const exercise of exercises) {
    try {
      const response = await fetch('http://localhost:8080/api/exercises', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          id: exercise.id,
          title: exercise.title,
          description: exercise.description,
          input_format: exercise.input_format,
          output_format: exercise.output_format,
          difficulty: exercise.difficulty,
          time_limit: exercise.time_limit,
          hint: exercise.hint,
          test_cases: exercise.test_cases
        })
      });

      if (response.ok) {
        console.log(`✓ Imported: ${exercise.title}`);
      } else {
        console.log(`✗ Failed: ${exercise.title} - ${response.status}`);
      }
    } catch (error) {
      console.log(`✗ Error: ${exercise.title} - ${error.message}`);
    }
  }

  console.log('Import completed!');
}

// Chạy import
importExercises().catch(console.error);