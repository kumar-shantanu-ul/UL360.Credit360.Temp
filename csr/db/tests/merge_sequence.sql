set serveroutput on
set echo off

--GRANT EXECUTE ON csr.merge_sequence_pkg TO csr;

CREATE SEQUENCE CSR.DBTEST_MERGE_SEQ;
CREATE TABLE CSR.DBTEST_MERGE(
   	MERGE1            NUMBER(10, 0),
   	MERGE2            NUMBER(10, 0),
    SEQ_ID            NUMBER(10, 0)
);

@@test_merge_sequence_pkg
sho err
@@test_merge_sequence_body
sho err

BEGIN
	-- Run all tests in package
	csr.unit_test_pkg.RunTests('csr.test_merge_sequence_pkg', :bv_site_name);
END;
/

DROP SEQUENCE CSR.DBTEST_MERGE_SEQ;
DROP TABLE CSR.DBTEST_MERGE;

-- No need to keep the test fixture package after tests have ran
DROP PACKAGE csr.test_merge_sequence_pkg;

set echo on
