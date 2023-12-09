<style>
    /* Add your custom CSS styles here */

    .content {
        font-family: Arial, sans-serif;
        background-color: #f5f5f5;
        text-align: center;

    }

    .inp {
        display: inline-block;
        padding: 10px 20px;
    }

    /*
            .wrapper {
                background-color: #fff;
                margin: 20px;
                padding: 20px;
                border: 1px solid #ccc;
                border-radius: 5px;
            } */

    h1 {
        color: #333;
    }

    .box {
        background-color: #fff;
        border: 1px solid #ddd;
        border-radius: 5px;
        padding: 20px;
        margin-top: 20px;
    }

    /* Style the table */
    table {
        width: 100%;
        border-collapse: collapse;
        margin-top: 20px;
    }

    table, th, td {
        border: 1px solid #ddd;
    }

    th, td {
        padding: 10px;
        text-align: left;
    }

    th {
        background-color: #f5f5f5;
    }

    /* Style the file input */
    input[type="file"] {
        display: none;
    }

    label.upload-label {
        background-color: #3498db;
        color: #fff;
        padding: 10px 20px;
        cursor: pointer;
        border-radius: 5px;
    }

    label.upload-label:hover {
        background-color: #2980b9;
    }

    /* Style the buttons */
    input[type="submit"] {
        background-color: #27ae60;
        color: #fff;
        border: none;
        padding: 10px 20px;
        cursor: pointer;
        border-radius: 5px;
    }

    input[type="submit"]:hover {
        background-color: #219955;
    }

    /* Style the file input */
    input[type="file"] {
        display: none; /* Hide the default file input */
        display: inline-block;
        padding: 10px 20px;
        background-color: #27ae60;
        color: #fff;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        text-align: center;


    }


    /* Hover state for the custom file input button */
    input[type="file"]:hover {
        background-color: #219955;
    }
</style>
<?php include 'includes/conn.php'; ?>
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
                Import Holiday List
            </h1>
            <ol class="breadcrumb">
                <li><a href="home.php"><i class="fa fa-dashboard"></i> Home</a></li>
                <li><a href="holiday.php"> <i class="fa fa-dashboard"></i> Holiday </a></li>
                <li class="active">Import Holiday</li>
            </ol>
        </section>
        <section class="content">
            <div class="row">
                <div class="col-xs-12">
                    <div class="box">
                        <div class="box-header with-border">
                            <h2>Upload Excel File</h2>
                            <form action="#" method="post" enctype="multipart/form-data">
                                <div>
                                    Select Excel File to Upload:
                                </div>
                                <div class="inp">
                                    <input type="file" name="excel_File" accept=".csv" class="form-control">
                                </div>

                                <br>
                                <input type="submit" value="import" name="import">
                                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
                                <input type="submit" name="insert" value="Insert Data into Database">
                            </form>

                            <?php
                            ?>
                            </tbody>
                            </table>

                            <?php


                            use SimpleExcel\SimpleExcel;

                            // $db = mysqli_connect('localhost', 'root', '', 'hrms');

                            if (!$conn) {
                                die('Could not connect: ' . mysqli_connect_error());
                            }

                            if (isset($_POST['import'])) {
                                if (move_uploaded_file($_FILES['excel_File']['tmp_name'], $_FILES['excel_File']['name'])) {
                                    require_once('../SimpleExcel/SimpleExcel.php');

                                    $excel = new SimpleExcel('csv');
                                    $excel->parser->loadFile($_FILES['excel_File']['name']);
                                    $rows = $excel->parser->getField();

                                    echo '<table class="dt" border="1">';
                                    echo '<thead><tr><th>Title</th><th>Holiday Date</th></tr></thead>';
                                    foreach ($rows as $row) {
                                        echo '<tr>';
                                        foreach ($row as $cell) {
                                            echo '<td>' . $cell . '</td>';
                                        }
                                        echo '</tr>';
                                    }
                                    echo '</table>';
                                }
                            }

                            if (isset($_POST['insert'])) {
                                if (move_uploaded_file($_FILES['excel_File']['tmp_name'], $_FILES['excel_File']['name'])) {
                                    require_once('../SimpleExcel/SimpleExcel.php');

                                    $excel = new SimpleExcel('csv');
                                    $excel->parser->loadFile($_FILES['excel_File']['name']);
                                    $foo = $excel->parser->getField();
                                    $count = 0;

                                    while (count($foo) > $count) {
                                        $Title = mysqli_real_escape_string($conn, $foo[$count][0]);
                                        $Holiday_Date = mysqli_real_escape_string($conn, $foo[$count][1]);
                                        $sql = "call `StrProc_InsertHolidayInfo`('$Title','$Holiday_Date')";

                                        if (mysqli_query($conn, $sql)) {
                                            // var_dump($sql);
                                            // echo '<script>alert("Data inserted successfully!");</script>';
                                        } else {
                                            echo "Error: " . $sql . "<br>" . mysqli_error($conn);
                                        }

                                        $count++;
                                    }
                                    // header("Location: holiday.php");
                                }
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
    <!-- <link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.css" /> -->
    <!-- <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.js"></script> -->
    <!-- <script>
    $(document).ready(function(){
    $('.dt').DataTable();
    })
    </script> -->
</div>