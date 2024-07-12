set serveroutput on
set echo off

-- Have to do this setup outside of the csr pkg to avoid having to modify permissions
BEGIN
	INSERT INTO cms.oracle_tab(oracle_table, oracle_schema)
	VALUES ('RAGTABLE1','RAG');

	security.user_pkg.logonadmin(:bv_site_name);
	INSERT INTO cms.tab (tab_sid, oracle_schema, oracle_table, managed, auto_registered, cms_editor, issues, 
		is_view, show_in_company_filter, is_basedata, show_in_product_filter, storage_location
	)
	VALUES (1,'RAG','RAGTABLE1', 0,0,0,0, 0,0,0,0, 'sl');
	security.user_pkg.logonadmin();
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/


@@disable_pkg
@@test_alert_user_pkg
@@disable_body
@@test_alert_user_body
BEGIN
	csr.unit_test_pkg.RunTests('csr.test_alert_user_pkg', :bv_site_name);
END;
/


-- Have to do this teardown outside of the csr pkg to avoid having to modify permissions
BEGIN
	DELETE FROM cms.tab
	 WHERE oracle_table = 'RAGTABLE1';
	DELETE FROM cms.oracle_tab
	 WHERE oracle_table = 'RAGTABLE1';
END;
/

DROP PACKAGE csr.test_alert_user_pkg;
DROP PACKAGE csr.disable_pkg;

set echo on

