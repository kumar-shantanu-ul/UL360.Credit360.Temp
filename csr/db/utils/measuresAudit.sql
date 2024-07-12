SET serveroutput on format truncated
SET lin 200
SET echo off
SET verify off
SET heading on
SET feedback off
SET pagesize 500

EXEC dbms_output.put_line('Find measure conversions on which different client have different conversions');
EXEC dbms_output.put_line('so at least one is probably wrong!');

COLUMN description format a30
COLUMN name format a30

SELECT mc.description, MAX(mc.A), MIN(mc.A),
    m.name, m.description,
    CASE WHEN MAX(mc.A)-(1/Min(mc.A)) < 0.00001 THEN 'yes' ELSE ' ' END reciprocal
FROM csr.measure_conversion mc
JOIN csr.measure m
    ON mc.measure_sid = m.measure_sid
WHERE m.description != 'Euros' -- these aren't expected to be consistent, quite likely null
AND m.description != 'USD'     -- these aren't expected to be consistent, quite likely null
AND m.description != 'GBP'     -- these aren't expected to be consistent, quite likely null
GROUP BY mc.description, m.name, m.description
HAVING MAX(mc.A)-MIN(mc.A) > 0.0001
ORDER BY m.description;

EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('');
EXEC dbms_output.put_line('Find std measure conversions which are not the reciprocal of their');
EXEC dbms_output.put_line('reciprocal conversions!');

COLUMN measureA format a30
COLUMN measureB format a30

SELECT
    smc1.description measureA, smc1.std_measure_conversion_id measureA_id, smc1.a,
    smc2.description measureB, smc2.std_measure_conversion_id measureB_id, smc2.a, smc1.a*smc2.a
FROM csr.std_measure_conversion smc1
JOIN csr.std_measure_conversion smc2
    ON regexp_like(smc1.description, '1\s*/\s*' || smc2.description)
WHERE smc1.a*smc2.a > 1.000001
OR smc1.a*smc2.a   < 0.999999;





exit
