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
        Employee List
      </h1>
      <ol class="breadcrumb">
        <li><a href="#"><i class="fa fa-dashboard"></i> Home</a></li>
        <li>Employees</li>
        <li class="active">Employee List</li>
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
               <a href="#addnew" data-toggle="modal" class="btn btn-primary btn-sm btn-flat" style='border-radius:8px;background-color:#4680ff;'><i class="fa fa-plus"></i> New</a>
            </div>
            <div class="box-body">
              <table id="example1" class="table table-bordered">
                <thead>
                  <th>ID</th>                 
                  <th>Employee Id</th>
                  <th>Designation Name</th>
                  <th>Pay Name</th>
                  <th>Shift Name</th>
                  <th>Name</th>
                  <th>Gender</th>
                  <th>Address</th>
                  <th>Contact</th>
                  <th>Salary</th>
                  <th>Working Days</th>
                </thead>
                <tbody>
                  <?php
                    //$sql = "SELECT *, employees.id AS empid FROM employees LEFT JOIN position ON position.id=employees.position_id LEFT JOIN schedules ON schedules.id=employees.schedule_id";
                    $sql = "call `StrProc_SelectUserProfileInfo`(0)";
                    $query = $conn->query($sql);
                    while($row = $query->fetch_assoc()){
                      ?>
                        <tr>
                          <td><?php echo $row['RecId']; ?></td>                         
                          <td><?php echo $row['Employee_Id']; ?></td>                         
                          <td><?php echo $row['designation_name']; ?></td>                         
                          <td><?php echo $row['pay_name']; ?></td>                         
                          <td><?php echo $row['shift_name']; ?></td>                         
                          <td><?php echo $row['PersonName']; ?></td>                         
                          <td><?php echo $row['Gender']; ?></td>
                          <td><?php echo $row['address']; ?></td>
                          <td><?php echo $row['contact']; ?></td>
                          <td><?php echo $row['salary']; ?></td>
                          <td><?php echo $row['workingDays']; ?></td>
                          <td>
                            <button class="btn btn-success btn-sm edit btn-flat"  style='border-radius:8px;' data-id="<?php echo $row['RecId']; ?>"><i class="fa fa-edit"></i> Edit</button>
                            
                          </td>
                        </tr>
                      <?php
                    }
                    // $query->free();
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
  <?php
   include 'includes/employee_modal.php';
   ?>
</div>
<?php include 'includes/scripts.php'; ?>

<script>

$(function(){
  $('.edit').click(function(e){
    e.preventDefault();
    $('#edit').modal('show');
    var id = $(this).data('id');
    getRow(id);
  });

  $('.addnew').click(function(e){
    e.preventDefault();
    $('#addnew').modal('show');
    var id = $(this).data('id');
    getRow(id);
  });
});

function getRow(id){
  $.ajax({
    type: 'POST',
    url: 'position_row.php',
    data: {id:id},
    dataType: 'json',
    success: function(response){
      $('#posid').val(response.id);
      $('#edit_title').val(response.description);
      $('#edit_rate').val(response.rate);
      $('#del_posid').val(response.id);
      $('#del_position').html(response.description);
    }
  });
}



// $(function(){
//   $('.edit').click(function(e){
//     e.preventDefault();
//     $('#edit').modal('show');
//     var id = $(this).data('id');
//     getRow(id);
//   });

//   $('.delete').click(function(e){
//     e.preventDefault();
//     $('#delete').modal('show');
//     var id = $(this).data('id');
//     getRow(id);
//   });

//   $('.photo').click(function(e){
//     e.preventDefault();
//     var id = $(this).data('id');
//     getRow(id);
//   });

// });

// function getRow(id){
  // $.ajax({
    // type: 'POST',
    // url: 'employee_row.php',
    // data: {id:id},
    // dataType: 'json',
    // success: function(response){
      // $('.empid').val(response.RecId);
      // $('.employee_id').html(response.RecId);
      // $('.del_employee_name').html(response.firstname+' '+response.lastname);
      // $('#employee_name').html(response.firstname+' '+response.lastname);
      // $('#edit_firstname').val(response.firstname);
      // $('#edit_lastname').val(response.lastname);
      // $('#edit_address').val(response.address);
      // $('#datepicker_edit').val(response.birthdate);
          // $('#edit_contact').val(response.contact_info);
          // $('#gender_val').val(response.gender).html(response.gender);
          // $('#gender_val').val(response.salary).html(response.salary);
      // $('#position_val').val(response.position_id).html(response.description);
      // $('#schedule_val').val(response.schedule_id).html(response.time_in+' - '+response.time_out);
    // }
  // });
// }
</script>
</body>
</html>
