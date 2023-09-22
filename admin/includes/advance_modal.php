<div class="modal fade" id="advance">
  <div class="modal-dialog">
      <div class="modal-content">
           <div class="modal-header">
                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                        <span aria-hidden="true">&times;</span></button>
                 <h4 class="modal-title"><b>Advance</b></h4>
            </div>
            <div class="modal-body">
            <!-- onkeyup="return validateAmount();" onclick="return validateAmount();"  -->
                <form class="form-horizontal" method="POST" action="advance_add.php" id="advanceForm" enctype="multipart/form-data">
                        
                    <div class="form-group">

                    <div class="col-sm-5">
                        <label for="UpId" class="col-sm-10 control-label">ID</label>
                        <input type="text" class="form-control" id="UpId" name="UpId">
                        </div>

                        <div class="col-sm-5">
                        <label for="PayableAmount" class="col-sm-10 control-label">Payable Amount</label>
                        <!-- <input type="text" class="form-control" id="PayableAmount" name="PayableAmount" disabled> -->
                        <input type="text" class="form-control" id="PayableAmount" name="PayableAmount" value="<?php echo $PayableAmount; ?>" disabled>
                        </div>

                        <div class="col-sm-5">
                        <label for="Amount" class="col-sm-10 control-label">Advance Amount</label>
                        <input type="text" class="form-control" id="Amount" name="Amount">
                        </div>
                        
                        <div class="col-sm-5">
                            
                            <label for="AmoutDate" class="col-sm-9 control-label">Advance Amount Date</label>
                            <input type="date" class="form-control" id="AmoutDate" name="AmoutDate" required>
                           
                        </div>
                        <div class="col-sm-2">
                            <button class="btn btn-success btn-sm advance btn-flat" value="submit" name="addadvance" id="addadvance" type="submit"  style='border-radius:8px;margin-top:27px;'><i class="fa fa-edit"></i> Add</button>
                        </div>
                    </div>
                 
                </form>
                
                <!-- Table to display employee information -->
                <!-- <table class="table" id="employeeTable">
                    <thead>
                        <tr>
                            <th>Employee ID</th>
                            <th>Employee Name</th>
                            <th>Advance Amount</th>
                        </tr>
                    </thead>
                    <tbody>
                        
                    </tbody>
                </table> -->
            </div>
        </div>
    </div>
</div>

<script src="script.js"></script>

<script src="https://code.jquery.com/jquery-3.7.0.js" integrity="sha256-JlqSTELeR4TLqP0OG9dxM7yDPqX1ox/HfgiSLBj8+kM=" crossorigin="anonymous"></script>

<script>
    // JavaScript code to fetch and display PayableAmount from the server
document.addEventListener("DOMContentLoaded", function () {
    // Send an AJAX request to the server to fetch PayableAmount
    var xhr = new XMLHttpRequest();
    xhr.open("GET", "getPayableAmount.php", true);
    
    xhr.onreadystatechange = function () {
        if (xhr.readyState === 4 && xhr.status === 200) {
            var response = xhr.responseText;
            document.getElementById("PayableAmount").value = response;
        }
    };
    
    xhr.send();
});
</script>


<script>
    $('#').click(function() {
    function addEmployeeToTable() {
    var employeeId = '<?php
        //  echo $row['Employee_Id'];
          ?>'; // Replace with the employee ID you want to fetch                             
    var employeeName = '<?php
    //  echo $row['PersonName']; 
     ?>'; // Replace with the employee name you want to fetch  
    var advanceAmount = document.getElementById('advanceamount').value;

    // Create a new row in the table to display the employee information
    var table = document.getElementById('employeeTable').getElementsByTagName('tbody')[0];
    var newRow = table.insertRow(table.rows.length);
    var cell1 = newRow.insertCell(0);
    var cell2 = newRow.insertCell(1);
    var cell3 = newRow.insertCell(2);
    cell1.innerHTML = employeeId;
    cell2.innerHTML = employeeName;
    cell3.innerHTML = advanceAmount;

    // Clear the advance amount input field
    document.getElementById('advanceamount').value = '';
}


    });

</script>

<!-- <script>
function validateAmount(){
    var advanceamount = document.getElementById("advanceamount").value;
    var minAmount = 0;
    var maxAmount = 4999;
    if(advanceamount<minAmount || advanceamount>maxAmount){
        alert("Advance Amount Must Be between Rs. 0 and Rs. 5000");
        return false; 
    }
    return true;
}
</script> -->

<!-- <script>
        $(document).ready(function() {
        // Edit button click event
        $('.advance').click(function() {
            var id = $(this).data('id');
            var advanceamount = $(this).closest('tr').find('td:eq(0)').text(); // Extract title from table
            $('#posid').val(id);
            $('#edit_advanceamount').val(advanceamount);
            $('#edit').modal('show');
        });
    });
</script> -->
<script>
    $(document).ready(function () {
    $('#addadvance').click(function (event) {
        event.preventDefault(); // Prevent the default form submission behavior
        
        // Your code to fetch data and populate the table goes here
        
        // Submit the form using JavaScript
        $('#advanceForm').submit(); // Assuming the form has an id of "advanceForm"
    });
});

</script>