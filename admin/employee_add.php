<?php
	include 'includes/session.php';

	if(isset($_POST['add'])){
		$Employee_Id = $_POST['EmpID'];
		$PersonName = $_POST['Fname'].$_POST['Lname'];
		$CNIC = $_POST['CNIC'];
		$Gmail = $_POST['gmail'];
		$designation_name = $_POST['DesID'];
		$pay_name = $_POST['PayId'];
		$shift_name = $_POST['ShiftID'];
		$Gender = $_POST['Sex'];
		$address = $_POST['Home'];
		$contact = $_POST['Phone'];
		$salary = $_POST['Salary'];
		// $workingDays = $_POST['workingDays'];
		
		$sql = "call `StrProc_InsertUserProfileInfo`('$Employee_Id',
		'$PersonName',
		'$CNIC',
		'$Gmail',
		'$designation_name',
		'$pay_name',
		'$shift_name',
		'$Gender',
		'$address',
		'$contact',
		'$salary')";

		if($conn->query($sql)){
			$_SESSION['success'] = "Data entered successfully";
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