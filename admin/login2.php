<?php
session_start();
include 'includes/conn.php';

if (isset($_POST['login'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Use prepared statement to prevent SQL injection
    $stmt = $conn->prepare("SELECT * FROM user WHERE username = ?");
    $stmt->bind_param("s", $username);
    $stmt->execute();
    $result = $stmt->get_result();

    if ($result->num_rows < 1) {
        $_SESSION['error'] = 'Cannot find account with the username';
        header('location: index.php');
        exit();
    } else {
        $row = $result->fetch_assoc();
        // Use password_verify to check the hashed password
        if (password_verify($password, $row["password"])) {
            $_SESSION['admin'] = $row['RecId']; // Set session variable
            header('location: home.php'); // Redirect to home page
            exit();
        } else {
            $_SESSION['error'] = 'Incorrect password';
            header('location: index.php');
            exit();
        }
    }
} else {
    $_SESSION['error'] = 'Input user credentials first';
    header('location: index.php');
    exit();
}
?>
