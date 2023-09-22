<?php
// Database connection
$servername = "localhost"; // Database server name
$username = "root"; // Database username
$password = ""; // Database password
$dbname = "hrms"; // Database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

// SQL query to retrieve PayableAmount
// $sql = "SELECT PayableAmount FROM your_table WHERE some_condition";
$sql = "call`SP_Advance_PayableAmount`(0)";

$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // Fetch the result
    $row = $result->fetch_assoc();
    $payableAmount = $row["PayableAmount"];
} else {
    $payableAmount = "No data found"; // If no data is found in the database
}

// Close the database connection
$conn->close();

// Send the PayableAmount value as a response to the JavaScript code
echo $payableAmount;
?>