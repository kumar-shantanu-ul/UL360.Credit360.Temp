CREATE OR REPLACE PACKAGE BODY csr.test_alert_user_pkg AS

v_users						security.security_pkg.T_SID_IDS;

PROCEDURE TRACE(in_msg VARCHAR2)
AS
BEGIN
	NULL;
	dbms_output.put_line(in_msg);
END;

PROCEDURE RemoveSids(
	v_sids					security_pkg.T_SID_IDS
)
AS
BEGIN
	IF v_sids.COUNT > 0 THEN
		FOR i IN v_sids.FIRST..v_sids.LAST
		LOOP
			security.securableobject_pkg.deleteso(security_pkg.getact, v_sids(i));
		END LOOP;
	END IF;
END;

PROCEDURE CleanUp
AS
BEGIN
	FOR r in (
		SELECT customer_alert_type_id 
		  FROM cms_alert_type
		 WHERE lookup_key = 'RAG_ALERT_TEST'
	) LOOP
		alert_pkg.DeleteTemplate(in_customer_alert_type_id => r.customer_alert_type_id);
	END LOOP;

	FOR r in (
		SELECT csr_user_sid
		  FROM csr_user
		 WHERE full_name LIKE 'test.alert_user.user%'
	) LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.csr_user_sid);
	END LOOP;

	RemoveSids(v_users);

	disable_pkg.DisableAlert(in_std_alert_type_id => csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM);
	disable_pkg.DisableAlert(in_std_alert_type_id => csr_data_pkg.ALERT_USER_INACTIVE_REMINDER);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
	CleanUp;

	v_users(1) := unit_test_pkg.GetOrCreateUser('test.alert_user.user1');
	v_users(2) := unit_test_pkg.GetOrCreateUser('test.alert_user.user2.nosend');
	v_users(3) := unit_test_pkg.GetOrCreateUser('test.alert_user.user3.notenabled');

	UPDATE csr_user
	   SET send_alerts = 0
	 WHERE csr_user_sid = v_users(2);

	security.user_pkg.DisableAccount(
		in_act_id			=> security_pkg.GetAct,
		in_user_sid			=> v_users(3)
	);

END;

PROCEDURE TearDownFixture 
AS
BEGIN
	CleanUp;
END;


PROCEDURE TestGetUserInactiveSysAlerts
AS
	v_test_alert_id					NUMBER := csr_data_pkg.ALERT_USER_INACTIVE_SYSTEM;
	v_customer_alert_type_id		customer_alert_type.customer_alert_type_id%TYPE;

	v_out_cur						SYS_REFCURSOR;
	v_cur_alert_id					user_inactive_sys_alert.user_inactive_sys_alert_id%TYPE;
	v_cur_app_sid					csr_user.app_sid%TYPE;
	v_cur_csr_user_sid				csr_user.csr_user_sid%TYPE;
	v_cur_full_name					csr_user.full_name%TYPE;
	v_cur_friendly_name				csr_user.friendly_name%TYPE;
	v_cur_email						csr_user.email%TYPE;
	v_cur_user_name					csr_user.user_name%TYPE;

	v_user_sid	NUMBER;
	v_user_sid2	NUMBER;
	v_count		NUMBER;
	v_count2	NUMBER;
BEGIN
	enable_pkg.EnableAlert(in_alert_id => v_test_alert_id);

	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM std_alert_type sat
	  JOIN customer_alert_type cat ON cat.std_alert_type_id = sat.std_alert_type_id
	 WHERE sat.std_alert_type_id = v_test_alert_id;


	-- Trigger a run with no alerts expected

	-- force run


	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	TRACE('v_customer_alert_type_id='||v_customer_alert_type_id);
	
	-- internally does csr.alert_pkg.BeginStdAlertBatchRun();
	csr_user_pkg.GetUserInactiveSysAlerts(
		out_cur	=> v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_alert_id, v_cur_app_sid, v_cur_csr_user_sid, v_cur_full_name, v_cur_friendly_name, v_cur_email, v_cur_user_name;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected none');

	csr.alert_pkg.EndStdAlertBatchRun(
		in_std_alert_type_id => v_test_alert_id
	);


	-- Trigger a run with an ALERT_USER_INACTIVE_SYSTEM
	SELECT MIN(csr_user_sid)
	  INTO v_user_sid2
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user1';

	csr_user_pkg.RaiseUserInactiveSysAlert(
		in_user_sid				=> v_user_sid2, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid2
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user2.nosend';

	csr_user_pkg.RaiseUserInactiveSysAlert(
		in_user_sid				=> v_user_sid2, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user3.notenabled';

	csr_user_pkg.RaiseUserInactiveSysAlert(
		in_user_sid				=> v_user_sid, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT count(*)
	  INTO v_count
	  FROM user_inactive_sys_alert;
	TRACE('user_inactive_sys_alerts '||v_count);

	-- force run
	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	
	csr_user_pkg.GetUserInactiveSysAlerts(
		out_cur	=> v_out_cur
	);

	SELECT count(*)
	  INTO v_count
	  FROM user_inactive_sys_alert
	 WHERE sent_dtm IS NULL;
	TRACE('user_inactive_sys_alerts awaiting send '||v_count);

/*
	SELECT count(*)
	  INTO v_count
	  FROM temp_csr_user;
	TRACE('temp_csr_user='||v_count);
	SELECT count(*)
	INTO v_count
	FROM csr_user cu
	JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
	WHERE cu.app_sid IN (
			SELECT app_sid
				FROM customer_alert_type
				WHERE std_alert_type_id = v_test_alert_id
		)
	AND cu.send_alerts = 1
	AND ut.account_enabled = 1;
	TRACE('csr_users='||v_count);
	SELECT count(*)
		INTO v_count
		FROM csr.alert_batch_run abr
		JOIN customer_alert_type cat ON abr.customer_alert_type_id = cat.customer_alert_type_id AND abr.app_sid = cat.app_sid
		WHERE cat.std_alert_type_id = v_test_alert_id;		
	TRACE('minus csr_users='||v_count);
	SELECT count(*)
		INTO v_count
		FROM csr.temp_alert_batch_run;
	TRACE('temp_alert_batch_run='||v_count);
*/

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_alert_batch_run
	 WHERE std_alert_type_id = v_test_alert_id;
	SELECT COUNT(*)
	  INTO v_count2
	  FROM csr_user cu
	  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
	 WHERE cu.send_alerts = 1;
	TRACE('v_count='||v_count);
	TRACE('v_count2='||v_count2);
	unit_test_pkg.AssertAreEqual(v_count2, v_count, 'Expected only the users marked as wanting alerts');

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_alert_id, v_cur_app_sid, v_cur_csr_user_sid, v_cur_full_name, v_cur_friendly_name, v_cur_email, v_cur_user_name;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
		TRACE(
			'* alert_id='||v_cur_alert_id||
			'* app_id='||v_cur_app_sid||
			'  csr_user_sid='||v_cur_csr_user_sid||
			'  full_name='||v_cur_full_name
		);
		unit_test_pkg.AssertAreEqual(v_user_sid, v_cur_csr_user_sid, 'Expected match');
	END LOOP;
	TRACE(v_count||' alert(s) found');
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one');

	csr.alert_pkg.EndStdAlertBatchRun(
		in_std_alert_type_id => v_test_alert_id
	);

END;


PROCEDURE TestGetUserInactiveReminderAlerts
AS
	v_test_alert_id					NUMBER := csr_data_pkg.ALERT_USER_INACTIVE_REMINDER;
	v_customer_alert_type_id		customer_alert_type.customer_alert_type_id%TYPE;

	v_out_cur						SYS_REFCURSOR;
	v_cur_alert_id					user_inactive_sys_alert.user_inactive_sys_alert_id%TYPE;
	v_cur_app_sid					csr_user.app_sid%TYPE;
	v_cur_csr_user_sid				csr_user.csr_user_sid%TYPE;
	v_cur_full_name					csr_user.full_name%TYPE;
	v_cur_friendly_name				csr_user.friendly_name%TYPE;
	v_cur_email						csr_user.email%TYPE;
	v_cur_user_name					csr_user.user_name%TYPE;

	v_user_sid	NUMBER;
	v_user_sid2	NUMBER;
	v_count		NUMBER;
	v_count2	NUMBER;
BEGIN
	enable_pkg.EnableAlert(in_alert_id => v_test_alert_id);

	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM std_alert_type sat
	  JOIN customer_alert_type cat ON cat.std_alert_type_id = sat.std_alert_type_id
	 WHERE sat.std_alert_type_id = v_test_alert_id;


	-- Trigger a run with no alerts expected

	-- force run


	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	 TRACE('v_customer_alert_type_id='||v_customer_alert_type_id);
	
	-- internally does csr.alert_pkg.BeginStdAlertBatchRun();
	csr_user_pkg.GetUserInactiveReminderAlerts(
		out_cur	=> v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_alert_id, v_cur_app_sid, v_cur_csr_user_sid, v_cur_full_name, v_cur_friendly_name, v_cur_email, v_cur_user_name;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected none');

	csr.alert_pkg.EndStdAlertBatchRun(
		in_std_alert_type_id => v_test_alert_id
	);


	-- Trigger a run with an ALERT_USER_INACTIVE_REMINDER
	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user1';

	csr_user_pkg.RaiseUserInactiveReminderAlert(
		in_user_sid				=> v_user_sid, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid2
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user2.nosend';

	csr_user_pkg.RaiseUserInactiveReminderAlert(
		in_user_sid				=> v_user_sid2, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid2
	  FROM csr_user
	 WHERE full_name = 'test.alert_user.user3.notenabled';

	csr_user_pkg.RaiseUserInactiveReminderAlert(
		in_user_sid				=> v_user_sid2, 
		in_app_sid				=> security_pkg.GetApp
	);

	SELECT count(*)
	  INTO v_count
	  FROM user_inactive_rem_alert;
	TRACE('user_inactive_rem_alerts '||v_count);

	-- force run
	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_customer_alert_type_id;
	
	csr_user_pkg.GetUserInactiveReminderAlerts(
		out_cur	=> v_out_cur
	);

	SELECT count(*)
	  INTO v_count
	  FROM user_inactive_rem_alert
	 WHERE sent_dtm IS NULL;
	TRACE('user_inactive_rem_alerts awaiting send '||v_count);

/*
	SELECT count(*)
	  INTO v_count
	  FROM temp_csr_user;
	TRACE('temp_csr_user='||v_count);
	SELECT count(*)
	INTO v_count
	FROM csr_user cu
	JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
	WHERE cu.app_sid IN (
			SELECT app_sid
				FROM customer_alert_type
				WHERE std_alert_type_id = v_test_alert_id
		)
	AND cu.send_alerts = 1
	AND ut.account_enabled = 1;
	TRACE('csr_users='||v_count);
	SELECT count(*)
		INTO v_count
		FROM csr.alert_batch_run abr
		JOIN customer_alert_type cat ON abr.customer_alert_type_id = cat.customer_alert_type_id AND abr.app_sid = cat.app_sid
		WHERE cat.std_alert_type_id = v_test_alert_id;		
	TRACE('minus csr_users='||v_count);
	SELECT count(*)
		INTO v_count
		FROM csr.temp_alert_batch_run;
	TRACE('temp_alert_batch_run='||v_count);
*/

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_alert_batch_run
	 WHERE std_alert_type_id = v_test_alert_id;
	SELECT COUNT(*)
	  INTO v_count2
	  FROM csr_user cu
	  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
	 WHERE cu.send_alerts = 1;
	TRACE('v_count='||v_count);
	TRACE('v_count2='||v_count2);
	unit_test_pkg.AssertAreEqual(v_count2, v_count, 'Expected only the users marked as wanting alerts');

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_alert_id, v_cur_app_sid, v_cur_csr_user_sid, v_cur_full_name, v_cur_friendly_name, v_cur_email, v_cur_user_name;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
		TRACE(
			'* alert_id='||v_cur_alert_id||
			'* app_id='||v_cur_app_sid||
			'  csr_user_sid='||v_cur_csr_user_sid||
			'  full_name='||v_cur_full_name
		);
		unit_test_pkg.AssertAreEqual(v_user_sid, v_cur_csr_user_sid, 'Expected match');
	END LOOP;
	TRACE(v_count||' alert(s) found');
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one');

	csr.alert_pkg.EndStdAlertBatchRun(
		in_std_alert_type_id => v_test_alert_id
	);

END;


END test_alert_user_pkg;
/
