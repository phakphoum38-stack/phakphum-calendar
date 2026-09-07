<?php
declare(strict_types=1);

$dbHost = getenv('DB_HOST') ?: 'db';
$dbName = getenv('DB_NAME') ?: 'phakphum';
$dbUser = getenv('DB_USER') ?: 'root';
$dbPass = getenv('DB_PASSWORD') ?: 'example';

function jsonResponse($data, $status = 200) {
    header('Content-Type: application/json');
    http_response_code($status);
    echo json_encode($data);
    exit;
}

$uri = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);
// If Apache serves the script as /index.php/..., strip the script name prefix
if (strpos($uri, '/index.php') === 0) {
    $uri = substr($uri, strlen('/index.php')) ?: '/';
}
$method = $_SERVER['REQUEST_METHOD'];

if ($uri === '/' && $method === 'GET') {
    jsonResponse(['message' => 'Phakphum Calendar Demo API']);
}

if ($uri === '/health' && $method === 'GET') {
    jsonResponse(['status' => 'ok']);
}

if ($uri === '/swap' && $method === 'POST') {
    $input = json_decode(file_get_contents('php://input'), true);
    if (!is_array($input)) {
        jsonResponse(['error' => 'invalid json'], 400);
    }

    $origin = $input['origin'] ?? null;
    $swap = $input['swap'] ?? null;
    $receiver = $input['receiver'] ?? null;

    try {
        $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass);
        $stmt = $pdo->prepare('INSERT INTO swap_requests (origin_name, swap_name, receiver_name, payload_json, status, created_at) VALUES (?, ?, ?, ?, ?, NOW())');
        $payload = json_encode($input);
        $stmt->execute([$origin, $swap, $receiver, $payload, 'pending']);
        $id = $pdo->lastInsertId();
        jsonResponse(['id' => $id, 'status' => 'created'], 201);
    } catch (PDOException $e) {
        jsonResponse(['error' => 'db_error', 'message' => $e->getMessage()], 500);
    }
}

// Basic listing for demo
if ($uri === '/swap' && $method === 'GET') {
    try {
        $pdo = new PDO("mysql:host=$dbHost;dbname=$dbName;charset=utf8mb4", $dbUser, $dbPass);
        $stmt = $pdo->query('SELECT id, origin_name, swap_name, receiver_name, status, created_at FROM swap_requests ORDER BY id DESC LIMIT 100');
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC);
        jsonResponse(['data' => $rows]);
    } catch (PDOException $e) {
        jsonResponse(['error' => 'db_error', 'message' => $e->getMessage()], 500);
    }
}

// Fallback
http_response_code(404);
echo 'Not found';
