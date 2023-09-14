<?php
	include 'includes/session.php';

	if(isset($_POST['edit'])){
		$id = $_POST['id'];
		$Title = $_POST['Title'];
		$Holiday_Date = $_POST['Holiday_Date'];
		// $rate = $_POST['rate'];

		// $sql = "UPDATE designation SET designation_name = '$title' WHERE RecId = '$id'";
		$sql = "Call `StrProc_ChangeHolidayInfo`('$id','$Title','$Holiday_Date',1)";
		if($conn->query($sql)){
			$_SESSION['success'] = 'Payscale updated successfully';
		}
		else{
			$_SESSION['error'] = $conn->error;
		}
	}
	else{
		$_SESSION['error'] = 'Fill up edit form first';
	}

	header('location:holiday.php');

?>