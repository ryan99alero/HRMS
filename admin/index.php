<?php
session_start();
if (isset($_SESSION['admin'])) {
    header('location:home.php');
}
?>
<?php include 'includes/header.php'; ?>
<body class="hold-transition login-page">
<div class="login-box">
    <div class="login-logo">
        <p>Admin</p>
    </div>
    <div class="login-box-body">
        <p class="login-box-msg">Sign in to start your session</p>

        <form action="login.php" method="POST">
            <div class="form-group has-feedback">
                <label>
                    <input type="text" class="form-control" name="username" placeholder="input Username" required autofocus>
                </label>
                <span class="glyphicon glyphicon-user form-control-feedback"></span>
            </div>
            <div class="form-group has-feedback">
                <label>
                    <input type="password" class="form-control" name="password" placeholder="input Password" required>
                </label>
                <span class="glyphicon glyphicon-lock form-control-feedback"></span>
            </div>
            <div class="row">
                <div class="col-xs-4">
                    <button type="submit" class="btn btn-primary btn-block btn-flat" name="login"><i
                                class="fa fa-sign-in"></i> Sign In
                    </button>
                </div>
                <div class="col-xs-2">
                    <!-- <button type="submit" class="btn btn-primary btn-block btn-flat" name="login"><i class="fa fa-sign-in"></i> Sign In</button> -->
                </div>
                <div class="col-xs-6">
                    <a href="../hr/index.php">
                        <btn class="btn btn-success btn-block btn-flat"><i class="fa fa-sign-in"></i> Sign In to HR
                        </btn>
                    </a>
                </div>
            </div>
        </form>
    </div>
    <?php
    if (isset($_SESSION['error'])) {
        echo "
  				<div class='callout callout-danger text-center mt20'>
			  		<p>" . $_SESSION['error'] . "</p> 
			  	</div>
  			";
        unset($_SESSION['error']);
    }
    ?>
</div>

<?php include 'includes/scripts.php' ?>
</body>
</html>