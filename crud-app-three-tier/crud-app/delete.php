<?php
// delete.php — Delete: remove a user by id
require 'db.php';

$id = $_GET['id'] ?? null;

if ($id) {
    $stmt = $pdo->prepare("DELETE FROM users WHERE id = :id");
    $stmt->execute(['id' => $id]);
}

header('Location: index.php?msg=deleted');
exit;
