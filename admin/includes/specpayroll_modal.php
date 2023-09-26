
<?php
// Connect to your database (replace with your database details)
$servername = "localhost";
$username = "root";
$password = "";
$dbname = "hrms";
$RecId = "";
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}
if(isset($_POST['id'])){
// Retrieve data from the database
$id = $_POST['id']; // Assuming you have a hidden input field with name 'id' in your form

// $sql = "SELECT * FROM your_table_name WHERE id = $id"; // Replace 'your_table_name' with the actual table name
$sql = "call `sp_Special_PayrollGenerator`(1,'$id')";
$result = $conn->query($sql);
var_dump($sql);
if ($result->num_rows > 0) {
    // Output data of each row
    while($row = $result->fetch_assoc()) {
        $RecId = $row['RecId'];
        $Employee_Name = $row['Employee_Name'];
        $designation_name = $row['designation_name'];
        $shift_name = $row['shift_name'];
        $pay_name = $row['pay_name'];
        $time_in = $row['time_in'];
        $time_out = $row['time_out'];
        $payroll_type = $row['payroll_type'];
        $salary = $row['salary'];
        $deducted_days = $row['deducted_days'];
        $late = $row['late'];
        $absent = $row['absent'];
        $Advance = $row['Advance'];
        $M_Advance = $row['M_Advance'];
        $Deduction = $row['Deduction'];
        $M_Deducted = $row['M_Deducted'];
        $M_Salary = $row['M_Salary'];
        $Total_Pay = $row['Total_Pay'];
        
    }
} else {
    echo "No results found";
}
}


// Close the database connection
$conn->close();
?>



<div class="modal fade" id="payroll">
    <div class="modal-dialog">
        <div class="modal-content">
          	<div class="modal-header">
            	<button type="button" class="close" data-dismiss="modal" aria-label="Close">
              		<span aria-hidden="true">&times;</span></button>
            	<h4 class="modal-title"><b>Genrate Payroll</b></h4>
          	</div>
              <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
          	<div class="modal-body">
            	<form class="form-horizontal payrollFormSubmit" method="POST" action="payroll_edit.php">
                                <input type="hidden" class="posid" name="RecId">
                            <div class="form-group">
                                <label for="edit_RecId" class="col-sm-3 control-label">User Id</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_RecId" name="RecId" disabled> -->
                                <input type="text" class="form-control posid" id="posid" name="RecId" value="<?php echo $RecId; ?>" disabled>
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_Employee_Name" class="col-sm-3 control-label">Employee Name</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_Employee_Name" name="Employee_Name" disabled> -->
                                <input type="text" class="form-control" id="edit_Employee_Name" name="Employee_Name" value="<?php echo $Employee_Name; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_designation_name" class="col-sm-3 control-label">Designation Name</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_designation_name" name="designation_name" disabled> -->
                                <input type="text" class="form-control" id="edit_designation_name" name="designation_name" value="<?php echo $designation_name; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_shift_name" class="col-sm-3 control-label">Shift Name</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_shift_name" name="shift_name" disabled> -->
                                <input type="text" class="form-control" id="edit_shift_name" name="shift_name" value="<?php echo $shift_name; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_pay_name" class="col-sm-3 control-label">Pay Name</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_pay_name" name="pay_name" disabled> -->
                                <input type="text" class="form-control" id="edit_pay_name" name="pay_name" value="<?php echo $pay_name; ?>" disabled>
                                
                                </div>
                            </div>
                        
                            <div class="form-group">
                                <label for="edit_time_in" class="col-sm-3 control-label">Time In</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_time_in" name="time_in" disabled> -->
                                <input type="text" class="form-control" id="edit_time_in" name="time_in" value="<?php echo $time_in; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_time_out" class="col-sm-3 control-label">Time Out</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_time_out" name="time_out" disabled> -->
                                <input type="text" class="form-control" id="edit_time_out" name="time_out" value="<?php echo $time_out; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_payroll_type" class="col-sm-3 control-label">Payroll Type</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_time_out" name="time_out" disabled> -->
                                <input type="text" class="form-control" id="edit_payroll_type" name="payroll_type" value="<?php echo $payroll_type; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_salary" class="col-sm-3 control-label">Salary</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_salary" name="salary" disabled> -->
                                <input type="text" class="form-control" id="edit_salary" name="salary" value="<?php echo $salary; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_deducted_days" class="col-sm-3 control-label">Deducted Days</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_deducted_days" name="deducted_days" disabled> -->
                                <input type="text" class="form-control" id="edit_deducted_days" name="deducted_days" value="<?php echo $deducted_days; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_late" class="col-sm-3 control-label">Late</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_late" name="late" disabled> -->
                                <input type="text" class="form-control" id="edit_late" name="late" value="<?php echo $late; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_absent" class="col-sm-3 control-label">Absent</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_absent" name="absent" disabled> -->
                                <input type="text" class="form-control" id="edit_absent" name="absent" value="<?php echo $absent; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_Deduction" class="col-sm-3 control-label">Deduction</label>
                                
                                <div class="col-sm-9">
                                    <!-- <input type="text" class="form-control" id="edit_Deduction" name="Deduction" disabled> -->
                                    <input type="text" class="form-control" id="edit_Deduction" name="Deduction" value="<?php echo $Deduction; ?>" disabled>
                                    
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_M_Deducted" class="col-sm-3 control-label">Modify Deduction</label>
                                
                                <div class="col-sm-9">
                                    <!-- <input type="text" class="form-control" id="edit_M_Deducted" name="M_Deducted"> -->
                                    <input type="text" class="form-control" id="edit_M_Deducted" name="M_Deducted" value="<?php echo $M_Deducted; ?>">
                                    
                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_Advance" class="col-sm-3 control-label">Advance</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_Advance" name="Advance"> -->
                                <input type="text" class="form-control" id="edit_Advance" name="Advance" value="<?php echo $Advance; ?>" disabled>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_M_Advance" class="col-sm-3 control-label">Modify Advance</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_Advance" name="Advance"> -->
                                <input type="text" class="form-control" id="edit_M_Advance" name="M_Advance" value="<?php echo $M_Advance; ?>">

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_M_Salary" class="col-sm-3 control-label">Modify Salary</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_M_Salary" name="M_Salary" readonly> -->
                                <input type="text" class="form-control" id="edit_M_Salary" name="M_Salary" value="<?php echo $M_Salary; ?>" readonly>

                                </div>
                            </div>
                            <div class="form-group">
                                <label for="edit_Total_Pay" class="col-sm-3 control-label">Total Pay</label>

                                <div class="col-sm-9">
                                <!-- <input type="text" class="form-control" id="edit_Total_Pay" name="Total_Pay" disabled> -->
                                <input type="text" class="form-control" id="edit_Total_Pay" name="Total_Pay" value="<?php echo $Total_Pay; ?>" disabled>

                                </div>
                            </div>

                                                
                           

                        </div>
                        <div class="modal-footer">
                                            <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
                                            <button type="submit" class="payrollFormSubmit-btn btn btn-success btn-flat" name="edit" ><i class="fa fa-check-square-o"></i> Generate Payroll</button>
            	</form>
          	</div>
        </div>
    </div>
</div>
<script>
    $(document).ready(function(){
    })
</script>
