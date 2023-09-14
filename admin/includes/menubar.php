<head>
  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
  <style>
    .skin-blue .sidebar-menu>li>a:hover{
      /* background-color:rgb(20, 194, 247); */
      background-color:#4680ff;
      transition : 1s;
    }
    .skin-blue .sidebar-menu>li>a:visited{
      /* background-color:rgb(20, 194, 247); */
      background-color:#4680ff;
    }
  </style>
</head>
<aside class="main-sidebar" style="background-color:rgba(0, 0, 0, 0.733);">
    <!-- sidebar: style can be found in sidebar.less -->
    <section class="sidebar">
      <!-- Sidebar user panel -->
      <div class="user-panel">
        <!-- <div class="pull-left image">
          <img src="<?php echo (!empty($user['photo'])) ? '../images/'.$user['photo'] : '../images/profile.jpg'; ?>" class="img-circle" alt="User Image">
        </div> -->
        <div class="pull-left info">
          <p><?php echo 
          // $user['username'];
          $user['firstname'].' '.$user['lastname']; 
          ?></p>
          <!-- <a><i class="fa fa-circle text-success"></i> Online</a> -->
        </div>
      </div>
      <!-- sidebar menu: : style can be found in sidebar.less -->
      <ul class="sidebar-menu" data-widget="tree">
        <li class="header" style="background-color:rgba(0, 0, 0, 0.733);">REPORTS</li>
        <li class=""><a href="home.php"><i class="fa fa-dashboard fa-beat"></i> <span>Dashboard</span></a></li>
        <li class="header" style="background-color:rgba(0, 0, 0, 0.733);">MANAGE</li>
        
        <li><a href="attendance.php"><i class="fa fa-calendar fa-beat"></i> <span>Attendance</span></a></li>
        <li><a href="attendance_import.php"><i class="fa fa-calendar fa-beat"></i> <span>Import Attendance List</span></a></li>
        <!-- <li class="treeview">
          <a href="#">
            <i class="fa fa-users fa-beat"></i>
            <span>Employees</span>
            <span class="pull-right-container">
              <i class="fa fa-angle-left pull-right"></i>
            </span>
          </a>
          <ul class="treeview-menu">
            <li><a href="employee.php"><i class="fa fa-circle-o"></i> Employee List</a></li>
            <li><a href="overtime.php"><i class="fa fa-circle-o"></i> Overtime</a></li>
            <li><a href="cashadvance.php"><i class="fa fa-circle-o"></i> Cash Advance</a></li>
            <li><a href="schedule.php"><i class="fa fa-circle-o"></i> Schedules</a></li>
          </ul>
        </li> -->
        <li><a href="employee.php"><i class="fa fa-users"></i> Employee List</a></li>
        <!-- <li><a href="deduction.php"><i class="fa fa-file-text fa-beat"></i> <span>Deductions</span></a></li> -->
        <li><a href="position.php"><i class="fa fa-suitcase fa-beat"></i> <span>Positions</span></a></li>
        <li class="header" style="background-color:rgba(0, 0, 0, 0.733);">PRINTABLES</li>
        <li><a href="payroll.php"><i class="fa fa-files-o fa-beat"></i> <span>Payroll</span></a></li>
        <li><a href="payscale.php"><i class="fa fa-files-o fa-beat"></i> <span>Pay Scale</span></a></li>
        <li><a href="schedule.php"><i class="fa fa-clock-o"></i> Schedules</a></li>
        <li><a href="holiday.php"><i class="fa fa-clock-o"></i>Holi Day</a></li>
        <!-- <li><a href="schedule_employee.php"><i class="fa fa-clock-o fa-beat"></i> <span>Schedule</span></a></li> -->
        <li><a href="Biometric Devices.php"><i class="fa-brands fa-nfc-directional fa-beat"></i> <span>&nbsp;&nbsp;Biometric Devices</span></a></li>
      </ul>
    </section>
    <!-- /.sidebar -->
  </aside>