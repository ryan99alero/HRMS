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
            <!-- Your existing PHP code for alerts -->

            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                            <!-- Your existing buttons for New and Import -->
                        </div>
                        <div class="box-body">
                            <table id="Employee" class="table table-bordered table-hover">
                                <thead>
                                <tr>
                                    <th>Employee ID</th>
                                    <th>Photo</th>
                                    <th>Name</th>
                                    <th>Position</th>
                                    <th>Schedule</th>
                                    <th>Member Since</th>
                                    <th>Tools</th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php
                                $sql = "call `StrProc_SelectUserProfileInfo`(0)";
                                $query = $conn->query($sql);
                                while ($row = $query->fetch_assoc()) {
                                    ?>
                                    <tr>

                                        <td><?php echo $row['RecId']; ?></td>
                                        <td><?php echo $row['Employee_Id']; ?></td>
                                        <td><?php echo $row['PersonName']; ?></td>
                                        <td><?php echo $row['CNIC']; ?></td>
                                        <td><?php echo $row['Gmail']; ?></td>
                                        <td><?php echo $row['designation_name']; ?></td>
                                        <td><?php echo $row['pay_name']; ?></td>
                                        <td><?php echo $row['shift_name']; ?></td>
                                        <td><?php echo $row['Gender']; ?></td>
                                        <td><?php echo $row['address']; ?></td>
                                        <td><?php echo $row['contact']; ?></td>
                                        <td><?php echo $row['salary']; ?></td>
                                        <td><?php echo $row['Advance']; ?></td>
                                        <td><?php echo $row['workingDays']; ?></td>
                                        <td>
                                            <?php
                                            if ($row['isactive'] != 0) {
                                                echo "<span class='badge badge-success' style='background-color:green'>Active</span>";
                                            } else {
                                                echo "<span class='badge badge-danger' style='background-color:Red'>Deactive</span>";
                                            };
                                            ?>
                                        </td>
                                        <td>
                                            <a class=" edit " style='border-radius:8px;color:white;cursor: pointer;'
                                               data-id="<?php echo $row['RecId']; ?>">
                                                <button style="border-radius:8px;border:none;background-color:#4680ff;">
                                                    <i class="fa fa-edit"></i></button>
                                            </a>

                                            <a class=" advance " style='border-radius:8px;color:white;cursor: pointer;'
                                               data-id="<?php echo $row['RecId']; ?>">
                                                <button style="border-radius:8px;border:none;background-color:orange;">
                                                    <i class="fa fa-money"></i></button>
                                            </a>

                                            <a class=" payroll " style='border-radius:8px;color:white;cursor: pointer;'
                                               data-id="<?php echo $row['RecId']; ?>">
                                                <button style="border-radius:8px;border:none;background-color:#dd4b39;">
                                                    <i class="fa fa-vcard"></i></button>
                                            </a>
                                        </td>
                                    </tr>
                                    <?php
                                }
                                // $query->free();
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
    <?php include 'includes/employee_modal.php'; ?>
</div>

<?php include 'includes/scripts.php'; ?>

<!-- DataTables Initialization and Scripts for Edit, Delete, Photo -->

<script>
    $(document).ready(function() {
        // Initialize DataTables for the Employee table
        $('#Employee').DataTable({
            "responsive": true,
            "autoWidth": false
            // Add other DataTables options here as needed
        });

        // Script for handling the edit button click
        $('.edit').click(function(e){
            e.preventDefault();
            $('#edit').modal('show');
            var id = $(this).data('id');
            getRow(id);
        });

        // Script for handling the delete button click
        $('.delete').click(function(e){
            e.preventDefault();
            $('#delete').modal('show');
            var id = $(this).data('id');
            getRow(id);
        });

        // Script for handling the photo click
        $('.photo').click(function(e){
            e.preventDefault();
            var id = $(this).data('id');
            getRow(id);
        });

        // Function to fetch row data
        function getRow(id){
            $.ajax({
                type: 'POST',
                url: 'employee_row.php',
                data: {id:id},
                dataType: 'json',
                success: function(response){
                    $('.empid').val(response.empid);
                    $('.employee_id').html(response.employee_id);
                    $('.del_employee_name').html(response.firstname+' '+response.lastname);
                    $('#employee_name').html(response.firstname+' '+response.lastname);
                    $('#edit_firstname').val(response.firstname);
                    $('#edit_lastname').val(response.lastname);
                    $('#edit_address').val(response.address);
                    $('#datepicker_edit').val(response.birthdate);
                    $('#edit_contact').val(response.contact_info);
                    $('#position_val').val(response.position_id).html(response.description);
                    $('#schedule_val').val(response.schedule_id).html(response.time_in+' - '+response.time_out);
                }
            });
        }
    });
</script>

</body>
</html>
