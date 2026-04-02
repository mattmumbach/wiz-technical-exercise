const express = require('express');
const { MongoClient } = require('mongodb');
const fs = require('fs');

const app = express();
const port = 3000;

// MongoDB connection string from environment variable
const mongoUri = process.env.MONGO_URI || 'mongodb://localhost:27017';

let db;

async function connectDB() {
  try {
    const client = new MongoClient(mongoUri, { useUnifiedTopology: true });
    await client.connect();
    db = client.db('wiz-exercise-db');
    console.log('Connected to MongoDB');
    
    // Create a collection and insert a test document if it doesn't exist
    const collection = db.collection('todos');
    const count = await collection.countDocuments();
    if (count === 0) {
      await collection.insertOne({ task: 'Welcome to AttackPath Express!', completed: false });
      console.log('Inserted initial todo item');
    }
  } catch (err) {
    console.error('Failed to connect to MongoDB:', err.message);
    // Don't exit, just log the error (for demo purposes)
  }
}

connectDB();

app.get('/', async (req, res) => {
  let html = `
    <html>
      <head><title>AttackPath Express</title></head>
      <body style="font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto;">
        <h1>🚂 AttackPath Express</h1>
        <p><strong>Destination:</strong> Full Account Compromise</p>
        <p><strong>Current Station:</strong> Public SSH → MongoDB → IAM Admin</p>
        <p style="color: orange; background-color: #fff3cd; padding: 10px; border-radius: 5px;">
          ⚠️ This app is intentionally vulnerable. Wiz would flag this as <span style="background-color: red; color: white; padding: 2px 5px; border-radius: 3px;">Critical</span>.
        </p>
        <h2>Todos:</h2>
        <ul>
  `;

  if (db) {
    try {
      const todos = await db.collection('todos').find().toArray();
      todos.forEach(todo => {
        html += `<li>${todo.task} - ${todo.completed ? 'Done' ✅ : 'Pending' ⏳}</li>`;
      });
    } catch (err) {
      html += `<li>Error fetching todos: ${err.message}</li>`;
    }
  } else {
    html += `<li>Database not connected.</li>`;
  }

  html += `
        </ul>
        <p><small><em>Powered by MongoDB 4.4 (EOL) • Running on EC2 with Admin IAM • SSH exposed to the internet</em></small></p>
      </body>
    </html>
  `;
  res.send(html);
});

app.listen(port, () => {
  console.log(`AttackPath Express listening on port ${port}`);
});
