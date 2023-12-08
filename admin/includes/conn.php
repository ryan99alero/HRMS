<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
$dbConfig = [
    'host' => getenv('DB_HOST'),
    'name' => getenv('DB_NAME'),
    'user' => getenv('DB_USER'),
    'password' => getenv('DB_PASS')
];
	// $conn = new mysqli('localhost', 'root', '', 'appattendance5');
	$conn = new mysqli('localhost', 'phpmyadmin', 'KnzudGNfJoiQgKv3nUNY37', 'attendance');

	if ($conn->connect_error) {
	    die("Connection failed: " . $conn->connect_error);
	}
	
?>