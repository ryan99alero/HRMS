<!-- Add -->
<div class="modal fade" id="addnew">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Add Designation</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="position_add.php">
                    <div class="form-group">
                        <label for="title" class="col-sm-3 control-label">Designation</label>

                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="title" name="title" required
                                   placeholder="Enter Designation">
                        </div>
                    </div>
                    <!-- <div class="form-group">
                        <label for="rate" class="col-sm-3 control-label">Rate per Hr</label>

                        <div class="col-sm-9">
                          <input type="text" class="form-control" id="rate" name="rate" required>
                        </div>
                    </div> -->
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i
                            class="fa fa-close"></i> Close
                </button>
                <button type="submit" class="btn btn-primary btn-flat" name="add"><i class="fa fa-save"></i> Save
                </button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Edit -->
<div class="modal fade" id="edit">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Update Designation</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="position_edit.php">
                    <input type="hidden" id="posid" name="id">
                    <div class="form-group">
                        <label for="edit_title" class="col-sm-3 control-label">Designation</label>

                        <div class="col-sm-9">
                            <input type="text" class="form-control" id="edit_title" name="title">
                        </div>
                    </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i
                            class="fa fa-close"></i> Close
                </button>
                <button type="submit" class="btn btn-success btn-flat" name="edit"><i class="fa fa-check-square-o"></i>
                    Update
                </button>
                </form>
            </div>
        </div>
    </div>
</div>

<!-- Delete -->
<div class="modal fade" id="delete">
    <div class="modal-dialog">
        <div class="modal-content">
            <div class="modal-header">
                <button type="button" class="close" data-dismiss="modal" aria-label="Close">
                    <span aria-hidden="true">&times;</span></button>
                <h4 class="modal-title"><b>Deleting...</b></h4>
            </div>
            <div class="modal-body">
                <form class="form-horizontal" method="POST" action="position_delete.php">
                    <input type="hidden" id="del_posid" name="id">
                    <div class="text-center">
                        <p>DELETE Designation</p>
                        <h2 id="del_position" class="bold"></h2>
                    </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-default btn-flat pull-left" data-dismiss="modal"><i
                            class="fa fa-close"></i> Close
                </button>
                <button type="submit" class="btn btn-danger btn-flat" name="delete"><i class="fa fa-trash"></i> Delete
                </button>
                </form>
            </div>
        </div>
    </div>
</div>
<script src="https://code.jquery.com/jquery-3.7.0.js" integrity="sha256-JlqSTELeR4TLqP0OG9dxM7yDPqX1ox/HfgiSLBj8+kM="
        crossorigin="anonymous"></script>
<script>
    $(document).ready(function () {
        // Edit button click event
        $('.edit').click(function () {
            var id = $(this).data('id');
            var positionTitle = $(this).closest('tr').find('td:eq(1)').text(); // Extract position title from table
            $('#posid').val(id);
            $('#edit_title').val(positionTitle);
            $('#edit').modal('show');
        });

        // Delete button click event
        $('.delete').click(function () {
            var id = $(this).data('id');
            var positionTitle = $(this).closest('tr').find('td:eq(1)').text(); // Extract position title from table
            $('#del_posid').val(id);
            $('#del_position').text(positionTitle);
            $('#delete').modal('show');
        });
    });
</script>


     