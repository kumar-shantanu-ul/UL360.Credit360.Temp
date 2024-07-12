CREATE OR REPLACE PACKAGE BODY CSR.test_issue_test_pkg AS

v_site_name					VARCHAR2(200);
v_region_1_sid				security_pkg.T_SID_ID;
v_region_2_sid				security_pkg.T_SID_ID;
v_ind_1_sid					security_pkg.T_SID_ID;
v_assigned_to_user_sid		security_pkg.T_SID_ID;
v_raised_by_user_sid		security_pkg.T_SID_ID;
v_issue_scheduled_task_id	issue_scheduled_task.issue_scheduled_task_id%TYPE;
v_issue_id					issue.issue_id%TYPE;
v_basic_issue_id			issue.issue_id%TYPE;
v_auto_issue_id				issue.issue_id%TYPE;
v_data_entry_issue_id		issue.issue_id%TYPE;
v_data_entry_child_issue_id	issue.issue_id%TYPE;
v_alert_issue_id			issue.issue_id%TYPE;
v_alert_child_issue_id		issue.issue_id%TYPE;
v_issue_log_id				issue_log.issue_log_id%TYPE;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	NULL;
END;

PROCEDURE TestCreateScheduledTask
AS
	v_schedule_xml				issue_scheduled_task.schedule_xml%TYPE;
	v_period_xml				issue_scheduled_task.period_xml%TYPE;
	v_count						NUMBER(10);
	v_flow_item_id				NUMBER(10) := 123;
	v_has_region_sid			NUMBER(1) := 0;
BEGIN
 	v_schedule_xml := XMLTYPE('<recurrences><yearly every-n="1"><day number="1" month="apr"/></yearly></recurrences>');
 	v_period_xml := XMLTYPE('<period occurrences="1"><start-date day="15" month="03" year="2018"/></period>');
	
	--extras
	BEGIN
		INSERT INTO issue_type (app_sid, issue_type_id, label, helper_pkg)
			VALUES (security.security_pkg.GetAPP, 21, 'Compliance', 'csr.compliance_pkg');

		INSERT INTO compliance_item (app_sid, compliance_item_id, title, source, created_dtm, updated_dtm, compliance_item_status_id, major_version, minor_version, compliance_item_type, reference_code)
			VALUES (security.security_pkg.GetAPP, 1, 'test', 1, SYSDATE-10, SYSDATE-10, 2, 1, 43, 1, 'TEST_REF');
			
		INSERT INTO compliance_item_region (app_sid, compliance_item_id, region_sid, flow_item_id, out_of_scope)
			VALUES (security.security_pkg.GetAPP, 1, v_region_1_sid, v_flow_item_id, 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	UPDATE issue_type SET helper_pkg = NULL WHERE issue_type_id = 21;

	issue_pkg.SaveScheduledTask(
		in_issue_scheduled_task_id		=> NULL,
		in_label						=> 'Scheduled task test',
		in_schedule_xml					=> v_schedule_xml,
		in_period_xml					=> v_period_xml,
		in_raised_by_user_sid			=> v_raised_by_user_sid,
		in_assign_to_user_sid			=> v_assigned_to_user_sid,
		in_next_run_dtm					=> SYSDATE + 10,
		in_due_dtm_relative				=> 10,
		in_due_dtm_relative_unit		=> 'd',
		in_scheduled_on_due_date		=> 0,
		in_parent_id					=> v_flow_item_id,
		in_issue_type_id				=> csr_data_pkg.ISSUE_COMPLIANCE,
		in_create_critical				=> 0,
		in_region_sid					=> v_region_1_sid,
		out_issue_scheduled_task_id		=> v_issue_scheduled_task_id
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = v_issue_scheduled_task_id;
	 
	SELECT 1
	  INTO v_has_region_sid
	  FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = v_issue_scheduled_task_id
	   AND region_sid IS NOT NULL;
	
	unit_test_pkg.AssertAreEqual(1, v_count, 'Scheduled task was added successfully');	
	unit_test_pkg.AssertAreEqual(1, v_has_region_sid, 'Region sid exists in scheduled task');	
END;

PROCEDURE TestCreateSheetValue
AS
	v_issue_sheet_value_id 			security_pkg.T_SID_ID;
	v_issue_sheet_count				NUMBER(10);
	v_child_issue_sheet_value_id 	security_pkg.T_SID_ID;
BEGIN
	INSERT INTO issue_sheet_value (app_sid, issue_sheet_value_id, ind_sid, region_sid, start_dtm, end_dtm)
		 VALUES (security.security_pkg.GetAPP, csr.issue_sheet_value_id_seq.nextval, v_ind_1_sid, v_region_2_sid, SYSDATE, SYSDATE + 1)
	  RETURNING issue_sheet_value_id INTO v_issue_sheet_value_id;

	SELECT COUNT(*)
	  INTO v_issue_sheet_count
	  FROM issue_sheet_value
	 WHERE issue_sheet_value_id = v_issue_sheet_value_id;

	unit_test_pkg.AssertAreEqual(1, v_issue_sheet_count, 'Issue sheet value was created');

	issue_pkg.createIssue(
		in_label					=> 'DataEntry',
		in_issue_type_id			=> csr_data_pkg.ISSUE_DATA_ENTRY,
		in_raised_by_user_sid 		=> v_raised_by_user_sid,
		in_priority_id				=> 5,
		in_due_dtm					=> NULL,
		out_issue_id				=> v_data_entry_issue_id
	);

	UPDATE issue
	   SET issue_sheet_value_id = v_issue_sheet_value_id
	 WHERE issue_id = v_data_entry_issue_id;

	 issue_pkg.createIssue(
		in_label					=> 'DataEntryChild',
		in_issue_type_id			=> csr_data_pkg.ISSUE_DATA_ENTRY,
		in_priority_id				=> 5,
		in_due_dtm					=> NULL,
		out_issue_id				=> v_data_entry_child_issue_id
	);

	issue_pkg.AddChildIssue(
		in_parent_issue_id		=>	v_data_entry_issue_id,
		in_child_issue_id		=>	v_data_entry_child_issue_id
	);

	SELECT issue_sheet_value_id
	  INTO v_child_issue_sheet_value_id
	  FROM issue
	 WHERE issue_id = v_data_entry_child_issue_id;

	unit_test_pkg.AssertAreEqual(v_child_issue_sheet_value_id, v_issue_sheet_value_id, 'Child issue sheet value was copied');

	UPDATE csr.issue
	   SET issue_sheet_value_id = NULL
	 WHERE issue_id = v_data_entry_child_issue_id;

	UPDATE csr.issue
	   SET issue_sheet_value_id = NULL
	 WHERE issue_id = v_data_entry_issue_id;

	DELETE FROM issue_sheet_value
		WHERE issue_sheet_value_id = v_issue_sheet_value_id;
END;


PROCEDURE TestCreateTaskIssue
AS
	v_count						NUMBER(10);
	v_has_region_sid			NUMBER(1) := 0;
BEGIN

	issue_pkg.CreateTaskIssue(
		in_issue_scheduled_task_id		=> v_issue_scheduled_task_id,
		in_issue_type_id				=> csr_data_pkg.ISSUE_COMPLIANCE,
		in_label						=> 'Issue test',
		in_raised_by_user_sid			=> v_raised_by_user_sid,
		in_assign_to_user_sid			=> v_assigned_to_user_sid,
		in_due_dtm						=> SYSDATE + 10,
		in_is_critical					=> 0,
		in_region_sid					=> v_region_1_sid,
		out_issue_id					=> v_issue_id
	);
	
	SELECT COUNT(*)
	  INTO v_count
	  FROM issue_scheduled_task
	 WHERE issue_scheduled_task_id = v_issue_scheduled_task_id;
	 
	SELECT 1
	  INTO v_has_region_sid
	  FROM issue
	 WHERE issue_id = v_issue_id
	   AND region_sid IS NOT NULL;
	
	unit_test_pkg.AssertAreEqual(1, v_count, 'Issue was added successfully');
	unit_test_pkg.AssertAreEqual(1, v_has_region_sid, 'Region sid exists in issue');
END;

PROCEDURE TestCreateIssue
AS
	v_has_due_dtm			NUMBER(1) := 0;
BEGIN
		
	issue_pkg.CreateIssue(
		in_label					=> 'Prio',
		in_issue_type_id			=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id				=> 666,
		in_due_dtm					=> NULL,
		out_issue_id				=> v_basic_issue_id
	);
	 
	SELECT NVL(MIN(1), 0)
	  INTO v_has_due_dtm
	  FROM issue
	 WHERE issue_id = v_basic_issue_id
	   AND due_dtm IS NOT NULL;
		
	unit_test_pkg.AssertAreEqual(1, v_has_due_dtm, 'Due date exists in issue');	
END;

PROCEDURE TestAutoCloseIssue
AS
	v_count						NUMBER(10);
	v_closed_dtm				DATE;
	v_closed_by_user_sid		security.security_pkg.T_SID_ID;
	v_read_by_user_sid			security.security_pkg.T_SID_ID;
	v_cur						SYS_REFCURSOR;
BEGIN
	
	issue_pkg.CreateIssue(
		in_label				=> 'Issue test',
		in_source_label			=> 'Issue test',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_raised_by_user_sid	=> v_raised_by_user_sid,
		in_assigned_to_user_sid => v_assigned_to_user_sid,
		in_due_dtm				=> SYSDATE + 10,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_auto_issue_id
	);
	
	issue_pkg.SetAutoCloseIssue(
		in_issue_id				=> v_auto_issue_id,
		in_auto_close			=> 1
	);
	
	issue_pkg.MarkAsResolved(
		in_act_id					=> security.security_pkg.getAct,
		in_issue_id 				=> v_auto_issue_id,
		in_message					=> 'Test resolve',
		in_var_expl					=> 'Var Ex',
		in_manual_completion_dtm 	=> SYSDATE - 10,
		in_manual_comp_dtm_set_dtm	=> SYSDATE,
		out_log_cur					=> v_cur,
		out_action_cur				=> v_cur
	);
	
	UPDATE issue_type SET auto_close_after_resolve_days = 0 WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC;
	
	security.user_pkg.logonadmin('');
	
	issue_pkg.AutoCloseResolvedIssues;
	
	security.user_pkg.logonadmin(v_site_name);
	
	SELECT closed_dtm, closed_by_user_sid
	  INTO v_closed_dtm, v_closed_by_user_sid
	  FROM issue
	 WHERE issue_id = v_auto_issue_id;
	
	unit_test_pkg.AssertAreEqual(TRUNC(SYSDATE, 'DD'), TRUNC(v_closed_dtm, 'DD'), 'Closed date set');
	unit_test_pkg.AssertAreEqual(3, v_closed_by_user_sid, 'Closed by user set');

	SELECT ilr.csr_user_sid
	  INTO v_read_by_user_sid
	  FROM issue_log il
	  LEFT JOIN issue_log_read ilr ON il.issue_log_id = ilr.issue_log_id AND ilr.csr_user_sid = 3
	 WHERE il.issue_id = v_auto_issue_id
	   AND il.logged_by_user_sid = 3
	   AND il.message LIKE 'Resolved issue automatically closed';
	  
	unit_test_pkg.AssertAreEqual(3, v_read_by_user_sid, 'Read by user set'); 
END;

PROCEDURE TestViewPriorityOveridden
AS
	v_count						NUMBER(10);
	v_normal_prio_id			NUMBER;
	v_test_issue_1				issue.issue_id%TYPE;
	v_test_issue_2				issue.issue_id%TYPE;
	v_test_issue_3				issue.issue_id%TYPE;
	v_test_issue_4				issue.issue_id%TYPE;
BEGIN
	-- CASE WHEN i.issue_priority_id IS NULL OR TRUNC(i.due_dtm) = TRUNC(i.raised_dtm + ip.due_date_offset) THEN 0 ELSE 1 END priority_overridden, 
	INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
	VALUES (1, 'Priority 1', 1)
	RETURNING issue_priority_id INTO v_normal_prio_id;

	issue_pkg.CreateIssue(
		in_label				=> 'View test, past due',
		in_source_label			=> 'View test, past due',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE),
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 issue'); 

	issue_pkg.CreateIssue(
		in_label				=> 'View test, due',
		in_source_label			=> 'View test, due',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) + INTERVAL '1' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_2
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 issue'); 

	issue_pkg.CreateIssue(
		in_label				=> 'View test, not due',
		in_source_label			=> 'View test, not due',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) + INTERVAL '2' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_3
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 issues'); 

	issue_pkg.CreateIssue(
		in_label				=> 'View test, no priority',
		in_source_label			=> 'View test, no priority',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_due_dtm				=> TRUNC(SYSDATE),
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_4
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 issues'); 

	issue_pkg.UNSEC_DeleteIssue(v_test_issue_1);
	issue_pkg.UNSEC_DeleteIssue(v_test_issue_2);
	issue_pkg.UNSEC_DeleteIssue(v_test_issue_3);
	issue_pkg.UNSEC_DeleteIssue(v_test_issue_4);

	DELETE FROM issue_priority
	 WHERE issue_priority_id = 1;
END;

PROCEDURE TestViewPriorityOveriddenSub00
AS
	v_count						NUMBER(10);
	v_normal_prio_id			NUMBER;
	v_test_issue_1				issue.issue_id%TYPE;
	v_test_issue_2				issue.issue_id%TYPE;
	v_test_issue_3				issue.issue_id%TYPE;
	v_test_issue_4				issue.issue_id%TYPE;
BEGIN
	-- CASE WHEN i.issue_priority_id IS NULL OR TRUNC(i.due_dtm) = TRUNC(NVL(pi.raiseddtm, i.raised_dtm) + ip.due_date_offset) THEN 0 ELSE 1 END priority_overridden, 
	INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
	VALUES (1, 'Priority 1', 1)
	RETURNING issue_priority_id INTO v_normal_prio_id;

	issue_pkg.CreateIssue(
		in_label				=> 'View test, no date set',
		in_source_label			=> 'View test, no date set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 overridden priorities'); 
	
	issue_pkg.CreateIssue(
		in_label				=> 'View test subitem, no date set',
		in_source_label			=> 'View test subitem, no date set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_2
	);

	issue_pkg.AddChildIssue(v_test_issue_1, v_test_issue_2);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 overridden priorities'); 
	

	issue_pkg.UNSEC_DeleteIssue(v_test_issue_1);

	DELETE FROM issue_priority
	 WHERE issue_priority_id = 1;
END;

PROCEDURE TestViewPriorityOveriddenSub10
AS
	v_count						NUMBER(10);
	v_normal_prio_id			NUMBER;
	v_test_issue_1				issue.issue_id%TYPE;
	v_test_issue_2				issue.issue_id%TYPE;
	v_test_issue_3				issue.issue_id%TYPE;
	v_test_issue_4				issue.issue_id%TYPE;
BEGIN
	-- CASE WHEN i.issue_priority_id IS NULL OR TRUNC(i.due_dtm) = TRUNC(NVL(pi.raiseddtm, i.raised_dtm) + ip.due_date_offset) THEN 0 ELSE 1 END priority_overridden, 
	INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
	VALUES (1, 'Priority 1', 1)
	RETURNING issue_priority_id INTO v_normal_prio_id;

	issue_pkg.CreateIssue(
		in_label				=> 'View test, date set',
		in_source_label			=> 'View test, date set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) - INTERVAL '1' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 overridden priorities'); 
	
	issue_pkg.CreateIssue(
		in_label				=> 'View test subitem, date not set',
		in_source_label			=> 'View test subitem, date not set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_2
	);

	issue_pkg.AddChildIssue(v_test_issue_1, v_test_issue_2);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 overridden priorities'); 
	

	issue_pkg.UNSEC_DeleteIssue(v_test_issue_1);

	DELETE FROM issue_priority
	 WHERE issue_priority_id = 1;
END;

PROCEDURE TestViewPriorityOveriddenSub01
AS
	v_count						NUMBER(10);
	v_normal_prio_id			NUMBER;
	v_test_issue_1				issue.issue_id%TYPE;
	v_test_issue_2				issue.issue_id%TYPE;
	v_test_issue_3				issue.issue_id%TYPE;
	v_test_issue_4				issue.issue_id%TYPE;
BEGIN
	-- CASE WHEN i.issue_priority_id IS NULL OR TRUNC(i.due_dtm) = TRUNC(NVL(pi.raiseddtm, i.raised_dtm) + ip.due_date_offset) THEN 0 ELSE 1 END priority_overridden, 
	INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
	VALUES (1, 'Priority 1', 1)
	RETURNING issue_priority_id INTO v_normal_prio_id;

	issue_pkg.CreateIssue(
		in_label				=> 'View test, date not set',
		in_source_label			=> 'View test, date not set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(0, v_count, 'Expected 0 overridden priorities'); 
	
	issue_pkg.CreateIssue(
		in_label				=> 'View test subitem, date set',
		in_source_label			=> 'View test subitem, date set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) - INTERVAL '1' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_2
	);

	issue_pkg.AddChildIssue(v_test_issue_1, v_test_issue_2);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 overridden priorities'); 
	

	issue_pkg.UNSEC_DeleteIssue(v_test_issue_1);

	DELETE FROM issue_priority
	 WHERE issue_priority_id = 1;
END;

PROCEDURE TestViewPriorityOveriddenSub11
AS
	v_count						NUMBER(10);
	v_normal_prio_id			NUMBER;
	v_test_issue_1				issue.issue_id%TYPE;
	v_test_issue_2				issue.issue_id%TYPE;
	v_test_issue_3				issue.issue_id%TYPE;
	v_test_issue_4				issue.issue_id%TYPE;
BEGIN
	-- CASE WHEN i.issue_priority_id IS NULL OR TRUNC(i.due_dtm) = TRUNC(NVL(pi.raiseddtm, i.raised_dtm) + ip.due_date_offset) THEN 0 ELSE 1 END priority_overridden, 
	INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
	VALUES (1, 'Priority 1', 1)
	RETURNING issue_priority_id INTO v_normal_prio_id;

	issue_pkg.CreateIssue(
		in_label				=> 'View test, date not set',
		in_source_label			=> 'View test, date not set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) - INTERVAL '1' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_1
	);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 overridden priorities'); 
	
	issue_pkg.CreateIssue(
		in_label				=> 'View test subitem, date set',
		in_source_label			=> 'View test subitem, date set',
		in_issue_type_id		=> csr_data_pkg.ISSUE_BASIC,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE) - INTERVAL '2' DAY,
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_test_issue_2
	);

	issue_pkg.AddChildIssue(v_test_issue_1, v_test_issue_2);

	SELECT COUNT(*)
	  INTO v_count
	  FROM v$issue
	  WHERE priority_overridden = 1;
	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 overridden priorities'); 
	

	issue_pkg.UNSEC_DeleteIssue(v_test_issue_1);

	DELETE FROM issue_priority
	 WHERE issue_priority_id = 1;
END;

PROCEDURE TestGetIssueAlertSummary
AS
	v_cur					SYS_REFCURSOR;
	-- the cursor contents...
	app_sid					NUMBER;
	csr_user_sid			NUMBER;
	friendly_name			VARCHAR(100);
	full_name				VARCHAR(100);
	email					VARCHAR(100);
	label					VARCHAR(100);
	issue_id				NUMBER;
	issue_log_id			NUMBER;
	logged_dtm				DATE;
	message					VARCHAR(100);
	source_url				VARCHAR(100);
	logged_by_user_sid		NUMBER;
	logged_by_user_name		VARCHAR(100);
	logged_by_full_name		VARCHAR(100);
	logged_by_email			VARCHAR(100);
	source_label			VARCHAR(100);
	issue_pending_val_id	NUMBER;
	issue_sheet_value_id	NUMBER;
	issue_non_compliance_id	NUMBER;
	non_compliance_label	VARCHAR(100);
	issue_action_id			NUMBER;
	issue_meter_id			NUMBER;
	issue_meter_alarm_id	NUMBER;
	issue_meter_raw_data_id	NUMBER;
	issue_compliance_region_id	NUMBER;
	issue_meter_data_source_id	NUMBER;
	issue_supplier_id		NUMBER;
	param_1					VARCHAR(100);
	param_2					VARCHAR(100);
	param_3					VARCHAR(100);
	is_system_generated		NUMBER;
	issue_type_label		VARCHAR(100);
	issue_type_id			NUMBER;
	logged_by_is_user		NUMBER;
	issue_url				VARCHAR(100);
	region_sid				NUMBER;
	region_description		VARCHAR(100);
	issue_ref				VARCHAR(100);
	guid					RAW(16);
	raised_dtm				DATE;
	due_dtm					DATE;
	assigned_to				VARCHAR(100);
	assigned_to_user_sid	NUMBER;
	is_critical				NUMBER;
	issue_status			VARCHAR(100);
	priority_due_date_offset	NUMBER;
	priority_description	VARCHAR(100);
	url						VARCHAR(100);
	url_label				VARCHAR(100);
	parent_url				VARCHAR(100);
	parent_url_label		VARCHAR(100);
	pending_val_id			NUMBER;

	-- other vars
	v_issue_sheet_value_id 			security_pkg.T_SID_ID;
	v_issue_sheet_count				NUMBER(10);
	v_child_issue_sheet_value_id 	security_pkg.T_SID_ID;

	v_customer_alert_type_id 		NUMBER;
	v_issue_log_id					NUMBER;

	v_alert_user_sid				security_pkg.T_SID_ID;

	v_count	NUMBER;
BEGIN
	v_alert_user_sid := 5; -- guest

	security.user_pkg.logonadmin(v_site_name);

	enable_pkg.EnableAlert(csr_data_pkg.ALERT_ISSUE_SUMMARY);

	SELECT customer_alert_type_id
	  INTO v_customer_alert_type_id
	  FROM customer_alert_type
	 WHERE std_alert_type_id = csr_data_pkg.ALERT_ISSUE_SUMMARY
	;

	INSERT INTO issue_sheet_value (app_sid, issue_sheet_value_id, ind_sid, region_sid, start_dtm, end_dtm)
		 VALUES (security.security_pkg.GetAPP, csr.issue_sheet_value_id_seq.nextval, v_ind_1_sid, v_region_2_sid, SYSDATE, SYSDATE + 1)
	  RETURNING issue_sheet_value_id INTO v_issue_sheet_value_id;

	SELECT COUNT(*)
	  INTO v_issue_sheet_count
	  FROM issue_sheet_value
	 WHERE issue_sheet_value_id = v_issue_sheet_value_id;

	unit_test_pkg.AssertAreEqual(1, v_issue_sheet_count, 'Issue sheet value was created');

	issue_pkg.createIssue(
		in_label					=> 'Alert',
		in_issue_type_id			=> csr_data_pkg.ISSUE_DATA_ENTRY,
		in_raised_by_user_sid 		=> v_alert_user_sid,
		in_priority_id				=> 5,
		in_due_dtm					=> NULL,
		out_issue_id				=> v_alert_issue_id
	);

	UPDATE issue
	   SET issue_sheet_value_id = v_issue_sheet_value_id
	 WHERE issue_id = v_alert_issue_id;

	 issue_pkg.createIssue(
		in_label					=> 'AlertChild',
		in_issue_type_id			=> csr_data_pkg.ISSUE_DATA_ENTRY,
		in_priority_id				=> 5,
		in_due_dtm					=> NULL,
		out_issue_id				=> v_alert_child_issue_id
	);

	issue_pkg.AddChildIssue(
		in_parent_issue_id		=>	v_alert_issue_id,
		in_child_issue_id		=>	v_alert_child_issue_id
	);


	INSERT INTO issue_log
		(issue_log_id, issue_id, message, logged_by_user_sid, logged_dtm, is_system_generated,
			param_1, param_2, param_3)
	VALUES
		(issue_log_id_seq.nextval, v_alert_issue_id, 'test issue message', v_assigned_to_user_sid, SYSDATE-2, 0,
			1, null, null)
	RETURNING issue_log_id
	     INTO v_issue_log_id;

	DELETE FROM alert_batch_run
	 WHERE csr_user_sid = v_assigned_to_user_sid;


	security.user_pkg.logonadmin();
	issue_pkg.GetIssueAlertSummary(
		out_cur	=>	v_cur
	);

	-- Simulate the 19c error by committing. Causes the temp table to be deleted.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_cur INTO app_sid, csr_user_sid, friendly_name, full_name, email, label, issue_id, issue_log_id,
		logged_dtm, message, source_url, logged_by_user_sid, logged_by_user_name, logged_by_full_name,  logged_by_email,
		source_label, issue_pending_val_id, issue_sheet_value_id, issue_non_compliance_id, non_compliance_label,
		issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_compliance_region_id, issue_meter_data_source_id, issue_supplier_id,
		param_1, param_2, param_3,
		is_system_generated, issue_type_label, issue_type_id, 
		logged_by_is_user, issue_url, region_sid, region_description,
		issue_ref, guid, raised_dtm, due_dtm,
		assigned_to, assigned_to_user_sid,
		is_critical, issue_status, priority_due_date_offset, priority_description, url, url_label,
		parent_url, parent_url_label, pending_val_id
		;
		TRACE('cur contains '||app_sid||csr_user_sid||friendly_name||full_name);
		v_count := v_count + 1;
		EXIT WHEN v_cur%NOTFOUND;
	END LOOP;

	unit_test_pkg.AssertIsTrue(v_count > 0, 'Expected cur entries'); 

	security.user_pkg.logonadmin(v_site_name);


	UPDATE csr.issue
	   SET issue_sheet_value_id = NULL
	 WHERE issue_id = v_alert_child_issue_id;

	UPDATE csr.issue
	   SET issue_sheet_value_id = NULL
	 WHERE issue_id = v_alert_issue_id;

	DELETE FROM issue_sheet_value
		WHERE issue_sheet_value_id = v_issue_sheet_value_id;

	delete from issue_involvement where issue_sheet_value_id = v_issue_sheet_value_id;
	delete from issue_action_log where issue_sheet_value_id = v_issue_sheet_value_id;
	delete from issue_log_read where issue_sheet_value_id = v_issue_sheet_value_id;
	delete from issue_log where issue_sheet_value_id = v_issue_sheet_value_id;
	delete from issue_log where issue_sheet_value_id = v_issue_sheet_value_id;

	v_alert_user_sid := NULL;
END;

PROCEDURE TestDeleteIssue
AS
	v_issue_count				NUMBER(10);
	v_issue_log_count			NUMBER(10);
	v_issue_log_file_count		NUMBER(10);
	v_deleted					issue.deleted%TYPE;
	v_issue_survey_answer_id	issue.issue_survey_answer_id%TYPE;
	v_issue_log_file_id  		issue_log_file.issue_log_file_id%TYPE;
	v_blob_data					issue_log_file.data%TYPE;
	v_sha1_hash					issue_log_file.sha1%TYPE;

BEGIN
	-- Setting the permission 
	UPDATE issue_type 
	   SET deletable_by_administrator = 1
     WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;

	csr_data_pkg.EnableCapability('Issue management');
	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('ACTION_REGION');

	-- Creating a new Action/Issue.
	issue_pkg.CreateIssue(
		in_label				=> 'Skymark',
		in_source_label			=> 'Skymark',
		in_issue_type_id		=> csr_data_pkg.ISSUE_NON_COMPLIANCE,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE),
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_issue_id
	);
	
	-- Verifying the creation of the new issue.
	SELECT COUNT(*) 
	  INTO v_issue_count 
	  FROM issue 
	 WHERE issue_id = v_issue_id;

	SELECT deleted
	  INTO v_deleted
	  FROM issue
	 WHERE issue_id = v_issue_id;
	
	unit_test_pkg.AssertAreEqual(1, v_issue_count, 'New Issue should be created for the given issue log');
	unit_test_pkg.AssertAreEqual(0, v_deleted, 'Prior to deletion, the value should be false for the new issue');
	
	-- Adding a Log entry for the new issue
	issue_pkg.AddLogEntry(
    	in_act_id                => security_pkg.getAct,
    	in_issue_id              => v_issue_id,
    	in_is_system_generated   => 0,
    	in_message               => 'Sample Message',
    	in_param_1               => '',
    	in_param_2               => '',
    	in_param_3               => '',
    	out_issue_log_id         => v_issue_log_id
  	);

	-- Verifying the creation of the issue log.
  	SELECT COUNT(*)
	  INTO v_issue_log_count
	  FROM issue_log
	 WHERE issue_log_id = v_issue_log_id;

	unit_test_pkg.AssertAreEqual(1, v_issue_log_count, 'Issue log should be created for the given issue');

	-- Setting up values for issue log file.
	v_blob_data := utl_raw.cast_to_raw('Sample BLOB data');
  	v_sha1_hash := dbms_crypto.hash(v_blob_data, dbms_crypto.hash_sh1);
	SELECT issue_log_file_id_seq.NEXTVAL INTO v_issue_log_file_id FROM DUAL;

	-- Inserting an issue log file entry.
	INSERT INTO csr.issue_log_file (
		issue_log_file_id,
		issue_log_id,
		filename,
		mime_type,
		data,
		sha1,
		uploaded_dtm
  	) VALUES (
		v_issue_log_file_id,
		v_issue_log_id,
		'sample_file.txt',
		'text/plain',
		v_blob_data,
		v_sha1_hash,
		TRUNC(sysdate)
	);

	-- Verifying the creation of the issue log file.
	SELECT COUNT(*)
	  INTO v_issue_log_file_count
	  FROM issue_log_file
	 WHERE issue_log_file_id = v_issue_log_file_id;

	unit_test_pkg.AssertAreEqual(1, v_issue_log_file_count, 'File should be created for the given issue log');

	-- Performing deletion of the issue.
	issue_pkg.DeleteIssue(v_issue_id);

	-- Verifying the deletion results.
	SELECT deleted
	  INTO v_deleted
	  FROM issue
	 WHERE issue_id = v_issue_id;

	SELECT COUNT(*)
	  INTO v_issue_count
	  FROM issue
	 WHERE issue_id = v_issue_id;
	
	SELECT issue_survey_answer_id
	  INTO v_issue_survey_answer_id
	  FROM issue
	 WHERE issue_id = v_issue_id;

	SELECT COUNT(*) 
	  INTO v_issue_log_count 
	  FROM issue_log 
	 WHERE issue_log_id = v_issue_log_id;

	SELECT COUNT(*) 
	  INTO v_issue_log_file_count 
	  FROM issue_log_file 
	 WHERE issue_log_file_id = v_issue_log_file_id;
	
	unit_test_pkg.AssertAreEqual(1, v_deleted, 'After deletion, the value should be true.');
	unit_test_pkg.AssertIsNull(v_issue_survey_answer_id, 'Issue Survey Answer Id should be null After deletion.');
	unit_test_pkg.AssertAreEqual(1, v_issue_count, 'The issue should still exist in the system.');
	unit_test_pkg.AssertAreEqual(1, v_issue_log_count, 'The issue log should still exist in the system.');
	unit_test_pkg.AssertAreEqual(0, v_issue_log_file_count, 'The issue log file should be deleted when the parent issue is deleted.');
END;

PROCEDURE TestUpdateIssues
AS
	v_issue_ids					security.security_pkg.T_SID_IDS;
	v_assigned_to_sid			issue.assigned_to_user_sid%TYPE;
	test_assigned_to_user_sid	issue.assigned_to_user_sid%TYPE;
	test_assigned_to_user_sid2	issue.assigned_to_user_sid%TYPE;
	v_involved_users			security.security_pkg.T_SID_IDS;
	v_uninvolved_users			security.security_pkg.T_SID_IDS;
	v_update_issue_id1			issue.issue_id%TYPE;
	v_update_issue_id2			issue.issue_id%TYPE;
	v_out_cur					SYS_REFCURSOR;
	test_due_dtm				issue.due_dtm%TYPE;
	test_involved_user			issue.assigned_to_user_sid%TYPE;
	test_uninvolved_user		NUMBER;
BEGIN
	csr_data_pkg.EnableCapability('Issue management');
	csr_data_pkg.enablecapability('Enable Actions Bulk Update');	
	
	-- Creating a new Action/Issue.
	issue_pkg.CreateIssue(
		in_label				=> 'Test1',
		in_source_label			=> 'Test1',
		in_issue_type_id		=> csr_data_pkg.ISSUE_NON_COMPLIANCE,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE),
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_update_issue_id1
	);
	
	-- Creating a new Action/Issue.
	issue_pkg.CreateIssue(
		in_label				=> 'Test2',
		in_source_label			=> 'Test2',
		in_issue_type_id		=> csr_data_pkg.ISSUE_NON_COMPLIANCE,
		in_priority_id			=> 1,
		in_due_dtm				=> TRUNC(SYSDATE),
		in_is_critical			=> 0,
		in_region_sid			=> v_region_1_sid,
		out_issue_id			=> v_update_issue_id2
	);
	v_assigned_to_sid := unit_test_pkg.GetOrCreateUser('UPDATE_TEST_USER');
	v_involved_users(1) := unit_test_pkg.GetOrCreateUser('USER_11');
	v_uninvolved_users(1) := unit_test_pkg.GetOrCreateUser('USER_22');

	v_issue_ids(1) := v_update_issue_id1;
	v_issue_ids(2) := v_update_issue_id2;

	issue_pkg.UpdateIssues(	
	in_act_id					=> security.security_pkg.getAct,
	in_issue_ids				=> v_issue_ids,
	in_assigned_to_sid			=> v_assigned_to_sid,
	in_comment					=> 'Test',
	in_involved_users			=> v_involved_users,
	in_uninvolved_users			=> v_uninvolved_users,
	in_set_due_dtm				=> 1,
	in_due_dtm					=> null,
	out_error_cur				=> v_out_cur);

	-- Verifying
	SELECT assigned_to_user_sid
	  INTO test_assigned_to_user_sid
	  FROM issue
	 WHERE issue_id = v_update_issue_id1;

	 SELECT assigned_to_user_sid, due_dtm
	  INTO test_assigned_to_user_sid2, test_due_dtm
	  FROM issue
	 WHERE issue_id = v_update_issue_id2;

	SELECT user_sid 
	  INTO test_involved_user
	  FROM issue_involvement
	WHERE issue_id = v_update_issue_id1 AND user_sid= v_involved_users(1);

	SELECT COUNT(user_sid) 
	  INTO test_uninvolved_user
	  FROM issue_involvement
	WHERE issue_id = v_update_issue_id2 AND user_sid= v_uninvolved_users(1);

	unit_test_pkg.AssertAreEqual(v_assigned_to_sid, test_assigned_to_user_sid, 'Assigned first user sid is not correct.');
	unit_test_pkg.AssertAreEqual(v_assigned_to_sid, test_assigned_to_user_sid2, 'Assigned second user sid is not correct.');
	unit_test_pkg.AssertAreEqual(NULL, test_due_dtm, 'Issue Due dtm is not correct.');
	unit_test_pkg.AssertAreEqual(v_involved_users(1), test_involved_user ,'Involved user is not exists.');
	unit_test_pkg.AssertAreEqual(0, test_uninvolved_user ,'Uninvolved user is exists.');

END;

/*****************************************************************************/
PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	v_site_name := in_site_name;
	security.user_pkg.logonadmin(v_site_name);

	-- clean up if previous fail.
	FOR r IN (SELECT issue_id FROM issue)
	LOOP
		BEGIN
			issue_pkg.UNSEC_DeleteIssue(r.issue_id);
		EXCEPTION
			WHEN others THEN NULL;
		END;
	END LOOP;



	v_region_1_sid := unit_test_pkg.GetOrCreateRegion('SCHEDULED_ACTION_REGION_1');
	v_region_2_sid := unit_test_pkg.GetOrCreateRegion('SHEET_VALUE_REGION_1');
	v_ind_1_sid := unit_test_pkg.GetOrCreateInd('ISSUE_VALUE_IND_1');
	v_assigned_to_user_sid := unit_test_pkg.GetOrCreateUser('USER_1');
	v_raised_by_user_sid := unit_test_pkg.GetOrCreateUser('USER_2'); 
	
	BEGIN
		INSERT INTO issue_type (issue_type_id, label, allow_children, create_raw)
		VALUES (csr_data_pkg.ISSUE_BASIC, 'Action', 1, 1);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (issue_type_id, label, allow_children, create_raw, deletable_by_administrator)
		VALUES (csr_data_pkg.ISSUE_NON_COMPLIANCE, 'Action', 1, 1, 1);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	BEGIN
		INSERT INTO issue_type (issue_type_id, label, allow_children, create_raw)
		VALUES (csr_data_pkg.ISSUE_DATA_ENTRY, 'Data Entry', 1, 1);
		
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE issue_type
			   SET allow_children = 1
			 WHERE issue_type_id = csr_data_pkg.ISSUE_DATA_ENTRY;
	END;
	
	BEGIN
		INSERT INTO issue_priority(issue_priority_id, description, due_date_offset)
		VALUES (666, 'Low priority', 14);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;

PROCEDURE TearDownFixture
AS
	v_act security.security_pkg.T_ACT_ID;
BEGIN
	Trace('TearDownFixture');
	security.user_pkg.logonadmin(v_site_name);
	IF v_issue_scheduled_task_id IS NOT NULL THEN
		issue_pkg.DeleteScheduledTask(v_issue_scheduled_task_id);
	END IF;
	IF v_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_issue_id);
	END IF;
	IF v_auto_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_auto_issue_id);
	END IF;
	IF v_basic_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_basic_issue_id);
	END IF;
	IF v_data_entry_child_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_data_entry_child_issue_id);
	END IF;
	IF v_data_entry_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_data_entry_issue_id);
	END IF;
	IF v_alert_child_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_alert_child_issue_id);
	END IF;
	IF v_alert_issue_id IS NOT NULL THEN
		issue_pkg.UNSEC_DeleteIssue(v_alert_issue_id);
	END IF;

	DELETE FROM comp_item_region_sched_issue;
	DELETE FROM issue_compliance_region;
	DELETE FROM compliance_item_region WHERE compliance_item_id = 1;
	DELETE FROM compliance_item WHERE compliance_item_id = 1;
	DELETE FROM issue_scheduled_task;

	UPDATE issue
	   SET issue_sheet_value_id = NULL;
	 --WHERE issue_id IN (v_issue_id, v_auto_issue_id, v_basic_issue_id, v_data_entry_child_issue_id, v_data_entry_issue_id, v_alert_child_issue_id, v_alert_issue_id);

	DELETE FROM issue_sheet_value 
	 WHERE region_sid IN (v_region_1_sid, v_region_2_sid);


	IF v_region_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_1_sid);
		v_region_1_sid := NULL;
	END IF;

	IF v_region_2_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_region_2_sid);
		v_region_2_sid := NULL;
	END IF;

	IF v_ind_1_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_ind_1_sid);
		v_ind_1_sid := NULL;
	END IF;

	IF v_assigned_to_user_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_assigned_to_user_sid);
		v_assigned_to_user_sid := NULL;
	END IF;

	IF v_raised_by_user_sid IS NOT NULL THEN
		security.securableobject_pkg.deleteso(security_pkg.getact, v_raised_by_user_sid);
		v_raised_by_user_sid := NULL;
	END IF;
	
	DELETE FROM issue_log_read WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC));
	DELETE FROM issue_action_log WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC));
	DELETE FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC);
	DELETE FROM issue_involvement WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC);
	DELETE FROM issue_action_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC);

	DELETE FROM issue_log_read WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE));
	DELETE FROM issue_action_log WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE));
	DELETE FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE);
	DELETE FROM issue_involvement WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE);
	DELETE FROM issue_action_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE);
	
	DELETE FROM issue_log_read WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE));
	DELETE FROM issue_action_log WHERE issue_log_id IN(SELECT issue_log_id FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE));
	DELETE FROM issue_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE);
	DELETE FROM issue_involvement WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE);
	DELETE FROM issue_action_log WHERE issue_id IN (SELECT issue_id FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE);

	DELETE FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC;
	DELETE FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE;
	DELETE FROM issue WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	
	DELETE FROM issue_type_aggregate_ind_grp WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC;
	DELETE FROM issue_type_aggregate_ind_grp WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE;
	DELETE FROM issue_type_aggregate_ind_grp WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	
	DELETE FROM issue_type WHERE issue_type_id = csr_data_pkg.ISSUE_BASIC;
	DELETE FROM issue_type WHERE issue_type_id = csr_data_pkg.ISSUE_COMPLIANCE;
	DELETE FROM issue_type WHERE issue_type_id = csr_data_pkg.ISSUE_NON_COMPLIANCE;
	DELETE FROM issue_priority WHERE issue_priority_id = 666;
	issue_pkg.DeleteLogEntry(security_pkg.GetAct, v_issue_log_id);
	csr_data_pkg.DeleteCapability('Issue management');
	csr_data_pkg.DeleteCapability('Enable Actions Bulk Update');
END;

END;
/
