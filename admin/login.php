<?php
global $conn;
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
        header('location: index.php'); // Redirect to login page
        exit();
    }
    else{
        $row = $result->fetch_assoc();
        if(password_verify($password, $row["password"])){
            $_SESSION['admin'] = $row['id'];
            $_SESSION['success'] = 'Login successful'; // Set a success message
            header('location: home.php'); // Redirect to home page
            exit();
        }
        else{
            $_SESSION['error'] = 'Incorrect password';
            header('location: index.php'); // Redirect to login page
            exit();
        }
    }
    $stmt->close();
}
else{
    $_SESSION['error'] = 'Input user credentials first';
    header('location: index.php');
    exit();
}
?>
