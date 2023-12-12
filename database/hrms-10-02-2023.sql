-- phpMyAdmin SQL Dump
-- version 5.1.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Oct 02, 2023 at 08:16 PM
-- Server version: 10.4.20-MariaDB
-- PHP Version: 7.4.22

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT = @@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS = @@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION = @@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `hrms-10-02-2023`
--

DELIMITER $$
--
-- Procedures
--
CREATE
    DEFINER = `root`@`localhost` PROCEDURE `NotWorkng_StrProc_ChangeAttendanceInfo`(IN `EmpId` INT,
                                                                                    IN `check_in` VARCHAR(50),
                                                                                    IN `check_in_date` DATE,
                                                                                    IN `check_out` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE attendance as a
    SET a.check_in      = check_in,
        a.check_in_date = check_in_date,
        a.check_out     = check_out,
        a.updated_by    = 1,
        a.updated_on    = CURRENT_TIMESTAMP
    WHERE a.id = EmpId
      AND a.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_Advance_PayableAmount`(IN `EmpId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
-- Calculate the number of days in the previous month (August)
    SET @DaysInCurrentMonth = DAY(LAST_DAY(CURRENT_DATE));

    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);

    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) NOT IN (1, 7)
                      ORDER BY 1 ASC);

    SELECT a.Net_Salary as PayableAmount
    FROM (SELECT up.id                                                                                 AS EMPID,
                 up.salary,
                 FLOOR(DeductedDaysBecauseOfLateArrival)                                                  AS DeductionDays,
                 NoOfLates                                                                                AS TotalLate,
                 (SystemWorkingDays - AttendedDays)                                                       AS Absent,
                 (
                         (FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                         (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
                 up.Advance,
                 FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                       up.Advance - FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))
                 )                                                                                        AS Net_Salary
          FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                       @SundayOff                                                       AS SunOff,
                       CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                       up.Employee_Id                                                   AS EMPID,
                       COUNT(a.check_in_date)                                           AS AttendedDays,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                            TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                       ELSE '0' END
                           END) /
                       3                                                                AS DeductedDaysBecauseOfLateArrival,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                            TIME(s.grace_time) THEN 1
                                       ELSE 0 END
                           END)                                                         AS _NoOfLates,
                       FLOOR((SUM(CASE
                                      WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                           TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                      ELSE '0' END)))                                      NoOfLates
                FROM attendance a
                         JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                         JOIN shift s ON s.id = up.shift_id
                         JOIN designation d ON d.id = up.Designation_Id
                         JOIN pay_scale pp ON pp.id = up.payscale_id
                WHERE a.isactive = 1
                  AND a.Employee_Id = EmpId
                GROUP BY up.Employee_Id) AS a
                   JOIN user_profile up ON up.Employee_Id = a.EMPID
                   JOIN shift s ON s.id = up.shift_id
                   JOIN designation d ON d.id = up.Designation_Id
                   JOIN pay_scale pp ON pp.id = up.payscale_id) as A;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_Count_Absent`()
BEGIN
    -- Subquery to count 'Absent' entries for the current day
    SELECT COUNT(*) AS AbsentCount
    FROM (SELECT CASE
                     WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 1
                     ELSE 0
                     END AS AbsentFlag
          FROM attendance AS a
                   JOIN
               user_profile AS up ON up.Employee_Id = a.Employee_Id
                   JOIN
               shift AS s ON up.shift_id = s.id
          WHERE a.isactive = 1
            AND s.isactive = 1
            AND up.isactive = 1
            AND DATE(a.check_in_date) = CURDATE() -- Filter for the current day's date
            AND TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') -- Filter for 'Absent' entries
         ) AS AbsentEntries;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_Count_Late`()
BEGIN
    -- Subquery to count 'Late' entries for the current day
    SELECT COUNT(*) AS LateCount
    FROM (SELECT CASE
                     WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                          TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN 1
                     ELSE 0
                     END AS LateFlag
          FROM attendance AS a
                   JOIN
               user_profile AS up ON up.Employee_Id = a.Employee_Id
                   JOIN
               shift AS s ON up.shift_id = s.id
          WHERE a.isactive = 1
            AND s.isactive = 1
            AND up.isactive = 1
            AND DATE(a.check_in_date) = CURDATE()                               -- Filter for the current day's date
            AND TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) -- Filter for 'Late' entries
            AND TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') -- Filter for entries before 4:00 AM
         ) AS LateEntries;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_Count_OnTime`()
BEGIN
    -- Subquery to count 'On Time' entries for the current day
    SELECT COUNT(*) AS OnTimeCount
    FROM (SELECT CASE
                     WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 1
                     ELSE 0
                     END AS OnTimeFlag
          FROM attendance AS a
                   JOIN
               user_profile AS up ON up.Employee_Id = a.Employee_Id
                   JOIN
               shift AS s ON up.shift_id = s.id
          WHERE a.isactive = 1
            AND s.isactive = 1
            AND up.isactive = 1
            AND DATE(a.check_in_date) = '2023-08-01'
             -- CURDATE() -- Filter for the current day's date
         ) AS OnTimeEntries;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `sp_Cursor_PayrollGenerator`()
BEGIN

    DECLARE done INT DEFAULT 0;

-- Declare variables for cursor
    DECLARE v_EMPID INT;
    DECLARE v_DesignationId INT;
    DECLARE v_Shift INT;
    DECLARE v_PayId INT;
    DECLARE v_TimeIn TIME;
    DECLARE v_TimeOut TIME;
    DECLARE v_salary DECIMAL(10, 2);
    DECLARE v_DeductionDays INT;
    DECLARE v_TotalLate INT;
    DECLARE v_Absent INT;
    DECLARE v_Deduction DECIMAL(10, 2);
    DECLARE v_MDeduction DECIMAL(10, 2);
    DECLARE v_Advance DECIMAL(10, 2);
    DECLARE v_MAdvance DECIMAL(10, 2);
    DECLARE v_Net_Salary DECIMAL(10, 2);
    DECLARE v_MSalary DECIMAL(10, 2);

-- Declare cursor
    DECLARE empCursor CURSOR FOR
        SELECT up.id                                                                                          AS EMPID,
               d.id,
               s.id                                                                                           AS Shift,
               pp.id,
               TIME(s.time_in)                                                                                   AS TimeIn,
               TIME(s.time_out)                                                                                  AS TimeOut,
               up.salary,
               FLOOR(DeductedDaysBecauseOfLateArrival)                                                           AS DeductionDays,
               NoOfLates                                                                                         AS TotalLate,
               (SystemWorkingDays - AttendedDays)                                                                AS Absent,
               ((FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))))                 AS Deduction,
               ((FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))))                 AS MDeduction,
               up.Advance,
               up.Advance,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     up.Advance -
                     FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))              AS Net_Salary,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     up.Advance -
                     FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))              AS MSalary
        FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                     @SundayOff                                                       AS SunOff,
                     CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                     up.Employee_Id                                                   AS EMPID,
                     COUNT(a.check_in_date)                                           AS AttendedDays,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                          TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                     ELSE '0' END
                         END) /
                     3                                                                AS DeductedDaysBecauseOfLateArrival,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time)
                                         THEN 1
                                     ELSE '0' END
                         END)                                                         AS _NoOfLates,
                     FLOOR((SUM(CASE
                                    WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                         TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                    ELSE '0' END)))                                      NoOfLates
              FROM attendance a
                       JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                       JOIN shift s ON s.id = up.shift_id
                       JOIN designation d ON d.id = up.Designation_Id
                       JOIN pay_scale pp ON pp.id = up.payscale_id
              WHERE a.isactive = 1
              GROUP BY up.Employee_Id) AS a
                 JOIN user_profile up ON up.Employee_Id = a.EMPID
                 JOIN shift s ON s.id = up.shift_id
                 JOIN designation d ON d.id = up.Designation_Id
                 JOIN pay_scale pp ON pp.id = up.payscale_id;

-- Declare continue handler for cursor
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;

    -- Calculate the number of days in the current month
-- Calculate the number of days in the previous month (August)
    SET @DaysInCurrentMonth = DAY(LAST_DAY(CURRENT_DATE));
    -- Get Holidays for current Month
    SET @HolidayCount = (SELECT COUNT(*)
                         FROM holidays h
                         WHERE h.isactive = 1
                           AND MONTH(h.Holiday_Date) = (MONTH(NOW()) - 1)
                           AND YEAR(h.Holiday_Date) = YEAR(NOW()));

    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 2) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = (MONTH(NOW()) - 1)
                        AND DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);

    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 2) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = (MONTH(NOW()) - 1)
                        AND DAYOFWEEK(date_field) NOT IN (1, 7)
                      ORDER BY 1 ASC);

    -- Reducting Holidays for System Working Days
    SET @SatSunOff = (@SatSunOff - @HolidayCount);
    SET @SundayOff = (@SundayOff - @HolidayCount);

    -- Open the cursor
    OPEN empCursor;
    -- Loop through cursor results
    employee_loop:
    LOOP
        FETCH empCursor INTO
            v_EMPID,
            v_DesignationId,
            v_Shift, v_PayId,
            v_TimeIn,
            v_TimeOut,
            v_salary,
            v_DeductionDays,
            v_TotalLate,
            v_Absent,
            v_Deduction,
            v_MDeduction,
            v_Advance,
            v_MAdvance,
            v_MSalary,
            v_Net_Salary;

        IF done = 1 THEN
            LEAVE employee_loop;
        END IF;

        SET @PayrollExists =
                (SELECT COUNT(*) FROM payroll pr WHERE pr.UserP_Id = v_EMPID AND MONTH(pr.created_on) = MONTH(NOW()));

        IF @PayrollExists = 0 THEN

            -- Insert data into payroll table
            INSERT INTO payroll(UserP_Id,
                                Designation_Id,
                                Shift_Id,
                                Pay_Id,
                                time_in,
                                time_out,
                                PayRoll_Type,
                                salary,
                                deducted_days,
                                late,
                                absent,
                                Deduction,
                                M_Deducted,
                                Advance,
                                M_Advance,
                                M_Salary,
                                Total_Pay,
                                created_by,
                                updated_by)
            VALUES (v_EMPID,
                    v_DesignationId,
                    v_Shift,
                    v_PayId,
                    v_TimeIn,
                    v_TimeOut,
                    1,
                    v_salary,
                    v_DeductionDays,
                    v_TotalLate,
                    v_Absent,
                    v_Deduction,
                    v_MDeduction,
                    v_Advance,
                    v_MAdvance,
                    v_MSalary,
                    v_Net_Salary,
                    1,
                    1);


            UPDATE user_profile up
            SET up.Advance = (up.Advance - v_MAdvance)
            WHERE up.Employee_Id = v_EMPID and up.isactive = 1;

        END IF;
    END LOOP;

    -- Close the cursor
    CLOSE empCursor;
    -- END IF;

-- Show Data
    SELECT pr.id,
           CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
           d.designation_name,
           s.shift_name,
           ps.pay_name,
           TIME(s.time_in)                           time_in,
           TIME(s.time_out)                          time_out,
           pt.Name                                As payroll_type,
           pr.salary,
           pr.deducted_days,
           pr.late,
           pr.absent,
           pr.Deduction,
           pr.M_Deducted,
           pr.Advance,
           pr.M_Advance,
           pr.M_Salary,
           pr.Total_Pay,
           pr.updated_on
    FROM payroll pr
             JOIN user_profile up ON up.id = pr.UserP_Id
             JOIN designation d ON d.id = pr.Designation_Id
             JOIN shift s ON s.id = pr.Shift_Id
             JOIN pay_scale ps ON ps.id = pr.Pay_Id
             JOIN payroll_type pt ON pt.id = pr.PayRoll_Type
    WHERE MONTH(pr.created_on) = MONTH(NOW())
      AND pr.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1
      AND pt.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `sp_getEmpInfoByUserID`(IN `EmpId` INT)
BEGIN
    SELECT ps.pay_name,
           up.id,
           up.Employee_Id,
           up.firstname,
           up.lastname,
           up.contact,
           up.address,
           up.Gmail,
           up.CNIC,
           up.salary,
           g.Gender,
           s.shift_name,
           up.workingDays
    FROM `user_profile` up
             JOIN shift s on s.id = up.shift_id
             JOIN designation d on d.id = up.Designation_Id
             JOIN tbl_gender g on g.id = up.gender
             join pay_scale ps on ps.id = up.payscale_id
    WHERE up.Employee_Id = EmpId;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Sp_GetSpecialPayrollValues`(IN `SP_EmpID` INT)
BEGIN
    -- Days in Current Month
    SET @DaysInCurrentMonth = DAY(LAST_DAY(CURRENT_DATE));

-- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);

    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) NOT IN (1, 7)
                      ORDER BY 1 ASC);


    SELECT up.id                                                                                 AS id,
           concat(up.firstname, ' ', up.lastname)                                                   as Employee_Name,
           dn                                                                                       as designation_name,
           s.shift_name                                                                             as shift_name,
           pp.pay_name                                                                              as pay_name,
           TIME(s.time_in)                                                                          AS time_in,
           TIME(s.time_out)                                                                         AS time_out,
           'Special Payroll'                                                                        as payroll_type,
           2,
           up.salary                                                                                as salary,
           FLOOR(DeductedDaysBecauseOfLateArrival)                                                  AS deducted_days,
           NoOfLates                                                                                AS late,
           (SystemWorkingDays - AttendedDays)                                                       AS absent, -- Calculate absent days as (SystemWorkingDays - AttendedDays)
           (
                   (FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                   (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
           (
                   (FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                   (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))) AS M_Deducted,
           up.Advance                                                                               as Advance,
           up.Advance                                                                               as M_Advance,
           FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                 up.Advance - FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))
           )                                                                                        AS Total_Pay,
           FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                 up.Advance - FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))
           )                                                                                        AS M_Salary
    FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                 @SundayOff                                                       AS SunOff,
                 d.designation_name                                               as dn,
                 CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                 up.Employee_Id                                                   AS EMPID,
                 COUNT(a.check_in_date)                                           AS AttendedDays,
                 SUM(CASE
                         WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                             THEN 0
                         ELSE
                             CASE
                                 WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                      TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                 ELSE '0' END
                     END) / 3                                                     AS DeductedDaysBecauseOfLateArrival,
                 SUM(CASE
                         WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                             THEN 0
                         ELSE
                             CASE
                                 WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time)
                                     THEN 1
                                 ELSE 0 END
                     END)                                                         AS _NoOfLates,
                 FLOOR((SUM(CASE
                                WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                     TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                ELSE '0' END)))                                      NoOfLates
          FROM attendance a
                   JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                   JOIN shift s ON s.id = up.shift_id
                   JOIN designation d ON d.id = up.Designation_Id
                   JOIN pay_scale pp ON pp.id = up.payscale_id
          WHERE a.isactive = 1
            AND a.Employee_Id = SP_EmpID
            AND MONTH(a.check_in_date) = '08'-- MONTH(CURRENT_DATE)
            AND YEAR(a.check_in_date) = '2023'-- YEAR(CURRENT_DATE)
          GROUP BY up.Employee_Id) AS a
             JOIN user_profile up ON up.Employee_Id = a.EMPID
             JOIN shift s ON s.id = up.shift_id
             JOIN designation d ON d.id = up.Designation_Id
             JOIN pay_scale pp ON pp.id = up.payscale_id;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_InsertUserProfileInfo`(IN `EmpID` VARCHAR(50), IN `Fname` VARCHAR(50),
                                                                      IN `Lname` VARCHAR(50), IN `Sex` INT(10),
                                                                      IN `CNIC` VARCHAR(50), IN `Gmail` VARCHAR(50),
                                                                      IN `Phone` VARCHAR(50), IN `Home` TEXT,
                                                                      IN `DesID` INT, IN `PayId` INT, IN `ShiftID` INT,
                                                                      IN `WorkingDays` INT, IN `Salary` DOUBLE)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    set @isExist = (SELECT COUNT(*) FROM user_profile up WHERE up.Employee_Id = EmpID);
    IF (@isExist <= 0) THEN
        INSERT INTO user_profile(Employee_Id, firstname, lastname, gender, CNIC, Gmail, contact, address,
                                 Designation_Id, payscale_id, shift_id, workingDays, salary, created_by, created_on)
        VALUES (EmpID, Fname, Lname, Sex, CNIC, Gmail, Phone, Home, DesID, PayId, ShiftID, WorkingDays, Salary, 1,
                CURRENT_TIMESTAMP);
    ELSE
        UPDATE user_profile as up
        SET up.Employee_Id    = EmpID,
            up.firstname      = Fname,
            up.lastname       = Lname,
            up.gender         = Sex,
            up.CNIC           = CNIC,
            up.Gmail          = Gmail,
            up.contact        = Phone,
            up.address        = Home,
            up.Designation_Id = DesID,
            up.payscale_id    = PayId,
            up.shift_id       = ShiftID,
            up.workingDays    = WorkingDays,
            up.salary         = Salary,
            up.updated_by     = 1,
            up.updated_on     = CURRENT_TIMESTAMP
        WHERE up.Employee_Id = EmpID;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `sp_Special_PayrollGenerator`(IN `Userid` INT, IN `EmpId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;

    UPDATE user_profile up JOIN payroll pr ON up.id = pr.UserP_Id
    SET up.isactive = 0,
        up.Advance  = (up.Advance - pr.Advance)
    WHERE up.Employee_Id = EmpId
      AND pr.isactive = 1;

-- Calculate the number of days in the previous month (August)
    SET @DaysInCurrentMonth = DAY(LAST_DAY(CURRENT_DATE));


    -- SET @HolidayCount = (SELECT COUNT(id) FROM holidays h WHERE MONTH(h.Holiday_Date) =  MONTH(CURRENT_DATE)
    --      AND YEAR(h.Holiday_Date) = YEAR(CURRENT_DATE));
-- Check if records exist for the current month
-- SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));
-- IF (@isExist <= 0) THEN

    SET @HolidayCount = (SELECT COUNT(*)
                         FROM holidays h
                         WHERE h.isactive = 1
                           AND MONTH(h.Holiday_Date) = (MONTH(NOW()) - 1)
                           AND YEAR(h.Holiday_Date) = YEAR(NOW()));

    SET @PayrollExists =
            (SELECT COUNT(*) FROM payroll pr WHERE pr.UserP_Id = EmpId AND MONTH(pr.created_on) = MONTH(NOW()));
    IF @PayrollExists = 0 THEN

        -- 6 days emp==========================
        SET @SundayOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 2) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = (MONTH(NOW()) - 1)
                            AND DAYOFWEEK(date_field) != 1
                          ORDER BY 1 ASC);

        -- 5 days emp==========================
        SET @SatSunOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 2) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = (MONTH(NOW()) - 1)
                            AND DAYOFWEEK(date_field) NOT IN (1, 7)
                          ORDER BY 1 ASC);

        -- Reducting Holidays for System Working Days
        SET @SatSunOff = (@SatSunOff - @HolidayCount);
        SET @SundayOff = (@SundayOff - @HolidayCount);


        -- Insert data into payroll table
        INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, PayRoll_Type, salary,
                            deducted_days, late, absent, Deduction, M_Deducted, Advance, M_Advance, M_Salary, Total_Pay,
                            created_by, updated_by)
        SELECT up.id                                                                                 AS EMPID,
               d.id,
               s.id                                                                                  AS Shift,
               pp.id,
               TIME(s.time_in)                                                                          AS TimeIn,
               TIME(s.time_out)                                                                         AS TimeOut,
               2,
               up.salary,
               FLOOR(DeductedDaysBecauseOfLateArrival)                                                  AS DeductionDays,
               NoOfLates                                                                                AS TotalLate,
               (SystemWorkingDays - AttendedDays)                                                       AS Absent, -- Calculate absent days as (SystemWorkingDays - AttendedDays)
               (
                       (FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                       (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
               (
                       (FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                       (FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays)))) AS MDeduction,
               up.Advance,
               up.Advance,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     up.Advance - FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))
               )                                                                                        AS Net_Salary,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInCurrentMonth) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     up.Advance - FLOOR((up.salary / @DaysInCurrentMonth) * (SystemWorkingDays - AttendedDays))
               )                                                                                        AS MSalary,
               Userid,
               Userid
        FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                     @SundayOff                                                       AS SunOff,
                     CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                     up.Employee_Id                                                   AS EMPID,
                     (COUNT(a.check_in_date) + @HolidayCount)                         AS AttendedDays,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                          TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                     ELSE '0' END
                         END) /
                     3                                                                AS DeductedDaysBecauseOfLateArrival,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time) THEN 1
                                     ELSE 0 END
                         END)                                                         AS _NoOfLates,
                     FLOOR((SUM(CASE
                                    WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                         TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                    ELSE '0' END)))                                      NoOfLates
              FROM attendance a
                       JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                       JOIN shift s ON s.id = up.shift_id
                       JOIN designation d ON d.id = up.Designation_Id
                       JOIN pay_scale pp ON pp.id = up.payscale_id
              WHERE a.isactive = 1
                AND a.Employee_Id = EmpId
                AND MONTH(a.check_in_date) = '08'-- MONTH(CURRENT_DATE)
                AND YEAR(a.check_in_date) = '2023'-- YEAR(CURRENT_DATE)
              GROUP BY up.Employee_Id) AS a
                 JOIN user_profile up ON up.Employee_Id = a.EMPID
                 JOIN shift s ON s.id = up.shift_id
                 JOIN designation d ON d.id = up.Designation_Id
                 JOIN pay_scale pp ON pp.id = up.payscale_id;
    END IF;

-- Show Data
    SELECT pr.id,
           CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
           d.designation_name,
           s.shift_name,
           ps.pay_name,
           TIME(s.time_in)                           time_in,
           TIME(s.time_out)                          time_out,
           pt.Name                                As payroll_type,
           pr.salary,
           pr.deducted_days,
           pr.late,
           pr.absent,
           pr.Deduction,
           pr.M_Deducted,
           pr.Advance,
           pr.M_Advance,
           pr.M_Salary,
           pr.Total_Pay,
           pr.updated_on
    FROM payroll pr
             JOIN user_profile up ON up.id = pr.UserP_Id
             JOIN designation d ON d.id = pr.Designation_Id
             JOIN shift s ON s.id = pr.Shift_Id
             JOIN pay_scale ps ON ps.id = pr.Pay_Id
             JOIN payroll_type pt ON pt.id = pr.PayRoll_Type
    WHERE MONTH(pr.created_on) = MONTH(NOW())
      AND pr.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1
      AND pt.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `SP_StrProc_ChangeAttendanceInfo`(IN `EmpId` INT, IN `check_in` VARCHAR(50),
                                                                             IN `check_out` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;

    START TRANSACTION;

    -- Declare variables to store previous datetime values
    SET @checkinold = (SELECT date(a.check_in) FROM attendance a WHERE a.id = EmpId);
    SET @checkoutold = (SELECT date(a.check_out) FROM attendance a WHERE a.id = EmpId);
    -- Convert the input time strings to TIME format
    SET @newCheckInTime = STR_TO_DATE(check_in, '%H:%i:%s');
    SET @newCheckOutTime = STR_TO_DATE(check_out, '%H:%i:%s');

    -- Update the check_in and check_out columns by concatenating with the existing date
    UPDATE attendance AS a
    SET a.check_in   = CONCAT(@checkinold, ' ', @newCheckInTime),
        a.check_out  = CONCAT(@checkoutold, ' ', @newCheckOutTime),
        a.updated_by = 1,
        a.updated_on = CURRENT_TIMESTAMP
    WHERE a.id = EmpId
      AND a.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeAdvanceInfo`(IN `adv_Id` INT, IN `UpId` INT,
                                                                       IN `Amount` DOUBLE, IN `AmountDate` DATETIME)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE advance as ad
    SET ad.Up_Id      = UpId,
        ad.Amount     = Amount,
        ad.AmoutDate  = AmountDate,
        ad.updated_by = 1,
        ad.updated_on = CURRENT_TIMESTAMP
    WHERE ad.id = adv_Id
      AND ad.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeAttendanceInfo`(IN `EmpId` INT, IN `check_in` VARCHAR(50),
                                                                          IN `check_out` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;

    START TRANSACTION;

    SET @checkindata = (Select a.check_in FROM attendance a WHERE a.id = EmpId);
    SET @checkoutdata = (Select a.check_in FROM attendance a WHERE a.id = EmpId);
    -- Declare variables to store previous datetime values
    SET @checkinold = (SELECT date(a.check_in) FROM attendance a WHERE a.id = EmpId);
    SET @checkoutold = (SELECT date(a.check_out) FROM attendance a WHERE a.id = EmpId);
    -- Convert the input time strings to TIME format
    SET @newCheckInTime = STR_TO_DATE(check_in, '%H:%i:%s');
    SET @newCheckOutTime = STR_TO_DATE(check_out, '%H:%i:%s');

    -- Update the check_in and check_out columns by concatenating with the existing date
    UPDATE attendance AS a
    SET a.check_in   = CONCAT(@checkinold, ' ', @newCheckInTime),
        a.check_out  = CONCAT(@checkoutold, ' ', @newCheckOutTime),
        a.updated_by = 1,
        a.updated_on = CURRENT_TIMESTAMP
    WHERE a.id = EmpId
      AND a.isactive = 1;

    SET @UserStr = (SELECT CONCAT(u.username, ' (', u.id, ')') FROM user u WHERE u.id = 1);
    SET @LogMsg = '';


    IF check_in IS NOT NULL THEN
        SET @LogMsg = CONCAT(@UserStr, ' has changed attendance record ', @checkindata, ' of check_in to ',
                             CONCAT(@checkinold, ' ', @newCheckInTime));
    END IF;

    IF check_out IS NOT NULL THEN
        -- Concatenate the check_out message
        IF @LogMsg != '' THEN
            SET @LogMsg = CONCAT(@LogMsg, ' And ');
        END IF;
        SET @LogMsg = CONCAT(@LogMsg, 'has changed attendance record ', @checkoutdata, ' of check_out to ',
                             CONCAT(@checkoutold, ' ', @newCheckOutTime));
    END IF;

    INSERT INTO logs (Log_Description, TBL_Name, created_by, created_on)
    VALUES (@LogMsg, 'Attendance', 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeDesignationInfo`(IN `Desig_Id` INT, IN `designation_name` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE designation as d
    SET d.designation_name = designation_name,
        d.updated_by       = 1,
        d.updated_on       = CURRENT_TIMESTAMP
    WHERE d.id = Desig_Id
      AND d.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeHolidayInfo`(IN `HoliId` INT, IN `Title` VARCHAR(50), IN `HolidayDate` DATE)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE holidays as h
    SET h.Title        = Title,
        h.Holiday_Date = HolidayDate,
        h.updated_by   = 1,
        h.updated_on   = CURRENT_TIMESTAMP
    WHERE h.id = HoliId
      AND h.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangePayRollInfo`(IN `PayRoll_Id` INT, IN `M_Deduction` INT,
                                                                       IN `M_Salary` INT, IN `M_Advance` DOUBLE,
                                                                       IN `Remarks` VARCHAR(255))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE payroll as pr
    SET pr.M_Deducted = M_Deduction,
        pr.M_Salary   = M_Salary,
        pr.M_Advance  = M_Advance,
        pr.Remarks    = Remarks,
        pr.updated_by = 1,
        pr.updated_on = CURRENT_TIMESTAMP
    WHERE pr.id = PayRoll_Id
      AND pr.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangePayScaleInfo`(IN `PaySca_Id` INT, IN `pay_name` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE pay_scale as ps
    SET ps.pay_name   = pay_name,
        ps.updated_by = 1,
        ps.updated_on = CURRENT_TIMESTAMP
    WHERE ps.id = PaySca_Id
      AND ps.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangePermissionAssignInfo`(IN `PermAssi_Id` INT, IN `Role_Id` INT, IN `Permission_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE permission_assign as pa
    SET pa.Role_Id       = Role_Id,
        pa.Permission_Id = Permission_Id,
        pa.updated_by    = 1,
        pa.updated_on    = CURRENT_TIMESTAMP
    WHERE pa.id = PermAssi_Id
      AND pa.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangePermissionInfo`(IN `Perm_Id` INT,
                                                                          IN `permisssion_name` VARCHAR(50),
                                                                          IN `controller` VARCHAR(50),
                                                                          IN `action` VARCHAR(50),
                                                                          IN `method` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE permission as p
    SET p.permisssion_name = permisssion_name,
        p.controller       = controller,
        p.action           = action,
        p.method           = method,
        p.updated_by       = 1,
        p.updated_on       = CURRENT_TIMESTAMP
    WHERE p.id = Perm_Id
      AND p.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeRoleAssignInfo`(IN `RoleAssi_Id` INT, IN `Role_Id` INT, IN `User_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE role_assign as ra
    SET ra.Role_Id    = Role_Id,
        ra.User_Id    = User_Id,
        ra.updated_by = 1,
        ra.updated_on = CURRENT_TIMESTAMP
    WHERE ra.id = RoleAssi_Id
      AND ra.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeRoleInfo`(IN `Roles_Id` INT(10), IN `role_name` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE role as r
    SET r.role_name  = role_name,
        r.updated_by = 1,
        r.updated_on = CURRENT_TIMESTAMP
    WHERE r.id = Roles_Id
      AND r.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeShiftInfo`(IN `Shift_Id` INT, IN `shift_name` VARCHAR(50),
                                                                     IN `time_in` TIME, IN `time_out` TIME,
                                                                     IN `grace_time` TIME)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE shift as s
    SET s.shift_name = shift_name,
        s.time_in    = time_in,
        s.time_out   = time_out,
        s.grace_time = grace_time,
        s.updated_by = 1,
        s.updated_on = CURRENT_TIMESTAMP
    WHERE s.id = Shift_Id
      AND s.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeUserInfo`(IN `UId` INT, IN `Role_Id` INT, IN `UserP_Id` INT,
                                                                    IN `username` VARCHAR(50),
                                                                    IN `password` VARCHAR(100))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE user as u
    SET u.Role_Id    = Role_Id,
        u.UserP_Id   = UserP_Id,
        u.username   = username,
        u.password   = password,
        u.updated_by = 1,
        u.updated_on = CURRENT_TIMESTAMP
    WHERE u.id = UId
      AND u.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_ChangeUserProfileInfo`(IN `UpId` INT, IN `Designation_Id` INT,
                                                                           IN `Employee_Id` VARCHAR(50),
                                                                           IN `firstname` VARCHAR(50),
                                                                           IN `lastname` VARCHAR(50),
                                                                           IN `CNIC` VARCHAR(255),
                                                                           IN `Gmail` VARCHAR(50), IN `address` TEXT,
                                                                           IN `contact` VARCHAR(255),
                                                                           IN `gender` VARCHAR(10), IN `shift_id` INT,
                                                                           IN `payscale_id` INT, IN `salary` DOUBLE,
                                                                           IN `workingDays` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE user_profile as up
    SET up.Designation_Id = Designation_Id,
        up.Employee_Id    = Employee_Id,
        up.firstname      = firstname,
        up.lastname       = lastname,
        up.CNIC           = CNIC,
        up.Gmail          = Gmail,
        up.address        = address,
        up.contact        = contact,
        up.gender         = gender,
        up.shift_id       = shift_id,
        up.payscale_id    = payscale_id,
        up.salary         = salary,
        up.workingDays    = workingDays,
        up.updated_by     = 1,
        up.updated_on     = CURRENT_TIMESTAMP
    WHERE up.id = UpId
      AND up.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getAdvanceInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT ad.id, ad.Up_Id, ad.Amount, ad.AmoutDate FROM advance as ad WHERE ad.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getAttendanceInfo`(IN `AtenId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT a.id,
           a.User_Id,
           a.check_in,
           a.check_out,
           a.over_time,
           a.isactive,
           a.created_by,
           a.updated_by,
           a.created_on,
           a.updated_on
    FROM attendance as a
             JOIN user as u ON a.User_Id = u.id
             JOIN user as u1 ON a.created_by = u1.id
             JOIN user as u2 ON a.updated_by = u2.id
    WHERE a.id = AtenId
      AND a.isactive = 1
      AND u.isactive = 1
      AND u1.isactive = 1
      AND u2.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getDesignationInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT d.id, d.designation_name FROM designation as d WHERE d.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getGenderInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT g.id, g.Gender FROM tbl_gender as g WHERE g.isactive;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getHolidayInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT h.id, h.Title, h.Holiday_Date FROM holidays as h WHERE h.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getPayRollInfo`(IN `PayRoll_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT pr.id,
           pr.UserP_Id,
           pr.Designation_Id,
           pr.Shift_Id,
           pr.Pay_Id,
           pr.Deduction,
           pr.salary,
           pr.Total_Pay,
           pr.isactive,
           pr.created_by,
           pr.updated_by,
           pr.created_on,
           pr.updated_on
    FROM payroll as pr
             JOIN user_profile as up ON pr.UserP_Id = up.id
             JOIN designation as d ON pr.Designation_Id = d.id
             JOIN shift as s ON pr.Shift_Id = s.id
             JOIN pay_scale as ps ON pr.Pay_Id = ps.id
             JOIN user as u ON ps.created_by = u.id
             JOIN user as u1 ON ps.updated_by = u1.id
    WHERE pr.id = PayRoll_Id
      AND ps.isactive = 1
      AND up.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1
      AND ps.isactive = 1
      AND u.isactive = 1
      AND u1.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getPayScaleInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
/*SELECT ps.id,ps.pay_name,ps.isactive,ps.created_by,ps.updated_by,ps.created_on,ps.updated_on FROM pay_scale as ps  JOIN user as u ON ps.created_by = u.id JOIN user as u1 ON ps.updated_by = u1.id WHERE ps.id = PaySca_Id AND ps.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;*/
    SELECT ps.id, ps.pay_name FROM pay_scale as ps WHERE ps.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getPermissionAssignInfo`(IN `PermAssi_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT pa.id,
           pa.Role_Id,
           pa.Permission_Id,
           pa.isactive,
           pa.created_by,
           pa.updated_by,
           pa.created_on,
           pa.updated_on
    FROM permission_assign as pa
             JOIN role as r ON pa.Role_Id = r.id
             JOIN permission as p ON pa.Permission_Id = p.id
             JOIN user as u ON pa.created_by = u.id
             JOIN user as u1 ON pa.updated_by = u1.id
    WHERE pa.id = PermAssi_Id
      AND pa.isactive = 1
      AND r.isactive = 1
      AND p.isactive = 1
      AND u.isactive = 1
      AND u1.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getPermissionInfo`(IN `Perm_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT p.id,
           p.permisssion_name,
           p.controller,
           p.action,
           p.parameters,
           p.method,
           p.icon,
           p.sort,
           p.parent_id,
           p.isactive,
           p.created_by,
           p.updated_by,
           p.created_on,
           p.updated_on
    FROM permission as p
             JOIN user as u ON p.created_by = u.id
             JOIN user as u1 ON p.updated_by = u1.id
    WHERE p.id = Perm_Id
      AND p.isactive = 1
      AND u.isactive = 1
      AND u1.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getRoleInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
/*SELECT r.id,r.role_name,r.isactive,r.created_by,r.updated_by,r.created_on,r.updated_on FROM role as r JOIN user as u ON r.created_by = u.id JOIN user as u1 ON r.updated_by = u1.id WHERE r.id = Roles_Id AND r.isactive = 1 AND u.isactive = 1 AND u1.isactive = 1;*/
    SELECT r.id, r.role_name FROM role as r WHERE isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getShiftInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT id, shift_name FROM shift WHERE isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getUserInfo`(IN `UId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT u.id,
           u.Role_Id,
           u.UserP_Id,
           u.username,
           u.password,
           u.isactive,
           u.created_by,
           u.updated_by,
           u.created_on,
           u.updated_on
    FROM user as u
             LEFT JOIN role as r ON u.Role_Id = r.id
             JOIN user_profile as up ON u.UserP_Id = up.id
    WHERE u.id = UId
      AND u.isactive = 1
      AND r.isactive = 1
      AND up.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getUserLoginInfo`(IN `username` VARCHAR(4), IN `password` VARCHAR(8))
BEGIN
    SELECT *
    FROM user as u
             JOIN user_profile as up ON u.UserP_Id = up.id
    WHERE u.isactive = 1
      AND up.isactive = 1
      AND u.username = username
      AND u.password = password;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_getUserProfileInfo`(IN `UpId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    SELECT up.id,
           up.Designation_Id,
           up.Employee_Id,
           up.firstname,
           up.lastname,
           up.CNIC,
           up.Gmail,
           up.address,
           up.contact,
           up.gender,
           up.shift_id,
           up.payscale_id,
           up.salary,
           up.Advance,
           up.workingDays,
           up.isactive,
           up.created_by,
           up.updated_by,
           up.created_on,
           up.updated_on
    FROM user_profile as up
             JOIN designation as d ON up.Designation_Id = d.id
             JOIN shift as s ON up.shift_id = s.id
             JOIN pay_scale as p ON up.payscale_id = p.id
    WHERE up.id = UpId
      AND up.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1
      AND p.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertAdvanceInfo`(IN `UpId` INT, IN `Amount` DOUBLE, IN `AmoutDate` DATE)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE user_profile up
    SET up.Advance = (up.Advance + Amount)
    WHERE up.id = UpId
      AND up.isactive = 1;

    -- Insert the Amount into the advance table
    INSERT INTO advance(Up_Id, Amount, AmountDate, created_by, created_on)
    VALUES (UpId, Amount, AmoutDate, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertAttendanceInfo`(IN `Employee_Id` INT, IN `CheckIn` DATETIME,
                                                                          IN `CheckInDate` DATE, IN `CheckOut` DATETIME)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    set @isExist =
            (SELECT COUNT(*) FROM attendance a WHERE a.check_in_date = CheckInDate AND a.Employee_Id = Employee_Id);
    IF (@isExist <= 0) THEN
        INSERT INTO attendance(Employee_Id, check_in, check_in_date, check_out, created_by, created_on)
        VALUES (Employee_Id, CheckIn, CheckInDate, CheckOut, 1, CURRENT_TIMESTAMP);
    ELSE
        UPDATE attendance a
        SET a.Employee_Id   = Employee_Id,
            a.check_in      = CheckIn,
            a.check_in_date = CheckInDate,
            a.check_out     = CheckOut,
            a.updated_by    = 1,
            a.updated_on    = CURRENT_TIMESTAMP
        WHERE a.Employee_Id = Employee_Id
          AND a.check_in_date = CheckInDate;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertDesignationInfo`(IN `Designame` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO designation(designation_name, created_by, created_on) VALUES (Designame, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertHolidayInfo`(IN `Title` VARCHAR(50), IN `Holiday_Date` DATE)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    set @isExist = (SELECT COUNT(*) FROM holidays h WHERE h.Holiday_Date = Holiday_Date);
    IF (@isExist <= 0) THEN
        INSERT INTO holidays(Title, Holiday_Date, created_by, created_on)
        VALUES (Title, Holiday_Date, 1, CURRENT_TIMESTAMP);
    ELSE
        UPDATE holidays h
        SET h.Title      = Title,
            h.updated_by = 1,
            h.updated_on = CURRENT_TIMESTAMP
        WHERE h.Holiday_Date = Holiday_Date;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertPayRollInfo`(IN `UPId` INT, IN `DesigId` INT, IN `SId` INT,
                                                                       IN `PayId` INT, IN `Deduc` DOUBLE,
                                                                       IN `Salary` DOUBLE, IN `TotalPay` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, Deduction, salary, Total_Pay, created_by,
                        created_on)
    VALUES (UPId, DesigId, SId, PayId, Deduc, Salary, TotalPay, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertPayScaleInfo`(IN `Payname` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO pay_scale(pay_name, created_by, created_on) VALUES (Payname, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertPermissionAssignInfo`(IN `RId` INT, IN `PermId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO permission_assign(Role_Id, Permission_Id, created_by, created_on)
    VALUES (RId, PermId, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertPermissionInfo`(IN `Pname` VARCHAR(50),
                                                                          IN `control` VARCHAR(50),
                                                                          IN `Actin` VARCHAR(50),
                                                                          IN `Pmeter` VARCHAR(50),
                                                                          IN `Meth` VARCHAR(50), IN `Icon` VARCHAR(50),
                                                                          IN `Sort` INT, IN `PrnId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO permission(permisssion_name, controller, action, parameters, method, icon, sort, parent_id, created_by,
                           created_on)
    VALUES (Pname, control, Actin, Pmeter, Meth, Icon, Sort, PrnId, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertRoleAssignInfo`(IN `RId` INT, IN `UId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO role_assign(Role_Id, User_Id, created_by, created_on) VALUES (RId, UId, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertRoleInfo`(IN `roll_name` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO role (role_name, created_by, created_on) VALUES (roll_name, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertShiftInfo`(IN `Sname` VARCHAR(50), IN `timeIn` TIME,
                                                                     IN `TimeOut` TIME, IN `GraceTime` TIME)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO shift(shift_name, time_in, time_out, grace_time, created_by, created_on)
    VALUES (Sname, timeIn, TimeOut, GraceTime, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertUserInfo`(IN `RId` INT(10), IN `UPId` INT,
                                                                    IN `Uname` VARCHAR(50), IN `Pass` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    INSERT INTO user(Role_Id, UserP_Id, username, password, created_by, created_on)
    VALUES (RId, UPId, Uname, Pass, 1, CURRENT_TIMESTAMP);
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_InsertUserProfileInfo`(IN `EmpID` VARCHAR(50),
                                                                           IN `Fname` VARCHAR(50),
                                                                           IN `Lname` VARCHAR(50), IN `Sex` INT(10),
                                                                           IN `CNIC` INT, IN `Gmail` VARCHAR(50),
                                                                           IN `Phone` INT, IN `Home` TEXT,
                                                                           IN `DesID` INT, IN `PayId` INT,
                                                                           IN `ShiftID` INT, IN `WorkingDays` INT,
                                                                           IN `Salary` DOUBLE, IN `Cheak_value` BOOLEAN,
                                                                           IN `RId` INT, IN `Uname` VARCHAR(50),
                                                                           IN `Pass` VARCHAR(50))
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    set @isExist = (SELECT COUNT(*) FROM user_profile WHERE Employee_Id = EmpID);
    IF (@isExist <= 0) THEN
        INSERT INTO user_profile(Designation_Id, Employee_Id, firstname, lastname, CNIC, Gmail, address, contact,
                                 gender, shift_id, payscale_id, salary, Advance, workingDays, created_by, created_on,
                                 Cheak_value)
        VALUES (EmpID, Fname, Lname, Sex, CNIC, Gmail, Phone, Home, DesID, PayId, ShiftID, WorkingDays, Salary, 0, 1,
                CURRENT_TIMESTAMP, Cheak_value);

        IF Cheak_value THEN
            INSERT INTO user (Role_Id, username, password, created_by, created_on, UserP_Id)
            VALUES (RId, Uname, Pass, 1, CURRENT_TIMESTAMP, LAST_INSERT_ID());
        END IF;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectAdvanceInfo`(IN `adv_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF adv_Id != 0 THEN
        SELECT up.firstname, ad.Amount, ad.AmountDate
        FROM advance as ad
                 JOIN user_profile up ON up.id = ad.Up_Id
        WHERE ad.isactive = 1
          AND MONTH(ad.AmountDate) = month(CURRENT_DATE)
          AND YEAR(ad.AmountDate) = YEAR(CURRENT_DATE)
          AND up.isactive = 1
          AND ad.Up_Id = adv_Id;
    ELSE
        SELECT ad.id, up.firstname, ad.Amount, ad.AmountDate
        FROM advance as ad
                 JOIN user_profile up ON up.id = ad.Up_Id
        WHERE ad.isactive = 1
          AND up.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectAttendanceInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE attendance AS a
        JOIN user_profile AS up ON up.Employee_Id = a.Employee_Id
        JOIN shift AS s ON up.shift_id = s.id
    SET a.over_time =
            CASE
                WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
                ELSE '00:00:00' -- Zero if Earlier Departure
                END
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;

    SELECT a.id,
           a.Employee_Id,
           CONCAT(up.firstname, ' ', up.lastname) as PersonName,
           TIME_FORMAT(TIME(a.check_in), '%r')    AS Check_In,
           a.check_in_date                        AS Check_In_Date,
           TIME_FORMAT(TIME(a.check_out), '%r')   AS Check_Out,
           s.shift_name                           AS Shift_Name,
           -- a.over_time AS Over_Time,
           CASE
               WHEN TIME(a.check_in) > TIME(s.time_in) THEN TIMEDIFF(TIME(a.check_in), TIME(s.time_in))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Late_Coming,
           CASE
               WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Over_Time,
           CASE
               WHEN TIME(a.check_in) <= TIME(s.time_in) THEN TIMEDIFF(TIME(s.time_in), TIME(a.check_in))
               ELSE '00:00:00' -- Zero if No Earlier Departure
               END                                AS Earlier_Arrival,
        /*  CASE WHEN time(a.check_out) < time(s.time_out) THEN timediff((concat(a.check_in_date,' ',time(s.time_out))),a.check_out) ELSE '-' END As Earlier_Departure,*/
           CASE
               WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                    TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Late'
               WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Absent'
               ELSE 'On Time'
               END                                AS Status
    FROM attendance AS a
             JOIN
         user_profile AS up ON up.Employee_Id = a.Employee_Id
             JOIN
         shift AS s ON up.shift_id = s.id
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectDesignationInfo`(IN `Desig_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF Desig_Id != 0 THEN
        SELECT d.id, d.designation_name FROM designation as d WHERE d.id = Desig_Id AND d.isactive = 1;
    ELSE
        SELECT d.id, d.designation_name FROM designation as d WHERE d.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectHolidayInfo`(IN `HoliId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF HoliId != 0 THEN
        SELECT h.id, h.Title, h.Holiday_Date FROM holidays as h WHERE h.id = HoliId AND h.isactive = 1;
    ELSE
        SELECT h.id, h.Title, h.Holiday_Date FROM holidays as h WHERE h.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectPayRollInfo`()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
-- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        and DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);
-- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t UNION SELECT 1 UNION SELECT 2 UNION SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        and DAYOFWEEK(date_field) not in (1, 7)
                      ORDER BY 1 ASC);

    SELECT LPAD(up.Employee_Id, 6, '0')                                                                 AS EMPID,
           CONCAT(up.firstname, ' ', up.lastname)                                                       AS EMPName,
           d.designation_name                                                                           AS Designation,
           s.shift_name                                                                                 AS Shift,
           TIME(s.time_in)                                                                              AS TimeIn,
           TIME(s.time_out)                                                                             AS TimeOut,
           up.salary,
           (SystemWorkingDays - AttendedDays)                                                           AS Absent,
           NoOfLates                                                                                    AS TotalLate,
           FLOOR(DeductedDaysBecauseOfLateArrival)                                                      AS DeductionDays,
           FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) *
                 FLOOR(DeductedDaysBecauseOfLateArrival))                                               AS LateDeduction,
           FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) *
                 (SystemWorkingDays - AttendedDays))                                                    AS AbsentDeduction,
           FLOOR(up.salary -
                 FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                 FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * (SystemWorkingDays - AttendedDays))) AS Net_Salary
    FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                 @SundayOff                                                       AS SunOff,
                 CASE WHEN up.workingDays = 5 THEN @SundayOff ELSE @SatSunOff END AS SystemWorkingDays,
                 up.Employee_Id                                                   AS EMPID,
                 COUNT(a.check_in_date)                                           AS AttendedDays,
                 SUM(CASE
                         WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                             THEN 0
                         ELSE
                             CASE
                                 WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time)
                                     THEN 1
                                 ELSE 0 END
                     END) / 3                                                     AS DeductedDaysBecauseOfLateArrival,
                 SUM(CASE
                         WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                             THEN 0
                         ELSE
                             CASE
                                 WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) > TIME(s.grace_time)
                                     THEN 1
                                 ELSE 0 END
                     END)                                                         AS NoOfLates
          FROM attendance a
                   JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                   JOIN shift s ON s.id = up.shift_id
                   JOIN designation d ON d.id = up.Designation_Id
          WHERE a.isactive = 1
          GROUP BY up.Employee_Id) AS a
             JOIN user_profile up ON up.Employee_Id = a.EMPID
             JOIN shift s ON s.id = up.shift_id
             JOIN designation d ON d.id = up.Designation_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectPayScaleInfo`(IN `PaySca_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF PaySca_Id != 0 THEN
        SELECT ps.id, ps.pay_name FROM pay_scale as ps WHERE ps.id = PaySca_Id AND ps.isactive = 1;
    ELSE
        SELECT ps.id, ps.pay_name FROM pay_scale as ps WHERE ps.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectPermissionAssignInfo`(IN `PermAssi_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF PermAssi_Id != 0 THEN
        SELECT pa.id, pa.Role_Id, pa.Permission_Id
        FROM permission_assign as pa
        WHERE pa.id = PermAssi_Id
          AND pa.isactive = 1;
    ELSE
        SELECT pa.id, pa.Role_Id, pa.Permission_Id FROM permission_assign as pa WHERE pa.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectPermissionInfo`(IN `Perm_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF Perm_Id != 0 THEN
        SELECT p.id,
               p.permisssion_name,
               p.controller,
               p.action,
               p.parameters,
               p.method,
               p.icon,
               p.sort,
               p.parent_id
        FROM permission as p
        WHERE p.id = Perm_Id
          AND p.isactive = 1;
    ELSE
        SELECT p.id,
               p.permisssion_name,
               p.controller,
               p.action,
               p.parameters,
               p.method,
               p.icon,
               p.sort,
               p.parent_id
        FROM permission as p
        WHERE p.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectRoleAssignInfo`(IN `RoleAssi_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF RoleAssi_Id != 0 THEN
        SELECT ra.id, ra.Role_Id, ra.User_Id FROM role_assign as ra WHERE ra.id = RoleAssi_Id AND ra.isactive = 1;
    ELSE
        SELECT ra.id, ra.Role_Id, ra.User_Id FROM role_assign as ra WHERE ra.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectRoleInfo`(IN `Roles_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF Roles_Id != 0 THEN
        SELECT r.id, r.role_name
        FROM role as r
        WHERE r.isactive = 1
          AND r.id = Roles_Id;
    ELSE
        SELECT r.id, r.role_name
        FROM role as r
        WHERE r.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectShiftInfo`(IN `Shift_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF Shift_Id != 0 THEN
        SELECT s.id, s.shift_name, s.time_in, s.time_out, s.grace_time
        FROM shift as s
        WHERE s.id = Shift_Id
          AND s.isactive = 1;
    ELSE
        SELECT s.id, s.shift_name, s.time_in, s.time_out, s.grace_time FROM shift as s WHERE s.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectUserInfo`(IN `UId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF UId != 0 THEN
        SELECT u.id, u.Role_Id, u.UserP_Id, u.username, u.password
        FROM user as u
        WHERE u.id = UId AND u.isactive = 1;
    ELSE
        SELECT u.id, u.Role_Id, u.UserP_Id, u.username, u.password FROM user as u WHERE u.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_SelectUserProfileInfo`(IN `UpId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    IF UpId != 0 THEN
        SELECT up.id,
               up.Employee_Id,
               d.designation_name,
               ps.pay_name,
               s.shift_nameCONCAT(up.firstname, ' ', up.lastname) as PersonName,
               up.CNIC,
               up.Gmail,
               g.Gender,
               up.address,
               up.contact,
               up.workingDays,
               up.salary,
               up.Advance,
               up.isactive
        FROM user_profile as up
                 JOIN designation as d On up.Designation_Id = d.id
                 JOIN pay_scale as ps ON up.payscale_id = ps.id
                 JOIN shift as s ON up.shift_id = s.id
                 jOIN tbl_gender as g ON up.gender = g.id
        WHERE up.id = UpId;
-- SELECT up.id,up.Designation_Id,up.Employee_Id,up.firstname,up.lastname,up.address,up.contact,up.gender,up.shift_id,up.payscale_id,up.salary,up.Advance FROM user_profile as up WHERE up.id = UpId AND up.isactive = 1;
    ELSE
        SELECT up.id,
               up.Employee_Id,
               d.designation_name,
               ps.pay_name,
               s.shift_name,
               CONCAT(up.firstname, ' ', up.lastname) as PersonName,
               up.CNIC,
               up.Gmail,
               g.Gender,
               up.address,
               up.contact,
               up.workingDays,
               up.salary,
               up.Advance,
               up.isactive
        FROM user_profile as up
                 JOIN designation as d On up.Designation_Id = d.id
                 JOIN pay_scale as ps ON up.payscale_id = ps.id
                 JOIN shift as s ON up.shift_id = s.id
                 jOIN tbl_gender as g ON up.gender = g.id;
-- SELECT up.id,up.Designation_Id,up.Employee_Id,up.firstname,up.lastname,up.address,up.contact,up.gender,up.shift_id,up.payscale_id,up.salary,up.Advance FROM user_profile as up WHERE up.isactive = 1;
    END IF;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateAdvanceInfo`(IN `adv_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE advance as ad SET ad.isactive = 0, ad.updated_on = CURRENT_TIMESTAMP WHERE ad.id = adv_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateAttendanceInfo`(IN `AtenId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE attendance as a SET a.isactive = 0, a.updated_on=CURRENT_TIMESTAMP WHERE a.id = AtenId;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateDesignationInfo`(IN `Desig_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE designation as d SET d.isactive = 0, d.updated_on = CURRENT_TIMESTAMP WHERE d.id = Desig_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateHolidayInfo`(IN `HoliId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE holidays SET isactive = 0 WHERE id = HoliId;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdatePayRollInfo`(IN `PayRoll_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE payroll as pr SET pr.isactive = 0, pr.updated_on = CURRENT_TIMESTAMP WHERE pr.id = PayRoll_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdatePayScaleInfo`(IN `PaySca_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE pay_scale as ps SET ps.isactive = 0, ps.updated_on = CURRENT_TIMESTAMP WHERE ps.id = PaySca_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdatePermissionAssignInfo`(IN `PermAssi_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE permission_assign as pa SET pa.isactive = 0, pa.updated_on = CURRENT_TIMESTAMP WHERE pa.id = PermAssi_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdatePermissionInfo`(IN `Perm_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE permission as p SET p.isactive = 0, p.updated_on = CURRENT_TIMESTAMP WHERE p.id = Perm_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateRoleInfo`(IN `Roles_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE role as r SET r.isactive = 0, r.updated_on = CURRENT_TIMESTAMP WHERE r.id = Roles_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateShiftInfo`(IN `Shift_Id` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE shift as s SET s.isactive = 0, s.updated_on = CURRENT_TIMESTAMP WHERE s.id = Shift_Id;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateUserInfo`(IN `UId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE user as u SET u.isactive = 0, u.updated_on = CURRENT_TIMESTAMP WHERE u.id = UId;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrProc_UpdateUser_ProfileInfo`(IN `UPId` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
    UPDATE user_profile as up SET up.isactive = 0, up.updated_on = CURRENT_TIMESTAMP WHERE up.id = UPId;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `StrPro_GaveAdvance`(IN `EMPID` VARCHAR(50))
BEGIN
    SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);

    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) NOT IN (1, 7)
                      ORDER BY 1 ASC);

    SELECT a.Net_Salary as PayableAmount
    FROM (SELECT up.id                                                                           AS EMPID,
                 up.salary,
                 FLOOR(DeductedDaysBecauseOfLateArrival)                                            AS DeductionDays,
                 NoOfLates                                                                          AS TotalLate,
                 (SystemWorkingDays - AttendedDays)                                                 AS Absent,
                 (
                         (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                         (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
                 FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                       FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
                 )                                                                                  AS Net_Salary
          FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                       @SundayOff                                                       AS SunOff,
                       CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                       up.Employee_Id                                                   AS EMPID,
                       COUNT(a.check_in_date)                                           AS AttendedDays,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                            TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                       ELSE '0' END
                           END) /
                       3                                                                AS DeductedDaysBecauseOfLateArrival,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                            TIME(s.grace_time) THEN 1
                                       ELSE 0 END
                           END)                                                         AS _NoOfLates,
                       FLOOR((SUM(CASE
                                      WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                           TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                      ELSE '0' END)))                                      NoOfLates
                FROM attendance a
                         JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                         JOIN shift s ON s.id = up.shift_id
                         JOIN designation d ON d.id = up.Designation_Id
                         JOIN pay_scale pp ON pp.id = up.payscale_id
                WHERE a.isactive = 1
                  AND a.Employee_Id = EmpId
                GROUP BY up.Employee_Id) AS a
                   JOIN user_profile up ON up.Employee_Id = a.EMPID
                   JOIN shift s ON s.id = up.shift_id
                   JOIN designation d ON d.id = up.Designation_Id
                   JOIN pay_scale pp ON pp.id = up.payscale_id) as A;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Temp1_For_Advance`(IN `EmpId` INT)
BEGIN
    SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

    -- 6 days emp==========================
    SET @SundayOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) != 1
                      ORDER BY 1 ASC);

    -- 5 days emp==========================
    SET @SatSunOff = (SELECT COUNT(date_field)
                      FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                   INTERVAL daynum DAY date_field
                            FROM (SELECT t * 10 + u daynum
                                  FROM (SELECT 0 t
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3) A,
                                       (SELECT 0 u
                                        UNION
                                        SELECT 1
                                        UNION
                                        SELECT 2
                                        UNION
                                        SELECT 3
                                        UNION
                                        SELECT 4
                                        UNION
                                        SELECT 5
                                        UNION
                                        SELECT 6
                                        UNION
                                        SELECT 7
                                        UNION
                                        SELECT 8
                                        UNION
                                        SELECT 9) B
                                  ORDER BY daynum) AA) AAA
                      WHERE MONTH(date_field) = MONTH(NOW())
                        AND DAYOFWEEK(date_field) NOT IN (1, 7)
                      ORDER BY 1 ASC);

    SELECT a.Net_Salary as PayableAmount
    FROM (SELECT up.id                                                                           AS EMPID,
                 up.salary,
                 FLOOR(DeductedDaysBecauseOfLateArrival)                                            AS DeductionDays,
                 NoOfLates                                                                          AS TotalLate,
                 (SystemWorkingDays - AttendedDays)                                                 AS Absent,
                 (
                         (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                         (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
                 FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                       FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
                 )                                                                                  AS Net_Salary
          FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                       @SundayOff                                                       AS SunOff,
                       CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                       up.Employee_Id                                                   AS EMPID,
                       COUNT(a.check_in_date)                                           AS AttendedDays,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                            TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                       ELSE '0' END
                           END) /
                       3                                                                AS DeductedDaysBecauseOfLateArrival,
                       SUM(CASE
                               WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                   THEN 0
                               ELSE
                                   CASE
                                       WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                            TIME(s.grace_time) THEN 1
                                       ELSE 0 END
                           END)                                                         AS _NoOfLates,
                       FLOOR((SUM(CASE
                                      WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                           TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                      ELSE '0' END)))                                      NoOfLates
                FROM attendance a
                         JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                         JOIN shift s ON s.id = up.shift_id
                         JOIN designation d ON d.id = up.Designation_Id
                         JOIN pay_scale pp ON pp.id = up.payscale_id
                WHERE a.isactive = 1
                  AND a.Employee_Id = EmpId
                GROUP BY up.Employee_Id) AS a
                   JOIN user_profile up ON up.Employee_Id = a.EMPID
                   JOIN shift s ON s.id = up.shift_id
                   JOIN designation d ON d.id = up.Designation_Id
                   JOIN pay_scale pp ON pp.id = up.payscale_id) as A;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `temp2`()
BEGIN

    UPDATE attendance AS a
        JOIN user_profile AS up ON up.Employee_Id = a.Employee_Id
        JOIN shift AS s ON up.shift_id = s.id
    SET a.over_time =
            CASE
                WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
                ELSE '00:00:00' -- Zero if Earlier Departure
                END
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;

    SELECT a.Employee_Id,
           CONCAT(up.firstname, ' ', up.lastname) as PersonName,
           TIME_FORMAT(TIME(a.check_in), '%r')    AS Check_In,
           a.check_in_date                        AS Check_In_Date,
           TIME_FORMAT(TIME(a.check_out), '%r')   AS Check_Out,
           s.shift_name                           AS Shift_Name,
           -- a.over_time AS Over_Time,
           CASE
               WHEN TIME(a.check_in) > TIME(s.time_in) THEN TIMEDIFF(TIME(a.check_in), TIME(s.time_in))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Late_Coming,
           CASE
               WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Over_Time,
           CASE
               WHEN TIME(a.check_in) <= TIME(s.time_in) THEN TIMEDIFF(TIME(s.time_in), TIME(a.check_in))
               ELSE '00:00:00' -- Zero if No Earlier Departure
               END                                AS Earlier_Arrival,
        /*  CASE WHEN time(a.check_out) < time(s.time_out) THEN timediff((concat(a.check_in_date,' ',time(s.time_out))),a.check_out) ELSE '-' END As Earlier_Departure,*/
           CASE
               WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                    TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Late'
               WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Absent'
               ELSE 'On Time'
               END                                AS Status,
           CASE
               WHEN TIME(a.check_in) = NULL THEN 'Absent'
               ELSE 'On Time'
               END                                AS Status
    FROM attendance AS a
             JOIN
         user_profile AS up ON up.Employee_Id = a.Employee_Id
             JOIN
         shift AS s ON up.shift_id = s.id
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `TempTestAttendance`()
BEGIN

    UPDATE attendance AS a
        JOIN user_profile AS up ON up.Employee_Id = a.Employee_Id
        JOIN shift AS s ON up.shift_id = s.id
    SET a.over_time =
            CASE
                WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
                ELSE '00:00:00' -- Zero if Earlier Departure
                END
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;

    SELECT a.Employee_Id,
           CONCAT(up.firstname, ' ', up.lastname) as PersonName,
           TIME_FORMAT(TIME(a.check_in), '%r')    AS Check_In,
           a.check_in_date                        AS Check_In_Date,
           TIME_FORMAT(TIME(a.check_out), '%r')   AS Check_Out,
           s.shift_name                           AS Shift_Name,
           -- a.over_time AS Over_Time,
           CASE
               WHEN TIME(a.check_in) > TIME(s.time_in) THEN TIMEDIFF(TIME(a.check_in), TIME(s.time_in))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Late_Coming,
           CASE
               WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
               ELSE '00:00:00' -- Zero if Earlier Departure
               END                                AS Over_Time,
           CASE
               WHEN TIME(a.check_in) <= TIME(s.time_in) THEN TIMEDIFF(TIME(s.time_in), TIME(a.check_in))
               ELSE '00:00:00' -- Zero if No Earlier Departure
               END                                AS Earlier_Arrival,
        /*  CASE WHEN time(a.check_out) < time(s.time_out) THEN timediff((concat(a.check_in_date,' ',time(s.time_out))),a.check_out) ELSE '-' END As Earlier_Departure,*/
           CASE
               WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                    TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Late'
               WHEN TIME(a.check_in) >= ADDTIME(TIME(s.time_in), '04:00:00') THEN 'Absent'
               ELSE 'On Time'
               END                                AS Status,
           CASE
               WHEN TIME(a.check_in) = NULL THEN 'Absent'
               ELSE 'On Time'
               END                                AS Status
    FROM attendance AS a
             JOIN
         user_profile AS up ON up.Employee_Id = a.Employee_Id
             JOIN
         shift AS s ON up.shift_id = s.id
    WHERE a.isactive = 1
      AND s.isactive = 1
      AND up.isactive = 1;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `temp_InsertAttendanceInfo`(IN `Employee_Id` INT, IN `CheckIn` DATETIME,
                                                                       IN `CheckOut` DATETIME, IN `over_time` TIME)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- If an error occurs, rollback the transaction
            ROLLBACK;
            -- You can customize the error handling here (e.g., raise an error message)
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'An error occurred during the transaction';
        END;

    START TRANSACTION;
    -- Insert the data into the attendance table
    INSERT INTO attendance (Employee_Id, check_in, check_out, over_time, created_by, created_on)
    VALUES (Employee_Id, CheckIn, CheckOut, over_time, 1, CURRENT_TIMESTAMP);

    -- Commit the transaction if everything is successful
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Temp_InsertPayrollData`()
BEGIN
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
        SELECT up.Employee_Id,
               up.Designation_Id,
               up.Shift_Id,
               s.time_in,
               s.time_out,
               up.salary,
               (SystemWorkingDays - AttendedDays)                                                           AS absent,
               NoOfLates                                                                                    AS late,
               FLOOR(DeductedDaysBecauseOfLateArrival)                                                      AS deducted_days,
               (FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival)) +
                FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) *
                      (SystemWorkingDays - AttendedDays)))                                                  AS Deduction,
               FLOOR(up.salary -
                     FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     FLOOR((up.salary / DAY(LAST_DAY(CURRENT_DATE))) * (SystemWorkingDays - AttendedDays))) AS Total_Pay
        FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                     @SundayOff                                                       AS SunOff,
                     CASE WHEN up.workingDays = 5 THEN @SundayOff ELSE @SatSunOff END AS SystemWorkingDays,
                     up.Employee_Id                                                   AS EMPID,
                     COUNT(a.check_in_date)                                           AS AttendedDays,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time) THEN 1
                                     ELSE 0 END
                         END) /
                     3                                                                AS DeductedDaysBecauseOfLateArrival,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time) THEN 1
                                     ELSE 0 END
                         END)                                                         AS NoOfLates
              FROM attendance a
                       JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                       JOIN shift s ON s.id = up.shift_id
                       JOIN designation d ON d.id = up.Designation_Id
              WHERE a.isactive = 1
              GROUP BY up.Employee_Id) AS a
                 JOIN user_profile up ON up.Employee_Id = a.EMPID
                 JOIN shift s ON s.id = up.shift_id
                 JOIN designation d ON d.id = up.Designation_Id;
    -- ___________________________________________________________________________________________________________________________________Talha/Abdullah Query End


    -- Handlers for exceptions
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

    -- Open the cursor
    OPEN cur;

    -- Loop through the cursor and insert data
    read_loop:
    LOOP
        FETCH cur INTO emp_id, desig_id,shift_id,emp_time_in,emp_time_out,emp_salary, emp_absent, emp_late, emp_deducted_days, emp_deduction, emp_total_pay;
        IF done THEN
            LEAVE read_loop;
        END IF;

        -- Insert data into payroll table
        INSERT INTO payroll (Employee_Id, Designation_Id, Shift_Id, time_in, time_out, salary, absent, late,
                             deducted_days, Deduction, Total_Pay)
        VALUES (emp_id, desig_id, shift_id, emp_time_in, emp_time_out, emp_salary, emp_absent, emp_late,
                emp_deducted_days, emp_deduction, emp_total_pay);
    END LOOP;

    -- Close the cursor
    CLOSE cur;

END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `TEMP_StrProc_SelectPayRollInfo`(IN `PayRoll_Id` INT)
BEGIN
    IF PayRoll_Id != 0 THEN
        SELECT pr.id,
               up.firstname,
               d.designation_name,
               s.shift_name,
               ps.pay_name,
               pr.Deduction,
               up.salary,
               pr.Total_Pay
        FROM payroll as pr
                 JOIN user_profile as up ON pr.UserP_Id = up.id
                 JOIN designation as d ON pr.Designation_Id = d.id
                 JOIN shift as s ON pr.Shift_Id = s.id
                 JOIN pay_scale as ps ON pr.Pay_Id = ps.id
                 JOIN user as u ON ps.created_by = u.id
                 JOIN user as u1 ON ps.updated_by = u1.id
        WHERE pr.id = PayRoll_Id
          AND ps.isactive = 1
          AND up.isactive = 1
          AND d.isactive = 1
          AND s.isactive = 1
          AND ps.isactive = 1
          AND u.isactive = 1
          AND u1.isactive = 1;
    ELSE
        SELECT pr.id,
               up.firstname,
               d.designation_name,
               s.shift_name,
               ps.pay_name,
               pr.Deduction,
               up.salary,
               pr.Total_Pay
        FROM payroll as pr
                 JOIN user_profile as up ON pr.UserP_Id = up.id
                 JOIN designation as d ON pr.Designation_Id = d.id
                 JOIN shift as s ON pr.Shift_Id = s.id
                 JOIN pay_scale as ps ON pr.Pay_Id = ps.id
                 JOIN user as u ON ps.created_by = u.id
                 JOIN user as u1 ON ps.updated_by = u1.id
        WHERE ps.isactive = 1
          AND up.isactive = 1
          AND d.isactive = 1
          AND s.isactive = 1
          AND ps.isactive = 1
          AND u.isactive = 1
          AND u1.isactive = 1;
    END IF;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Temp_s_PayrollGenerator`(IN `Userid` INT)
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
        END;
    START TRANSACTION;
-- Calculate the number of days in the previous month (August)
    SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

-- Check if records exist for the current month
    SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));

    IF (@isExist <= 0) THEN
        -- 6 days emp==========================
        SET @SundayOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = MONTH(NOW())
                            AND DAYOFWEEK(date_field) != 1
                          ORDER BY 1 ASC);

        -- 5 days emp==========================
        SET @SatSunOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = MONTH(NOW())
                            AND DAYOFWEEK(date_field) NOT IN (1, 7)
                          ORDER BY 1 ASC);

        -- Insert data into payroll table
        INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, salary, deducted_days, late,
                            absent, Deduction, M_Deducted, M_Salary, Total_Pay, created_by, updated_by)
        SELECT up.id                                                                                            AS EMPID,
               d.id,
               s.id                                                                                             AS Shift,
               pp.id,
               TIME(s.time_in)                                                                                     AS TimeIn,
               TIME(s.time_out)                                                                                    AS TimeOut,
               up.salary,
               up.advance,
               FLOOR(DeductedDaysBecauseOfLateArrival)                                                             AS DeductionDays,
               NoOfLates                                                                                           AS TotalLate,
               (SystemWorkingDays - AttendedDays)                                                                  AS Absent, -- Calculate absent days as (SystemWorkingDays - AttendedDays)
               (
                           (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                           (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))) -
                           up.Advance)                                                                             AS Deduction,
               (
                           (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                           (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))) -
                           up.Advance)                                                                             AS MDeduction,
               FLOOR(up.salary - up.Advance -
                     FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
               )                                                                                                   AS Net_Salary,
               FLOOR(up.salary - up.Advance -
                     FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
               )                                                                                                   AS MSalary,
               Userid,
               Userid
        FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                     @SundayOff                                                       AS SunOff,
                     CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                     up.Employee_Id                                                   AS EMPID,
                     COUNT(a.check_in_date)                                           AS AttendedDays,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                          TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                     ELSE '0' END
                         END) /
                     3                                                                AS DeductedDaysBecauseOfLateArrival,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time) THEN 1
                                     ELSE 0 END
                         END)                                                         AS _NoOfLates,
                     FLOOR((SUM(CASE
                                    WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                         TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                    ELSE '0' END)))                                      NoOfLates
              FROM attendance a
                       JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                       JOIN shift s ON s.id = up.shift_id
                       JOIN designation d ON d.id = up.Designation_Id
                       JOIN pay_scale pp ON pp.id = up.payscale_id
              WHERE a.isactive = 1
              GROUP BY up.Employee_Id) AS a
                 JOIN user_profile up ON up.Employee_Id = a.EMPID
                 JOIN shift s ON s.id = up.shift_id
                 JOIN designation d ON d.id = up.Designation_Id
                 JOIN pay_scale pp ON pp.id = up.payscale_id;
    END IF;

-- Show Data
    SELECT pr.id,
           CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
           d.designation_name,
           s.shift_name,
           ps.pay_name,
           TIME(s.time_in)                           time_in,
           TIME(s.time_out)                          time_out,
           pr.salary,
           pr.deducted_days,
           pr.late,
           pr.absent,
           pr.Advance,
           pr.Deduction,
           pr.M_Deducted,
           pr.M_Salary,
           pr.Total_Pay,
           pr.updated_on
    FROM payroll pr
             JOIN user_profile up ON up.id = pr.UserP_Id
             JOIN designation d ON d.id = pr.Designation_Id
             JOIN shift s ON s.id = pr.Shift_Id
             JOIN pay_scale ps ON ps.id = pr.Pay_Id
    WHERE MONTH(pr.created_on) = MONTH(NOW())
      AND pr.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1;
    COMMIT;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Test1_StrProc_SelectAttendanceInfo`()
SELECT a.Employee_Id,
       CONCAT(up.firstname, ' ', up.lastname) AS Person_Name,
       a.check_in                             AS Check_In,
       a.check_in_date                        AS Check_In_Date,
       a.check_out                            AS Check_Out,
       s.shift_name                           AS Shift_Name,
       CASE
           WHEN a.check_in > s.time_in THEN TIMEDIFF(a.check_in, s.time_in)
           ELSE '00:00:00' -- Zero if Earlier Departure
           END                                AS Late_Coming,
       CASE
           WHEN time(a.check_out) > time(s.time_out) THEN TIMEDIFF(time(a.check_out), time(s.time_out))
           ELSE '00:00:00' -- Zero if Earlier Departure
           END                                AS Over_Time,
       CASE
           WHEN a.check_in <= s.time_in THEN TIMEDIFF(s.time_in, a.check_in)
           ELSE '00:00:00' -- Zero if No Earlier Departure
           END                                AS Earlier_Departure,
       CASE
           WHEN a.check_in > ADDTIME(s.time_in, s.grace_time) AND a.check_in < ADDTIME(s.time_in, '04:00:00')
               THEN 'Late'
           WHEN a.check_in >= ADDTIME(s.time_in, '04:00:00') THEN 'Absent'
           ELSE 'On Time'
           END                                AS Status
FROM attendance AS a
         JOIN
     user_profile AS up ON up.Employee_Id = a.Employee_Id
         JOIN
     shift AS s ON up.shift_id = s.id
WHERE a.isactive = 1
  AND s.isactive = 1
  AND up.isactive = 1$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Test2_STR_GeneratePayRollInfo`(IN `Userid` INT)
BEGIN
    -- Calculate the number of days in the previous month (August)
    SET @DaysInAugust = DAY(LAST_DAY(DATE_SUB(CURRENT_DATE, INTERVAL 1 MONTH)));

-- Check if records exist for the current month
    SET @isExist = (SELECT COUNT(*) FROM `payroll` WHERE MONTH(created_on) = MONTH(CURRENT_DATE));

    IF (@isExist <= 0) THEN
        -- 6 days emp==========================
        SET @SundayOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = MONTH(NOW())
                            AND DAYOFWEEK(date_field) != 1
                          ORDER BY 1 ASC);

        -- 5 days emp==========================
        SET @SatSunOff = (SELECT COUNT(date_field)
                          FROM (SELECT MAKEDATE(YEAR(NOW()), 1) + INTERVAL (MONTH(NOW()) - 1) MONTH +
                                       INTERVAL daynum DAY date_field
                                FROM (SELECT t * 10 + u daynum
                                      FROM (SELECT 0 t
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3) A,
                                           (SELECT 0 u
                                            UNION
                                            SELECT 1
                                            UNION
                                            SELECT 2
                                            UNION
                                            SELECT 3
                                            UNION
                                            SELECT 4
                                            UNION
                                            SELECT 5
                                            UNION
                                            SELECT 6
                                            UNION
                                            SELECT 7
                                            UNION
                                            SELECT 8
                                            UNION
                                            SELECT 9) B
                                      ORDER BY daynum) AA) AAA
                          WHERE MONTH(date_field) = MONTH(NOW())
                            AND DAYOFWEEK(date_field) NOT IN (1, 7)
                          ORDER BY 1 ASC);

        -- Insert data into payroll table
        INSERT INTO payroll(UserP_Id, Designation_Id, Shift_Id, Pay_Id, time_in, time_out, salary, deducted_days, late,
                            absent, Deduction, M_Deducted, M_Salary, Total_Pay, created_by, updated_by)
        SELECT up.id                                                                           AS EMPID,
               d.id,
               s.id                                                                            AS Shift,
               pp.id,
               TIME(s.time_in)                                                                    AS TimeIn,
               TIME(s.time_out)                                                                   AS TimeOut,
               up.salary,
               FLOOR(DeductedDaysBecauseOfLateArrival)                                            AS DeductionDays,
               NoOfLates                                                                          AS TotalLate,
               (SystemWorkingDays - AttendedDays)                                                 AS Absent, -- Calculate absent days as (SystemWorkingDays - AttendedDays)
               (
                       (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                       (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS Deduction,
               (
                       (FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival))) +
                       (FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays)))) AS MDeduction,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
               )                                                                                  AS Net_Salary,
               FLOOR(up.salary - FLOOR((up.salary / @DaysInAugust) * FLOOR(DeductedDaysBecauseOfLateArrival)) -
                     FLOOR((up.salary / @DaysInAugust) * (SystemWorkingDays - AttendedDays))
               )                                                                                  AS MSalary,
               Userid,
               Userid
        FROM (SELECT @SatSunOff                                                       AS SatSunOff,
                     @SundayOff                                                       AS SunOff,
                     CASE WHEN up.workingDays = 5 THEN @SatSunOff ELSE @SundayOff END AS SystemWorkingDays,
                     up.Employee_Id                                                   AS EMPID,
                     COUNT(a.check_in_date)                                           AS AttendedDays,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                          TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                     ELSE '0' END
                         END) /
                     3                                                                AS DeductedDaysBecauseOfLateArrival,
                     SUM(CASE
                             WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) <= 0
                                 THEN 0
                             ELSE
                                 CASE
                                     WHEN SEC_TO_TIME(TIME_TO_SEC(TIME(a.check_in) - TIME(s.time_in))) >
                                          TIME(s.grace_time) THEN 1
                                     ELSE 0 END
                         END)                                                         AS _NoOfLates,
                     FLOOR((SUM(CASE
                                    WHEN TIME(a.check_in) > ADDTIME(TIME(s.time_in), TIME(s.grace_time)) AND
                                         TIME(a.check_in) < ADDTIME(TIME(s.time_in), '04:00:00') THEN '1'
                                    ELSE '0' END)))                                      NoOfLates
              FROM attendance a
                       JOIN user_profile up ON up.Employee_Id = a.Employee_Id
                       JOIN shift s ON s.id = up.shift_id
                       JOIN designation d ON d.id = up.Designation_Id
                       JOIN pay_scale pp ON pp.id = up.payscale_id
              WHERE a.isactive = 1
              GROUP BY up.Employee_Id) AS a
                 JOIN user_profile up ON up.Employee_Id = a.EMPID
                 JOIN shift s ON s.id = up.shift_id
                 JOIN designation d ON d.id = up.Designation_Id
                 JOIN pay_scale pp ON pp.id = up.payscale_id;
    END IF;

-- Show Data
    SELECT pr.id,
           CONCAT(up.firstname, ' ', up.lastname) AS Employee_Name,
           d.designation_name,
           s.shift_name,
           ps.pay_name,
           TIME(s.time_in)                           time_in,
           TIME(s.time_out)                          time_out,
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
             JOIN user_profile up ON up.id = pr.UserP_Id
             JOIN designation d ON d.id = pr.Designation_Id
             JOIN shift s ON s.id = pr.Shift_Id
             JOIN pay_scale ps ON ps.id = pr.Pay_Id
    WHERE MONTH(pr.created_on) = MONTH(NOW())
      AND pr.isactive = 1
      AND d.isactive = 1
      AND s.isactive = 1;
END$$

CREATE
    DEFINER = `root`@`localhost` PROCEDURE `Test_For_Roles`(IN `Roles_Id` INT)
BEGIN
    IF Roles_Id != 0 THEN
        SELECT r.id, r.role_name, r.isactive, r.created_by, r.updated_by, r.created_on, r.updated_on
        FROM role as r
                 JOIN user as u ON r.created_by = u.id
                 JOIN user as u1 ON r.updated_by = u1.id
        WHERE r.isactive = 1
          AND u.isactive = 1
          AND u1.isactive = 1
          AND r.id = Roles_Id;
    ELSE
        SELECT r.id, r.role_name, r.isactive, r.created_by, r.updated_by, r.created_on, r.updated_on
        FROM role as r
                 JOIN user as u ON r.created_by = u.id
                 JOIN user as u1 ON r.updated_by = u1.id
        WHERE r.isactive = 1
          AND u.isactive = 1
          AND u1.isactive = 1;
    END IF;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `advance`
--

CREATE TABLE `advance`
(
    `id`      int(11)    NOT NULL,
    `Up_Id`      int(11)    NOT NULL,
    `Amount`     double              DEFAULT 0,
    `AmountDate` date       NOT NULL,
    `isactive`   tinyint(1) NOT NULL DEFAULT 1,
    `created_by` int(11)    NOT NULL,
    `updated_by` int(11)             DEFAULT NULL,
    `created_on` datetime   NOT NULL,
    `updated_on` datetime            DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `advance`
--

INSERT INTO `advance` (`id`, `Up_Id`, `Amount`, `AmountDate`, `isactive`, `created_by`, `updated_by`, `created_on`,
                       `updated_on`)
VALUES (1, 14, 9000, '2023-09-21', 1, 1, NULL, '2023-09-21 21:45:10', NULL),
       (2, 14, 35, '2023-09-25', 1, 1, NULL, '2023-09-25 19:54:02', NULL),
       (3, 14, 3500, '2023-09-25', 1, 1, NULL, '2023-09-25 23:13:26', NULL),
       (4, 14, 3500, '2023-09-25', 1, 1, NULL, '2023-09-25 23:16:50', NULL),
       (5, 14, 3500, '2023-09-26', 1, 1, NULL, '2023-09-25 23:26:31', NULL),
       (6, 14, 3500, '2023-09-26', 1, 1, NULL, '2023-09-26 00:19:49', NULL),
       (7, 14, 3500, '0000-00-00', 1, 1, NULL, '2023-09-26 00:36:35', NULL),
       (8, 14, 35, '2023-09-26', 1, 1, NULL, '2023-09-26 00:36:52', NULL),
       (9, 14, 3500, '2023-09-26', 1, 1, NULL, '2023-09-26 19:21:03', NULL),
       (10, 14, 500, '0000-00-00', 1, 1, NULL, '2023-09-26 19:21:32', NULL),
       (11, 1, 500, '0000-00-00', 1, 1, NULL, '2023-09-27 02:51:10', NULL),
       (12, 1, 500, '0000-00-00', 1, 1, NULL, '2023-09-27 02:53:32', NULL),
       (13, 1, 500, '0000-00-00', 1, 1, NULL, '2023-09-27 02:54:05', NULL),
       (14, 1, 500, '2023-09-26', 1, 1, NULL, '2023-09-27 02:54:33', NULL),
       (15, 14, 0, '0000-00-00', 1, 1, NULL, '2023-09-27 19:07:58', NULL),
       (16, 13, 0, '0000-00-00', 1, 1, NULL, '2023-09-27 19:12:48', NULL),
       (17, 1, 3500, '2023-09-27', 1, 1, NULL, '2023-09-27 21:39:55', NULL),
       (18, 14, 27097, '2023-10-02', 1, 1, NULL, '2023-10-02 21:15:17', NULL),
       (19, 14, 0, '0000-00-00', 1, 1, NULL, '2023-10-02 21:15:37', NULL),
       (20, 14, 0, '0000-00-00', 1, 1, NULL, '2023-10-02 21:16:12', NULL),
       (21, 14, 0, '0000-00-00', 1, 1, NULL, '2023-10-02 21:22:20', NULL),
       (22, 1, 1, '2023-10-02', 1, 1, NULL, '2023-10-02 21:28:49', NULL);

--
-- Triggers `advance`
--
DELIMITER $$
CREATE TRIGGER `advance_update_trigger`
    BEFORE UPDATE
    ON `advance`
    FOR EACH ROW
BEGIN

    Set @User = (select CONCAT(u.username, ' (', u.id, ')') from user u where u.id = NEW.updated_by);
    SET @GUser = '';

    IF NEW.Amount != OLD.Amount THEN
        Set @usrp = (select CONCAT(up.firstname, ' (', up.id, ')') from user_profile up WHERE up.id = OLD.Up_Id);
        SET @GUser = CONCAT(@GUser, ' ', CONCAT(@User, ' Approved Advance Amount: ', NEW.Amount, ' For ',
                                                (select CONCAT(up.firstname, ' (', up.id, ')')
                                                 from user_profile up
                                                 WHERE up.id = NEW.Up_Id)));
    END IF;

    IF NEW.Up_Id != OLD.Up_Id THEN
        SET @GUser = CONCAT(@GUser, ' ', CONCAT('And has changed Amount record from ', OLD.Amount, ' To ', New.Amount));
    END IF;


    insert into logs(Log_Description, TBL_Name, created_by, created_on) value (@GUser, 'Advance', NEW.id, CURRENT_TIMESTAMP);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `attendance`
--

CREATE TABLE `attendance`
(
    `id`         int(10)  NOT NULL,
    `Employee_Id`   int(11)  NOT NULL,
    `DeviceNo`      int(11)    DEFAULT NULL,
    `check_in`      datetime   DEFAULT NULL,
    `check_in_date` date     NOT NULL,
    `check_out`     datetime   DEFAULT NULL,
    `over_time`     time     NOT NULL,
    `isactive`      tinyint(1) DEFAULT 1,
    `created_by`    int(10)  NOT NULL,
    `updated_by`    int(10)    DEFAULT NULL,
    `created_on`    datetime NOT NULL,
    `updated_on`    datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `attendance`
--

INSERT INTO `attendance` (`id`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`,
                          `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, 14, NULL, '2023-08-01 11:30:31', '2023-08-01', '2023-08-01 10:30:35', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-10-02 20:49:40'),
       (2, 14, NULL, '2023-08-02 11:30:00', '2023-08-02', '2023-08-02 21:53:47', '01:23:47', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (3, 14, NULL, '2023-08-03 12:12:47', '2023-08-03', '2023-08-03 21:06:56', '00:36:56', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (4, 14, NULL, '2023-08-04 12:14:33', '2023-08-04', '2023-08-04 21:08:31', '00:38:31', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (5, 14, NULL, '2023-08-05 12:07:52', '2023-08-05', '2023-08-05 22:20:20', '01:50:20', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (6, 14, NULL, '2023-08-07 12:08:44', '2023-08-07', '2023-08-07 22:12:03', '01:42:03', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (7, 14, NULL, '2023-08-08 12:09:00', '2023-08-08', '2023-08-08 21:53:31', '01:23:31', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (8, 14, NULL, '2023-08-09 12:08:00', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (9, 14, NULL, '2023-08-10 12:09:54', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (10, 14, NULL, '2023-08-11 12:25:37', '2023-08-11', '2023-08-11 23:27:12', '02:57:12', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (11, 14, NULL, '2023-08-12 12:24:13', '2023-08-12', '2023-08-12 22:47:08', '02:17:08', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (12, 14, NULL, '2023-08-15 12:05:14', '2023-08-15', '2023-08-15 21:43:07', '01:13:07', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (13, 14, NULL, '2023-08-16 12:05:25', '2023-08-16', '2023-08-16 21:18:59', '00:48:59', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (14, 14, NULL, '2023-08-17 12:03:57', '2023-08-17', '2023-08-18 01:26:19', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (15, 14, NULL, '2023-08-18 12:10:56', '2023-08-18', '2023-08-18 20:58:19', '00:28:19', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (16, 14, NULL, '2023-08-19 11:15:29', '2023-08-19', '2023-08-19 21:01:38', '00:31:38', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (17, 14, NULL, '2023-08-21 11:55:34', '2023-08-21', '2023-08-21 21:41:30', '01:11:30', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (18, 14, NULL, '2023-08-22 12:05:39', '2023-08-22', '2023-08-22 20:51:39', '00:21:39', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (19, 14, NULL, '2023-08-23 12:11:20', '2023-08-23', '2023-08-23 20:53:35', '00:23:35', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (20, 14, NULL, '2023-08-24 12:02:24', '2023-08-24', '2023-08-24 20:55:02', '00:25:02', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (21, 14, NULL, '2023-08-25 12:00:51', '2023-08-25', '2023-08-25 20:51:45', '00:21:45', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (22, 14, NULL, '2023-08-26 11:49:48', '2023-08-26', '2023-08-26 21:32:42', '01:02:42', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (23, 14, NULL, '2023-08-28 12:00:58', '2023-08-28', '2023-08-28 22:05:29', '01:35:29', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (24, 14, NULL, '2023-08-29 11:53:16', '2023-08-29', '2023-08-29 21:22:01', '00:52:01', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (25, 14, NULL, '2023-08-30 11:55:57', '2023-08-30', '2023-08-30 21:21:30', '00:51:30', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (26, 14, NULL, '2023-08-31 12:04:36', '2023-08-31', '2023-08-31 21:19:00', '00:49:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (27, 16, NULL, '2023-08-01 11:11:20', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (28, 16, NULL, '2023-08-03 11:03:45', '2023-08-02', '2023-08-02 21:13:15', '00:43:15', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (29, 16, NULL, '2023-08-03 11:03:45', '2023-08-03', '2023-08-03 21:15:27', '00:45:27', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (30, 16, NULL, '2023-08-04 11:29:00', '2023-08-04', '2023-08-04 21:05:35', '00:35:35', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (31, 16, NULL, '2023-08-05 11:19:08', '2023-08-05', '2023-08-05 21:46:16', '01:16:16', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (32, 16, NULL, '2023-08-07 11:32:57', '2023-08-07', '2023-08-07 21:16:36', '00:46:36', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (33, 16, NULL, '2023-08-08 11:17:28', '2023-08-08', '2023-08-08 22:14:04', '01:44:04', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (34, 16, NULL, '2023-08-09 11:05:01', '2023-08-09', '2023-08-09 21:01:11', '00:31:11', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (35, 16, NULL, '2023-08-10 11:17:57', '2023-08-10', '2023-08-10 21:57:55', '01:27:55', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (36, 16, NULL, '2023-08-11 11:19:11', '2023-08-11', '2023-08-11 22:06:37', '01:36:37', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (37, 16, NULL, '2023-08-12 10:55:38', '2023-08-12', '2023-08-12 20:59:35', '00:29:35', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (38, 16, NULL, '2023-08-15 11:29:11', '2023-08-15', '2023-08-15 21:56:04', '01:26:04', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (39, 16, NULL, '2023-08-16 11:29:39', '2023-08-16', '2023-08-16 21:48:36', '01:18:36', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (40, 16, NULL, '2023-08-17 11:31:54', '2023-08-17', '2023-08-17 21:23:44', '00:53:44', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (41, 16, NULL, '2023-08-18 11:15:34', '2023-08-18', '2023-08-18 21:36:33', '01:06:33', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (42, 16, NULL, '2023-08-19 11:06:56', '2023-08-19', '2023-08-19 21:04:10', '00:34:10', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (43, 16, NULL, '2023-08-21 11:14:28', '2023-08-21', '2023-08-21 22:04:11', '01:34:11', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (44, 16, NULL, '2023-08-22 11:17:18', '2023-08-22', '2023-08-22 21:20:26', '00:50:26', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (45, 16, NULL, '2023-08-23 11:12:45', '2023-08-23', '2023-08-23 21:40:37', '01:10:37', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (46, 16, NULL, '2023-08-24 11:06:49', '2023-08-24', '2023-08-24 21:23:56', '00:53:56', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (47, 16, NULL, '2023-08-25 13:42:28', '2023-08-25', '2023-08-25 21:52:44', '01:22:44', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (48, 16, NULL, '2023-08-26 11:10:49', '2023-08-26', '2023-08-26 21:11:21', '00:41:21', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (49, 16, NULL, '2023-08-28 11:16:49', '2023-08-28', '2023-08-28 22:08:58', '01:38:58', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (50, 16, NULL, '2023-08-29 11:10:22', '2023-08-29', '2023-08-29 21:25:10', '00:55:10', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (51, 16, NULL, '2023-08-30 11:18:12', '2023-08-30', '2023-08-30 21:48:55', '01:18:55', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (52, 16, NULL, '2023-08-31 11:10:05', '2023-08-31', '2023-08-31 21:52:01', '01:22:01', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (53, 17, NULL, '2023-08-01 11:58:58', '2023-08-01', '2023-08-01 23:25:27', '02:55:27', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (54, 17, NULL, '2023-08-02 12:22:39', '2023-08-02', '2023-08-02 22:17:15', '01:47:15', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (55, 17, NULL, '2023-08-03 11:50:56', '2023-08-03', '2023-08-03 22:56:31', '02:26:31', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (56, 17, NULL, '2023-08-04 12:19:41', '2023-08-04', '2023-08-04 21:52:43', '01:22:43', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (57, 17, NULL, '2023-08-05 12:03:14', '2023-08-05', '2023-08-05 23:06:54', '02:36:54', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (58, 17, NULL, '2023-08-07 11:48:18', '2023-08-07', '2023-08-07 23:21:44', '02:51:44', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (59, 17, NULL, '2023-08-08 12:16:01', '2023-08-08', '2023-08-08 22:26:25', '01:56:25', 1, 1, 1,
        '2023-09-26 19:52:24', '2023-09-28 00:31:04'),
       (60, 17, NULL, '2023-08-09 12:04:10', '2023-08-09', '2023-08-09 23:06:11', '02:36:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (61, 17, NULL, '2023-08-10 11:53:45', '2023-08-10', '2023-08-10 22:01:59', '01:31:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (62, 17, NULL, '2023-08-11 12:46:28', '2023-08-11', '2023-08-11 22:27:56', '01:57:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (63, 17, NULL, '2023-08-12 12:14:19', '2023-08-12', '2023-08-12 23:43:00', '03:13:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (64, 17, NULL, '2023-08-15 12:39:12', '2023-08-15', '2023-08-15 22:24:27', '01:54:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (65, 17, NULL, '2023-08-16 12:15:49', '2023-08-16', '2023-08-16 22:19:48', '01:49:48', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (66, 17, NULL, '2023-08-17 12:14:25', '2023-08-17', '2023-08-17 20:33:40', '00:03:40', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (67, 17, NULL, '2023-08-18 12:17:20', '2023-08-18', '2023-08-18 21:41:29', '01:11:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (68, 17, NULL, '2023-08-19 11:52:55', '2023-08-19', '2023-08-19 21:23:43', '00:53:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (69, 17, NULL, '2023-08-21 11:58:59', '2023-08-21', '2023-08-21 21:48:13', '01:18:13', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (70, 17, NULL, '2023-08-22 12:00:29', '2023-08-22', '2023-08-22 21:58:02', '01:28:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (71, 17, NULL, '2023-08-23 12:03:02', '2023-08-23', '2023-08-23 22:04:57', '01:34:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (72, 17, NULL, '2023-08-24 12:01:02', '2023-08-24', '2023-08-24 21:54:27', '01:24:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (73, 17, NULL, '2023-08-25 12:44:49', '2023-08-25', '2023-08-25 21:58:27', '01:28:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (74, 17, NULL, '2023-08-26 12:13:37', '2023-08-26', '2023-08-26 22:11:35', '01:41:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (75, 17, NULL, '2023-08-28 12:16:32', '2023-08-28', '2023-08-28 23:26:32', '02:56:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (76, 17, NULL, '2023-08-29 12:16:19', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (77, 17, NULL, '2023-08-30 00:10:28', '2023-08-30', '2023-08-30 22:42:29', '02:12:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (78, 17, NULL, '2023-08-31 11:57:50', '2023-08-31', '2023-09-01 01:41:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (79, 18, NULL, '2023-08-01 10:41:59', '2023-08-01', '2023-08-01 20:46:55', '00:16:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (80, 18, NULL, '2023-08-02 10:44:38', '2023-08-02', '2023-08-02 20:44:47', '00:14:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (81, 18, NULL, '2023-08-03 10:55:18', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (82, 18, NULL, '2023-08-04 10:42:16', '2023-08-04', '2023-08-04 20:51:56', '00:21:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (83, 18, NULL, '2023-08-05 10:47:07', '2023-08-05', '2023-08-05 20:29:49', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (84, 18, NULL, '2023-08-07 10:41:57', '2023-08-07', '2023-08-07 20:44:07', '00:14:07', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (85, 18, NULL, '2023-08-08 10:53:17', '2023-08-08', '2023-08-08 20:51:18', '00:21:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (86, 18, NULL, '2023-08-09 10:41:42', '2023-08-09', '2023-08-09 20:43:05', '00:13:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (87, 18, NULL, '2023-08-10 10:38:54', '2023-08-10', '2023-08-10 20:43:48', '00:13:48', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (88, 18, NULL, '2023-08-11 10:41:25', '2023-08-11', '2023-08-11 20:40:56', '00:10:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (89, 18, NULL, '2023-08-12 10:45:24', '2023-08-12', '2023-08-12 20:37:16', '00:07:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (90, 18, NULL, '2023-08-15 10:45:32', '2023-08-15', '2023-08-15 20:46:32', '00:16:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (91, 18, NULL, '2023-08-16 10:35:39', '2023-08-16', '2023-08-16 20:40:52', '00:10:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (92, 18, NULL, '2023-08-17 10:46:23', '2023-08-17', '2023-08-17 20:34:12', '00:04:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (93, 18, NULL, '2023-08-18 10:49:24', '2023-08-18', '2023-08-18 20:46:42', '00:16:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (94, 18, NULL, '2023-08-19 10:31:55', '2023-08-19', '2023-08-19 20:39:15', '00:09:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (95, 18, NULL, '2023-08-21 10:40:02', '2023-08-21', '2023-08-21 20:46:44', '00:16:44', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (96, 18, NULL, '2023-08-22 10:42:44', '2023-08-22', '2023-08-22 20:47:47', '00:17:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (97, 18, NULL, '2023-08-23 10:49:12', '2023-08-23', '2023-08-23 20:46:20', '00:16:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (98, 18, NULL, '2023-08-24 10:48:55', '2023-08-24', '2023-08-24 20:42:31', '00:12:31', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (99, 18, NULL, '2023-08-25 10:40:47', '2023-08-25', '2023-08-25 20:49:18', '00:19:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (100, 18, NULL, '2023-08-26 10:43:46', '2023-08-26', '2023-08-26 20:41:55', '00:11:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (101, 18, NULL, '2023-08-28 10:44:29', '2023-08-28', '2023-08-28 20:51:33', '00:21:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (102, 18, NULL, '2023-08-29 10:50:14', '2023-08-29', '2023-08-29 20:47:55', '00:17:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (103, 18, NULL, '2023-08-30 10:47:30', '2023-08-30', '2023-08-30 20:49:54', '00:19:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (104, 18, NULL, '2023-08-31 10:43:28', '2023-08-31', '2023-08-31 20:39:52', '00:09:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (105, 19, NULL, '2023-08-01 11:49:16', '2023-08-01', '2023-08-01 21:40:21', '01:10:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (106, 19, NULL, '2023-08-02 11:36:17', '2023-08-02', '2023-08-02 21:13:29', '00:43:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (107, 19, NULL, '2023-08-03 11:30:08', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (108, 19, NULL, '2023-08-04 11:24:21', '2023-08-04', '2023-08-04 21:05:11', '00:35:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (109, 19, NULL, '2023-08-05 11:27:00', '2023-08-05', '2023-08-05 21:46:49', '01:16:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (110, 19, NULL, '2023-08-07 11:42:11', '2023-08-07', '2023-08-07 21:16:41', '00:46:41', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (111, 19, NULL, '2023-08-08 11:45:44', '2023-08-08', '2023-08-08 22:22:17', '01:52:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (112, 19, NULL, '2023-08-09 11:39:26', '2023-08-09', '2023-08-09 21:06:28', '00:36:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (113, 19, NULL, '2023-08-10 11:40:44', '2023-08-10', '2023-08-11 11:46:36', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (114, 19, NULL, '2023-08-11 11:46:39', '2023-08-11', '2023-08-11 22:07:01', '01:37:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (115, 19, NULL, '2023-08-15 11:39:22', '2023-08-15', '2023-08-15 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (116, 19, NULL, '2023-08-16 11:53:37', '2023-08-16', '2023-08-16 21:48:55', '01:18:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (117, 19, NULL, '2023-08-17 11:38:35', '2023-08-17', '2023-08-17 21:36:53', '01:06:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (118, 19, NULL, '2023-08-18 11:43:31', '2023-08-18', '2023-08-18 21:41:32', '01:11:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (119, 19, NULL, '2023-08-19 11:25:00', '2023-08-19', '2023-08-19 21:04:19', '00:34:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (120, 19, NULL, '2023-08-21 11:40:02', '2023-08-21', '2023-08-21 22:04:22', '01:34:22', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (121, 19, NULL, '2023-08-22 11:27:15', '2023-08-22', '2023-08-22 21:19:49', '00:49:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (122, 19, NULL, '2023-08-23 10:52:50', '2023-08-23', '2023-08-23 21:44:39', '01:14:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (123, 19, NULL, '2023-08-24 11:38:54', '2023-08-24', '2023-08-24 21:50:28', '01:20:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (124, 19, NULL, '2023-08-25 11:12:57', '2023-08-25', '2023-08-25 21:53:02', '01:23:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (125, 19, NULL, '2023-08-26 11:49:13', '2023-08-26', '2023-08-26 21:11:35', '00:41:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (126, 19, NULL, '2023-08-28 11:40:30', '2023-08-28', '2023-08-28 22:09:16', '01:39:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (127, 19, NULL, '2023-08-29 11:28:07', '2023-08-29', '2023-08-29 21:26:03', '00:56:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (128, 19, NULL, '2023-08-30 11:38:35', '2023-08-30', '2023-08-30 21:49:08', '01:19:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (129, 19, NULL, '2023-08-31 11:21:56', '2023-08-31', '2023-08-31 21:52:14', '01:22:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (130, 20, NULL, '2023-08-01 11:30:00', '2023-08-01', '2023-08-01 20:46:03', '00:16:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (131, 20, NULL, '2023-08-02 14:35:39', '2023-08-02', '2023-08-02 20:56:50', '00:26:50', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (132, 20, NULL, '2023-08-03 14:53:05', '2023-08-03', '2023-08-03 20:47:59', '00:17:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (133, 20, NULL, '2023-08-04 11:47:21', '2023-08-04', '2023-08-04 20:39:19', '00:09:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (134, 20, NULL, '2023-08-05 12:07:04', '2023-08-05', '2023-08-05 21:23:23', '00:53:23', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (135, 20, NULL, '2023-08-07 15:00:27', '2023-08-07', '2023-08-07 21:25:37', '00:55:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (136, 20, NULL, '2023-08-08 14:42:18', '2023-08-08', '2023-08-08 21:35:42', '01:05:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (137, 20, NULL, '2023-08-09 15:01:53', '2023-08-09', '2023-08-09 21:43:03', '01:13:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (138, 20, NULL, '2023-08-10 14:57:07', '2023-08-10', '2023-08-10 21:05:35', '00:35:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (139, 20, NULL, '2023-08-11 11:57:35', '2023-08-11', '2023-08-11 20:42:34', '00:12:34', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (140, 20, NULL, '2023-08-12 12:00:49', '2023-08-12', '2023-08-12 22:03:08', '01:33:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (141, 20, NULL, '2023-08-15 14:51:25', '2023-08-15', '2023-08-15 21:08:29', '00:38:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (142, 20, NULL, '2023-08-16 14:48:11', '2023-08-16', '2023-08-16 21:04:00', '00:34:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (143, 20, NULL, '2023-08-17 14:40:50', '2023-08-17', '2023-08-17 20:42:28', '00:12:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (144, 20, NULL, '2023-08-18 11:48:15', '2023-08-18', '2023-08-18 20:51:27', '00:21:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (145, 20, NULL, '2023-08-19 11:53:13', '2023-08-19', '2023-08-19 20:42:33', '00:12:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (146, 20, NULL, '2023-08-21 14:44:54', '2023-08-21', '2023-08-21 20:58:18', '00:28:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (147, 20, NULL, '2023-08-22 12:30:46', '2023-08-22', '2023-08-22 20:47:19', '00:17:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (148, 20, NULL, '2023-08-23 11:59:11', '2023-08-23', '2023-08-23 20:49:36', '00:19:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (149, 20, NULL, '2023-08-24 12:20:10', '2023-08-24', '2023-08-24 20:40:18', '00:10:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (150, 20, NULL, '2023-08-25 12:07:24', '2023-08-25', '2023-08-25 20:55:43', '00:25:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (151, 20, NULL, '2023-08-26 11:42:28', '2023-08-26', '2023-08-26 20:56:20', '00:26:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (152, 20, NULL, '2023-08-28 12:36:59', '2023-08-28', '2023-08-28 20:52:01', '00:22:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (153, 20, NULL, '2023-08-29 12:06:19', '2023-08-29', '2023-08-29 21:11:27', '00:41:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (154, 20, NULL, '2023-08-30 12:22:01', '2023-08-30', '2023-08-30 21:15:26', '00:45:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (155, 20, NULL, '2023-08-31 12:14:43', '2023-08-31', '2023-08-31 20:44:30', '00:14:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (156, 21, NULL, '2023-08-01 11:12:46', '2023-08-01', '2023-08-01 19:29:23', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (157, 21, NULL, '2023-08-02 10:40:58', '2023-08-02', '2023-08-02 19:31:28', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (158, 21, NULL, '2023-08-03 11:15:32', '2023-08-03', '2023-08-03 19:32:28', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (159, 21, NULL, '2023-08-04 10:55:20', '2023-08-04', '2023-08-04 19:40:05', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (160, 21, NULL, '2023-08-05 11:01:13', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (161, 21, NULL, '2023-08-07 11:14:45', '2023-08-07', '2023-08-07 19:29:02', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (162, 21, NULL, '2023-08-08 11:19:31', '2023-08-08', '2023-08-08 19:18:18', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (163, 21, NULL, '2023-08-09 10:41:49', '2023-08-09', '2023-08-09 19:33:16', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (164, 21, NULL, '2023-08-10 11:03:05', '2023-08-10', '2023-08-10 19:37:41', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (165, 21, NULL, '2023-08-11 10:52:53', '2023-08-11', '2023-08-11 19:35:45', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (166, 21, NULL, '2023-08-12 11:13:11', '2023-08-12', '2023-08-12 19:25:39', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (167, 21, NULL, '2023-08-15 11:14:28', '2023-08-15', '2023-08-15 19:45:42', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (168, 21, NULL, '2023-08-16 10:47:44', '2023-08-16', '2023-08-16 19:41:36', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (169, 21, NULL, '2023-08-17 11:09:37', '2023-08-17', '2023-08-17 19:33:09', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (170, 21, NULL, '2023-08-18 11:11:48', '2023-08-18', '2023-08-18 19:35:28', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (171, 21, NULL, '2023-08-19 11:07:09', '2023-08-19', '2023-08-19 19:14:43', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (172, 21, NULL, '2023-08-21 11:14:42', '2023-08-21', '2023-08-21 19:33:30', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (173, 21, NULL, '2023-08-22 11:17:42', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (174, 21, NULL, '2023-08-23 11:14:55', '2023-08-23', '2023-08-23 19:38:51', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (175, 21, NULL, '2023-08-24 11:11:02', '2023-08-24', '2023-08-24 19:49:07', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (176, 21, NULL, '2023-08-25 11:06:59', '2023-08-25', '2023-08-25 19:26:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (177, 21, NULL, '2023-08-26 10:56:32', '2023-08-26', '2023-08-26 19:27:01', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (178, 21, NULL, '2023-08-28 10:56:46', '2023-08-28', '2023-08-28 19:41:53', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (179, 21, NULL, '2023-08-29 11:15:09', '2023-08-29', '2023-08-29 19:46:52', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (180, 21, NULL, '2023-08-30 11:11:04', '2023-08-30', '2023-08-30 19:28:17', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (181, 21, NULL, '2023-08-31 11:29:37', '2023-08-31', '2023-08-31 19:21:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (182, 22, NULL, '2023-08-01 11:20:23', '2023-08-01', '2023-08-01 23:15:59', '02:45:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (183, 22, NULL, '2023-08-02 11:15:12', '2023-08-02', '2023-08-02 22:09:51', '01:39:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (184, 22, NULL, '2023-08-03 11:20:16', '2023-08-03', '2023-08-03 22:26:58', '01:56:58', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (185, 22, NULL, '2023-08-04 11:27:37', '2023-08-04', '2023-08-04 21:48:45', '01:18:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (186, 22, NULL, '2023-08-05 11:16:58', '2023-08-05', '2023-08-05 22:25:39', '01:55:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (187, 22, NULL, '2023-08-07 11:17:30', '2023-08-07', '2023-08-07 23:08:33', '02:38:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (188, 22, NULL, '2023-08-08 11:19:13', '2023-08-08', '2023-08-08 21:57:14', '01:27:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (189, 22, NULL, '2023-08-09 11:24:37', '2023-08-09', '2023-08-09 22:35:56', '02:05:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (190, 22, NULL, '2023-08-10 11:13:10', '2023-08-10', '2023-08-11 11:24:44', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (191, 22, NULL, '2023-08-11 11:24:49', '2023-08-11', '2023-08-11 22:23:17', '01:53:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (192, 22, NULL, '2023-08-12 11:09:59', '2023-08-12', '2023-08-12 23:30:05', '03:00:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (193, 22, NULL, '2023-08-15 11:20:11', '2023-08-15', '2023-08-15 22:23:02', '01:53:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (194, 22, NULL, '2023-08-16 11:05:23', '2023-08-16', '2023-08-16 21:07:17', '00:37:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (195, 22, NULL, '2023-08-17 11:07:17', '2023-08-17', '2023-08-17 20:33:03', '00:03:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (196, 22, NULL, '2023-08-18 11:28:36', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (197, 22, NULL, '2023-08-19 11:12:58', '2023-08-19', '2023-08-19 21:15:43', '00:45:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (198, 22, NULL, '2023-08-21 11:06:21', '2023-08-21', '2023-08-21 21:46:29', '01:16:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (199, 22, NULL, '2023-08-22 11:10:51', '2023-08-22', '2023-08-22 21:42:57', '01:12:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (200, 22, NULL, '2023-08-23 11:24:26', '2023-08-23', '2023-08-23 21:35:51', '01:05:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (201, 22, NULL, '2023-08-24 11:14:28', '2023-08-24', '2023-08-24 21:46:54', '01:16:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (202, 22, NULL, '2023-08-26 11:18:19', '2023-08-25', '2023-08-25 21:45:39', '01:15:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (203, 22, NULL, '2023-08-26 11:18:19', '2023-08-26', '2023-08-26 22:11:19', '01:41:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (204, 22, NULL, '2023-08-28 11:19:25', '2023-08-28', '2023-08-28 22:55:21', '02:25:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (205, 22, NULL, '2023-08-29 11:17:30', '2023-08-29', '2023-08-29 23:28:52', '02:58:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (206, 22, NULL, '2023-08-30 11:13:01', '2023-08-30', '2023-08-30 22:08:00', '01:38:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (207, 22, NULL, '2023-08-31 11:24:21', '2023-08-31', '2023-09-01 01:40:21', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (208, 23, NULL, '2023-08-01 10:42:13', '2023-08-01', '2023-08-01 23:15:06', '02:45:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (209, 23, NULL, '2023-08-02 10:40:46', '2023-08-02', '2023-08-02 22:14:56', '01:44:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (210, 23, NULL, '2023-08-03 10:38:16', '2023-08-03', '2023-08-03 22:26:29', '01:56:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (211, 23, NULL, '2023-08-04 10:48:52', '2023-08-04', '2023-08-04 21:50:40', '01:20:40', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (212, 23, NULL, '2023-08-05 10:45:16', '2023-08-05', '2023-08-05 22:25:06', '01:55:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (213, 23, NULL, '2023-08-07 10:41:35', '2023-08-07', '2023-08-07 23:10:44', '02:40:44', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (214, 23, NULL, '2023-08-08 10:40:19', '2023-08-08', '2023-08-08 22:25:11', '01:55:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (215, 23, NULL, '2023-08-09 10:32:59', '2023-08-09', '2023-08-09 22:36:17', '02:06:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (216, 23, NULL, '2023-08-10 10:38:39', '2023-08-10', '2023-08-10 21:58:22', '01:28:22', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (217, 23, NULL, '2023-08-11 10:41:33', '2023-08-11', '2023-08-11 22:28:08', '01:58:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (218, 23, NULL, '2023-08-12 10:45:33', '2023-08-12', '2023-08-12 23:42:08', '03:12:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (219, 23, NULL, '2023-08-15 10:45:23', '2023-08-15', '2023-08-15 22:23:36', '01:53:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (220, 23, NULL, '2023-08-16 14:59:27', '2023-08-16', '2023-08-16 22:17:10', '01:47:10', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (221, 23, NULL, '2023-08-17 10:46:14', '2023-08-17', '2023-08-17 20:39:56', '00:09:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (222, 23, NULL, '2023-08-18 10:49:00', '2023-08-18', '2023-08-18 21:32:04', '01:02:04', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (223, 23, NULL, '2023-08-19 10:35:59', '2023-08-19', '2023-08-19 21:11:20', '00:41:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (224, 23, NULL, '2023-08-21 10:40:13', '2023-08-21', '2023-08-21 21:46:53', '01:16:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (225, 23, NULL, '2023-08-22 10:38:34', '2023-08-22', '2023-08-22 20:31:32', '00:01:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (226, 23, NULL, '2023-08-23 10:49:23', '2023-08-23', '2023-08-23 21:35:59', '01:05:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (227, 23, NULL, '2023-08-24 10:49:03', '2023-08-24', '2023-08-24 21:46:09', '01:16:09', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (228, 23, NULL, '2023-08-25 10:40:37', '2023-08-25', '2023-08-25 21:45:52', '01:15:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (229, 23, NULL, '2023-08-26 10:43:59', '2023-08-26', '2023-08-26 22:10:55', '01:40:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (230, 23, NULL, '2023-08-28 11:07:44', '2023-08-28', '2023-08-28 23:01:15', '02:31:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (231, 23, NULL, '2023-08-29 10:50:21', '2023-08-29', '2023-08-29 23:29:01', '02:59:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (232, 23, NULL, '2023-08-30 10:47:38', '2023-08-30', '2023-08-30 22:08:22', '01:38:22', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (233, 23, NULL, '2023-08-31 10:43:38', '2023-08-31', '2023-08-31 19:47:58', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (234, 24, NULL, '2023-08-01 11:20:53', '2023-08-01', '2023-08-01 21:07:45', '00:37:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (235, 24, NULL, '2023-08-02 11:45:50', '2023-08-02', '2023-08-02 20:34:21', '00:04:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (236, 24, NULL, '2023-08-03 11:38:08', '2023-08-03', '2023-08-03 21:02:32', '00:32:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (237, 24, NULL, '2023-08-04 11:51:45', '2023-08-04', '2023-08-05 11:42:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (238, 24, NULL, '2023-08-05 11:30:00', '2023-08-05', '2023-08-05 21:25:04', '00:55:04', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (239, 24, NULL, '2023-08-07 11:41:29', '2023-08-07', '2023-08-07 21:11:03', '00:41:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (240, 24, NULL, '2023-08-08 11:18:22', '2023-08-08', '2023-08-08 21:00:50', '00:30:50', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (241, 24, NULL, '2023-08-09 11:49:38', '2023-08-09', '2023-08-09 21:02:17', '00:32:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (242, 24, NULL, '2023-08-10 11:45:22', '2023-08-10', '2023-08-10 21:17:29', '00:47:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (243, 24, NULL, '2023-08-11 11:30:40', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (244, 24, NULL, '2023-08-12 11:46:16', '2023-08-12', '2023-08-12 20:39:53', '00:09:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (245, 24, NULL, '2023-08-15 11:35:41', '2023-08-15', '2023-08-15 21:21:51', '00:51:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (246, 24, NULL, '2023-08-16 11:27:58', '2023-08-16', '2023-08-16 21:02:30', '00:32:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (247, 24, NULL, '2023-08-17 12:00:46', '2023-08-17', '2023-08-18 01:28:34', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (248, 24, NULL, '2023-08-18 11:24:04', '2023-08-18', '2023-08-18 01:28:34', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (249, 24, NULL, '2023-08-19 11:35:51', '2023-08-19', '2023-08-19 20:45:59', '00:15:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (250, 24, NULL, '2023-08-21 11:34:54', '2023-08-21', '2023-08-21 21:12:49', '00:42:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (251, 24, NULL, '2023-08-22 11:45:47', '2023-08-22', '2023-08-22 20:38:14', '00:08:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (252, 24, NULL, '2023-08-23 11:41:34', '2023-08-23', '2023-08-23 20:50:24', '00:20:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (253, 24, NULL, '2023-08-24 11:31:20', '2023-08-24', '2023-08-24 20:53:55', '00:23:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (254, 24, NULL, '2023-08-25 11:44:51', '2023-08-25', '2023-08-25 20:54:44', '00:24:44', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (255, 24, NULL, '2023-08-26 14:20:59', '2023-08-26', '2023-08-26 21:32:33', '01:02:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (256, 24, NULL, '2023-08-28 11:21:45', '2023-08-28', '2023-08-28 21:17:32', '00:47:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (257, 24, NULL, '2023-08-29 11:29:23', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (258, 24, NULL, '2023-08-30 11:42:41', '2023-08-30', '2023-08-30 21:04:51', '00:34:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (259, 24, NULL, '2023-08-31 11:43:26', '2023-08-31', '2023-08-31 20:50:00', '00:20:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (260, 25, NULL, '2023-08-01 11:43:05', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (261, 25, NULL, '2023-08-02 11:47:37', '2023-08-02', '2023-08-02 20:42:29', '00:12:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (262, 25, NULL, '2023-08-03 11:51:59', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (263, 25, NULL, '2023-08-04 11:46:10', '2023-08-04', '2023-08-04 20:34:13', '00:04:13', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (264, 25, NULL, '2023-08-05 12:22:51', '2023-08-05', '2023-08-05 20:19:52', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (265, 25, NULL, '2023-08-07 11:50:43', '2023-08-07', '2023-08-07 18:12:56', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (266, 25, NULL, '2023-08-08 11:51:11', '2023-08-08', '2023-08-08 20:31:07', '00:01:07', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (267, 25, NULL, '2023-08-09 12:04:16', '2023-08-09', '2023-08-09 20:21:57', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (268, 25, NULL, '2023-08-10 11:53:31', '2023-08-10', '2023-08-10 19:50:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (269, 25, NULL, '2023-08-11 11:54:54', '2023-08-11', '2023-08-11 20:40:01', '00:10:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (270, 25, NULL, '2023-08-12 12:10:14', '2023-08-12', '2023-08-12 19:34:26', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (271, 25, NULL, '2023-08-15 11:46:21', '2023-08-15', '2023-08-15 20:30:35', '00:00:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (272, 25, NULL, '2023-08-16 12:21:57', '2023-08-16', '2023-08-16 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (273, 25, NULL, '2023-08-17 11:51:39', '2023-08-17', '2023-08-17 20:50:21', '00:20:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (274, 25, NULL, '2023-08-18 12:41:04', '2023-08-18', '2023-08-18 21:03:30', '00:33:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (275, 25, NULL, '2023-08-19 11:49:32', '2023-08-19', '2023-08-19 20:35:43', '00:05:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (276, 25, NULL, '2023-08-21 11:45:57', '2023-08-21', '2023-08-21 20:29:25', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (277, 25, NULL, '2023-08-22 11:50:25', '2023-08-22', '2023-08-22 20:44:38', '00:14:38', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (278, 25, NULL, '2023-08-23 11:51:12', '2023-08-23', '2023-08-23 20:23:45', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (279, 25, NULL, '2023-08-24 11:59:18', '2023-08-24', '2023-08-24 20:48:57', '00:18:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (280, 25, NULL, '2023-08-25 12:03:22', '2023-08-25', '2023-08-25 20:37:35', '00:07:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (281, 25, NULL, '2023-08-26 13:14:38', '2023-08-26', '2023-08-26 19:37:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (282, 25, NULL, '2023-08-28 12:09:23', '2023-08-28', '2023-08-28 20:23:34', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (283, 25, NULL, '2023-08-29 11:56:29', '2023-08-29', '2023-08-29 20:42:31', '00:12:31', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (284, 25, NULL, '2023-08-30 11:54:02', '2023-08-30', '2023-08-30 20:17:47', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (285, 25, NULL, '2023-08-31 11:56:17', '2023-08-31', '2023-08-31 18:36:30', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (286, 26, NULL, '2023-08-01 12:18:15', '2023-08-01', '2023-08-01 23:14:51', '02:44:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (287, 26, NULL, '2023-08-02 12:44:29', '2023-08-02', '2023-08-02 22:10:36', '01:40:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (288, 26, NULL, '2023-08-03 12:05:13', '2023-08-03', '2023-08-03 22:26:07', '01:56:07', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (289, 26, NULL, '2023-08-04 11:51:55', '2023-08-04', '2023-08-04 21:49:13', '01:19:13', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (290, 26, NULL, '2023-08-05 12:22:57', '2023-08-05', '2023-08-05 22:25:24', '01:55:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (291, 26, NULL, '2023-08-07 12:05:48', '2023-08-07', '2023-08-07 23:12:36', '02:42:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (292, 26, NULL, '2023-08-08 11:54:14', '2023-08-08', '2023-08-08 22:25:14', '01:55:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (293, 26, NULL, '2023-08-09 13:56:05', '2023-08-09', '2023-08-09 23:04:11', '02:34:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (294, 26, NULL, '2023-08-10 12:10:19', '2023-08-10', '2023-08-10 22:00:51', '01:30:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (295, 26, NULL, '2023-08-11 11:52:46', '2023-08-11', '2023-08-11 22:23:19', '01:53:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (296, 26, NULL, '2023-08-12 14:26:11', '2023-08-12', '2023-08-12 23:42:10', '03:12:10', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (297, 26, NULL, '2023-08-15 11:58:06', '2023-08-15', '2023-08-15 22:03:07', '01:33:07', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (298, 26, NULL, '2023-08-16 11:43:15', '2023-08-16', '2023-08-16 22:17:41', '01:47:41', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (299, 26, NULL, '2023-08-17 13:15:25', '2023-08-17', '2023-08-18 11:36:57', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (300, 26, NULL, '2023-08-18 11:37:02', '2023-08-18', '2023-08-18 21:10:58', '00:40:58', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (301, 26, NULL, '2023-08-19 11:30:20', '2023-08-19', '2023-08-19 21:11:00', '00:41:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (302, 26, NULL, '2023-08-21 11:56:44', '2023-08-21', '2023-08-21 21:47:05', '01:17:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (303, 26, NULL, '2023-08-22 11:54:04', '2023-08-22', '2023-08-22 21:44:32', '01:14:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (304, 26, NULL, '2023-08-23 11:38:16', '2023-08-23', '2023-08-23 21:36:37', '01:06:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (305, 26, NULL, '2023-08-24 12:35:17', '2023-08-24', '2023-08-24 21:58:08', '01:28:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (306, 26, NULL, '2023-08-25 11:55:46', '2023-08-25', '2023-08-25 21:51:43', '01:21:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (307, 26, NULL, '2023-08-28 12:34:58', '2023-08-28', '2023-08-28 22:56:22', '02:26:22', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (308, 26, NULL, '2023-08-29 11:49:53', '2023-08-29', '2023-08-29 23:34:45', '03:04:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (309, 26, NULL, '2023-08-30 22:09:01', '2023-08-30', '2023-08-30 22:08:45', '01:38:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (310, 26, NULL, '2023-08-31 12:12:26', '2023-08-31', '2023-09-01 01:41:04', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (311, 27, NULL, '2023-08-01 11:21:59', '2023-08-01', '2023-08-01 23:25:46', '02:55:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (312, 27, NULL, '2023-08-02 11:30:47', '2023-08-02', '2023-08-02 22:17:32', '01:47:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (313, 27, NULL, '2023-08-03 11:21:04', '2023-08-03', '2023-08-03 22:56:42', '02:26:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (314, 27, NULL, '2023-08-04 11:36:26', '2023-08-04', '2023-08-04 21:52:34', '01:22:34', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (315, 27, NULL, '2023-08-05 11:09:48', '2023-08-05', '2023-08-05 23:07:03', '02:37:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (316, 27, NULL, '2023-08-07 11:32:10', '2023-08-07', '2023-08-07 23:22:05', '02:52:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (317, 27, NULL, '2023-08-08 11:26:46', '2023-08-08', '2023-08-08 22:26:35', '01:56:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (318, 27, NULL, '2023-08-09 11:38:49', '2023-08-09', '2023-08-09 23:06:18', '02:36:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (319, 27, NULL, '2023-08-10 11:27:06', '2023-08-10', '2023-08-10 22:02:15', '01:32:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (320, 27, NULL, '2023-08-11 11:35:04', '2023-08-11', '2023-08-11 22:28:15', '01:58:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (321, 27, NULL, '2023-08-12 11:31:02', '2023-08-12', '2023-08-12 23:42:17', '03:12:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (322, 27, NULL, '2023-08-15 11:28:58', '2023-08-15', '2023-08-15 22:26:12', '01:56:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (323, 27, NULL, '2023-08-16 11:26:22', '2023-08-16', '2023-08-17 11:23:25', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (324, 27, NULL, '2023-08-17 11:23:32', '2023-08-17', '2023-08-17 20:33:28', '00:03:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (325, 27, NULL, '2023-08-18 11:29:55', '2023-08-18', '2023-08-18 21:35:05', '01:05:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (326, 27, NULL, '2023-08-19 10:58:11', '2023-08-19', '2023-08-19 21:23:36', '00:53:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (327, 27, NULL, '2023-08-21 11:01:22', '2023-08-21', '2023-08-21 21:48:27', '01:18:27', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (328, 27, NULL, '2023-08-22 11:07:37', '2023-08-22', '2023-08-22 21:57:49', '01:27:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (329, 27, NULL, '2023-08-23 11:12:59', '2023-08-23', '2023-08-23 22:04:49', '01:34:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (330, 27, NULL, '2023-08-24 11:34:45', '2023-08-24', '2023-08-24 21:54:57', '01:24:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (331, 27, NULL, '2023-08-25 11:31:58', '2023-08-25', '2023-08-25 21:58:45', '01:28:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (332, 27, NULL, '2023-08-26 11:13:23', '2023-08-26', '2023-08-26 22:12:06', '01:42:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (333, 27, NULL, '2023-08-28 11:17:03', '2023-08-28', '2023-08-28 23:26:21', '02:56:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (334, 27, NULL, '2023-08-29 11:17:36', '2023-08-29', '2023-08-30 00:10:02', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (335, 27, NULL, '2023-08-30 11:18:27', '2023-08-30', '2023-08-30 22:43:51', '02:13:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (336, 27, NULL, '2023-08-31 11:07:43', '2023-08-31', '2023-09-01 01:41:50', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (337, 28, NULL, '2023-08-02 11:47:22', '2023-08-02', '2023-08-02 20:56:46', '00:26:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (338, 28, NULL, '2023-08-03 11:57:06', '2023-08-03', '2023-08-03 20:37:49', '00:07:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (339, 28, NULL, '2023-08-04 12:48:39', '2023-08-04', '2023-08-04 20:36:54', '00:06:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (340, 28, NULL, '2023-08-05 11:33:04', '2023-08-05', '2023-08-05 20:33:30', '00:03:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (341, 28, NULL, '2023-08-07 12:39:16', '2023-08-07', '2023-08-07 20:37:00', '00:07:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (342, 28, NULL, '2023-08-08 12:03:53', '2023-08-08', '2023-08-08 20:39:50', '00:09:50', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (343, 28, NULL, '2023-08-09 12:34:35', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (344, 28, NULL, '2023-08-10 11:32:02', '2023-08-10', '2023-08-10 20:34:17', '00:04:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (345, 28, NULL, '2023-08-11 12:58:34', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (346, 28, NULL, '2023-08-12 11:30:29', '2023-08-12', '2023-08-12 20:52:55', '00:22:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (347, 28, NULL, '2023-08-15 12:33:18', '2023-08-15', '2023-08-15 21:29:03', '00:59:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (348, 28, NULL, '2023-08-16 12:45:12', '2023-08-16', '2023-08-16 21:04:46', '00:34:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (349, 28, NULL, '2023-08-17 11:55:54', '2023-08-17', '2023-08-17 20:42:26', '00:12:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (350, 28, NULL, '2023-08-18 13:01:19', '2023-08-18', '2023-08-18 20:31:08', '00:01:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (351, 28, NULL, '2023-08-19 11:34:34', '2023-08-19', '2023-08-19 20:36:40', '00:06:40', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04');
INSERT INTO `attendance` (`id`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`,
                          `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (352, 28, NULL, '2023-08-21 12:48:15', '2023-08-21', '2023-08-21 20:56:24', '00:26:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (353, 28, NULL, '2023-08-22 11:49:41', '2023-08-22', '2023-08-22 20:29:51', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (354, 28, NULL, '2023-08-23 12:48:42', '2023-08-23', '2023-08-23 20:37:12', '00:07:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (355, 28, NULL, '2023-08-24 11:58:50', '2023-08-24', '2023-08-24 20:31:09', '00:01:09', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (356, 28, NULL, '2023-08-25 12:48:53', '2023-08-25', '2023-08-25 20:39:26', '00:09:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (357, 28, NULL, '2023-08-26 11:42:25', '2023-08-26', '2023-08-26 20:56:17', '00:26:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (358, 28, NULL, '2023-08-28 12:32:22', '2023-08-28', '2023-08-28 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (359, 28, NULL, '2023-08-29 11:30:00', '2023-08-29', '2023-08-29 20:32:52', '00:02:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (360, 28, NULL, '2023-08-31 11:55:57', '2023-08-30', '2023-08-30 20:30:03', '00:00:03', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (361, 28, NULL, '2023-08-31 11:55:57', '2023-08-31', '2023-08-31 19:59:59', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (362, 29, NULL, '2023-08-01 11:32:43', '2023-08-01', '2023-08-01 20:34:16', '00:04:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (363, 29, NULL, '2023-08-02 11:00:20', '2023-08-02', '2023-08-02 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (364, 29, NULL, '2023-08-03 11:05:42', '2023-08-03', '2023-08-03 20:36:25', '00:06:25', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (365, 29, NULL, '2023-08-04 11:02:17', '2023-08-04', '2023-08-04 20:50:01', '00:20:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (366, 29, NULL, '2023-08-05 11:36:14', '2023-08-05', '2023-08-05 20:55:24', '00:25:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (367, 29, NULL, '2023-08-07 11:32:03', '2023-08-07', '2023-08-07 20:32:16', '00:02:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (368, 29, NULL, '2023-08-08 11:13:40', '2023-08-08', '2023-08-08 21:06:51', '00:36:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (369, 29, NULL, '2023-08-09 11:28:01', '2023-08-09', '2023-08-09 20:36:49', '00:06:49', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (370, 29, NULL, '2023-08-10 11:40:24', '2023-08-10', '2023-08-10 19:54:58', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (371, 29, NULL, '2023-08-11 12:22:03', '2023-08-11', '2023-08-11 20:58:14', '00:28:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (372, 29, NULL, '2023-08-12 11:39:09', '2023-08-12', '2023-08-12 21:11:26', '00:41:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (373, 29, NULL, '2023-08-15 11:35:22', '2023-08-15', '2023-08-15 21:10:15', '00:40:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:04'),
       (374, 29, NULL, '2023-08-17 11:40:51', '2023-08-16', '2023-08-16 21:11:18', '00:41:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (375, 29, NULL, '2023-08-17 11:40:51', '2023-08-17', '2023-08-17 21:19:18', '00:49:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (376, 29, NULL, '2023-08-18 11:59:48', '2023-08-18', '2023-08-18 21:11:12', '00:41:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (377, 29, NULL, '2023-08-19 11:05:01', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (378, 29, NULL, '2023-08-21 11:41:06', '2023-08-21', '2023-08-21 21:15:01', '00:45:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (379, 29, NULL, '2023-08-22 11:31:08', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (380, 29, NULL, '2023-08-23 11:39:34', '2023-08-23', '2023-08-23 21:23:14', '00:53:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (381, 29, NULL, '2023-08-24 11:44:15', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (382, 29, NULL, '2023-08-25 10:57:21', '2023-08-25', '2023-08-25 20:46:54', '00:16:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (383, 29, NULL, '2023-08-26 11:28:39', '2023-08-26', '2023-08-26 21:05:36', '00:35:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (384, 29, NULL, '2023-08-28 11:44:35', '2023-08-28', '2023-08-28 21:34:51', '01:04:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (385, 29, NULL, '2023-08-29 11:41:40', '2023-08-29', '2023-08-29 21:18:24', '00:48:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (386, 29, NULL, '2023-08-30 10:59:49', '2023-08-30', '2023-08-30 20:20:20', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (387, 29, NULL, '2023-08-31 12:02:44', '2023-08-31', '2023-08-31 20:30:16', '00:00:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (388, 30, NULL, '2023-08-01 14:27:17', '2023-08-01', '2023-08-01 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (389, 30, NULL, '2023-08-02 12:22:21', '2023-08-02', '2023-08-02 20:40:05', '00:10:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (390, 30, NULL, '2023-08-03 12:26:26', '2023-08-03', '2023-08-03 20:43:22', '00:13:22', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (391, 30, NULL, '2023-08-04 12:23:41', '2023-08-04', '2023-08-04 20:51:33', '00:21:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (392, 30, NULL, '2023-08-05 12:13:48', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (393, 30, NULL, '2023-08-07 11:58:05', '2023-08-07', '2023-08-07 21:16:26', '00:46:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (394, 30, NULL, '2023-08-08 12:50:33', '2023-08-08', '2023-08-08 19:38:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (395, 30, NULL, '2023-08-09 12:25:13', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (396, 30, NULL, '2023-08-10 12:04:35', '2023-08-10', '2023-08-10 20:40:54', '00:10:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (397, 30, NULL, '2023-08-11 12:42:16', '2023-08-11', '2023-08-11 21:13:11', '00:43:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (398, 30, NULL, '2023-08-12 11:41:10', '2023-08-12', '2023-08-12 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (399, 30, NULL, '2023-08-17 12:51:29', '2023-08-17', '2023-08-17 20:40:34', '00:10:34', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (400, 30, NULL, '2023-08-18 13:52:18', '2023-08-18', '2023-08-18 20:39:55', '00:09:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (401, 30, NULL, '2023-08-19 12:02:31', '2023-08-19', '2023-08-19 20:42:28', '00:12:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (402, 30, NULL, '2023-08-21 11:28:45', '2023-08-21', '2023-08-21 21:05:37', '00:35:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (403, 30, NULL, '2023-08-22 11:48:20', '2023-08-22', '2023-08-22 21:20:29', '00:50:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (404, 30, NULL, '2023-08-23 12:41:11', '2023-08-23', '2023-08-23 21:06:04', '00:36:04', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (405, 30, NULL, '2023-08-24 11:36:23', '2023-08-24', '2023-08-24 20:59:17', '00:29:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (406, 30, NULL, '2023-08-25 11:36:50', '2023-08-25', '2023-08-25 20:06:39', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (407, 30, NULL, '2023-08-26 12:20:30', '2023-08-26', '2023-08-26 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (408, 30, NULL, '2023-08-28 11:37:56', '2023-08-28', '2023-08-28 20:25:20', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (409, 30, NULL, '2023-08-29 11:41:47', '2023-08-29', '2023-08-29 21:14:53', '00:44:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (410, 30, NULL, '2023-08-30 13:13:15', '2023-08-30', '2023-08-30 21:09:00', '00:39:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (411, 30, NULL, '2023-08-31 11:49:34', '2023-08-31', '2023-08-31 20:53:12', '00:23:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (412, 31, NULL, '2023-08-01 11:54:19', '2023-08-01', '2023-08-01 21:43:47', '01:13:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (413, 31, NULL, '2023-08-02 11:45:27', '2023-08-02', '2023-08-02 21:38:08', '01:08:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (414, 31, NULL, '2023-08-03 12:01:23', '2023-08-03', '2023-08-03 21:52:42', '01:22:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (415, 31, NULL, '2023-08-04 12:04:06', '2023-08-04', '2023-08-04 18:30:32', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (416, 31, NULL, '2023-08-05 12:14:44', '2023-08-05', '2023-08-05 21:42:47', '01:12:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (417, 31, NULL, '2023-08-07 11:37:17', '2023-08-07', '2023-08-07 21:37:50', '01:07:50', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (418, 31, NULL, '2023-08-09 11:43:29', '2023-08-09', '2023-08-09 21:42:20', '01:12:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (419, 31, NULL, '2023-08-10 11:57:14', '2023-08-10', '2023-08-10 21:57:41', '01:27:41', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (420, 31, NULL, '2023-08-11 12:16:23', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (421, 31, NULL, '2023-08-12 12:02:52', '2023-08-12', '2023-08-12 20:36:39', '00:06:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (422, 31, NULL, '2023-08-15 11:40:42', '2023-08-15', '2023-08-15 21:00:18', '00:30:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (423, 31, NULL, '2023-08-16 11:24:28', '2023-08-16', '2023-08-16 21:16:08', '00:46:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (424, 31, NULL, '2023-08-17 12:06:35', '2023-08-17', '2023-08-17 20:23:19', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (425, 31, NULL, '2023-08-18 11:44:48', '2023-08-18', '2023-08-18 22:03:05', '01:33:05', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (426, 31, NULL, '2023-08-19 12:11:46', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (427, 31, NULL, '2023-08-21 13:53:22', '2023-08-21', '2023-08-21 21:59:16', '01:29:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (428, 31, NULL, '2023-08-22 12:03:54', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (429, 31, NULL, '2023-08-23 11:57:01', '2023-08-23', '2023-08-23 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (430, 31, NULL, '2023-08-24 12:25:20', '2023-08-24', '2023-08-24 21:38:55', '01:08:55', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (431, 31, NULL, '2023-08-25 11:50:16', '2023-08-25', '2023-08-25 20:54:52', '00:24:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (432, 31, NULL, '2023-08-26 12:04:06', '2023-08-26', '2023-08-26 21:08:32', '00:38:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (433, 31, NULL, '2023-08-28 11:30:00', '2023-08-28', '2023-08-28 21:36:46', '01:06:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (434, 32, NULL, '2023-08-01 11:24:29', '2023-08-01', '2023-08-02 00:46:42', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (435, 32, NULL, '2023-08-02 12:49:45', '2023-08-02', '2023-08-03 00:19:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (436, 32, NULL, '2023-08-03 11:21:36', '2023-08-03', '2023-08-04 11:07:59', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (437, 32, NULL, '2023-08-04 11:07:54', '2023-08-04', '2023-08-05 10:58:38', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (438, 32, NULL, '2023-08-05 11:30:00', '2023-08-05', '2023-08-05 20:52:14', '00:22:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (439, 32, NULL, '2023-08-07 10:50:51', '2023-08-07', '2023-08-08 01:23:23', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (440, 32, NULL, '2023-08-08 11:25:40', '2023-08-08', '2023-08-09 00:41:06', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (441, 32, NULL, '2023-08-09 00:41:02', '2023-08-09', '2023-08-10 00:27:32', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (442, 32, NULL, '2023-08-10 10:59:29', '2023-08-10', '2023-08-11 00:23:33', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (443, 32, NULL, '2023-08-11 11:04:54', '2023-08-11', '2023-08-11 23:53:06', '03:23:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (444, 32, NULL, '2023-08-12 11:26:27', '2023-08-12', '2023-08-12 20:37:54', '00:07:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (445, 32, NULL, '2023-08-15 11:01:58', '2023-08-15', '2023-08-16 00:27:56', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (446, 32, NULL, '2023-08-16 13:15:50', '2023-08-16', '2023-08-17 00:35:34', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (447, 32, NULL, '2023-08-17 11:08:38', '2023-08-17', '2023-08-18 00:45:46', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (448, 32, NULL, '2023-08-18 11:02:05', '2023-08-18', '2023-08-19 00:22:49', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (449, 32, NULL, '2023-08-19 10:58:04', '2023-08-19', '2023-08-19 21:17:37', '00:47:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (450, 32, NULL, '2023-08-21 11:11:13', '2023-08-21', '2023-08-22 00:59:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (451, 32, NULL, '2023-08-22 10:52:22', '2023-08-22', '2023-08-23 00:26:44', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (452, 32, NULL, '2023-08-23 11:02:25', '2023-08-23', '2023-08-24 00:37:57', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (453, 32, NULL, '2023-08-24 11:04:19', '2023-08-24', '2023-08-25 00:33:01', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (454, 32, NULL, '2023-08-25 11:15:11', '2023-08-25', '2023-08-26 00:30:53', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (455, 32, NULL, '2023-08-26 10:57:12', '2023-08-26', '2023-08-26 20:45:21', '00:15:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (456, 32, NULL, '2023-08-28 11:07:35', '2023-08-28', '2023-08-29 00:40:38', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (457, 32, NULL, '2023-08-29 11:17:43', '2023-08-29', '2023-08-30 00:34:12', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (458, 32, NULL, '2023-08-30 11:14:59', '2023-08-30', '2023-08-31 00:33:41', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (459, 32, NULL, '2023-08-31 11:10:42', '2023-08-31', '2023-09-01 00:37:01', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (460, 33, NULL, '2023-08-04 11:44:29', '2023-08-04', '2023-08-04 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (461, 33, NULL, '2023-08-05 11:42:08', '2023-08-05', '2023-08-05 20:57:02', '00:27:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (462, 33, NULL, '2023-08-08 11:41:11', '2023-08-08', '2023-08-08 20:41:17', '00:11:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (463, 33, NULL, '2023-08-09 11:41:10', '2023-08-09', '2023-08-09 20:34:45', '00:04:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (464, 33, NULL, '2023-08-10 11:42:54', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (465, 33, NULL, '2023-08-11 11:51:14', '2023-08-11', '2023-08-11 20:42:44', '00:12:44', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (466, 33, NULL, '2023-08-12 11:43:22', '2023-08-12', '2023-08-12 21:26:30', '00:56:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (467, 33, NULL, '2023-08-15 11:41:59', '2023-08-15', '2023-08-15 20:31:10', '00:01:10', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (468, 33, NULL, '2023-08-16 11:38:48', '2023-08-16', '2023-08-16 20:35:48', '00:05:48', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (469, 33, NULL, '2023-08-17 13:26:02', '2023-08-17', '2023-08-17 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (470, 33, NULL, '2023-08-18 11:41:27', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (471, 33, NULL, '2023-08-19 11:39:47', '2023-08-19', '2023-08-19 20:38:35', '00:08:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (472, 33, NULL, '2023-08-21 11:44:05', '2023-08-21', '2023-08-21 20:32:47', '00:02:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (473, 33, NULL, '2023-08-22 11:43:52', '2023-08-22', '2023-08-22 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (474, 33, NULL, '2023-08-23 11:45:07', '2023-08-23', '2023-08-23 20:41:54', '00:11:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (475, 33, NULL, '2023-08-24 11:35:57', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (476, 33, NULL, '2023-08-25 11:39:05', '2023-08-25', '2023-08-25 20:34:33', '00:04:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (477, 33, NULL, '2023-08-28 11:42:12', '2023-08-28', '2023-08-28 20:35:52', '00:05:52', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (478, 33, NULL, '2023-08-29 11:43:21', '2023-08-29', '2023-08-29 20:33:36', '00:03:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (479, 33, NULL, '2023-08-30 11:41:12', '2023-08-30', '2023-08-30 20:37:57', '00:07:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (480, 33, NULL, '2023-08-31 11:41:45', '2023-08-31', '2023-08-31 20:38:11', '00:08:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (481, 34, NULL, '2023-08-02 11:31:47', '2023-08-02', '2023-08-02 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (482, 34, NULL, '2023-08-08 11:36:40', '2023-08-08', '2023-08-08 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (483, 34, NULL, '2023-08-09 11:32:10', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (484, 34, NULL, '2023-08-10 11:24:53', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (485, 34, NULL, '2023-08-15 11:27:14', '2023-08-15', '2023-08-15 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (486, 34, NULL, '2023-08-16 11:28:19', '2023-08-16', '2023-08-16 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (487, 34, NULL, '2023-08-17 11:29:05', '2023-08-17', '2023-08-17 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (488, 34, NULL, '2023-08-18 11:24:18', '2023-08-18', '2023-08-18 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (489, 34, NULL, '2023-08-19 11:22:26', '2023-08-19', '2023-08-19 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (490, 34, NULL, '2023-08-21 11:24:21', '2023-08-21', '2023-08-21 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (491, 34, NULL, '2023-08-24 11:32:52', '2023-08-24', '2023-08-24 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (492, 34, NULL, '2023-08-25 11:15:48', '2023-08-25', '2023-08-25 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (493, 34, NULL, '2023-08-26 13:50:14', '2023-08-26', '2023-08-26 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (494, 34, NULL, '2023-08-28 11:33:40', '2023-08-28', '2023-08-28 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (495, 34, NULL, '2023-08-29 11:23:50', '2023-08-29', '2023-08-29 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (496, 34, NULL, '2023-08-30 11:29:41', '2023-08-30', '2023-08-30 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (497, 34, NULL, '2023-08-31 11:42:56', '2023-08-31', '2023-08-31 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (498, 35, NULL, '2023-08-03 11:10:47', '2023-08-03', '2023-08-03 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (499, 35, NULL, '2023-08-04 11:14:55', '2023-08-04', '2023-08-04 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (500, 35, NULL, '2023-08-05 11:13:32', '2023-08-05', '2023-08-05 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (501, 35, NULL, '2023-08-07 11:16:33', '2023-08-07', '2023-08-07 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (502, 35, NULL, '2023-08-08 11:16:31', '2023-08-08', '2023-08-08 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (503, 35, NULL, '2023-08-09 11:22:13', '2023-08-09', '2023-08-09 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (504, 35, NULL, '2023-08-10 11:22:20', '2023-08-10', '2023-08-10 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (505, 35, NULL, '2023-08-11 11:21:53', '2023-08-11', '2023-08-11 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (506, 35, NULL, '2023-08-12 11:28:17', '2023-08-12', '2023-08-12 20:30:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (507, 35, NULL, '2023-08-15 11:21:49', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (508, 35, NULL, '2023-08-16 11:25:29', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (509, 35, NULL, '2023-08-17 11:22:13', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (510, 35, NULL, '2023-08-18 11:20:57', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (511, 35, NULL, '2023-08-19 11:17:05', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (512, 35, NULL, '2023-08-21 11:17:20', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (513, 35, NULL, '2023-08-22 11:22:39', '2023-08-22', '2023-08-22 22:23:20', '01:53:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (514, 35, NULL, '2023-08-23 11:15:19', '2023-08-23', '2023-08-23 22:00:39', '01:30:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (515, 35, NULL, '2023-08-24 17:13:42', '2023-08-24', '2023-08-24 20:47:38', '00:17:38', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (516, 35, NULL, '2023-08-26 11:26:36', '2023-08-25', '2023-08-25 21:01:42', '00:31:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (517, 35, NULL, '2023-08-26 11:26:36', '2023-08-26', '2023-08-26 21:27:01', '00:57:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (518, 35, NULL, '2023-08-28 11:24:06', '2023-08-28', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (519, 35, NULL, '0000-00-00 00:00:00', '2023-08-29', '2023-08-29 21:03:16', '00:33:16', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (520, 36, NULL, '2023-08-02 11:41:09', '2023-08-02', '2023-08-02 20:58:35', '00:28:35', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (521, 36, NULL, '2023-08-03 11:35:01', '2023-08-03', '2023-08-03 20:11:34', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (522, 36, NULL, '2023-08-04 11:44:20', '2023-08-04', '2023-08-04 19:23:18', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (523, 36, NULL, '2023-08-07 11:49:04', '2023-08-07', '2023-08-07 21:25:41', '00:55:41', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (524, 36, NULL, '2023-08-08 11:40:42', '2023-08-08', '2023-08-08 19:55:03', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (525, 36, NULL, '2023-08-09 11:40:07', '2023-08-09', '2023-08-09 21:42:59', '01:12:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (526, 36, NULL, '2023-08-10 11:35:19', '2023-08-10', '2023-08-10 19:18:04', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (527, 36, NULL, '2023-08-11 11:43:29', '2023-08-11', '2023-08-11 19:16:59', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (528, 36, NULL, '2023-08-12 11:43:40', '2023-08-12', '2023-08-12 22:03:12', '01:33:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (529, 36, NULL, '2023-08-15 11:45:58', '2023-08-15', '2023-08-15 19:14:23', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (530, 36, NULL, '2023-08-16 11:41:02', '2023-08-16', '2023-08-16 18:57:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (531, 36, NULL, '2023-08-17 11:38:04', '2023-08-17', '2023-08-17 19:01:12', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (532, 36, NULL, '2023-08-18 11:54:12', '2023-08-18', '2023-08-18 18:59:08', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (533, 36, NULL, '2023-08-19 11:47:08', '2023-08-19', '2023-08-19 18:59:20', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (534, 36, NULL, '2023-08-21 11:49:08', '2023-08-21', '2023-08-21 19:08:21', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (535, 37, NULL, '2023-08-01 12:08:57', '2023-08-01', '2023-08-01 20:32:39', '00:02:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (536, 37, NULL, '2023-08-02 11:59:53', '2023-08-02', '2023-08-02 20:24:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (537, 37, NULL, '2023-08-03 11:53:52', '2023-08-03', '2023-08-03 20:20:55', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (538, 37, NULL, '2023-08-04 11:59:12', '2023-08-04', '2023-08-04 20:18:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (539, 37, NULL, '2023-08-07 12:04:09', '2023-08-07', '2023-08-07 20:31:58', '00:01:58', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (540, 37, NULL, '2023-08-08 11:52:32', '2023-08-08', '2023-08-08 20:37:21', '00:07:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (541, 37, NULL, '2023-08-09 11:54:03', '2023-08-09', '2023-08-09 20:19:54', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (542, 37, NULL, '2023-08-10 13:50:30', '2023-08-10', '2023-08-10 20:17:24', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (543, 37, NULL, '2023-08-11 11:58:29', '2023-08-11', '2023-08-11 20:15:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (544, 37, NULL, '2023-08-15 12:02:41', '2023-08-15', '2023-08-15 20:29:49', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (545, 37, NULL, '2023-08-16 13:29:32', '2023-08-16', '2023-08-16 20:17:36', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (546, 37, NULL, '2023-08-17 12:02:08', '2023-08-17', '2023-08-17 20:18:49', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (547, 37, NULL, '2023-08-18 11:48:31', '2023-08-18', '2023-08-18 20:19:21', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (548, 37, NULL, '2023-08-21 11:45:40', '2023-08-21', '2023-08-21 20:19:40', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (549, 37, NULL, '2023-08-22 11:50:21', '2023-08-22', '2023-08-22 20:44:54', '00:14:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (550, 37, NULL, '2023-08-23 12:01:03', '2023-08-23', '2023-08-23 20:15:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (551, 37, NULL, '2023-08-24 12:36:51', '2023-08-24', '2023-08-24 20:19:42', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (552, 37, NULL, '2023-08-25 12:03:29', '2023-08-25', '2023-08-25 20:32:30', '00:02:30', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (553, 37, NULL, '2023-08-28 11:54:32', '2023-08-28', '2023-08-28 20:18:55', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (554, 37, NULL, '2023-08-29 12:09:04', '2023-08-29', '2023-08-29 20:20:46', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (555, 37, NULL, '2023-08-30 12:12:56', '2023-08-30', '2023-08-30 20:14:21', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (556, 37, NULL, '2023-08-31 12:16:13', '2023-08-31', '2023-08-31 20:23:35', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (557, 38, NULL, '2023-08-01 11:40:14', '2023-08-01', '2023-08-01 21:14:01', '00:44:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (558, 38, NULL, '2023-08-02 11:42:45', '2023-08-02', '2023-08-02 21:03:19', '00:33:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (559, 38, NULL, '2023-08-03 14:11:20', '2023-08-03', '2023-08-03 21:10:47', '00:40:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (560, 38, NULL, '2023-08-04 11:40:15', '2023-08-04', '2023-08-04 21:05:54', '00:35:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (561, 38, NULL, '2023-08-05 11:33:34', '2023-08-05', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (562, 38, NULL, '2023-08-07 11:43:41', '2023-08-07', '2023-08-07 21:22:18', '00:52:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (563, 38, NULL, '2023-08-08 11:51:22', '2023-08-08', '2023-08-08 21:36:41', '01:06:41', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (564, 38, NULL, '2023-08-09 11:46:14', '2023-08-09', '2023-08-09 21:29:29', '00:59:29', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (565, 38, NULL, '2023-08-10 11:46:49', '2023-08-10', '2023-08-10 21:11:51', '00:41:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (566, 38, NULL, '2023-08-11 11:49:29', '2023-08-11', '2023-08-11 21:04:53', '00:34:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (567, 38, NULL, '2023-08-12 11:44:35', '2023-08-12', '2023-08-12 22:20:42', '01:50:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (568, 38, NULL, '2023-08-15 11:41:31', '2023-08-15', '2023-08-15 21:29:36', '00:59:36', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (569, 38, NULL, '2023-08-16 12:32:55', '2023-08-16', '2023-08-16 21:15:26', '00:45:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (570, 38, NULL, '2023-08-17 11:46:33', '2023-08-17', '2023-08-17 21:12:11', '00:42:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (571, 38, NULL, '2023-08-18 11:43:57', '2023-08-18', '2023-08-18 21:12:47', '00:42:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (572, 38, NULL, '2023-08-19 11:46:42', '2023-08-19', '2023-08-19 21:29:37', '00:59:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (573, 38, NULL, '2023-08-21 11:47:37', '2023-08-21', '2023-08-21 21:15:20', '00:45:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (574, 38, NULL, '2023-08-22 12:35:46', '2023-08-22', '2023-08-22 21:31:13', '01:01:13', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (575, 38, NULL, '2023-08-23 11:44:53', '2023-08-23', '2023-08-23 21:51:04', '01:21:04', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (576, 38, NULL, '2023-08-24 11:43:31', '2023-08-24', '2023-08-24 21:00:14', '00:30:14', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (577, 38, NULL, '2023-08-25 11:45:01', '2023-08-25', '2023-08-25 21:37:39', '01:07:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (578, 38, NULL, '2023-08-26 12:20:01', '2023-08-26', '2023-08-26 21:16:33', '00:46:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (579, 38, NULL, '2023-08-28 11:44:58', '2023-08-28', '2023-08-28 21:33:17', '01:03:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (580, 38, NULL, '2023-08-29 11:44:18', '2023-08-29', '2023-08-29 21:24:44', '00:54:44', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (581, 38, NULL, '2023-08-30 11:46:31', '2023-08-30', '2023-08-30 21:29:40', '00:59:40', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (582, 38, NULL, '2023-08-31 11:46:20', '2023-08-31', '2023-08-31 22:08:34', '01:38:34', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (583, 39, NULL, '2023-08-01 11:26:10', '2023-08-01', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (584, 39, NULL, '2023-08-02 11:11:27', '2023-08-02', '2023-08-02 21:03:25', '00:33:25', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (585, 39, NULL, '2023-08-03 11:20:41', '2023-08-03', '2023-08-03 21:10:26', '00:40:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (586, 39, NULL, '2023-08-04 10:59:29', '2023-08-04', '2023-08-04 21:05:56', '00:35:56', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (587, 39, NULL, '2023-08-05 11:28:22', '2023-08-05', '2023-08-05 20:57:26', '00:27:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (588, 39, NULL, '2023-08-07 11:28:57', '2023-08-07', '2023-08-07 21:22:20', '00:52:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (589, 39, NULL, '2023-08-08 11:29:20', '2023-08-08', '2023-08-08 21:36:51', '01:06:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (590, 39, NULL, '2023-08-09 11:26:27', '2023-08-09', '2023-08-09 16:08:07', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (591, 39, NULL, '2023-08-10 11:12:33', '2023-08-10', '2023-08-10 21:11:38', '00:41:38', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (592, 39, NULL, '2023-08-11 11:23:58', '2023-08-11', '2023-08-11 18:25:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (593, 39, NULL, '2023-08-12 11:29:42', '2023-08-12', '2023-08-12 19:05:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (594, 39, NULL, '2023-08-15 11:13:42', '2023-08-15', '2023-08-15 21:29:45', '00:59:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (595, 39, NULL, '2023-08-16 11:27:22', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (596, 39, NULL, '2023-08-17 11:30:28', '2023-08-17', '2023-08-17 21:25:32', '00:55:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (597, 39, NULL, '2023-08-18 11:29:16', '2023-08-18', '2023-08-19 11:14:51', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (598, 39, NULL, '2023-08-19 11:14:54', '2023-08-19', '2023-08-19 21:48:06', '01:18:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (599, 39, NULL, '2023-08-21 11:15:49', '2023-08-21', '2023-08-21 21:15:23', '00:45:23', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (600, 39, NULL, '2023-08-22 11:34:36', '2023-08-22', '2023-08-22 21:31:17', '01:01:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (601, 39, NULL, '2023-08-23 11:02:11', '2023-08-23', '2023-08-23 13:37:07', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (602, 39, NULL, '2023-08-24 11:10:26', '2023-08-24', '2023-08-24 21:11:39', '00:41:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (603, 39, NULL, '2023-08-25 11:40:59', '2023-08-25', '2023-08-25 20:34:57', '00:04:57', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (604, 39, NULL, '2023-08-26 11:08:49', '2023-08-26', '2023-08-26 21:16:48', '00:46:48', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (605, 39, NULL, '2023-08-28 11:46:18', '2023-08-28', '2023-08-28 21:33:24', '01:03:24', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (606, 39, NULL, '2023-08-29 11:27:56', '2023-08-29', '2023-08-29 21:24:37', '00:54:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (607, 39, NULL, '2023-08-30 11:15:13', '2023-08-30', '2023-08-30 21:29:42', '00:59:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (608, 39, NULL, '2023-08-31 11:29:03', '2023-08-31', '2023-08-31 20:54:42', '00:24:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (609, 40, NULL, '2023-08-01 11:23:39', '2023-08-01', '2023-08-01 20:32:58', '00:02:58', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (610, 40, NULL, '2023-08-02 11:17:29', '2023-08-02', '2023-08-02 20:36:06', '00:06:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (611, 40, NULL, '2023-08-04 11:08:53', '2023-08-03', '2023-08-03 20:36:43', '00:06:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (612, 40, NULL, '2023-08-04 11:08:53', '2023-08-04', '2023-08-04 20:34:08', '00:04:08', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (613, 40, NULL, '0000-00-00 00:00:00', '2023-08-05', '2023-08-05 20:40:17', '00:10:17', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (614, 40, NULL, '2023-08-07 11:35:11', '2023-08-07', '2023-08-07 21:05:02', '00:35:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (615, 40, NULL, '2023-08-08 11:30:51', '2023-08-08', '2023-08-08 20:40:42', '00:10:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (616, 40, NULL, '2023-08-09 11:19:48', '2023-08-09', '2023-08-09 20:24:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (617, 40, NULL, '2023-08-10 11:33:50', '2023-08-10', '2023-08-10 20:32:59', '00:02:59', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (618, 40, NULL, '2023-08-11 11:22:47', '2023-08-11', '2023-08-11 20:31:10', '00:01:10', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (619, 40, NULL, '2023-08-12 11:16:44', '2023-08-12', '2023-08-12 20:33:21', '00:03:21', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (620, 40, NULL, '2023-08-15 11:51:45', '2023-08-15', '2023-08-15 20:51:13', '00:21:13', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (621, 40, NULL, '2023-08-16 11:35:23', '2023-08-16', '2023-08-16 20:32:33', '00:02:33', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (622, 40, NULL, '2023-08-17 11:16:41', '2023-08-17', '2023-08-17 20:33:20', '00:03:20', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (623, 40, NULL, '2023-08-18 11:38:28', '2023-08-18', '2023-08-18 20:32:42', '00:02:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (624, 40, NULL, '2023-08-19 11:52:20', '2023-08-19', '2023-08-19 20:40:32', '00:10:32', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (625, 40, NULL, '2023-08-21 11:31:24', '2023-08-21', '2023-08-21 20:22:05', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (626, 40, NULL, '2023-08-22 11:36:47', '2023-08-22', '2023-08-22 20:27:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (627, 40, NULL, '2023-08-23 11:40:47', '2023-08-23', '2023-08-23 20:22:25', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (628, 40, NULL, '2023-08-24 11:25:45', '2023-08-24', '2023-08-24 20:30:02', '00:00:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (629, 40, NULL, '2023-08-25 11:35:55', '2023-08-25', '2023-08-25 20:37:19', '00:07:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (630, 40, NULL, '2023-08-26 11:45:46', '2023-08-26', '2023-08-26 20:30:46', '00:00:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (631, 40, NULL, '2023-08-28 12:13:28', '2023-08-28', '2023-08-28 20:26:37', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (632, 40, NULL, '2023-08-29 11:36:14', '2023-08-29', '2023-08-29 20:22:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (633, 40, NULL, '2023-08-30 11:44:19', '2023-08-30', '2023-08-30 20:48:51', '00:18:51', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (634, 40, NULL, '2023-08-31 11:17:37', '2023-08-31', '2023-08-31 20:26:53', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (635, 41, NULL, '2023-08-01 12:07:18', '2023-08-01', '2023-08-01 20:36:12', '00:06:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (636, 41, NULL, '2023-08-02 11:26:37', '2023-08-02', '2023-08-02 20:41:46', '00:11:46', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (637, 41, NULL, '2023-08-03 13:36:38', '2023-08-03', '2023-08-03 20:29:22', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (638, 41, NULL, '2023-08-04 11:37:47', '2023-08-04', '2023-08-04 20:37:06', '00:07:06', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (639, 41, NULL, '2023-08-05 11:24:43', '2023-08-05', '2023-08-05 20:36:07', '00:06:07', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (640, 41, NULL, '2023-08-07 11:53:58', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (641, 41, NULL, '2023-08-08 11:24:21', '2023-08-08', '2023-08-08 20:34:53', '00:04:53', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (642, 41, NULL, '2023-08-09 11:11:50', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (643, 41, NULL, '2023-08-10 12:36:03', '2023-08-10', '2023-08-10 20:30:39', '00:00:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (644, 41, NULL, '2023-08-11 11:33:49', '2023-08-11', '2023-08-11 20:53:19', '00:23:19', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (645, 41, NULL, '0000-00-00 00:00:00', '2023-08-12', '2023-08-12 20:37:58', '00:07:58', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (646, 41, NULL, '2023-08-15 12:58:31', '2023-08-15', '2023-08-15 20:42:42', '00:12:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (647, 41, NULL, '2023-08-16 11:35:55', '2023-08-16', '2023-08-16 20:31:39', '00:01:39', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (648, 41, NULL, '2023-08-17 11:54:02', '2023-08-17', '2023-08-17 20:27:24', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (649, 41, NULL, '2023-08-18 13:15:03', '2023-08-18', '2023-08-18 20:34:42', '00:04:42', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (650, 41, NULL, '2023-08-19 11:36:06', '2023-08-19', '2023-08-19 20:31:37', '00:01:37', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (651, 41, NULL, '2023-08-22 11:28:37', '2023-08-22', '2023-08-22 20:51:01', '00:21:01', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (652, 41, NULL, '2023-08-23 11:36:14', '2023-08-23', '2023-08-23 20:32:38', '00:02:38', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (653, 41, NULL, '2023-08-24 11:36:54', '2023-08-24', '2023-08-24 20:27:42', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (654, 41, NULL, '2023-08-25 12:07:17', '2023-08-25', '2023-08-25 20:38:54', '00:08:54', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (655, 41, NULL, '2023-08-26 11:35:22', '2023-08-26', '2023-08-26 20:33:11', '00:03:11', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (656, 41, NULL, '2023-08-28 12:09:13', '2023-08-28', '2023-08-28 20:37:47', '00:07:47', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (657, 41, NULL, '2023-08-29 12:07:38', '2023-08-29', '2023-08-29 20:44:40', '00:14:40', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (658, 41, NULL, '2023-08-30 13:19:25', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (659, 42, NULL, '2023-08-01 11:55:10', '2023-08-01', '2023-08-01 20:28:25', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (660, 42, NULL, '2023-08-02 11:49:09', '2023-08-02', '2023-08-02 20:48:50', '00:18:50', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (661, 42, NULL, '2023-08-03 11:54:09', '2023-08-03', '2023-08-03 18:25:06', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (662, 42, NULL, '2023-08-04 12:11:37', '2023-08-04', '2023-08-04 20:39:45', '00:09:45', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (663, 42, NULL, '2023-08-25 12:07:36', '2023-08-25', '2023-08-25 20:37:43', '00:07:43', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (664, 42, NULL, '2023-08-26 11:59:07', '2023-08-26', '2023-08-26 20:31:28', '00:01:28', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (665, 42, NULL, '2023-08-28 11:54:04', '2023-08-28', '2023-08-28 20:38:12', '00:08:12', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (666, 42, NULL, '2023-08-29 14:48:50', '2023-08-29', '2023-08-29 20:48:15', '00:18:15', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (667, 42, NULL, '2023-08-30 11:38:15', '2023-08-30', '2023-08-30 20:47:02', '00:17:02', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (668, 42, NULL, '2023-08-31 11:55:34', '2023-08-31', '2023-08-31 20:27:12', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (669, 43, NULL, '0000-00-00 00:00:00', '2023-08-03', '2023-08-03 19:28:23', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (670, 43, NULL, '2023-08-04 12:23:13', '2023-08-04', '2023-08-04 20:19:08', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (671, 43, NULL, '2023-08-05 12:17:58', '2023-08-05', '2023-08-05 17:03:35', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (672, 43, NULL, '0000-00-00 00:00:00', '2023-08-07', '2023-08-07 19:08:14', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (673, 43, NULL, '2023-08-09 11:34:59', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (674, 43, NULL, '2023-08-10 12:07:56', '2023-08-10', '2023-08-10 19:01:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (675, 43, NULL, '2023-08-11 12:25:22', '2023-08-11', '2023-08-11 19:47:07', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (676, 43, NULL, '2023-08-12 12:23:01', '2023-08-12', '2023-08-12 18:43:32', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (677, 43, NULL, '2023-08-15 11:44:23', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (678, 43, NULL, '2023-08-16 12:21:46', '2023-08-16', '2023-08-16 19:32:44', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (679, 43, NULL, '2023-08-17 12:06:47', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (680, 43, NULL, '2023-08-18 11:33:45', '2023-08-18', '2023-08-18 19:36:15', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (681, 43, NULL, '2023-08-21 11:47:11', '2023-08-21', '2023-08-21 19:51:15', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (682, 43, NULL, '2023-08-22 12:05:34', '2023-08-22', '2023-08-22 19:28:08', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (683, 43, NULL, '2023-08-23 12:02:54', '2023-08-23', '2023-08-23 19:13:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (684, 43, NULL, '2023-08-24 11:52:27', '2023-08-24', '2023-08-24 19:17:12', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (685, 43, NULL, '2023-08-25 12:13:46', '2023-08-25', '2023-08-25 19:11:19', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (686, 43, NULL, '2023-08-26 11:29:17', '2023-08-26', '2023-08-26 19:13:36', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (687, 43, NULL, '2023-08-28 12:38:59', '2023-08-28', '2023-08-28 19:09:14', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (688, 43, NULL, '2023-08-29 12:47:32', '2023-08-29', '2023-08-29 19:25:45', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (689, 43, NULL, '2023-08-30 12:29:11', '2023-08-30', '2023-08-30 20:25:16', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (690, 43, NULL, '2023-08-31 12:26:06', '2023-08-31', '2023-08-31 20:03:09', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (691, 44, NULL, '0000-00-00 00:00:00', '2023-08-09', '2023-08-09 22:15:09', '01:45:09', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (692, 44, NULL, '2023-08-15 11:13:24', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (693, 44, NULL, '2023-08-16 11:18:31', '2023-08-16', '2023-08-16 21:15:48', '00:45:48', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (694, 45, NULL, '2023-08-01 14:25:22', '2023-08-01', '2023-08-01 22:16:26', '01:46:26', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (695, 45, NULL, '2023-08-02 13:05:46', '2023-08-02', '2023-08-02 22:36:18', '02:06:18', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (696, 45, NULL, '2023-08-03 12:51:30', '2023-08-03', '2023-08-04 00:20:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (697, 45, NULL, '2023-08-04 12:37:09', '2023-08-04', '2023-08-05 00:20:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (698, 45, NULL, '2023-08-05 14:54:27', '2023-08-05', '2023-08-05 22:21:09', '01:51:09', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (699, 45, NULL, '2023-08-07 14:28:44', '2023-08-07', '2023-08-08 00:09:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (700, 45, NULL, '2023-08-08 14:20:19', '2023-08-08', '2023-08-09 01:26:41', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05'),
       (701, 45, NULL, '2023-08-09 15:17:02', '2023-08-09', '2023-08-10 01:02:05', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:25', '2023-09-28 00:31:05');
INSERT INTO `attendance` (`id`, `Employee_Id`, `DeviceNo`, `check_in`, `check_in_date`, `check_out`, `over_time`,
                          `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (702, 45, NULL, '2023-08-11 15:46:17', '2023-08-10', '2023-08-12 01:22:45', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (703, 45, NULL, '2023-08-12 16:13:26', '2023-08-12', '2023-08-12 22:48:29', '02:18:29', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (704, 45, NULL, '2023-08-16 14:16:38', '2023-08-16', '2023-08-17 00:41:13', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (705, 45, NULL, '2023-08-17 12:32:49', '2023-08-17', '2023-08-18 00:40:15', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (706, 45, NULL, '2023-08-18 13:21:53', '2023-08-18', '2023-08-18 23:01:13', '02:31:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (707, 45, NULL, '2023-08-19 14:03:18', '2023-08-19', '2023-08-19 22:34:24', '02:04:24', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (708, 45, NULL, '2023-08-21 13:33:34', '2023-08-21', '2023-08-21 22:42:36', '02:12:36', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (709, 45, NULL, '2023-08-23 13:55:26', '2023-08-23', '2023-08-24 00:23:16', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (710, 45, NULL, '2023-08-24 14:03:58', '2023-08-24', '2023-08-25 00:24:37', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (711, 45, NULL, '2023-08-25 14:07:23', '2023-08-25', '2023-08-25 23:19:21', '02:49:21', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (712, 45, NULL, '0000-00-00 00:00:00', '2023-08-26', '2023-08-26 21:32:53', '01:02:53', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (713, 45, NULL, '0000-00-00 00:00:00', '2023-08-28', '2023-08-28 23:38:35', '03:08:35', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (714, 45, NULL, '2023-08-29 12:49:40', '2023-08-29', '2023-08-30 00:06:08', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (715, 45, NULL, '2023-08-30 14:54:41', '2023-08-30', '2023-08-30 22:59:32', '02:29:32', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (716, 45, NULL, '0000-00-00 00:00:00', '2023-08-31', '2023-09-01 00:27:41', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (717, 46, NULL, '2023-08-01 11:31:56', '2023-08-01', '2023-08-01 23:17:25', '02:47:25', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (718, 46, NULL, '2023-08-02 11:50:22', '2023-08-02', '2023-08-02 22:10:55', '01:40:55', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (719, 46, NULL, '2023-08-03 11:51:16', '2023-08-03', '2023-08-03 22:27:18', '01:57:18', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (720, 46, NULL, '2023-08-04 12:11:19', '2023-08-04', '2023-08-04 21:49:11', '01:19:11', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (721, 46, NULL, '2023-08-05 11:40:15', '2023-08-05', '2023-08-05 22:25:41', '01:55:41', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (722, 46, NULL, '2023-08-07 12:10:52', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (723, 46, NULL, '2023-08-08 11:43:25', '2023-08-08', '2023-08-08 21:55:47', '01:25:47', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (724, 46, NULL, '2023-08-09 11:31:28', '2023-08-09', '2023-08-09 22:37:03', '02:07:03', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (725, 46, NULL, '2023-08-10 11:41:06', '2023-08-10', '2023-08-10 21:53:36', '01:23:36', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (726, 46, NULL, '2023-08-11 11:30:05', '2023-08-11', '2023-08-11 22:23:26', '01:53:26', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (727, 46, NULL, '2023-08-12 11:49:24', '2023-08-12', '2023-08-12 23:30:35', '03:00:35', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (728, 46, NULL, '2023-08-15 12:59:04', '2023-08-15', '2023-08-15 22:23:22', '01:53:22', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (729, 46, NULL, '2023-08-16 16:25:40', '2023-08-16', '2023-08-16 21:08:49', '00:38:49', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (730, 46, NULL, '2023-08-17 11:41:02', '2023-08-17', '2023-08-17 20:33:13', '00:03:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (731, 46, NULL, '2023-08-18 12:02:11', '2023-08-18', '2023-08-18 21:28:59', '00:58:59', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (732, 46, NULL, '2023-08-19 11:37:18', '2023-08-19', '2023-08-19 21:16:00', '00:46:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (733, 46, NULL, '2023-08-21 11:40:17', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (734, 46, NULL, '2023-08-22 11:37:44', '2023-08-22', '2023-08-22 21:43:13', '01:13:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (735, 46, NULL, '2023-08-23 11:41:26', '2023-08-23', '2023-08-23 21:36:08', '01:06:08', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (736, 46, NULL, '2023-08-24 11:44:35', '2023-08-24', '2023-08-24 21:46:41', '01:16:41', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (737, 46, NULL, '2023-08-25 11:55:39', '2023-08-25', '2023-08-25 21:46:00', '01:16:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (738, 46, NULL, '2023-08-26 12:34:12', '2023-08-26', '2023-08-26 22:11:04', '01:41:04', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (739, 46, NULL, '2023-08-28 12:18:38', '2023-08-28', '2023-08-28 22:56:38', '02:26:38', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (740, 46, NULL, '2023-08-29 12:02:16', '2023-08-29', '2023-08-29 23:29:10', '02:59:10', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (741, 46, NULL, '2023-08-30 12:12:03', '2023-08-30', '2023-08-30 22:08:37', '01:38:37', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (742, 46, NULL, '2023-08-31 11:35:02', '2023-08-31', '2023-09-01 01:40:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (743, 47, NULL, '2023-08-01 12:06:24', '2023-08-01', '2023-08-02 01:37:16', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (744, 47, NULL, '2023-08-02 11:04:05', '2023-08-02', '2023-08-02 19:56:11', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (745, 47, NULL, '2023-08-03 12:13:55', '2023-08-03', '2023-08-03 20:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (746, 47, NULL, '2023-08-04 11:31:40', '2023-08-04', '2023-08-04 20:01:35', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (747, 47, NULL, '2023-08-05 11:29:57', '2023-08-05', '2023-08-05 23:09:03', '02:39:03', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (748, 47, NULL, '2023-08-07 11:26:58', '2023-08-07', '2023-08-07 19:58:39', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (749, 47, NULL, '2023-08-08 12:00:50', '2023-08-08', '2023-08-08 20:01:49', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (750, 47, NULL, '2023-08-09 11:51:09', '2023-08-09', '2023-08-09 20:00:31', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (751, 47, NULL, '2023-08-10 11:26:52', '2023-08-10', '2023-08-10 20:02:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (752, 47, NULL, '2023-08-11 11:32:04', '2023-08-11', '2023-08-11 20:15:52', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (753, 47, NULL, '2023-08-12 11:27:17', '2023-08-12', '2023-08-12 21:52:28', '01:22:28', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (754, 47, NULL, '2023-08-15 11:53:40', '2023-08-15', '2023-08-15 20:10:43', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (755, 47, NULL, '2023-08-16 11:45:46', '2023-08-16', '2023-08-16 20:02:24', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (756, 47, NULL, '2023-08-17 11:29:54', '2023-08-17', '2023-08-17 19:33:12', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (757, 47, NULL, '2023-08-18 11:35:43', '2023-08-18', '2023-08-18 20:11:45', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (758, 47, NULL, '2023-08-19 12:27:51', '2023-08-19', '2023-08-19 20:11:51', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (759, 47, NULL, '2023-08-21 11:54:31', '2023-08-21', '2023-08-21 20:06:42', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (760, 47, NULL, '2023-08-22 11:50:43', '2023-08-22', '2023-08-22 20:10:32', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (761, 47, NULL, '2023-08-23 11:42:50', '2023-08-23', '2023-08-23 20:01:59', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (762, 47, NULL, '2023-08-24 11:43:16', '2023-08-24', '2023-08-24 20:04:37', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (763, 47, NULL, '2023-08-25 11:59:35', '2023-08-25', '2023-08-25 20:08:03', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (764, 47, NULL, '2023-08-26 11:55:19', '2023-08-26', '2023-08-26 20:04:30', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (765, 47, NULL, '2023-08-28 11:44:13', '2023-08-28', '2023-08-28 20:02:27', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (766, 47, NULL, '2023-08-29 12:06:12', '2023-08-29', '2023-08-29 20:00:29', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (767, 47, NULL, '2023-08-30 11:36:04', '2023-08-30', '2023-08-30 21:03:14', '00:33:14', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (768, 47, NULL, '2023-08-31 11:47:49', '2023-08-31', '2023-08-31 20:11:15', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:05'),
       (769, 51, NULL, '2023-08-01 11:25:01', '2023-08-01', '2023-08-01 23:08:52', '02:38:52', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (770, 51, NULL, '2023-08-02 11:52:48', '2023-08-02', '2023-08-02 22:14:10', '01:44:10', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (771, 51, NULL, '2023-08-03 11:22:10', '2023-08-03', '2023-08-03 22:25:43', '01:55:43', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (772, 51, NULL, '2023-08-04 11:53:08', '2023-08-04', '2023-08-04 21:11:05', '00:41:05', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (773, 51, NULL, '2023-08-05 11:38:09', '2023-08-05', '2023-08-05 22:28:39', '01:58:39', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (774, 51, NULL, '2023-08-07 11:31:21', '2023-08-07', '2023-08-07 23:10:30', '02:40:30', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (775, 51, NULL, '2023-08-08 11:31:01', '2023-08-08', '2023-08-08 21:41:37', '01:11:37', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (776, 51, NULL, '2023-08-09 11:41:16', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (777, 51, NULL, '2023-08-10 11:41:15', '2023-08-10', '2023-08-10 21:59:13', '01:29:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (778, 51, NULL, '2023-08-11 11:42:30', '2023-08-11', '2023-08-11 22:04:32', '01:34:32', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (779, 51, NULL, '2023-08-12 11:32:03', '2023-08-12', '2023-08-12 23:30:49', '03:00:49', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (780, 51, NULL, '2023-08-15 11:23:10', '2023-08-15', '2023-08-15 21:52:55', '01:22:55', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (781, 51, NULL, '2023-08-16 11:36:55', '2023-08-16', '2023-08-16 20:59:25', '00:29:25', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (782, 51, NULL, '2023-08-17 11:36:12', '2023-08-17', '2023-08-18 11:26:55', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (783, 51, NULL, '2023-08-18 11:27:01', '2023-08-18', '2023-08-18 22:17:36', '01:47:36', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (784, 51, NULL, '2023-08-19 11:20:45', '2023-08-19', '2023-08-19 21:16:29', '00:46:29', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (785, 51, NULL, '2023-08-21 11:32:03', '2023-08-21', '2023-08-21 21:32:12', '01:02:12', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (786, 51, NULL, '2023-08-22 11:55:36', '2023-08-22', '2023-08-22 21:54:46', '01:24:46', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (787, 51, NULL, '0000-00-00 00:00:00', '2023-08-23', '2023-08-23 21:38:56', '01:08:56', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (788, 51, NULL, '2023-08-24 12:01:31', '2023-08-24', '2023-08-24 21:46:45', '01:16:45', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (789, 51, NULL, '2023-08-25 11:48:24', '2023-08-25', '2023-08-25 21:44:53', '01:14:53', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (790, 51, NULL, '2023-08-26 11:34:36', '2023-08-26', '2023-08-26 22:11:21', '01:41:21', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (791, 51, NULL, '2023-08-28 11:37:11', '2023-08-28', '2023-08-28 22:52:04', '02:22:04', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (792, 51, NULL, '2023-08-29 11:31:21', '2023-08-29', '2023-08-29 23:34:12', '03:04:12', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (793, 51, NULL, '2023-08-30 11:50:56', '2023-08-30', '2023-08-30 22:04:20', '01:34:20', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (794, 51, NULL, '2023-08-31 10:31:29', '2023-08-31', '2023-09-01 01:40:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (795, 61, NULL, '2023-08-01 11:21:40', '2023-08-01', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (796, 61, NULL, '2023-08-03 11:15:59', '2023-08-03', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (797, 61, NULL, '2023-08-04 11:26:50', '2023-08-04', '2023-08-04 20:44:27', '00:14:27', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (798, 61, NULL, '2023-08-05 11:19:33', '2023-08-05', '2023-08-05 20:44:53', '00:14:53', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (799, 61, NULL, '2023-08-07 11:21:09', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (800, 61, NULL, '0000-00-00 00:00:00', '2023-08-08', '2023-08-08 20:44:21', '00:14:21', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (801, 61, NULL, '2023-08-10 11:29:05', '2023-08-10', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (802, 61, NULL, '2023-08-11 11:29:07', '2023-08-11', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (803, 61, NULL, '2023-08-12 11:19:53', '2023-08-12', '2023-08-12 21:11:10', '00:41:10', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (804, 61, NULL, '2023-08-15 11:42:36', '2023-08-15', '2023-08-15 20:58:58', '00:28:58', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (805, 61, NULL, '2023-08-16 11:30:17', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (806, 61, NULL, '2023-08-17 11:18:22', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (807, 61, NULL, '2023-08-18 11:35:28', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (808, 61, NULL, '2023-08-19 11:31:46', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (809, 61, NULL, '2023-08-21 11:39:41', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (810, 61, NULL, '2023-08-22 11:22:09', '2023-08-22', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (811, 61, NULL, '2023-08-23 11:19:24', '2023-08-23', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (812, 61, NULL, '2023-08-24 11:21:29', '2023-08-24', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (813, 61, NULL, '2023-08-25 11:34:18', '2023-08-25', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (814, 61, NULL, '2023-08-26 12:21:05', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (815, 61, NULL, '2023-08-28 11:26:34', '2023-08-28', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (816, 61, NULL, '2023-08-29 11:31:08', '2023-08-29', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (817, 61, NULL, '2023-08-30 11:21:31', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (818, 61, NULL, '2023-08-31 11:27:28', '2023-08-31', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (819, 63, NULL, '2023-08-01 11:22:18', '2023-08-01', '2023-08-01 23:07:46', '02:37:46', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (820, 63, NULL, '2023-08-02 11:26:12', '2023-08-02', '2023-08-02 22:14:44', '01:44:44', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (821, 63, NULL, '2023-08-03 11:16:09', '2023-08-03', '2023-08-03 22:45:12', '02:15:12', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (822, 63, NULL, '2023-08-04 11:15:25', '2023-08-04', '2023-08-04 21:34:31', '01:04:31', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (823, 63, NULL, '2023-08-05 11:26:48', '2023-08-05', '2023-08-05 22:25:16', '01:55:16', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (824, 63, NULL, '2023-08-07 11:24:30', '2023-08-07', '2023-08-07 23:10:32', '02:40:32', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (825, 63, NULL, '2023-08-08 11:31:51', '2023-08-08', '2023-08-08 21:48:14', '01:18:14', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (826, 63, NULL, '2023-08-09 11:27:28', '2023-08-09', '2023-08-09 22:24:34', '01:54:34', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (827, 63, NULL, '2023-08-10 11:34:42', '2023-08-10', '2023-08-10 21:41:00', '01:11:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (828, 63, NULL, '2023-08-11 11:38:42', '2023-08-11', '2023-08-11 22:06:39', '01:36:39', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (829, 63, NULL, '2023-08-12 11:30:51', '2023-08-12', '2023-08-12 23:29:48', '02:59:48', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (830, 63, NULL, '2023-08-15 11:28:34', '2023-08-15', '2023-08-15 21:50:02', '01:20:02', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (831, 63, NULL, '2023-08-16 11:35:01', '2023-08-16', '2023-08-16 21:05:15', '00:35:15', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (832, 63, NULL, '2023-08-17 11:35:31', '2023-08-17', '2023-08-17 20:20:39', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (833, 63, NULL, '2023-08-18 11:27:59', '2023-08-18', '2023-08-18 21:18:54', '00:48:54', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (834, 63, NULL, '2023-08-19 11:28:28', '2023-08-19', '2023-08-19 20:58:33', '00:28:33', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (835, 63, NULL, '2023-08-21 11:18:16', '2023-08-21', '2023-08-21 21:33:34', '01:03:34', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (836, 63, NULL, '2023-08-22 11:30:30', '2023-08-22', '2023-08-22 21:42:35', '01:12:35', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (837, 63, NULL, '2023-08-23 11:26:47', '2023-08-23', '2023-08-23 21:41:00', '01:11:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (838, 63, NULL, '2023-08-24 11:26:03', '2023-08-24', '2023-08-24 21:46:23', '01:16:23', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (839, 63, NULL, '2023-08-25 11:50:36', '2023-08-25', '2023-08-25 21:17:37', '00:47:37', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (840, 63, NULL, '2023-08-26 11:33:05', '2023-08-26', '2023-08-26 22:08:22', '01:38:22', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (841, 63, NULL, '2023-08-28 11:36:59', '2023-08-28', '2023-08-28 23:06:28', '02:36:28', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (842, 63, NULL, '2023-08-29 11:45:51', '2023-08-29', '2023-08-29 23:34:14', '03:04:14', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (843, 63, NULL, '2023-08-30 11:59:38', '2023-08-30', '2023-08-30 22:03:58', '01:33:58', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (844, 63, NULL, '2023-08-31 11:33:29', '2023-08-31', '2023-09-01 01:40:03', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (845, 70, NULL, '2023-08-01 12:36:50', '2023-08-01', '2023-08-01 21:33:00', '01:03:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (846, 70, NULL, '2023-08-02 11:40:33', '2023-08-02', '2023-08-02 21:38:02', '01:08:02', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (847, 70, NULL, '2023-08-03 11:54:21', '2023-08-03', '2023-08-03 21:54:17', '01:24:17', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (848, 70, NULL, '2023-08-04 12:13:02', '2023-08-04', '2023-08-04 21:37:21', '01:07:21', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (849, 70, NULL, '2023-08-05 11:41:48', '2023-08-05', '2023-08-05 22:11:07', '01:41:07', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (850, 70, NULL, '2023-08-07 11:55:39', '2023-08-07', '2023-08-07 21:46:07', '01:16:07', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (851, 70, NULL, '2023-08-08 11:38:16', '2023-08-08', '2023-08-08 21:40:48', '01:10:48', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (852, 70, NULL, '2023-08-09 12:00:29', '2023-08-09', '2023-08-09 21:32:13', '01:02:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (853, 70, NULL, '2023-08-10 11:45:39', '2023-08-10', '2023-08-10 21:29:36', '00:59:36', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (854, 70, NULL, '2023-08-11 11:51:41', '2023-08-11', '2023-08-11 21:18:12', '00:48:12', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (855, 70, NULL, '2023-08-12 11:36:45', '2023-08-12', '2023-08-12 22:20:26', '01:50:26', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (856, 70, NULL, '2023-08-15 11:42:03', '2023-08-15', '2023-08-15 21:29:21', '00:59:21', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (857, 70, NULL, '2023-08-16 11:37:14', '2023-08-16', '2023-08-16 21:15:41', '00:45:41', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (858, 70, NULL, '2023-08-17 11:27:32', '2023-08-17', '2023-08-17 21:25:26', '00:55:26', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (859, 70, NULL, '2023-08-18 11:35:36', '2023-08-18', '2023-08-18 21:16:34', '00:46:34', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (860, 70, NULL, '2023-08-19 11:30:34', '2023-08-19', '2023-08-19 21:30:00', '01:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (861, 70, NULL, '2023-08-21 12:04:44', '2023-08-21', '2023-08-21 21:54:00', '01:24:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (862, 70, NULL, '2023-08-22 10:38:24', '2023-08-22', '2023-08-22 21:40:59', '01:10:59', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (863, 70, NULL, '2023-08-23 15:13:37', '2023-08-23', '2023-08-23 21:52:59', '01:22:59', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (864, 70, NULL, '2023-08-24 12:09:04', '2023-08-24', '2023-08-24 21:38:03', '01:08:03', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (865, 70, NULL, '2023-08-25 11:46:05', '2023-08-25', '2023-08-25 21:40:05', '01:10:05', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (866, 70, NULL, '2023-08-26 11:14:42', '2023-08-26', '2023-08-26 21:33:25', '01:03:25', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (867, 70, NULL, '2023-08-28 11:43:58', '2023-08-28', '2023-08-28 21:41:09', '01:11:09', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (868, 70, NULL, '2023-08-29 11:49:17', '2023-08-29', '2023-08-29 21:20:40', '00:50:40', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (869, 70, NULL, '2023-08-30 11:51:58', '2023-08-30', '2023-08-30 15:33:10', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (870, 70, NULL, '2023-08-31 11:59:08', '2023-08-31', '2023-08-31 21:33:44', '01:03:44', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (871, 71, NULL, '2023-08-01 11:38:05', '2023-08-01', '2023-08-01 21:07:39', '00:37:39', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (872, 71, NULL, '2023-08-02 11:39:58', '2023-08-02', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (873, 71, NULL, '2023-08-03 11:39:43', '2023-08-03', '2023-08-03 20:31:25', '00:01:25', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (874, 71, NULL, '2023-08-04 11:43:45', '2023-08-04', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (875, 71, NULL, '2023-08-05 11:35:51', '2023-08-05', '2023-08-05 20:20:22', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (876, 71, NULL, '2023-08-07 11:44:01', '2023-08-07', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (877, 71, NULL, '2023-08-08 11:42:03', '2023-08-08', '2023-08-08 20:38:11', '00:08:11', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (878, 71, NULL, '2023-08-09 11:41:55', '2023-08-09', '2023-08-09 20:34:06', '00:04:06', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (879, 71, NULL, '2023-08-10 11:43:33', '2023-08-10', '2023-08-10 19:50:15', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (880, 71, NULL, '2023-08-12 11:44:03', '2023-08-12', '2023-08-12 21:26:23', '00:56:23', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (881, 71, NULL, '2023-08-15 11:40:51', '2023-08-15', '2023-08-15 20:30:56', '00:00:56', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (882, 71, NULL, '2023-08-16 11:37:51', '2023-08-16', '2023-08-16 20:33:20', '00:03:20', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (883, 71, NULL, '2023-08-17 13:24:49', '2023-08-17', '2023-08-17 20:30:30', '00:00:30', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (884, 71, NULL, '2023-08-18 11:40:35', '2023-08-18', '2023-08-18 20:34:11', '00:04:11', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (885, 71, NULL, '2023-08-19 11:38:34', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (886, 71, NULL, '2023-08-21 11:43:03', '2023-08-21', '2023-08-21 20:32:13', '00:02:13', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (887, 71, NULL, '2023-08-22 11:44:30', '2023-08-22', '2023-08-22 20:31:48', '00:01:48', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (888, 71, NULL, '2023-08-23 11:45:38', '2023-08-23', '2023-08-23 20:38:55', '00:08:55', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (889, 71, NULL, '2023-08-24 11:36:37', '2023-08-24', '2023-08-24 20:45:59', '00:15:59', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (890, 71, NULL, '2023-08-25 11:39:55', '2023-08-25', '2023-08-25 20:34:26', '00:04:26', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (891, 71, NULL, '2023-08-26 11:39:42', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (892, 71, NULL, '2023-08-28 11:42:58', '2023-08-28', '2023-08-28 20:30:54', '00:00:54', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (893, 71, NULL, '2023-08-29 11:42:15', '2023-08-29', '2023-08-29 20:30:58', '00:00:58', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (894, 71, NULL, '2023-08-30 11:40:08', '2023-08-30', '2023-08-30 20:34:24', '00:04:24', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (895, 71, NULL, '2023-08-31 11:40:06', '2023-08-31', '2023-08-31 20:38:14', '00:08:14', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (896, 75, NULL, '2023-08-04 11:35:52', '2023-08-04', '2023-08-04 20:52:08', '00:22:08', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (897, 75, NULL, '2023-08-05 11:57:45', '2023-08-05', '2023-08-05 20:48:04', '00:18:04', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (898, 75, NULL, '2023-08-07 12:13:17', '2023-08-07', '2023-08-07 21:16:49', '00:46:49', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (899, 75, NULL, '2023-08-08 12:06:04', '2023-08-08', '2023-08-08 21:57:17', '01:27:17', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (900, 75, NULL, '2023-08-09 11:51:43', '2023-08-09', '2023-08-09 20:48:10', '00:18:10', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (901, 75, NULL, '2023-08-10 12:35:31', '2023-08-10', '2023-08-10 21:58:03', '01:28:03', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (902, 75, NULL, '2023-08-11 13:03:30', '2023-08-11', '2023-08-11 20:48:56', '00:18:56', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (903, 75, NULL, '2023-08-12 11:59:03', '2023-08-12', '2023-08-12 21:05:18', '00:35:18', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (904, 75, NULL, '2023-08-16 11:50:19', '2023-08-15', '2023-08-15 21:22:49', '00:52:49', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (905, 75, NULL, '2023-08-16 11:50:19', '2023-08-16', '2023-08-16 21:16:55', '00:46:55', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (906, 75, NULL, '2023-08-17 12:07:15', '2023-08-17', '2023-08-17 21:34:19', '01:04:19', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (907, 75, NULL, '2023-08-18 11:54:44', '2023-08-18', '2023-08-18 21:07:33', '00:37:33', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (908, 75, NULL, '2023-08-19 11:46:36', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (909, 75, NULL, '2023-08-21 12:17:44', '2023-08-21', '2023-08-21 22:25:10', '01:55:10', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (910, 75, NULL, '2023-08-22 11:52:18', '2023-08-22', '2023-08-22 21:19:25', '00:49:25', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (911, 75, NULL, '0000-00-00 00:00:00', '2023-08-23', '2023-08-23 21:51:51', '01:21:51', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (912, 75, NULL, '2023-08-24 12:25:09', '2023-08-24', '2023-08-24 21:03:09', '00:33:09', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (913, 75, NULL, '2023-08-25 12:02:06', '2023-08-25', '2023-08-25 21:25:04', '00:55:04', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (914, 75, NULL, '2023-08-26 18:21:36', '2023-08-26', '2023-08-26 20:53:00', '00:23:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (915, 75, NULL, '2023-08-28 12:01:08', '2023-08-28', '2023-08-28 21:28:22', '00:58:22', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (916, 75, NULL, '2023-08-29 12:11:06', '2023-08-29', '2023-08-29 21:19:16', '00:49:16', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (917, 75, NULL, '2023-08-30 11:51:03', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (918, 75, NULL, '2023-08-31 12:10:32', '2023-08-31', '2023-08-31 21:47:58', '01:17:58', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (919, 76, NULL, '2023-08-09 11:52:54', '2023-08-08', '2023-08-08 20:31:33', '00:01:33', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (920, 76, NULL, '2023-08-09 11:52:54', '2023-08-09', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (921, 76, NULL, '2023-08-10 11:48:47', '2023-08-10', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (922, 76, NULL, '2023-08-11 12:24:36', '2023-08-11', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (923, 76, NULL, '2023-08-12 12:01:16', '2023-08-12', '2023-08-12 21:15:19', '00:45:19', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (924, 76, NULL, '2023-08-15 12:21:02', '2023-08-15', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (925, 76, NULL, '2023-08-16 12:25:03', '2023-08-16', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (926, 76, NULL, '2023-08-17 12:15:44', '2023-08-17', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (927, 76, NULL, '2023-08-18 12:02:23', '2023-08-18', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (928, 76, NULL, '2023-08-19 11:59:03', '2023-08-19', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (929, 76, NULL, '2023-08-21 12:04:38', '2023-08-21', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (930, 76, NULL, '2023-08-22 12:12:07', '2023-08-22', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (931, 76, NULL, '2023-08-23 12:24:36', '2023-08-23', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (932, 76, NULL, '2023-08-24 11:56:55', '2023-08-24', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (933, 76, NULL, '2023-08-25 12:30:00', '2023-08-25', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (934, 76, NULL, '2023-08-26 12:00:56', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (935, 76, NULL, '2023-08-29 12:05:50', '2023-08-29', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (936, 76, NULL, '2023-08-30 12:09:35', '2023-08-30', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (937, 76, NULL, '2023-08-31 12:03:44', '2023-08-31', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (938, 78, NULL, '0000-00-00 00:00:00', '2023-08-19', '2023-08-19 20:45:38', '00:15:38', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (939, 78, NULL, '2023-08-21 12:09:34', '2023-08-21', '2023-08-21 20:55:54', '00:25:54', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (940, 78, NULL, '2023-08-22 12:28:12', '2023-08-22', '2023-08-22 20:45:16', '00:15:16', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (941, 78, NULL, '2023-08-23 10:50:32', '2023-08-23', '2023-08-23 20:23:53', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (942, 78, NULL, '2023-08-24 11:48:29', '2023-08-24', '2023-08-24 20:39:36', '00:09:36', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (943, 78, NULL, '2023-08-25 12:01:09', '2023-08-25', '2023-08-25 20:37:22', '00:07:22', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (944, 78, NULL, '2023-08-26 12:29:31', '2023-08-26', '0000-00-00 00:00:00', '00:00:00', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (945, 78, NULL, '2023-08-28 12:15:29', '2023-08-28', '2023-08-28 20:34:04', '00:04:04', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (946, 78, NULL, '2023-08-29 12:37:38', '2023-08-29', '2023-08-29 20:47:28', '00:17:28', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (947, 78, NULL, '2023-08-30 12:21:30', '2023-08-30', '2023-08-30 20:38:27', '00:08:27', 1, 1, 1,
        '2023-09-26 19:52:26', '2023-09-28 00:31:06'),
       (948, 78, NULL, '2023-08-31 12:28:38', '2023-08-31', NULL, '00:00:00', 1, 1, 1, '2023-09-26 19:52:26',
        '2023-09-28 02:40:22');

-- --------------------------------------------------------

--
-- Table structure for table `designation`
--

CREATE TABLE `designation`
(
    `id`            int(10)     NOT NULL,
    `designation_name` varchar(50) NOT NULL,
    `isactive`         tinyint(1) DEFAULT 1,
    `created_by`       int(10)     NOT NULL,
    `updated_by`       int(10)    DEFAULT NULL,
    `created_on`       datetime    NOT NULL,
    `updated_on`       datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `designation`
--

INSERT INTO `designation` (`id`, `designation_name`, `isactive`, `created_by`, `updated_by`, `created_on`,
                           `updated_on`)
VALUES (1, 'Inovi Technology', 1, 1, 1, '2023-08-31 10:51:56', '2023-10-02 20:44:21'),
       (2, 'Inovi Solution', 1, 1, 1, '2023-09-06 22:03:39', '2023-09-26 19:27:21'),
       (4, 'Telecom', 0, 1, 1, '2023-09-28 00:10:55', '2023-09-28 00:11:15'),
       (5, 'Inovi Telecoms', 0, 1, 1, '2023-09-28 02:41:12', '2023-09-28 02:41:20');

-- --------------------------------------------------------

--
-- Table structure for table `devicetable`
--

CREATE TABLE `devicetable`
(
    `Device_Id`         int(11)     NOT NULL,
    `Device_Name`       varchar(50) NOT NULL,
    `Connection_Type`   varchar(50) NOT NULL,
    `Network_Parameter` varchar(50) NOT NULL,
    `Serial_No`         varchar(50) NOT NULL,
    `IP_Address`        varchar(50) NOT NULL,
    `Port_No`           varchar(50) NOT NULL,
    `Connected_Table`   varchar(50) NOT NULL,
    `Status`            tinyint(1)  NOT NULL DEFAULT 1,
    `created_by`        int(11)     NOT NULL,
    `updated_by`        int(11)     NOT NULL,
    `created_on`        datetime    NOT NULL,
    `updated_on`        datetime    NOT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `devicetable`
--

INSERT INTO `devicetable` (`Device_Id`, `Device_Name`, `Connection_Type`, `Network_Parameter`, `Serial_No`,
                           `IP_Address`, `Port_No`, `Connected_Table`, `Status`, `created_by`, `updated_by`,
                           `created_on`, `updated_on`)
VALUES (1, 'IVMS-4200', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 'XYZ', 1, 1, 1, '2023-08-09 00:00:00',
        '2023-08-09 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `holidays`
--

CREATE TABLE `holidays`
(
    `id`        int(10)     NOT NULL,
    `Title`        varchar(50) NOT NULL,
    `Holiday_Date` date        NOT NULL,
    `isactive`     tinyint(1)  NOT NULL DEFAULT 1,
    `created_by`   int(11)     NOT NULL,
    `updated_by`   int(11)              DEFAULT NULL,
    `created_on`   datetime    NOT NULL,
    `updated_on`   datetime             DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `holidays`
--

INSERT INTO `holidays` (`id`, `Title`, `Holiday_Date`, `isactive`, `created_by`, `updated_by`, `created_on`,
                        `updated_on`)
VALUES (1, 'Saturday', '2023-09-15', 1, 1, 1, '2023-09-26 21:14:19', '2023-10-02 20:42:04'),
       (2, 'Sunday', '2023-09-20', 1, 1, 1, '2023-09-26 21:14:20', '2023-09-28 00:25:38'),
       (3, 'Monday', '2023-01-10', 1, 1, 1, '2023-09-26 21:14:20', '2023-09-28 00:25:38'),
       (4, 'a', '2023-09-01', 1, 1, NULL, '2023-09-26 21:27:35', NULL),
       (5, 'b', '2023-09-02', 1, 1, NULL, '2023-09-26 21:27:42', NULL),
       (6, 'c', '2023-09-03', 1, 1, NULL, '2023-09-26 21:27:49', NULL),
       (7, 'd', '2023-09-04', 1, 1, NULL, '2023-09-26 21:27:57', NULL),
       (8, 'e', '2023-09-05', 1, 1, NULL, '2023-09-26 21:28:04', NULL),
       (9, 'f', '2023-09-06', 1, 1, NULL, '2023-09-26 21:28:13', NULL),
       (10, 'g', '2023-09-07', 1, 1, 1, '2023-09-26 21:28:25', '2023-09-26 21:28:46'),
       (11, 'hh', '2023-09-08', 1, 1, 1, '2023-09-26 21:28:57', '2023-10-02 20:42:24'),
       (12, 'i', '2023-09-28', 1, 1, NULL, '2023-09-28 01:06:56', NULL),
       (13, 'test 02', '2023-10-18', 1, 1, 1, '2023-10-02 20:43:42', '2023-10-02 20:44:00');

-- --------------------------------------------------------

--
-- Table structure for table `logs`
--

CREATE TABLE `logs`
(
    `id`           int(11)  NOT NULL,
    `Log_Description` text       DEFAULT NULL,
    `TBL_Name`        text     NOT NULL,
    `isactive`        tinyint(1) DEFAULT 1,
    `created_by`      int(11)  NOT NULL,
    `created_on`      datetime NOT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `logs`
--

INSERT INTO `logs` (`id`, `Log_Description`, `TBL_Name`, `isactive`, `created_by`, `created_on`)
VALUES (1, '', 'UserProfile', 1, 1, '2023-09-26 22:43:11'),
       (2, 'Admin (1) has changed attendance record 2023-08-01 of check_out to 2023-08-01 21:30:00', 'Attendance', 1, 1,
        '2023-09-26 23:16:38'),
       (3, 'Admin (1) has changed attendance record 2023-08-01 of check_in to 2023-08-01 11:30:01', 'Attendance', 1, 1,
        '2023-09-26 23:18:24'),
       (4, 'Admin (1) has changed attendance record 2023-08-01 of check_out to 2023-08-01 22:30:00', 'Attendance', 1, 1,
        '2023-09-26 23:18:24'),
       (5, 'Admin (1) has changed attendance record 2023-08-01 11:30:01 of check_in to 2023-08-01 11:20:01',
        'Attendance', 1, 1, '2023-09-26 23:21:10'),
       (6, 'Admin (1) has changed attendance record 2023-08-01 11:30:01 of check_out to 2023-08-01 11:30:00',
        'Attendance', 1, 1, '2023-09-26 23:21:10'),
       (7, 'Admin (1)And has changed attendance record 2023-08-01 11:20:01 of check_out to 2023-08-01 22:30:00',
        'Attendance', 1, 1, '2023-09-26 23:22:34'),
       (8, 'And has changed attendance record 2023-08-01 11:30:01 of check_out to 2023-08-01 23:30:00', 'Attendance', 1,
        1, '2023-09-26 23:23:39'),
       (9,
        'Admin (1) has changed attendance record 2023-08-01 11:00:01 of check_in to 2023-08-01 11:30:01 And has changed attendance record 2023-08-01 11:00:01 of check_out to 2023-08-01 23:30:00',
        'Attendance', 1, 1, '2023-09-26 23:30:39'),
       (10, 'Admin (1) has changed payroll record 1 of salary from 34067 To 25470', 'PayRoll', 1, 1,
        '2023-09-26 23:34:31'),
       (11, 'Admin (1) has changed payroll record 1 of salary from 25470 To 34067', 'PayRoll', 1, 1,
        '2023-09-26 23:38:11'),
       (12,
        'Admin (1) has changed Deduction record from 933 To 0And has changed Advance record from 0 To 1And changed Salary record from 34067 To 34999',
        'PayRoll', 1, 1, '2023-09-26 23:43:51'),
       (13,
        'Admin (1) has changed Deduction record from 0 To 8000 And has changed Advance record from 1 To 0 And changed Salary record from 34999 To 27000',
        'PayRoll', 1, 1, '2023-09-26 23:44:39'),
       (14,
        ' And changed Last Name record Name from . To Ahmed And changed CNIC record from 46327733 To 463277332 And changed Gmail record from gh@gmail.com To ghi@gmail.com And changed Contact record from 2147483647 To 2147483 And changed Address record Name from Karachi, Sindh To Karachi, Sindh Pakistan And changed Shift record from (I-T)Morning(11:30am to 8:30pm) (1) To (I-S)Part time(6:00pm to 12:00am) (6) And changed Working Days record Name from 5 To 6 And changed Salary record Name from 2000 To 200000',
        'UserProfile', 1, 1, '2023-09-26 23:47:53'),
       (15,
        ' And changed CNIC record from 463277332 To 2147483647 And changed Gmail record from ghi@gmail.com To ghij@gmail.com And changed Contact record from 2147483 To 21474832 And changed Address record Name from Karachi, Sindh Pakistan To Karachi, Sindh  And changed Shift record from (I-S)Part time(6:00pm to 12:00am) (6) To Morning C (7) And changed Working Days record Name from 6 To 5 And changed Salary record Name from 200000 To 300000',
        'UserProfile', 1, 1, '2023-09-26 23:51:21'),
       (16,
        ' And changed CNIC record from 2147483647 To 214748364 And changed Gmail record from ghij@gmail.com To ghi@gmail.com And changed Contact record from 21474832 To 2147483 And changed Address record Name from Karachi, Sindh  To Karachi Sindh And changed Shift record from Morning C (7) To (I-T)Morning(11:30am to 8:30pm) (1) And changed Working Days record Name from 5 To 6 And changed Salary record Name from 300000 To 100000',
        'UserProfile', 1, 1, '2023-09-27 00:18:36'),
       (17,
        'Admin (1) And changed Gender record from Male (1) To Other (3) And changed CNIC record from 214748364 To 21474836 And changed Gmail record from ghi@gmail.com To ghij@gmail.com And changed Contact record from 2147483 To 21474832 And changed Address record Name from Karachi Sindh To Karachi, Sindh And changed Designatiom record 1 of Designation from Inovi Technology (1) To Inovi Solution (2) And changed PayScale record from Monthly (1) To Hourly (2) And changed Shift record from (I-T)Morning(11:30am to 8:30pm) (1) To (I-S)Night(9:00pm to 6:00am) (5) And changed Working Days record Name from 6 To 5 And changed Salary record Name from 100000 To 200000',
        'UserProfile', 1, 1, '2023-09-27 00:23:59'),
       (18,
        'Admin (1) Has changed First Name record from Arsalan To Ahmed And changed Last Name record Name from Ahmed To Arsalan And changed Gender record from Other (3) To Male (1) And changed CNIC record from 21474836 To 214748362 And changed Gmail record from ghij@gmail.com To ghi@gmail.com And changed Contact record from 21474832 To 214748322 And changed Address record Name from Karachi, Sindh To Karachi Sindh Pakistan And changed Designatiom record 1 of Designation from Inovi Solution (2) To Inovi Technology (1) And changed PayScale record from Hourly (2) To Monthly (1) And changed Shift record from (I-S)Night(9:00pm to 6:00am) (5) To Morning C (7) And changed Working Days record Name from 5 To 6 And changed Salary record Name from 200000 To 2000002',
        'UserProfile', 1, 1, '2023-09-27 00:25:43'),
       (19, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 00:28:01'),
       (20, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 00:31:57'),
       (21, 'Admin (1)', 'UserProfile', 1, 16, '2023-09-27 00:32:38'),
       (22, 'Admin (1)', 'UserProfile', 1, 17, '2023-09-27 00:32:38'),
       (23, 'Admin (1)', 'UserProfile', 1, 18, '2023-09-27 00:32:38'),
       (24, 'Admin (1)', 'UserProfile', 1, 19, '2023-09-27 00:32:38'),
       (25, 'Admin (1)', 'UserProfile', 1, 20, '2023-09-27 00:32:38'),
       (26, 'Admin (1)', 'UserProfile', 1, 21, '2023-09-27 00:32:38'),
       (27, 'Admin (1)', 'UserProfile', 1, 22, '2023-09-27 00:32:38'),
       (28, 'Admin (1)', 'UserProfile', 1, 23, '2023-09-27 00:32:38'),
       (29, 'Admin (1)', 'UserProfile', 1, 24, '2023-09-27 00:32:38'),
       (30, 'Admin (1)', 'UserProfile', 1, 25, '2023-09-27 00:32:38'),
       (31, 'Admin (1)', 'UserProfile', 1, 26, '2023-09-27 00:32:38'),
       (32, 'Admin (1)', 'UserProfile', 1, 27, '2023-09-27 00:32:38'),
       (33, 'Admin (1)', 'UserProfile', 1, 28, '2023-09-27 00:32:38'),
       (34, 'Admin (1)', 'UserProfile', 1, 29, '2023-09-27 00:32:38'),
       (35, 'Admin (1)', 'UserProfile', 1, 30, '2023-09-27 00:32:38'),
       (36, 'Admin (1)', 'UserProfile', 1, 31, '2023-09-27 00:32:38'),
       (37, 'Admin (1)', 'UserProfile', 1, 32, '2023-09-27 00:32:38'),
       (38, 'Admin (1)', 'UserProfile', 1, 33, '2023-09-27 00:32:38'),
       (39, 'Admin (1)', 'UserProfile', 1, 34, '2023-09-27 00:32:38'),
       (40, 'Admin (1)', 'UserProfile', 1, 35, '2023-09-27 00:32:38'),
       (41, 'Admin (1)', 'UserProfile', 1, 36, '2023-09-27 00:32:38'),
       (42, 'Admin (1)', 'UserProfile', 1, 37, '2023-09-27 00:32:38'),
       (43, 'Admin (1)', 'UserProfile', 1, 38, '2023-09-27 00:32:38'),
       (44, 'Admin (1)', 'UserProfile', 1, 39, '2023-09-27 00:32:38'),
       (45, 'Admin (1)', 'UserProfile', 1, 40, '2023-09-27 00:32:38'),
       (46, 'Admin (1)', 'UserProfile', 1, 41, '2023-09-27 00:32:38'),
       (47, 'Admin (1)', 'UserProfile', 1, 42, '2023-09-27 00:32:38'),
       (48, 'Admin (1)', 'UserProfile', 1, 43, '2023-09-27 00:32:38'),
       (49, 'Admin (1)', 'UserProfile', 1, 44, '2023-09-27 00:32:38'),
       (50, 'Admin (1)', 'UserProfile', 1, 45, '2023-09-27 00:32:38'),
       (51, 'Admin (1)', 'UserProfile', 1, 46, '2023-09-27 00:32:38'),
       (52, 'Admin (1)', 'UserProfile', 1, 47, '2023-09-27 00:32:38'),
       (53, 'Admin (1)', 'UserProfile', 1, 51, '2023-09-27 00:32:38'),
       (54, 'Admin (1)', 'UserProfile', 1, 61, '2023-09-27 00:32:38'),
       (55, 'Admin (1)', 'UserProfile', 1, 63, '2023-09-27 00:32:38'),
       (56, 'Admin (1)', 'UserProfile', 1, 70, '2023-09-27 00:32:38'),
       (57, 'Admin (1)', 'UserProfile', 1, 71, '2023-09-27 00:32:38'),
       (58, 'Admin (1)', 'UserProfile', 1, 75, '2023-09-27 00:32:38'),
       (59, 'Admin (1)', 'UserProfile', 1, 76, '2023-09-27 00:32:38'),
       (60, 'Admin (1)', 'UserProfile', 1, 78, '2023-09-27 00:32:38'),
       (61, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 02:51:10'),
       (62, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 02:53:32'),
       (63, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 02:54:05'),
       (64, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 02:54:33'),
       (65, NULL, 'Attendance', 1, 1, '2023-09-27 03:02:02'),
       (66, NULL, 'Attendance', 1, 1, '2023-09-27 03:02:36'),
       (67, NULL, 'Attendance', 1, 1, '2023-09-27 03:02:49'),
       (68,
        'Admin (1) has changed attendance record 2023-08-01 11:30:00 of check_in to 2023-08-01 11:30:00 And has changed attendance record 2023-08-01 11:30:00 of check_out to 2023-08-01 11:30:00',
        'Attendance', 1, 1, '2023-09-27 03:03:27'),
       (69,
        'Admin (1) has changed attendance record 2023-08-02 11:30:00 of check_in to 2023-08-02 11:37:00 And has changed attendance record 2023-08-02 11:30:00 of check_out to 2023-08-02 09:53:47',
        'Attendance', 1, 1, '2023-09-27 03:03:52'),
       (70, 'Admin (1)', 'UserProfile', 1, 14, '2023-09-27 19:07:58'),
       (71, 'Admin (1)', 'UserProfile', 1, 13, '2023-09-27 19:12:48'),
       (72,
        'Admin (1) And changed Last Name record Name from Arsalan To  Arsalan And changed Designatiom record 1 of Designation from Inovi Technology (1) To Inovi Solution (2) And changed Shift record from Morning C (7) To (I-T)Morning(11:30am to 8:30pm) (1) And changed Working Days record Name from 6 To 5 And changed Salary record Name from 2000002 To 200000',
        'UserProfile', 1, 1, '2023-09-27 20:25:51'),
       (73,
        'Admin (1) Has changed First Name record from Ahmed To Ahmed  Arsalan And changed Last Name record Name from  Arsalan To Ahmed  Arsalan And changed Designatiom record 1 of Designation from Inovi Solution (2) To Inovi Technology (1) And changed Working Days record Name from 5 To 6',
        'UserProfile', 1, 1, '2023-09-27 20:28:29'),
       (74,
        'Admin (1) Has changed First Name record from Ahmed  Arsalan To Ahmed  Arsalan Ahmed  Arsalan And changed Last Name record Name from Ahmed  Arsalan To Ahmed  Arsalan Ahmed  Arsalan And changed Gender record from Male (1) To Female (2)',
        'UserProfile', 1, 1, '2023-09-27 20:28:38'),
       (75,
        'Admin (1) Has changed First Name record from Ahmed  Arsalan Ahmed  Arsalan To Ahmed And changed Last Name record Name from Ahmed  Arsalan Ahmed  Arsalan To   Arsalan  And changed Gender record from Female (2) To Male (1)',
        'UserProfile', 1, 1, '2023-09-27 20:29:03'),
       (76, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 21:39:55'),
       (77, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 22:01:42'),
       (78, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-27 22:01:54'),
       (79,
        'Admin (1) Has changed First Name record from Ahmed To Ahmed   Arsalan  And changed Last Name record Name from   Arsalan  To Ahmed   Arsalan  And changed Gender record from Male (1) To Female (2)',
        'UserProfile', 1, 1, '2023-09-27 22:04:56'),
       (81,
        'Admin (1) Has changed First Name record from Ahmed   Arsalan  To Ahmed And changed Last Name record Name from Ahmed   Arsalan  To . And changed Gender record from Female (2) To Male (1)',
        'UserProfile', 1, 1, '2023-09-27 22:06:31'),
       (82,
        'Admin (1) Has changed First Name record from Ahmed To Ahmed . And changed Gender record from Male (1) To Female (2)',
        'UserProfile', 1, 1, '2023-09-27 23:57:13'),
       (83,
        'Admin (1) Has changed First Name record from Ahmed . To Ahmed  And changed Gender record from Female (2) To Male (1)',
        'UserProfile', 1, 1, '2023-09-27 23:57:28'),
       (84, 'Admin (1) And changed Gender record from Male (1) To Female (2)', 'UserProfile', 1, 1,
        '2023-09-28 00:00:13'),
       (85, 'Admin (1) And changed Gender record from Female (2) To Male (1)', 'UserProfile', 1, 1,
        '2023-09-28 00:00:27'),
       (86,
        'Admin (1) has changed attendance record 2023-08-01 11:30:00 of check_in to 2023-08-01 11:20:00 And has changed attendance record 2023-08-01 11:30:00 of check_out to 2023-08-01 11:30:00',
        'Attendance', 1, 1, '2023-09-28 00:06:51'),
       (87,
        'Admin (1) has changed attendance record 2023-08-08 12:16:01 of check_in to 2023-08-08 12:26:01 And has changed attendance record 2023-08-08 12:16:01 of check_out to 2023-08-08 10:26:25',
        'Attendance', 1, 1, '2023-09-28 00:07:25'),
       (88, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-28 00:10:07'),
       (89, 'Admin (1)', 'UserProfile', 1, 1, '2023-09-28 00:10:20'),
       (90, 'Admin (1) has changed Deduction record from 9332 To 933 And changed Salary record from 25668 To 34067',
        'PayRoll', 1, 1, '2023-09-28 00:11:32'),
       (91,
        'Admin (1) has changed attendance record 2023-08-01 11:30:00 of check_in to 2023-08-01 11:20:00 And has changed attendance record 2023-08-01 11:30:00 of check_out to 2023-08-01 10:00:20',
        'Attendance', 1, 1, '2023-09-28 00:29:21'),
       (92,
        'Admin (1) has changed attendance record 2023-08-01 11:30:00 of check_in to 2023-08-01 11:20:00 And has changed attendance record 2023-08-01 11:30:00 of check_out to 2023-08-01 10:00:20',
        'Attendance', 1, 1, '2023-09-28 00:30:52'),
       (93,
        'Admin (1) Has changed First Name record from Ahmed  To Ahmed . And changed Last Name record Name from . To Ahmed . And changed Shift record from (I-T)Morning(11:30am to 8:30pm) (1) To (I-S)Part time(6:00pm to 12:00am) (6)',
        'UserProfile', 1, 1, '2023-09-28 01:15:12'),
       (94,
        'Admin (1) Has changed First Name record from Ahmed . To ARSALAN And changed Last Name record Name from Ahmed . To AHMED And changed Working Days record Name from 6 To 5',
        'UserProfile', 1, 1, '2023-09-28 01:15:36'),
       (95,
        'Admin (1) And changed Last Name record Name from AHMED To  AHMED And changed Address record Name from Karachi Sindh Pakistan To Karachi Sindh And changed Working Days record Name from 5 To 6',
        'UserProfile', 1, 1, '2023-09-28 02:39:08'),
       (96, NULL, 'Attendance', 1, 1, '2023-09-28 02:39:54'),
       (97, NULL, 'Attendance', 1, 1, '2023-09-28 02:40:22'),
       (98,
        'Admin (1) has changed attendance record 2023-08-01 11:30:00 of check_in to 2023-08-01 11:30:30 And has changed attendance record 2023-08-01 11:30:00 of check_out to 2023-08-01 10:30:30',
        'Attendance', 1, 1, '2023-09-28 02:40:49'),
       (99,
        'Admin (1) And changed Last Name record Name from  To TAHA TABANI  And changed CNIC record from 0 To 2147483647 And changed Gmail record from  To syedtalha641@gmail.com And changed PayScale record from Monthly (1) To Hourly (2)',
        'UserProfile', 1, 25, '2023-10-02 20:39:06'),
       (100,
        'Admin (1) Has changed First Name record from TAHA TABANI  To TAHA TABANI  TAHA TABANI  And changed Last Name record Name from TAHA TABANI  To TAHA TABANI  TAHA TABANI  And changed PayScale record from Hourly (2) To Monthly (1)',
        'UserProfile', 1, 25, '2023-10-02 20:39:33'),
       (101,
        'Admin (1) Has changed First Name record from TAHA TABANI  TAHA TABANI  To TAHA TABANI  TAHA TABANI  TAHA TABANI  TAHA TABANI And changed Last Name record Name from TAHA TABANI  TAHA TABANI  To TAHA TABANI  TAHA TABANI  TAHA TABANI  TAHA TABANI And changed CNIC record from 2147483647 To 0',
        'UserProfile', 1, 25, '2023-10-02 20:39:50'),
       (102,
        'Admin (1) Has changed First Name record from TAHA TABANI  TAHA TABANI  TAHA TABANI  TAHA TABANI To TAHA TABANI  And changed Last Name record Name from TAHA TABANI  TAHA TABANI  TAHA TABANI  TAHA TABANI To TAHA TABANI',
        'UserProfile', 1, 25, '2023-10-02 20:40:07'),
       (103, 'Admin (1)', 'UserProfile', 1, 14, '2023-10-02 20:44:05'),
       (104, 'Admin (1)', 'UserProfile', 1, 16, '2023-10-02 20:44:05'),
       (105, 'Admin (1)', 'UserProfile', 1, 17, '2023-10-02 20:44:05'),
       (106, 'Admin (1)', 'UserProfile', 1, 18, '2023-10-02 20:44:05'),
       (107, 'Admin (1)', 'UserProfile', 1, 19, '2023-10-02 20:44:05'),
       (108, 'Admin (1)', 'UserProfile', 1, 20, '2023-10-02 20:44:05'),
       (109, 'Admin (1)', 'UserProfile', 1, 21, '2023-10-02 20:44:05'),
       (110, 'Admin (1)', 'UserProfile', 1, 22, '2023-10-02 20:44:05'),
       (111, 'Admin (1)', 'UserProfile', 1, 23, '2023-10-02 20:44:05'),
       (112, 'Admin (1)', 'UserProfile', 1, 24, '2023-10-02 20:44:05'),
       (113, 'Admin (1)', 'UserProfile', 1, 25, '2023-10-02 20:44:05'),
       (114, 'Admin (1)', 'UserProfile', 1, 26, '2023-10-02 20:44:05'),
       (115, 'Admin (1)', 'UserProfile', 1, 27, '2023-10-02 20:44:05'),
       (116, 'Admin (1)', 'UserProfile', 1, 28, '2023-10-02 20:44:05'),
       (117, 'Admin (1)', 'UserProfile', 1, 29, '2023-10-02 20:44:05'),
       (118, 'Admin (1)', 'UserProfile', 1, 30, '2023-10-02 20:44:05'),
       (119, 'Admin (1)', 'UserProfile', 1, 31, '2023-10-02 20:44:05'),
       (120, 'Admin (1)', 'UserProfile', 1, 32, '2023-10-02 20:44:05'),
       (121, 'Admin (1)', 'UserProfile', 1, 33, '2023-10-02 20:44:05'),
       (122, 'Admin (1)', 'UserProfile', 1, 34, '2023-10-02 20:44:05'),
       (123, 'Admin (1)', 'UserProfile', 1, 35, '2023-10-02 20:44:05'),
       (124, 'Admin (1)', 'UserProfile', 1, 36, '2023-10-02 20:44:05'),
       (125, 'Admin (1)', 'UserProfile', 1, 37, '2023-10-02 20:44:05'),
       (126, 'Admin (1)', 'UserProfile', 1, 38, '2023-10-02 20:44:05'),
       (127, 'Admin (1)', 'UserProfile', 1, 39, '2023-10-02 20:44:05'),
       (128, 'Admin (1)', 'UserProfile', 1, 40, '2023-10-02 20:44:05'),
       (129, 'Admin (1)', 'UserProfile', 1, 41, '2023-10-02 20:44:05'),
       (130, 'Admin (1)', 'UserProfile', 1, 42, '2023-10-02 20:44:05'),
       (131, 'Admin (1)', 'UserProfile', 1, 43, '2023-10-02 20:44:05'),
       (132, 'Admin (1)', 'UserProfile', 1, 44, '2023-10-02 20:44:05'),
       (133, 'Admin (1)', 'UserProfile', 1, 45, '2023-10-02 20:44:05'),
       (134, 'Admin (1)', 'UserProfile', 1, 46, '2023-10-02 20:44:05'),
       (135, 'Admin (1)', 'UserProfile', 1, 47, '2023-10-02 20:44:05'),
       (136, 'Admin (1)', 'UserProfile', 1, 51, '2023-10-02 20:44:05'),
       (137, 'Admin (1)', 'UserProfile', 1, 61, '2023-10-02 20:44:05'),
       (138, 'Admin (1)', 'UserProfile', 1, 63, '2023-10-02 20:44:05'),
       (139, 'Admin (1)', 'UserProfile', 1, 70, '2023-10-02 20:44:05'),
       (140, 'Admin (1)', 'UserProfile', 1, 71, '2023-10-02 20:44:05'),
       (141, 'Admin (1)', 'UserProfile', 1, 75, '2023-10-02 20:44:05'),
       (142, 'Admin (1)', 'UserProfile', 1, 76, '2023-10-02 20:44:05'),
       (143, 'Admin (1)', 'UserProfile', 1, 78, '2023-10-02 20:44:05'),
       (144,
        'Admin (1) Has changed First Name record from f test To f test l test  And changed Last Name record Name from l test  To f test l test  And changed Working Days record Name from 0 To 6',
        'UserProfile', 1, 90, '2023-10-02 20:49:13'),
       (145,
        'Admin (1) has changed attendance record 2023-08-01 11:30:30 of check_in to 2023-08-01 11:30:31 And has changed attendance record 2023-08-01 11:30:30 of check_out to 2023-08-01 10:30:35',
        'Attendance', 1, 1, '2023-10-02 20:49:40'),
       (146, 'Admin (1)', 'UserProfile', 1, 14, '2023-10-02 21:15:17'),
       (147, 'Admin (1)', 'UserProfile', 1, 14, '2023-10-02 21:15:37'),
       (148, 'Admin (1)', 'UserProfile', 1, 14, '2023-10-02 21:16:12'),
       (149, 'Admin (1)', 'UserProfile', 1, 14, '2023-10-02 21:22:20'),
       (150, 'Admin (1)', 'UserProfile', 1, 1, '2023-10-02 21:28:49'),
       (151, 'Admin (1) And changed CNIC record from 0 To 42401', 'UserProfile', 1, 91, '2023-10-02 21:47:52'),
       (152, 'Admin (1)', 'UserProfile', 1, 91, '2023-10-02 21:48:22'),
       (153, 'Admin (1)', 'UserProfile', 1, 91, '2023-10-02 21:48:41'),
       (154, 'Admin (1)', 'UserProfile', 1, 91, '2023-10-02 21:50:00'),
       (155,
        'Admin (1) Has changed First Name record from ABRAR To ABRAR 1 And changed Last Name record Name from  To ABRAR 2 And changed Gmail record from  To syedtalha641@gmail.com',
        'UserProfile', 1, 3, '2023-10-02 22:15:03'),
       (156,
        'Admin (1) Has changed First Name record from ARSALAN To Syed Arsalan And changed Last Name record Name from  AHMED To  AHMED 1 And changed CNIC record from 214748362 To 2147483647 And changed Contact record from 214748322 To 2147483647',
        'UserProfile', 1, 1, '2023-10-02 22:56:13'),
       (157, 'Admin (1)', 'UserProfile', 1, 1, '2023-10-02 22:56:57'),
       (158, 'Admin (1)', 'UserProfile', 1, 1, '2023-10-02 22:57:37'),
       (159, 'Admin (1)', 'UserProfile', 1, 1, '2023-10-02 22:57:54'),
       (160, 'Admin (1) And changed CNIC record from 2147483647 To 4240164872311', 'UserProfile', 1, 1,
        '2023-10-02 22:58:25'),
       (161, 'Admin (1) And changed Contact record from 2147483647 To 03152155245', 'UserProfile', 1, 1,
        '2023-10-02 22:58:54');

-- --------------------------------------------------------

--
-- Table structure for table `payroll`
--

CREATE TABLE `payroll`
(
    `id`          int(10)  NOT NULL,
    `UserP_Id`       int(10)  NOT NULL,
    `Designation_Id` int(10)  NOT NULL,
    `Shift_Id`       int(10)  NOT NULL,
    `Pay_Id`         int(10)  NOT NULL,
    `time_in`        datetime NOT NULL,
    `time_out`       datetime NOT NULL,
    `PayRoll_Type`   int(11)  NOT NULL,
    `salary`         double            DEFAULT 0,
    `deducted_days`  int(11)           DEFAULT 0,
    `late`           int(11)           DEFAULT 0,
    `absent`         int(11)           DEFAULT 0,
    `Deduction`      double            DEFAULT 0,
    `M_Deducted`     double            DEFAULT 0,
    `Advance`        double            DEFAULT 0,
    `M_Advance`      double            DEFAULT 0,
    `Total_Pay`      double            DEFAULT 0,
    `M_Salary`       double            DEFAULT 0,
    `Remarks`        varchar(255)      DEFAULT NULL,
    `Status`         int(11)  NOT NULL DEFAULT 0,
    `isactive`       tinyint(1)        DEFAULT 1,
    `created_by`     int(10)  NOT NULL,
    `updated_by`     int(10)           DEFAULT NULL,
    `created_on`     datetime          DEFAULT current_timestamp(),
    `updated_on`     datetime          DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Triggers `payroll`
--
DELIMITER $$
CREATE TRIGGER `payroll_update_trigger`
    BEFORE UPDATE
    ON `payroll`
    FOR EACH ROW
BEGIN

    Set @User = (select CONCAT(u.username, ' (', u.id, ')') from user u where u.id = NEW.updated_by);
    SET @MSG = '';
    IF NEW.M_Deducted != OLD.M_Deducted THEN
        SET @MSG = CONCAT(@User, ' has changed Deduction record from ', OLD.M_Deducted, ' To ', New.M_Deducted);
    END IF;

    IF NEW.M_Advance != OLD.M_Advance THEN
        SET @MSG = CONCAT(@MSG, ' And has changed Advance record from ', OLD.M_Advance, ' To ', New.M_Advance);
    END IF;

    IF NEW.M_Salary != OLD.M_Salary THEN
        SET @MSG = CONCAT(@MSG, ' And changed Salary record from ', OLD.M_Salary, ' To ', NEW.M_Salary);
    END IF;

    insert into logs(Log_Description, TBL_Name, created_by, created_on) value (@MSG, 'PayRoll', NEW.id, CURRENT_TIMESTAMP);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `payroll_type`
--

CREATE TABLE `payroll_type`
(
    `id`       int(11)      NOT NULL,
    `Name`        varchar(50)  NOT NULL,
    `Description` varchar(255) NOT NULL,
    `isactive`    tinyint(1)   NOT NULL DEFAULT 1,
    `created_by`  int(11)      NOT NULL,
    `updated_by`  int(11)               DEFAULT NULL,
    `created_on`  datetime     NOT NULL,
    `updated_on`  datetime              DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `payroll_type`
--

INSERT INTO `payroll_type` (`id`, `Name`, `Description`, `isactive`, `created_by`, `updated_by`, `created_on`,
                            `updated_on`)
VALUES (1, 'Regular Payroll', 'Payroll For Regular Base', 1, 1, NULL, '2023-09-16 00:48:26', NULL),
       (2, 'Special Payroll', 'Payroll for instant termination', 1, 1, 1, '2023-09-18 20:52:41', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `pay_scale`
--

CREATE TABLE `pay_scale`
(
    `id`      int(10)     NOT NULL,
    `pay_name`   varchar(50) NOT NULL,
    `isactive`   tinyint(1) DEFAULT 1,
    `created_by` int(10)     NOT NULL,
    `updated_by` int(10)    DEFAULT NULL,
    `created_on` datetime    NOT NULL,
    `updated_on` datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `pay_scale`
--

INSERT INTO `pay_scale` (`id`, `pay_name`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, 'Monthly', 1, 1, 1, '2023-08-09 00:00:00', '2023-08-22 11:48:07'),
       (2, 'Hourly', 1, 1, NULL, '2023-09-01 22:00:06', '2023-09-12 10:35:18');

-- --------------------------------------------------------

--
-- Table structure for table `permission`
--

CREATE TABLE `permission`
(
    `id`            int(11)     NOT NULL,
    `permisssion_name` varchar(50) NOT NULL,
    `controller`       varchar(50) NOT NULL,
    `action`           varchar(50) NOT NULL,
    `parameters`       varchar(50) NOT NULL,
    `method`           varchar(50) NOT NULL,
    `icon`             varchar(50) NOT NULL,
    `sort`             int(11)     NOT NULL,
    `Permission_Id`    int(10)     NOT NULL,
    `isactive`         tinyint(1) DEFAULT 1,
    `created_by`       int(10)     NOT NULL,
    `updated_by`       int(10)    DEFAULT NULL,
    `created_on`       datetime    NOT NULL,
    `updated_on`       datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `permission`
--

INSERT INTO `permission` (`id`, `permisssion_name`, `controller`, `action`, `parameters`, `method`, `icon`, `sort`,
                          `Permission_Id`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, 'HR', 'HR', 'POST', 'EDIT', 'GET', 'MENU', 1, 1, 1, 1, NULL, '2023-08-31 18:17:57', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `permission_assign`
--

CREATE TABLE `permission_assign`
(
    `id`         int(10)  NOT NULL,
    `Role_Id`       int(10)  NOT NULL,
    `Permission_Id` int(10)  NOT NULL,
    `isactive`      tinyint(1) DEFAULT 1,
    `created_by`    int(10)  NOT NULL,
    `updated_by`    int(10)    DEFAULT NULL,
    `created_on`    datetime NOT NULL,
    `updated_on`    datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `permission_assign`
--

INSERT INTO `permission_assign` (`id`, `Role_Id`, `Permission_Id`, `isactive`, `created_by`, `updated_by`,
                                 `created_on`, `updated_on`)
VALUES (1, 1, 1, 1, 1, 1, '2023-08-09 00:00:00', '2023-08-09 00:00:00');

-- --------------------------------------------------------

--
-- Table structure for table `role`
--

CREATE TABLE `role`
(
    `id`      int(10)     NOT NULL,
    `role_name`  varchar(50) NOT NULL,
    `isactive`   tinyint(1) DEFAULT 1,
    `created_by` int(10)     NOT NULL,
    `updated_by` int(10)    DEFAULT NULL,
    `created_on` datetime    NOT NULL,
    `updated_on` datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `role`
--

INSERT INTO `role` (`id`, `role_name`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, 'HR Manager', 1, 1, NULL, '2023-08-31 09:11:29', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `shift`
--

CREATE TABLE `shift`
(
    `id`      int(10)     NOT NULL,
    `shift_name` varchar(50) NOT NULL,
    `time_in`    time        NOT NULL,
    `time_out`   time        NOT NULL,
    `grace_time` time        NOT NULL,
    `isactive`   tinyint(1)  NOT NULL DEFAULT 1,
    `created_by` int(10)     NOT NULL,
    `updated_by` int(10)              DEFAULT NULL,
    `created_on` datetime    NOT NULL,
    `updated_on` datetime             DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `shift`
--

INSERT INTO `shift` (`id`, `shift_name`, `time_in`, `time_out`, `grace_time`, `isactive`, `created_by`, `updated_by`,
                     `created_on`, `updated_on`)
VALUES (1, '(I-T)Morning(11:30am to 8:30pm)', '11:30:00', '20:30:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28',
        NULL),
       (2, '(I-S)DAY(Production)Morning (12:00pm to 9:00pm)', '12:00:00', '21:00:00', '00:15:00', 1, 1, NULL,
        '2023-08-31 17:56:27', NULL),
       (3, '(I-S)MID SHIFT(6:00pm to 3:00am)', '18:00:00', '03:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28',
        NULL),
       (4, '(I-S)Mid Late(7:00pm to 4:00am)', '19:00:00', '04:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 17:56:27',
        NULL),
       (5, '(I-S)Night(9:00pm to 6:00am)', '21:00:00', '06:00:00', '00:15:00', 1, 1, NULL, '2023-08-31 08:56:28', NULL),
       (6, '(I-S)Part time(6:00pm to 12:00am)', '18:00:00', '23:59:59', '00:15:00', 1, 1, NULL, '2023-08-31 17:56:27',
        NULL),
       (7, 'Morning C', '07:31:00', '00:36:00', '00:00:15', 0, 1, 1, '2023-09-26 19:36:18', '2023-09-26 19:37:06'),
       (8, 'Morning B', '00:30:00', '12:30:00', '00:15:00', 0, 1, 1, '2023-09-28 00:12:04', '2023-09-28 00:13:04'),
       (9, 'Morning c', '00:30:00', '23:15:00', '00:15:00', 0, 1, NULL, '2023-09-28 00:12:41', '2023-09-28 00:12:54');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_gender`
--

CREATE TABLE `tbl_gender`
(
    `id`      int(10)     NOT NULL,
    `Gender`     varchar(10) NOT NULL,
    `isactive`   tinyint(1)  NOT NULL DEFAULT 1,
    `created_by` int(2)      NOT NULL,
    `updated_by` int(2)      NOT NULL,
    `created_on` datetime    NOT NULL,
    `updated_on` datetime    NOT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `tbl_gender`
--

INSERT INTO `tbl_gender` (`id`, `Gender`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, 'Male', 1, 1, 1, '2023-08-24 11:09:14', '2023-08-24 11:09:14'),
       (2, 'Female', 1, 1, 1, '2023-08-24 11:09:14', '2023-08-24 11:09:14'),
       (3, 'Other', 1, 1, 1, '2023-08-24 11:15:03', '2023-08-24 11:15:03');

-- --------------------------------------------------------

--
-- Table structure for table `tbl_machinedata`
--

CREATE TABLE `tbl_machinedata`
(
    `ID`          varchar(50)  NOT NULL,
    `DateAndTime` datetime     NOT NULL,
    `Date`        date         NOT NULL,
    `Time`        time         NOT NULL,
    `Status`      varchar(50)  NOT NULL,
    `Device`      varchar(255) NOT NULL,
    `DeviceNo`    varchar(255) NOT NULL,
    `Person_Name` varchar(25)  NOT NULL,
    `Card_No`     varchar(25)  NOT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `tbl_machinedata`
--

INSERT INTO `tbl_machinedata` (`ID`, `DateAndTime`, `Date`, `Time`, `Status`, `Device`, `DeviceNo`, `Person_Name`,
                               `Card_No`)
VALUES ('1', '2023-08-17 08:02:31', '2023-08-17', '08:02:31', '1', 'IVMS_4200', '5575345546', '1', ''),
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
CREATE TRIGGER `Trigger_Pull_Data`
    AFTER INSERT
    ON `tbl_machinedata`
    FOR EACH ROW
BEGIN
    DECLARE ClockIn DATETIME;
    DECLARE ClockOut DATETIME;

    -- Find the earliest clock in time
    SELECT Time
    INTO ClockIn
    FROM tbl_machinedata
    WHERE ID = NEW.ID
      AND Date = NEW.Date
    ORDER BY Time DESC
    LIMIT 1;

    -- Find the latest clock out time
    SELECT Time
    INTO ClockOut
    FROM tbl_machinedata
    WHERE ID = NEW.ID
      AND Date = NEW.Date
    ORDER BY Time ASC
    LIMIT 1;

    -- Update the new attendance record with the earliest clock in and latest clock out times
    UPDATE attendance as a
    SET a.check_in  = ClockIn,
        a.check_out = ClockOut
    WHERE a.Employee_Id = NEW.ID
      AND a.check_in_date = NEW.Date;

END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `user`
--

CREATE TABLE `user`
(
    `id`      int(10)     NOT NULL,
    `UserP_Id`   int(10)     NOT NULL,
    `Role_Id`    int(10)     NOT NULL,
    `username`   varchar(50) NOT NULL,
    `password`   varchar(100) NOT NULL,
    `isactive`   tinyint(1) DEFAULT 1,
    `created_by` int(10)     NOT NULL,
    `updated_by` int(10)    DEFAULT NULL,
    `created_on` datetime    NOT NULL,
    `updated_on` datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `user`
--

INSERT INTO `user` (`id`, `UserP_Id`, `Role_Id`, `username`, `password`, `isactive`, `created_by`, `updated_by`,
                    `created_on`, `updated_on`)
VALUES (1, 43, 1, 'Admin', '123', 1, 1, NULL, '2023-08-31 09:09:39', NULL);

-- --------------------------------------------------------

--
-- Table structure for table `user_profile`
--

CREATE TABLE `user_profile`
(
    `id`          int(10)      NOT NULL,
    `Employee_Id`    varchar(50)  NOT NULL,
    `firstname`      varchar(50)  NOT NULL,
    `lastname`       varchar(50)  NOT NULL,
    `gender`         int(10)      NOT NULL,
    `CNIC`           varchar(255) NOT NULL,
    `Gmail`          varchar(50)  NOT NULL,
    `contact`        varchar(255) NOT NULL,
    `address`        text         NOT NULL,
    `Designation_Id` int(10)    DEFAULT NULL,
    `payscale_id`    int(10)    DEFAULT NULL,
    `shift_id`       int(10)    DEFAULT NULL,
    `workingDays`    int(5)     DEFAULT 5,
    `salary`         double       NOT NULL,
    `Advance`        double     DEFAULT 0,
    `Cheak_value`    tinyint(2) DEFAULT 0,
    `isactive`       tinyint(1) DEFAULT 1,
    `created_by`     int(10)      NOT NULL,
    `updated_by`     int(10)    DEFAULT NULL,
    `created_on`     datetime     NOT NULL,
    `updated_on`     datetime   DEFAULT NULL
) ENGINE = InnoDB
  DEFAULT CHARSET = utf8mb4;

--
-- Dumping data for table `user_profile`
--

INSERT INTO `user_profile` (`id`, `Employee_Id`, `firstname`, `lastname`, `gender`, `CNIC`, `Gmail`, `contact`,
                            `address`, `Designation_Id`, `payscale_id`, `shift_id`, `workingDays`, `salary`, `Advance`,
                            `Cheak_value`, `isactive`, `created_by`, `updated_by`, `created_on`, `updated_on`)
VALUES (1, '1', 'Syed Arsalan', ' AHMED 1', 1, '4240164872311', 'ghi@gmail.com', '03152155245', 'Karachi Sindh', 1, 1,
        6, 6, 200000, 5501, 0, 1, 0, 1, '0000-00-00 00:00:00', '2023-10-02 22:58:54'),
       (2, '2', 'FARHAN RAZZAQ', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5, 25000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (3, '3', 'ABRAR 1', 'ABRAR 2', 1, '0', 'syedtalha641@gmail.com', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5,
        3000, 0, 0, 1, 0, 1, '0000-00-00 00:00:00', '2023-10-02 22:15:03'),
       (4, '4', 'FARRUKH', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 3, 5, 200, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (5, '5', 'MUHAMMAD JIBRAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 1000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (6, '6', 'SAAD SAEED', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 100000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (7, '7', 'ABDUL SUBHAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5, 50000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (8, '8', 'SYED TALHA SALMAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 6, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (9, '9', 'ALIYAAN AHMED', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (10, '10', 'VARUN KUMAR', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (11, '11', 'MUHAMMAD ANIQ', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (12, '12', 'MUHAMMAD FURQAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (13, '13', 'ZOHRAN AHMED', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (14, '14', 'MUHAMMAD SHAHRYAR', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 35000, 27097, 0, 1,
        0, 1, '0000-00-00 00:00:00', NULL),
       (15, '15', 'MUJTABA KHAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (16, '16', 'NADEEM ZUBARI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 40000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (17, '17', 'IRFAN HUSSSIN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 45000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (18, '18', 'ABDUL REHMAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 150000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (19, '19', 'SYED ALY RAZA', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 24000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (20, '20', 'ANAS KHATRI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 8000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (21, '21', 'WAQAR NARSI', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 10000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (22, '22', 'IRFAN KHAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 200, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (23, '23', 'NOMAN KODWAWI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 100, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (24, '24', 'TAHIR WADIWALA', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 700, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (25, '25', 'TAHA TABANI ', 'TAHA TABANI', 1, '0', 'syedtalha641@gmail.com', '2147483647', 'Karachi, Sindh', 1, 1,
        1, 6, 60000, 0, 0, 1, 0, 1, '0000-00-00 00:00:00', '2023-10-02 20:40:07'),
       (26, '26', 'SAMEER SALEEM', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 75000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (27, '27', 'RIZWAN HUSSAIN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 900, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (28, '28', 'ABDUL AZEEM', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 90000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (29, '29', 'MOHSIN ASLAM', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 13000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (30, '30', 'SHAFIQ AHMED', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 15000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (31, '31', 'RAYYAN MIANOOR', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 19000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (32, '32', 'FAHAD FAISAL', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 800000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (33, '33', 'MUHAMMAD ALI', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 120000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (34, '34', 'IMRAN CHOUHAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 134000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (35, '35', 'SALMAN QAZI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 1500, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (36, '36', 'SYED AMMAR', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 35000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (37, '37', 'HUSSAIN AHMED', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 60000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (38, '38', 'ABDUL SAMAD', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 78000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (39, '39', 'NADEEM AHMED', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 88000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (40, '40', 'HAFIZ BILAL HASSAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 40500, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (41, '41', 'AZHAR KHAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 47000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (42, '42', 'USAMA JAVED', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 50000, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (43, '43', 'TOOBA ALI', '', 2, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 30000, 0, 1, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (44, '44', 'TALHA MIANOOR', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (45, '45', 'NOOR MUHAMMAD', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (46, '46', 'ASIF SHAIKH', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (47, '47', 'MUHAMMAD QASIM', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (48, '48', 'SYED HASNAIN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (49, '49', 'SUNWEETH ROBIN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (50, '50', 'SAAD SULEMAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (51, '51', 'HARIS TARIQ', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (52, '52', 'HUNAIN IMRAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (53, '53', 'ASHTAR ALI', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (54, '54', 'SYED SAQIB', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (55, '55', 'ABDULLAH REHMAN', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (56, '56', 'MURTAZA KHAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (57, '57', 'ANAS FAROOQ', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (58, '58', 'MUHAMMAD USMAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (59, '59', 'SAHIL KHIMANI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 3, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (60, '60', 'M.UMAIR SHAFIQ', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (61, '61', 'MUHAMMAD NAEEM', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (62, '62', 'SYED AREEB', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (63, '63', 'SAIM MAJID', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (64, '64', 'M.FARIS SHEIKH', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (65, '65', 'UMER DURANI', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (66, '66', 'HAYA SHEIKH', '', 2, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 6, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (67, '67', 'ABDUL REHMAN RAZA', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (68, '68', 'M.TARIQ', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (69, '69', 'SOMIL RUPELA', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 4, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (70, '70', 'ASLAM MEER', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (71, '71', 'ZAFAR', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (72, '72', 'HOOD BASIT', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (73, '73', 'HUNAIN NADEEM', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 1, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (74, '74', 'DANIYAL KHATRI', '', 1, '0', '', '2147483647', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (75, '75', 'M.AFZAL', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (76, '76', 'FAROOQ KHAN', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (77, '77', 'MURTAZA MUGHAL', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 5, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (78, '78', 'HAMMAD AFTAB', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 1, 6, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (79, '79', 'AQIB RAZA', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (80, '80', 'DANIYAL SHAKEEL', '', 1, '0', '', '87654321', 'Karachi, Sindh', 1, 1, 2, 5, 0, 0, 0, 1, 0, 1,
        '0000-00-00 00:00:00', NULL),
       (88, '81', 'Ali', 'Aslam', 1, '544334543', 'a@gmail.com', '34223', 'fgdg', 2, 2, 4, 5, 67890, 0, NULL, 1, 1,
        NULL, '2023-09-23 03:33:54', NULL),
       (89, '82', 'Aslam O', 'Aleikum', 1, '41101', 'asl@gmail.com', '0', '34726357', 1, 1, 1, 5, 4666, 0, 1, 1,
        2147483647, NULL, '0000-00-00 00:00:00', NULL),
       (90, '2003', 'f test l test ', 'f test l test ', 1, '2147483647', 'syedtalha641@gmail.com', '2147483647',
        'address', 2, 1, 7, 6, 1000, 0, 0, 1, 1, 1, '2023-10-02 20:47:59', '2023-10-02 20:49:13'),
       (91, 'empid', 'f', 'l', 2, '42401', 'gmail', '2147483647', 'ad', 2, 2, 1, 0, 1000, 0, 0, 1, 1, 1,
        '2023-10-02 21:46:25', '2023-10-02 21:50:00'),
       (92, 'empid1', 'f', 'l', 2, '42401', 'gmail', '2147483647', 'ad', 2, 2, 1, 0, 1000, 0, 0, 1, 1, NULL,
        '2023-10-02 21:50:16', NULL),
       (93, 'empid2', 'f', 'l', 2, '42401', 'gmail', '2147483647', 'ad', 2, 2, 1, 0, 1000, 0, 0, 1, 1, NULL,
        '2023-10-02 21:52:20', NULL),
       (94, 'empid3', 'f', 'l', 2, '42401-6487231-1', 'gmail', '03152155245', 'ad', 2, 2, 1, 0, 1000, 0, 0, 1, 1, NULL,
        '2023-10-02 21:53:07', NULL),
       (95, 'empid4', 'ff', 'll', 1, '1111111111111', 'syedtalha641@gmail.com', '03152155245',
        'l6 st32 sector L-1 Surjani karachi pak', 2, 2, 1, 0, 60000, 0, 0, 1, 1, NULL, '2023-10-02 21:54:49', NULL);

--
-- Triggers `user_profile`
--
DELIMITER $$
CREATE TRIGGER `userprofile_update_trigger`
    BEFORE UPDATE
    ON `user_profile`
    FOR EACH ROW
BEGIN
    Set @User = (select CONCAT(u.username, ' (', u.id, ')') from user u where u.id = NEW.updated_by);
    SET @GUser = CONCAT(@User, '');

    IF NEW.firstname != OLD.firstname THEN
        Set @GUser = CONCAT(@GUser, ' Has changed First Name record from ', OLD.firstname, ' To ', NEW.firstname);
    END IF;

    IF NEW.lastname != OLD.lastname THEN
        Set @GUser = CONCAT(@GUser, ' And changed Last Name record Name from ', OLD.lastname, ' To ', NEW.lastname);
    END IF;

    IF NEW.gender != OLD.gender THEN
        Set @gen = (select CONCAT(g.Gender, ' (', g.id, ')') from tbl_gender g WHERE g.id = OLD.gender);
        Set @GUser = CONCAT(@GUser, ' And changed Gender record from ', @gen, ' To ',
                            (select CONCAT(g.Gender, ' (', g.id, ')') from tbl_gender g WHERE g.id = NEW.gender));
    END IF;

    IF NEW.CNIC != OLD.CNIC THEN
        Set @GUser = CONCAT(@GUser, ' And changed CNIC record from ', OLD.CNIC, ' To ', NEW.CNIC);
    END IF;

    IF NEW.Gmail != OLD.Gmail THEN
        Set @GUser = CONCAT(@GUser, ' And changed Gmail record from ', OLD.Gmail, ' To ', NEW.Gmail);
    END IF;

    IF NEW.contact != OLD.contact THEN
        Set @GUser = CONCAT(@GUser, ' And changed Contact record from ', OLD.contact, ' To ', NEW.contact);
    END IF;

    IF NEW.address != OLD.address THEN
        Set @GUser = CONCAT(@GUser, ' And changed Address record Name from ', OLD.address, ' To ', NEW.address);
    END IF;

    IF NEW.Designation_Id != OLD.Designation_Id THEN
        Set @desi = (select CONCAT(d.designation_name, ' (', d.id, ')')
                     from designation d
                     WHERE d.id = OLD.Designation_Id);
        Set @GUser =
                CONCAT(@GUser, ' And changed Designatiom record ', NEW.id, ' of Designation from ', @desi, ' To ',
                       (select CONCAT(d.designation_name, ' (', d.id, ')')
                        from designation d
                        WHERE d.id = NEW.Designation_Id));
    END IF;

    IF NEW.payscale_id != OLD.payscale_id THEN
        Set @pay = (select CONCAT(ps.pay_name, ' (', ps.id, ')') from pay_scale ps WHERE ps.id = OLD.payscale_id);
        Set @GUser = CONCAT(@GUser, ' And changed PayScale record from ', @pay, ' To ',
                            (select CONCAT(ps.pay_name, ' (', ps.id, ')')
                             from pay_scale ps
                             WHERE ps.id = NEW.payscale_id));
    END IF;

    IF NEW.shift_id != OLD.shift_id THEN
        Set @shft = (select CONCAT(s.shift_name, ' (', s.id, ')') from shift s WHERE s.id = OLD.shift_id);
        Set @GUser = CONCAT(@GUser, ' And changed Shift record from ', @shft, ' To ',
                            (select CONCAT(s.shift_name, ' (', s.id, ')')
                             from shift s
                             WHERE s.id = NEW.shift_id));
    END IF;

    IF NEW.workingDays != OLD.workingDays THEN
        Set @GUser =
                CONCAT(@GUser, ' And changed Working Days record Name from ', OLD.workingDays, ' To ', NEW.workingDays);
    END IF;

    IF NEW.salary != OLD.salary THEN
        Set @GUser = CONCAT(@GUser, ' And changed Salary record Name from ', OLD.salary, ' To ', NEW.salary);
    END IF;

    insert into logs(Log_Description, TBL_Name, created_by, created_on) value (@GUser, 'UserProfile', NEW.id, CURRENT_TIMESTAMP);

END
$$
DELIMITER ;

--
-- Indexes for dumped tables
--

--
-- Indexes for table `advance`
--
ALTER TABLE `advance`
    ADD PRIMARY KEY (`id`),
    ADD KEY `advance_ibfk_1` (`Up_Id`),
    ADD KEY `advance_ibfk_2` (`created_by`),
    ADD KEY `advance_ibfk_3` (`updated_by`);

--
-- Indexes for table `attendance`
--
ALTER TABLE `attendance`
    ADD PRIMARY KEY (`id`),
    ADD KEY `created_by` (`created_by`),
    ADD KEY `updated_by` (`updated_by`),
    ADD KEY `Device_Id` (`DeviceNo`);

--
-- Indexes for table `designation`
--
ALTER TABLE `designation`
    ADD PRIMARY KEY (`id`),
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
    ADD PRIMARY KEY (`id`),
    ADD KEY `holidays_ibfk_1` (`created_by`),
    ADD KEY `holidays_ibfk_2` (`updated_by`);

--
-- Indexes for table `logs`
--
ALTER TABLE `logs`
    ADD PRIMARY KEY (`id`);

--
-- Indexes for table `payroll`
--
ALTER TABLE `payroll`
    ADD PRIMARY KEY (`id`),
    ADD KEY `UserP_Id` (`UserP_Id`),
    ADD KEY `Designation_Id` (`Designation_Id`),
    ADD KEY `Shift_Id` (`Shift_Id`),
    ADD KEY `Pay_Id` (`Pay_Id`),
    ADD KEY `created_by` (`created_by`),
    ADD KEY `updated_by` (`updated_by`),
    ADD KEY `payroll_ibfk_7` (`PayRoll_Type`);

--
-- Indexes for table `payroll_type`
--
ALTER TABLE `payroll_type`
    ADD PRIMARY KEY (`id`);

--
-- Indexes for table `pay_scale`
--
ALTER TABLE `pay_scale`
    ADD PRIMARY KEY (`id`),
    ADD KEY `updated_by` (`updated_by`),
    ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `permission`
--
ALTER TABLE `permission`
    ADD PRIMARY KEY (`id`),
    ADD KEY `created_by` (`created_by`),
    ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `permission_assign`
--
ALTER TABLE `permission_assign`
    ADD PRIMARY KEY (`id`),
    ADD KEY `Permission_Id` (`Permission_Id`),
    ADD KEY `Role_Id` (`Role_Id`),
    ADD KEY `updated_by` (`updated_by`),
    ADD KEY `created_by` (`created_by`);

--
-- Indexes for table `role`
--
ALTER TABLE `role`
    ADD PRIMARY KEY (`id`),
    ADD KEY `created_by` (`created_by`),
    ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `shift`
--
ALTER TABLE `shift`
    ADD PRIMARY KEY (`id`),
    ADD KEY `created_by` (`created_by`),
    ADD KEY `updated_by` (`updated_by`);

--
-- Indexes for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
    ADD PRIMARY KEY (`id`);

--
-- Indexes for table `user`
--
ALTER TABLE `user`
    ADD PRIMARY KEY (`id`),
    ADD UNIQUE KEY `username` (`username`),
    ADD KEY `UserP_Id` (`UserP_Id`),
    ADD KEY `Role_Id` (`Role_Id`);

--
-- Indexes for table `user_profile`
--
ALTER TABLE `user_profile`
    ADD PRIMARY KEY (`id`),
    ADD UNIQUE KEY `Employee_Id` (`Employee_Id`),
    ADD KEY `Designation_Id` (`Designation_Id`),
    ADD KEY `shift_id` (`shift_id`),
    ADD KEY `user_profile_ibfk_3` (`payscale_id`),
    ADD KEY `user_profile_ibfk_4` (`gender`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `advance`
--
ALTER TABLE `advance`
    MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 23;

--
-- AUTO_INCREMENT for table `attendance`
--
ALTER TABLE `attendance`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 949;

--
-- AUTO_INCREMENT for table `designation`
--
ALTER TABLE `designation`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 6;

--
-- AUTO_INCREMENT for table `devicetable`
--
ALTER TABLE `devicetable`
    MODIFY `Device_Id` int(11) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 2;

--
-- AUTO_INCREMENT for table `holidays`
--
ALTER TABLE `holidays`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 14;

--
-- AUTO_INCREMENT for table `logs`
--
ALTER TABLE `logs`
    MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 162;

--
-- AUTO_INCREMENT for table `payroll`
--
ALTER TABLE `payroll`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT;

--
-- AUTO_INCREMENT for table `payroll_type`
--
ALTER TABLE `payroll_type`
    MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 3;

--
-- AUTO_INCREMENT for table `pay_scale`
--
ALTER TABLE `pay_scale`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 3;

--
-- AUTO_INCREMENT for table `permission`
--
ALTER TABLE `permission`
    MODIFY `id` int(11) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 2;

--
-- AUTO_INCREMENT for table `permission_assign`
--
ALTER TABLE `permission_assign`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 2;

--
-- AUTO_INCREMENT for table `role`
--
ALTER TABLE `role`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 2;

--
-- AUTO_INCREMENT for table `shift`
--
ALTER TABLE `shift`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 10;

--
-- AUTO_INCREMENT for table `tbl_gender`
--
ALTER TABLE `tbl_gender`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 4;

--
-- AUTO_INCREMENT for table `user`
--
ALTER TABLE `user`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 2;

--
-- AUTO_INCREMENT for table `user_profile`
--
ALTER TABLE `user_profile`
    MODIFY `id` int(10) NOT NULL AUTO_INCREMENT,
    AUTO_INCREMENT = 96;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `advance`
--
ALTER TABLE `advance`
    ADD CONSTRAINT `advance_ibfk_1` FOREIGN KEY (`Up_Id`) REFERENCES `user_profile` (`id`),
    ADD CONSTRAINT `advance_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `advance_ibfk_3` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `attendance`
--
ALTER TABLE `attendance`
    ADD CONSTRAINT `attendance_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `attendance_ibfk_3` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `designation`
--
ALTER TABLE `designation`
    ADD CONSTRAINT `designation_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `designation_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `holidays`
--
ALTER TABLE `holidays`
    ADD CONSTRAINT `holidays_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `holidays_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `payroll`
--
ALTER TABLE `payroll`
    ADD CONSTRAINT `payroll_ibfk_1` FOREIGN KEY (`UserP_Id`) REFERENCES `user_profile` (`id`),
    ADD CONSTRAINT `payroll_ibfk_2` FOREIGN KEY (`Designation_Id`) REFERENCES `designation` (`id`),
    ADD CONSTRAINT `payroll_ibfk_3` FOREIGN KEY (`Shift_Id`) REFERENCES `shift` (`id`),
    ADD CONSTRAINT `payroll_ibfk_4` FOREIGN KEY (`Pay_Id`) REFERENCES `pay_scale` (`id`),
    ADD CONSTRAINT `payroll_ibfk_5` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `payroll_ibfk_6` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `payroll_ibfk_7` FOREIGN KEY (`PayRoll_Type`) REFERENCES `payroll_type` (`id`);

--
-- Constraints for table `pay_scale`
--
ALTER TABLE `pay_scale`
    ADD CONSTRAINT `pay_scale_ibfk_1` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `pay_scale_ibfk_2` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `permission`
--
ALTER TABLE `permission`
    ADD CONSTRAINT `permission_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `permission_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `permission_assign`
--
ALTER TABLE `permission_assign`
    ADD CONSTRAINT `permission_assign_ibfk_2` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`id`),
    ADD CONSTRAINT `permission_assign_ibfk_3` FOREIGN KEY (`Permission_Id`) REFERENCES `permission` (`id`),
    ADD CONSTRAINT `permission_assign_ibfk_4` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`id`),
    ADD CONSTRAINT `permission_assign_ibfk_5` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `permission_assign_ibfk_6` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `role`
--
ALTER TABLE `role`
    ADD CONSTRAINT `role_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `role_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `shift`
--
ALTER TABLE `shift`
    ADD CONSTRAINT `shift_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `user` (`id`),
    ADD CONSTRAINT `shift_ibfk_2` FOREIGN KEY (`updated_by`) REFERENCES `user` (`id`);

--
-- Constraints for table `user`
--
ALTER TABLE `user`
    ADD CONSTRAINT `user_ibfk_1` FOREIGN KEY (`UserP_Id`) REFERENCES `user_profile` (`id`),
    ADD CONSTRAINT `user_ibfk_2` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`id`),
    ADD CONSTRAINT `user_ibfk_3` FOREIGN KEY (`Role_Id`) REFERENCES `role` (`id`);

--
-- Constraints for table `user_profile`
--
ALTER TABLE `user_profile`
    ADD CONSTRAINT `user_profile_ibfk_1` FOREIGN KEY (`Designation_Id`) REFERENCES `designation` (`id`),
    ADD CONSTRAINT `user_profile_ibfk_2` FOREIGN KEY (`shift_id`) REFERENCES `shift` (`id`),
    ADD CONSTRAINT `user_profile_ibfk_3` FOREIGN KEY (`payscale_id`) REFERENCES `pay_scale` (`id`),
    ADD CONSTRAINT `user_profile_ibfk_4` FOREIGN KEY (`gender`) REFERENCES `tbl_gender` (`id`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT = @OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS = @OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION = @OLD_COLLATION_CONNECTION */;
