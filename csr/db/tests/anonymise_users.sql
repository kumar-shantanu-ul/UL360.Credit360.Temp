set serveroutput on
set echo off

VARIABLE sec_grant_present NUMBER;

BEGIN
	SELECT COUNT(*)
	  INTO :sec_grant_present
	  FROM dba_tab_privs
     WHERE table_name = 'USER_TABLE'
	   AND grantee = 'CSR'
       AND privilege = 'UPDATE'
	   AND owner = 'SECURITY';

	IF :sec_grant_present = 0 THEN
		EXECUTE IMMEDIATE 'GRANT UPDATE ON security.user_table TO csr';
	END IF;
	
	EXECUTE IMMEDIATE 'CREATE TYPE csr.test_user_sids IS VARRAY(100) OF NUMBER';
END;
/

@@test_anonymise_users_pkg
@@test_anonymise_users_body

BEGIN
	csr.unit_test_pkg.RunTests('csr.test_anonymise_users_pkg', :bv_site_name);
END;
/

BEGIN
	IF :sec_grant_present = 0 THEN
		EXECUTE IMMEDIATE 'REVOKE UPDATE ON security.user_table FROM csr';
	END IF;
END;
/

DROP PACKAGE csr.test_anonymise_users_pkg;
DROP TYPE csr.test_user_sids FORCE;

@@../unit_test_pkg
@@../unit_test_body

set echo on
