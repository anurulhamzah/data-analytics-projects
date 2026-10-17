--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T2-pdc-insert.sql

-- Assignment 2 Task 2

--Student ID: [removed]
--Student Name: Akhmad Fauzi Nurulhamzah

/* Comments for your marker:

-- appointment length: appointment length as either S: short (30 minutes), T: standard (60 minutes) or L: long (2 hours)


*/


-- ENSURE that your SQL code is formatted and has a semicolon (;)
-- at the end of every statement. When marked this will be run as
-- a script.


-- Insert into APPOINTMENT

INSERT INTO appointment VALUES (
    1,
    TO_DATE('02/SEP/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    1,
    'S', /*short*/
    16,
    'END001',
    1,
    NULL
);

INSERT INTO appointment VALUES (
    2,
    TO_DATE('02/SEP/2024 09:30', 'DD/MM/YYYY HH24:MI'),
    1,
    'S', /*short*/
    9,
    'END001',
    6,
    NULL
);

INSERT INTO appointment VALUES (
    3,
    TO_DATE('02/SEP/2024 10:00', 'DD/MM/YYYY HH24:MI'),
    1,
    'T', /*standard*/
    15,
    'END001',
    6,
    NULL
);

INSERT INTO appointment VALUES (
    4,
    TO_DATE('02/SEP/2024 13:30', 'DD/MM/YYYY HH24:MI'),
    5,
    'S', /*short*/
    1,
    'ORS001',
    3,
    NULL
);

INSERT INTO appointment VALUES (
    5,
    TO_DATE('02/SEP/2024 14:00', 'DD/MM/YYYY HH24:MI'),
    5,
    'T', /*standard*/
    4,
    'ORS001',
    3,
    NULL
);

INSERT INTO appointment VALUES (
    6, 
    TO_DATE('05/SEP/2024 09:00', 'DD/MM/YYYY HH24:MI'), 
    8,
    'S', /*short*/
    5,
    'PED001',
    5,
    NULL
);

INSERT INTO appointment VALUES (
    7,
    TO_DATE('05/SEP/2024 09:30', 'DD/MM/YYYY HH24:MI'),
    8,
    'L', /*long*/
    8,
    'PED001',
    5,
    NULL
);

INSERT INTO appointment VALUES (
    8,
    TO_DATE('05/SEP/2024 11:30', 'DD/MM/YYYY HH24:MI'),
    8,
    'L', /*long*/
    7,
    'PED001',
    5,
    NULL
);

INSERT INTO appointment VALUES (
    9,
    TO_DATE('05/SEP/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    13,
    'L', /*long*/
    11,
    'PRO001',
    9,
    NULL
);

INSERT INTO appointment VALUES (
    10,
    TO_DATE('05/SEP/2024 11:00', 'DD/MM/YYYY HH24:MI'),
    13,
    'L', /*long*/
    12,
    'PRO001',
    9,
    NULL
);

INSERT INTO appointment VALUES (
    11,
    TO_DATE('09/SEP/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    1,
    'T', /*standard*/
    15,
    'END001',
    10,
    3
);

INSERT INTO appointment VALUES (
    12,
    TO_DATE('09/SEP/2024 10:00', 'DD/MM/YYYY HH24:MI'),
    1,
    'L', /*long*/
    9,
    'END001',
    10,
    2
);

INSERT INTO appointment VALUES (
    13,
    TO_DATE('09/SEP/2024 10:00', 'DD/MM/YYYY HH24:MI'),
    8,
    'L', /*long*/
    5,
    'ORT001',
    7,
    6
);

INSERT INTO appointment VALUES (
    14,
    TO_DATE('14/SEP/2024 09:00', 'DD/MM/YYYY HH24:MI'),
    8,
    'T', /*standard*/
    6,
    'ORT001',
    12,
    NULL
);

INSERT INTO appointment VALUES (
    15,
    TO_DATE('14/SEP/2024 10:00', 'DD/MM/YYYY HH24:MI'),
    8,
    'T', /*standard*/
    5,
    'ORT001',
    12,
    8
);

INSERT INTO appointment VALUES (
    16,
    TO_DATE('14/SEP/2024 11:00', 'DD/MM/YYYY HH24:MI'),
    8,
    'T', /*standard*/
    14,
    'ORT001',
    12,
    NULL
);

COMMIT;




-- Insert into APPT_SERV

INSERT INTO appt_serv VALUES (
    1,
    'D001',
    60.00,
    80.00
);

INSERT INTO appt_serv VALUES (
    2,
    'RC01',
    200.00,
    151.00
);

INSERT INTO appt_serv VALUES (
    3,
    'X002',
    85.00,
    80.00
);

INSERT INTO appt_serv VALUES (
    4,
    'EX01',
    185.00,
    20.00
);

INSERT INTO appt_serv VALUES (
    5,
    'EX03',
    500.00,
    20.00
);

INSERT INTO appt_serv VALUES (
    6,
    'D001',
    60.00,
    80.00
);

INSERT INTO appt_serv VALUES (
    7,
    'P001',
    100.00,
    60.00
);

INSERT INTO appt_serv VALUES (
    8,
    'D003',
    60.00,
    356.00
);

INSERT INTO appt_serv VALUES (
    9,
    'DC03',
    1200.00,
    36.00
);

INSERT INTO appt_serv VALUES (
    10,
    'DV03',
    200.00,
    60.00
);

INSERT INTO appt_serv VALUES (
    11,
    'RC02',
    100.00,
    128.00
);

INSERT INTO appt_serv VALUES (
    12,
    'RC03',
    240.00, 
    128.00
);

INSERT INTO appt_serv VALUES (
    13,
    'OT02',
    3000.00,
    15.00
);

INSERT INTO appt_serv VALUES (
    14,
    'OT01',
    520.00,
    6.00
);

INSERT INTO appt_serv VALUES (
    15,
    'D001',
    60.00,
    15.00
);

INSERT INTO appt_serv VALUES (
    16,
    'OT01',
    520.00,
    15.00
);

COMMIT;




-- Insert into APPTSERVICE_ITEM

INSERT INTO apptservice_item VALUES (
    1,
    1, 
    'D001',
    20,
    1
);

INSERT INTO apptservice_item VALUES (
    2,
    1,
    'D001',
    21,
    1
);

INSERT INTO apptservice_item VALUES (
    3,
    2,
    'RC01',
    1,
    5
);

INSERT INTO apptservice_item VALUES (
    4,
    2,
    'RC01',
    2,
    3
);

INSERT INTO apptservice_item VALUES (
    5,
    2,
    'RC01',
    3,
    3
);

INSERT INTO apptservice_item VALUES (
    6,
    2,
    'RC01',
    4,
    3
);

INSERT INTO apptservice_item VALUES (
    7,
    2,
    'RC01',
    5,
    1
);

INSERT INTO apptservice_item VALUES (
    8,
    2,
    'RC01',
    8,
    1
);

INSERT INTO apptservice_item VALUES (
    9,
    2,
    'RC01',
    7,
    1
);

INSERT INTO apptservice_item VALUES (
    10,
    2,
    'RC01',
    6,
    1
);

INSERT INTO apptservice_item VALUES (
    11,
    2,
    'RC01',
    16,
    1
);

INSERT INTO apptservice_item VALUES (
    12,
    3,
    'X002',
    20,
    1
);

INSERT INTO apptservice_item VALUES (
    13,
    3,
    'X002',
    21,
    1
);

INSERT INTO apptservice_item VALUES (
    14,
    4,
    'EX01',
    14,
    4
);

INSERT INTO apptservice_item VALUES (
    15,
    4,
    'EX01',
    15,
    4
);

INSERT INTO apptservice_item VALUES (
    16,
    5,
    'EX03',
    14,
    4
);

INSERT INTO apptservice_item VALUES (
    17,
    5,
    'EX03',
    15,
    4
);

INSERT INTO apptservice_item VALUES (
    18,
    6,
    'D001',
    20,
    1
);

INSERT INTO apptservice_item VALUES (
    19,
    6,
    'D001',
    21,
    1
);

INSERT INTO apptservice_item VALUES (
    20,
    7,
    'P001',
    22,
    1
);

INSERT INTO apptservice_item VALUES (
    21,
    7,
    'P001',
    23,
    1
);

INSERT INTO apptservice_item VALUES (
    22,
    8,
    'D003',
    16,
    3
);

INSERT INTO apptservice_item VALUES (
    23,
    8,
    'D003',
    17,
    2
);

INSERT INTO apptservice_item VALUES (
    24,
    8,
    'D003',
    18,
    1
);

INSERT INTO apptservice_item VALUES (
    25,
    8,
    'D003',
    19,
    1
);

INSERT INTO apptservice_item VALUES (
    26,
    9,
    'DC03',
    9,
    2
);

INSERT INTO apptservice_item VALUES (
    27,
    9,
    'DC03',
    10,
    1
);

INSERT INTO apptservice_item VALUES (
    28,
    9,
    'DC03',
    11,
    1
);

INSERT INTO apptservice_item VALUES (
    29,
    9,
    'DC03',
    12,
    1
);

INSERT INTO apptservice_item VALUES (
    30,
    9,
    'DC03',
    13,
    1
);

INSERT INTO apptservice_item VALUES (
    31,
    10, 
    'DV03',
    22,
    1
);

INSERT INTO apptservice_item VALUES (
    32,
    10,
    'DV03',
    23,
    1
);

INSERT INTO apptservice_item VALUES (
    33,
    13,
    'OT02',
    14,
    3
);

INSERT INTO apptservice_item VALUES (
    34,
    13,
    'OT02',
    15,
    3
);

INSERT INTO apptservice_item VALUES (
    35,
    14,
    'OT01',
    14,
    3
);


COMMIT;
