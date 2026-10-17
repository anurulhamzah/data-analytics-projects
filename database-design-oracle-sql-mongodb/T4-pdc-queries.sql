--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T4-pdc-queries.sql

-- Assignment 2 Task 4

--Student ID: [removed]
--Student Name: Akhmad Fauzi Nurulhamzah

/* Comments for your marker:




*/

-- ENSURE that your SQL code is formatted and has a semicolon (;)
-- at the end of every statement. When marked this will be run as
-- a script.

/*
(a)
*/

-- List doctor (provider) that specialize in 'PAEDIATRIC DENTISTRY'
SELECT 
    p.provider_code, 
    p.provider_title || '. ' || p.provider_fname || ' ' || p.provider_lname AS provider_name  -- concatenate the name and provider_title
FROM 
    provider p
    JOIN 
    specialisation s 
    ON p.spec_id = s.spec_id
WHERE 
    upper(s.spec_name) = upper('PAEDIATRIC DENTISTRY')  -- make sure the string format is the same
ORDER BY 
    p.provider_lname, -- 1st order
    p.provider_fname, -- 2nd order
    p.provider_code;

/*
(b)
*/

--List services that are more expensive than the average standard fee
SELECT 
    service_code, 
    service_desc, 
    LPAD(TO_CHAR(service_stdfee, '$9999.99'), 12, ' ') AS standard_fee -- formated stdfee
FROM 
    service
WHERE 
    service_stdfee > (
        SELECT
            AVG(service_stdfee)
        FROM
            service
        ) -- calculate the average service stdfee
ORDER BY 
    service_stdfee DESC,
    service_code;

/*
(c)
*/

-- Find the most expensive appointment(s) in terms of total cost
SELECT
    a.appt_no,
    TO_CHAR(a.appt_datetime, 'YYYY-MM-DD HH24:MI') AS appt_datetime,
    a.patient_no, 
    p.patient_fname || ' ' || p.patient_lname AS patient_name, 
    LPAD(TO_CHAR( --right align with LPAD
        SUM(NVL(ap.apptserv_fee, 0) + NVL(ap.apptserv_itemcost, 0)), --Calculates the total cost of the appointment; Use NVL to replace null with 0
         '$9999.99'), 12, ' ') AS total_cost --change format to $ 00.00
FROM 
    appointment a
    JOIN 
    patient p ON a.patient_no = p.patient_no
    JOIN 
    appt_serv ap ON a.appt_no = ap.appt_no
GROUP BY 
    a.appt_no,
    a.appt_datetime,
    a.patient_no,
    p.patient_fname,
    p.patient_lname
HAVING -- where the total cost = max total cost in all appointment
    SUM(
        NVL(ap.apptserv_fee, 0) + NVL(ap.apptserv_itemcost, 0)) = (
            SELECT 
                MAX(
                    SUM(NVL(apptserv_fee, 0) + NVL(apptserv_itemcost, 0))
                ) 
            FROM 
                appointment
                LEFT JOIN 
                appt_serv USING (appt_no)
            GROUP BY 
                appt_no
    )
ORDER BY 
    total_cost DESC,
    a.appt_no;


/*
(d) 
*/

    -- Calculate the difference between the average actual service fee and the standard fee
SELECT
    s.service_code,
    s.service_desc,
    LPAD(TO_CHAR(s.service_stdfee, '$9999.99'), 12, ' ') AS standard_fee,
    LPAD(TO_CHAR(AVG(ap.apptserv_fee), '$9999.99'), 12, ' ') AS avg_charged_fee, -- calculate average charged
    LPAD(TO_CHAR(AVG(ap.apptserv_fee) - s.service_stdfee, '$9999.99'), 12, ' ') AS service_fee_differential  -- service different
FROM
    service s
    JOIN
    appt_serv ap ON s.service_code = ap.service_code
GROUP BY
    s.service_code,
    s.service_desc,
    s.service_stdfee
ORDER BY
    service_fee_differential DESC;  -- Sorting by service fee differential


/*
(e) get pencentage of patient doing follow up
*/
SELECT 
    p.patient_no, 
    p.patient_fname || ' ' || p.patient_lname AS patientname, -- generate patient name 
    TO_NUMBER(TO_CHAR(SYSDATE, 'YYYY')) - TO_NUMBER(TO_CHAR(patient_dob, 'YYYY')) AS currentage, -- Calculate the current age (current date - birthdate)
    COUNT(a.appt_no) AS numappts, -- Count total appointments
    
    CASE -- Calculate percentage of follow-up appointment
        WHEN COUNT(a.appt_no) = 0 THEN '-'
        ELSE TO_CHAR(
            (COUNT(CASE WHEN
                a.appt_prior_apptno IS NOT NULL THEN 1 END) / COUNT(a.appt_no)) * 100, '999.99') || '%'
    END AS followups
FROM 
    patient p
    LEFT JOIN 
    appointment a ON p.patient_no = a.patient_no
GROUP BY 
    p.patient_no,
    p.patient_fname,
    p.patient_lname,
    p.patient_dob
ORDER BY 
    p.patient_no;



/*
(f)
*/

-- create calculation for appointments between 5th September 2024, 9 AM and 15th September 2024, 5 PM
SELECT 
    pr.provider_code AS pcode,
    CASE  -- Number of appointments within the specified period
        WHEN COUNT(a.appt_no) = 0 THEN '-' 
        ELSE TO_CHAR(COUNT(a.appt_no)) 
    END AS numberappts,

    CASE  -- Total fees charged within the specified period
        WHEN SUM(ap.apptserv_fee) IS NULL THEN '-' 
        ELSE TO_CHAR(SUM(ap.apptserv_fee), '$9999.99') 
    END AS totalfees,
    
    CASE -- Total quantity of items used within the specified period
        WHEN SUM(asi.as_item_quantity) IS NULL THEN '-' 
        ELSE TO_CHAR(SUM(asi.as_item_quantity)) 
    END AS noitems
FROM 
    provider pr
    LEFT JOIN 
    appointment a ON pr.provider_code = a.provider_code
    AND a.appt_datetime BETWEEN TO_TIMESTAMP('2024-09-05 09:00', 'YYYY-MM-DD HH24:MI') 
    AND TO_TIMESTAMP('2024-09-15 17:00', 'YYYY-MM-DD HH24:MI')
    LEFT JOIN 
    apptservice_item asi ON a.appt_no = asi.appt_no
    LEFT JOIN 
    appt_serv ap ON a.appt_no = ap.appt_no
GROUP BY 
    pr.provider_code,
    pr.provider_title,
    pr.provider_fname,
    pr.provider_lname
ORDER BY 
    pr.provider_code;