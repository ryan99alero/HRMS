<?php
// Database connection
$servername = "localhost"; // Database server name
$username = "root"; // Database username
$password = ""; // Database password
$dbname = "hrms"; // Database name

// Create connection
$conn = new mysqli($servername, $username, $password, $dbname);

// Check connection
if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$adv_ID = isset($_POST['id']) ? $_POST['id'] : 0;

$sql = "call`StrProc_SelectAdvanceInfo`($adv_ID)";
$result = $conn->query($sql);

if ($result->num_rows > 0) {
    // Fetch the result
 $row = $result->fetch_assoc();
    // {
    $firstname = $row["firstname"];
    $Amounts = $row["Amount"];
    $AmoutDate = $row["AmoutDate"];
    // }
} else {
    $firstname = "No data found"; // If no data is found in the database
    $Amounts = "No data found"; // If no data is found in the database
    $AmoutDate = "No data found"; // If no data is found in the database
}
?>
<div class="modal fade" id="advance">
  <div class="modal-dialog">
      <div class="modal-content">
           <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span></button>
                 <h4 class="modal-title"><b>Advance</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="advance_add.php" id="advanceForm" enctype="multipart/form-data">
                        
                    <div class="form-group">

                    <div class="col-sm-4 hidden">
                        <label for="UpId" class="col-sm-10 control-label">ID</label>
                        <input type="text" class="form-control UpId" id="UpId" name="UpId" value="<?php echo $UpId ?>">
                        </div>

                        <div class="col-sm-4">
                        <label for="PayableAmount" class="col-sm-10 control-label">Payable Amount</label>
                        <input type="text" class="form-control" id="PayableAmount" disabled>
                        </div>

                        <div class="col-sm-4">
                        <label for="Amount" class="col-sm-10 control-label">Advance Amount</label>
                        <input type="text" class="form-control" id="Amount" name="Amount">
                        </div>
                        
                        <div class="col-sm-4">
                            
                            <label for="AmoutDate" class="col-sm-9 control-label">Amount Date</label>
                            <input type="date" class="form-control" id="AmoutDate" name="AmoutDate" required>
                           
                        </div>
                        <div class="col-sm-2 pull-right">
                            <button class="btn btn-success btn-sm advance btn-flat" value="submit" name="addadvance" id="addadvance" type="submit"  style='border-radius:8px;margin-top:27px;'><i class="fa fa-edit"></i> Add</button>
                        </div>
                    </div>
                 
                </form>
              
                
         
                <table class="table" id="employeeTable">
                    <thead>
                        <tr>
                            <th>Employee Name</th>
                            <th>Advance Amount</th>
                            <th>Advance Amount Date</th>
                        </tr>
                    </thead>
                    <tbody >
                      <td><?php echo $firstname; ?></td>
                      <td><?php echo $Amounts; ?></td>
                      <td><?php echo $AmoutDate; ?></td>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
    $(document).ready(function () {
    $('#addadvance').click(function (event) {
        event.preventDefault(); // Prevent the default form submission behavior
        $('#advanceForm').submit(); // Assuming the form has an id of "advanceForm"
    });
});

</script>