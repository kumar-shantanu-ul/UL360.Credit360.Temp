CREATE OR REPLACE PACKAGE BODY csr.test_scheduled_import_pkg AS

v_site_name					VARCHAR2(200);
v_new_message_id			NUMBER(10);
v_long_message				CLOB;

PROCEDURE SetUp
AS
BEGIN
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	FOR i IN 1 .. 10000
	LOOP
		v_long_message := v_long_message || 'a';
	END LOOP;
END;

-- Write message tests
PROCEDURE WriteMsg_AcceptsLongMessages
AS
	v_message_length			NUMBER(10);
BEGIN
	v_new_message_id := NULL;
	BEGIN
		automated_export_import_pkg.WriteInstanceMessage(v_long_message, 'S', v_new_message_id);
	EXCEPTION
	  WHEN OTHERS THEN unit_test_pkg.TestFail('Unable to log long message');
	END;

	unit_test_pkg.AssertIsTrue(v_new_message_id > 0, 'Expected new message to be created');
	SELECT LENGTH(message)
	  INTO v_message_length
	  FROM auto_impexp_instance_msg
	 WHERE message_id = v_new_message_id;

	unit_test_pkg.AssertIsTrue(v_message_length = 10000, 'Expected new message to be stored in full');
END;

PROCEDURE TearDown
AS
BEGIN
	DELETE FROM auto_impexp_instance_msg
	 WHERE message_id = v_new_message_id;
END;


END test_scheduled_import_pkg;
/
