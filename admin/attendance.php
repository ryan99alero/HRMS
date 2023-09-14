<?php include 'includes/conn.php'; ?>
<?php include 'includes/session.php'; ?>
<?php include 'includes/header.php'; ?>
<!-- <link href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css" rel="stylesheet"/> -->
<link href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css" rel="stylesheet"/>
<link rel="stylesheet" type="text/css" href="https://cdn.datatables.net/buttons/2.4.1/css/buttons.dataTables.min.css">
<body class="hold-transition skin-blue sidebar-mini">
<div class="wrapper">

  <?php include 'includes/navbar.php'; ?>
  <?php include 'includes/menubar.php'; ?>

  <!-- Content Wrapper. Contains page content -->
  <div class="content-wrapper">
    <!-- Content Header (Page header) -->
    <section class="content-header">
      <h1>
        Attendance
      </h1>
      <ol class="breadcrumb">
        <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
        <li class="active">Attendance</li>
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
              <!-- <a href="#edit" data-toggle="modal" class="btn btn-primary btn-sm btn-flat" style="border-radius:8px;background-color:#4680ff;"><i class="fa fa-plus"></i> New</a> -->
              <!-- <button class="btn btn-primary btn-sm btn-flat btn-success glyphicon glyphicon-print" style="border-radius:8px;"> Print</button> -->
            </div>
            <div class="box-body">
              <table id="attendanceTable" class="table table-bordered">
                <thead>
                  <th>Employee ID</th>
                  <th>Person Name</th>
                  <th>Shift Name</th>
                  <th>Check In</th>
                  <th>Date</th>
                  <th>Check Out</th>
                  <th>Earlier Departure</th>
                  <th>Late Coming</th>
                  <th>Over Time</th>
                  <th>Status</th>
                  <!-- <th>Action</th> -->
                  <th></th>
                </thead>
                <tbody>
                  <?php
                   // $sql = "SELECT *, employees.employee_id AS empid, attendance.id AS attid FROM attendance LEFT JOIN employees ON employees.id=attendance.employee_id ORDER BY attendance.date DESC, attendance.time_in DESC";
                   $sql = "call `StrProc_SelectAttendanceInfo`"; 
                   $query = $conn->query($sql);
                    while($row = $query->fetch_assoc()){
                       //$status = ($row['status'])?'<span class="label label-warning pull-right">ontime</span>':'<span class="label label-danger pull-right">late</span>';
                      echo "
                        <tr>
                          <td>".$row['Employee_Id']."</td>
                          <td>".$row['PersonName']."</td>
                          <td>".$row['Shift_Name']."</td>
                          <td>".$row['Check_In']."</td>
                          <td>".$row['Check_In_Date']."</td>
                          <td>".$row['Check_Out']."</td>
                          <td>".$row['Late_Coming']."</td>
                          <td>".$row['Over_Time']."</td>
                          <td>".$row['Status']."</td>
                          <td>
                            <button class='btn btn-success btn-sm btn-flat edit' style='border-radius:8px;' data-id=''><i class='fa fa-edit'></i> Edit</button>
                            
                          </td>
                        </tr>
                      ";
                    }
                    // <button class='btn btn-danger btn-sm btn-flat delete' style='border-radius:8px;' data-id=''><i class='fa fa-trash'></i> Delete</button>
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
  <?php include 'includes/attendance_modal.php'; ?>
</div>
<?php include 'includes/scripts.php'; ?>
<!-- <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.4.1/js/dataTables.buttons.min.js"></script> -->
<script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
<script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.4.1/js/dataTables.buttons.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/jszip/3.1.3/jszip.min.js"></script>
<script src="https://cdn.datatables.net/buttons/2.4.1/js/buttons.html5.min.js"></script>
<script>
$(function(){
  $("#attendanceTable").DataTable( {
        dom: 'Bfrtip',
        buttons: [
          'excel', 'pdf', 'print'
        ]
    } );
  $('.edit').click(function(e){
    e.preventDefault();
    $('#edit').modal('show');
    var id = $(this).data('id');
    getRow(id);
  });

  // $('.delete').click(function(e){
  //   e.preventDefault();
  //   $('#delete').modal('show');
  //   var id = $(this).data('id');
  //   getRow(id);
  // });
});

function getRow(id){
  $.ajax({
    type: 'POST',
    url: 'attendance_row.php',
    data: {id:id},
    dataType: 'json',
    success: function(response){
      $('#datepicker_edit').val(response.edit);
      $('#attendance_date').html(response.date);
      $('#edit_time_in').val(response.time_in);
      $('#edit_time_out').val(response.time_out);
      $('#attid').val(response.attid);
      $('#employee_name').html(response.firstname+' '+response.lastname);
      $('#del_attid').val(response.attid);
      $('#del_employee_name').html(response.firstname+' '+response.lastname);
    }
  });
}
</script>
</body>
</html>