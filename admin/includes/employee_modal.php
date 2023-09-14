<?php
include "includes/conn.php";
include 'includes/session.php';
// include "admin/employee.php";
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
                  	<label for="EmpID" class="col-sm-3 control-label">Employee Id</label>

                  	<div class="col-sm-9">
                    	<input type="text" class="form-control" id="EmpID" name="EmpID" required>
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
                  	<label for="Home" class="col-sm-3 control-label">Address</label>

                  	<div class="col-sm-9">
                      <textarea class="form-control" name="Home" id="Home"></textarea>
                  	</div>
                </div>
                <div class="form-group">
                    <label for="Phone" class="col-sm-3 control-label">Contact</label>

                    <div class="col-sm-9">
                      <input type="number" class="form-control" id="Phone" name="Phone">
                    </div>
                </div>
                <div class="form-group">
                    <label for="Salary" class="col-sm-3 control-label">salary</label>

                    <div class="col-sm-9">
                      <input type="number" class="form-control" id="Salary" name="Salary">
                    </div>
                </div>
                <div class="form-group">
                    <label for="Gender" class="col-sm-3 control-label">Gender</label>

                    <div class="col-sm-9"> 
                      <select class="form-control" name="Sex" id="Sex" required>
                        <option value="" selected>- Select -</option>
                        <!-- <option value="Male">Male</option>
                        <option value="Female">Female</option> -->
                        
                        <?php
                           $sql = "SELECT * FROM `tbl_gender`";
                        //  $sql = "call `StrProc_getGenderInfo`()";
                          $query = $conn->query($sql);
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
                    <label for="designation_name" class="col-sm-3 control-label">Designation Name</label>

                    <div class="col-sm-9">
                      <select class="form-control" name="DesID" id="DesID" required>
                        <option value="" selected>- Select -</option>
                        <?php
                          $sql = "SELECT * FROM `designation`";
                          // $sql = "call `StrProc_getDesignationInfo`()";
                          $query = $conn->query($sql);
                          while($drow = $query->fetch_assoc()){
                            echo "
                              <option value='".$drow['RecId']."'>".$drow['designation_name']."</option>
                            ";
                          } 
                          // $query->free();
                        ?>
                      </select>
                    </div>
                    
                </div>
                <div class="form-group">
                    <label for="pay_name" class="col-sm-3 control-label">Pay Name</label>

                    <div class="col-sm-9">
                      <select class="form-control" name="PayId" id="PayId" required>
                        <option value="" selected>- Select -</option>
                        <?php
                          $sql = "SELECT * FROM `pay_scale`";
                          // $sql = "call `StrProc_SelectDesignationInfo`(0)";
                          $query = $conn->query($sql);
                          while($prow = $query->fetch_assoc()){
                            echo "
                              <option value='".$prow['RecId']."'>".$prow['pay_name']."</option>
                            ";
                          } 
                          // $query->free();
                        ?>
                      </select>
                    </div>
                    
                </div>
                <div class="form-group">
                    <label for="shift_name" class="col-sm-3 control-label">Shift Name</label>

                    <div class="col-sm-9">
                      <select class="form-control" id="ShiftID" name="ShiftID" required>
                        <option value="" selected>- Select -</option>
                        <?php
                          $sql = "SELECT * FROM `shift`";
                          //  $ssql="Call `StrProc_SelectShiftInfo`(0)";  
                          //  var_dump($query);
                          //  $shiftArray = $conn->query($ssql);
                          $query = $conn->query($sql);
                          while($srow = $query->fetch_assoc()){
                            echo "
                              <option value='".$srow['RecId']."'>".$srow['shift_name']."</option>
                            ";
                            //  echo "
                            //   <option value='".$srow['RecId']."'>".$srow['shift_name']."'>".$srow['time_in'].' - '.$srow['time_out'].'-'.$srow['grace_time']."</option>
                            // ";
                          }
                        ?>
                      </select>
                    </div>
                </div>
                <div class="form-group">
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
                          $sql = "CALL `StrProc_getRoleInfo`()";
                          $query = $conn->query($sql);
                          while($Rrow = $query->fetch_assoc()){
                            echo "
                              <option value='".$Rrow['RecId']."'>".$Rrow['role_name']."</option>
                            ";
                          } 
                          // $query->free();
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
                </div>
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
                    <label for="edit_firstname" class="col-sm-3 control-label">Firstname</label>

                    <div class="col-sm-9">
                      <input type="text" class="form-control" id="edit_firstname" name="firstname">
                    </div>
                </div>
                <div class="form-group">
                    <label for="edit_lastname" class="col-sm-3 control-label">Lastname</label>

                    <div class="col-sm-9">
                      <input type="text" class="form-control" id="edit_lastname" name="lastname">
                    </div>
                </div>
                <div class="form-group">
                    <label for="edit_address" class="col-sm-3 control-label">Address</label>

                    <div class="col-sm-9">
                      <textarea class="form-control" name="address" id="edit_address"></textarea>
                    </div>
                </div>
                <div class="form-group">
                    <label for="datepicker_edit" class="col-sm-3 control-label">Birthdate</label>

                    <div class="col-sm-9"> 
                      <div class="date">
                        <input type="text" class="form-control" id="datepicker_edit" name="birthdate">
                      </div>
                    </div>
                </div>
                <div class="form-group">
                    <label for="edit_contact" class="col-sm-3 control-label">Contact Info</label>

                    <div class="col-sm-9">
                      <input type="text" class="form-control" id="edit_contact" name="contact">
                    </div>
                </div>
                <div class="form-group">
                    <label for="Gender" class="col-sm-3 control-label">Gender</label>

                    <div class="col-sm-9"> 
                      <select class="form-control" name="Sex" id="Sex" required>
                        <option value="" selected>- Select -</option>
                        <!-- <option value="Male">Male</option>
                        <option value="Female">Female</option> -->
                        
                        <?php
                           $sql = "SELECT * FROM `tbl_gender`";
                        //  $sql = "call `StrProc_getGenderInfo`()";
                          $query = $conn->query($sql);
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
                    <label for="edit_position" class="col-sm-3 control-label">Position</label>

                    <div class="col-sm-9">
                      <select class="form-control" name="position" id="edit_position">
                        <option selected id="position_val"></option>
                        <?php
                          // $sql = "SELECT * FROM position";
                          // $query = $conn->query($sql);
                          // while($prow = $query->fetch_assoc()){
                          //   echo "
                          //     <option value='".$prow['id']."'>".$prow['description']."</option>
                          //   ";
                          // }
                        ?>
                      </select>
                    </div>
                </div>
                <div class="form-group">
                    <label for="edit_schedule" class="col-sm-3 control-label">Schedule</label>

                    <div class="col-sm-9">
                      <select class="form-control" id="edit_schedule" name="schedule">
                        <option selected id="schedule_val"></option>
                        <?php
                          // $sql = "SELECT * FROM schedules";
                          // $query = $conn->query($sql);
                          // while($srow = $query->fetch_assoc()){
                          //   echo "
                          //     <option value='".$srow['id']."'>".$srow['time_in'].' - '.$srow['time_out']."</option>
                          //   ";
                          // }
                        ?>
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