<?php
/*session_start();
include 'includes/conn.php';

if (isset($_POST['login'])) {
    $username = $_POST['username'];
    $password = $_POST['password'];

    //$sql = "SELECT * FROM user WHERE username = '$username'";
    //$sql = "call 'StrProc_getUserLoginInfo'('".$_POST["username"]."','".$_POST["password"]."')";
    $query = $conn->query($sql);

    if ($query->num_rows < 1) {
        $_SESSION['error'] = 'Cannot find account with the username';
    } else {
        $row = $query->fetch_assoc();
        if (($password == $row["password"])) {
            $_SESSION['admin'] = $row['id'];
        } else {
            header('location: home.php');
            $_SESSION['error'] = 'Incorrect password';
        }
    }

} else {
    $_SESSION['error'] = 'Input user credentials first';
}

header('location: index.php');*/

ini_set('display_errors', 1);
error_reporting(E_ALL);
session_start();
include 'includes/conn.php';

if(isset($_POST['login'])){
    $username = $_POST['username'];
    $password = $_POST['password'];

    // Using prepared statements to call stored procedure
    $sql = "CALL StrProc_getUserLoginInfo(?, ?)";
    $stmt = $conn->prepare($sql);

    if ($stmt) {
        // Bind parameters and execute
        $stmt->bind_param("ss", $username, $password);
        $stmt->execute();

        // Get the result
        $result = $stmt->get_result();

        if ($result->num_rows < 1) {
            $_SESSION['error'] = 'Cannot find account with the username';
        } else {
            $row = $result->fetch_assoc();
            if (password_verify($password, $row['password'])) {
                $_SESSION['admin'] = $row['id'];
            } else {
                $_SESSION['error'] = 'Incorrect password';
            }
        }

        // Close the statement
        $stmt->close();
    } else {
        // Handle error
        echo "Error in preparing statement: " . $conn->error;
    }

    // Close the database connection
    $conn->close();
} else {
    $_SESSION['error'] = 'Input admin credentials first';
}

header('location: index.php');

?>
