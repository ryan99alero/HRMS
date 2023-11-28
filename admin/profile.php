<?php
include 'includes/session.php';

// Assuming $conn is your database connection and $user['id'] is the ID of the logged-in user
$sql = "SELECT * FROM admin WHERE id = '".$user['id']."'";
$query = $conn->query($sql);
if($query->num_rows > 0){
    $row = $query->fetch_assoc();
} else {
    // Handle the case where the user is not found
    $_SESSION['error'] = 'User not found.';
    header('location: home.php'); // Redirect to a default page
    exit();
}
?>

<!DOCTYPE html>
<html>
<head>
    <title>User Profile</title>
    <!-- Add other head elements like CSS files -->
</head>
<body>

<form action="profile_update.php" method="POST" enctype="multipart/form-data">
    <!-- Display any success or error messages -->
    <?php
    if(isset($_SESSION['error'])){
        echo "<p>".$_SESSION['error']."</p>";
        unset($_SESSION['error']);
    }

    if(isset($_SESSION['success'])){
        echo "<p>".$_SESSION['success']."</p>";
        unset($_SESSION['success']);
    }
    ?>

    <label for="username">Username:</label>
    <input type="text" name="username" value="<?php echo $row['username']; ?>">

    <label for="curr_password">Current Password:</label>
    <input type="password" name="curr_password" required>

    <label for="password">New Password:</label>
    <input type="password" name="password">

    <label for="firstname">First Name:</label>
    <input type="text" name="firstname" value="<?php echo $row['firstname']; ?>">

    <label for="lastname">Last Name:</label>
    <input type="text" name="lastname" value="<?php echo $row['lastname']; ?>">

    <label for="photo">Photo:</label>
    <input type="file" name="photo">
    <?php if($row['photo']): ?>
        <img src="../images/<?php echo $row['photo']; ?>" width="100px" height="100px">
    <?php endif; ?>

    <input type="submit" name="save" value="Save Changes">
</form>

</body>
</html>
