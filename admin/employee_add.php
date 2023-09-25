<?php
	include 'includes/session.php';

	if(isset($_POST['add'])){
		$Employee_Id = $_POST['EmpID'];
		$firstname = $_POST['Fname'];
		$lastname = $_POST['Lname'];
		$gender = $_POST['Sex'];
		$CNIC = $_POST['CNIC'];
		$Gmail = $_POST['Gmail'];
		$contact = $_POST['Phone'];
		$address = $_POST['Home'];
		$Designation_Id = $_POST['DesID'];
		$payscale_id = $_POST['PayId'];
		$shift_id = $_POST['ShiftID'];
		$workingDays = $_POST['WorkingDays'];
		$salary = $_POST['Salary'];
		// $Advance = $_POST['Advance'];
		// $workingDays = $_POST['workingDays'];
		
		$sql = "call `SP_InsertUserProfileInfo`('$Employee_Id',
		'$firstname',
		'$lastname',
		'$gender',
		'$CNIC',
		'$Gmail',
		'$contact',
		'$address',
		'$Designation_Id',
		'$payscale_id',
		'$shift_id',
		'$workingDays',
		'$salary')";

		if($conn->query($sql)){
			$_SESSION['success'] = "Employee Add Successfully";
		}
		else{
			$_SESSION['error'] = $conn->error;
		}

	}
	else{
		$_SESSION['error'] = 'Fill up the add form first';
	}

	header('location: employee.php');
?>