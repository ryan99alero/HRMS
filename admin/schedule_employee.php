<?php include 'includes/session.php'; ?>
<?php include 'includes/header.php'; ?>
<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">

    <?php include 'includes/navbar.php'; ?>
    <?php include 'includes/menubar.php'; ?>

    <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <section class="content-header">
            <h1>
                Schedules
            </h1>
            <ol class="breadcrumb">
                <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
                <li>Employees</li>
                <li class="active">Schedules</li>
            </ol>
        </section>
        <!-- Main content -->
        <section class="content">
            <?php
            if (isset($_SESSION['error'])) {
                echo "
            <div class='alert alert-danger alert-dismissible'>
              <button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button>
              <h4><i class='icon fa fa-warning'></i> Error!</h4>
              " . $_SESSION['error'] . "
            </div>
          ";
                unset($_SESSION['error']);
            }
            if (isset($_SESSION['success'])) {
                echo "
            <div class='alert alert-success alert-dismissible'>
              <button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button>
              <h4><i class='icon fa fa-check'></i> Success!</h4>
              " . $_SESSION['success'] . "
            </div>
          ";
                unset($_SESSION['success']);
            }
            ?>
            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                            <a href="schedule_print.php" class="btn btn-success btn-sm btn-flat"
                               style='border-radius:8px;'><span class="glyphicon glyphicon-print"></span> Print</a>
                        </div>
                        <div class="box-body">
                            <table id="example1" class="table table-bordered">
                                <thead>
                                <tr>
                                    <th>Shift Name</th>
                                    <th>Time In</th>
                                    <th>Time Out</th>
                                    <th>Grace Time</th>
                                    <th>Action</th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php
                                //  $sql = "SELECT * FROM  shift"
                                $sql = "Call `StrProc_SelectShiftInfo`(0)";
                                $query = $conn->query($sql);
                                while ($row = $query->fetch_assoc()) {
                                    echo "
                         <tr>
                           <td>" . $row['shift_name'] . "</td>
                           <td>" . $row['time_in'] . "</td>
                           <td>" . $row['time_out'] . "</td>
                           <td>" . $row['grace_time'] . "</td>
                           <td>
                             <button class='btn btn-success btn-sm edit btn-flat' style='border-radius:8px;' data-id='" . $row['id'] . "'><i class='fa fa-edit'></i> Edit</button>
                             <button class='btn btn-danger btn-sm delete btn-flat' style='border-radius:8px;' data-id='" . $row['id'] . "'><i class='fa fa-trash'></i> Delete</button>
                           </td>
                         </tr>
                       ";
                                }
                                ?>
                                </tbody>
                            </table>
                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>

    <?php include 'includes/footer.php'; ?>
    <?php include 'includes/employee_schedule_modal.php'; ?>
</div>
<?php include 'includes/scripts.php'; ?>
<script>
    $(function () {
        $('.edit').click(function (e) {
            e.preventDefault();
            $('#edit').modal('show');
            var id = $(this).data('id');
            getRow(id);
        });
    });

    function getRow(id) {
        $.ajax({
            type: 'POST',
            url: 'schedule_employee_row.php',
            data: {id: id},
            dataType: 'json',
            success: function (response) {
                $('.employee_name').html(response.firstname + ' ' + response.lastname);
                $('#schedule_val').val(response.schedule_id);
                $('#schedule_val').html(response.time_in + ' ' + response.time_out);
                $('#empid').val(response.empid);
            }
        });
    }
</script>
</body>
</html>
