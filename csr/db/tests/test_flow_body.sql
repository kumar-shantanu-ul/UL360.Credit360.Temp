CREATE OR REPLACE PACKAGE BODY csr.test_flow_pkg AS

v_site_name		VARCHAR2(200);
v_flow_sid 		security.security_pkg.T_SID_ID;
v_flow_item_id 	security.security_pkg.T_SID_ID;
v_s0			security.security_pkg.T_SID_ID;
v_s1			security.security_pkg.T_SID_ID;	

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
	v_workflows_sid			security.security_pkg.T_SID_ID;
	v_xml 					CLOB;
	v_str 					VARCHAR2(2000);			
BEGIN
	Trace('SetUpFixture');
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);
	
	TearDownFixture;
	BEGIN
		INSERT INTO csr.customer_flow_alert_class (flow_alert_class)
		VALUES ('audit');
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
	
	-- Set Up
	v_workflows_sid := security.securableobject_pkg.GetSIDFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'Workflows');
	

	flow_pkg.CreateFlow(
		in_label				=> 'Workflow',
		in_parent_sid 			=> v_workflows_sid,
		in_flow_alert_class 	=> 'audit',
		out_flow_sid 			=> v_flow_sid
	);

	v_xml := '<';
	v_str := UNISTR('flow label="Workflow" cmsTabSid="" default-state-id="$S0$"><state id="$S0$" label="A" final="0" colour="" lookup-key="STATE_A"><attributes x="1078.5" y="801.5" /><transition to-state-id="$S1$" verb="To B" helper-sp="" lookup-key="TRANS_TO_B" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="0" button-icon-path=""></transition></state><state id="$S1$" label="B" final="1" colour="" lookup-key="STATE_B"><attributes x="726.5" y="799.5" /><transition to-state-id="$S0$" verb="OR not to B" helper-sp="" lookup-key="TRANS_B" ask-for-comment="optional" mandatory-fields-message="" hours-before-auto-tran="" button-icon-path=""></transition></state></flow>');
	dbms_lob.writeappend(v_xml, LENGTH(v_str), v_str);

	-- states
	v_s0 := flow_pkg.GetNextStateID;
	v_s1 := flow_pkg.GetNextStateID;

	v_xml := REPLACE(v_xml, '$S0$', v_s0);
	v_xml := REPLACE(v_xml, '$S1$', v_s1);

	flow_pkg.SetFlowFromXml(v_flow_sid, XMLType(v_xml));
	
	UPDATE flow_state_transition SET auto_trans_type = flow_pkg.AUTO_TRANS_HOURS WHERE to_state_id = v_s1;
	
	flow_pkg.AddFlowItem(
		in_flow_sid 		=> v_flow_sid,
		out_flow_item_id 	=> v_flow_item_id
	);

END;

PROCEDURE SetUp AS
	v_flow_sid	NUMBER;
BEGIN
	Trace('SetUp');
	security.user_pkg.logonadmin(v_site_name);
END;

PROCEDURE TearDown AS
	v_flow_sid	NUMBER;
BEGIN
	Trace('TearDown');
END;

PROCEDURE TearDownFixture AS
BEGIN 
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	
	SELECT MIN(flow_sid)
	  INTO v_flow_sid
	  FROM flow
	 WHERE label = 'Workflow';
	 
	IF v_flow_sid IS NOT NULL THEN
		security.securableobject_pkg.DeleteSO(
			in_act_id			=> security.security_pkg.GetACT,
			in_sid_id			=> v_flow_sid
		);
	END IF;
	
	BEGIN
		DELETE FROM csr.customer_flow_alert_class
		 WHERE flow_alert_class = 'audit';
	EXCEPTION
		WHEN OTHERS THEN
			NULL;
	END;
END;

-- HELPER PROCS

-- Tests

PROCEDURE TestFlowItemAutoFailureCount AS
	v_out_cur				SYS_REFCURSOR;
	v_cur_host				VARCHAR2(1024);
	v_cur_flow_item_id		NUMBER;
	v_cur_to_state_id		NUMBER;
	v_cur_app_sid			NUMBER;
	v_cur_helper_pkg		VARCHAR2(1024);
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
	v_flow_state_log_id		NUMBER;
	v_auto_failure_count	NUMBER;
	
	v_act_id				security.security_pkg.T_ACT_ID := security.security_pkg.GetAct;
	v_app_sid				NUMBER := security.security_pkg.GetApp;
	
BEGIN
	Trace('TestFlowItemAutoFailureCount');
	
	-- TESTS
	
	-- AutonomouslyIncreaseFailureCnt updates failure count
	COMMIT; -- Autonomous transaction can't run against uncommitted data.
	flow_pkg.AutonomouslyIncreaseFailureCnt(
		in_flow_item_id 	=> v_flow_item_id
	);
	
	SELECT auto_failure_count
	  INTO v_auto_failure_count
	  FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;
	
	unit_test_pkg.AssertAreEqual(1, v_auto_failure_count, 'Failure count not increased.');
	
	flow_pkg.AutonomouslyIncreaseFailureCnt(
		in_flow_item_id 	=> v_flow_item_id
	);
	
	SELECT auto_failure_count
	  INTO v_auto_failure_count
	  FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;
	
	unit_test_pkg.AssertAreEqual(2, v_auto_failure_count, 'Failure count not increased.');
	
	-- A successful transition resets the failure count
	flow_pkg.SetItemState(
		in_flow_item_id			=> v_flow_item_id,
		in_to_state_Id			=> v_s1,
		in_comment_text			=> '',
		in_cache_keys			=> v_cache_keys,
		in_user_sid				=> SYS_CONTEXT('SECURITY','SID'),
		in_force				=> 0,
		in_cancel_alerts		=> 0,
		out_flow_state_log_id	=> v_flow_state_log_id
	);
	
	SELECT auto_failure_count
	  INTO v_auto_failure_count
	  FROM flow_item
	 WHERE flow_item_id = v_flow_item_id;
	
	unit_test_pkg.AssertAreEqual(0, v_auto_failure_count, 'Failure count not reset.');
	
	flow_pkg.SetItemState(
		in_flow_item_id			=> v_flow_item_id,
		in_to_state_Id			=> v_s0,
		in_comment_text			=> '',
		in_cache_keys			=> v_cache_keys,
		in_user_sid				=> SYS_CONTEXT('SECURITY','SID'),
		in_force				=> 0,
		in_cancel_alerts		=> 0,
		out_flow_state_log_id	=> v_flow_state_log_id
	);
END;

END test_flow_pkg;
/
