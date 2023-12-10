<?php include 'includes/session.php'; ?>
<?php include 'includes/header.php'; ?>

<!-- DataTables CSS -->
<link rel="stylesheet" href="https://cdn.datatables.net/1.10.20/css/jquery.dataTables.min.css">
<!-- DataTables JavaScript -->
<script src="https://cdn.datatables.net/1.10.20/js/jquery.dataTables.min.js"></script>

<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">

    <?php include 'includes/navbar.php'; ?>
    <?php include 'includes/menubar.php'; ?>

    <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <section class="content-header">
            <h1>
                Employee List
            </h1>
            <ol class="breadcrumb">
                <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
                <li>Employees</li>
                <li class="active">Employee List</li>
            </ol>
        </section>

        <!-- Main content -->
        <section class="content">
            <!-- Your existing PHP and HTML content here -->

            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                            <!-- Your existing buttons and other elements here -->
                        </div>
                        <div class="box-body">
                            <table id="Employee" class="table table-bordered">
                                <!-- Your existing table structure here -->
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>

    <?php include 'includes/footer.php'; ?>
    <?php include 'includes/employee_modal.php'; ?>
</div>

<!-- Your existing script for handling buttons and modals -->
<script>
    $(function(){
        // Your existing JavaScript code

        // Initialize DataTables for the Employee table
        $('#Employee').DataTable();
    });
</script>

<?php include 'includes/scripts.php'; ?>
</body>
</html>
