<?php
	$conn = new mysqli('localhost', 'root', 'deepspace9', 'HRMS');

	if ($conn->connect_error) {
	    die("Connection failed: " . $conn->connect_error);
	}
	
?>