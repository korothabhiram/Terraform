<?php
// init-schema.php - applies schema.sql to the database named by the DB_*
// environment variables. Safe to run from every container at once:
//  - schema.sql only uses CREATE ... IF NOT EXISTS and a guarded seed insert
//  - an advisory lock makes tasks that start together take turns
// Usage: php init-schema.php /opt/app/schema.sql

$file = $argv[1] ?? '/opt/app/schema.sql';

$host = getenv('DB_HOST') ?: 'localhost';
$port = getenv('DB_PORT') ?: '3306';
$user = getenv('DB_USER') ?: 'root';
$pass = getenv('DB_PASS') ?: '';

// No dbname here: schema.sql creates/selects the database itself.
$pdo = new PDO("mysql:host=$host;port=$port;charset=utf8mb4", $user, $pass, [
    PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
]);

$sql = file_get_contents($file);
if ($sql === false) {
    fwrite(STDERR, "Cannot read $file\n");
    exit(1);
}

// Drop "-- ..." comment lines, then run one statement at a time so a failure
// in any statement is raised instead of silently skipped.
$sql = preg_replace('/^\s*--.*$/m', '', $sql);
$statements = array_filter(array_map('trim', explode(';', $sql)), 'strlen');

$got = $pdo->query("SELECT GET_LOCK('crud_schema_init', 60)")->fetchColumn();
if ((int)$got !== 1) {
    fwrite(STDERR, "Could not get the schema lock in 60s\n");
    exit(1);
}

try {
    foreach ($statements as $statement) {
        $pdo->exec($statement);
    }
    echo "Schema applied (" . count($statements) . " statements)\n";
} finally {
    $pdo->query("SELECT RELEASE_LOCK('crud_schema_init')");
}
