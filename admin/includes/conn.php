<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

// Retrieve environment variables
$dbHost = getenv('DB_HOST') ?: 'localhost'; // Default to 'localhost' if not set
$dbName = getenv('DB_NAME') ?: 'hrms';      // Default to 'hrms' if not set
$dbUser = getenv('DB_USER') ?: 'root';      // Default to 'root' if not set
$dbPass = getenv('DB_PASS') ?: '';          // Default to an empty string if not set

// Create a new connection
$conn = new mysqli($dbHost, $dbUser, $dbPass, $dbName);

// Check the connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
?>
