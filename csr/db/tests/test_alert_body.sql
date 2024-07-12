CREATE OR REPLACE PACKAGE BODY csr.test_alert_pkg AS

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
		 WHERE full_name LIKE 'test.alert.user%'
	) LOOP
		security.securableobject_pkg.deleteso(security_pkg.getact, r.csr_user_sid);
	END LOOP;

	RemoveSids(v_users);
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
	CleanUp;

	v_users(1) := unit_test_pkg.GetOrCreateUser('test.alert.user1');
	v_users(2) := unit_test_pkg.GetOrCreateUser('test.alert.user2.nosend');
	v_users(3) := unit_test_pkg.GetOrCreateUser('test.alert.user3.notenabled');

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

PROCEDURE TestActiveAlertMarkUnconfiguredCmsFieldChangeSent
AS
	v_count	NUMBER;

	v_tab_sid						cms_alert_type.tab_sid%TYPE;
	v_customer_alert_type_id		cms_alert_type.customer_alert_type_id%TYPE;
	v_description					cms_alert_type.description%TYPE;
	v_lookup_key					cms_alert_type.lookup_key%TYPE;
	v_alert_frame_id				alert_template.alert_frame_id%TYPE;
	v_send_type						alert_template.send_type%TYPE;
	v_reply_to_name					alert_template.reply_to_name%TYPE;
	v_reply_to_email				alert_template.reply_to_email%TYPE;
	v_deleted						cms_alert_type.deleted%TYPE;
	v_is_batched					cms_alert_type.is_batched%TYPE;
	v_out_customer_alert_type_id	cms_alert_type.customer_alert_type_id%TYPE;
	v_out_customer_alert_type_id2	cms_alert_type.customer_alert_type_id%TYPE;

	v_user_sid						cms_field_change_alert.user_sid%TYPE;
	v_version_number				cms_field_change_alert.version_number%TYPE;
BEGIN
	v_tab_sid:=1;
	v_description:='desc';
	v_lookup_key:='RAG_ALERT_TEST';
	v_send_type:='manual';
	v_reply_to_name:='rtn';
	v_reply_to_email:='rte';
	v_deleted:=0;
	v_is_batched:=0;
	
	SELECT MIN(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM alert_frame;
	
	flow_pkg.SaveCmsAlertTemplate(
		in_tab_sid						=> v_tab_sid,
		in_customer_alert_type_id		=> v_customer_alert_type_id,
		in_description					=> v_description,
		in_lookup_key					=> v_lookup_key,
		in_alert_frame_id				=> v_alert_frame_id,
		in_send_type					=> v_send_type,
		in_reply_to_name				=> v_reply_to_name,
		in_reply_to_email				=> v_reply_to_email,
		in_deleted						=> v_deleted,
		in_is_batched					=> v_is_batched,
		out_customer_alert_type_id		=> v_out_customer_alert_type_id
	);
	TRACE(v_out_customer_alert_type_id);

	UPDATE cms_alert_type
	   SET include_in_alert_setup = 1
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;

	alert_pkg.SetCmsAlert (
		in_tab_sid						=> v_tab_sid,
		in_lookup_key					=> v_lookup_key,
		in_description					=> v_description || ' cmsalert',
		in_subject						=> 'cmsalert subj',
		in_body_html					=> 'cmsalert body',
		--in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
		out_customer_alert_type_id		=> v_out_customer_alert_type_id2
	);
	TRACE(v_out_customer_alert_type_id2);
	unit_test_pkg.AssertAreEqual(v_out_customer_alert_type_id, v_out_customer_alert_type_id2, 'Expected same id');

	alert_pkg.MarkUnconfiguredCmsFieldChangeSent;

	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected count');


	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'test.alert.user1';

	alert_pkg.AddCmsFieldChangeAlert(
		in_lookup_key					=> v_lookup_key, 
		in_item_id						=> 101, 
		in_user_sid						=> v_user_sid, 
		in_version_number				=> 103
	);
	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE sent_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected count');

	alert_pkg.MarkUnconfiguredCmsFieldChangeSent;

	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one alert to be present');
	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE sent_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected the configured alerts to be still be marked as not sent');


	alert_pkg.DeleteTemplate(in_customer_alert_type_id => v_out_customer_alert_type_id);
END;

PROCEDURE TestInactiveAlertMarkUnconfiguredCmsFieldChangeSent
AS
	v_count	NUMBER;

	v_tab_sid						cms_alert_type.tab_sid%TYPE;
	v_customer_alert_type_id		cms_alert_type.customer_alert_type_id%TYPE;
	v_description					cms_alert_type.description%TYPE;
	v_lookup_key					cms_alert_type.lookup_key%TYPE;
	v_alert_frame_id				alert_template.alert_frame_id%TYPE;
	v_send_type						alert_template.send_type%TYPE;
	v_reply_to_name					alert_template.reply_to_name%TYPE;
	v_reply_to_email				alert_template.reply_to_email%TYPE;
	v_deleted						cms_alert_type.deleted%TYPE;
	v_is_batched					cms_alert_type.is_batched%TYPE;
	v_out_customer_alert_type_id	cms_alert_type.customer_alert_type_id%TYPE;
	v_out_customer_alert_type_id2	cms_alert_type.customer_alert_type_id%TYPE;

	v_user_sid						cms_field_change_alert.user_sid%TYPE;
	v_version_number				cms_field_change_alert.version_number%TYPE;
BEGIN
	v_tab_sid:=1;
	v_description:='desc';
	v_lookup_key:='RAG_ALERT_TEST';
	v_send_type:='inactive';
	v_reply_to_name:='rtn';
	v_reply_to_email:='rte';
	v_deleted:=0;
	v_is_batched:=0;
	
	SELECT MIN(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM alert_frame;
	
	flow_pkg.SaveCmsAlertTemplate(
		in_tab_sid						=> v_tab_sid,
		in_customer_alert_type_id		=> v_customer_alert_type_id,
		in_description					=> v_description,
		in_lookup_key					=> v_lookup_key,
		in_alert_frame_id				=> v_alert_frame_id,
		in_send_type					=> v_send_type,
		in_reply_to_name				=> v_reply_to_name,
		in_reply_to_email				=> v_reply_to_email,
		in_deleted						=> v_deleted,
		in_is_batched					=> v_is_batched,
		out_customer_alert_type_id		=> v_out_customer_alert_type_id
	);
	TRACE(v_out_customer_alert_type_id);

	UPDATE cms_alert_type
	   SET include_in_alert_setup = 1
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;

	alert_pkg.SetCmsAlert (
		in_tab_sid						=> v_tab_sid,
		in_lookup_key					=> v_lookup_key,
		in_description					=> v_description || ' cmsalert',
		in_subject						=> 'cmsalert subj',
		in_body_html					=> 'cmsalert body',
		--in_is_batched					IN	cms_alert_type.is_batched%TYPE DEFAULT 0,
		out_customer_alert_type_id		=> v_out_customer_alert_type_id2
	);
	TRACE(v_out_customer_alert_type_id2);
	unit_test_pkg.AssertAreEqual(v_out_customer_alert_type_id, v_out_customer_alert_type_id2, 'Expected same id');

	alert_pkg.MarkUnconfiguredCmsFieldChangeSent;

	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE sent_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected count');


	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'test.alert.user1';

	alert_pkg.AddCmsFieldChangeAlert(
		in_lookup_key					=> v_lookup_key, 
		in_item_id						=> 101, 
		in_user_sid						=> v_user_sid, 
		in_version_number				=> 104
	);
	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE sent_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected count');

	alert_pkg.MarkUnconfiguredCmsFieldChangeSent;

	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE version_number = 104;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one alert to be present');
	SELECT count(*) 
	  INTO v_count
	  FROM cms_field_change_alert
	 WHERE sent_dtm IS NULL;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected the inactive alert to marked as not sent');

	alert_pkg.DeleteTemplate(in_customer_alert_type_id => v_out_customer_alert_type_id);
END;

PROCEDURE TestGetBatchedCmsFieldChangeAlerts
AS
	v_tab_sid						cms_alert_type.tab_sid%TYPE;
	v_customer_alert_type_id		cms_alert_type.customer_alert_type_id%TYPE;
	v_description					cms_alert_type.description%TYPE;
	v_lookup_key					cms_alert_type.lookup_key%TYPE;
	v_alert_frame_id				alert_template.alert_frame_id%TYPE;
	v_send_type						alert_template.send_type%TYPE;
	v_reply_to_name					alert_template.reply_to_name%TYPE;
	v_reply_to_email				alert_template.reply_to_email%TYPE;
	v_deleted						cms_alert_type.deleted%TYPE;
	v_is_batched					cms_alert_type.is_batched%TYPE;
	v_out_customer_alert_type_id	cms_alert_type.customer_alert_type_id%TYPE;

	v_version_number				cms_field_change_alert.version_number%TYPE;

	v_out_cur						SYS_REFCURSOR;
	v_cur_cms_field_change_alert_id	cms_field_change_alert.cms_field_change_alert_id%TYPE;
	v_cur_user_sid					cms_field_change_alert.user_sid%TYPE;
	v_cur_item_id					cms_field_change_alert.item_id%TYPE;
	v_cur_customer_alert_type_id	cms_field_change_alert.customer_alert_type_id%TYPE;
	v_cur_version_number			cms_field_change_alert.version_number%TYPE;

	v_user_sid	NUMBER;
	v_count		NUMBER;
	v_count2	NUMBER;
BEGIN
	v_tab_sid:=1;
	v_description:='desc';
	v_lookup_key:='RAG_ALERT_TEST';
	v_send_type:='manual';
	v_reply_to_name:='rtn';
	v_reply_to_email:='rte';
	v_deleted:=0;
	v_is_batched:=1;

	SELECT MIN(alert_frame_id)
	  INTO v_alert_frame_id
	  FROM alert_frame;

	flow_pkg.SaveCmsAlertTemplate(
		in_tab_sid						=> v_tab_sid,
		in_customer_alert_type_id		=> v_customer_alert_type_id,
		in_description					=> v_description,
		in_lookup_key					=> v_lookup_key,
		in_alert_frame_id				=> v_alert_frame_id,
		in_send_type					=> v_send_type,
		in_reply_to_name				=> v_reply_to_name,
		in_reply_to_email				=> v_reply_to_email,
		in_deleted						=> v_deleted,
		in_is_batched					=> v_is_batched,
		out_customer_alert_type_id		=> v_out_customer_alert_type_id
	);
	TRACE(v_out_customer_alert_type_id);

	UPDATE cms_alert_type
	   SET include_in_alert_setup = 1
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;


	-- Trigger a run with no alerts expected

	-- force run
	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;
	
	-- internally does csr.alert_pkg.BeginCustomerAlertBatchRun();
	alert_pkg.GetBatchedCmsFieldChangeAlerts(
		in_customer_alert_type_id => v_out_customer_alert_type_id,
		out_cur	=> v_out_cur
	);

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_cms_field_change_alert_id, v_cur_user_sid, v_cur_item_id, v_cur_customer_alert_type_id, v_cur_version_number;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
	END LOOP;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected none');

	csr.alert_pkg.EndCustomerAlertBatchRun(
		in_customer_alert_type_id => v_out_customer_alert_type_id
	);


	-- Trigger a run with a Field Change Alert

	SELECT MIN(csr_user_sid)
	  INTO v_user_sid
	  FROM csr_user
	 WHERE full_name = 'test.alert.user1';

	v_version_number := 103;
	alert_pkg.AddCmsFieldChangeAlert(
		in_lookup_key					=> v_lookup_key, 
		in_item_id						=> 101, 
		in_user_sid						=> v_user_sid, 
		in_version_number				=> v_version_number
	);

	-- force run
	UPDATE alert_batch_run
	   SET next_fire_time = SYSDATE-1
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;
	
	alert_pkg.GetBatchedCmsFieldChangeAlerts(
		in_customer_alert_type_id => v_out_customer_alert_type_id,
		out_cur	=> v_out_cur
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM temp_alert_batch_run
	 WHERE customer_alert_type_id = v_out_customer_alert_type_id;
	SELECT COUNT(*)
	  INTO v_count2
	  FROM csr_user cu
	  JOIN security.user_table ut ON ut.sid_id = cu.csr_user_sid
	 WHERE cu.send_alerts = 1
	   AND ut.account_enabled = 1;
	TRACE('v_count='||v_count);
	TRACE('v_count2='||v_count2);
	unit_test_pkg.AssertAreEqual(v_count2, v_count, 'Expected only the users marked as wanting alerts');

	v_count := 0;
	LOOP
		FETCH v_out_cur INTO v_cur_cms_field_change_alert_id, v_cur_user_sid, v_cur_item_id, v_cur_customer_alert_type_id, v_cur_version_number;
		EXIT WHEN v_out_cur%NOTFOUND;
		v_count := v_count + 1;
		TRACE(
			'* field_change_alert_id='||v_cur_cms_field_change_alert_id||
			'  user_sid='||v_cur_user_sid||
			'  customer_alert_type_id='||v_cur_customer_alert_type_id||
			'  version_number='||v_cur_version_number
		);
		unit_test_pkg.AssertAreEqual(v_user_sid, v_cur_user_sid, 'Expected match');
		unit_test_pkg.AssertAreEqual(v_out_customer_alert_type_id, v_cur_customer_alert_type_id, 'Expected match');
		unit_test_pkg.AssertAreEqual(v_version_number, v_cur_version_number, 'Expected match');
	END LOOP;
	TRACE(v_count||' alert(s) found');
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected one');

	csr.alert_pkg.EndCustomerAlertBatchRun(
		in_customer_alert_type_id => v_out_customer_alert_type_id
	);
END;


END test_alert_pkg;
/
