<?php
	// $conn = new mysqli('localhost', 'root', '', 'appattendance5');
	$conn = new mysqli('localhost', 'root', 'deepspace9', 'hrms');

	if ($conn->connect_error) {
	    die("Connection failed: " . $conn->connect_error);
	}
	
?>