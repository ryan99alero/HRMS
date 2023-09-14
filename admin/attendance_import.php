<?php include 'includes/session.php'; ?>
<?php include 'includes/header.php'; ?>

<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">

<?php include 'includes/navbar.php'; ?>
  <?php include 'includes/menubar.php'; ?>

  <!-- Content Wrapper. Contains page content -->
    <div class="content-wrapper">
        <!-- Content Header (Page header) -->
        <section class="content-header">
        <h1>
            Import Attendance List
        </h1>
        <ol class="breadcrumb">
            <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
            <li>Employees</li>
            <li class="active">Import Employees</li>
        </ol>
        </section>
        <section class="content">
            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                                 <h2>Upload Excel File</h2>
                           <form action="#" method="post" enctype="multipart/form-data">
                              Select Excel File to Upload:
                              <input type="file" name="excel_File" accept=".csv">
                              <input type="submit" value="import" name="import">
                            </form>


                            <form action="#" method="post" enctype="multipart/form-data">
                                <!-- ... (your existing form fields) ... -->
                                <!-- <input type="submit" name="import" value="Display Data"> -->
                                <input type="submit" name="insert" value="Insert Data into Database">
                            </form>

                            <?php
                            //     use SimpleExcel\SimpleExcel;
                            //     if(isset($_POST['import'])){

                            //    if(move_uploaded_file($_FILES['excel_File']['tmp_name'],$_FILES['excel_File']['name'])){
                                
                            //     require_once('../SimpleExcel/SimpleExcel.php');
                                
                            //     $excel = new SimpleExcel('csv');
                                
                            //     $excel->parser->loadFile($_FILES['excel_File']['name']);
                                
                            //     $row = $excel->parser->getField(); 
                            //     $count = 1;
                            //     while(count($row)>$count){
                            //     //    $User_Id = $foo[$count][0];
                            //        $Employee_Id = $row[$count][0];
                            //        $check_in = $row[$count][1];
                            //        $check_out = $row[$count][2];
                            //        $over_time = $row[$count][3];
                                   
                                //    $created_by = $foo[$count][4];
                                //    $User_Id = $foo[$count][0];
                                // $sql = "call `StrProc_InsertAttendanceInfo`('$Employee_Id','$check_in','$check_out','$over_time',1)";  
                                // $sql = "INSERT INTO `attendance`(`Employee_Id`,`check_in`,`check_out`,`over_time`,`updated_by`) VALUES ('$Employee_Id','$check_in','$check_out','$over_time',NOW())";
                                    // $query = $conn->query($sql);
		                            //  if($conn->query($sql)){
		                            //  	$_SESSION['success'] = 'Attendance added successfully';
		                            //  }
		                            //  else{
		                            //  	$_SESSION['error'] = $conn->error;
		                            //  }   
                            //         $count++;
                            //     }
                            //     echo '<pre>';
                            //     print_r($row);
                            //     echo '</pre>';

                            //    }

                                

                            //     }
// ----------------------------------------------------------------------------------------------------------------------



use SimpleExcel\SimpleExcel;

if(isset($_POST['import'])){
    if(move_uploaded_file($_FILES['excel_File']['tmp_name'], $_FILES['excel_File']['name'])){
        require_once('../SimpleExcel/SimpleExcel.php');
        
        $excel = new SimpleExcel('csv');
        $excel->parser->loadFile($_FILES['excel_File']['name']);
        $rows = $excel->parser->getField(); 

        echo '<table border="1">';
        echo '<tr><th>Person ID</th><th>Date</th><th>Check-In</th><th>Check-out</th></tr>';
        
        foreach ($rows as $row) {
            echo '<tr>';
            foreach ($row as $cell) {
                echo '<td>' . $cell  . '</td>';
            }
            echo '</tr>';
        }
        

        echo '</table>';
    }
}

if(isset($_POST['insert'])){
    $Employee_Id = $_POST['Person ID'];
    $check_in = $_POST['Date'];
    $check_out = $_POST['Check-In'];
    $over_time = $_POST['Check-out'];

 $sql = "call `StrProc_InsertAttendanceInfo`('$Employee_Id','$check_in','$check_out','$over_time',1)";  




}


                            ?>
                            


                        </div>
                    </div>
                </div>
            </div>
        </section>
    </div>
 
    <?php include 'includes/footer.php'; ?>
    <?php include 'includes/scripts.php'; ?>

</div>