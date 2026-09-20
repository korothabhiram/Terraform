-- schema.sql
-- Run this in phpMyAdmin (or applied automatically by init-schema.php) to set up the database.

CREATE DATABASE IF NOT EXISTS php_crud_demo;
USE php_crud_demo;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: sample row so index.php isn't empty on first load.
-- Idempotent: every ASG instance runs this at boot, so it must not re-insert.
INSERT INTO users (name, email)
SELECT 'Abhiram Koroth', 'abhiram1289@gmail.com'
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'abhiram1289@gmail.com');
