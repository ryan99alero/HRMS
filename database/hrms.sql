-- phpMyAdmin SQL Dump
-- version 5.2.0
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Sep 04, 2023 at 05:14 PM
-- Server version: 10.4.25-MariaDB
-- PHP Version: 8.1.10

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hrms`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `sp_PayrollGenerator` (IN `UserRecID` INT)   BEGIN
-- Calculate the number of days in the previous month (August)
SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

-- Check if records exist for the current month
SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));

IF (@isExist <= 0) THEN
    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) != 1
    ORDER BY 1 ASC);
    
    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) NOT IN (1, 7)
    ORDER BY 1 ASC);

    -- Insert data into payroll table
    INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, salary, deducted_days, late, absent, Deduction, M_Deducted, M_Salary, Total_Pay, created_by, updated_by)
    SELECT
        up.RecId AS EMPID,
        d.RecId,
        s.RecId AS Shift,
        pp.RecId,
        TIME(s.time_in) AS TimeIn,
        TIME(s.time_out) AS TimeOut,
        up.salary,
        FLOOR(DeductedDaysBecauseOfLateArrival) AS DeductionDays,
        NoOfLates AS TotalLate,
        (SystemWorkingDays - AttendedDays) AS Absent,  -- Calculate absent days as (SystemWorkingDays - AttendedDays)
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) + (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) + (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS MDeduction,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
             ) AS Net_Salary,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
             ) AS MSalary,
        UserRecID,
        UserRecID
    FROM (
        SELECT
            @SatSunOff AS SatSunOff,
            @SundayOff AS SunOff,
            CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
            up.Employee_Id AS EMPID,
            COUNT(a.check_in_date) AS AttendedDays,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1' ELSE '0' END
            END) / 3 AS DeductedDaysBecauseOfLateArrival,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
            END) AS _NoOfLates,
            FLOOR((SUM(CASE WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1' ELSE '0' END))) NoOfLates
        FROM
            attendance a
        JOIN user_profile up ON up.Employee_Id = a.Employee_Id 
        JOIN shift s ON s.RecId = up.shift_id
        JOIN designation d ON d.RecId = up.Designation_Id
        JOIN pay_scale pp ON pp.RecId = up.payscale_id
        WHERE a.isactive = 1
        GROUP BY up.Employee_Id
    ) AS a
    JOIN user_profile up ON up.Employee_Id = a.EMPID 
    JOIN shift s ON s.RecId = up.shift_id
    JOIN designation d ON d.RecId = up.Designation_Id
    JOIN pay_scale pp ON pp.RecId = up.payscale_id;
END IF;

-- Show Data
SELECT
    pr.RecId,
    CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
    d.designation_name,
    s.shift_name,
    ps.pay_name,
    TIME(s.time_in) time_in,
    TIME(s.time_out) time_out,
    pr.salary,
    pr.deducted_days,
    pr.late,
    pr.absent,
    pr.Deduction,
    pr.M_Deducted,
    pr.M_Salary,
    pr.Total_Pay,
    pr.updated_on
FROM payroll pr 
JOIN user_profile up ON up.RecId = pr.UserP_Id 
JOIN designation d ON d.RecId = pr.Designation_Id 
JOIN shift s ON s.RecId = pr.Shift_Id 
JOIN pay_scale ps ON ps.RecId = pr.Pay_Id 
WHERE MONTH(pr.created_on) = MONTH(NOW()) 
AND pr.isactive = 1
AND d.isactive = 1
AND s.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeAttendanceInfo` (IN `EmpId` INT, IN `check_in` DATETIME, IN `check_out` DATETIME, IN `check_in_date` DATE)   BEGIN 
UPDATE attendance as a SET a.check_in = check_in ,a.check_out = check_out ,a.updated_by = 1 ,a.updated_on = CURRENT_TIMESTAMP WHERE a.check_in_date =  check_in_date AND a.Employee_Id = EmpId AND a.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeDesignationInfo` (IN `Desig_Id` INT, IN `designation_name` VARCHAR(50))   BEGIN 
UPDATE designation as d SET d.designation_name = designation_name, d.updated_by = 1, d.updated_on = CURRENT_TIMESTAMP WHERE d.RecId = Desig_Id AND d.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeHolidayInfo` (IN `HoliId` INT, IN `Title` VARCHAR(50), IN `HolidayDate` DATE)   BEGIN 
UPDATE holidays as h SET h.Title = Title ,h.Holiday_Date = HolidayDate, h.updated_by = 1 ,h.updated_on = CURRENT_TIMESTAMP WHERE h.RecId = HoliId AND h.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangePayRollInfo` (IN `PayRoll_Id` INT, IN `M_Deduction` INT, IN `M_Salary` INT, IN `Remarks` VARCHAR(255))   BEGIN 
UPDATE payroll as pr SET pr.M_Deducted = M_Deduction,pr.M_Salary = M_Salary ,pr.Remarks = Remarks,pr.updated_by = 1, pr.updated_on = CURRENT_TIMESTAMP WHERE pr.RecId = PayRoll_Id AND pr.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangePayScaleInfo` (IN `PaySca_Id` INT, IN `pay_name` VARCHAR(50))   BEGIN 
UPDATE pay_scale as ps SET ps.pay_name = pay_name, ps.updated_by = 1, ps.updated_on = CURRENT_TIMESTAMP WHERE ps.RecId = PaySca_Id AND ps.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangePermissionAssignInfo` (IN `PermAssi_Id` INT, IN `Role_Id` INT, IN `Permission_Id` INT)   BEGIN 
UPDATE permission_assign as pa SET pa.Role_Id = Role_Id, pa.Permission_Id = Permission_Id, pa.updated_by = 1, pa.updated_on = CURRENT_TIMESTAMP WHERE pa.RecId = PermAssi_Id AND pa.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangePermissionInfo` (IN `Perm_Id` INT, IN `permisssion_name` VARCHAR(50), IN `controller` VARCHAR(50), IN `action` VARCHAR(50), IN `method` VARCHAR(50))   BEGIN 
UPDATE permission as p SET p.permisssion_name = permisssion_name, p.controller = controller, p.action = action, p.method = method, p.updated_by = 1 , p.updated_on = CURRENT_TIMESTAMP WHERE p.RecId = Perm_Id AND p.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeRoleAssignInfo` (IN `RoleAssi_Id` INT, IN `Role_Id` INT, IN `User_Id` INT)   BEGIN
UPDATE role_assign as ra SET ra.Role_Id = Role_Id, ra.User_Id = User_Id, ra.updated_by = 1, ra.updated_on = CURRENT_TIMESTAMP WHERE ra.RecId = RoleAssi_Id AND ra.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeRoleInfo` (IN `Roles_Id` INT(10), IN `role_name` VARCHAR(50))   BEGIN
UPDATE role as r SET r.role_name = role_name, r.updated_by = 1, r.updated_on = CURRENT_TIMESTAMP WHERE r.RecId = Roles_Id AND r.isactive =1 ;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeShiftInfo` (IN `Shift_Id` INT, IN `shift_name` VARCHAR(50), IN `time_in` TIME, IN `time_out` TIME, IN `grace_time` TIME)   BEGIN 
UPDATE shift as s SET s.shift_name = shift_name, s.time_in = time_in, s.time_out = time_out, s.grace_time = grace_time, s.updated_by = 1, s.updated_on = CURRENT_TIMESTAMP WHERE s.RecId = Shift_Id AND s.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeUserInfo` (IN `UId` INT, IN `Role_Id` INT, IN `UserP_Id` INT, IN `username` VARCHAR(50), IN `password` VARCHAR(50))   BEGIN 
UPDATE user as u SET u.Role_Id = Role_Id, u.UserP_Id = UserP_Id, u.username = username, u.password = password, u.updated_by = 1, u.updated_on = CURRENT_TIMESTAMP WHERE u.RecId = UId AND u.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_ChangeUserProfileInfo` (IN `UpId` INT, IN `Designation_Id` INT, IN `Employee_Id` VARCHAR(50), IN `firstname` VARCHAR(50), IN `lastname` VARCHAR(50), IN `address` TEXT, IN `contact` INT, IN `gender` VARCHAR(10), IN `shift_id` INT, IN `payscale_id` INT, IN `salary` DOUBLE, IN `workingDays` INT)   BEGIN 
UPDATE user_profile as up SET up.Designation_Id = Designation_Id, up.Employee_Id = Employee_Id, up.firstname = firstname, up.lastname = lastname, up.address = address, up.contact = contact, up.gender = gender, up.shift_id = shift_id, up.payscale_id = payscale_id, up.salary = salary, up.workingDays = workingDays,up.updated_by = 1, up.updated_on = CURRENT_TIMESTAMP WHERE up.RecId = UpId AND up.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getAttendanceInfo` (IN `AtenId` INT)   BEGIN
SELECT a.RecId,a.User_Id,a.check_in,a.check_out,a.over_time,a.isactive,a.created_by,a.updated_by,a.created_on,a.updated_on FROM attendance as a JOIN user as u ON a.User_Id = u.RecId JOIN user as u1 ON a.created_by = u1.RecId JOIN user as u2 ON a.updated_by = u2.RecId WHERE a.RecId = AtenId AND a.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1 AND u2.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getDesignationInfo` ()   BEGIN 
SELECT d.RecId,d.designation_name FROM designation as d WHERE d.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getGenderInfo` ()   BEGIN 
SELECT g.RecId,g.Gender FROM tbl_gender as g WHERE g.isactive;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getHolidayInfo` ()   BEGIN 
SELECT h.RecId,h.Title,h.Holiday_Date FROM holidays as h WHERE h.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getPayRollInfo` (IN `PayRoll_Id` INT)   BEGIN
SELECT pr.RecId,pr.UserP_Id,pr.Designation_Id,pr.Shift_Id,pr.Pay_Id,pr.Deduction,pr.salary,pr.Total_Pay,pr.isactive,pr.created_by,pr.updated_by,pr.created_on,pr.updated_on FROM payroll as pr JOIN user_profile as up ON pr.UserP_Id = up.RecId JOIN designation as d ON pr.Designation_Id = d.RecId JOIN shift as s ON pr.Shift_Id = s.RecId JOIN pay_scale as ps ON pr.Pay_Id = ps.RecId JOIN user as u ON ps.created_by = u.RecId JOIN user as u1 ON ps.updated_by = u1.RecId WHERE pr.RecId =  PayRoll_Id AND ps.isactive = 1 AND up.isactive = 1 AND d.isactive = 1 AND s.isactive = 1 AND ps.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getPayScaleInfo` ()   BEGIN
/*SELECT ps.RecId,ps.pay_name,ps.isactive,ps.created_by,ps.updated_by,ps.created_on,ps.updated_on FROM pay_scale as ps  JOIN user as u ON ps.created_by = u.RecId JOIN user as u1 ON ps.updated_by = u1.RecId WHERE ps.RecId = PaySca_Id AND ps.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;*/
SELECT ps.RecId,ps.pay_name FROM pay_scale as ps WHERE  ps.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getPermissionAssignInfo` (IN `PermAssi_Id` INT)   BEGIN
SELECT pa.RecId,pa.Role_Id,pa.Permission_Id,pa.isactive,pa.created_by,pa.updated_by,pa.created_on,pa.updated_on FROM permission_assign as pa JOIN role as r ON pa.Role_Id = r.RecId JOIN permission as p ON pa.Permission_Id = p.RecId JOIN user as u ON pa.created_by = u.RecId JOIN user as u1 ON pa.updated_by = u1.RecId WHERE pa.RecId = PermAssi_Id AND pa.isactive = 1 AND r.isactive = 1 AND p.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getPermissionInfo` (IN `Perm_Id` INT)   BEGIN
SELECT p.RecId,p.permisssion_name,p.controller,p.action,p.parameters,p.method,p.icon,p.sort,p.parent_id,p.isactive,p.created_by,p.updated_by,p.created_on,p.updated_on FROM permission as p JOIN user as u ON p.created_by = u.RecId JOIN user as u1 ON p.updated_by = u1.RecId WHERE p.RecId = Perm_Id AND p.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getRoleInfo` ()   BEGIN
/*SELECT r.RecId,r.role_name,r.isactive,r.created_by,r.updated_by,r.created_on,r.updated_on FROM role as r JOIN user as u ON r.created_by = u.RecId JOIN user as u1 ON r.updated_by = u1.RecId WHERE r.RecId = Roles_Id AND r.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;*/
SELECT r.RecId,r.role_name FROM role as r WHERE isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getShiftInfo` ()   BEGIN
SELECT RecId ,shift_name FROM shift WHERE isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getUserInfo` (IN `UId` INT)   BEGIN
   SELECT u.RecId,u.Role_Id,u.UserP_Id,u.username,u.password,u.isactive,u.created_by,u.updated_by,u.created_on,u.updated_on FROM user as u LEFT JOIN role as r ON u.Role_Id = r.RecId JOIN user_profile as up ON u.UserP_Id = up.RecId WHERE u.RecId = UId AND u.isactive = 1 AND r.isactive = 1 AND up.isactive = 1; 
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getUserLoginInfo` (IN `username` VARCHAR(4), IN `password` VARCHAR(8))   BEGIN
SELECT * FROM user as u JOIN user_profile as up ON u.UserP_Id = up.RecId WHERE u.isactive = 1 AND up.isactive = 1 AND u.username = username AND u.password = password;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_getUserProfileInfo` (IN `UpId` INT)   BEGIN
SELECT up.RecId,up.Designation_Id,up.Employee_Id,up.firstname,up.lastname,up.address,up.contact,up.gender,up.shift_id,up.payscale_id,up.salary,up.Advance,up.isactive,up.created_by,up.updated_by,up.created_on,up.updated_on FROM user_profile as up JOIN designation as d ON up.Designation_Id = d.RecId JOIN shift as s ON up.shift_id = s.RecId JOIN pay_scale as p  ON up.payscale_id = p.RecId WHERE up.RecId = UpId AND up.isactive = 1 AND d.isactive = 1 AND s.isactive = 1 AND p.isactive = 1;  
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertAttendanceInfo` (IN `Employee_Id` INT, IN `CheakIn` DATETIME, IN `CheakOut` DATETIME, IN `over_time` TIME)   BEGIN
INSERT INTO attendance(Employee_Id,check_in,check_out,over_time,created_by,created_on)VALUES(Employee_Id,CheckIn,CheckOut,over_time,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertDesignationInfo` (IN `Designame` VARCHAR(50))   BEGIN
INSERT INTO designation(designation_name,created_by,created_on)VALUES(Designame,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertPayRollInfo` (IN `UPId` INT, IN `DesigId` INT, IN `SId` INT, IN `PayId` INT, IN `Deduc` DOUBLE, IN `Salary` DOUBLE, IN `TotalPay` INT)   BEGIN
INSERT INTO payroll(UserP_Id,Designation_Id,Shift_Id,Pay_Id,Deduction,salary,Total_Pay,created_by,created_on)VALUES(UPId,DesigId,SId,PayId,Deduc,Salary,TotalPay,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertPayScaleInfo` (IN `Payname` VARCHAR(50))   BEGIN
INSERT INTO pay_scale(pay_name,created_by,created_on)VALUES(Payname,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertPermissionAssignInfo` (IN `RId` INT, IN `PermId` INT)   BEGIN
INSERT INTO permission_assign(Role_Id,Permission_Id,created_by,created_on)VALUES(RId,PermId,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertPermissionInfo` (IN `Pname` VARCHAR(50), IN `control` VARCHAR(50), IN `Actin` VARCHAR(50), IN `Pmeter` VARCHAR(50), IN `Meth` VARCHAR(50), IN `Icon` VARCHAR(50), IN `Sort` INT, IN `PrnId` INT)   BEGIN
INSERT INTO permission(permisssion_name,controller,action,parameters,method,icon,sort,parent_id,created_by,created_on) VALUES (Pname,control,Actin,Pmeter,Meth,Icon,Sort,PrnId,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertRoleAssignInfo` (IN `RId` INT, IN `UId` INT)   BEGIN
INSERT INTO role_assign(Role_Id,User_Id,created_by,created_on)VALUES(RId,UId,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertRoleInfo` (IN `roll_name` VARCHAR(50))   BEGIN
INSERT INTO role (role_name, created_by,created_on) VALUES (roll_name,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertShiftInfo` (IN `Sname` VARCHAR(50), IN `timeIn` TIME, IN `TimeOut` TIME, IN `GraceTime` TIME)   BEGIN
INSERT INTO shift(shift_name,time_in,time_out,grace_time,created_by,created_on)VALUES(Sname,timeIn,TimeOut,GraceTime,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertUserInfo` (IN `RId` INT(10), IN `UPId` INT, IN `Uname` VARCHAR(50), IN `Pass` VARCHAR(50))   BEGIN
INSERT INTO user(Role_Id,UserP_Id,username,password,created_by,created_on)VALUES(RId,UPId,Uname,Pass,1,CURRENT_TIMESTAMP);
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_InsertUserProfileInfo` (IN `EmpID` VARCHAR(50), IN `DesID` INT, IN `PayId` INT, IN `ShiftID` INT, IN `Fname` VARCHAR(50), IN `Lname` VARCHAR(50), IN `Sex` INT(10), IN `Home` TEXT, IN `Phone` INT, IN `Salary` DOUBLE, IN `WorkingDays` INT, IN `Cheak_value` BOOLEAN, IN `RId` INT, IN `Uname` VARCHAR(50), IN `Pass` VARCHAR(50))   BEGIN
INSERT INTO user_profile(Designation_Id,Employee_Id,firstname,lastname,address,contact,gender,shift_id,payscale_id ,salary,workingDays,created_by,created_on,Cheak_value)VALUES(DesID,EmpID,Fname,Lname,Home,Phone,Sex,ShiftID,PayId,Salary,WorkingDays,1,CURRENT_TIMESTAMP,Cheak_value);
 
	IF Cheak_value THEN
        INSERT INTO user (Role_Id, username, password, created_by, created_on,UserP_Id)
        SELECT RId , Uname, Pass, 1, CURRENT_TIMESTAMP,LAST_INSERT_ID()
        WHERE Cheak_value = 1;
	END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectAttendanceInfo` ()   SELECT
    a.Employee_Id,
    CONCAT(up.firstname,' ',up.lastname ) as PersonName,
    TIME_FORMAT(TIME(a.check_in), '%r') AS Check_In,
    a.check_in_date AS Check_In_Date,
    TIME_FORMAT(TIME(a.check_out), '%r') AS Check_Out,
    s.shift_name AS Shift_Name,
    -- a.over_time AS Over_Time,
    CASE
        WHEN TIME(a.check_in) > TIME(s.time_in) THEN TIMEDIFF(TIME(a.check_in), TIME(s.time_in))
        ELSE '00:00:00'  -- Zero if Earlier Departure
    END AS Late_Coming,
     CASE
        WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out),time(s.time_out))
        ELSE '00:00:00'  -- Zero if Earlier Departure
    END AS Over_Time,
    CASE
        WHEN TIME(a.check_in) <= TIME(s.time_in) THEN TIMEDIFF(TIME(s.time_in), TIME(a.check_in))
        ELSE '00:00:00'  -- Zero if No Earlier Departure
    END AS Earlier_Arrival,
  /*  CASE WHEN time(a.check_out) < time(s.time_out) THEN timediff((concat(a.check_in_date,' ',time(s.time_out))),a.check_out) ELSE '-' END As Earlier_Departure,*/
    CASE
        WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Late'
        WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Absent'
        ELSE 'On Time'
    END AS Status
FROM
    attendance AS a
JOIN
    user_profile AS up ON up.Employee_Id = a.Employee_Id
JOIN
    shift AS s ON up.shift_id = s.RecId
WHERE
    a.isactive = 1 AND s.isactive = 1 AND up.isactive = 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectDesignationInfo` (IN `Desig_Id` INT)   BEGIN
IF Desig_Id != 0 THEN
SELECT d.RecId,d.designation_name FROM designation as d WHERE d.RecId = Desig_Id AND d.isactive = 1;
ELSE
SELECT d.RecId,d.designation_name FROM designation as d WHERE d.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectHolidayInfo` (IN `HoliId` INT)   BEGIN
IF HoliId != 0 THEN
SELECT h.RecId,h.Title,h.Holiday_Date FROM holidays as h WHERE h.RecId = HoliId AND h.isactive = 1;
ELSE
SELECT h.RecId,h.Title,h.Holiday_Date FROM holidays as h WHERE h.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectPayRollInfo` ()   BEGIN
-- 6 days emp==========================
SET @SundayOff = (SELECT COUNT(date_field) FROM ( SELECT MAKEDATE(YEAR(NOW()),1) + INTERVAL (MONTH(NOW())-1) MONTH + INTERVAL daynum DAY date_field FROM ( SELECT t*10+u daynum FROM (SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) A, (SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) B ORDER BY daynum ) AA ) AAA WHERE MONTH(date_field) = MONTH(NOW()) and DAYOFWEEK(date_field) != 1 ORDER BY 1 ASC);
-- 5 days emp==========================
SET @SatSunOff = (SELECT COUNT(date_field) FROM ( SELECT MAKEDATE(YEAR(NOW()),1) + INTERVAL (MONTH(NOW())-1) MONTH + INTERVAL daynum DAY date_field FROM ( SELECT t*10+u daynum FROM (SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) A, (SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) B ORDER BY daynum ) AA ) AAA WHERE MONTH(date_field) = MONTH(NOW()) and DAYOFWEEK(date_field) not in (1,7) ORDER BY 1 ASC);

SELECT
    LPAD(up.Employee_Id, 6, '0') AS EMPID,
    CONCAT(up.firstname, ' ', up.lastname) AS EMPName,
    d.designation_name AS Designation,
    s.shift_name AS Shift,
    TIME(s.time_in) AS TimeIn,
    TIME(s.time_out) AS TimeOut,
    up.salary,
    (SystemWorkingDays - AttendedDays) AS Absent,
    NoOfLates AS TotalLate,
    FLOOR(DeductedDaysBecauseOfLateArrival) AS DeductionDays,
    FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival)) AS LateDeduction,
    FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * (SystemWorkingDays - AttendedDays)) AS AbsentDeduction,
    FLOOR(up.salary-FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE)))*FLOOR(DeductedDaysBecauseOfLateArrival))-      FLOOR((up.salary/DAY(LAST_DAY(CURRENT_DATE)))*(SystemWorkingDays - AttendedDays))) AS Net_Salary
FROM (
    SELECT
        @SatSunOff AS SatSunOff,
        @SundayOff AS SunOff,
        CASE WHEN up.workingDays = 5 THEN @SundayOff ELSE @SatSunOff END AS SystemWorkingDays,
        up.Employee_Id AS EMPID,
        COUNT(a.check_in_date) AS AttendedDays,
        SUM(CASE 
            WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
            THEN 0 
            ELSE 
                CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
        END) / 3 AS DeductedDaysBecauseOfLateArrival,
        SUM(CASE 
            WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
            THEN 0 
            ELSE 
                CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
        END) AS NoOfLates
    FROM
        attendance a
    JOIN user_profile up ON up.Employee_Id = a.Employee_Id 
    JOIN shift s ON s.RecId = up.shift_id
    JOIN designation d ON d.RecId = up.Designation_Id
    WHERE a.isactive = 1
    GROUP BY up.Employee_Id
) AS a
JOIN user_profile up ON up.Employee_Id = a.EMPID 
JOIN shift s ON s.RecId = up.shift_id
JOIN designation d ON d.RecId = up.Designation_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectPayScaleInfo` (IN `PaySca_Id` INT)   BEGIN
IF PaySca_Id != 0 THEN
SELECT ps.RecId,ps.pay_name FROM pay_scale as ps WHERE ps.RecId = PaySca_Id AND ps.isactive = 1; 
ELSE
SELECT ps.RecId,ps.pay_name FROM pay_scale as ps WHERE ps.isactive = 1; 
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectPermissionAssignInfo` (IN `PermAssi_Id` INT)   BEGIN
IF PermAssi_Id != 0 THEN
SELECT pa.RecId,pa.Role_Id,pa.Permission_Id FROM permission_assign as pa WHERE pa.RecId = PermAssi_Id AND pa.isactive = 1;
ELSE
SELECT pa.RecId,pa.Role_Id,pa.Permission_Id FROM permission_assign as pa WHERE pa.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectPermissionInfo` (IN `Perm_Id` INT)   BEGIN
IF Perm_Id != 0 THEN
SELECT p.RecId,p.permisssion_name,p.controller,p.action,p.parameters,p.method,p.icon,p.sort,p.parent_id FROM permission as p WHERE p.RecId = Perm_Id AND p.isactive = 1;
ELSE 
SELECT p.RecId,p.permisssion_name,p.controller,p.action,p.parameters,p.method,p.icon,p.sort,p.parent_id FROM permission as p WHERE p.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectRoleAssignInfo` (IN `RoleAssi_Id` INT)   BEGIN
IF RoleAssi_Id != 0 THEN
SELECT ra.RecId,ra.Role_Id,ra.User_Id FROM role_assign as ra WHERE ra.RecId = RoleAssi_Id AND ra.isactive = 1;
ELSE
SELECT ra.RecId,ra.Role_Id,ra.User_Id FROM role_assign as ra WHERE ra.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectRoleInfo` (IN `Roles_Id` INT)   BEGIN
    IF Roles_Id != 0 THEN
        SELECT r.RecId, r.role_name
        FROM role as r
        WHERE r.isactive = 1
        AND r.RecId = Roles_Id;
    ELSE
        SELECT r.RecId, r.role_name
        FROM role as r
        WHERE r.isactive = 1;
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectShiftInfo` (IN `Shift_Id` INT)   BEGIN
IF Shift_Id != 0 THEN
SELECT s.RecId,s.shift_name,s.time_in,s.time_out,s.grace_time FROM shift as s WHERE s.RecId = Shift_Id AND s.isactive = 1;
ELSE
SELECT s.RecId,s.shift_name,s.time_in,s.time_out,s.grace_time FROM shift as s WHERE s.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectUserInfo` (IN `UId` INT)   BEGIN
IF UId != 0 THEN
SELECT u.RecId,u.Role_Id,u.UserP_Id,u.username,u.password FROM user as u WHERE u.RecId = UId AND u.isactive = 1;
ELSE
SELECT u.RecId,u.Role_Id,u.UserP_Id,u.username,u.password FROM user as u WHERE u.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_SelectUserProfileInfo` (IN `UpId` INT)   BEGIN
IF UpId != 0 THEN 
SELECT up.RecId,up.Employee_Id,d.designation_name,ps.pay_name,s.shift_name,CONCAT(up.firstname,' ',up.lastname ) as PersonName,g.Gender,up.address,up.contact,up.salary,up.workingDays
FROM user_profile as up JOIN designation as d On up.Designation_Id = d.RecId JOIN pay_scale as ps ON up.payscale_id = ps.recId JOIN shift as s ON up.shift_id = s.RecId  jOIN tbl_gender as g ON up.gender = g.RecId WHERE up.isactive = 1 AND d.isactive = 1 AND ps.isactive = 1 AND s.isactive = 1 AND g.isactive = 1 AND up.RecId = UpId; 
-- SELECT up.RecId,up.Designation_Id,up.Employee_Id,up.firstname,up.lastname,up.address,up.contact,up.gender,up.shift_id,up.payscale_id,up.salary,up.Advance FROM user_profile as up WHERE up.RecId = UpId AND up.isactive = 1; 
ELSE
SELECT up.RecId,up.Employee_Id,d.designation_name,ps.pay_name,s.shift_name,CONCAT(up.firstname,' ',up.lastname ) as PersonName,g.Gender,up.address,up.contact,up.salary,up.workingDays
FROM user_profile as up JOIN designation as d On up.Designation_Id = d.RecId JOIN pay_scale as ps ON up.payscale_id = ps.recId JOIN shift as s ON up.shift_id = s.RecId  jOIN tbl_gender as g ON up.gender = g.RecId WHERE up.isactive = 1 AND d.isactive = 1 AND ps.isactive = 1 AND s.isactive = 1 AND g.isactive = 1;
-- SELECT up.RecId,up.Designation_Id,up.Employee_Id,up.firstname,up.lastname,up.address,up.contact,up.gender,up.shift_id,up.payscale_id,up.salary,up.Advance FROM user_profile as up WHERE up.isactive = 1; 
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateAttendanceInfo` (IN `AtenId` INT)   BEGIN
UPDATE attendance as a SET a.isactive = 0,a.updated_on=CURRENT_TIMESTAMP WHERE a.RecId = AtenId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateDesignationInfo` (IN `Desig_Id` INT)   BEGIN 
UPDATE designation as d SET d.isactive = 0 ,d.updated_on = CURRENT_TIMESTAMP WHERE d.RecId = Desig_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateHolidayInfo` (IN `HoliId` INT)   BEGIN 
UPDATE holidays SET isactive = 0 WHERE RecId = HoliId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdatePayRollInfo` (IN `PayRoll_Id` INT)   BEGIN 
UPDATE payroll as pr SET pr.isactive = 0, pr.updated_on = CURRENT_TIMESTAMP WHERE pr.RecId = PayRoll_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdatePayScaleInfo` (IN `PaySca_Id` INT)   BEGIN 
 UPDATE pay_scale as ps SET ps.isactive = 0, ps.updated_on = CURRENT_TIMESTAMP WHERE ps.RecId = PaySca_Id;
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdatePermissionAssignInfo` (IN `PermAssi_Id` INT)   BEGIN
UPDATE permission_assign as pa SET pa.isactive = 0,pa.updated_on = CURRENT_TIMESTAMP  WHERE pa.RecId = PermAssi_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdatePermissionInfo` (IN `Perm_Id` INT)   BEGIN 
UPDATE permission as p SET p.isactive = 0,p.updated_on = CURRENT_TIMESTAMP WHERE p.RecId = Perm_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateRoleInfo` (IN `Roles_Id` INT)   BEGIN
UPDATE role as r SET r.isactive = 0,r.updated_on = CURRENT_TIMESTAMP WHERE r.RecId = Roles_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateShiftInfo` (IN `Shift_Id` INT)   BEGIN 
UPDATE shift as s SET s.isactive = 0, s.updated_on = CURRENT_TIMESTAMP WHERE s.RecId = Shift_Id;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateUserInfo` (IN `UId` INT)   BEGIN 
UPDATE user as u SET u.isactive = 0, u.updated_on = CURRENT_TIMESTAMP WHERE u.RecId = UId;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `StrProc_UpdateUser_ProfileInfo` (IN `UPId` INT)   BEGIN
  UPDATE user_profile as up SET up.isactive = 0,up.updated_on = CURRENT_TIMESTAMP WHERE up.RecId = UPId;
 END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Temp_InsertPayrollData` ()   BEGIN
    DECLARE done INT DEFAULT 0;
    DECLARE emp_id INT;
    DECLARE desig_id INT;
    DECLARE shift_id INT;
    DECLARE emp_time_in datetime;
    DECLARE emp_time_out datetime;
    DECLARE emp_salary INT;
    DECLARE emp_absent INT;
    DECLARE emp_late INT;
    DECLARE emp_deducted_days INT;
    DECLARE emp_deduction INT;
    DECLARE emp_total_pay INT;

    -- Declare cursor for fetching data
    DECLARE cur CURSOR FOR 
 	-- SELECT Employee_Id, Designation_Id, Shift_Id, salary, absent, late, deducted_days, Deduction, Total_Pay FROM exampleTable 
    -- ___________________________________________________________________________________________________________________________________Talha/Abdullah Query Begin
    SELECT
    up.Employee_Id ,
    up.Designation_Id,
    up.Shift_Id,
    s.time_in ,
    s.time_out ,
    up.salary,
    (SystemWorkingDays - AttendedDays) AS absent,
    NoOfLates AS late,
    FLOOR(DeductedDaysBecauseOfLateArrival) AS deducted_days,
    (FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival))+
    FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * (SystemWorkingDays - AttendedDays))) AS Deduction,
    FLOOR(up.salary - FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * (SystemWorkingDays - AttendedDays))) AS Total_Pay
FROM (
    SELECT
        @SatSunOff AS SatSunOff,
        @SundayOff AS SunOff,
        CASE WHEN up.workingDays = 5 THEN @SundayOff ELSE @SatSunOff END AS SystemWorkingDays,
        up.Employee_Id AS EMPID,
        COUNT(a.check_in_date) AS AttendedDays,
        SUM(CASE 
            WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
            THEN 0 
            ELSE 
                CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
        END) / 3 AS DeductedDaysBecauseOfLateArrival,
        SUM(CASE 
            WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
            THEN 0 
            ELSE 
                CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
        END) AS NoOfLates
    FROM
        attendance a
    JOIN user_profile up ON up.Employee_Id = a.Employee_Id 
    JOIN shift s ON s.RecId = up.shift_id
    JOIN designation d ON d.RecId = up.Designation_Id
    WHERE a.isactive = 1
    GROUP BY up.Employee_Id
) AS a
JOIN user_profile up ON up.Employee_Id = a.EMPID 
JOIN shift s ON s.RecId = up.shift_id
JOIN designation d ON d.RecId = up.Designation_Id;
    -- ___________________________________________________________________________________________________________________________________Talha/Abdullah Query End
    
    
    

    -- Handlers for exceptions
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN cur;

    -- Loop through the cursor and insert data
    read_loop: LOOP
        FETCH cur INTO emp_id, desig_id,shift_id,emp_time_in,emp_time_out,emp_salary, emp_absent, emp_late, emp_deducted_days, emp_deduction, emp_total_pay;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Insert data into payroll table
        INSERT INTO payroll (Employee_Id, Designation_Id, Shift_Id, time_in, time_out, salary, absent, late, deducted_days, Deduction, Total_Pay)
        VALUES (emp_id, desig_id, shift_id,emp_time_in,emp_time_out,emp_salary, emp_absent, emp_late, emp_deducted_days, emp_deduction, emp_total_pay);
    END LOOP;

    -- Close the cursor
    CLOSE cur;

END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Temp_sp_PayrollGenerator` (IN `UserRecID` INT)   BEGIN
-- Calculate the number of days in the previous month (August)
SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

-- Check if records exist for the current month
SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));

IF (@isExist <= 0) THEN
    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) != 1
    ORDER BY 1 ASC);
    
    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) NOT IN (1, 7)
    ORDER BY 1 ASC);

    -- Insert data into payroll table
    INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, salary, deducted_days, late, absent, Deduction, M_Deducted, M_Salary, Total_Pay, created_by, updated_by)
    SELECT
        up.RecId AS EMPID,
        d.RecId,
        s.RecId AS Shift,
        pp.RecId,
        TIME(s.time_in) AS TimeIn,
        TIME(s.time_out) AS TimeOut,
        up.salary,
        FLOOR(DeductedDaysBecauseOfLateArrival) AS DeductionDays,
        NoOfLates AS TotalLate,
        (SystemWorkingDays - AttendedDays) AS Absent,  -- Calculate absent days as (SystemWorkingDays - AttendedDays)
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
            (FLOOR((up.salary / @DaysInAugust) * (@DaysInAugust - AttendedDays)))
        ) AS Deduction,
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
            (FLOOR((up.salary / @DaysInAugust) * (@DaysInAugust - AttendedDays)))
        ) AS MDeduction,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (@DaysInAugust - AttendedDays))) AS Net_Salary,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (@DaysInAugust - AttendedDays))) AS MSalary
    FROM (
        SELECT
            @SatSunOff AS SatSunOff,
            @SundayOff AS SunOff,
            CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
            up.Employee_Id AS EMPID,
            COUNT(a.check_in_date) AS AttendedDays,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
            END) / 3 AS DeductedDaysBecauseOfLateArrival,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
            END) AS _NoOfLates,
            FLOOR((SUM(CASE WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1' ELSE '0' END)) / 3) NoOfLates

        FROM
            attendance a
        JOIN user_profile up ON up.Employee_Id = a.Employee_Id 
        JOIN shift s ON s.RecId = up.shift_id
        JOIN designation d ON d.RecId = up.Designation_Id
        JOIN pay_scale pp ON pp.RecId = up.payscale_id
        WHERE a.isactive = 1
        GROUP BY up.Employee_Id
    ) AS a
    JOIN user_profile up ON up.Employee_Id = a.EMPID 
    JOIN shift s ON s.RecId = up.shift_id
    JOIN designation d ON d.RecId = up.Designation_Id
    JOIN pay_scale pp ON pp.RecId = up.payscale_id;
END IF;

-- Show Data
SELECT
    pr.RecId,
    CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
    d.designation_name,
    s.shift_name,
    ps.pay_name,
    TIME(s.time_in) time_in,
    TIME(s.time_out) time_out,
    pr.salary,
    pr.deducted_days,
    pr.late,
    pr.absent,
    pr.Deduction,
    pr.M_Deducted,
    pr.M_Salary,
    pr.Total_Pay,
    pr.updated_on
FROM payroll pr 
JOIN user_profile up ON up.RecId = pr.UserP_Id 
JOIN designation d ON d.RecId = pr.Designation_Id 
JOIN shift s ON s.RecId = pr.Shift_Id 
JOIN pay_scale ps ON ps.RecId = pr.Pay_Id 
WHERE MONTH(pr.created_on) = MONTH(NOW()) 
AND pr.isactive = 1
AND d.isactive = 1
AND s.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `TEMP_StrProc_SelectPayRollInfo` (IN `PayRoll_Id` INT)   BEGIN
IF PayRoll_Id != 0 THEN
SELECT pr.RecId,up.firstname,d.designation_name,s.shift_name,ps.pay_name,pr.Deduction,up.salary,pr.Total_Pay FROM payroll as pr JOIN user_profile as up ON pr.UserP_Id = up.RecId JOIN designation as d ON pr.Designation_Id = d.RecId JOIN shift as s ON pr.Shift_Id = s.RecId JOIN pay_scale as ps ON pr.Pay_Id = ps.RecId JOIN user as u ON ps.created_by = u.RecId JOIN user as u1 ON ps.updated_by = u1.RecId WHERE pr.RecId =  PayRoll_Id AND ps.isactive = 1 AND up.isactive = 1 AND d.isactive = 1 AND s.isactive = 1 AND ps.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;
ELSE
SELECT pr.RecId,up.firstname,d.designation_name,s.shift_name,ps.pay_name,pr.Deduction,up.salary,pr.Total_Pay FROM payroll as pr JOIN user_profile as up ON pr.UserP_Id = up.RecId JOIN designation as d ON pr.Designation_Id = d.RecId JOIN shift as s ON pr.Shift_Id = s.RecId JOIN pay_scale as ps ON pr.Pay_Id = ps.RecId JOIN user as u ON ps.created_by = u.RecId JOIN user as u1 ON ps.updated_by = u1.RecId WHERE ps.isactive = 1 AND up.isactive = 1 AND d.isactive = 1 AND s.isactive = 1 AND ps.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;
END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Test1_StrProc_SelectAttendanceInfo` ()   SELECT
    a.Employee_Id,
    CONCAT(up.firstname,' ',up.lastname) AS Person_Name,
    a.check_in AS Check_In,
    a.check_in_date AS Check_In_Date,
    a.check_out AS Check_Out,
    s.shift_name AS Shift_Name,
    CASE
        WHEN a.check_in > s.time_in THEN TIMEDIFF(a.check_in, s.time_in)
        ELSE '00:00:00'  -- Zero if Earlier Departure
    END AS Late_Coming,
    CASE
        WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out),time(s.time_out))
        ELSE '00:00:00'  -- Zero if Earlier Departure
    END AS Over_Time,
    CASE
        WHEN a.check_in <= s.time_in THEN TIMEDIFF(s.time_in, a.check_in)
        ELSE '00:00:00'  -- Zero if No Earlier Departure
    END AS Earlier_Departure,
    CASE
        WHEN a.check_in > ADDTIME(s.time_in, s.grace_time) AND a.check_in < ADDTIME(s.time_in, '04:00:00') THEN 'Late'
        WHEN a.check_in >= ADDTIME(s.time_in, '04:00:00') THEN 'Absent'
        ELSE 'On Time'
    END AS Status
FROM
    attendance AS a
JOIN
    user_profile AS up ON up.Employee_Id = a.Employee_Id
JOIN
    shift AS s ON up.shift_id = s.RecId
WHERE
    a.isactive = 1 AND s.isactive = 1 AND up.isactive = 1$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Test2_STR_GeneratePayRollInfo` (IN `UserRecID` INT)   BEGIN
-- Calculate the number of days in the previous month (August)
SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

-- Check if records exist for the current month
SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));

IF (@isExist <= 0) THEN
    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) != 1
    ORDER BY 1 ASC);
    
    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field) FROM (
        SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH + INTERVAL daynum DAY date_field
        FROM (
            SELECT t * 10 + u daynum
            FROM (
                SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3
            ) A,
            (
                SELECT 0 u UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4
                UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9
            ) B
            ORDER BY daynum
        ) AA
    ) AAA
    WHERE MONTH(date_field) = MONTH(NOW()) AND DAYOFWEEK(date_field) NOT IN (1, 7)
    ORDER BY 1 ASC);

    -- Insert data into payroll table
    INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, salary, deducted_days, late, absent, Deduction, M_Deducted, M_Salary, Total_Pay, created_by, updated_by)
    SELECT
        up.RecId AS EMPID,
        d.RecId,
        s.RecId AS Shift,
        pp.RecId,
        TIME(s.time_in) AS TimeIn,
        TIME(s.time_out) AS TimeOut,
        up.salary,
        FLOOR(DeductedDaysBecauseOfLateArrival) AS DeductionDays,
        NoOfLates AS TotalLate,
        (SystemWorkingDays - AttendedDays) AS Absent,  -- Calculate absent days as (SystemWorkingDays - AttendedDays)
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) + (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
        (
            (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) + (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS MDeduction,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
             ) AS Net_Salary,
        FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) - FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
             ) AS MSalary,
        UserRecID,
        UserRecID
    FROM (
        SELECT
            @SatSunOff AS SatSunOff,
            @SundayOff AS SunOff,
            CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
            up.Employee_Id AS EMPID,
            COUNT(a.check_in_date) AS AttendedDays,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1' ELSE '0' END
            END) / 3 AS DeductedDaysBecauseOfLateArrival,
            SUM(CASE 
                WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0 
                THEN 0 
                ELSE 
                    CASE WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time) THEN 1 ELSE 0 END
            END) AS _NoOfLates,
            FLOOR((SUM(CASE WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1' ELSE '0' END))) NoOfLates
        FROM
            attendance a
        JOIN user_profile up ON up.Employee_Id = a.Employee_Id 
        JOIN shift s ON s.RecId = up.shift_id
        JOIN designation d ON d.RecId = up.Designation_Id
        JOIN pay_scale pp ON pp.RecId = up.payscale_id
        WHERE a.isactive = 1
        GROUP BY up.Employee_Id
    ) AS a
    JOIN user_profile up ON up.Employee_Id = a.EMPID 
    JOIN shift s ON s.RecId = up.shift_id
    JOIN designation d ON d.RecId = up.Designation_Id
    JOIN pay_scale pp ON pp.RecId = up.payscale_id;
END IF;

-- Show Data
SELECT
    pr.RecId,
    CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
    d.designation_name,
    s.shift_name,
    ps.pay_name,
    TIME(s.time_in) time_in,
    TIME(s.time_out) time_out,
    pr.salary,
    pr.deducted_days,
    pr.late,
    pr.absent,
    pr.Deduction,
    pr.M_Deducted,
    pr.M_Salary,
    pr.Total_Pay,
    pr.updated_on
FROM payroll pr 
JOIN user_profile up ON up.RecId = pr.UserP_Id 
JOIN designation d ON d.RecId = pr.Designation_Id 
JOIN shift s ON s.RecId = pr.Shift_Id 
JOIN pay_scale ps ON ps.RecId = pr.Pay_Id 
WHERE MONTH(pr.created_on) = MONTH(NOW()) 
AND pr.isactive = 1
AND d.isactive = 1
AND s.isactive = 1;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `Test_For_Roles` (IN `Roles_Id` INT)   BEGIN
    IF Roles_Id != 0 THEN
        SELECT r.RecId, r.role_name, r.isactive, r.created_by, r.updated_by, r.created_on, r.updated_on
        FROM role as r
        JOIN user as u ON r.created_by = u.RecId
        JOIN user as u1 ON r.updated_by = u1.RecId
        WHERE r.isactive = 1 
        AND u.isactive = 1 
        AND u1.isactive = 1 
        AND r.RecId = Roles_Id;
    ELSE
        SELECT r.RecId, r.role_name, r.isactive, r.created_by, r.updated_by, r.created_on, r.updated_on
        FROM role as r
        JOIN user as u ON r.created_by = u.RecId
        JOIN user as u1 ON r.updated_by = u1.RecId
        WHERE r.isactive = 1 
        AND u.isactive = 1 
        AND u1.isactive = 1;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance` (
  `RecId` int(10) NOT NULL,
  `Employee_Id` int(11) NOT NULL,
  `DeviceNo` int(11) DEFAULT NULL,
  `check_in` datetime NOT NULL,
  `check_in_date` date NOT NULL,
  `check_out` datetime NOT NULL,
  `over_time` time NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`RecId`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 14, NULL, '2023-08-01 11:30:00', '2023-08-01', '2023-08-01 22:00:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(2, 14, NULL, '2023-08-02 11:30:00', '2023-08-02', '2023-08-02 21:53:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(3, 14, NULL, '2023-08-03 12:12:47', '2023-08-03', '2023-08-03 21:06:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(4, 14, NULL, '2023-08-04 12:14:33', '2023-08-04', '2023-08-04 21:08:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(5, 14, NULL, '2023-08-05 12:07:52', '2023-08-05', '2023-08-05 22:20:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(6, 14, NULL, '2023-08-07 12:08:44', '2023-08-07', '2023-08-07 22:12:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(7, 14, NULL, '2023-08-08 12:09:00', '2023-08-08', '2023-08-08 21:53:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(8, 14, NULL, '2023-08-09 12:08:00', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(9, 14, NULL, '2023-08-10 12:09:54', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(10, 14, NULL, '2023-08-11 12:25:37', '2023-08-11', '2023-08-11 23:27:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(11, 14, NULL, '2023-08-12 12:24:13', '2023-08-12', '2023-08-12 22:47:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(12, 14, NULL, '2023-08-15 12:05:14', '2023-08-15', '2023-08-15 21:43:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(13, 14, NULL, '2023-08-16 12:05:25', '2023-08-16', '2023-08-16 21:18:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(14, 14, NULL, '2023-08-17 12:03:57', '2023-08-17', '2023-08-18 01:26:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(15, 14, NULL, '2023-08-18 12:10:56', '2023-08-18', '2023-08-18 20:58:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(16, 14, NULL, '2023-08-19 11:15:29', '2023-08-19', '2023-08-19 21:01:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(17, 14, NULL, '2023-08-21 11:55:34', '2023-08-21', '2023-08-21 21:41:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(18, 14, NULL, '2023-08-22 12:05:39', '2023-08-22', '2023-08-22 20:51:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(19, 14, NULL, '2023-08-23 12:11:20', '2023-08-23', '2023-08-23 20:53:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(20, 14, NULL, '2023-08-24 12:02:24', '2023-08-24', '2023-08-24 20:55:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(21, 14, NULL, '2023-08-25 12:00:51', '2023-08-25', '2023-08-25 20:51:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(22, 14, NULL, '2023-08-26 11:49:48', '2023-08-26', '2023-08-26 21:32:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(23, 14, NULL, '2023-08-28 12:00:58', '2023-08-28', '2023-08-28 22:05:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(24, 14, NULL, '2023-08-29 11:53:16', '2023-08-29', '2023-08-29 21:22:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(25, 14, NULL, '2023-08-30 11:55:57', '2023-08-30', '2023-08-30 21:21:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(26, 14, NULL, '2023-08-31 12:04:36', '2023-08-31', '2023-08-31 21:19:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(27, 16, NULL, '2023-08-01 11:11:20', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(28, 16, NULL, '2023-08-03 11:03:45', '2023-08-02', '2023-08-02 21:13:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(29, 16, NULL, '2023-08-03 11:03:45', '2023-08-03', '2023-08-03 21:15:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(30, 16, NULL, '2023-08-04 11:29:00', '2023-08-04', '2023-08-04 21:05:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(31, 16, NULL, '2023-08-05 11:19:08', '2023-08-05', '2023-08-05 21:46:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(32, 16, NULL, '2023-08-07 11:32:57', '2023-08-07', '2023-08-07 21:16:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(33, 16, NULL, '2023-08-08 11:17:28', '2023-08-08', '2023-08-08 22:14:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(34, 16, NULL, '2023-08-09 11:05:01', '2023-08-09', '2023-08-09 21:01:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(35, 16, NULL, '2023-08-10 11:17:57', '2023-08-10', '2023-08-10 21:57:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(36, 16, NULL, '2023-08-11 11:19:11', '2023-08-11', '2023-08-11 22:06:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(37, 16, NULL, '2023-08-12 10:55:38', '2023-08-12', '2023-08-12 20:59:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(38, 16, NULL, '2023-08-15 11:29:11', '2023-08-15', '2023-08-15 21:56:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(39, 16, NULL, '2023-08-16 11:29:39', '2023-08-16', '2023-08-16 21:48:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(40, 16, NULL, '2023-08-17 11:31:54', '2023-08-17', '2023-08-17 21:23:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(41, 16, NULL, '2023-08-18 11:15:34', '2023-08-18', '2023-08-18 21:36:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(42, 16, NULL, '2023-08-19 11:06:56', '2023-08-19', '2023-08-19 21:04:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(43, 16, NULL, '2023-08-21 11:14:28', '2023-08-21', '2023-08-21 22:04:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(44, 16, NULL, '2023-08-22 11:17:18', '2023-08-22', '2023-08-22 21:20:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(45, 16, NULL, '2023-08-23 11:12:45', '2023-08-23', '2023-08-23 21:40:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(46, 16, NULL, '2023-08-24 11:06:49', '2023-08-24', '2023-08-24 21:23:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(47, 16, NULL, '2023-08-25 13:42:28', '2023-08-25', '2023-08-25 21:52:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(48, 16, NULL, '2023-08-26 11:10:49', '2023-08-26', '2023-08-26 21:11:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(49, 16, NULL, '2023-08-28 11:16:49', '2023-08-28', '2023-08-28 22:08:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(50, 16, NULL, '2023-08-29 11:10:22', '2023-08-29', '2023-08-29 21:25:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(51, 16, NULL, '2023-08-30 11:18:12', '2023-08-30', '2023-08-30 21:48:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(52, 16, NULL, '2023-08-31 11:10:05', '2023-08-31', '2023-08-31 21:52:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(53, 17, NULL, '2023-08-01 11:58:58', '2023-08-01', '2023-08-01 23:25:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(54, 17, NULL, '2023-08-02 12:22:39', '2023-08-02', '2023-08-02 22:17:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(55, 17, NULL, '2023-08-03 11:50:56', '2023-08-03', '2023-08-03 22:56:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(56, 17, NULL, '2023-08-04 12:19:41', '2023-08-04', '2023-08-04 21:52:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(57, 17, NULL, '2023-08-05 12:03:14', '2023-08-05', '2023-08-05 23:06:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(58, 17, NULL, '2023-08-07 11:48:18', '2023-08-07', '2023-08-07 23:21:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(59, 17, NULL, '2023-08-08 12:16:01', '2023-08-08', '2023-08-08 22:26:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(60, 17, NULL, '2023-08-09 12:04:10', '2023-08-09', '2023-08-09 23:06:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(61, 17, NULL, '2023-08-10 11:53:45', '2023-08-10', '2023-08-10 22:01:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(62, 17, NULL, '2023-08-11 12:46:28', '2023-08-11', '2023-08-11 22:27:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(63, 17, NULL, '2023-08-12 12:14:19', '2023-08-12', '2023-08-12 23:43:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(64, 17, NULL, '2023-08-15 12:39:12', '2023-08-15', '2023-08-15 22:24:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(65, 17, NULL, '2023-08-16 12:15:49', '2023-08-16', '2023-08-16 22:19:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(66, 17, NULL, '2023-08-17 12:14:25', '2023-08-17', '2023-08-17 20:33:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(67, 17, NULL, '2023-08-18 12:17:20', '2023-08-18', '2023-08-18 21:41:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(68, 17, NULL, '2023-08-19 11:52:55', '2023-08-19', '2023-08-19 21:23:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(69, 17, NULL, '2023-08-21 11:58:59', '2023-08-21', '2023-08-21 21:48:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(70, 17, NULL, '2023-08-22 12:00:29', '2023-08-22', '2023-08-22 21:58:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(71, 17, NULL, '2023-08-23 12:03:02', '2023-08-23', '2023-08-23 22:04:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(72, 17, NULL, '2023-08-24 12:01:02', '2023-08-24', '2023-08-24 21:54:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(73, 17, NULL, '2023-08-25 12:44:49', '2023-08-25', '2023-08-25 21:58:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(74, 17, NULL, '2023-08-26 12:13:37', '2023-08-26', '2023-08-26 22:11:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(75, 17, NULL, '2023-08-28 12:16:32', '2023-08-28', '2023-08-28 23:26:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(76, 17, NULL, '2023-08-29 12:16:19', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(77, 17, NULL, '2023-08-30 00:10:28', '2023-08-30', '2023-08-30 22:42:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(78, 17, NULL, '2023-08-31 11:57:50', '2023-08-31', '2023-09-01 01:41:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(79, 18, NULL, '2023-08-01 10:41:59', '2023-08-01', '2023-08-01 20:46:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(80, 18, NULL, '2023-08-02 10:44:38', '2023-08-02', '2023-08-02 20:44:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(81, 18, NULL, '2023-08-03 10:55:18', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(82, 18, NULL, '2023-08-04 10:42:16', '2023-08-04', '2023-08-04 20:51:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(83, 18, NULL, '2023-08-05 10:47:07', '2023-08-05', '2023-08-05 20:29:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(84, 18, NULL, '2023-08-07 10:41:57', '2023-08-07', '2023-08-07 20:44:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(85, 18, NULL, '2023-08-08 10:53:17', '2023-08-08', '2023-08-08 20:51:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(86, 18, NULL, '2023-08-09 10:41:42', '2023-08-09', '2023-08-09 20:43:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(87, 18, NULL, '2023-08-10 10:38:54', '2023-08-10', '2023-08-10 20:43:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(88, 18, NULL, '2023-08-11 10:41:25', '2023-08-11', '2023-08-11 20:40:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(89, 18, NULL, '2023-08-12 10:45:24', '2023-08-12', '2023-08-12 20:37:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(90, 18, NULL, '2023-08-15 10:45:32', '2023-08-15', '2023-08-15 20:46:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(91, 18, NULL, '2023-08-16 10:35:39', '2023-08-16', '2023-08-16 20:40:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(92, 18, NULL, '2023-08-17 10:46:23', '2023-08-17', '2023-08-17 20:34:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(93, 18, NULL, '2023-08-18 10:49:24', '2023-08-18', '2023-08-18 20:46:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(94, 18, NULL, '2023-08-19 10:31:55', '2023-08-19', '2023-08-19 20:39:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(95, 18, NULL, '2023-08-21 10:40:02', '2023-08-21', '2023-08-21 20:46:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(96, 18, NULL, '2023-08-22 10:42:44', '2023-08-22', '2023-08-22 20:47:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(97, 18, NULL, '2023-08-23 10:49:12', '2023-08-23', '2023-08-23 20:46:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(98, 18, NULL, '2023-08-24 10:48:55', '2023-08-24', '2023-08-24 20:42:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(99, 18, NULL, '2023-08-25 10:40:47', '2023-08-25', '2023-08-25 20:49:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(100, 18, NULL, '2023-08-26 10:43:46', '2023-08-26', '2023-08-26 20:41:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(101, 18, NULL, '2023-08-28 10:44:29', '2023-08-28', '2023-08-28 20:51:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(102, 18, NULL, '2023-08-29 10:50:14', '2023-08-29', '2023-08-29 20:47:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(103, 18, NULL, '2023-08-30 10:47:30', '2023-08-30', '2023-08-30 20:49:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(104, 18, NULL, '2023-08-31 10:43:28', '2023-08-31', '2023-08-31 20:39:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(105, 19, NULL, '2023-08-01 11:49:16', '2023-08-01', '2023-08-01 21:40:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(106, 19, NULL, '2023-08-02 11:36:17', '2023-08-02', '2023-08-02 21:13:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(107, 19, NULL, '2023-08-03 11:30:08', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(108, 19, NULL, '2023-08-04 11:24:21', '2023-08-04', '2023-08-04 21:05:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(109, 19, NULL, '2023-08-05 11:27:00', '2023-08-05', '2023-08-05 21:46:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(110, 19, NULL, '2023-08-07 11:42:11', '2023-08-07', '2023-08-07 21:16:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(111, 19, NULL, '2023-08-08 11:45:44', '2023-08-08', '2023-08-08 22:22:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(112, 19, NULL, '2023-08-09 11:39:26', '2023-08-09', '2023-08-09 21:06:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(113, 19, NULL, '2023-08-10 11:40:44', '2023-08-10', '2023-08-11 11:46:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(114, 19, NULL, '2023-08-11 11:46:39', '2023-08-11', '2023-08-11 22:07:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(115, 19, NULL, '2023-08-15 11:39:22', '2023-08-15', '2023-08-15 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(116, 19, NULL, '2023-08-16 11:53:37', '2023-08-16', '2023-08-16 21:48:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(117, 19, NULL, '2023-08-17 11:38:35', '2023-08-17', '2023-08-17 21:36:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(118, 19, NULL, '2023-08-18 11:43:31', '2023-08-18', '2023-08-18 21:41:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(119, 19, NULL, '2023-08-19 11:25:00', '2023-08-19', '2023-08-19 21:04:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(120, 19, NULL, '2023-08-21 11:40:02', '2023-08-21', '2023-08-21 22:04:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(121, 19, NULL, '2023-08-22 11:27:15', '2023-08-22', '2023-08-22 21:19:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(122, 19, NULL, '2023-08-23 10:52:50', '2023-08-23', '2023-08-23 21:44:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(123, 19, NULL, '2023-08-24 11:38:54', '2023-08-24', '2023-08-24 21:50:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(124, 19, NULL, '2023-08-25 11:12:57', '2023-08-25', '2023-08-25 21:53:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(125, 19, NULL, '2023-08-26 11:49:13', '2023-08-26', '2023-08-26 21:11:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(126, 19, NULL, '2023-08-28 11:40:30', '2023-08-28', '2023-08-28 22:09:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(127, 19, NULL, '2023-08-29 11:28:07', '2023-08-29', '2023-08-29 21:26:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(128, 19, NULL, '2023-08-30 11:38:35', '2023-08-30', '2023-08-30 21:49:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(129, 19, NULL, '2023-08-31 11:21:56', '2023-08-31', '2023-08-31 21:52:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(130, 20, NULL, '2023-08-01 11:30:00', '2023-08-01', '2023-08-01 20:46:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(131, 20, NULL, '2023-08-02 14:35:39', '2023-08-02', '2023-08-02 20:56:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(132, 20, NULL, '2023-08-03 14:53:05', '2023-08-03', '2023-08-03 20:47:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(133, 20, NULL, '2023-08-04 11:47:21', '2023-08-04', '2023-08-04 20:39:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(134, 20, NULL, '2023-08-05 12:07:04', '2023-08-05', '2023-08-05 21:23:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(135, 20, NULL, '2023-08-07 15:00:27', '2023-08-07', '2023-08-07 21:25:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(136, 20, NULL, '2023-08-08 14:42:18', '2023-08-08', '2023-08-08 21:35:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(137, 20, NULL, '2023-08-09 15:01:53', '2023-08-09', '2023-08-09 21:43:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(138, 20, NULL, '2023-08-10 14:57:07', '2023-08-10', '2023-08-10 21:05:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(139, 20, NULL, '2023-08-11 11:57:35', '2023-08-11', '2023-08-11 20:42:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(140, 20, NULL, '2023-08-12 12:00:49', '2023-08-12', '2023-08-12 22:03:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(141, 20, NULL, '2023-08-15 14:51:25', '2023-08-15', '2023-08-15 21:08:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(142, 20, NULL, '2023-08-16 14:48:11', '2023-08-16', '2023-08-16 21:04:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(143, 20, NULL, '2023-08-17 14:40:50', '2023-08-17', '2023-08-17 20:42:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(144, 20, NULL, '2023-08-18 11:48:15', '2023-08-18', '2023-08-18 20:51:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(145, 20, NULL, '2023-08-19 11:53:13', '2023-08-19', '2023-08-19 20:42:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(146, 20, NULL, '2023-08-21 14:44:54', '2023-08-21', '2023-08-21 20:58:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(147, 20, NULL, '2023-08-22 12:30:46', '2023-08-22', '2023-08-22 20:47:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(148, 20, NULL, '2023-08-23 11:59:11', '2023-08-23', '2023-08-23 20:49:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(149, 20, NULL, '2023-08-24 12:20:10', '2023-08-24', '2023-08-24 20:40:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(150, 20, NULL, '2023-08-25 12:07:24', '2023-08-25', '2023-08-25 20:55:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(151, 20, NULL, '2023-08-26 11:42:28', '2023-08-26', '2023-08-26 20:56:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(152, 20, NULL, '2023-08-28 12:36:59', '2023-08-28', '2023-08-28 20:52:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(153, 20, NULL, '2023-08-29 12:06:19', '2023-08-29', '2023-08-29 21:11:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(154, 20, NULL, '2023-08-30 12:22:01', '2023-08-30', '2023-08-30 21:15:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(155, 20, NULL, '2023-08-31 12:14:43', '2023-08-31', '2023-08-31 20:44:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(156, 21, NULL, '2023-08-01 11:12:46', '2023-08-01', '2023-08-01 19:29:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(157, 21, NULL, '2023-08-02 10:40:58', '2023-08-02', '2023-08-02 19:31:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(158, 21, NULL, '2023-08-03 11:15:32', '2023-08-03', '2023-08-03 19:32:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(159, 21, NULL, '2023-08-04 10:55:20', '2023-08-04', '2023-08-04 19:40:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(160, 21, NULL, '2023-08-05 11:01:13', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(161, 21, NULL, '2023-08-07 11:14:45', '2023-08-07', '2023-08-07 19:29:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(162, 21, NULL, '2023-08-08 11:19:31', '2023-08-08', '2023-08-08 19:18:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(163, 21, NULL, '2023-08-09 10:41:49', '2023-08-09', '2023-08-09 19:33:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(164, 21, NULL, '2023-08-10 11:03:05', '2023-08-10', '2023-08-10 19:37:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(165, 21, NULL, '2023-08-11 10:52:53', '2023-08-11', '2023-08-11 19:35:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(166, 21, NULL, '2023-08-12 11:13:11', '2023-08-12', '2023-08-12 19:25:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(167, 21, NULL, '2023-08-15 11:14:28', '2023-08-15', '2023-08-15 19:45:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(168, 21, NULL, '2023-08-16 10:47:44', '2023-08-16', '2023-08-16 19:41:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(169, 21, NULL, '2023-08-17 11:09:37', '2023-08-17', '2023-08-17 19:33:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(170, 21, NULL, '2023-08-18 11:11:48', '2023-08-18', '2023-08-18 19:35:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(171, 21, NULL, '2023-08-19 11:07:09', '2023-08-19', '2023-08-19 19:14:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(172, 21, NULL, '2023-08-21 11:14:42', '2023-08-21', '2023-08-21 19:33:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(173, 21, NULL, '2023-08-22 11:17:42', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(174, 21, NULL, '2023-08-23 11:14:55', '2023-08-23', '2023-08-23 19:38:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(175, 21, NULL, '2023-08-24 11:11:02', '2023-08-24', '2023-08-24 19:49:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(176, 21, NULL, '2023-08-25 11:06:59', '2023-08-25', '2023-08-25 19:26:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(177, 21, NULL, '2023-08-26 10:56:32', '2023-08-26', '2023-08-26 19:27:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(178, 21, NULL, '2023-08-28 10:56:46', '2023-08-28', '2023-08-28 19:41:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(179, 21, NULL, '2023-08-29 11:15:09', '2023-08-29', '2023-08-29 19:46:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(180, 21, NULL, '2023-08-30 11:11:04', '2023-08-30', '2023-08-30 19:28:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(181, 21, NULL, '2023-08-31 11:29:37', '2023-08-31', '2023-08-31 19:21:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(182, 22, NULL, '2023-08-01 11:20:23', '2023-08-01', '2023-08-01 23:15:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(183, 22, NULL, '2023-08-02 11:15:12', '2023-08-02', '2023-08-02 22:09:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(184, 22, NULL, '2023-08-03 11:20:16', '2023-08-03', '2023-08-03 22:26:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(185, 22, NULL, '2023-08-04 11:27:37', '2023-08-04', '2023-08-04 21:48:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(186, 22, NULL, '2023-08-05 11:16:58', '2023-08-05', '2023-08-05 22:25:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(187, 22, NULL, '2023-08-07 11:17:30', '2023-08-07', '2023-08-07 23:08:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(188, 22, NULL, '2023-08-08 11:19:13', '2023-08-08', '2023-08-08 21:57:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(189, 22, NULL, '2023-08-09 11:24:37', '2023-08-09', '2023-08-09 22:35:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(190, 22, NULL, '2023-08-10 11:13:10', '2023-08-10', '2023-08-11 11:24:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(191, 22, NULL, '2023-08-11 11:24:49', '2023-08-11', '2023-08-11 22:23:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(192, 22, NULL, '2023-08-12 11:09:59', '2023-08-12', '2023-08-12 23:30:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(193, 22, NULL, '2023-08-15 11:20:11', '2023-08-15', '2023-08-15 22:23:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(194, 22, NULL, '2023-08-16 11:05:23', '2023-08-16', '2023-08-16 21:07:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(195, 22, NULL, '2023-08-17 11:07:17', '2023-08-17', '2023-08-17 20:33:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(196, 22, NULL, '2023-08-18 11:28:36', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(197, 22, NULL, '2023-08-19 11:12:58', '2023-08-19', '2023-08-19 21:15:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(198, 22, NULL, '2023-08-21 11:06:21', '2023-08-21', '2023-08-21 21:46:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(199, 22, NULL, '2023-08-22 11:10:51', '2023-08-22', '2023-08-22 21:42:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(200, 22, NULL, '2023-08-23 11:24:26', '2023-08-23', '2023-08-23 21:35:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(201, 22, NULL, '2023-08-24 11:14:28', '2023-08-24', '2023-08-24 21:46:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(202, 22, NULL, '2023-08-26 11:18:19', '2023-08-25', '2023-08-25 21:45:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(203, 22, NULL, '2023-08-26 11:18:19', '2023-08-26', '2023-08-26 22:11:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(204, 22, NULL, '2023-08-28 11:19:25', '2023-08-28', '2023-08-28 22:55:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(205, 22, NULL, '2023-08-29 11:17:30', '2023-08-29', '2023-08-29 23:28:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(206, 22, NULL, '2023-08-30 11:13:01', '2023-08-30', '2023-08-30 22:08:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(207, 22, NULL, '2023-08-31 11:24:21', '2023-08-31', '2023-09-01 01:40:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(208, 23, NULL, '2023-08-01 10:42:13', '2023-08-01', '2023-08-01 23:15:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(209, 23, NULL, '2023-08-02 10:40:46', '2023-08-02', '2023-08-02 22:14:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(210, 23, NULL, '2023-08-03 10:38:16', '2023-08-03', '2023-08-03 22:26:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(211, 23, NULL, '2023-08-04 10:48:52', '2023-08-04', '2023-08-04 21:50:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(212, 23, NULL, '2023-08-05 10:45:16', '2023-08-05', '2023-08-05 22:25:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(213, 23, NULL, '2023-08-07 10:41:35', '2023-08-07', '2023-08-07 23:10:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(214, 23, NULL, '2023-08-08 10:40:19', '2023-08-08', '2023-08-08 22:25:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(215, 23, NULL, '2023-08-09 10:32:59', '2023-08-09', '2023-08-09 22:36:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(216, 23, NULL, '2023-08-10 10:38:39', '2023-08-10', '2023-08-10 21:58:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(217, 23, NULL, '2023-08-11 10:41:33', '2023-08-11', '2023-08-11 22:28:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(218, 23, NULL, '2023-08-12 10:45:33', '2023-08-12', '2023-08-12 23:42:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(219, 23, NULL, '2023-08-15 10:45:23', '2023-08-15', '2023-08-15 22:23:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(220, 23, NULL, '2023-08-16 14:59:27', '2023-08-16', '2023-08-16 22:17:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(221, 23, NULL, '2023-08-17 10:46:14', '2023-08-17', '2023-08-17 20:39:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(222, 23, NULL, '2023-08-18 10:49:00', '2023-08-18', '2023-08-18 21:32:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(223, 23, NULL, '2023-08-19 10:35:59', '2023-08-19', '2023-08-19 21:11:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(224, 23, NULL, '2023-08-21 10:40:13', '2023-08-21', '2023-08-21 21:46:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(225, 23, NULL, '2023-08-22 10:38:34', '2023-08-22', '2023-08-22 20:31:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(226, 23, NULL, '2023-08-23 10:49:23', '2023-08-23', '2023-08-23 21:35:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(227, 23, NULL, '2023-08-24 10:49:03', '2023-08-24', '2023-08-24 21:46:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(228, 23, NULL, '2023-08-25 10:40:37', '2023-08-25', '2023-08-25 21:45:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(229, 23, NULL, '2023-08-26 10:43:59', '2023-08-26', '2023-08-26 22:10:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(230, 23, NULL, '2023-08-28 11:07:44', '2023-08-28', '2023-08-28 23:01:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(231, 23, NULL, '2023-08-29 10:50:21', '2023-08-29', '2023-08-29 23:29:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(232, 23, NULL, '2023-08-30 10:47:38', '2023-08-30', '2023-08-30 22:08:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(233, 23, NULL, '2023-08-31 10:43:38', '2023-08-31', '2023-08-31 19:47:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(234, 24, NULL, '2023-08-01 11:20:53', '2023-08-01', '2023-08-01 21:07:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(235, 24, NULL, '2023-08-02 11:45:50', '2023-08-02', '2023-08-02 20:34:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(236, 24, NULL, '2023-08-03 11:38:08', '2023-08-03', '2023-08-03 21:02:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(237, 24, NULL, '2023-08-04 11:51:45', '2023-08-04', '2023-08-05 11:42:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(238, 24, NULL, '2023-08-05 11:30:00', '2023-08-05', '2023-08-05 21:25:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(239, 24, NULL, '2023-08-07 11:41:29', '2023-08-07', '2023-08-07 21:11:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(240, 24, NULL, '2023-08-08 11:18:22', '2023-08-08', '2023-08-08 21:00:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(241, 24, NULL, '2023-08-09 11:49:38', '2023-08-09', '2023-08-09 21:02:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(242, 24, NULL, '2023-08-10 11:45:22', '2023-08-10', '2023-08-10 21:17:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(243, 24, NULL, '2023-08-11 11:30:40', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(244, 24, NULL, '2023-08-12 11:46:16', '2023-08-12', '2023-08-12 20:39:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(245, 24, NULL, '2023-08-15 11:35:41', '2023-08-15', '2023-08-15 21:21:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(246, 24, NULL, '2023-08-16 11:27:58', '2023-08-16', '2023-08-16 21:02:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(247, 24, NULL, '2023-08-17 12:00:46', '2023-08-17', '2023-08-18 01:28:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(248, 24, NULL, '2023-08-18 11:24:04', '2023-08-18', '2023-08-18 01:28:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(249, 24, NULL, '2023-08-19 11:35:51', '2023-08-19', '2023-08-19 20:45:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(250, 24, NULL, '2023-08-21 11:34:54', '2023-08-21', '2023-08-21 21:12:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(251, 24, NULL, '2023-08-22 11:45:47', '2023-08-22', '2023-08-22 20:38:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(252, 24, NULL, '2023-08-23 11:41:34', '2023-08-23', '2023-08-23 20:50:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(253, 24, NULL, '2023-08-24 11:31:20', '2023-08-24', '2023-08-24 20:53:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(254, 24, NULL, '2023-08-25 11:44:51', '2023-08-25', '2023-08-25 20:54:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(255, 24, NULL, '2023-08-26 14:20:59', '2023-08-26', '2023-08-26 21:32:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(256, 24, NULL, '2023-08-28 11:21:45', '2023-08-28', '2023-08-28 21:17:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(257, 24, NULL, '2023-08-29 11:29:23', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(258, 24, NULL, '2023-08-30 11:42:41', '2023-08-30', '2023-08-30 21:04:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(259, 24, NULL, '2023-08-31 11:43:26', '2023-08-31', '2023-08-31 20:50:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(260, 25, NULL, '2023-08-01 11:43:05', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(261, 25, NULL, '2023-08-02 11:47:37', '2023-08-02', '2023-08-02 20:42:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(262, 25, NULL, '2023-08-03 11:51:59', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(263, 25, NULL, '2023-08-04 11:46:10', '2023-08-04', '2023-08-04 20:34:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(264, 25, NULL, '2023-08-05 12:22:51', '2023-08-05', '2023-08-05 20:19:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(265, 25, NULL, '2023-08-07 11:50:43', '2023-08-07', '2023-08-07 18:12:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(266, 25, NULL, '2023-08-08 11:51:11', '2023-08-08', '2023-08-08 20:31:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(267, 25, NULL, '2023-08-09 12:04:16', '2023-08-09', '2023-08-09 20:21:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(268, 25, NULL, '2023-08-10 11:53:31', '2023-08-10', '2023-08-10 19:50:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(269, 25, NULL, '2023-08-11 11:54:54', '2023-08-11', '2023-08-11 20:40:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(270, 25, NULL, '2023-08-12 12:10:14', '2023-08-12', '2023-08-12 19:34:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(271, 25, NULL, '2023-08-15 11:46:21', '2023-08-15', '2023-08-15 20:30:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(272, 25, NULL, '2023-08-16 12:21:57', '2023-08-16', '2023-08-16 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(273, 25, NULL, '2023-08-17 11:51:39', '2023-08-17', '2023-08-17 20:50:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(274, 25, NULL, '2023-08-18 12:41:04', '2023-08-18', '2023-08-18 21:03:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(275, 25, NULL, '2023-08-19 11:49:32', '2023-08-19', '2023-08-19 20:35:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(276, 25, NULL, '2023-08-21 11:45:57', '2023-08-21', '2023-08-21 20:29:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(277, 25, NULL, '2023-08-22 11:50:25', '2023-08-22', '2023-08-22 20:44:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(278, 25, NULL, '2023-08-23 11:51:12', '2023-08-23', '2023-08-23 20:23:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(279, 25, NULL, '2023-08-24 11:59:18', '2023-08-24', '2023-08-24 20:48:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(280, 25, NULL, '2023-08-25 12:03:22', '2023-08-25', '2023-08-25 20:37:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(281, 25, NULL, '2023-08-26 13:14:38', '2023-08-26', '2023-08-26 19:37:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(282, 25, NULL, '2023-08-28 12:09:23', '2023-08-28', '2023-08-28 20:23:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(283, 25, NULL, '2023-08-29 11:56:29', '2023-08-29', '2023-08-29 20:42:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(284, 25, NULL, '2023-08-30 11:54:02', '2023-08-30', '2023-08-30 20:17:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(285, 25, NULL, '2023-08-31 11:56:17', '2023-08-31', '2023-08-31 18:36:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(286, 26, NULL, '2023-08-01 12:18:15', '2023-08-01', '2023-08-01 23:14:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(287, 26, NULL, '2023-08-02 12:44:29', '2023-08-02', '2023-08-02 22:10:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(288, 26, NULL, '2023-08-03 12:05:13', '2023-08-03', '2023-08-03 22:26:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(289, 26, NULL, '2023-08-04 11:51:55', '2023-08-04', '2023-08-04 21:49:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(290, 26, NULL, '2023-08-05 12:22:57', '2023-08-05', '2023-08-05 22:25:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(291, 26, NULL, '2023-08-07 12:05:48', '2023-08-07', '2023-08-07 23:12:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(292, 26, NULL, '2023-08-08 11:54:14', '2023-08-08', '2023-08-08 22:25:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(293, 26, NULL, '2023-08-09 13:56:05', '2023-08-09', '2023-08-09 23:04:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(294, 26, NULL, '2023-08-10 12:10:19', '2023-08-10', '2023-08-10 22:00:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(295, 26, NULL, '2023-08-11 11:52:46', '2023-08-11', '2023-08-11 22:23:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(296, 26, NULL, '2023-08-12 14:26:11', '2023-08-12', '2023-08-12 23:42:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(297, 26, NULL, '2023-08-15 11:58:06', '2023-08-15', '2023-08-15 22:03:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(298, 26, NULL, '2023-08-16 11:43:15', '2023-08-16', '2023-08-16 22:17:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(299, 26, NULL, '2023-08-17 13:15:25', '2023-08-17', '2023-08-18 11:36:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(300, 26, NULL, '2023-08-18 11:37:02', '2023-08-18', '2023-08-18 21:10:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(301, 26, NULL, '2023-08-19 11:30:20', '2023-08-19', '2023-08-19 21:11:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(302, 26, NULL, '2023-08-21 11:56:44', '2023-08-21', '2023-08-21 21:47:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(303, 26, NULL, '2023-08-22 11:54:04', '2023-08-22', '2023-08-22 21:44:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(304, 26, NULL, '2023-08-23 11:38:16', '2023-08-23', '2023-08-23 21:36:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(305, 26, NULL, '2023-08-24 12:35:17', '2023-08-24', '2023-08-24 21:58:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(306, 26, NULL, '2023-08-25 11:55:46', '2023-08-25', '2023-08-25 21:51:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(307, 26, NULL, '2023-08-28 12:34:58', '2023-08-28', '2023-08-28 22:56:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(308, 26, NULL, '2023-08-29 11:49:53', '2023-08-29', '2023-08-29 23:34:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(309, 26, NULL, '2023-08-30 22:09:01', '2023-08-30', '2023-08-30 22:08:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(310, 26, NULL, '2023-08-31 12:12:26', '2023-08-31', '2023-09-01 01:41:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(311, 27, NULL, '2023-08-01 11:21:59', '2023-08-01', '2023-08-01 23:25:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(312, 27, NULL, '2023-08-02 11:30:47', '2023-08-02', '2023-08-02 22:17:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(313, 27, NULL, '2023-08-03 11:21:04', '2023-08-03', '2023-08-03 22:56:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(314, 27, NULL, '2023-08-04 11:36:26', '2023-08-04', '2023-08-04 21:52:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(315, 27, NULL, '2023-08-05 11:09:48', '2023-08-05', '2023-08-05 23:07:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(316, 27, NULL, '2023-08-07 11:32:10', '2023-08-07', '2023-08-07 23:22:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(317, 27, NULL, '2023-08-08 11:26:46', '2023-08-08', '2023-08-08 22:26:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(318, 27, NULL, '2023-08-09 11:38:49', '2023-08-09', '2023-08-09 23:06:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(319, 27, NULL, '2023-08-10 11:27:06', '2023-08-10', '2023-08-10 22:02:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(320, 27, NULL, '2023-08-11 11:35:04', '2023-08-11', '2023-08-11 22:28:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(321, 27, NULL, '2023-08-12 11:31:02', '2023-08-12', '2023-08-12 23:42:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(322, 27, NULL, '2023-08-15 11:28:58', '2023-08-15', '2023-08-15 22:26:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(323, 27, NULL, '2023-08-16 11:26:22', '2023-08-16', '2023-08-17 11:23:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(324, 27, NULL, '2023-08-17 11:23:32', '2023-08-17', '2023-08-17 20:33:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(325, 27, NULL, '2023-08-18 11:29:55', '2023-08-18', '2023-08-18 21:35:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(326, 27, NULL, '2023-08-19 10:58:11', '2023-08-19', '2023-08-19 21:23:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(327, 27, NULL, '2023-08-21 11:01:22', '2023-08-21', '2023-08-21 21:48:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(328, 27, NULL, '2023-08-22 11:07:37', '2023-08-22', '2023-08-22 21:57:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(329, 27, NULL, '2023-08-23 11:12:59', '2023-08-23', '2023-08-23 22:04:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(330, 27, NULL, '2023-08-24 11:34:45', '2023-08-24', '2023-08-24 21:54:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(331, 27, NULL, '2023-08-25 11:31:58', '2023-08-25', '2023-08-25 21:58:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(332, 27, NULL, '2023-08-26 11:13:23', '2023-08-26', '2023-08-26 22:12:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(333, 27, NULL, '2023-08-28 11:17:03', '2023-08-28', '2023-08-28 23:26:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(334, 27, NULL, '2023-08-29 11:17:36', '2023-08-29', '2023-08-30 00:10:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(335, 27, NULL, '2023-08-30 11:18:27', '2023-08-30', '2023-08-30 22:43:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(336, 27, NULL, '2023-08-31 11:07:43', '2023-08-31', '2023-09-01 01:41:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(337, 28, NULL, '2023-08-02 11:47:22', '2023-08-02', '2023-08-02 20:56:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(338, 28, NULL, '2023-08-03 11:57:06', '2023-08-03', '2023-08-03 20:37:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(339, 28, NULL, '2023-08-04 12:48:39', '2023-08-04', '2023-08-04 20:36:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(340, 28, NULL, '2023-08-05 11:33:04', '2023-08-05', '2023-08-05 20:33:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(341, 28, NULL, '2023-08-07 12:39:16', '2023-08-07', '2023-08-07 20:37:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(342, 28, NULL, '2023-08-08 12:03:53', '2023-08-08', '2023-08-08 20:39:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(343, 28, NULL, '2023-08-09 12:34:35', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(344, 28, NULL, '2023-08-10 11:32:02', '2023-08-10', '2023-08-10 20:34:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(345, 28, NULL, '2023-08-11 12:58:34', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(346, 28, NULL, '2023-08-12 11:30:29', '2023-08-12', '2023-08-12 20:52:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(347, 28, NULL, '2023-08-15 12:33:18', '2023-08-15', '2023-08-15 21:29:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(348, 28, NULL, '2023-08-16 12:45:12', '2023-08-16', '2023-08-16 21:04:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(349, 28, NULL, '2023-08-17 11:55:54', '2023-08-17', '2023-08-17 20:42:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(350, 28, NULL, '2023-08-18 13:01:19', '2023-08-18', '2023-08-18 20:31:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(351, 28, NULL, '2023-08-19 11:34:34', '2023-08-19', '2023-08-19 20:36:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(352, 28, NULL, '2023-08-21 12:48:15', '2023-08-21', '2023-08-21 20:56:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(353, 28, NULL, '2023-08-22 11:49:41', '2023-08-22', '2023-08-22 20:29:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(354, 28, NULL, '2023-08-23 12:48:42', '2023-08-23', '2023-08-23 20:37:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(355, 28, NULL, '2023-08-24 11:58:50', '2023-08-24', '2023-08-24 20:31:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(356, 28, NULL, '2023-08-25 12:48:53', '2023-08-25', '2023-08-25 20:39:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(357, 28, NULL, '2023-08-26 11:42:25', '2023-08-26', '2023-08-26 20:56:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(358, 28, NULL, '2023-08-28 12:32:22', '2023-08-28', '2023-08-28 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(359, 28, NULL, '2023-08-29 11:30:00', '2023-08-29', '2023-08-29 20:32:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(360, 28, NULL, '2023-08-31 11:55:57', '2023-08-30', '2023-08-30 20:30:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(361, 28, NULL, '2023-08-31 11:55:57', '2023-08-31', '2023-08-31 19:59:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(362, 29, NULL, '2023-08-01 11:32:43', '2023-08-01', '2023-08-01 20:34:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(363, 29, NULL, '2023-08-02 11:00:20', '2023-08-02', '2023-08-02 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(364, 29, NULL, '2023-08-03 11:05:42', '2023-08-03', '2023-08-03 20:36:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(365, 29, NULL, '2023-08-04 11:02:17', '2023-08-04', '2023-08-04 20:50:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(366, 29, NULL, '2023-08-05 11:36:14', '2023-08-05', '2023-08-05 20:55:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(367, 29, NULL, '2023-08-07 11:32:03', '2023-08-07', '2023-08-07 20:32:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(368, 29, NULL, '2023-08-08 11:13:40', '2023-08-08', '2023-08-08 21:06:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(369, 29, NULL, '2023-08-09 11:28:01', '2023-08-09', '2023-08-09 20:36:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(370, 29, NULL, '2023-08-10 11:40:24', '2023-08-10', '2023-08-10 19:54:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(371, 29, NULL, '2023-08-11 12:22:03', '2023-08-11', '2023-08-11 20:58:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(372, 29, NULL, '2023-08-12 11:39:09', '2023-08-12', '2023-08-12 21:11:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(373, 29, NULL, '2023-08-15 11:35:22', '2023-08-15', '2023-08-15 21:10:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(374, 29, NULL, '2023-08-17 11:40:51', '2023-08-16', '2023-08-16 21:11:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(375, 29, NULL, '2023-08-17 11:40:51', '2023-08-17', '2023-08-17 21:19:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(376, 29, NULL, '2023-08-18 11:59:48', '2023-08-18', '2023-08-18 21:11:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(377, 29, NULL, '2023-08-19 11:05:01', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(378, 29, NULL, '2023-08-21 11:41:06', '2023-08-21', '2023-08-21 21:15:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(379, 29, NULL, '2023-08-22 11:31:08', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(380, 29, NULL, '2023-08-23 11:39:34', '2023-08-23', '2023-08-23 21:23:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(381, 29, NULL, '2023-08-24 11:44:15', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(382, 29, NULL, '2023-08-25 10:57:21', '2023-08-25', '2023-08-25 20:46:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(383, 29, NULL, '2023-08-26 11:28:39', '2023-08-26', '2023-08-26 21:05:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(384, 29, NULL, '2023-08-28 11:44:35', '2023-08-28', '2023-08-28 21:34:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(385, 29, NULL, '2023-08-29 11:41:40', '2023-08-29', '2023-08-29 21:18:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(386, 29, NULL, '2023-08-30 10:59:49', '2023-08-30', '2023-08-30 20:20:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(387, 29, NULL, '2023-08-31 12:02:44', '2023-08-31', '2023-08-31 20:30:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(388, 30, NULL, '2023-08-01 14:27:17', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(389, 30, NULL, '2023-08-02 12:22:21', '2023-08-02', '2023-08-02 20:40:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL);
INSERT INTO `attendance` (`RecId`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(390, 30, NULL, '2023-08-03 12:26:26', '2023-08-03', '2023-08-03 20:43:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(391, 30, NULL, '2023-08-04 12:23:41', '2023-08-04', '2023-08-04 20:51:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(392, 30, NULL, '2023-08-05 12:13:48', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(393, 30, NULL, '2023-08-07 11:58:05', '2023-08-07', '2023-08-07 21:16:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(394, 30, NULL, '2023-08-08 12:50:33', '2023-08-08', '2023-08-08 19:38:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(395, 30, NULL, '2023-08-09 12:25:13', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(396, 30, NULL, '2023-08-10 12:04:35', '2023-08-10', '2023-08-10 20:40:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(397, 30, NULL, '2023-08-11 12:42:16', '2023-08-11', '2023-08-11 21:13:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(398, 30, NULL, '2023-08-12 11:41:10', '2023-08-12', '2023-08-12 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(399, 30, NULL, '2023-08-17 12:51:29', '2023-08-17', '2023-08-17 20:40:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(400, 30, NULL, '2023-08-18 13:52:18', '2023-08-18', '2023-08-18 20:39:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(401, 30, NULL, '2023-08-19 12:02:31', '2023-08-19', '2023-08-19 20:42:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(402, 30, NULL, '2023-08-21 11:28:45', '2023-08-21', '2023-08-21 21:05:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(403, 30, NULL, '2023-08-22 11:48:20', '2023-08-22', '2023-08-22 21:20:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(404, 30, NULL, '2023-08-23 12:41:11', '2023-08-23', '2023-08-23 21:06:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(405, 30, NULL, '2023-08-24 11:36:23', '2023-08-24', '2023-08-24 20:59:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(406, 30, NULL, '2023-08-25 11:36:50', '2023-08-25', '2023-08-25 20:06:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(407, 30, NULL, '2023-08-26 12:20:30', '2023-08-26', '2023-08-26 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(408, 30, NULL, '2023-08-28 11:37:56', '2023-08-28', '2023-08-28 20:25:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(409, 30, NULL, '2023-08-29 11:41:47', '2023-08-29', '2023-08-29 21:14:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(410, 30, NULL, '2023-08-30 13:13:15', '2023-08-30', '2023-08-30 21:09:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(411, 30, NULL, '2023-08-31 11:49:34', '2023-08-31', '2023-08-31 20:53:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(412, 31, NULL, '2023-08-01 11:54:19', '2023-08-01', '2023-08-01 21:43:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(413, 31, NULL, '2023-08-02 11:45:27', '2023-08-02', '2023-08-02 21:38:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(414, 31, NULL, '2023-08-03 12:01:23', '2023-08-03', '2023-08-03 21:52:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(415, 31, NULL, '2023-08-04 12:04:06', '2023-08-04', '2023-08-04 18:30:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(416, 31, NULL, '2023-08-05 12:14:44', '2023-08-05', '2023-08-05 21:42:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(417, 31, NULL, '2023-08-07 11:37:17', '2023-08-07', '2023-08-07 21:37:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(418, 31, NULL, '2023-08-09 11:43:29', '2023-08-09', '2023-08-09 21:42:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(419, 31, NULL, '2023-08-10 11:57:14', '2023-08-10', '2023-08-10 21:57:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(420, 31, NULL, '2023-08-11 12:16:23', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(421, 31, NULL, '2023-08-12 12:02:52', '2023-08-12', '2023-08-12 20:36:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(422, 31, NULL, '2023-08-15 11:40:42', '2023-08-15', '2023-08-15 21:00:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(423, 31, NULL, '2023-08-16 11:24:28', '2023-08-16', '2023-08-16 21:16:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(424, 31, NULL, '2023-08-17 12:06:35', '2023-08-17', '2023-08-17 20:23:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(425, 31, NULL, '2023-08-18 11:44:48', '2023-08-18', '2023-08-18 22:03:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(426, 31, NULL, '2023-08-19 12:11:46', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(427, 31, NULL, '2023-08-21 13:53:22', '2023-08-21', '2023-08-21 21:59:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(428, 31, NULL, '2023-08-22 12:03:54', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(429, 31, NULL, '2023-08-23 11:57:01', '2023-08-23', '2023-08-23 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(430, 31, NULL, '2023-08-24 12:25:20', '2023-08-24', '2023-08-24 21:38:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(431, 31, NULL, '2023-08-25 11:50:16', '2023-08-25', '2023-08-25 20:54:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(432, 31, NULL, '2023-08-26 12:04:06', '2023-08-26', '2023-08-26 21:08:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(433, 31, NULL, '2023-08-28 11:30:00', '2023-08-28', '2023-08-28 21:36:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(434, 32, NULL, '2023-08-01 11:24:29', '2023-08-01', '2023-08-02 00:46:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(435, 32, NULL, '2023-08-02 12:49:45', '2023-08-02', '2023-08-03 00:19:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(436, 32, NULL, '2023-08-03 11:21:36', '2023-08-03', '2023-08-04 11:07:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(437, 32, NULL, '2023-08-04 11:07:54', '2023-08-04', '2023-08-05 10:58:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(438, 32, NULL, '2023-08-05 11:30:00', '2023-08-05', '2023-08-05 20:52:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(439, 32, NULL, '2023-08-07 10:50:51', '2023-08-07', '2023-08-08 01:23:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(440, 32, NULL, '2023-08-08 11:25:40', '2023-08-08', '2023-08-09 00:41:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(441, 32, NULL, '2023-08-09 00:41:02', '2023-08-09', '2023-08-10 00:27:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(442, 32, NULL, '2023-08-10 10:59:29', '2023-08-10', '2023-08-11 00:23:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(443, 32, NULL, '2023-08-11 11:04:54', '2023-08-11', '2023-08-11 23:53:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(444, 32, NULL, '2023-08-12 11:26:27', '2023-08-12', '2023-08-12 20:37:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(445, 32, NULL, '2023-08-15 11:01:58', '2023-08-15', '2023-08-16 00:27:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(446, 32, NULL, '2023-08-16 13:15:50', '2023-08-16', '2023-08-17 00:35:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(447, 32, NULL, '2023-08-17 11:08:38', '2023-08-17', '2023-08-18 00:45:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(448, 32, NULL, '2023-08-18 11:02:05', '2023-08-18', '2023-08-19 00:22:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(449, 32, NULL, '2023-08-19 10:58:04', '2023-08-19', '2023-08-19 21:17:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(450, 32, NULL, '2023-08-21 11:11:13', '2023-08-21', '2023-08-22 00:59:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(451, 32, NULL, '2023-08-22 10:52:22', '2023-08-22', '2023-08-23 00:26:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(452, 32, NULL, '2023-08-23 11:02:25', '2023-08-23', '2023-08-24 00:37:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(453, 32, NULL, '2023-08-24 11:04:19', '2023-08-24', '2023-08-25 00:33:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(454, 32, NULL, '2023-08-25 11:15:11', '2023-08-25', '2023-08-26 00:30:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(455, 32, NULL, '2023-08-26 10:57:12', '2023-08-26', '2023-08-26 20:45:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(456, 32, NULL, '2023-08-28 11:07:35', '2023-08-28', '2023-08-29 00:40:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(457, 32, NULL, '2023-08-29 11:17:43', '2023-08-29', '2023-08-30 00:34:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(458, 32, NULL, '2023-08-30 11:14:59', '2023-08-30', '2023-08-31 00:33:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(459, 32, NULL, '2023-08-31 11:10:42', '2023-08-31', '2023-09-01 00:37:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(460, 33, NULL, '2023-08-04 11:44:29', '2023-08-04', '2023-08-04 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(461, 33, NULL, '2023-08-05 11:42:08', '2023-08-05', '2023-08-05 20:57:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(462, 33, NULL, '2023-08-08 11:41:11', '2023-08-08', '2023-08-08 20:41:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(463, 33, NULL, '2023-08-09 11:41:10', '2023-08-09', '2023-08-09 20:34:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(464, 33, NULL, '2023-08-10 11:42:54', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(465, 33, NULL, '2023-08-11 11:51:14', '2023-08-11', '2023-08-11 20:42:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(466, 33, NULL, '2023-08-12 11:43:22', '2023-08-12', '2023-08-12 21:26:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(467, 33, NULL, '2023-08-15 11:41:59', '2023-08-15', '2023-08-15 20:31:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(468, 33, NULL, '2023-08-16 11:38:48', '2023-08-16', '2023-08-16 20:35:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(469, 33, NULL, '2023-08-17 13:26:02', '2023-08-17', '2023-08-17 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(470, 33, NULL, '2023-08-18 11:41:27', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(471, 33, NULL, '2023-08-19 11:39:47', '2023-08-19', '2023-08-19 20:38:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(472, 33, NULL, '2023-08-21 11:44:05', '2023-08-21', '2023-08-21 20:32:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(473, 33, NULL, '2023-08-22 11:43:52', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(474, 33, NULL, '2023-08-23 11:45:07', '2023-08-23', '2023-08-23 20:41:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(475, 33, NULL, '2023-08-24 11:35:57', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(476, 33, NULL, '2023-08-25 11:39:05', '2023-08-25', '2023-08-25 20:34:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(477, 33, NULL, '2023-08-28 11:42:12', '2023-08-28', '2023-08-28 20:35:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(478, 33, NULL, '2023-08-29 11:43:21', '2023-08-29', '2023-08-29 20:33:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(479, 33, NULL, '2023-08-30 11:41:12', '2023-08-30', '2023-08-30 20:37:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(480, 33, NULL, '2023-08-31 11:41:45', '2023-08-31', '2023-08-31 20:38:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(481, 34, NULL, '2023-08-02 11:31:47', '2023-08-02', '2023-08-02 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(482, 34, NULL, '2023-08-08 11:36:40', '2023-08-08', '2023-08-08 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(483, 34, NULL, '2023-08-09 11:32:10', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(484, 34, NULL, '2023-08-10 11:24:53', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(485, 34, NULL, '2023-08-15 11:27:14', '2023-08-15', '2023-08-15 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(486, 34, NULL, '2023-08-16 11:28:19', '2023-08-16', '2023-08-16 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(487, 34, NULL, '2023-08-17 11:29:05', '2023-08-17', '2023-08-17 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(488, 34, NULL, '2023-08-18 11:24:18', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(489, 34, NULL, '2023-08-19 11:22:26', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(490, 34, NULL, '2023-08-21 11:24:21', '2023-08-21', '2023-08-21 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(491, 34, NULL, '2023-08-24 11:32:52', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(492, 34, NULL, '2023-08-25 11:15:48', '2023-08-25', '2023-08-25 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(493, 34, NULL, '2023-08-26 13:50:14', '2023-08-26', '2023-08-26 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(494, 34, NULL, '2023-08-28 11:33:40', '2023-08-28', '2023-08-28 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(495, 34, NULL, '2023-08-29 11:23:50', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(496, 34, NULL, '2023-08-30 11:29:41', '2023-08-30', '2023-08-30 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(497, 34, NULL, '2023-08-31 11:42:56', '2023-08-31', '2023-08-31 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(498, 35, NULL, '2023-08-03 11:10:47', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(499, 35, NULL, '2023-08-04 11:14:55', '2023-08-04', '2023-08-04 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(500, 35, NULL, '2023-08-05 11:13:32', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(501, 35, NULL, '2023-08-07 11:16:33', '2023-08-07', '2023-08-07 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(502, 35, NULL, '2023-08-08 11:16:31', '2023-08-08', '2023-08-08 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(503, 35, NULL, '2023-08-09 11:22:13', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(504, 35, NULL, '2023-08-10 11:22:20', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(505, 35, NULL, '2023-08-11 11:21:53', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(506, 35, NULL, '2023-08-12 11:28:17', '2023-08-12', '2023-08-12 20:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(507, 35, NULL, '2023-08-15 11:21:49', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(508, 35, NULL, '2023-08-16 11:25:29', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(509, 35, NULL, '2023-08-17 11:22:13', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(510, 35, NULL, '2023-08-18 11:20:57', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(511, 35, NULL, '2023-08-19 11:17:05', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(512, 35, NULL, '2023-08-21 11:17:20', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(513, 35, NULL, '2023-08-22 11:22:39', '2023-08-22', '2023-08-22 22:23:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(514, 35, NULL, '2023-08-23 11:15:19', '2023-08-23', '2023-08-23 22:00:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(515, 35, NULL, '2023-08-24 17:13:42', '2023-08-24', '2023-08-24 20:47:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(516, 35, NULL, '2023-08-26 11:26:36', '2023-08-25', '2023-08-25 21:01:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(517, 35, NULL, '2023-08-26 11:26:36', '2023-08-26', '2023-08-26 21:27:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(518, 35, NULL, '2023-08-28 11:24:06', '2023-08-28', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(519, 35, NULL, '0000-00-00 00:00:00', '2023-08-29', '2023-08-29 21:03:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(520, 36, NULL, '2023-08-02 11:41:09', '2023-08-02', '2023-08-02 20:58:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(521, 36, NULL, '2023-08-03 11:35:01', '2023-08-03', '2023-08-03 20:11:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(522, 36, NULL, '2023-08-04 11:44:20', '2023-08-04', '2023-08-04 19:23:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(523, 36, NULL, '2023-08-07 11:49:04', '2023-08-07', '2023-08-07 21:25:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(524, 36, NULL, '2023-08-08 11:40:42', '2023-08-08', '2023-08-08 19:55:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(525, 36, NULL, '2023-08-09 11:40:07', '2023-08-09', '2023-08-09 21:42:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(526, 36, NULL, '2023-08-10 11:35:19', '2023-08-10', '2023-08-10 19:18:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(527, 36, NULL, '2023-08-11 11:43:29', '2023-08-11', '2023-08-11 19:16:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(528, 36, NULL, '2023-08-12 11:43:40', '2023-08-12', '2023-08-12 22:03:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(529, 36, NULL, '2023-08-15 11:45:58', '2023-08-15', '2023-08-15 19:14:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(530, 36, NULL, '2023-08-16 11:41:02', '2023-08-16', '2023-08-16 18:57:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(531, 36, NULL, '2023-08-17 11:38:04', '2023-08-17', '2023-08-17 19:01:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(532, 36, NULL, '2023-08-18 11:54:12', '2023-08-18', '2023-08-18 18:59:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(533, 36, NULL, '2023-08-19 11:47:08', '2023-08-19', '2023-08-19 18:59:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(534, 36, NULL, '2023-08-21 11:49:08', '2023-08-21', '2023-08-21 19:08:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(535, 37, NULL, '2023-08-01 12:08:57', '2023-08-01', '2023-08-01 20:32:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(536, 37, NULL, '2023-08-02 11:59:53', '2023-08-02', '2023-08-02 20:24:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(537, 37, NULL, '2023-08-03 11:53:52', '2023-08-03', '2023-08-03 20:20:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(538, 37, NULL, '2023-08-04 11:59:12', '2023-08-04', '2023-08-04 20:18:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(539, 37, NULL, '2023-08-07 12:04:09', '2023-08-07', '2023-08-07 20:31:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(540, 37, NULL, '2023-08-08 11:52:32', '2023-08-08', '2023-08-08 20:37:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(541, 37, NULL, '2023-08-09 11:54:03', '2023-08-09', '2023-08-09 20:19:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(542, 37, NULL, '2023-08-10 13:50:30', '2023-08-10', '2023-08-10 20:17:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(543, 37, NULL, '2023-08-11 11:58:29', '2023-08-11', '2023-08-11 20:15:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(544, 37, NULL, '2023-08-15 12:02:41', '2023-08-15', '2023-08-15 20:29:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(545, 37, NULL, '2023-08-16 13:29:32', '2023-08-16', '2023-08-16 20:17:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(546, 37, NULL, '2023-08-17 12:02:08', '2023-08-17', '2023-08-17 20:18:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(547, 37, NULL, '2023-08-18 11:48:31', '2023-08-18', '2023-08-18 20:19:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(548, 37, NULL, '2023-08-21 11:45:40', '2023-08-21', '2023-08-21 20:19:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(549, 37, NULL, '2023-08-22 11:50:21', '2023-08-22', '2023-08-22 20:44:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(550, 37, NULL, '2023-08-23 12:01:03', '2023-08-23', '2023-08-23 20:15:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(551, 37, NULL, '2023-08-24 12:36:51', '2023-08-24', '2023-08-24 20:19:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(552, 37, NULL, '2023-08-25 12:03:29', '2023-08-25', '2023-08-25 20:32:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(553, 37, NULL, '2023-08-28 11:54:32', '2023-08-28', '2023-08-28 20:18:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(554, 37, NULL, '2023-08-29 12:09:04', '2023-08-29', '2023-08-29 20:20:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(555, 37, NULL, '2023-08-30 12:12:56', '2023-08-30', '2023-08-30 20:14:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(556, 37, NULL, '2023-08-31 12:16:13', '2023-08-31', '2023-08-31 20:23:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(557, 38, NULL, '2023-08-01 11:40:14', '2023-08-01', '2023-08-01 21:14:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(558, 38, NULL, '2023-08-02 11:42:45', '2023-08-02', '2023-08-02 21:03:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(559, 38, NULL, '2023-08-03 14:11:20', '2023-08-03', '2023-08-03 21:10:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(560, 38, NULL, '2023-08-04 11:40:15', '2023-08-04', '2023-08-04 21:05:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(561, 38, NULL, '2023-08-05 11:33:34', '2023-08-05', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(562, 38, NULL, '2023-08-07 11:43:41', '2023-08-07', '2023-08-07 21:22:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(563, 38, NULL, '2023-08-08 11:51:22', '2023-08-08', '2023-08-08 21:36:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(564, 38, NULL, '2023-08-09 11:46:14', '2023-08-09', '2023-08-09 21:29:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(565, 38, NULL, '2023-08-10 11:46:49', '2023-08-10', '2023-08-10 21:11:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(566, 38, NULL, '2023-08-11 11:49:29', '2023-08-11', '2023-08-11 21:04:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(567, 38, NULL, '2023-08-12 11:44:35', '2023-08-12', '2023-08-12 22:20:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(568, 38, NULL, '2023-08-15 11:41:31', '2023-08-15', '2023-08-15 21:29:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(569, 38, NULL, '2023-08-16 12:32:55', '2023-08-16', '2023-08-16 21:15:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(570, 38, NULL, '2023-08-17 11:46:33', '2023-08-17', '2023-08-17 21:12:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(571, 38, NULL, '2023-08-18 11:43:57', '2023-08-18', '2023-08-18 21:12:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(572, 38, NULL, '2023-08-19 11:46:42', '2023-08-19', '2023-08-19 21:29:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(573, 38, NULL, '2023-08-21 11:47:37', '2023-08-21', '2023-08-21 21:15:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(574, 38, NULL, '2023-08-22 12:35:46', '2023-08-22', '2023-08-22 21:31:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(575, 38, NULL, '2023-08-23 11:44:53', '2023-08-23', '2023-08-23 21:51:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(576, 38, NULL, '2023-08-24 11:43:31', '2023-08-24', '2023-08-24 21:00:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(577, 38, NULL, '2023-08-25 11:45:01', '2023-08-25', '2023-08-25 21:37:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(578, 38, NULL, '2023-08-26 12:20:01', '2023-08-26', '2023-08-26 21:16:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(579, 38, NULL, '2023-08-28 11:44:58', '2023-08-28', '2023-08-28 21:33:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(580, 38, NULL, '2023-08-29 11:44:18', '2023-08-29', '2023-08-29 21:24:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(581, 38, NULL, '2023-08-30 11:46:31', '2023-08-30', '2023-08-30 21:29:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(582, 38, NULL, '2023-08-31 11:46:20', '2023-08-31', '2023-08-31 22:08:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(583, 39, NULL, '2023-08-01 11:26:10', '2023-08-01', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(584, 39, NULL, '2023-08-02 11:11:27', '2023-08-02', '2023-08-02 21:03:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(585, 39, NULL, '2023-08-03 11:20:41', '2023-08-03', '2023-08-03 21:10:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(586, 39, NULL, '2023-08-04 10:59:29', '2023-08-04', '2023-08-04 21:05:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(587, 39, NULL, '2023-08-05 11:28:22', '2023-08-05', '2023-08-05 20:57:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(588, 39, NULL, '2023-08-07 11:28:57', '2023-08-07', '2023-08-07 21:22:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(589, 39, NULL, '2023-08-08 11:29:20', '2023-08-08', '2023-08-08 21:36:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(590, 39, NULL, '2023-08-09 11:26:27', '2023-08-09', '2023-08-09 16:08:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(591, 39, NULL, '2023-08-10 11:12:33', '2023-08-10', '2023-08-10 21:11:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(592, 39, NULL, '2023-08-11 11:23:58', '2023-08-11', '2023-08-11 18:25:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(593, 39, NULL, '2023-08-12 11:29:42', '2023-08-12', '2023-08-12 19:05:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(594, 39, NULL, '2023-08-15 11:13:42', '2023-08-15', '2023-08-15 21:29:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(595, 39, NULL, '2023-08-16 11:27:22', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(596, 39, NULL, '2023-08-17 11:30:28', '2023-08-17', '2023-08-17 21:25:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(597, 39, NULL, '2023-08-18 11:29:16', '2023-08-18', '2023-08-19 11:14:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(598, 39, NULL, '2023-08-19 11:14:54', '2023-08-19', '2023-08-19 21:48:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(599, 39, NULL, '2023-08-21 11:15:49', '2023-08-21', '2023-08-21 21:15:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(600, 39, NULL, '2023-08-22 11:34:36', '2023-08-22', '2023-08-22 21:31:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(601, 39, NULL, '2023-08-23 11:02:11', '2023-08-23', '2023-08-23 13:37:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(602, 39, NULL, '2023-08-24 11:10:26', '2023-08-24', '2023-08-24 21:11:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(603, 39, NULL, '2023-08-25 11:40:59', '2023-08-25', '2023-08-25 20:34:57', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(604, 39, NULL, '2023-08-26 11:08:49', '2023-08-26', '2023-08-26 21:16:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(605, 39, NULL, '2023-08-28 11:46:18', '2023-08-28', '2023-08-28 21:33:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(606, 39, NULL, '2023-08-29 11:27:56', '2023-08-29', '2023-08-29 21:24:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(607, 39, NULL, '2023-08-30 11:15:13', '2023-08-30', '2023-08-30 21:29:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(608, 39, NULL, '2023-08-31 11:29:03', '2023-08-31', '2023-08-31 20:54:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(609, 40, NULL, '2023-08-01 11:23:39', '2023-08-01', '2023-08-01 20:32:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(610, 40, NULL, '2023-08-02 11:17:29', '2023-08-02', '2023-08-02 20:36:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(611, 40, NULL, '2023-08-04 11:08:53', '2023-08-03', '2023-08-03 20:36:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(612, 40, NULL, '2023-08-04 11:08:53', '2023-08-04', '2023-08-04 20:34:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(613, 40, NULL, '0000-00-00 00:00:00', '2023-08-05', '2023-08-05 20:40:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(614, 40, NULL, '2023-08-07 11:35:11', '2023-08-07', '2023-08-07 21:05:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(615, 40, NULL, '2023-08-08 11:30:51', '2023-08-08', '2023-08-08 20:40:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(616, 40, NULL, '2023-08-09 11:19:48', '2023-08-09', '2023-08-09 20:24:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(617, 40, NULL, '2023-08-10 11:33:50', '2023-08-10', '2023-08-10 20:32:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(618, 40, NULL, '2023-08-11 11:22:47', '2023-08-11', '2023-08-11 20:31:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(619, 40, NULL, '2023-08-12 11:16:44', '2023-08-12', '2023-08-12 20:33:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(620, 40, NULL, '2023-08-15 11:51:45', '2023-08-15', '2023-08-15 20:51:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(621, 40, NULL, '2023-08-16 11:35:23', '2023-08-16', '2023-08-16 20:32:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(622, 40, NULL, '2023-08-17 11:16:41', '2023-08-17', '2023-08-17 20:33:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(623, 40, NULL, '2023-08-18 11:38:28', '2023-08-18', '2023-08-18 20:32:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(624, 40, NULL, '2023-08-19 11:52:20', '2023-08-19', '2023-08-19 20:40:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(625, 40, NULL, '2023-08-21 11:31:24', '2023-08-21', '2023-08-21 20:22:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(626, 40, NULL, '2023-08-22 11:36:47', '2023-08-22', '2023-08-22 20:27:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(627, 40, NULL, '2023-08-23 11:40:47', '2023-08-23', '2023-08-23 20:22:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(628, 40, NULL, '2023-08-24 11:25:45', '2023-08-24', '2023-08-24 20:30:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(629, 40, NULL, '2023-08-25 11:35:55', '2023-08-25', '2023-08-25 20:37:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(630, 40, NULL, '2023-08-26 11:45:46', '2023-08-26', '2023-08-26 20:30:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(631, 40, NULL, '2023-08-28 12:13:28', '2023-08-28', '2023-08-28 20:26:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(632, 40, NULL, '2023-08-29 11:36:14', '2023-08-29', '2023-08-29 20:22:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(633, 40, NULL, '2023-08-30 11:44:19', '2023-08-30', '2023-08-30 20:48:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(634, 40, NULL, '2023-08-31 11:17:37', '2023-08-31', '2023-08-31 20:26:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(635, 41, NULL, '2023-08-01 12:07:18', '2023-08-01', '2023-08-01 20:36:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(636, 41, NULL, '2023-08-02 11:26:37', '2023-08-02', '2023-08-02 20:41:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(637, 41, NULL, '2023-08-03 13:36:38', '2023-08-03', '2023-08-03 20:29:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(638, 41, NULL, '2023-08-04 11:37:47', '2023-08-04', '2023-08-04 20:37:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(639, 41, NULL, '2023-08-05 11:24:43', '2023-08-05', '2023-08-05 20:36:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(640, 41, NULL, '2023-08-07 11:53:58', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(641, 41, NULL, '2023-08-08 11:24:21', '2023-08-08', '2023-08-08 20:34:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(642, 41, NULL, '2023-08-09 11:11:50', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(643, 41, NULL, '2023-08-10 12:36:03', '2023-08-10', '2023-08-10 20:30:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(644, 41, NULL, '2023-08-11 11:33:49', '2023-08-11', '2023-08-11 20:53:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(645, 41, NULL, '0000-00-00 00:00:00', '2023-08-12', '2023-08-12 20:37:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(646, 41, NULL, '2023-08-15 12:58:31', '2023-08-15', '2023-08-15 20:42:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(647, 41, NULL, '2023-08-16 11:35:55', '2023-08-16', '2023-08-16 20:31:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(648, 41, NULL, '2023-08-17 11:54:02', '2023-08-17', '2023-08-17 20:27:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(649, 41, NULL, '2023-08-18 13:15:03', '2023-08-18', '2023-08-18 20:34:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(650, 41, NULL, '2023-08-19 11:36:06', '2023-08-19', '2023-08-19 20:31:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(651, 41, NULL, '2023-08-22 11:28:37', '2023-08-22', '2023-08-22 20:51:01', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(652, 41, NULL, '2023-08-23 11:36:14', '2023-08-23', '2023-08-23 20:32:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(653, 41, NULL, '2023-08-24 11:36:54', '2023-08-24', '2023-08-24 20:27:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(654, 41, NULL, '2023-08-25 12:07:17', '2023-08-25', '2023-08-25 20:38:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(655, 41, NULL, '2023-08-26 11:35:22', '2023-08-26', '2023-08-26 20:33:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(656, 41, NULL, '2023-08-28 12:09:13', '2023-08-28', '2023-08-28 20:37:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(657, 41, NULL, '2023-08-29 12:07:38', '2023-08-29', '2023-08-29 20:44:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(658, 41, NULL, '2023-08-30 13:19:25', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(659, 42, NULL, '2023-08-01 11:55:10', '2023-08-01', '2023-08-01 20:28:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(660, 42, NULL, '2023-08-02 11:49:09', '2023-08-02', '2023-08-02 20:48:50', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(661, 42, NULL, '2023-08-03 11:54:09', '2023-08-03', '2023-08-03 18:25:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(662, 42, NULL, '2023-08-04 12:11:37', '2023-08-04', '2023-08-04 20:39:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(663, 42, NULL, '2023-08-25 12:07:36', '2023-08-25', '2023-08-25 20:37:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(664, 42, NULL, '2023-08-26 11:59:07', '2023-08-26', '2023-08-26 20:31:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(665, 42, NULL, '2023-08-28 11:54:04', '2023-08-28', '2023-08-28 20:38:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(666, 42, NULL, '2023-08-29 14:48:50', '2023-08-29', '2023-08-29 20:48:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(667, 42, NULL, '2023-08-30 11:38:15', '2023-08-30', '2023-08-30 20:47:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(668, 42, NULL, '2023-08-31 11:55:34', '2023-08-31', '2023-08-31 20:27:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(669, 43, NULL, '0000-00-00 00:00:00', '2023-08-03', '2023-08-03 19:28:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(670, 43, NULL, '2023-08-04 12:23:13', '2023-08-04', '2023-08-04 20:19:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(671, 43, NULL, '2023-08-05 12:17:58', '2023-08-05', '2023-08-05 17:03:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(672, 43, NULL, '0000-00-00 00:00:00', '2023-08-07', '2023-08-07 19:08:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(673, 43, NULL, '2023-08-09 11:34:59', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(674, 43, NULL, '2023-08-10 12:07:56', '2023-08-10', '2023-08-10 19:01:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(675, 43, NULL, '2023-08-11 12:25:22', '2023-08-11', '2023-08-11 19:47:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(676, 43, NULL, '2023-08-12 12:23:01', '2023-08-12', '2023-08-12 18:43:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(677, 43, NULL, '2023-08-15 11:44:23', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(678, 43, NULL, '2023-08-16 12:21:46', '2023-08-16', '2023-08-16 19:32:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(679, 43, NULL, '2023-08-17 12:06:47', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(680, 43, NULL, '2023-08-18 11:33:45', '2023-08-18', '2023-08-18 19:36:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(681, 43, NULL, '2023-08-21 11:47:11', '2023-08-21', '2023-08-21 19:51:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(682, 43, NULL, '2023-08-22 12:05:34', '2023-08-22', '2023-08-22 19:28:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(683, 43, NULL, '2023-08-23 12:02:54', '2023-08-23', '2023-08-23 19:13:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(684, 43, NULL, '2023-08-24 11:52:27', '2023-08-24', '2023-08-24 19:17:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(685, 43, NULL, '2023-08-25 12:13:46', '2023-08-25', '2023-08-25 19:11:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(686, 43, NULL, '2023-08-26 11:29:17', '2023-08-26', '2023-08-26 19:13:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(687, 43, NULL, '2023-08-28 12:38:59', '2023-08-28', '2023-08-28 19:09:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(688, 43, NULL, '2023-08-29 12:47:32', '2023-08-29', '2023-08-29 19:25:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(689, 43, NULL, '2023-08-30 12:29:11', '2023-08-30', '2023-08-30 20:25:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(690, 43, NULL, '2023-08-31 12:26:06', '2023-08-31', '2023-08-31 20:03:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(691, 44, NULL, '0000-00-00 00:00:00', '2023-08-09', '2023-08-09 22:15:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(692, 44, NULL, '2023-08-15 11:13:24', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(693, 44, NULL, '2023-08-16 11:18:31', '2023-08-16', '2023-08-16 21:15:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(694, 45, NULL, '2023-08-01 14:25:22', '2023-08-01', '2023-08-01 22:16:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(695, 45, NULL, '2023-08-02 13:05:46', '2023-08-02', '2023-08-02 22:36:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(696, 45, NULL, '2023-08-03 12:51:30', '2023-08-03', '2023-08-04 00:20:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(697, 45, NULL, '2023-08-04 12:37:09', '2023-08-04', '2023-08-05 00:20:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(698, 45, NULL, '2023-08-05 14:54:27', '2023-08-05', '2023-08-05 22:21:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(699, 45, NULL, '2023-08-07 14:28:44', '2023-08-07', '2023-08-08 00:09:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(700, 45, NULL, '2023-08-08 14:20:19', '2023-08-08', '2023-08-09 01:26:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(701, 45, NULL, '2023-08-09 15:17:02', '2023-08-09', '2023-08-10 01:02:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(702, 45, NULL, '2023-08-11 15:46:17', '2023-08-10', '2023-08-12 01:22:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(703, 45, NULL, '2023-08-12 16:13:26', '2023-08-12', '2023-08-12 22:48:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(704, 45, NULL, '2023-08-16 14:16:38', '2023-08-16', '2023-08-17 00:41:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(705, 45, NULL, '2023-08-17 12:32:49', '2023-08-17', '2023-08-18 00:40:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(706, 45, NULL, '2023-08-18 13:21:53', '2023-08-18', '2023-08-18 23:01:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(707, 45, NULL, '2023-08-19 14:03:18', '2023-08-19', '2023-08-19 22:34:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(708, 45, NULL, '2023-08-21 13:33:34', '2023-08-21', '2023-08-21 22:42:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(709, 45, NULL, '2023-08-23 13:55:26', '2023-08-23', '2023-08-24 00:23:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(710, 45, NULL, '2023-08-24 14:03:58', '2023-08-24', '2023-08-25 00:24:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(711, 45, NULL, '2023-08-25 14:07:23', '2023-08-25', '2023-08-25 23:19:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(712, 45, NULL, '0000-00-00 00:00:00', '2023-08-26', '2023-08-26 21:32:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(713, 45, NULL, '0000-00-00 00:00:00', '2023-08-28', '2023-08-28 23:38:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(714, 45, NULL, '2023-08-29 12:49:40', '2023-08-29', '2023-08-30 00:06:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(715, 45, NULL, '2023-08-30 14:54:41', '2023-08-30', '2023-08-30 22:59:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(716, 45, NULL, '0000-00-00 00:00:00', '2023-08-31', '2023-09-01 00:27:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(717, 46, NULL, '2023-08-01 11:31:56', '2023-08-01', '2023-08-01 23:17:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(718, 46, NULL, '2023-08-02 11:50:22', '2023-08-02', '2023-08-02 22:10:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(719, 46, NULL, '2023-08-03 11:51:16', '2023-08-03', '2023-08-03 22:27:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(720, 46, NULL, '2023-08-04 12:11:19', '2023-08-04', '2023-08-04 21:49:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(721, 46, NULL, '2023-08-05 11:40:15', '2023-08-05', '2023-08-05 22:25:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(722, 46, NULL, '2023-08-07 12:10:52', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(723, 46, NULL, '2023-08-08 11:43:25', '2023-08-08', '2023-08-08 21:55:47', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(724, 46, NULL, '2023-08-09 11:31:28', '2023-08-09', '2023-08-09 22:37:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(725, 46, NULL, '2023-08-10 11:41:06', '2023-08-10', '2023-08-10 21:53:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(726, 46, NULL, '2023-08-11 11:30:05', '2023-08-11', '2023-08-11 22:23:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(727, 46, NULL, '2023-08-12 11:49:24', '2023-08-12', '2023-08-12 23:30:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(728, 46, NULL, '2023-08-15 12:59:04', '2023-08-15', '2023-08-15 22:23:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(729, 46, NULL, '2023-08-16 16:25:40', '2023-08-16', '2023-08-16 21:08:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(730, 46, NULL, '2023-08-17 11:41:02', '2023-08-17', '2023-08-17 20:33:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(731, 46, NULL, '2023-08-18 12:02:11', '2023-08-18', '2023-08-18 21:28:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(732, 46, NULL, '2023-08-19 11:37:18', '2023-08-19', '2023-08-19 21:16:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(733, 46, NULL, '2023-08-21 11:40:17', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(734, 46, NULL, '2023-08-22 11:37:44', '2023-08-22', '2023-08-22 21:43:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(735, 46, NULL, '2023-08-23 11:41:26', '2023-08-23', '2023-08-23 21:36:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(736, 46, NULL, '2023-08-24 11:44:35', '2023-08-24', '2023-08-24 21:46:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(737, 46, NULL, '2023-08-25 11:55:39', '2023-08-25', '2023-08-25 21:46:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(738, 46, NULL, '2023-08-26 12:34:12', '2023-08-26', '2023-08-26 22:11:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(739, 46, NULL, '2023-08-28 12:18:38', '2023-08-28', '2023-08-28 22:56:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(740, 46, NULL, '2023-08-29 12:02:16', '2023-08-29', '2023-08-29 23:29:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(741, 46, NULL, '2023-08-30 12:12:03', '2023-08-30', '2023-08-30 22:08:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(742, 46, NULL, '2023-08-31 11:35:02', '2023-08-31', '2023-09-01 01:40:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(743, 47, NULL, '2023-08-01 12:06:24', '2023-08-01', '2023-08-02 01:37:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(744, 47, NULL, '2023-08-02 11:04:05', '2023-08-02', '2023-08-02 19:56:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(745, 47, NULL, '2023-08-03 12:13:55', '2023-08-03', '2023-08-03 20:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(746, 47, NULL, '2023-08-04 11:31:40', '2023-08-04', '2023-08-04 20:01:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(747, 47, NULL, '2023-08-05 11:29:57', '2023-08-05', '2023-08-05 23:09:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(748, 47, NULL, '2023-08-07 11:26:58', '2023-08-07', '2023-08-07 19:58:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(749, 47, NULL, '2023-08-08 12:00:50', '2023-08-08', '2023-08-08 20:01:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(750, 47, NULL, '2023-08-09 11:51:09', '2023-08-09', '2023-08-09 20:00:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(751, 47, NULL, '2023-08-10 11:26:52', '2023-08-10', '2023-08-10 20:02:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(752, 47, NULL, '2023-08-11 11:32:04', '2023-08-11', '2023-08-11 20:15:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(753, 47, NULL, '2023-08-12 11:27:17', '2023-08-12', '2023-08-12 21:52:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(754, 47, NULL, '2023-08-15 11:53:40', '2023-08-15', '2023-08-15 20:10:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(755, 47, NULL, '2023-08-16 11:45:46', '2023-08-16', '2023-08-16 20:02:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(756, 47, NULL, '2023-08-17 11:29:54', '2023-08-17', '2023-08-17 19:33:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(757, 47, NULL, '2023-08-18 11:35:43', '2023-08-18', '2023-08-18 20:11:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(758, 47, NULL, '2023-08-19 12:27:51', '2023-08-19', '2023-08-19 20:11:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(759, 47, NULL, '2023-08-21 11:54:31', '2023-08-21', '2023-08-21 20:06:42', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(760, 47, NULL, '2023-08-22 11:50:43', '2023-08-22', '2023-08-22 20:10:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(761, 47, NULL, '2023-08-23 11:42:50', '2023-08-23', '2023-08-23 20:01:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(762, 47, NULL, '2023-08-24 11:43:16', '2023-08-24', '2023-08-24 20:04:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(763, 47, NULL, '2023-08-25 11:59:35', '2023-08-25', '2023-08-25 20:08:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(764, 47, NULL, '2023-08-26 11:55:19', '2023-08-26', '2023-08-26 20:04:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(765, 47, NULL, '2023-08-28 11:44:13', '2023-08-28', '2023-08-28 20:02:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(766, 47, NULL, '2023-08-29 12:06:12', '2023-08-29', '2023-08-29 20:00:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(767, 47, NULL, '2023-08-30 11:36:04', '2023-08-30', '2023-08-30 21:03:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(768, 47, NULL, '2023-08-31 11:47:49', '2023-08-31', '2023-08-31 20:11:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(769, 51, NULL, '2023-08-01 11:25:01', '2023-08-01', '2023-08-01 23:08:52', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(770, 51, NULL, '2023-08-02 11:52:48', '2023-08-02', '2023-08-02 22:14:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(771, 51, NULL, '2023-08-03 11:22:10', '2023-08-03', '2023-08-03 22:25:43', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(772, 51, NULL, '2023-08-04 11:53:08', '2023-08-04', '2023-08-04 21:11:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(773, 51, NULL, '2023-08-05 11:38:09', '2023-08-05', '2023-08-05 22:28:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(774, 51, NULL, '2023-08-07 11:31:21', '2023-08-07', '2023-08-07 23:10:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(775, 51, NULL, '2023-08-08 11:31:01', '2023-08-08', '2023-08-08 21:41:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(776, 51, NULL, '2023-08-09 11:41:16', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(777, 51, NULL, '2023-08-10 11:41:15', '2023-08-10', '2023-08-10 21:59:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(778, 51, NULL, '2023-08-11 11:42:30', '2023-08-11', '2023-08-11 22:04:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL);
INSERT INTO `attendance` (`RecId`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(779, 51, NULL, '2023-08-12 11:32:03', '2023-08-12', '2023-08-12 23:30:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(780, 51, NULL, '2023-08-15 11:23:10', '2023-08-15', '2023-08-15 21:52:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(781, 51, NULL, '2023-08-16 11:36:55', '2023-08-16', '2023-08-16 20:59:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(782, 51, NULL, '2023-08-17 11:36:12', '2023-08-17', '2023-08-18 11:26:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(783, 51, NULL, '2023-08-18 11:27:01', '2023-08-18', '2023-08-18 22:17:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(784, 51, NULL, '2023-08-19 11:20:45', '2023-08-19', '2023-08-19 21:16:29', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(785, 51, NULL, '2023-08-21 11:32:03', '2023-08-21', '2023-08-21 21:32:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(786, 51, NULL, '2023-08-22 11:55:36', '2023-08-22', '2023-08-22 21:54:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(787, 51, NULL, '0000-00-00 00:00:00', '2023-08-23', '2023-08-23 21:38:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(788, 51, NULL, '2023-08-24 12:01:31', '2023-08-24', '2023-08-24 21:46:45', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(789, 51, NULL, '2023-08-25 11:48:24', '2023-08-25', '2023-08-25 21:44:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(790, 51, NULL, '2023-08-26 11:34:36', '2023-08-26', '2023-08-26 22:11:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(791, 51, NULL, '2023-08-28 11:37:11', '2023-08-28', '2023-08-28 22:52:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(792, 51, NULL, '2023-08-29 11:31:21', '2023-08-29', '2023-08-29 23:34:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(793, 51, NULL, '2023-08-30 11:50:56', '2023-08-30', '2023-08-30 22:04:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(794, 51, NULL, '2023-08-31 10:31:29', '2023-08-31', '2023-09-01 01:40:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(795, 61, NULL, '2023-08-01 11:21:40', '2023-08-01', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(796, 61, NULL, '2023-08-03 11:15:59', '2023-08-03', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(797, 61, NULL, '2023-08-04 11:26:50', '2023-08-04', '2023-08-04 20:44:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(798, 61, NULL, '2023-08-05 11:19:33', '2023-08-05', '2023-08-05 20:44:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(799, 61, NULL, '2023-08-07 11:21:09', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(800, 61, NULL, '0000-00-00 00:00:00', '2023-08-08', '2023-08-08 20:44:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(801, 61, NULL, '2023-08-10 11:29:05', '2023-08-10', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(802, 61, NULL, '2023-08-11 11:29:07', '2023-08-11', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(803, 61, NULL, '2023-08-12 11:19:53', '2023-08-12', '2023-08-12 21:11:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(804, 61, NULL, '2023-08-15 11:42:36', '2023-08-15', '2023-08-15 20:58:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(805, 61, NULL, '2023-08-16 11:30:17', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(806, 61, NULL, '2023-08-17 11:18:22', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(807, 61, NULL, '2023-08-18 11:35:28', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(808, 61, NULL, '2023-08-19 11:31:46', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(809, 61, NULL, '2023-08-21 11:39:41', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(810, 61, NULL, '2023-08-22 11:22:09', '2023-08-22', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(811, 61, NULL, '2023-08-23 11:19:24', '2023-08-23', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(812, 61, NULL, '2023-08-24 11:21:29', '2023-08-24', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(813, 61, NULL, '2023-08-25 11:34:18', '2023-08-25', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(814, 61, NULL, '2023-08-26 12:21:05', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(815, 61, NULL, '2023-08-28 11:26:34', '2023-08-28', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(816, 61, NULL, '2023-08-29 11:31:08', '2023-08-29', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(817, 61, NULL, '2023-08-30 11:21:31', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(818, 61, NULL, '2023-08-31 11:27:28', '2023-08-31', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(819, 63, NULL, '2023-08-01 11:22:18', '2023-08-01', '2023-08-01 23:07:46', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(820, 63, NULL, '2023-08-02 11:26:12', '2023-08-02', '2023-08-02 22:14:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(821, 63, NULL, '2023-08-03 11:16:09', '2023-08-03', '2023-08-03 22:45:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(822, 63, NULL, '2023-08-04 11:15:25', '2023-08-04', '2023-08-04 21:34:31', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(823, 63, NULL, '2023-08-05 11:26:48', '2023-08-05', '2023-08-05 22:25:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(824, 63, NULL, '2023-08-07 11:24:30', '2023-08-07', '2023-08-07 23:10:32', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(825, 63, NULL, '2023-08-08 11:31:51', '2023-08-08', '2023-08-08 21:48:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(826, 63, NULL, '2023-08-09 11:27:28', '2023-08-09', '2023-08-09 22:24:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(827, 63, NULL, '2023-08-10 11:34:42', '2023-08-10', '2023-08-10 21:41:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(828, 63, NULL, '2023-08-11 11:38:42', '2023-08-11', '2023-08-11 22:06:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(829, 63, NULL, '2023-08-12 11:30:51', '2023-08-12', '2023-08-12 23:29:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(830, 63, NULL, '2023-08-15 11:28:34', '2023-08-15', '2023-08-15 21:50:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(831, 63, NULL, '2023-08-16 11:35:01', '2023-08-16', '2023-08-16 21:05:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(832, 63, NULL, '2023-08-17 11:35:31', '2023-08-17', '2023-08-17 20:20:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(833, 63, NULL, '2023-08-18 11:27:59', '2023-08-18', '2023-08-18 21:18:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(834, 63, NULL, '2023-08-19 11:28:28', '2023-08-19', '2023-08-19 20:58:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(835, 63, NULL, '2023-08-21 11:18:16', '2023-08-21', '2023-08-21 21:33:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(836, 63, NULL, '2023-08-22 11:30:30', '2023-08-22', '2023-08-22 21:42:35', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(837, 63, NULL, '2023-08-23 11:26:47', '2023-08-23', '2023-08-23 21:41:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(838, 63, NULL, '2023-08-24 11:26:03', '2023-08-24', '2023-08-24 21:46:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(839, 63, NULL, '2023-08-25 11:50:36', '2023-08-25', '2023-08-25 21:17:37', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(840, 63, NULL, '2023-08-26 11:33:05', '2023-08-26', '2023-08-26 22:08:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(841, 63, NULL, '2023-08-28 11:36:59', '2023-08-28', '2023-08-28 23:06:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(842, 63, NULL, '2023-08-29 11:45:51', '2023-08-29', '2023-08-29 23:34:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(843, 63, NULL, '2023-08-30 11:59:38', '2023-08-30', '2023-08-30 22:03:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(844, 63, NULL, '2023-08-31 11:33:29', '2023-08-31', '2023-09-01 01:40:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(845, 70, NULL, '2023-08-01 12:36:50', '2023-08-01', '2023-08-01 21:33:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(846, 70, NULL, '2023-08-02 11:40:33', '2023-08-02', '2023-08-02 21:38:02', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(847, 70, NULL, '2023-08-03 11:54:21', '2023-08-03', '2023-08-03 21:54:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(848, 70, NULL, '2023-08-04 12:13:02', '2023-08-04', '2023-08-04 21:37:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(849, 70, NULL, '2023-08-05 11:41:48', '2023-08-05', '2023-08-05 22:11:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(850, 70, NULL, '2023-08-07 11:55:39', '2023-08-07', '2023-08-07 21:46:07', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(851, 70, NULL, '2023-08-08 11:38:16', '2023-08-08', '2023-08-08 21:40:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(852, 70, NULL, '2023-08-09 12:00:29', '2023-08-09', '2023-08-09 21:32:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(853, 70, NULL, '2023-08-10 11:45:39', '2023-08-10', '2023-08-10 21:29:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(854, 70, NULL, '2023-08-11 11:51:41', '2023-08-11', '2023-08-11 21:18:12', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(855, 70, NULL, '2023-08-12 11:36:45', '2023-08-12', '2023-08-12 22:20:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(856, 70, NULL, '2023-08-15 11:42:03', '2023-08-15', '2023-08-15 21:29:21', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(857, 70, NULL, '2023-08-16 11:37:14', '2023-08-16', '2023-08-16 21:15:41', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(858, 70, NULL, '2023-08-17 11:27:32', '2023-08-17', '2023-08-17 21:25:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(859, 70, NULL, '2023-08-18 11:35:36', '2023-08-18', '2023-08-18 21:16:34', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(860, 70, NULL, '2023-08-19 11:30:34', '2023-08-19', '2023-08-19 21:30:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(861, 70, NULL, '2023-08-21 12:04:44', '2023-08-21', '2023-08-21 21:54:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(862, 70, NULL, '2023-08-22 10:38:24', '2023-08-22', '2023-08-22 21:40:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(863, 70, NULL, '2023-08-23 15:13:37', '2023-08-23', '2023-08-23 21:52:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(864, 70, NULL, '2023-08-24 12:09:04', '2023-08-24', '2023-08-24 21:38:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(865, 70, NULL, '2023-08-25 11:46:05', '2023-08-25', '2023-08-25 21:40:05', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(866, 70, NULL, '2023-08-26 11:14:42', '2023-08-26', '2023-08-26 21:33:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(867, 70, NULL, '2023-08-28 11:43:58', '2023-08-28', '2023-08-28 21:41:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(868, 70, NULL, '2023-08-29 11:49:17', '2023-08-29', '2023-08-29 21:20:40', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(869, 70, NULL, '2023-08-30 11:51:58', '2023-08-30', '2023-08-30 15:33:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(870, 70, NULL, '2023-08-31 11:59:08', '2023-08-31', '2023-08-31 21:33:44', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(871, 71, NULL, '2023-08-01 11:38:05', '2023-08-01', '2023-08-01 21:07:39', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(872, 71, NULL, '2023-08-02 11:39:58', '2023-08-02', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(873, 71, NULL, '2023-08-03 11:39:43', '2023-08-03', '2023-08-03 20:31:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(874, 71, NULL, '2023-08-04 11:43:45', '2023-08-04', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(875, 71, NULL, '2023-08-05 11:35:51', '2023-08-05', '2023-08-05 20:20:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(876, 71, NULL, '2023-08-07 11:44:01', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(877, 71, NULL, '2023-08-08 11:42:03', '2023-08-08', '2023-08-08 20:38:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(878, 71, NULL, '2023-08-09 11:41:55', '2023-08-09', '2023-08-09 20:34:06', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(879, 71, NULL, '2023-08-10 11:43:33', '2023-08-10', '2023-08-10 19:50:15', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(880, 71, NULL, '2023-08-12 11:44:03', '2023-08-12', '2023-08-12 21:26:23', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(881, 71, NULL, '2023-08-15 11:40:51', '2023-08-15', '2023-08-15 20:30:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(882, 71, NULL, '2023-08-16 11:37:51', '2023-08-16', '2023-08-16 20:33:20', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(883, 71, NULL, '2023-08-17 13:24:49', '2023-08-17', '2023-08-17 20:30:30', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(884, 71, NULL, '2023-08-18 11:40:35', '2023-08-18', '2023-08-18 20:34:11', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(885, 71, NULL, '2023-08-19 11:38:34', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(886, 71, NULL, '2023-08-21 11:43:03', '2023-08-21', '2023-08-21 20:32:13', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(887, 71, NULL, '2023-08-22 11:44:30', '2023-08-22', '2023-08-22 20:31:48', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(888, 71, NULL, '2023-08-23 11:45:38', '2023-08-23', '2023-08-23 20:38:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(889, 71, NULL, '2023-08-24 11:36:37', '2023-08-24', '2023-08-24 20:45:59', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(890, 71, NULL, '2023-08-25 11:39:55', '2023-08-25', '2023-08-25 20:34:26', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(891, 71, NULL, '2023-08-26 11:39:42', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(892, 71, NULL, '2023-08-28 11:42:58', '2023-08-28', '2023-08-28 20:30:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(893, 71, NULL, '2023-08-29 11:42:15', '2023-08-29', '2023-08-29 20:30:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(894, 71, NULL, '2023-08-30 11:40:08', '2023-08-30', '2023-08-30 20:34:24', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(895, 71, NULL, '2023-08-31 11:40:06', '2023-08-31', '2023-08-31 20:38:14', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(896, 75, NULL, '2023-08-04 11:35:52', '2023-08-04', '2023-08-04 20:52:08', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(897, 75, NULL, '2023-08-05 11:57:45', '2023-08-05', '2023-08-05 20:48:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(898, 75, NULL, '2023-08-07 12:13:17', '2023-08-07', '2023-08-07 21:16:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(899, 75, NULL, '2023-08-08 12:06:04', '2023-08-08', '2023-08-08 21:57:17', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(900, 75, NULL, '2023-08-09 11:51:43', '2023-08-09', '2023-08-09 20:48:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(901, 75, NULL, '2023-08-10 12:35:31', '2023-08-10', '2023-08-10 21:58:03', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(902, 75, NULL, '2023-08-11 13:03:30', '2023-08-11', '2023-08-11 20:48:56', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(903, 75, NULL, '2023-08-12 11:59:03', '2023-08-12', '2023-08-12 21:05:18', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(904, 75, NULL, '2023-08-16 11:50:19', '2023-08-15', '2023-08-15 21:22:49', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(905, 75, NULL, '2023-08-16 11:50:19', '2023-08-16', '2023-08-16 21:16:55', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(906, 75, NULL, '2023-08-17 12:07:15', '2023-08-17', '2023-08-17 21:34:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(907, 75, NULL, '2023-08-18 11:54:44', '2023-08-18', '2023-08-18 21:07:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(908, 75, NULL, '2023-08-19 11:46:36', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(909, 75, NULL, '2023-08-21 12:17:44', '2023-08-21', '2023-08-21 22:25:10', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(910, 75, NULL, '2023-08-22 11:52:18', '2023-08-22', '2023-08-22 21:19:25', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(911, 75, NULL, '0000-00-00 00:00:00', '2023-08-23', '2023-08-23 21:51:51', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(912, 75, NULL, '2023-08-24 12:25:09', '2023-08-24', '2023-08-24 21:03:09', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(913, 75, NULL, '2023-08-25 12:02:06', '2023-08-25', '2023-08-25 21:25:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(914, 75, NULL, '2023-08-26 18:21:36', '2023-08-26', '2023-08-26 20:53:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(915, 75, NULL, '2023-08-28 12:01:08', '2023-08-28', '2023-08-28 21:28:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(916, 75, NULL, '2023-08-29 12:11:06', '2023-08-29', '2023-08-29 21:19:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(917, 75, NULL, '2023-08-30 11:51:03', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(918, 75, NULL, '2023-08-31 12:10:32', '2023-08-31', '2023-08-31 21:47:58', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(919, 76, NULL, '2023-08-09 11:52:54', '2023-08-08', '2023-08-08 20:31:33', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(920, 76, NULL, '2023-08-09 11:52:54', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(921, 76, NULL, '2023-08-10 11:48:47', '2023-08-10', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(922, 76, NULL, '2023-08-11 12:24:36', '2023-08-11', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(923, 76, NULL, '2023-08-12 12:01:16', '2023-08-12', '2023-08-12 21:15:19', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(924, 76, NULL, '2023-08-15 12:21:02', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(925, 76, NULL, '2023-08-16 12:25:03', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(926, 76, NULL, '2023-08-17 12:15:44', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(927, 76, NULL, '2023-08-18 12:02:23', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(928, 76, NULL, '2023-08-19 11:59:03', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(929, 76, NULL, '2023-08-21 12:04:38', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(930, 76, NULL, '2023-08-22 12:12:07', '2023-08-22', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(931, 76, NULL, '2023-08-23 12:24:36', '2023-08-23', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(932, 76, NULL, '2023-08-24 11:56:55', '2023-08-24', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(933, 76, NULL, '2023-08-25 12:30:00', '2023-08-25', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(934, 76, NULL, '2023-08-26 12:00:56', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(935, 76, NULL, '2023-08-29 12:05:50', '2023-08-29', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(936, 76, NULL, '2023-08-30 12:09:35', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(937, 76, NULL, '2023-08-31 12:03:44', '2023-08-31', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(938, 78, NULL, '0000-00-00 00:00:00', '2023-08-19', '2023-08-19 20:45:38', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(939, 78, NULL, '2023-08-21 12:09:34', '2023-08-21', '2023-08-21 20:55:54', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(940, 78, NULL, '2023-08-22 12:28:12', '2023-08-22', '2023-08-22 20:45:16', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(941, 78, NULL, '2023-08-23 10:50:32', '2023-08-23', '2023-08-23 20:23:53', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(942, 78, NULL, '2023-08-24 11:48:29', '2023-08-24', '2023-08-24 20:39:36', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(943, 78, NULL, '2023-08-25 12:01:09', '2023-08-25', '2023-08-25 20:37:22', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(944, 78, NULL, '2023-08-26 12:29:31', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(945, 78, NULL, '2023-08-28 12:15:29', '2023-08-28', '2023-08-28 20:34:04', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(946, 78, NULL, '2023-08-29 12:37:38', '2023-08-29', '2023-08-29 20:47:28', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(947, 78, NULL, '2023-08-30 12:21:30', '2023-08-30', '2023-08-30 20:38:27', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(948, 78, NULL, '2023-08-31 12:28:38', '2023-08-31', '0000-00-00 00:00:00', '00:00:00', 1, 0, NULL, '0000-00-00 00:00:00', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `designation`
--

CREATE TABLE `designation` (
  `RecId` int(10) NOT NULL,
  `designation_name` varchar(50) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `designation`
--

INSERT INTO `designation` (`RecId`, `designation_name`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'Inovi Technology', 1, 1, NULL, '2023-08-31 10:51:56', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `devicetable`
--

CREATE TABLE `devicetable` (
  `Device_Id` int(11) NOT NULL,
  `Device_Name` varchar(50) NOT NULL,
  `Connection_Type` varchar(50) NOT NULL,
  `Network_Parameter` varchar(50) NOT NULL,
  `Serial_No` varchar(50) NOT NULL,
  `IP_Address` varchar(50) NOT NULL,
  `Port_No` varchar(50) NOT NULL,
  `Connected_Table` varchar(50) NOT NULL,
  `Status` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `updated_by` int(11) NOT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `devicetable`
--

INSERT INTO `devicetable` (`Device_Id`, `Device_Name`, `Connection_Type`, `Network_Parameter`, `Serial_No`, `IP_Address`, `Port_No`, `Connected_Table`, `Status`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'IVMS-4200', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 1, 1, 1, '2023-08-09 00:00:00', '2023-08-09 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays` (
  `RecId` int(10) NOT NULL,
  `Title` varchar(50) NOT NULL,
  `Holiday_Date` date NOT NULL,
  `isactive` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(11) NOT NULL,
  `updated_by` int(11) NOT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `holidays`
--

INSERT INTO `holidays` (`RecId`, `Title`, `Holiday_Date`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'Kashmir Solidarity Day', '2023-02-05', 1, 1, 1, '2023-08-21 08:35:31', '2023-08-21 08:35:31'),
(2, 'Pakistan Day', '2023-03-23', 1, 1, 1, '2023-08-21 08:38:59', '2023-08-21 08:38:59'),
(3, 'Labour Day', '2023-05-01', 1, 1, 1, '2023-08-21 08:39:46', '2023-08-21 08:39:46'),
(4, 'Independence Day', '2023-08-14', 1, 1, 1, '2023-08-21 08:40:26', '2023-08-21 08:40:26'),
(5, 'Defense Day', '2023-09-06', 1, 1, 1, '2023-08-21 08:41:02', '2023-08-21 08:41:02'),
(6, 'Iqbal Day', '2023-11-09', 1, 1, 1, '2023-08-21 08:41:51', '2023-08-21 08:41:51'),
(7, 'Quaid-e-Azam Day', '2023-12-25', 1, 1, 1, '2023-08-21 08:42:25', '2023-08-21 08:42:25');

-- --------------------------------------------------------

--
-- Table structure for table `payroll`
--

CREATE TABLE `payroll` (
  `RecId` int(10) NOT NULL,
  `UserP_Id` int(10) NOT NULL,
  `Designation_Id` int(10) NOT NULL,
  `Shift_Id` int(10) NOT NULL,
  `Pay_Id` int(10) NOT NULL,
  `time_in` datetime NOT NULL,
  `time_out` datetime NOT NULL,
  `salary` double DEFAULT 0,
  `deducted_days` int(11) DEFAULT 0,
  `late` int(11) DEFAULT 0,
  `absent` int(11) DEFAULT 0,
  `Deduction` double DEFAULT 0,
  `M_Deducted` double DEFAULT 0,
  `Total_Pay` double DEFAULT 0,
  `M_Salary` double DEFAULT 0,
  `Remarks` varchar(255) DEFAULT NULL,
  `Status` int(11) NOT NULL DEFAULT 0,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime DEFAULT current_timestamp(),
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------

--
-- Table structure for table `pay_scale`
--

CREATE TABLE `pay_scale` (
  `RecId` int(10) NOT NULL,
  `pay_name` varchar(50) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `pay_scale`
--

INSERT INTO `pay_scale` (`RecId`, `pay_name`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'Monthly', 1, 1, 1, '2023-08-09 00:00:00', '2023-08-22 11:48:07'),
(2, 'Hourly', 1, 1, NULL, '2023-09-01 22:00:06', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `permission`
--

CREATE TABLE `permission` (
  `RecId` int(11) NOT NULL,
  `permisssion_name` varchar(50) NOT NULL,
  `controller` varchar(50) NOT NULL,
  `action` varchar(50) NOT NULL,
  `parameters` varchar(50) NOT NULL,
  `method` varchar(50) NOT NULL,
  `icon` varchar(50) NOT NULL,
  `sort` int(11) NOT NULL,
  `Permission_Id` int(10) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `permission`
--

INSERT INTO `permission` (`RecId`, `permisssion_name`, `controller`, `action`, `parameters`, `method`, `icon`, `sort`, `Permission_Id`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'HR', 'HR', 'POST', 'EDIT', 'GET', 'MENU', 1, 1, 1, 1, NULL, '2023-08-31 18:17:57', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `permission_assign`
--

CREATE TABLE `permission_assign` (
  `RecId` int(10) NOT NULL,
  `Role_Id` int(10) NOT NULL,
  `Permission_Id` int(10) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `permission_assign`
--

INSERT INTO `permission_assign` (`RecId`, `Role_Id`, `Permission_Id`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 1, 1, 1, 1, 1, '2023-08-09 00:00:00', '2023-08-09 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role` (
  `RecId` int(10) NOT NULL,
  `role_name` varchar(50) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`RecId`, `role_name`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'HR Manager', 1, 1, NULL, '2023-08-31 09:11:29', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `shift`
--

CREATE TABLE `shift` (
  `RecId` int(10) NOT NULL,
  `shift_name` varchar(50) NOT NULL,
  `time_in` time NOT NULL,
  `time_out` time NOT NULL,
  `grace_time` time NOT NULL,
  `isactive` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `shift`
--

INSERT INTO `shift` (`RecId`, `shift_name`, `time_in`, `time_out`, `grace_time`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, '(I-T)Morning(11:30am to 8:30pm)', '11:30:00', '20:30:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28', NULL),
(2, '(I-S)DAY(Production)Morning (12:00pm to 9:00pm)', '12:00:00', '21:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 17:56:27', NULL),
(3, '(I-S)MID SHIFT(6:00pm to 3:00am)', '18:00:00', '03:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28', NULL),
(4, '(I-S)Mid Late(7:00pm to 4:00am)', '19:00:00', '04:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 17:56:27', NULL),
(5, '(I-S)Night(9:00pm to 6:00am)', '21:00:00', '06:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28', NULL),
(6, '(I-S)Part time(6:00pm to 12:00am)', '18:00:00', '23:59:59', '00:15:00', 1, 1, NULL, '2023-08-31 17:56:27', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `tbl_gender`
--

CREATE TABLE `tbl_gender` (
  `RecId` int(10) NOT NULL,
  `Gender` varchar(10) NOT NULL,
  `isactive` tinyint(1) NOT NULL DEFAULT 1,
  `created_by` int(2) NOT NULL,
  `updated_by` int(2) NOT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_gender`
--

INSERT INTO `tbl_gender` (`RecId`, `Gender`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 'Male', 1, 1, 1, '2023-08-24 11:09:14', '2023-08-24 11:09:14'),
(2, 'Female', 1, 1, 1, '2023-08-24 11:09:14', '2023-08-24 11:09:14'),
(3, 'Other', 1, 1, 1, '2023-08-24 11:15:03', '2023-08-24 11:15:03');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_machinedata`
--

CREATE TABLE `tbl_machinedata` (
  `ID` varchar(50) NOT NULL,
  `DateAndTime` datetime NOT NULL,
  `Date` date NOT NULL,
  `Time` time NOT NULL,
  `Status` varchar(50) NOT NULL,
  `Device` varchar(255) NOT NULL,
  `DeviceNo` varchar(255) NOT NULL,
  `Person_Name` varchar(25) NOT NULL,
  `Card_No` varchar(25) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `tbl_machinedata`
--

INSERT INTO `tbl_machinedata` (`ID`, `DateAndTime`, `Date`, `Time`, `Status`, `Device`, `DeviceNo`, `Person_Name`, `Card_No`) VALUES
('1', '2023-08-17 08:02:31', '2023-08-17', '08:02:31', '1', 'IVMS_4200', '5575345546', '1', ''),
('2', '2023-08-18 08:04:13', '2023-08-18', '08:04:13', '1', 'iVMS_4200i', '645832287', '1', ''),
('3', '2023-08-19 08:05:44', '2023-08-19', '08:05:44', '1', 'IVMS-4200', '6534654', '1', ''),
('4', '2023-08-20 08:05:44', '2023-08-20', '08:05:44', '', 'IVMS-4200', '67336435', '1', ''),
('5', '2023-08-21 08:11:51', '2023-08-21', '08:11:51', '1', 'IVMS_4200', '643725542', '1', ''),
('6', '2023-08-22 08:11:51', '2023-08-22', '08:11:51', '1', 'IVMS-4200', '63734653', '1', ''),
('500', '2023-08-17 20:05:17', '2023-08-17', '08:02:31', '1', '88888', '88', '1', '');

--
-- Triggers `tbl_machinedata`
--
DELIMITER $$
CREATE TRIGGER `Trigger_Pull_Data` AFTER INSERT ON `tbl_machinedata` FOR EACH ROW BEGIN
   DECLARE ClockIn DATETIME;
    DECLARE ClockOut DATETIME;

    -- Find the earliest clock in time
    SELECT Time INTO ClockIn
    FROM tbl_machinedata
    WHERE ID = NEW.ID AND Date = NEW.Date
    ORDER BY Time DESC
    LIMIT 1;

    -- Find the latest clock out time
    SELECT Time INTO ClockOut
    FROM tbl_machinedata
    WHERE ID = NEW.ID AND Date = NEW.Date
    ORDER BY Time ASC
    LIMIT 1;

    -- Update the new attendance record with the earliest clock in and latest clock out times
    UPDATE attendance as a 
    SET a.check_in = ClockIn, a.check_out = ClockOut
    WHERE a.Employee_Id = NEW.ID AND a.check_in_date = NEW.Date;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user` (
  `RecId` int(10) NOT NULL,
  `UserP_Id` int(10) NOT NULL,
  `Role_Id` int(10) NOT NULL,
  `username` varchar(50) NOT NULL,
  `password` varchar(50) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`RecId`, `UserP_Id`, `Role_Id`, `username`, `password`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 43, 1, 'Admin', '123', 1, 1, NULL, '2023-08-31 09:09:39', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_profile`
--

CREATE TABLE `user_profile` (
  `RecId` int(10) NOT NULL,
  `Designation_Id` int(10) DEFAULT NULL,
  `Employee_Id` varchar(50) NOT NULL,
  `payscale_id` int(10) DEFAULT NULL,
  `shift_id` int(10) DEFAULT NULL,
  `firstname` varchar(50) NOT NULL,
  `lastname` varchar(50) NOT NULL,
  `address` text NOT NULL,
  `contact` int(10) NOT NULL,
  `gender` int(10) NOT NULL,
  `workingDays` int(5) DEFAULT 5,
  `salary` double NOT NULL,
  `Cheak_value` tinyint(1) NOT NULL,
  `isactive` tinyint(1) DEFAULT 1,
  `created_by` int(10) NOT NULL,
  `updated_by` int(10) DEFAULT NULL,
  `created_on` datetime NOT NULL,
  `updated_on` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

--
-- Dumping data for table `user_profile`
--

INSERT INTO `user_profile` (`RecId`, `Designation_Id`, `Employee_Id`, `payscale_id`, `shift_id`, `firstname`, `lastname`, `address`, `contact`, `gender`, `workingDays`, `salary`, `Cheak_value`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`) VALUES
(1, 1, '1', 1, 5, 'ARSALAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(2, 1, '2', 1, 5, 'FARHAN RAZZAQ', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(3, 1, '3', 1, 5, 'ABRAR', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(4, 1, '4', 1, 3, 'FARRUKH', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(5, 1, '5', 1, 5, 'MUHAMMAD JIBRAN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(6, 1, '6', 1, 5, 'SAAD SAEED', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(7, 1, '7', 1, 5, 'ABDUL SUBHAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(8, 1, '8', 1, 6, 'SYED TALHA SALMAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(9, 1, '9', 1, 5, 'ALIYAAN AHMED', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(10, 1, '10', 1, 4, 'VARUN KUMAR', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(11, 1, '11', 1, 2, 'MUHAMMAD ANIQ', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(12, 1, '12', 1, 5, 'MUHAMMAD FURQAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(13, 1, '13', 1, 5, 'ZOHRAN AHMED', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(14, 1, '14', 1, 1, 'MUHAMMAD SHAHRYAR', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(15, 1, '15', 1, 5, 'MUJTABA KHAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(16, 1, '16', 1, 1, 'NADEEM ZUBARI', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(17, 1, '17', 1, 1, 'IRFAN HUSSSIN', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(18, 1, '18', 1, 1, 'ABDUL REHMAN', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(19, 1, '19', 1, 1, 'SYED ALY RAZA', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(20, 1, '20', 1, 1, 'ANAS KHATRI', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(21, 1, '21', 1, 1, 'WAQAR NARSI', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(22, 1, '22', 1, 1, 'IRFAN KHAN', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(23, 1, '23', 1, 1, 'NOMAN KODWAWI', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(24, 1, '24', 1, 1, 'TAHIR WADIWALA', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(25, 1, '25', 1, 1, 'TAHA TABANI', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(26, 1, '26', 1, 1, 'SAMEER SALEEM', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(27, 1, '27', 1, 1, 'RIZWAN HUSSAIN', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(28, 1, '28', 1, 1, 'ABDUL AZEEM', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(29, 1, '29', 1, 1, 'MOHSIN ASLAM', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(30, 1, '30', 1, 1, 'SHAFIQ AHMED', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(31, 1, '31', 1, 1, 'RAYYAN MIANOOR', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(32, 1, '32', 1, 1, 'FAHAD FAISAL', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(33, 1, '33', 1, 1, 'MUHAMMAD ALI', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(34, 1, '34', 1, 1, 'IMRAN CHOUHAN', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(35, 1, '35', 1, 1, 'SALMAN QAZI', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(36, 1, '36', 1, 1, 'SYED AMMAR', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(37, 1, '37', 1, 1, 'HUSSAIN AHMED', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(38, 1, '38', 1, 1, 'ABDUL SAMAD', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(39, 1, '39', 1, 1, 'NADEEM AHMED', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(40, 1, '40', 1, 1, 'HAFIZ BILAL HASSAN', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(41, 1, '41', 1, 1, 'AZHAR KHAN', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(42, 1, '42', 1, 1, 'USAMA JAVED', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(43, 1, '43', 1, 1, 'TOOBA ALI', '', 'Karachi, Sindh', 2147483647, 2, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(44, 1, '44', 1, 1, 'TALHA MIANOOR', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(45, 1, '45', 1, 1, 'NOOR MUHAMMAD', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(46, 1, '46', 1, 1, 'ASIF SHAIKH', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(47, 1, '47', 1, 1, 'MUHAMMAD QASIM', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(48, 1, '48', 1, 2, 'SYED HASNAIN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(49, 1, '49', 1, 2, 'SUNWEETH ROBIN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(50, 1, '50', 1, 2, 'SAAD SULEMAN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(51, 1, '51', 1, 1, 'HARIS TARIQ', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(52, 1, '52', 1, 5, 'HUNAIN IMRAN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(53, 1, '53', 1, 4, 'ASHTAR ALI', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(54, 1, '54', 1, 2, 'SYED SAQIB', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(55, 1, '55', 1, 4, 'ABDULLAH REHMAN', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(56, 1, '56', 1, 2, 'MURTAZA KHAN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(57, 1, '57', 1, 4, 'ANAS FAROOQ', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(58, 1, '58', 1, 2, 'MUHAMMAD USMAN', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(59, 1, '59', 1, 3, 'SAHIL KHIMANI', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(60, 1, '60', 1, 2, 'M.UMAIR SHAFIQ', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(61, 1, '61', 1, 1, 'MUHAMMAD NAEEM', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(62, 1, '62', 1, 2, 'SYED AREEB', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(63, 1, '63', 1, 1, 'SAIM MAJID', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(64, 1, '64', 1, 5, 'M.FARIS SHEIKH', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(65, 1, '65', 1, 5, 'UMER DURANI', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(66, 1, '66', 1, 6, 'HAYA SHEIKH', '', 'Karachi, Sindh', 87654321, 2, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(67, 1, '67', 1, 4, 'ABDUL REHMAN RAZA', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(68, 1, '68', 1, 4, 'M.TARIQ', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(69, 1, '69', 1, 4, 'SOMIL RUPELA', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(70, 1, '70', 1, 1, 'ASLAM MEER', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(71, 1, '71', 1, 1, 'ZAFAR', '', 'Karachi, Sindh', 2147483647, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(72, 1, '72', 1, 5, 'HOOD BASIT', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(73, 1, '73', 1, 1, 'HUNAIN NADEEM', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(74, 1, '74', 1, 2, 'DANIYAL KHATRI', '', 'Karachi, Sindh', 2147483647, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(75, 1, '75', 1, 1, 'M.AFZAL', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(76, 1, '76', 1, 1, 'FAROOQ KHAN', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(77, 1, '77', 1, 5, 'MURTAZA MUGHAL', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(78, 1, '78', 1, 1, 'HAMMAD AFTAB', '', 'Karachi, Sindh', 87654321, 1, 6, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(79, 1, '79', 1, 2, 'AQIB RAZA', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL),
(80, 1, '80', 1, 2, 'DANIYAL SHAKEEL', '', 'Karachi, Sindh', 87654321, 1, 5, 0, 0, 1, 0, NULL, '0000-00-00 00:00:00', NULL);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `Device_Id` (`DeviceNo`);

--
-- Indexes for table `designation`
--
ALTER TABLE `designation`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `devicetable`
--
ALTER TABLE `devicetable`
  ADD PRIMARY KEY (`Device_Id`);

--
-- Indexes for table `holidays`
--
ALTER TABLE `holidays`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `holidays_ibfk_1` (`created_by`),
  ADD KEY `holidays_ibfk_2` (`updated_by`);

--
-- Indexes for table `payroll`
--
ALTER TABLE `payroll`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `UserP_Id` (`UserP_Id`),
  ADD KEY `Designation_Id` (`Designation_Id`),
  ADD KEY `Shift_Id` (`Shift_Id`),
  ADD KEY `Pay_Id` (`Pay_Id`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `pay_scale`
--
ALTER TABLE `pay_scale`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `permission`
--
ALTER TABLE `permission`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `permission_assign`
--
ALTER TABLE `permission_assign`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `Permission_Id` (`Permission_Id`),
  ADD KEY `Role_Id` (`Role_Id`),
  ADD KEY `updated_by` (`updated_by`),
  ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `shift`
--
ALTER TABLE `shift`
  ADD PRIMARY KEY (`RecId`),
  ADD KEY `created_by` (`created_by`),
  ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
  ADD PRIMARY KEY (`RecId`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
  ADD PRIMARY KEY (`RecId`),
  ADD UNIQUE KEY `username` (`username`),
  ADD KEY `UserP_Id` (`UserP_Id`),
  ADD KEY `Role_Id` (`Role_Id`);

--
-- Indexes for table `user_profile`
--
ALTER TABLE `user_profile`
  ADD PRIMARY KEY (`RecId`),
  ADD UNIQUE KEY `Employee_Id` (`Employee_Id`),
  ADD KEY `Designation_Id` (`Designation_Id`),
  ADD KEY `shift_id` (`shift_id`),
  ADD KEY `user_profile_ibfk_3` (`payscale_id`),
  ADD KEY `user_profile_ibfk_4` (`gender`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=949;

--
-- AUTO_INCREMENT for table `designation`
--
ALTER TABLE `designation`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `devicetable`
--
ALTER TABLE `devicetable`
  MODIFY `Device_Id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `holidays`
--
ALTER TABLE `holidays`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=8;

--
-- AUTO_INCREMENT for table `payroll`
--
ALTER TABLE `payroll`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `pay_scale`
--
ALTER TABLE `pay_scale`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=3;

--
-- AUTO_INCREMENT for table `permission`
--
ALTER TABLE `permission`
  MODIFY `RecId` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `permission_assign`
--
ALTER TABLE `permission_assign`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `shift`
--
ALTER TABLE `shift`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;

--
-- AUTO_INCREMENT for table `user_profile`
--
ALTER TABLE `user_profile`
  MODIFY `RecId` int(10) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=81;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
  ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `attendance_ibfk_3` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `designation`
--
ALTER TABLE `designation`
  ADD CONSTRAINT `designation_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `designation_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `holidays`
--
ALTER TABLE `holidays`
  ADD CONSTRAINT `holidays_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `holidays_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `payroll`
--
ALTER TABLE `payroll`
  ADD CONSTRAINT `payroll_ibfk_1` FOREIGN KEY (`UserP_Id`) REFERENCES `user_profile` (`RecId`),
  ADD CONSTRAINT `payroll_ibfk_2` FOREIGN KEY (`Designation_Id`) REFERENCES `designation` (`RecId`),
  ADD CONSTRAINT `payroll_ibfk_3` FOREIGN KEY (`Shift_Id`) REFERENCES `shift` (`RecId`),
  ADD CONSTRAINT `payroll_ibfk_4` FOREIGN KEY (`Pay_Id`) REFERENCES `pay_scale` (`RecId`),
  ADD CONSTRAINT `payroll_ibfk_5` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `payroll_ibfk_6` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `pay_scale`
--
ALTER TABLE `pay_scale`
  ADD CONSTRAINT `pay_scale_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `pay_scale_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `permission`
--
ALTER TABLE `permission`
  ADD CONSTRAINT `permission_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `permission_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `permission_assign`
--
ALTER TABLE `permission_assign`
  ADD CONSTRAINT `permission_assign_ibfk_2` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`RecId`),
  ADD CONSTRAINT `permission_assign_ibfk_3` FOREIGN KEY (`Permission_Id`) REFERENCES `permission` (`RecId`),
  ADD CONSTRAINT `permission_assign_ibfk_4` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`RecId`),
  ADD CONSTRAINT `permission_assign_ibfk_5` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `permission_assign_ibfk_6` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `role`
--
ALTER TABLE `role`
  ADD CONSTRAINT `role_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `role_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `shift`
--
ALTER TABLE `shift`
  ADD CONSTRAINT `shift_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`RecId`),
  ADD CONSTRAINT `shift_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`RecId`);

--
-- Constraints for table `user`
--
ALTER TABLE `user`
  ADD CONSTRAINT `user_ibfk_1` FOREIGN KEY (`UserP_Id`) REFERENCES `user_profile` (`RecId`),
  ADD CONSTRAINT `user_ibfk_2` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`RecId`),
  ADD CONSTRAINT `user_ibfk_3` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`RecId`);

--
-- Constraints for table `user_profile`
--
ALTER TABLE `user_profile`
  ADD CONSTRAINT `user_profile_ibfk_1` FOREIGN KEY (`Designation_Id`) REFERENCES `designation` (`RecId`),
  ADD CONSTRAINT `user_profile_ibfk_2` FOREIGN KEY (`shift_id`) REFERENCES `shift` (`RecId`),
  ADD CONSTRAINT `user_profile_ibfk_3` FOREIGN KEY (`payscale_id`) REFERENCES `pay_scale` (`RecId`),
  ADD CONSTRAINT `user_profile_ibfk_4` FOREIGN KEY (`gender`) REFERENCES `tbl_gender` (`RecId`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
