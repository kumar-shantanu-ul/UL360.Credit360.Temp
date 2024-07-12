set serveroutput on
set echo off

CREATE OR REPLACE TYPE csr.t_test_case AS OBJECT (test_input VARCHAR2(255), test_output NUMBER(10));
/
CREATE OR REPLACE TYPE csr.t_test_cases AS TABLE OF t_test_case;
/

@@test_aspen2_utils_pkg
@@test_aspen2_utils_body

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_aspen2_utils_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_aspen2_utils_pkg;
DROP TYPE csr.t_test_cases;
DROP TYPE csr.t_test_case;

set echo on