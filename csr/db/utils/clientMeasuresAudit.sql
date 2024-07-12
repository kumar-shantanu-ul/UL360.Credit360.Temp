SET serveroutput on format truncated
SET lin 200
SET echo off
SET verify off
SET heading on
SET feedback off
SET pagesize 500

EXEC security.user_pkg.logonAdmin('&&1');

EXEC dbms_output.put_line('Client');
COLUMN name format a30;
COLUMN host format a40;
COLUMN in_use format a6;

SELECT name, host, app_sid
FROM csr.customer;


EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('Client measures without standard measure conversion set up');

COLUMN name format a20;
COLUMN description format a20;

SELECT m.measure_sid, name, description,
    CASE WHEN dm.measure_sid = m.measure_sid THEN 'yes' ELSE ' ' END in_use
FROM csr.measure m
LEFT JOIN (
    SELECT DISTINCT measure_sid
    FROM csr.ind
) dm
ON m.measure_sid = dm.measure_sid
WHERE std_measure_conversion_id IS NULL
AND custom_field IS NULL;



EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('Client measures with the same name/description as standard measure conversions,');
EXEC dbms_output.put_line('but no std measure conversion set up.');

SELECT m.measure_sid, m.name, m.description,
    CASE WHEN dm.measure_sid = m.measure_sid THEN 'yes' ELSE ' ' END in_use
FROM csr.measure m
JOIN csr.std_measure_conversion smc
    ON m.description = smc.description
LEFT JOIN (
    SELECT DISTINCT measure_sid
    FROM csr.ind
) dm
ON m.measure_sid = dm.measure_sid
WHERE m.std_measure_conversion_id IS NULL
AND m.custom_field IS NULL;



EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('Client measures conversions which aren''t the reciprocal of their reciprocal conversion');

COLUMN measureA format a30
COLUMN measureB format a30

SELECT
    mc1.description measureA, mc1.std_measure_conversion_id measureA_id, mc1.a,
    mc2.description measureB, mc2.std_measure_conversion_id measureB_id, mc2.a, mc1.a*mc2.a
FROM csr.measure_conversion mc1
JOIN csr.measure_conversion mc2
    ON regexp_like(mc1.description, '1\s*/\s*' || mc2.description)
WHERE mc1.a*mc2.a > 1.000001
OR mc1.a*mc2.a   < 0.999999;


exit
