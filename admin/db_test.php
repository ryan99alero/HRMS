<?php
$servername = "localhost";
$username = "phpmyadmin";
$password = "KnzudGNfJoiQgKv3nUNY37";
$dbname = "HRMS";

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);$conn = new mysqli('localhost', 'phpmyadmin', 'KnzudGNfJoiQgKv3nUNY37', 'HRMS');

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
echo "Connected successfully";
?>