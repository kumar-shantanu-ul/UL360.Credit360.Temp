set serveroutput on
set echo off

--@@xxx_pkg
--@@xxx_body

BEGIN
	--Pass
	dbms_output.put_line('Pass with '||:bv_site_name);

	--Fail
	-- Uncomment to verify failure stops if running via RunAll.sql.
	--csr.unit_test_pkg.TestFail('failtest with '||v_site);
END;
/

-- No need to keep the test fixture package after tests have ran
--DROP PACKAGE csr.xxx_pkg;

set echo on
