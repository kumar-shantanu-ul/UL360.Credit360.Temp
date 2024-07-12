set serveroutput on
set echo off

--GRANT EXECUTE ON csr.meter_processing_job_pkg TO csr;

@@test_meter_processing_job_pkg
sho err
@@test_meter_processing_job_body
sho err

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_meter_processing_job_pkg', :bv_site_name);
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_meter_processing_job_pkg;

set echo on
