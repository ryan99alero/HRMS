<?php
$dbConfig = [
    'host' => getenv('DB_HOST'),
    'name' => getenv('DB_NAME'),
    'user' => getenv('DB_USER'),
    'password' => getenv('DB_PASS')
];
	// $conn = new mysqli('localhost', 'root', '', 'appattendance5');
	$conn = new mysqli('localhost', 'phpmyadmin', 'KnzudGNfJoiQgKv3nUNY37', 'HRMS');

	if ($conn->connect_error) {
	    die("Connection failed: " . $conn->connect_error);
	}
	
?>