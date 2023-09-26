
<?php
// advance_add.php

// Check if the form was submitted
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Connect to your database (replace these variables with your actual database credentials)
    $servername = "localhost";
    $username = "root";
    $password = "";
    $dbname = "hrms";

    $conn = new mysqli($servername, $username, $password, $dbname);

    // Check connection
    if ($conn->connect_error) {
        die("Connection failed: " . $conn->connect_error);
    }

    // Get data from the form
    $UpId = $_POST["UpId"];
    $Amount = $_POST["Amount"];
    $AmoutDate = $_POST["AmoutDate"];

    // Create an SQL insert query
    // $sql = "INSERT INTO your_table_name (UpId, Amount, AmoutDate) VALUES ('$UpId', '$Amount', '$AmoutDate')";
     
	$sql = "call`StrProc_InsertAdvanceInfo`('$UpId','$Amount','$AmoutDate')";

    if ($conn->query($sql) === TRUE) {
        echo "Record inserted successfully";
    } else {
        echo "Error: " . $sql . "<br>" . $conn->error;
    }

    $conn->close();
} else {
    echo "Form was not submitted";
}
header('location: employee.php');
?>
