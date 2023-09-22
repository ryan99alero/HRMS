<?php
include "includes/conn.php";
include 'includes/session.php';
// include "./employee.php";
?>

<?php 
     $sql = "SELECT * FROM `tbl_gender`"; 
    //  $sql = "call `StrProc_getGenderInfo`()";
     $query = $conn->query($sql);
     $query1 = $conn->query($sql);
?>

<?php
    $sql = "SELECT * FROM `designation`";
    // $sql = "call `StrProc_getDesignationInfo`()";
    $query2 = $conn->query($sql);
    $query3 = $conn->query($sql);
?>
<?php
     $sql = "SELECT * FROM `pay_scale`";
     // $sql = "call `StrProc_SelectDesignationInfo`(0)";
     $query4 = $conn->query($sql);
     $query5 = $conn->query($sql);
?>
<?php
    $sql = "SELECT * FROM `shift`";
    //  $ssql="Call `StrProc_SelectShiftInfo`(0)";  
    $query6 = $conn->query($sql);
    $query7 = $conn->query($sql);
?>


<!-- Add -->
<div class="modal fade" id="addnew">
  <div class="modal-dialog">
      <div class="modal-content">
          <div class="modal-header">
            <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                <span aria-hidden="true">&times;</span></button>
            <h4 class="modal-title"><b>Add Employee</b></h4>
          </div>
          <div class="modal-body">
            <form class="form-horizontal" method="POST" action="employee_add.php" enctype="multipart/form-data">
           
            <div class="form-group">
                  <label for="EmpID" class="col-sm-3 control-label">Employee ID*</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="EmpID" name="EmpID" required>
                  </div>
              </div>
              <div class="form-group">
                  <label for="Fname" class="col-sm-3 control-label">First Name*</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="Fname" name="Fname" required>
                  </div>
              </div>
              <div class="form-group">
                  <label for="Lname" class="col-sm-3 control-label">Last Name</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="Lname" name="Lname" >
                  </div>
              </div>
              <div class="form-group">
                  <label for="CNIC" class="col-sm-3 control-label">CNIC*</label>
                  <div class="col-sm-9">
                      <input type="text" class="form-control" id="CNIC" name="CNIC" required>
                  </div>
              </div>
              <div class="form-group">
                  <label for="gmail" class="col-sm-3 control-label">Gmail*</label>
                  <div class="col-sm-9">
                      <input type="text" class="form-control" id="gmail" name="gmail" required>
                  </div>
              </div>
              <div class="form-group">
                  <label for="Home" class="col-sm-3 control-label">Address*</label>

                  <div class="col-sm-9">
                    <textarea class="form-control" name="Home" id="Home"></textarea>
                  </div>
              </div>
              <div class="form-group">
                  <label for="Phone" class="col-sm-3 control-label">Contact*</label>

                  <div class="col-sm-9">
                    <input type="number" class="form-control" id="Phone" name="Phone">
                  </div>
              </div>
              <div class="form-group">
                  <label for="Salary" class="col-sm-3 control-label">Salary*</label>

                  <div class="col-sm-9">
                    <input type="number" class="form-control" id="Salary" name="Salary">
                  </div>
              </div>
              <div class="form-group">
                  <label for="Gender" class="col-sm-3 control-label">Gender*</label>

                  <div class="col-sm-9"> 
                    <select class="form-control" name="Sex" id="Sex" required>
                      <option value="" selected>- Select -</option>
                      <!-- <option value="Male">Male</option>
                      <option value="Female">Female</option> -->
                      
                      <?php
                      //     $sql = "SELECT * FROM `tbl_gender`";
                      // //  $sql = "call `StrProc_getGenderInfo`()";
                      //   $query = $conn->query($sql);
                        while($Grow = $query->fetch_assoc()){
                          echo "
                            <option value='".$Grow['RecId']."'>".$Grow['Gender']."</option>

                          ";
                        }
                        // $query->free();
                      ?>

                    </select>
                  </div>
              </div>
              <div class="form-group">
                  <label for="designation_name" class="col-sm-3 control-label">Designation*</label>

                  <div class="col-sm-9">
                    <select class="form-control" name="DesID" id="DesID" required>
                      <option value="" selected>- Select -</option>
                      <?php
                        // $sql = "SELECT * FROM `designation`";
                        // $sql = "call `StrProc_getDesignationInfo`()";
                        // $query = $conn->query($sql);
                        while($drow2 = $query2->fetch_assoc()){
                          echo "
                            <option value='".$drow2['RecId']."'>".$drow2['designation_name']."</option>
                          ";
                        } 
                        // $query->free();
                      ?>
                    </select>
                  </div>
                  
              </div>
              <div class="form-group">
                  <label for="pay_name" class="col-sm-3 control-label">Salary Type*</label>

                  <div class="col-sm-9">
                    <select class="form-control" name="PayId" id="PayId" required>
                      <option value="" selected>- Select -</option>
                      <?php
                        // $sql = "SELECT * FROM `pay_scale`";
                        // $sql = "call `StrProc_SelectDesignationInfo`(0)";
                        // $query4 = $conn->query($sql);
                        while($prow4 = $query4->fetch_assoc()){
                          echo "
                            <option value='".$prow4['RecId']."'>".$prow4['pay_name']."</option>
                          ";
                        } 
                        // $query->free();
                      ?>
                    </select>
                  </div>
                  
              </div>
              <div class="form-group">
                  <label for="shift_name" class="col-sm-3 control-label">Shift*</label>

                  <div class="col-sm-9">
                    <select class="form-control" id="ShiftID" name="ShiftID" required>
                      <option value="" selected>- Select -</option>
                      <?php
                        // $sql = "SELECT * FROM `shift`";
                        //  $ssql="Call `StrProc_SelectShiftInfo`(0)";  
                        //  var_dump($query);
                        //  $shiftArray = $conn->query($ssql);
                        // $query = $conn->query($sql);
                        while($srow6 = $query6->fetch_assoc()){
                          echo "
                            <option value='".$srow6['RecId']."'>".$srow6['shift_name']."</option>
                          ";
                           echo "
                            <option value='".$srow6['RecId']."'>".$srow6['shift_name']."'>".$srow6['time_in'].' - '.$srow6['time_out'].'-'.$srow6['grace_time']."</option>
                          ";
                        }
                      ?>
                    </select>
                  </div>
              </div>
              <!-- <div class="form-group">
                  <label for="RecId" class="col-sm-3 control-label">User Id</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="RecId" name="RecId">
                  </div>
              </div>
              <div class="form-group">
                  <label for="RId" class="col-sm-3 control-label">Role</label>

                  <div class="col-sm-9">
                    <select class="form-control" name="RId" id="RId" required>
                      <option value="" selected>- Select -</option>
                      <?php
                        // $sql = "SELECT * FROM `role`";
                        // $sql = "CALL `StrProc_getRoleInfo`()";
                        // $query = $conn->query($sql);
                        // while($Rrow = $query->fetch_assoc()){
                        //   echo "
                        //     <option value='".$Rrow['RecId']."'>".$Rrow['role_name']."</option>
                        //   ";
                        // } 
                        //  $query->free();
                      ?>
                    </select>
                  </div>
                  
              </div>
              <div class="form-group">
                  <label for="Uname" class="col-sm-3 control-label">User Name</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="Uname" name="Uname">
                  </div>
              </div>
              <div class="form-group">
                  <label for="Pass" class="col-sm-3 control-label">Password</label>

                  <div class="col-sm-9">
                    <input type="text" class="form-control" id="Pass" name="Pass">
                  </div>
              </div> -->
              <!-- <div class="form-group">
                  <label for="photo" class="col-sm-3 control-label">Photo</label>

                  <div class="col-sm-9">
                    <input type="file" name="photo" id="photo">
                  </div>
              </div> -->
          </div>
          <div class="modal-footer">
            <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
            <button type="submit" class="btn btn-primary btn-flat" name="add"><i class="fa fa-save"></i> Save</button>
            </form>
          </div>
      </div>
  </div>
</div>

<!-- Edit -->
<div class="modal fade" id="edit">
    <div class="modal-dialog">
        <div class="modal-content">
          	<div class="modal-header">
            	<button type="button" class="close" data-dismiss="modal" aria-label="Close">
              		<span aria-hidden="true">&times;</span></button>
            	<h4 class="modal-title"><b><span class="employee_id"></span></b></h4>
          	</div>
          	<div class="modal-body">
            	<form class="form-horizontal" method="POST" action="employee_edit.php">
            		<input type="hidden" class="empid" name="id">
                <div class="form-group">
        <label for="UpId" class="col-sm-3 control-label">User ID</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="UpId" name="UpId" required readonly>
        </div>
    </div>
    <div class="form-group">
        <label for="EmpID" class="col-sm-3 control-label">Employee ID</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="EmpID" name="EmpID" required readonly>
        </div>
    </div>
                <div class="form-group">
        <label for="Fname" class="col-sm-3 control-label">First Name</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="Fname" name="Fname" required>
        </div>
    </div>
    <div class="form-group">
        <label for="Lname" class="col-sm-3 control-label">Last Name</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="Lname" name="Lname" required>
        </div>
    </div>
    <div class="form-group">
        <label for="CNIC" class="col-sm-3 control-label">CNIC</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="CNIC" name="CNIC" required>
        </div>
    </div>
    <div class="form-group">
        <label for="gmail" class="col-sm-3 control-label">Gmail</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="gmail" name="gmail" required>
        </div>
    </div>
    
    <div class="form-group">
        <label for="Home" class="col-sm-3 control-label">Address</label>
        <div class="col-sm-9">
            <textarea class="form-control" name="Home" id="Home"></textarea>
        </div>
    </div>
    
    <div class="form-group">
        <label for="Phone" class="col-sm-3 control-label">Contact</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="Phone" name="Phone">
        </div>
    </div>
    
    <div class="form-group">
        <label for="Salary" class="col-sm-3 control-label">Salary</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="Salary" name="Salary">
        </div>
    </div>
    
    <div class="form-group">
        <label for="Gender" class="col-sm-3 control-label">Gender</label>
        <div class="col-sm-9">
            <select class="form-control" name="Sex" id="Sex"  required>

                <option value=""  selected></option>
                <!-- PHP code to populate gender options -->
                <?php
                
                // echo"<option value='".$Grow['RecId']."'>".$Grow['Gender']."</option>";
                // $sql = "SELECT * FROM `tbl_gender`";
                //         //  $sql = "call `StrProc_getGenderInfo`()";
                //           $query = $conn->query($sql);
                          while($Grow1 = $query1->fetch_assoc()){
                            echo "
                              <option value='".$Grow1['RecId']."'>".$Grow1['Gender']."</option>

                            ";
                          }
                          // $query->free();  
                        ?>
            </select>
        </div>
    </div>
    
    <div class="form-group">
        <label for="designation_name" class="col-sm-3 control-label">Designation</label>
        <div class="col-sm-9">
            <select class="form-control" name="DesID" id="DesID" required>
                <option value="" selected>- Select -</option>
                <!-- PHP code to populate designation options -->
                <?php
                          // $sql = "SELECT * FROM `designation`";
                          // $sql = "call `StrProc_getDesignationInfo`()";
                          // $query1 = $conn->query($sql);
                          while($drow3 = $query3->fetch_assoc()){
                            echo "
                              <option value='".$drow3['RecId']."'>".$drow3['designation_name']."</option>
                            ";
                          } 
                          // $query->free();
                        ?>
            </select>
        </div>
    </div>
    
    <div class="form-group">
        <label for="pay_name" class="col-sm-3 control-label">Salary Type</label>
        <div class="col-sm-9">
            <select class="form-control" name="PayId" id="PayId" required>
                <option value="" selected>- Select -</option>
                <!-- PHP code to populate pay scale options -->
                <?php
                          // $sql = "SELECT * FROM `pay_scale`";
                          // $sql = "call `StrProc_SelectDesignationInfo`(0)";
                          // $query = $conn->query($sql);
                          while($prow5 = $query5->fetch_assoc()){
                            echo "
                              <option value='".$prow5['RecId']."'>".$prow5['pay_name']."</option>
                            ";
                          } 
                          // $query->free();
                        ?>
            </select>
        </div>
    </div>
    
    <div class="form-group">
        <label for="shift_name" class="col-sm-3 control-label">Shift</label>
        <div class="col-sm-9">
            <select class="form-control" id="ShiftID" name="ShiftID" required>
                <option value="" selected>- Select -</option>
                <!-- PHP code to populate shift options -->
                <?php
                          // $sql = "SELECT * FROM `shift`";
                          //  $ssql="Call `StrProc_SelectShiftInfo`(0)";  
                          //  var_dump($query);
                          //  $shiftArray = $conn->query($ssql);
                          // $query = $conn->query($sql);
                          while($srow7 = $query7->fetch_assoc()){
                            echo "
                              <option value='".$srow7['RecId']."'>".$srow7['shift_name']."</option>
                            ";
                             echo "
                              <option value='".$srow7['RecId']."'>".$srow7['shift_name']."'>".$srow7['time_in'].' - '.$srow7['time_out'].'-'.$srow7['grace_time']."</option>
                            ";
                          }
                        ?>
            </select>
        </div>
    </div>
    <div class="form-group">
        <label for="workingDays" class="col-sm-3 control-label">Working Days</label>
        <div class="col-sm-9">
            <input type="text" class="form-control" id="workingDays" name="workingDays">
        </div>
    </div>
    <!-- <div class="form-group">
        <label for="RId" class="col-sm-3 control-label">Role</label>
        <div class="col-sm-9">
            <select class="form-control" name="RId" id="RId" required>
                <option value="" selected>- Select -</option> -->
                <?php
                          // $sql = "SELECT * FROM `role`";
                          // $sql = "CALL `StrProc_getRoleInfo`()";
                          // $query = $conn->query($sql);
                          // while($Rrow = $query->fetch_assoc()){
                          //   echo "
                          //     <option value='".$Rrow['RecId']."'>".$Rrow['role_name']."</option>
                          //   ";
                          // } 
                          // $query->free();
                        ?>
            <!-- </select>
        </div>
    </div> -->
          	</div>
          	      <div class="modal-footer">
            	      <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
            	      <button type="submit" class="btn btn-success btn-flat" name="edit"><i class="fa fa-check-square-o"></i> Update</button>
            	</form>
                	</div>
        </div>
    </div>
</div>

<!-- Delete -->
<div class="modal fade" id="delete">
    <div class="modal-dialog">
        <div class="modal-content">
          	<div class="modal-header">
            	<button type="button" class="close" data-dismiss="modal" aria-label="Close">
              		<span aria-hidden="true">&times;</span></button>
            	<h4 class="modal-title"><b><span class="employee_id"></span></b></h4>
          	</div>
          	<div class="modal-body">
            	<form class="form-horizontal" method="POST" action="employee_delete.php">
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







<!-- Update Photo -->
<!-- <div class="modal fade" id="edit_photo">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
              <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                  <span aria-hidden="true">&times;</span></button>
              <h4 class="modal-title"><b><span class="del_employee_name"></span></b></h4>
            </div>
            <div class="modal-body">
              <form class="form-horizontal" method="POST" action="employee_edit_photo.php" enctype="multipart/form-data">
                <input type="hidden" class="empid" name="id">
                <div class="form-group">
                    <label for="photo" class="col-sm-3 control-label">Photo</label>

                    <div class="col-sm-9">
                      <input type="file" id="photo" name="photo" required>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
              <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i class="fa fa-close"></i> Close</button>
              <button type="submit" class="btn btn-success btn-flat" name="upload"><i class="fa fa-check-square-o"></i> Update</button>
              </form>
            </div>
        </div>
    </div>
</div>     -->


<script src="https://code.jquery.com/jquery-3.7.0.js" integrity="sha256-JlqSTELeR4TLqP0OG9dxM7yDPqX1ox/HfgiSLBj8+kM=" crossorigin="anonymous"></script>



<script>

    $(document).ready(function() {
        // Edit button click event
        $(".empid").click((function(){
            $(".empid #DesID").submit()
        }));
        $(document).ready(function() {
    // Function to open the edit modal and populate form fields
    $('.edit').click(function() {
        // Get data from the row or wherever it's stored
        var UpId = $(this).closest('tr').find('td:eq(0)').text();
        var EmpID = $(this).closest('tr').find('td:eq(1)').text();
        var Fname = $(this).closest('tr').find('td:eq(2)').text();
        var Lname = $(this).closest('tr').find('td:eq(2)').text();
        var CNIC = $(this).closest('tr').find('td:eq(3)').text();
        var Gmail = $(this).closest('tr').find('td:eq(4)').text();
        var DesID = $(this).closest('tr').find('td:eq(5)').text();
        var PayId = $(this).closest('tr').find('td:eq(6)').text();   
        var ShiftID = $(this).closest('tr').find('td:eq(7)').text();
        var Sex = $(this).closest('tr').find('td:eq(8)').text();
        var Home = $(this).closest('tr').find('td:eq(9)').text();
        var Phone = $(this).closest('tr').find('td:eq(10)').text();
        var Salary = $(this).closest('tr').find('td:eq(11)').text();
        var workingDays = $(this).closest('tr').find('td:eq(13)').text();
        // var roleId = $(this).closest('tr').find('td:eq(9)').text();

        // Set the values in the edit modal
        $('#edit #UpId').val(UpId);
        $('#edit #EmpID').val(EmpID);
        $('#edit #Fname').val(Fname);
        $('#edit #Lname').val(Lname);
        $('#edit #CNIC').val(CNIC);
        $('#edit #gmail').val(Gmail);
        $('#edit #DesID').val(DesID);
        $('#edit #PayId').val(PayId);
        $('#edit #ShiftID').val(ShiftID);
        $('#edit #Sex').val(Sex);
        $('#edit #Home').val(Home);
        $('#edit #Phone').val(Phone);
        $('#edit #Salary').val(Salary);
        $('#edit #workingDays').val(workingDays);
        // $('#edit #RId').val(roleId);

        // Open the edit modal
        $('#edit').modal('show');
    });

    // Handle form submission (you may need additional validation)
    $('edit').submit(function(e) {
        e.preventDefault();

        // Get form data
        var formData = $(this).serialize();

        // Send the form data to the server using AJAX or form submission

        // Close the modal when the operation is successful
        $('#edit').modal('hide');
    });
});
  });
</script>