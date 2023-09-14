<?php
	include 'includes/session.php';

	if(isset($_POST['edit'])){
		$empid = $_POST['RecId'];
		$firstname = $_POST['firstname'];
		$lastname = $_POST['lastname'];
		$address = $_POST['address'];
		$birthdate = $_POST['contact'];
		$contact = $_POST['gender'];
		$gender = $_POST['salary'];
		$position = $_POST['Advance'];
		// $schedule = $_POST['schedule'];
		
		$sql = "UPDATE user_profile SET firstname = '$firstname', lastname = '$lastname', address = '$address', birthdate = '$birthdate', contact_info = '$contact', gender = '$gender', position_id = '$position', schedule_id = '$schedule' WHERE id = '$empid'";
		//$sql = "call StrProc_ChangeUserProfileInfo";
		//$sql = "UPDATE user_profile as up SET up.Designation_Id = Designation_Id, up.Employee_Id = Employee_Id, up.firstname = firstname, up.lastname = lastname, up.address = address, up.contact = contact, up.gender = gender, up.shift_id = shift_id, up.payscale_id = payscale_id, up.salary = salary, up.Advance = Advance, up.updated_by = updated_by, up.updated_on = updated_on WHERE up.RecId = UpId AND up.isactive = 1;
		//END";
		if($conn->query($sql)){
			$_SESSION['success'] = 'Employee updated successfully';
		}
		else{
			$_SESSION['error'] = $conn->error;
		}

	}
	else{
		$_SESSION['error'] = 'Select employee to edit first';
	}

	header('location: employee.php');
?>