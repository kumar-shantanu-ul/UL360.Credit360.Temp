set serveroutput on
set echo off

@@disable_pkg
@@test_enable_pkg

@@disable_body
@@test_enable_body

BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tables
		  WHERE owner = 'OWL' AND table_name = 'CLIENT_MODULE')
	LOOP
		EXECUTE IMMEDIATE 'GRANT UPDATE ON owl.client_module TO csr';
	END LOOP;
END;
/

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_enable_pkg', :bv_site_name);
END;
/
--REVOKE UPDATE ON owl.client_module FROM csr;
BEGIN
	FOR r IN (
		SELECT 1
		  FROM all_tables
		  WHERE owner = 'OWL' AND table_name = 'CLIENT_MODULE')
	LOOP
		EXECUTE IMMEDIATE 'REVOKE UPDATE ON owl.client_module FROM csr';
	END LOOP;
END;
/

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_enable_pkg;
DROP PACKAGE csr.disable_pkg;

-- Revoke invalidates this package.
@../audit_body

set echo on