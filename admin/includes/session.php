<?php
/*session_start();
include 'includes/conn.php';

// Check if the 'admin' session variable is set and not empty
if (!isset($_SESSION['admin']) || trim($_SESSION['admin']) == '') {
    header('Location: index.php'); // Replace 'index.php' with your login page
    exit();
}

$sql = "SELECT * FROM user WHERE id = '" . $_SESSION['admin'] . "'";
$query = $conn->query($sql);
$user = $query->fetch_assoc();

// Rest of your code...
*/

session_start();
include 'includes/conn.php';

if(!isset($_SESSION['admin']) || trim($_SESSION['admin']) == ''){
    header('location: index.php');
    exit; // Always call exit after header redirection
}

// Use prepared statement for security
$sql = "SELECT * FROM user WHERE id = ?";
$stmt = $conn->prepare($sql);

if($stmt){
    // Bind the parameter and execute
    $stmt->bind_param("s", $_SESSION['admin']);
    $stmt->execute();
    $result = $stmt->get_result();
    $user = $result->fetch_assoc();

    $stmt->close();
} else {
    // Error handling
    die("Database error: " . $conn->error);
}

?>
