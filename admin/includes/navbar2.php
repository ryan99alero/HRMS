<header class="main-header">
    <!-- Logo -->
    <a href="index2.html" class="logo">
        <!-- mini logo for sidebar mini 50x50 pixels -->
        <span class="logo-mini"><b>T</b>IT</span>
        <!-- logo for regular state and mobile devices -->
        <span class="logo-lg"><b>RAND</b> Graphics</span>
    </a>
    <!-- Header Navbar: style can be found in header.less -->
    <nav class="navbar navbar-static-top">
        <!-- Sidebar toggle button-->
        <a href="#" class="sidebar-toggle" data-toggle="push-menu" role="button">
            <span class="sr-only">Toggle navigation</span>
        </a>

        <div class="navbar-custom-menu">
            <ul class="nav navbar-nav">
                <!-- User Account: style can be found in dropdown.less -->
                <li class="dropdown user user-menu">
                    <a href="#" class="dropdown-toggle" data-toggle="dropdown">
                        <img src="<?php echo (!empty($user['photo'])) ? '../images/'.$user['photo'] : '../images/profile.jpg'; ?>" class="user-image" alt="User Image">
                        <span class="hidden-xs"><?php echo $user['firstname'].' '.$user['lastname']; ?></span>
                    </a>
                    <ul class="dropdown-menu">
                        <!-- User image -->
                        <li class="user-header">
                            <img src="<?php echo (!empty($user['photo'])) ? '../images/'.$user['photo'] : '../images/profile.jpg'; ?>" class="img-circle" alt="User Image">
                            <p>
                                <?php echo $user['firstname'].' '.$user['lastname']; ?>
                                <small>Member since <?php echo date('M. Y', strtotime($user['created_on'])); ?></small>
                            </p>
                        </li>
                        <!-- Menu Footer user-footer-->
                        <li class="user-profile">
                            <table>
                                <tr>
                                    <td>
                                        <div>
                                            <a href="#profile" data-toggle="modal" class="btn btn-default-profile btn-flat-profile">Update</a>
                                        </div>
                                    </td>
                                    <td>
                                        <div>
                                            <a href="#passwordModal" data-toggle="modal" class="btn btn-default-profile btn-flat-profile">Change Password</a>
                                        </div>
                                    </td>
                                    <td>
                                        <div>
                                            <a href="logout.php" class="btn btn-default-profile btn-flat-profile">Sign out</a>
                                        </div>
                                    </td>
                                </tr>
                            </table>
                        </li>
                    </ul>
                </li>
            </ul>
        </div>
    </nav>
</header>
<?php include 'includes/profile_modal.php'; ?>
<?php include 'includes/profile_password_modal.php'; ?>
