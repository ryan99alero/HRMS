<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
ini_set('log_errors', 1);
ini_set('error_log', '/path/to/error_log.txt'); // Update with your actual server path

	session_start();
	include 'includes/conn.php';

	if(!isset($_SESSION['admin']) || trim($_SESSION['admin']) == ''){
        // header('location: index.php');
        echo $_SESSION['admin'];
    }

	$sql = "SELECT * FROM user WHERE RecId = '".$_SESSION['admin']."'";
	$query = $conn->query($sql);
	$user = $query->fetch_assoc();

?>
