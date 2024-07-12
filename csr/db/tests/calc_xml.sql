set serveroutput on
set echo off

@@test_calc_xml_pkg
@@test_calc_xml_body

-- grant access to csr so that unit_test_pkg can call it
GRANT EXECUTE ON cms.test_calc_xml_pkg to csr;

@@create_rag_user

BEGIN
	csr.unit_test_pkg.RunTests('cms.test_calc_xml_pkg', :bv_site_name);
END;
/

DROP PACKAGE cms.test_calc_xml_pkg;

set echo on

