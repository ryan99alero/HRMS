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

$EmpID = isset($_POST['id']) ? $_POST['id'] : 0;

// Call the stored procedure
$sql = "CALL `StrProc_SelectAdvanceInfo`($EmpID)";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
  
    while ($row = $result->fetch_assoc()) 
    {
        $firstName = json_decode($row['firstname']);
        $amount = json_decode($row['Amount']);
        $amountDate = json_decode($row['AmountDate']);
    }

} else {
    $firstName = json_encode("No data found");
    $amount = json_encode("No data found");
    $amountDate = json_encode("No data found");
}

// Close the database connection
$conn->close();

echo $firstName;
echo $amount;
echo $amountDate;
// Send the data as a response to the JavaScript code
?>
<?php
// Database connection
// $servername = "localhost"; // Database server name
// $username = "root"; // Database username
// $password = ""; // Database password
// $dbname = "hrms"; // Database name

// // Create connection
// $conn = new mysqli($servername, $username, $password, $dbname);

// // Check connection
// if ($conn->connect_error) {
//     die("Connection failed: " . $conn->connect_error);
// }

// $EmpID = isset($_POST['id']) ? $_POST['id'] : 0;

// // Call the stored procedure
// $sql = "CALL StrProc_SelectAdvanceInfo($EmpID)";
// $result = $conn->query($sql);

// $data = array();

// if ($result->num_rows > 0) {
//     while ($row = $result->fetch_assoc()) {
//         $data[] = array(
//             'RecId' => $row['RecId'],
//             'FirstName' => $row['firstname'],
//             'Amount' => $row['Amount'],
//             'AmountDate' => $row['AmountDate']
//         );
//     }
// }

// // Close the database connection
// $conn->close();

// // Send the data as a JSON response
// echo json_encode($data);
?>
