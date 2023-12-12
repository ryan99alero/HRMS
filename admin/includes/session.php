<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', '/path/to/error_log.txt'); // Update with your actual server path

session_start();
include 'includes/conn.php';

if (!isset($_SESSION['admin']) || trim($_SESSION['admin']) == '') {
    header('location: index.php');
    exit;
}

// Debugging statement
echo 'Admin session value: ' . $_SESSION['admin'] . '<br>';

$sql = "SELECT * FROM user WHERE id = ?";
$stmt = $conn->prepare($sql);

if ($stmt) {
    $stmt->bind_param("s", $_SESSION['admin']);
    $stmt->execute();
    $result = $stmt->get_result();
    if ($result) {
        $user = $result->fetch_assoc();
        // Debugging statement
        echo '<pre>'; var_dump($user); echo '</pre>';
    } else {
        echo "Error in result fetching: " . $conn->error;
    }
    $stmt->close();
} else {
    die("Error in query preparation: " . $conn->error);
}
?>
