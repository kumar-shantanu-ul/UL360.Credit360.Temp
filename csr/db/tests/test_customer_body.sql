CREATE OR REPLACE PACKAGE BODY csr.test_customer_pkg AS

/* private Setup, TearDown helpers */

PROCEDURE DeleteDataCreatedDuringTests
AS
BEGIN
	-- delete data that could have been created during tests, in case of previously aborted/failed runs.
	DELETE FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	DELETE FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;

	DELETE FROM aspen2.translated
	 WHERE application_sid = security.security_pkg.getApp;
	DELETE FROM aspen2.translation
	 WHERE application_sid = security.security_pkg.getApp;
	--null;
END;


/* Fixture Setup, TearDown */

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	--dbms_output.put_line('SetUpFixture');
	security.user_pkg.logonadmin(in_site_name);
	DeleteDataCreatedDuringTests;
END;

PROCEDURE TearDownFixture AS
BEGIN 
	--dbms_output.put_line('TearDownFixture');
	DeleteDataCreatedDuringTests;
END;


/* Per test Setup, TearDown */

PROCEDURE SetUp AS
BEGIN
	--dbms_output.put_line('SetUp');
	NULL;
END;

PROCEDURE TearDown AS
BEGIN
	--dbms_output.put_line('TearDown');
	NULL;
END;


/* Tests */

PROCEDURE Test01SetSysTranslation AS
	m_count			NUMBER;
	v_maxid			NUMBER;

	v_logid			NUMBER;
	v_logid_data	NUMBER;
	v_isdel			NUMBER;
	v_description	VARCHAR2(4000);
	v_orig			VARCHAR2(4000);
	v_tran			VARCHAR2(4000);
	v_oldtran		VARCHAR2(4000);
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(0, m_count, 'Unexpected stad');

	customer_pkg.SetSystemTranslation(
		in_original			=>	'a',
		in_lang				=>	'en',
		in_translation		=>	'b',
		in_delete			=>	0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing stad');

	SELECT MAX(sys_translations_audit_log_id)
	  INTO v_maxid
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT sys_translations_audit_log_id, description
	  INTO v_logid, v_description
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	SELECT sys_translations_audit_log_id, is_delete, original, translation, old_translation
	  INTO v_logid_data, v_isdel, v_orig, v_tran, v_oldtran
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	unit_test_pkg.AssertAreEqual(v_logid, v_logid_data, 'Unmatched logid');
	unit_test_pkg.AssertAreEqual('Original string created and translation created for lang en.', v_description, 'Unexpected description');

	unit_test_pkg.AssertAreEqual(0, v_isdel, 'Unexpected is_delete');
	unit_test_pkg.AssertAreEqual('a', v_orig, 'Unexpected original');
	unit_test_pkg.AssertAreEqual('b', v_tran, 'Unexpected translation');
	unit_test_pkg.AssertIsNull(v_oldtran, 'Unexpected old_translation');

	SELECT COUNT(*)
	 INTO m_count
	 FROM aspen2.translated
	 WHERE translated = 'b';
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing translated');

	SELECT COUNT(*)
	 INTO m_count
	 FROM aspen2.translation
	 WHERE original = 'a';
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing translation');
END;

PROCEDURE Test02UpdSysTranslation AS
	m_count			NUMBER;
	v_maxid			NUMBER;

	v_logid			NUMBER;
	v_logid_data	NUMBER;
	v_isdel			NUMBER;
	v_description	VARCHAR2(4000);
	v_orig			VARCHAR2(4000);
	v_tran			VARCHAR2(4000);
	v_oldtran		VARCHAR2(4000);
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(1, m_count, 'Unexpected stad');

	SELECT COUNT(*)
	 INTO m_count
	 FROM aspen2.translated
	 WHERE translated = 'b';
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing translated');

	SELECT COUNT(*)
	 INTO m_count
	 FROM aspen2.translation
	 WHERE original = 'a';
	unit_test_pkg.AssertAreEqual(1, m_count, 'Missing translation');

	customer_pkg.SetSystemTranslation(
		in_original			=>	'a',
		in_lang				=>	'en',
		in_translation		=>	'c',
		in_delete			=>	0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(2, m_count, 'Missing stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(2, m_count, 'Missing stad');

	SELECT MAX(sys_translations_audit_log_id)
	  INTO v_maxid
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT sys_translations_audit_log_id, description
	  INTO v_logid, v_description
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	SELECT sys_translations_audit_log_id, is_delete, original, translation, old_translation
	  INTO v_logid_data, v_isdel, v_orig, v_tran, v_oldtran
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	unit_test_pkg.AssertAreEqual(v_logid, v_logid_data, 'Unmatched logid');
	unit_test_pkg.AssertAreEqual('Translation updated for lang en.', v_description, 'Unexpected description');

	unit_test_pkg.AssertAreEqual(0, v_isdel, 'Unexpected is_delete');
	unit_test_pkg.AssertAreEqual('a', v_orig, 'Unexpected original');
	unit_test_pkg.AssertAreEqual('c', v_tran, 'Unexpected translation');
	unit_test_pkg.AssertAreEqual('b', v_oldtran, 'Unexpected oldtranslation');

END;

PROCEDURE Test03CreSysTranslation AS
	m_count			NUMBER;
	v_maxid			NUMBER;

	v_logid			NUMBER;
	v_logid_data	NUMBER;
	v_isdel			NUMBER;
	v_description	VARCHAR2(4000);
	v_orig			VARCHAR2(4000);
	v_tran			VARCHAR2(4000);
	v_oldtran		VARCHAR2(4000);
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(2, m_count, 'Unexpected stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(2, m_count, 'Unexpected stad');

	DELETE FROM aspen2.translated
	 WHERE application_sid = security.security_pkg.getApp
	   AND translated = 'c';

	customer_pkg.SetSystemTranslation(
		in_original			=>	'a',
		in_lang				=>	'en',
		in_translation		=>	'd',
		in_delete			=>	0
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(3, m_count, 'Missing stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(3, m_count, 'Missing stad');

	SELECT MAX(sys_translations_audit_log_id)
	  INTO v_maxid
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT sys_translations_audit_log_id, description
	  INTO v_logid, v_description
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	SELECT sys_translations_audit_log_id, is_delete, original, translation, old_translation
	  INTO v_logid_data, v_isdel, v_orig, v_tran, v_oldtran
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	unit_test_pkg.AssertAreEqual(v_logid, v_logid_data, 'Unmatched logid');
	unit_test_pkg.AssertAreEqual('Translation created for lang en.', v_description, 'Unexpected description');

	unit_test_pkg.AssertAreEqual(0, v_isdel, 'Unexpected is_delete');
	unit_test_pkg.AssertAreEqual('a', v_orig, 'Unexpected original');
	unit_test_pkg.AssertAreEqual('d', v_tran, 'Unexpected translation');
	unit_test_pkg.AssertIsNull(v_oldtran, 'Unexpected oldtranslation');
END;

PROCEDURE Test04DelSysTranslation AS
	m_count			NUMBER;
	v_maxid			NUMBER;

	v_logid			NUMBER;
	v_logid_data	NUMBER;
	v_isdel			NUMBER;
	v_description	VARCHAR2(4000);
	v_orig			VARCHAR2(4000);
	v_tran			VARCHAR2(4000);
	v_oldtran		VARCHAR2(4000);
BEGIN
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(3, m_count, 'Unexpected stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(3, m_count, 'Unexpected stad');

	customer_pkg.SetSystemTranslation(
		in_original			=>	'a',
		in_lang				=>	'en',
		in_translation		=>	'c',
		in_delete			=>	1
	);

	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(4, m_count, 'Missing stal');
	SELECT COUNT(*)
	  INTO m_count
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp;
	unit_test_pkg.AssertAreEqual(4, m_count, 'Missing stad');

	SELECT MAX(sys_translations_audit_log_id)
	  INTO v_maxid
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp;

	SELECT sys_translations_audit_log_id, description
	  INTO v_logid, v_description
	  FROM sys_translations_audit_log
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	SELECT sys_translations_audit_log_id, is_delete, original, translation, old_translation
	  INTO v_logid_data, v_isdel, v_orig, v_tran, v_oldtran
	  FROM sys_translations_audit_data
	 WHERE app_sid = security.security_pkg.getApp
	   AND sys_translations_audit_log_id = v_maxid;

	unit_test_pkg.AssertAreEqual(v_logid, v_logid_data, 'Unmatched logid');
	unit_test_pkg.AssertAreEqual('Original string and all the translations for it have been deleted.', v_description, 'Unexpected description');

	unit_test_pkg.AssertAreEqual(1, v_isdel, 'Unexpected is_delete');
	unit_test_pkg.AssertAreEqual('a', v_orig, 'Unexpected original');
	unit_test_pkg.AssertIsNull(v_tran, 'Unexpected translation');
	unit_test_pkg.AssertIsNull(v_oldtran, 'Unexpected oldtranslation');

END;

PROCEDURE CheckAudit(
	in_audit_type_id	NUMBER,
	in_description		VARCHAR2,
	in_expected_value	NUMBER
)
AS
	v_audited_value		NUMBER;
BEGIN
	SELECT param_1
	  INTO v_audited_value
	  FROM audit_log 
	 WHERE app_sid = security.security_pkg.getApp
	   AND audit_type_id = in_audit_type_id
	   AND description = in_description
	ORDER BY audit_date DESC
	FETCH FIRST 1 ROWS ONLY;

	unit_test_pkg.AssertIsTrue(v_audited_value = in_expected_value, 'Expected '|| in_description ||' audited_value = '||in_expected_value||', got '||v_audited_value);
	--dbms_output.put_line('Expected '|| in_description ||' audited_value = '||in_expected_value||', got '||v_audited_value);
END;

END test_customer_pkg;
/
