<?php include 'includes/session.php'; ?>
<?php
  include '../timezone.php';
  $range_to = date('m/d/Y');
  $range_from = date('m/d/Y', strtotime('-30 day', strtotime($range_to)));
?>
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
        Payroll
      </h1>
      <ol class="breadcrumb">
        <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
        <li class="active">Payroll</li>
      </ol>
    </section>
    <!-- Main content -->
    <section class="content">
      <?php
        if(isset($_SESSION['error'])){
          echo "
            <div class='alert alert-danger alert-dismissible'>
              <button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button>
              <h4><i class='icon fa fa-warning'></i> Error!</h4>
              ".$_SESSION['error']."
            </div>
          ";
          unset($_SESSION['error']);
        }
        if(isset($_SESSION['success'])){
          echo "
            <div class='alert alert-success alert-dismissible'>
              <button type='button' class='close' data-dismiss='alert' aria-hidden='true'>&times;</button>
              <h4><i class='icon fa fa-check'></i> Success!</h4>
              ".$_SESSION['success']."
            </div>
          ";
          unset($_SESSION['success']);
        }
      ?>
      <div class="row">
        <div class="col-xs-12">
          <div class="box">
          <div class="box-header with-border">
          <a href="payroll_genereate.php" class="myButton" name="paygn">PayRoll Generate Now</a>
            <!-- <a href="payroll_genereate.php" class="btn btn-primary btn-sm btn-flat" style='border-radius:8px;background-color:#4680ff;'><i class="fa fa-plus"></i>PayRoll Generate</a> -->
             </div>
            <div class="box-header with-border">
              <div class="pull-right">
                <form method="POST" class="form-inline" id="payForm">
                  <div class="input-group">
                    <div class="input-group-addon">
                      <i class="fa fa-calendar"></i>
                    </div>
                   <input type="text" class="form-control pull-right col-sm-8" id="reservation" name="date_range" value="<?php echo (isset($_GET['range'])) ? $_GET['range'] : $range_from.' - '.$range_to; ?>">
                   </div>
                  <!-- <button type="button" class="btn btn-success btn-sm btn-flat" id="payroll" style='border-radius:8px;'><span class="glyphicon glyphicon-print"></span> Payroll</button>
                  <button type="button" class="btn btn-primary btn-sm btn-flat" id="payslip" style='border-radius:8px;'><span class="glyphicon glyphicon-print"></span> Payslip</button> -->
                </form>
              </div>
            </div>
            <div class="box-body">
              <table id="example1" class="table table-bordered">
                <thead>
                  <th>ID</th>
                  <th>Employee Name</th>
                  <th>Designation</th>
                  <th>Shift</th>
                  <th>Pay Name</th>
                  <th>Time In</th>
                  <th>Time Out</th>
                  <th>Salary</th>
                  <th>Deducted Days</th>
                  <th>Late</th>
                  <th>Absent</th>
                  <th>Deduction</th>
                  <th>M_Deducted</th>
                  <th>M_Salary</th>
                  <th>Total_Pay</th>
                </thead>
                <tbody>
                   <?php
                   
                  //  $sql = "SELECT * FROM payroll";
                   $sql = "call `sp_PayrollGenerator`(1)";
                   $query = $conn->query($sql);
                   while($row = $query->fetch_assoc()){
                     echo "
                       <tr>
                         <td>".$row['RecId']."</td>
                         <td>".$row['Employee_Name']."</td>
                         <td>".$row['designation_name']."</td>
                         <td>".$row['shift_name']."</td>
                         <td>".$row['pay_name']."</td>
                         <td>".$row['time_in']."</td>
                         <td>".$row['time_out']."</td>
                         <td>".$row['salary']."</td>
                         <td>".$row['deducted_days']."</td>
                         <td>".$row['late']."</td>
                         <td>".$row['absent']."</td>
                         <td>".$row['Deduction']."</td>
                         <td>".$row['M_Deducted']."</td>
                         <td>".$row['M_Salary']."</td>
                         <td>".$row['Total_Pay']."</td>
                         </tr>
                     ";
                   }
                   
                   // $sql = "SELECT *, SUM(amount) as total_amount FROM deductions";
                  // $sql = "call StrProc_SelectPayRollInfo"; 
                   //$query = $conn->query($sql);
                    //$drow = $query->fetch_assoc();
                    //$deduction = $drow['total_amount'];
  
                    
                    //$to = date('Y-m-d');
                    //$from = date('Y-m-d', strtotime('-30 day', strtotime($to)));

                    //if(isset($_GET['range'])){
                      //$range = $_GET['range'];
                      //$ex = explode(' - ', $range);
                      //$from = date('Y-m-d', strtotime($ex[0]));
                      //$to = date('Y-m-d', strtotime($ex[1]));
                    //}

                    //$sql = "SELECT *, SUM(num_hr) AS total_hr, attendance.employee_id AS empid FROM attendance LEFT JOIN employees ON employees.id=attendance.employee_id LEFT JOIN position ON position.id=employees.position_id WHERE date BETWEEN '$from' AND '$to' GROUP BY attendance.employee_id ORDER BY employees.lastname ASC, employees.firstname ASC";
                   // $sql = "call StrProc_SelectPayRollInfo";  
                   // $query = $conn->query($sql);
                    // $total = 0;
                    //while($row = $query->fetch_assoc()){
                      //$empid = $row['empid'];
                      
                      //$casql = "SELECT *, SUM(amount) AS cashamount FROM cashadvance WHERE employee_id='$empid' AND date_advance BETWEEN '$from' AND '$to'";
                      //$sql = "call StrProc_SelectPayRollInfo";
                      //$caquery = $conn->query($casql);
                     // $carow = $caquery->fetch_assoc();
                      //$cashadvance = $carow['cashamount'];

                      //$gross = $row['rate'] * $row['total_hr'];
                      //$total_deduction = $deduction + $cashadvance;
                      //$net = $gross - $total_deduction;

                      // echo "
                      //   <tr>
                      //     <td>".$row['UserP_Id']."</td>
                      //     <td>".$row['Designation_Id']."</td>
                      //     <td>".$row['Shift_Id']."</td>
                      //     <td>".$row['Pay_Id']."</td>
                      //     <td>".$row['Deduction']."</td>
                      //     <td>".$row['salary']."</td>
                      //     <td>".$row['Total_Pay']."</td>
                          
                      //   </tr>
                      // ";
                   // }
                   ?>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </section>   
  </div>
  
    
  <?php include 'includes/footer.php'; ?>
</div>
<?php include 'includes/scripts.php'; ?> 
<script>
$(function(){
  $('#example1').DataTable().destroy();
  $('#example1').DataTable( {
        dom: 'Bfrtip',
        // "pageLength": 90,
        buttons: [
            'copy', 'csv', 'excel', 'pdf', 'print'
        ]
    } );
  $('.edit').click(function(e){
    e.preventDefault();
    $('#edit').modal('show');
    var id = $(this).data('id');
    getRow(id);
  });

  $('.delete').click(function(e){
    e.preventDefault();
    $('#delete').modal('show');
    var id = $(this).data('id');
    getRow(id);
  });

  $("#reservation").on('change', function(){
    var range = encodeURI($(this).val());
    window.location = 'payroll.php?range='+range;
  });

  $('#payroll').click(function(e){
    e.preventDefault();
    $('#payForm').attr('action', 'payroll_generate.php');
    $('#payForm').submit();
  });

  $('#payslip').click(function(e){
    e.preventDefault();
    $('#payForm').attr('action', 'payslip_generate.php');
    $('#payForm').submit();
  });

});

// function getRow(id){
//   $.ajax({
//     type: 'POST',
//     url: 'position_row.php',
//     data: {id:id},
//     dataType: 'json',
//     success: function(response){
//       $('#posid').val(response.id);
//       $('#edit_title').val(response.description);
//       $('#edit_rate').val(response.rate);
//       $('#del_posid').val(response.id);
//       $('#del_position').html(response.description);
//     }
//   });
// }
</script>
<style>

.myButton {
	background-color:#2dabf9;
	-webkit-border-radius:23px;
	-moz-border-radius:23px;
	border-radius:23px;
	border:2px solid #0b0e07;
	display:inline-block;
	cursor:pointer;
	color:#ffffff;
	font-family:Arial;
	font-size:17px;
	padding:4px 8px;
	text-decoration:none;
	text-shadow:-2px 2px 0px #263666;
}
.myButton:hover {
	background-color:#0688fa;
}
.myButton:active {
	position:relative;
	top:1px;
}
</style>
<script>
window.addEventListener('load', function() {
    var payrollButton = document.getElementById('payrollButton');
    payrollButton.disabled = true; // Button ko disable kardo
});
</script>
</body>
</html>