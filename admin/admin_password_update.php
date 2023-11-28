<?php
// Database credentials
$host = 'localhost';
$dbUsername = 'root';
$dbPassword = 'deepspace9';
$dbName = 'HRMS';

// Create connection
$conn = new mysqli($host, $dbUsername, $dbPassword, $dbName);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// New password to be set
$newPassword = 'TacoFarm';
// Hash the new password
$hashedPassword = password_hash($newPassword, PASSWORD_DEFAULT);

// SQL to update the password
$sql = "UPDATE user SET password = ? WHERE username = 'admin'";

// Prepare statement
$stmt = $conn->prepare($sql);
if (!$stmt) {
    die("Error in statement preparation: " . $conn->error);
}

// Bind the parameter
$stmt->bind_param("s", $hashedPassword);

// Execute the statement
if ($stmt->execute()) {
    echo "Password updated successfully.";
} else {
    echo "Error updating record: " . $stmt->error;
}

// Close statement and connection
$stmt->close();
$conn->close();
?>