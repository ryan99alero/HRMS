<?php
ini_set('display_errors', 1);
error_reporting(E_ALL);
session_start();
include 'includes/conn.php';

if(isset($_POST['login'])){
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Use prepared statements to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM user WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if($result->num_rows < 1){
        $_SESSION['error'] = 'Cannot find account with the username';
    }
    else{
        $row = $result->fetch_assoc();
        if(password_verify($password, $row["password"])){
            $_SESSION['admin'] = $row['RecId'];
        }
        else{
            $_SESSION['error'] = 'Incorrect password';
            header('location: home.php'); // Redirect should be done after setting the session variable
            exit(); // Always call exit after header redirection
        }
    }
    $stmt->close();
}
else{
    $_SESSION['error'] = 'Input user credentials first';
}

header('location: index.php');
exit(); // Always call exit after header redirection
?>
