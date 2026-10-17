--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T5-pdc-mods.sql

-- Assignment 2 Task 5

--Student ID: [removed]
--Student Name: Akhmad Fauzi Nurulhamzah

/* Comments for your marker:

5.a add new column to record the total number of appointments for each patient with countting every apointment based on patient uniq number (patient_no)
5.b to modify the database so that each patient can have multiple emergency contacts we need to make bridging table since the relation of emergency contact and patient will be many-to-many
    the idea is to create PATIENT_CONTACT table as bridging, in addition, we will remove ec_id from PATIENT table.
5.c create table to accomodate nurse training log (NURSE_TRAINING), we will add nurse_no as refference of nurse trainer and trainee

*/

-- ENSURE that your SQL code is formatted and has a semicolon (;)
-- at the end of every statement. When marked this will be run as
-- a script.

/*
(a)
*/

-- add new column
ALTER TABLE patient ADD (
    total_appointments NUMBER
);


COMMENT ON COLUMN patient.total_appointments IS
    'Total number of appointments for the patient.'
;

-- update information
UPDATE patient p
SET total_appointments = (
    SELECT
        COUNT(*)
    FROM
        appointment a
    WHERE
        a.patient_no = p.patient_no
);

COMMIT;


-- check
SELECT 
    patient_no,
    patient_fname,
    patient_lname,
    total_appointments
FROM 
    patient;

DESC patient;



/*
(b) 
*/

DROP TABLE patient_contact; -- Include this for safe re-runs

-- create new table to bridge the new relationship between patient and emergency contact (many-to-many)

CREATE TABLE patient_contact (
    pc_id NUMBER(6) PRIMARY KEY, -- add uniq number for patient contact
    patient_no NUMBER(4) NOT NULL, -- FK from patient table
    ec_id NUMBER(4) NOT NULL, -- FK from emergency contact table
    CONSTRAINT fk_patient FOREIGN KEY (patient_no) REFERENCES patient(patient_no),
    CONSTRAINT fk_contact FOREIGN KEY (ec_id) REFERENCES emergency_contact(ec_id)
);

-- create sequence for pk
DROP SEQUENCE patient_contact_seq;

CREATE SEQUENCE patient_contact_seq
    START WITH 1
    INCREMENT BY 1;


--insert into new table
INSERT INTO patient_contact (pc_id, patient_no, ec_id)
SELECT 
    patient_contact_seq.NEXTVAL, -- Generate unique pc_id
    patient_no,
    ec_id
FROM 
    patient

SELECT * FROM patient_contact

-- Drop the ec_id column from patient table
ALTER TABLE patient DROP COLUMN ec_id;

COMMIT;



-- Verify data migration
SELECT * FROM patient_contact;

-- Verify table structure
DESC patient_contact;
DESC patient; -- remove ec_id


/*
(c)
*/

DROP TABLE nurse_training; -- drop for safe re-runs

CREATE TABLE nurse_training (
    tr_id NUMBER (3) PRIMARY KEY, -- add uniq id for each training log
    tr_trainee_no NUMBER(3) NOT NULL, -- Foreign key referencing the trainee nurse
    tr_trainer_no NUMBER(3) NOT NULL, -- Foreign key referencing the trainer nurse
    tr_Start DATE NOT NULL,    -- Start time of the training
    tr_End DATE NOT NULL,    -- End time of the training
    tr_desc VARCHAR2(100), -- Details about the training
    CONSTRAINT fk_trainee FOREIGN KEY (tr_trainee_no) REFERENCES nurse(nurse_no),
    CONSTRAINT fk_trainer FOREIGN KEY (tr_trainer_no) REFERENCES nurse(nurse_no)
);
COMMENT ON COLUMN nurse_training.tr_desc IS 'Name of training, incuding status: initial/refresher.';

COMMIT;

-- Validate nurse_training table structure
DESC nurse_training;


-- create sequence for nurse training
DROP SEQUENCE nurse_training_seq;

CREATE SEQUENCE nurse_training_seq
    START WITH 1
    INCREMENT BY 1;

-- Insert data into nurse_training
INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    8,
    12,
    TO_DATE('27/07/2024 10:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('27/07/2024 16:00', 'DD/MM/YYYY HH24:MI'),
    'Decontamination of scaling instruments'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    8,
    6,
    TO_DATE('04/08/2024 11:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('04/08/2024 13:00', 'DD/MM/YYYY HH24:MI'),
    'Initial examination data entry'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    8,
    6,
    TO_DATE('04/08/2024 14:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('04/08/2024 15:00', 'DD/MM/YYYY HH24:MI'),
    'Patient record keeping'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    8,
    12,
    TO_DATE('08/08/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('08/08/2024 11:00', 'DD/MM/YYYY HH24:MI'),
    'Maintaining dental x-ray machine'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    7,
    12,
    TO_DATE('27/07/2024 13:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('27/07/2024 16:00', 'DD/MM/YYYY HH24:MI'),
    'Scaling instrument maintenance'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    7,
    12,
    TO_DATE('08/08/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('08/08/2024 11:00', 'DD/MM/YYYY HH24:MI'),
    'Cleaning dental x-ray machine'
);

INSERT INTO nurse_training VALUES (
    nurse_training_seq.NEXTVAL,
    7,
    6,
    TO_DATE('28/08/2024 14:00', 'DD/MM/YYYY HH24:MI'),
    TO_DATE('28/08/2024 15:00', 'DD/MM/YYYY HH24:MI'),
    'Scaling instrument maintenance - refreshment'
);

COMMIT;

SELECT * FROM nurse_training