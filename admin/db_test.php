<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);

$servername = "localhost";
$username = "phpmyadmin";
$password = "KnzudGNfJoiQgKv3nUNY37";
$dbname = "attendance";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);$conn = new mysqli('localhost', 'phpmyadmin', 'KnzudGNfJoiQgKv3nUNY37', 'HRMS');

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";
?>