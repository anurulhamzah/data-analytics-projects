--*****PLEASE ENTER YOUR DETAILS BELOW*****
--T6a-pdc-json.sql

-- Assignment 2 Task 6a

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

--SET PAGESIZE 200

SELECT JSON_OBJECT(
    '_id' VALUE a.appt_no,
    'datetime' VALUE TO_CHAR(a.appt_datetime, 'DD/MM/YYYY HH24:MI'),
    'provider_code' VALUE p.provider_code,
    'provider_name' VALUE p.provider_title 
    || ' ' 
    || p.provider_fname 
    || ' ' 
    || p.provider_lname, -- concatenate provider name and title
    'item_totalcost' VALUE SUM(i.item_stdcost * asi.as_item_quantity), -- calculate total itemcost (item_stdcost * quantity)
    'no_of_items' VALUE COUNT(DISTINCT asi.item_id), -- sum of item used
    'items' VALUE JSON_ARRAYAGG(
        JSON_OBJECT(
            'id' VALUE i.item_id,
            'desc' VALUE i.item_desc,
            'standardcost' VALUE i.item_stdcost,
            'quantity' VALUE asi.as_item_quantity
        )
    )
FORMAT JSON) AS json_document
FROM 
    appointment a
    JOIN apptservice_item asi ON a.appt_no = asi.appt_no
    JOIN item i ON asi.item_id = i.item_id
    JOIN provider p ON a.provider_code = p.provider_code
GROUP BY
    a.appt_no,
    a.appt_datetime,
    p.provider_code,
    p.provider_title,
    p.provider_fname,
    p.provider_lname
HAVING
    COUNT(asi.item_id) > 0; -- make sure item is not zero



