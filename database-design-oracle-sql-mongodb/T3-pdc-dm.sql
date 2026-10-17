--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T3-pdc-dm.sql

-- Assignment 2 Task 3

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
-- Create Sequence for emergency_contact table, patient table and appointment table

-- Drop and Create Sequence for EMERGENCY_CONTACT
DROP SEQUENCE emergency_contact_seq;

CREATE SEQUENCE emergency_contact_seq
    START WITH 100
    INCREMENT BY 5;

-- Drop and Create Sequence for PATIENT
DROP SEQUENCE patient_seq;

CREATE SEQUENCE patient_seq
    START WITH 100
    INCREMENT BY 5;

-- Drop and Create Sequence for APPOINTMENT
DROP SEQUENCE appointment_seq;

CREATE SEQUENCE appointment_seq
    START WITH 100
    INCREMENT BY 5;

COMMIT;
/*
(b) 
*/
--insert new EC contact, new patient and new appointment

-- 1: Insert Jonathan Robey as Emergency Contact
INSERT INTO emergency_contact VALUES (
    emergency_contact_seq.NEXTVAL,
     'Jonathan',
     'Robey',
     '0412523122'
     );

COMMIT;

-- 2: insert new patient
--    a. Laura as a Patient

INSERT INTO patient VALUES (
    patient_seq.NEXTVAL,
    'Laura',
    'Robey',
    '30 Sunrise Drive',
    'Saint Helena',
    'VIC',
    '3088',
    TO_DATE('2012-05-02', 'YYYY-MM-DD'),
    '0449724333',
    'laura@gmail.com',
        (
            SELECT
                ec_id
            FROM
                emergency_contact
            WHERE
                upper(ec_fname) = upper('Jonathan') 
                AND upper(ec_lname) = upper('Robey')
        )
);

--    b. Lachlan as a Patient
INSERT INTO patient VALUES (
    patient_seq.NEXTVAL,
    'Lachlan',
    'Robey',
    '30 Sunrise Drive',
    'Saint Helena',
    'VIC',
    '3088',
    TO_DATE('2012-05-02', 'YYYY-MM-DD'),
    '0449724444',
    'lachlan@gmail.com',
        (
            SELECT
                ec_id
            FROM
                emergency_contact
            WHERE
                upper(ec_fname) = upper('Jonathan') 
                AND upper(ec_lname) = upper('Robey')
        )
);

COMMIT;

-- 3: Insert Appointment
--    a. Laura's appointment

INSERT INTO appointment VALUES (
        appointment_seq.NEXTVAL,
        TO_DATE('2024-10-04 15:30', 'YYYY-MM-DD HH24:MI'),
        2,
        'S',
            (
                SELECT
                    patient_no
                FROM
                    patient
                WHERE
                    upper(patient_fname) = upper('Laura')
                    AND upper(patient_lname) = upper('Robey')
            ), -- Patient number
            (
                SELECT
                    provider_code
                FROM
                    provider
                WHERE
                    upper(provider_fname) = upper('Bruce')
                    AND upper(provider_lname) = upper('STRIPLIN')
            ), -- Provider code
        6,
        NULL
);

--    b. Lachan's appointment

INSERT INTO appointment VALUES (
        appointment_seq.NEXTVAL,
        TO_DATE('2024-10-04 16:00', 'YYYY-MM-DD HH24:MI'),
        2,
        'S',
            (
                SELECT
                    patient_no
                FROM
                    patient
                WHERE
                    upper(patient_fname) = upper('Lachlan')
                    AND upper(patient_lname) = upper('Robey')
            ), -- Patient number
            (
                SELECT
                    provider_code
                FROM
                    provider
                WHERE
                    upper(provider_fname) = upper('Bruce')
                    AND upper(provider_lname) = upper('STRIPLIN')
            ), -- Provider code
        6,
        NULL
);

COMMIT;


/*
(c)
*/
--Insert Follow-up Appointment for Lachlan

INSERT INTO appointment VALUES (
    appointment_seq.NEXTVAL, 
    TO_DATE('2024-10-14 16:00', 'YYYY-MM-DD HH24:MI'),
    2, 
    'S', 
    (
        SELECT
            patient_no
        FROM
            patient
        WHERE
            upper(patient_fname) = upper('Lachlan')
            AND upper(patient_lname) = upper('Robey')
    ), -- Patient number
    (
        SELECT
            provider_code
        FROM
            provider
        WHERE
            upper(provider_fname) = upper('Bruce')
            AND upper(provider_lname) = upper('STRIPLIN')
    ), -- Provider code
    14,
    (
        SELECT
            appt_no
        FROM
            appointment
        WHERE
            patient_no = (
                SELECT
                    patient_no
                FROM
                    patient
                WHERE
                    upper(patient_fname) = upper('Lachlan')
                    AND upper(patient_lname) = upper('Robey')
            )
    ) -- Prior appointment number
);


COMMIT;

/*
(d)
*/

-- Reschedule Follow-up Appointment for Lachlan
UPDATE appointment
SET appt_datetime = TO_DATE('2024-10-18 16:00', 'YYYY-MM-DD HH24:MI')
WHERE appt_datetime = TO_DATE('2024-10-14 16:00', 'YYYY-MM-DD HH24:MI')
  AND patient_no = (
    SELECT
        patient_no 
            FROM
                patient
            WHERE 
                upper(patient_fname) = upper('Lachlan')
                AND upper(patient_lname) = upper('Robey')
    );

COMMIT;

/*
(e)
*/
--Delete Appointments for Dr. Bruce between 14th October and 18th October 2024
DELETE FROM appointment
WHERE 
    provider_code = (
        SELECT
            provider_code
        FROM
            provider
        WHERE 
            upper(provider_fname) = upper('Bruce')
            AND upper(provider_lname) = upper('STRIPLIN') -- select provider name
    )
AND 
    appt_datetime BETWEEN TO_DATE('2024-10-14', 'YYYY-MM-DD') -- select date between
    AND TO_DATE('2024-10-18', 'YYYY-MM-DD');

COMMIT;
