//https://www.sourcecodester.com/php-project
//https://www.codecademy.com/learn
//https://www.geeksforgeeks.org/web-development-projects/
//https://stackoverflow.com/
//https://bootstrap.com/docs/5.3/getting-started/introduction/

<?php
session_start();
include 'includes/conn.php';

if(isset($_POST['login'])){
    $username = $_POST['username'];
    $password = $_POST['password'];

    $sql = "SELECT * FROM admin WHERE username = '$username'";
    $query = $conn->query($sql);

    if($query->num_rows < 1){
        $_SESSION['error'] = 'Cannot find account with the username';
    }
    else{
        $row = $query->fetch_assoc();
        if(password_verify($password, $row['password'])){
            $_SESSION['admin'] = $row['id'];
        }
        else{
            $_SESSION['error'] = 'Incorrect password';
        }
    }

}
else{
    $_SESSION['error'] = 'Input admin credentials first';
}

header('location: index.php');

?>