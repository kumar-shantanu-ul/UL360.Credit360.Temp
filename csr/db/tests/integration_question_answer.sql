set serveroutput on
set echo off


@@test_integration_question_answer_pkg
@@test_integration_question_answer_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_integration_question_answer_pkg', :bv_site_name);
END;
/

DROP PACKAGE csr.test_integration_question_answer_pkg;

set echo on

