-- schema.sql
-- Run this in phpMyAdmin (Import tab, or the SQL tab) to set up the database.

CREATE DATABASE IF NOT EXISTS php_crud_demo;
USE php_crud_demo;

CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Optional: sample row so index.php isn't empty on first load
INSERT INTO users (name, email) VALUES
('Abhiram Koroth', 'abhiram1289@gmail.com');
