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
