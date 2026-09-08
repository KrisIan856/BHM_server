const db = require("../config/db");
const bcrypt = require("bcryptjs");

const SALT_ROUNDS = 10;

async function findByUsername(username) {
  const [rows] = await db.query(
    "SELECT id, username, password_hash, role FROM users WHERE username = ?",
    [username]
  );
  return rows[0] || null;
}

async function create(username, password, role) {
  const password_hash = await bcrypt.hash(password, SALT_ROUNDS);
  const [result] = await db.query(
    "INSERT INTO users (username, password_hash, role) VALUES (?, ?, ?)",
    [username, password_hash, role]
  );
  return { id: result.insertId, username, role };
}

async function verifyPassword(plaintext, hash) {
  return bcrypt.compare(plaintext, hash);
}

module.exports = { findByUsername, create, verifyPassword };
