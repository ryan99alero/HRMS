<?php
	include 'includes/session.php';

	if(isset($_POST['add'])){
		$EmpID = $_POST['EmpID'];
		$Fname = $_POST['Fname'];
		$Lname = $_POST['Lname'];
		$DesID = $_POST['DesID'];
		$PayId = $_POST['PayId'];
		$ShiftID = $_POST['ShiftID'];
		$Sex = $_POST['Sex'];
		$Home = $_POST['Home'];
		$Phone = $_POST['Phone'];
		$Salary = $_POST['Salary'];
		$RecId = $_POST['RecId']; // Initialize $RecId from POST data
		$RId = $_POST['RId'];     // Initialize $RId from POST data
		$Uname = $_POST['Uname']; // Initialize $Uname from POST data
		$Pass = $_POST['Pass'];   // Initialize $Pass from POST data

		$sql = "call `StrProc_InsertUserProfileInfo`('$RecId','$EmpID','$DesID','$PayId','$ShiftID','$Fname','$Lname','$Sex','$Home','$Phone','$Salary','$RId','$Uname','$Pass',1,NOW())";

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