<?php
session_start();
include 'includes/conn.php';

// Check if the 'admin' session variable is set and not empty
if (!isset($_SESSION['admin']) || trim($_SESSION['admin']) == '') {
    header('Location: index.php'); // Replace 'index.php' with your login page
    exit();
}

$sql = "SELECT * FROM user WHERE RecId = '" . $_SESSION['admin'] . "'";
$query = $conn->query($sql);
$user = $query->fetch_assoc();

// Rest of your code...
?>
