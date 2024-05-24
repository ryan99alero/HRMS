<?php
global $conn;
include 'includes/session.php';
include 'includes/header.php';
include "conn.php";
include 'includes/navbar.php';
include 'includes/menubar.php';

// Handling POST requests
if ($_SERVER['REQUEST_METHOD'] == 'POST') {
    if (isset($_POST['add'])) {
        addEmployee($conn);
    } elseif (isset($_POST['edit'])) {
        editEmployee($conn);
    } elseif (isset($_POST['delete'])) {
        deleteEmployee($conn);
    } elseif (isset($_POST['upload'])) {
        uploadEmployeePhoto($conn);
    }
}

// Function to add an employee
function addEmployee($conn) {
    $Employee_Id = trim($_POST['EmpID']);
    $firstname = trim($_POST['Fname']);
    $lastname = trim($_POST['Lname']);
    $gender = trim($_POST['Sex']);
    $CNIC = trim($_POST['CNIC']);
    $Gmail = trim($_POST['Gmail']);
    $contact = trim($_POST['Phone']);
    $address = trim($_POST['Home']);
    $Designation_Id = trim($_POST['DesID']);
    $payscale_id = trim($_POST['PayId']);
    $shift_id = trim($_POST['ShiftID']);
    $workingDays = trim($_POST['workingDays']);
    $salary = trim($_POST['Salary']);

    if (empty($Employee_Id) || empty($firstname) || empty($gender)) {
        $_SESSION['error'] = 'Fill up the add form first';
    } else {
        $sql = "call `SP_InsertUserProfileInfo`('$Employee_Id', '$firstname', '$lastname', '$gender', '$CNIC', '$Gmail', '$contact', '$address', '$Designation_Id', '$payscale_id', '$shift_id', '$workingDays', '$salary')";
        if ($conn->query($sql)) {
            $_SESSION['success'] = "Employee Added Successfully";
        } else {
            $_SESSION['error'] = $conn->error;
        }
    }
    header('location: users.php');
}

// Function to edit an employee
function editEmployee($conn) {
    $id = $_POST['UpId'];
    $Employee_Id = $_POST['EmpID'];
    $firstname = $_POST['Fname'];
    $lastname = $_POST['Lname'];
    $CNIC = $_POST['CNIC'];
    $Gmail = $_POST['gmail'];
    $Designation_Id = $_POST['DesID'];
    $payscale_id = $_POST['PayId'];
    $shift_id = $_POST['ShiftID'];
    $gender = $_POST['Sex'];
    $address = $_POST['Home'];
    $contact = $_POST['Phone'];
    $salary = $_POST['Salary'];
    $workingDays = $_POST['workingDays'];

    $sql = "call `StrProc_ChangeUserProfileInfo`('$id', '$Designation_Id', '$Employee_Id', '$firstname', '$lastname', '$CNIC', '$Gmail', '$address', '$contact', '$gender', '$shift_id', '$payscale_id', '$salary', '$workingDays')";
    if ($conn->query($sql)) {
        $_SESSION['success'] = "Data Updated Successfully";
    } else {
        $_SESSION['error'] = $conn->error;
    }
    header('location: users.php');
}

// Function to delete an employee
function deleteEmployee($conn) {
    $id = $_POST['id'];
    $sql = "DELETE FROM employees WHERE id = '$id'";
    if ($conn->query($sql)) {
        $_SESSION['success'] = 'Employee deleted successfully';
    } else {
        $_SESSION['error'] = $conn->error;
    }
    header('location: users.php');
}
?>
<?php
// Function to upload employee photo
function uploadEmployeePhoto($conn) {
    $empid = $_POST['id'];
    $filename = $_FILES['photo']['name'];
    if (!empty($filename)) {
        move_uploaded_file($_FILES['photo']['tmp_name'], '../images/' . $filename);
    }

    $sql = "UPDATE employees SET photo = '$filename' WHERE id = '$empid'";
    if ($conn->query($sql)) {
        $_SESSION['success'] = 'Employee photo updated successfully';
    } else {
        $_SESSION['error'] = $conn->error;
    }
    header('location: users.php');
}

// Fetch data for modals
function fetchData($conn, $table) {
    $sql = "SELECT * FROM `$table` WHERE isactive=1";
    return $conn->query($sql);
}

$genders = fetchData($conn, 'tbl_gender');
$designations = fetchData($conn, 'designation');
$payscale = fetchData($conn, 'pay_scale');
$shifts = fetchData($conn, 'shift');

?>

<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">
    <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <section class="content-header">
            <h1>Employee List</h1>
            <ol class="breadcrumb">
                <li><a href="home.php"><i class="fa fa-dashboard"></i> Home</a></li>
                <li class="active">Employee List</li>
            </ol>
        </section>

        <!-- Main content -->
        <section class="content">
            <?php
            if (isset($_SESSION['error'])) {
                echo "<div class='alert alert-danger alert-dismissible'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><h4><i class='icon fa fa-warning'></i> Error!</h4>{$_SESSION['error']}</div>";
                unset($_SESSION['error']);
            }
            if (isset($_SESSION['success'])) {
                echo "<div class='alert alert-success alert-dismissible'><button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button><h4><i class='icon fa fa-check'></i> Success!</h4>{$_SESSION['success']}</div>";
                unset($_SESSION['success']);
            }
            ?>
            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                            <a href="#addnew" data-toggle="modal" class="btn btn-primary btn-sm btn-flat" style='border-radius:8px;background-color:#4680ff;'><i class="fa fa-plus"></i> New</a>
                        </div>
                        <div class="box-body table-responsive">
                            <table style="width: 100%; table-layout: fixed;" class="dt table table-bordered">
                                <thead>
                                <tr>
                                    <th>User ID</th>
                                    <th>Employee ID</th>
                                    <th>Name</th>
                                    <th>CNIC No.</th>
                                    <th>Gmail</th>
                                    <th>Designation</th>
                                    <th>Pay</th>
                                    <th>Shift</th>
                                    <th>Gender</th>
                                    <th>Address</th>
                                    <th>Contact</th>
                                    <th>Salary</th>
                                    <th>Advance</th>
                                    <th>Working Days</th>
                                    <th>Status</th>
                                    <th style="width: 150px;text-align:center;">Action</th>
                                </tr>
                                </thead>
                                <tbody>
                                <?php
                                $sql = "call `StrProc_SelectUserProfileInfo`(0)";
                                $query = $conn->query($sql);
                                while ($row = $query->fetch_assoc()) {
                                    echo "<tr>
                                            <td>{$row['id']}</td>
                                            <td>{$row['Employee_Id']}</td>
                                            <td>{$row['PersonName']}</td>
                                            <td>{$row['CNIC']}</td>
                                            <td>{$row['Gmail']}</td>
                                            <td>{$row['designation_name']}</td>
                                            <td>{$row['pay_name']}</td>
                                            <td>{$row['shift_name']}</td>
                                            <td>{$row['Gender']}</td>
                                            <td>{$row['address']}</td>
                                            <td>{$row['contact']}</td>
                                            <td>{$row['salary']}</td>
                                            <td>{$row['Advance']}</td>
                                            <td>{$row['workingDays']}</td>
                                            <td>" . ($row['isactive'] ? "<span class='badge badge-success' style='background-color:green'>Active</span>" : "<span class='badge badge-danger' style='background-color:Red'>Deactive</span>") . "</td>
                                            <td>
                                                <a class='edit' style='border-radius:8px;color:white;cursor: pointer;' data-id='{$row['id']}'><button style='border-radius:8px;border:none;background-color:#4680ff;'><i class='fa fa-edit'></i></button></a>
                                                <a class='advance' style='border-radius:8px;color:white;cursor: pointer;' data-id='{$row['id']}'><button style='border-radius:8px;border:none;background-color:orange;'><i class='fa fa-money'></i></button></a>
                                                <a class='payroll' style='border-radius:8px;color:white;cursor: pointer;' data-id='{$row['id']}'><button style='border-radius:8px;border:none;background-color:#dd4b39;'><i class='fa fa-vcard'></i></button></a>
                                            </td>
                                        </tr>";
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
</div>
<!-- Add Modal -->
<div class="modal fade" id="addnew">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Add Employee</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="users.php" enctype="multipart/form-data" onsubmit="return validation()">
                    <!-- Form Fields for Add Employee -->
                    <div class="form-group">
                        <label for="EmpID" class="col-sm-3 control-label">Employee ID</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="EmpID" name="EmpID" placeholder="Enter Employee ID" required>
                            <span id="EmpIDerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Fname" class="col-sm-3 control-label">First Name</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="Fname" name="Fname" placeholder="Enter First Name" required>
                            <span id="Fnameerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Lname" class="col-sm-3 control-label">Last Name</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="Lname" name="Lname" placeholder="Enter Last Name">
                            <span id="Lnameerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="CNIC" class="col-sm-3 control-label">CNIC</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control CNIC" id="CNIC" name="CNIC" placeholder="00000-0000000-0">
                            <span id="CNICerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Gmail" class="col-sm-3 control-label">Gmail</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="Gmail" name="Gmail" placeholder="Enter Gmail Account" required>
                            <span id="Gmailerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Home" class="col-sm-3 control-label">Address</label>
                        <div class="col-sm-9">
                            <textarea class="form-control" name="Home" id="Home" style="resize:none;" placeholder="Enter Employee Address" required></textarea>
                            <span id="Homeerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Phone" class="col-sm-3 control-label">Contact</label>
                        <div class="col-sm-9">
                            <input type="number" class="form-control" id="Phone" name="Phone" placeholder="0000-000000-0" required>
                            <span id="Phoneerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Salary" class="col-sm-3 control-label">Salary</label>
                        <div class="col-sm-9">
                            <input type="number" class="form-control" id="Salary" name="Salary" placeholder="Enter Salary Here" required>
                            <span id="Salaryerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="workingDays" class="col-sm-3 control-label">Working Days</label>
                        <div class="col-sm-9">
                            <select class="form-control workingDays" name="workingDays" id="workingDays" required>
                                <option value="" selected>Select Working Days</option>
                                <option value="5">5</option>
                                <option value="6">6</option>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Gender" class="col-sm-3 control-label">Gender*</label>
                        <div class="col-sm-9">
                            <select class="form-control" name="Sex" id="Sex" required>
                                <option value="" selected>Select Gender</option>
                                <?php while ($Grow = $genders->fetch_assoc()): ?>
                                    <option value="<?= $Grow['id'] ?>"><?= $Grow['Gender'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="designation_name" class="col-sm-3 control-label">Designation</label>
                        <div class="col-sm-9">
                            <select class="form-control" name="DesID" id="DesID" required>
                                <option value="" selected>Select Designation</option>
                                <?php while ($drow2 = $designations->fetch_assoc()): ?>
                                    <option value="<?= $drow2['id'] ?>"><?= $drow2['designation_name'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="pay_name" class="col-sm-3 control-label">Salary Type</label>
                        <div class="col-sm-9">
                            <select class="form-control" name="PayId" id="PayId" required>
                                <option value="" selected>Select Salary Type</option>
                                <?php while ($prow4 = $payscale->fetch_assoc()): ?>
                                    <option value="<?= $prow4['id'] ?>"><?= $prow4['pay_name'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="shift_name" class="col-sm-3 control-label">Shift</label>
                        <div class="col-sm-9">
                            <select class="form-control" id="ShiftID" name="ShiftID" required>
                                <option value="" selected>Select Shift</option>
                                <?php while ($srow6 = $shifts->fetch_assoc()): ?>
                                    <option value="<?= $srow6['id'] ?>"><?= $srow6['shift_name'] ?></option>
                                    <option value="<?= $srow6['id'] ?>"><?= $srow6['time_in'] . ' - ' . $srow6['time_out'] . '-' . $srow6['grace_time'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
                <button type="submit" class="btn btn-primary btn-flat" name="add"><i class="fa fa-save"></i> Save</button>
                </form>
            </div>
        </div>
    </div>
</div>
<!-- Edit Modal -->
<div class="modal fade" id="edit">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Edit Employee</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="users.php" onsubmit="return editEmployeeValidation()">
                    <!-- Form Fields for Edit Employee -->
                    <input type="hidden" class="empid" name="id">
                    <div class="form-group">
                        <label for="UpId" class="col-sm-3 control-label">User ID</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control UpId" id="UpId" name="UpId" required readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="EmpID" class="col-sm-3 control-label">Employee ID</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control EmpID" id="EmpID" name="EmpID" required readonly>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Fname" class="col-sm-3 control-label">First Name</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control Fname" id="editFname" name="Fname" required>
                            <span id="upFnameerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Lname" class="col-sm-3 control-label">Last Name</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control Lname" id="editLname" name="Lname" required>
                            <span id="upLnameerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="CNIC" class="col-sm-3 control-label">CNIC</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control CNIC" id="editCNIC" name="CNIC" required>
                            <span id="upCNICerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="gmail" class="col-sm-3 control-label">Gmail</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control gmail" id="editGmail" name="gmail" required>
                            <span id="upGmailerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Home" class="col-sm-3 control-label">Address</label>
                        <div class="col-sm-9">
                            <textarea class="form-control Home" name="Home" id="editHome" style="resize:none;"></textarea>
                            <span id="upHomeerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Phone" class="col-sm-3 control-label">Contact</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control Phone" id="editPhone" name="Phone">
                            <span id="upPhoneerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Salary" class="col-sm-3 control-label">Salary</label>
                        <div class="col-sm-9">
                            <input type="text" class="form-control Salary" id="editSalary" name="Salary">
                            <span id="upSalaryerror" style="color: red;"></span>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="Sex" class="col-sm-3 control-label">Gender</label>
                        <div class="col-sm-9">
                            <select class="form-control Sex" name="Sex">
                                <?php while ($Grow1 = $genders->fetch_assoc()): ?>
                                    <option value="<?= $Grow1['id'] ?>" data-value="<?= $Grow1['id'] ?>" data-current="<?= $Grow1['Gender'] ?>"><?= $Grow1['Gender'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="designation_name" class="col-sm-3 control-label">Designation</label>
                        <div class="col-sm-9">
                            <select class="form-control DesID" name="DesID" required>
                                <?php while ($drow3 = $designations->fetch_assoc()): ?>
                                    <option value="<?= $drow3['id'] ?>" data-value="<?= $drow3['id'] ?>" data-current="<?= $drow3['designation_name'] ?>"><?= $drow3['designation_name'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="pay_name" class="col-sm-3 control-label">Salary Type</label>
                        <div class="col-sm-9">
                            <select class="form-control PayId" name="PayId" required>
                                <?php while ($prow5 = $payscale->fetch_assoc()): ?>
                                    <option value="<?= $prow5['id'] ?>" data-value="<?= $prow5['id'] ?>" data-current="<?= $prow5['pay_name'] ?>"><?= $prow5['pay_name'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="shift_name" class="col-sm-3 control-label">Shift</label>
                        <div class="col-sm-9">
                            <select class="form-control ShiftID" name="ShiftID" required>
                                <?php while ($srow7 = $shifts->fetch_assoc()): ?>
                                    <option value="<?= $srow7['id'] ?>" data-value="<?= $srow7['id'] ?>" data-current="<?= $srow7['shift_name'] ?>"><?= $srow7['shift_name'] ?></option>
                                <?php endwhile; ?>
                            </select>
                        </div>
                    </div>
                    <div class="form-group">
                        <label for="workingDays" class="col-sm-3 control-label">Working Days</label>
                        <div class="col-sm-9">
                            <select class="form-control workingDays" name="workingDays" id="workingDays">
                                <option value="5">5</option>
                                <option value="6">6</option>
                            </select>
                        </div>
                    </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
                <button type="submit" class="btn btn-success btn-flat" name="edit"><i class="fa fa-check-square-o"></i> Update</button>
                </form>
            </div>
        </div>
    </div>
</div>
<!-- Delete Modal -->
<div class="modal fade" id="delete">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Delete Employee</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="users.php">
                    <input type="hidden" class="empid" name="id">
                    <div class="text-center">
                        <p>DELETE EMPLOYEE</p>
                        <h2 class="bold del_employee_name"></h2>
                    </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
                <button type="submit" class="btn btn-danger btn-flat" name="delete"><i class="fa fa-trash"></i> Delete</button>
                </form>
            </div>
        </div>
    </div>
</div>

<script src="https://code.jquery.com/jquery-3.7.0.js" integrity="sha256-JlqSTELeR4TLqP0OG9dxM7yDPqX1ox/HfgiSLBj8+kM=" crossorigin="anonymous"></script>
<script src="JS/datatable1.13.6.js"></script>
<script src="JS/button2.4.1.js"></script>
<script src="JS/ajax3.10.1.js"></script>
<script src="JS/ajax0.1.53pdf.js"></script>
<script src="JS/ajax0.1.53font.js"></script>
<script src="JS/button2.4.15.js"></script>

<script>
    $(function() {
        $('.dt').DataTable({
            dom: "'<'row'l>Bfrtip'",
            "scrollX": true,
            "scrollY": '500px',
            buttons: [
                {
                    extend: 'pdf',
                    title: 'Employee List',
                    orientation: 'landscape',
                    customize: function(doc) {
                        doc.pageSize = 'legal';
                        doc.pageMargins = [40, 60, 40, 60];
                        var columnIndexToSkip = 15;
                        for (var i = 0; i < doc.content[1].table.body.length; i++) {
                            doc.content[1].table.body[i].splice(columnIndexToSkip, 16);
                        }
                    }
                },
                {
                    extend: 'excel',
                    title: 'Employee List',
                    customize: function(xlsx) {
                        var columnIndexToHide = 15;
                        var sheet = xlsx.xl.worksheets['sheet1.xml'];
                        $('row c', sheet).each(function() {
                            if ($(this).index() == columnIndexToHide) {
                                $(this).text('');
                            }
                        });
                    }
                },
                'copy', 'csv', 'print'
            ]
        });

        $(document).on('click', '.edit', function(e) {
            $('#edit').modal('show');
            var id = $(this).data('id');
            getRow(id);
            let tempGender = ($(this).closest('tr').find('td:eq(8)').text());
            let tempDes = ($(this).closest('tr').find('td:eq(5)').text());
            let tempSalaryType = ($(this).closest('tr').find('td:eq(6)').text());
            let tempShift = ($(this).closest('tr').find('td:eq(7)').text());
            let workingDays = ($(this).closest('tr').find('td:eq(13)').text());
            $(".Sex option:selected").removeAttr("selected");
            $(".DesID option:selected").removeAttr("selected");
            $(".PayId option:selected").removeAttr("selected");
            $(".ShiftID option:selected").removeAttr("selected");
            $(".workingDays option:selected").removeAttr("selected");
            setTimeout(function() {
                $(`.Sex option[data-current|='${tempGender}']`).attr('selected', 'selected');
                $(`.DesID option[data-current|='${tempDes}']`).attr('selected', 'selected');
                $(`.PayId option[data-current|='${tempSalaryType}']`).attr('selected', 'selected');
                $(`.ShiftID option[data-current|='${tempShift}']`).attr('selected', 'selected');
                $(`.workingDays option[data-current|='${workingDays}']`).attr('selected', 'selected');
            }, 100);
        });

        $(document).on('click', '.advance', function(e) {
            e.preventDefault();
            let empID = $(this).data('id');
            $.ajax({
                type: 'POST',
                url: 'getPayableAmount.php',
                data: { id: empID },
                dataType: 'json',
                success: function(response) {
                    $('.UpId').val(empID);
                    $('#UpId').val(response.UpId);
                    $('#PayableAmount').val(response);
                    $('#advance').modal('show');
                }
            });
            $.ajax({
                type: 'POST',
                url: 'getAdvanceData.php',
                data: { id: empID },
                dataType: 'json',
                success: function(data) {
                    var tbody = $('#employeeTable tbody');
                    tbody.empty();
                    if (data.length > 0) {
                        $.each(data, function(index, row) {
                            var newRow = '<tr>';
                            newRow += '<td>' + row.firstname + '</td>';
                            newRow += '<td>' + row.Amount + '</td>';
                            newRow += '<td>' + row.AmountDate + '</td>';
                            newRow += '</tr>';
                            tbody.append(newRow);
                        });
                    } else {
                        tbody.append('<tr><td colspan="4">No data found</td></tr>');
                    }
                    $('#advance').modal('show');
                },
                error: function() {
                    console.error('Error fetching data');
                }
            });
        });

        $(document).on('click', '.payroll', function(e) {
            e.preventDefault();
            let empID = $(this).data('id');
            $('#payroll').modal('show');
            $.ajax({
                type: 'POST',
                url: 'getSpecialPayrollEmpDetails.php',
                data: { id: empID },
                dataType: 'json',
                success: function(response) {
                    $('.posid').val(empID);
                    $('#edit_Employee_Name').val(response.Employee_Name);
                    $('#edit_designation_name').val(response.designation_name);
                    $('#edit_shift_name').val(response.shift_name);
                    $('#edit_pay_name').val(response.pay_name);
                    $('#edit_time_in').val(response.time_in);
                    $('#edit_time_out').val(response.time_out);
                    $('#edit_payroll_type').val(response.payroll_type);
                    $('#edit_salary').val(response.salary);
                    $('#edit_deducted_days').val(response.deducted_days);
                    $('#edit_late').val(response.late);
                    $('#edit_absent').val(response.absent);
                    $('#edit_Advance').val(response.Advance);
                    $('#edit_M_Advance').val(response.M_Advance);
                    $('#edit_Deduction').val(response.Deduction);
                    $('#edit_M_Deducted').val(response.M_Deducted);
                    $('#edit_M_Salary').val(response.M_Salary);
                    $('#edit_Total_Pay').val(response.Total_Pay);
                }
            });
        });

        $('.addnew').click(function(e) {
            e.preventDefault();
            $('#addnew').modal('show');
        });
    });

    function getRow(id) {
        $.ajax({
            type: 'POST',
            url: 'employee_row.php',
            data: { id: id },
            dataType: 'json',
            success: function(response) {
                $('#posid').val(response.id);
                $('#edit_title').val(response.description);
                $('#edit_rate').val(response.rate);
                $('#del_posid').val(response.id);
                $('#del_position').html(response.description);
            }
        });
    }
</script>
</body>
</html>
<!-- Additional Modals for advance and payroll can be added here as needed -->

<script src="https://code.jquery.com/jquery-3.7.0.js" integrity="sha256-JlqSTELeR4TLqP0OG9dxM7yDPqX1ox/HfgiSLBj8+kM=" crossorigin="anonymous"></script>
<script src="JS/datatable1.13.6.js"></script>
<script src="JS/button2.4.1.js"></script>
<script src="JS/ajax3.10.1.js"></script>
<script src="JS/ajax0.1.53pdf.js"></script>
<script src="JS/ajax0.1.53font.js"></script>
<script src="JS/button2.4.15.js"></script>

<script>
    $(function() {
        $('.dt').DataTable({
            dom: "'<'row'l>Bfrtip'",
            "scrollX": true,
            "scrollY": '500px',
            buttons: [
                {
                    extend: 'pdf',
                    title: 'Employee List',
                    orientation: 'landscape',
                    customize: function(doc) {
                        doc.pageSize = 'legal';
                        doc.pageMargins = [40, 60, 40, 60];
                        var columnIndexToSkip = 15;
                        for (var i = 0; i < doc.content[1].table.body.length; i++) {
                            doc.content[1].table.body[i].splice(columnIndexToSkip, 16);
                        }
                    }
                },
                {
                    extend: 'excel',
                    title: 'Employee List',
                    customize: function(xlsx) {
                        var columnIndexToHide = 15;
                        var sheet = xlsx.xl.worksheets['sheet1.xml'];
                        $('row c', sheet).each(function() {
                            if ($(this).index() == columnIndexToHide) {
                                $(this).text('');
                            }
                        });
                    }
                },
                'copy', 'csv', 'print'
            ]
        });

        $(document).on('click', '.edit', function(e) {
            $('#edit').modal('show');
            var id = $(this).data('id');
            getRow(id);
            let tempGender = ($(this).closest('tr').find('td:eq(8)').text());
            let tempDes = ($(this).closest('tr').find('td:eq(5)').text());
            let tempSalaryType = ($(this).closest('tr').find('td:eq(6)').text());
            let tempShift = ($(this).closest('tr').find('td:eq(7)').text());
            let workingDays = ($(this).closest('tr').find('td:eq(13)').text());
            $(".Sex option:selected").removeAttr("selected");
            $(".DesID option:selected").removeAttr("selected");
            $(".PayId option:selected").removeAttr("selected");
            $(".ShiftID option:selected").removeAttr("selected");
            $(".workingDays option:selected").removeAttr("selected");
            setTimeout(function() {
                $(`.Sex option[data-current|='${tempGender}']`).attr('selected', 'selected');
                $(`.DesID option[data-current|='${tempDes}']`).attr('selected', 'selected');
                $(`.PayId option[data-current|='${tempSalaryType}']`).attr('selected', 'selected');
                $(`.ShiftID option[data-current|='${tempShift}']`).attr('selected', 'selected');
                $(`.workingDays option[data-current|='${workingDays}']`).attr('selected', 'selected');
            }, 100);
        });

        $(document).on('click', '.advance', function(e) {
            e.preventDefault();
            let empID = $(this).data('id');
            $.ajax({
                type: 'POST',
                url: 'getPayableAmount.php',
                data: { id: empID },
                dataType: 'json',
                success: function(response) {
                    $('.UpId').val(empID);
                    $('#UpId').val(response.UpId);
                    $('#PayableAmount').val(response);
                    $('#advance').modal('show');
                }
            });
            $.ajax({
                type: 'POST',
                url: 'getAdvanceData.php',
                data: { id: empID },
                dataType: 'json',
                success: function(data) {
                    var tbody = $('#employeeTable tbody');
                    tbody.empty();
                    if (data.length > 0) {
                        $.each(data, function(index, row) {
                            var newRow = '<tr>';
                            newRow += '<td>' + row.firstname + '</td>';
                            newRow += '<td>' + row.Amount + '</td>';
                            newRow += '<td>' + row.AmountDate + '</td>';
                            newRow += '</tr>';
                            tbody.append(newRow);
                        });
                    } else {
                        tbody.append('<tr><td colspan="4">No data found</td></tr>');
                    }
                    $('#advance').modal('show');
                },
                error: function() {
                    console.error('Error fetching data');
                }
            });
        });

        $(document).on('click', '.payroll', function(e) {
            e.preventDefault();
            let empID = $(this).data('id');
            $('#payroll').modal('show');
            $.ajax({
                type: 'POST',
                url: 'getSpecialPayrollEmpDetails.php',
                data: { id: empID },
                dataType: 'json',
                success: function(response) {
                    $('.posid').val(empID);
                    $('#edit_Employee_Name').val(response.Employee_Name);
                    $('#edit_designation_name').val(response.designation_name);
                    $('#edit_shift_name').val(response.shift_name);
                    $('#edit_pay_name').val(response.pay_name);
                    $('#edit_time_in').val(response.time_in);
                    $('#edit_time_out').val(response.time_out);
                    $('#edit_payroll_type').val(response.payroll_type);
                    $('#edit_salary').val(response.salary);
                    $('#edit_deducted_days').val(response.deducted_days);
                    $('#edit_late').val(response.late);
                    $('#edit_absent').val(response.absent);
                    $('#edit_Advance').val(response.Advance);
                    $('#edit_M_Advance').val(response.M_Advance);
                    $('#edit_Deduction').val(response.Deduction);
                    $('#edit_M_Deducted').val(response.M_Deducted);
                    $('#edit_M_Salary').val(response.M_Salary);
                    $('#edit_Total_Pay').val(response.Total_Pay);
                }
            });
        });

        $('.addnew').click(function(e) {
            e.preventDefault();
            $('#addnew').modal('show');
        });
    });

    function getRow(id) {
        $.ajax({
            type: 'POST',
            url: 'employee_row.php',
            data: { id: id },
            dataType: 'json',
            success: function(response) {
                $('#posid').val(response.id);
                $('#edit_title').val(response.description);
                $('#edit_rate').val(response.rate);
                $('#del_posid').val(response.id);
                $('#del_position').html(response.description);
            }
        });
    }
</script>
</body>
</html>