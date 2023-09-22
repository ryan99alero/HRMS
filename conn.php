<?php
	// $conn = new mysqli('localhost', 'root', '', 'appattendance4');
	$conn = new mysqli('localhost', 'root', '', 'hrms4');

	if ($conn->connect_error) {
	    die("Connection failed: " . $conn->connect_error);
	}
	
?>