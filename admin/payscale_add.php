<?php
	include 'includes/session.php';

	if(isset($_POST['add'])){
		$title = $_POST['title'];
		// $rate = $_POST['rate'];

		//$sql = "INSERT INTO pay_scale (pay_name) 
        // VALUES ('$title')";
		//$sql = "call StrProc_InsertPayScaleInfo('$title',1')";
		$sql = "CALL `StrProc_InsertPayScaleInfo`('$title', 1)";
        if($conn->query($sql)){
			$_SESSION['success'] = 'Payscale added successfully';
		}
		else{
			$_SESSION['error'] = $conn->error;
		}
	}	
	else{
		$_SESSION['error'] = 'Fill up add form first';
	}

	header('location: payscale.php');

?>