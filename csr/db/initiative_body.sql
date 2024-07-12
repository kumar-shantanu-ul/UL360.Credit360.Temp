CREATE OR REPLACE PACKAGE BODY CSR.initiative_pkg
IS

PROC_NOT_FOUND				EXCEPTION;
PRAGMA EXCEPTION_INIT(PROC_NOT_FOUND, -06550);

--
-- RETURN EMPTY ASSOCIATIVE ARRAYS OF GIVEN TYPES
-- THEN USE THE FUNCTION IN THE DEFAULT CLAUSE ON THE
-- PROCEDURE PARAMETER. I DON'T SEE ANOTHER WAY OF
-- DOING THIS AS ASSOCIATIVE ARRAYS DON'T HAVE
-- A DEFAULT CONSTRUCTOR, THEY'RE JUST CREATED EMPTY.

FUNCTION INIT_EmptySidIds
RETURN security_pkg.T_SID_IDS
AS
	v security_pkg.T_SID_IDS;
BEGIN
	RETURN v;
END;

FUNCTION INIT_EmptyTeamNames
RETURN T_TEAM_NAMES
AS
	v T_TEAM_NAMES;
BEGIN
	RETURN v;
END;

FUNCTION INIT_EmptyTeamEmails
RETURN T_TEAM_EMAILS
AS
	v T_TEAM_EMAILS;
BEGIN
	RETURN v;
END;

--

PROCEDURE INTERNAL_CheckReference (
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_ref					IN	initiative.internal_ref%TYPE
)
AS
BEGIN
	FOR r IN (
		SELECT initiative_sid
		  FROM initiative
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND internal_ref = in_ref
		   AND initiative_sid != in_initiative_sid
	) LOOP
		RAISE_APPLICATION_ERROR(ERR_DUP_REFERENCE, 'Reference is not unique');
	END LOOP;
END;

-- Initiatives specific version of this procedure
PROCEDURE INTERNAL_AuditInfoXmlChanges(
	in_initiative_sid				IN	security_pkg.T_SID_ID,
	in_old_info_xml					IN	XMLType,
	in_new_info_xml					IN	XMLType
)
AS
	v_info_xml_fields				XMLType;
BEGIN
	-- Get the field definitions
	SELECT p.fields_xml
	  INTO v_info_xml_fields
	  FROM initiative_project p
	  JOIN initiative i ON i.app_sid = p.app_sid AND i.project_sid = p.project_sid
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.initiative_sid = in_initiative_sid;
	
	-- Process changes
	FOR rx IN (
		 SELECT 
		    CASE 
		      WHEN n.node_key IS NULL THEN '{0} deleted'
		      WHEN o.node_key IS NULL THEN '{0} set to "{2}"'
		      ELSE '{0} changed from "{1}" to "{2}"'
		    END action, NVL(f.node_label, NVL(o.node_key, n.node_key)) node_label, 
		    REGEXP_REPLACE(NVL(o.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') old_node_value, 
		    REGEXP_REPLACE(NVL(n.node_value,'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') new_node_value
		  FROM (
		      SELECT 
		        EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key,
		        EXTRACT(VALUE(x), 'field/@description').getStringVal() node_label
		      FROM TABLE(XMLSEQUENCE(EXTRACT(v_info_xml_fields, '*/field' )))x
		   )f, (
		    SELECT 
		      EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key, 
		      EXTRACT(VALUE(x), 'field/text()').getStringVal() node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_old_info_xml, '/values/field'))
		      )x
		  )o FULL JOIN (
		     SELECT 
		      EXTRACT(VALUE(x), 'field/@id').getStringVal() node_key, 
		      EXTRACT(VALUE(x), 'field/text()').getStringVal() node_value
		      FROM TABLE(
		        XMLSEQUENCE(EXTRACT(in_new_info_xml, '/values/field'))
		      )x
		  )n ON o.node_key = n.node_key
		  WHERE f.node_key = NVL(o.node_key, n.node_key)
		    AND (n.node_key IS NULL
				OR o.node_key IS NULL
				OR NVL(o.node_value, '-') != NVL(n.node_value, '-')
			)
	)
	LOOP
		csr_data_pkg.WriteAuditLogEntryAndSubObject(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP, 
			in_initiative_sid,
			NULL,
			rx.action, 
			rx.node_label, 
			rx.old_node_value, 
			rx.new_node_value
		);
	END LOOP;
END;

PROCEDURE INTERNAL_GetInitiativeRowState(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_row_state				OUT	initiative%ROWTYPE
)
AS
BEGIN
	SELECT *
	  INTO out_row_state
	  FROM initiative
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_sid = in_initiative_sid;
END;

PROCEDURE INTERNAL_BeginAuditInitiative(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_row_state				OUT	initiative%ROWTYPE
)
AS
BEGIN
	BEGIN
		INTERNAL_GetInitiativeRowState(
			in_initiative_sid,
			out_row_state
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- Ignore (create new)
	END;
END;

PROCEDURE INTERNAL_EndAuditInitiative(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_start_row_state			IN	initiative%ROWTYPE
)
AS
	v_end_row_state				initiative%ROWTYPE;
	v_start_saving_type			initiative_saving_type.label%TYPE;
	v_end_saving_type			initiative_saving_type.label%TYPE;
BEGIN
	
	-- Get new state
	INTERNAL_GetInitiativeRowState(
		in_initiative_sid,
		v_end_row_state
	);
	
	-- Name
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Name',
		in_start_row_state.name,
		v_end_row_state.name
	);
	
	-- Name
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Reference',
		in_start_row_state.internal_ref,
		v_end_row_state.internal_ref
	);
	
	-- Project start date
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Project start date',
		in_start_row_state.project_start_dtm,
		v_end_row_state.project_start_dtm
	);
	
	-- Project end date
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Project end date',
		in_start_row_state.project_end_dtm,
		v_end_row_state.project_end_dtm
	);
	
	-- Running start date
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Running start date',
		in_start_row_state.running_start_dtm,
		v_end_row_state.running_start_dtm
	);
	
	-- Running end date
	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Running end date',
		in_start_row_state.running_end_dtm,
		v_end_row_state.running_end_dtm
	);

	-- Is ramped flag
   	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Is ramped',
		in_start_row_state.is_ramped,
		v_end_row_state.is_ramped
	);
   
	-- Saving type
	BEGIN
	   	SELECT label
	   	  INTO v_start_saving_type
	   	  FROM initiative_saving_type
	   	 WHERE saving_type_id = in_start_row_state.saving_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_start_saving_type := NULL;
	END;
	
	BEGIN
	   	SELECT label
	   	  INTO v_end_saving_type
	   	  FROM initiative_saving_type
	   	 WHERE saving_type_id = v_end_row_state.saving_type_id;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			v_end_saving_type := NULL;
	END;

   	csr_data_pkg.AuditValueChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Saving type',
		v_start_saving_type,
		v_end_saving_type
	);
	

	-- Info xml fields
	INTERNAL_AuditInfoXmlChanges(
		in_initiative_sid,
		CASE WHEN in_start_row_state.fields_xml IS NULL THEN NULL ELSE XMLType(in_start_row_state.fields_xml) END,
		CASE WHEN v_end_row_state.fields_xml IS NULL THEN NULL ELSE XMLType(v_end_row_state.fields_xml) END
	);
   
END;


PROCEDURE CreateObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_class_id				IN security_pkg.T_CLASS_ID,
	in_name					IN security_pkg.T_SO_NAME,
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE RenameObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_name				IN security_pkg.T_SO_NAME
)
AS
BEGIN
	NULL;
END;

PROCEDURE MoveObject(
	in_act					IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID,
	in_new_parent_sid		IN security_pkg.T_SID_ID,
	in_old_parent_sid_id	IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;

PROCEDURE TrashObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN
	initiative_aggr_pkg.RefreshAggrRegions(in_sid_id);
	initiative_aggr_pkg.RefreshAggrVals(in_sid_id);
END;

PROCEDURE DeleteObject(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_sid_id				IN security_pkg.T_SID_ID
)
AS
BEGIN

	DELETE FROM initiative_comment
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_group_member
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_metric_val
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_period
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_project_team
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_sponsor
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_region
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_tag
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_user
	 WHERE initiative_sid = in_sid_id;

	BEGIN
	  FOR r IN (
			SELECT issue_id
			  FROM issue i, issue_initiative ii
			 WHERE i.issue_initiative_id = ii.issue_initiative_id
			   AND ii.initiative_sid = in_sid_id
		) LOOP
			issue_pkg.UNSEC_DeleteIssue(r.issue_id);
		END LOOP;
	END;

	UPDATE issue
	   SET issue_initiative_id = null
	 WHERE issue_initiative_id IN (
	 	SELECT issue_initiative_id FROM issue_initiative WHERE initiative_sid = in_sid_id
	 );

	-- XXX: Remove the issue entry
	DELETE FROM issue_initiative
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_event
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative_user_msg
	 WHERE initiative_sid = in_sid_id;

	DELETE FROM initiative
	 WHERE initiative_sid = in_sid_id;

	initiative_aggr_pkg.RefreshAggrRegions(in_sid_id);
	initiative_aggr_pkg.RefreshAggrVals;
END;

PROCEDURE GetOptions(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT initiative_name_gen_proc, initiative_reminder_alerts, initiative_new_days, gantt_period_colour,
			initiatives_host, my_initiatives_options, auto_complete_date, update_ref_on_amend, current_report_date,
			metrics_start_year, metrics_end_year
		  FROM initiatives_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
END;

PROCEDURE SetOptions(
	in_initiative_name_gen_proc		IN	initiatives_options.initiative_name_gen_proc%TYPE		DEFAULT NULL,
	in_initiative_reminder_alerts	IN	initiatives_options.initiative_reminder_alerts%TYPE		DEFAULT 0,
	in_initiative_new_days			IN	initiatives_options.initiative_new_days%TYPE			DEFAULT 5,
	in_gantt_period_colour			IN	initiatives_options.gantt_period_colour%TYPE			DEFAULT 0,
	in_initiatives_host				IN	initiatives_options.initiatives_host%TYPE				DEFAULT NULL,
	in_my_initiatives_options		IN	initiatives_options.my_initiatives_options%TYPE			DEFAULT NULL,
	in_auto_complete_date			IN	initiatives_options.auto_complete_date%TYPE				DEFAULT 1,
	in_update_ref_on_amend			IN	initiatives_options.update_ref_on_amend%TYPE			DEFAULT 0,
	in_current_report_date			IN	initiatives_options.current_report_date%TYPE			DEFAULT NULL,
	in_metrics_start_year			IN	initiatives_options.metrics_start_year%TYPE				DEFAULT 2012,
	in_metrics_end_year				IN	initiatives_options.metrics_end_year%TYPE				DEFAULT 2030
)
AS
BEGIN
	BEGIN
		INSERT INTO initiatives_options
			(initiative_name_gen_proc, initiative_reminder_alerts, initiative_new_days, gantt_period_colour,
			initiatives_host, my_initiatives_options, auto_complete_date, update_ref_on_amend, current_report_date,
			metrics_start_year, metrics_end_year)
		VALUES (
			in_initiative_name_gen_proc,
			in_initiative_reminder_alerts,
			in_initiative_new_days,
			in_gantt_period_colour,
			in_initiatives_host,
			in_my_initiatives_options,
			in_auto_complete_date,
			in_update_ref_on_amend,
			in_current_report_date,
			in_metrics_start_year,
			in_metrics_end_year
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE initiatives_options
			   SET	initiative_name_gen_proc = in_initiative_name_gen_proc,
					initiative_reminder_alerts = in_initiative_reminder_alerts,
					initiative_new_days = in_initiative_new_days,
					gantt_period_colour = in_gantt_period_colour,
					initiatives_host = in_initiatives_host,
					my_initiatives_options = in_my_initiatives_options,
					auto_complete_date = in_auto_complete_date,
					update_ref_on_amend = in_update_ref_on_amend,
					current_report_date = in_current_report_date,
					metrics_start_year = in_metrics_start_year,
					metrics_end_year = in_metrics_end_year
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	END;
END;

FUNCTION GetCreatePageUrl 
RETURN VARCHAR2
AS
	v_create_page_url				VARCHAR2(255);
BEGIN
	-- Ick, this is stored in json
	BEGIN
		SELECT SUBSTR(REGEXP_SUBSTR(my_initiatives_options,'createPage:"[^"]*'), 13)
		  INTO v_create_page_url
		  FROM initiatives_options
		 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');
	EXCEPTION
		WHEN no_data_found THEN
			NULL;
	END;
	
	IF v_create_page_url IS NOT NULL THEN
		RETURN v_create_page_url;
	END IF;
	
	RETURN '/csr/site/initiatives/createFull.acds';
END;

PROCEDURE INTERNAL_BeginAuditRegions(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_region_sids				OUT security_pkg.T_SID_IDS
)
AS
BEGIN
	SELECT ir.region_sid
	  BULK COLLECT INTO out_region_sids
	  FROM initiative_region ir
	 WHERE ir.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ir.initiative_sid = in_initiative_sid;
END;

PROCEDURE INTERNAL_EndAuditRegions(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_tbl						security.T_SID_TABLE;					
BEGIN
	v_tbl := security_pkg.SidArrayToTable(in_region_sids);
	
	FOR r IN (
		SELECT ir.region_sid, r.description
		  FROM initiative_region ir
		  JOIN v$region r ON r.app_sid = ir.app_sid AND r.region_sid = ir.region_sid
		 WHERE ir.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ir.initiative_sid = in_initiative_sid
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM TABLE(v_tbl) a
		 	 WHERE a.column_value = ir.region_sid
		 )
	) LOOP
		-- Region added
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Region {0} added.',
			r.description
		);
	END LOOP;
	
	FOR r IN (
		SELECT a.column_value region_sid, r.description
		  FROM TABLE(v_tbl) a
		  JOIN v$region r ON r.region_sid = a.column_value
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM initiative_region ir
		 	 WHERE ir.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND ir.initiative_sid = in_initiative_sid
		 	   AND ir.region_sid = a.column_value
		 )
	) LOOP
		-- Region removed
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Region {0} removed.',
			r.description
		);
	END LOOP;
END;

PROCEDURE SetRegions(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_region_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_audit_region_sids			security_pkg.T_SID_IDS;
	v_sid_table 				security.T_SID_TABLE;
	v_spin						BOOLEAN;
BEGIN
	-- Init audit info
	INTERNAL_BeginAuditRegions(
		in_initiative_sid,
		v_audit_region_sids
	);
	
	v_sid_table := security_pkg.SidArrayToTable(in_region_sids);
	
	-- Check for aggr region assignments
	FOR r IN (
		SELECT r.region_sid
		  FROM region r, TABLE(v_sid_table) t
		 WHERE r.region_sid = t.column_value
		   AND r.region_type = csr_data_pkg.REGION_TYPE_AGGR_REGION
	) LOOP
		RAISE_APPLICATION_ERROR(
			ERR_AGGR_REGION_ASSIGN, 
			'Can not assign an aggregate region to an initiative'
		);
	END LOOP;
	
	v_spin := TRUE;
	WHILE v_spin
	LOOP
		BEGIN
			-- Add new items (insert optimistically)
			INSERT INTO initiative_region (initiative_sid, region_sid)
				SELECT in_initiative_sid, t.column_value
				  FROM TABLE(v_sid_table) t
				MINUS
				SELECT initiative_sid, region_sid
				  FROM initiative_region
				 WHERE initiative_sid = in_initiative_sid;

			-- Delete removed items
			DELETE FROM initiative_region
			 WHERE (initiative_sid, region_sid) IN (
			 	SELECT initiative_sid, region_sid
				  FROM initiative_region
				 WHERE initiative_sid = in_initiative_sid
				MINUS
				SELECT in_initiative_sid, t.column_value
				  FROM TABLE(v_sid_table) t
			);
			v_spin := FALSE;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	initiative_aggr_pkg.RefreshAggrRegions(in_initiative_sid);
	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);
	
	-- Audit changes
	INTERNAL_EndAuditRegions(
		in_initiative_sid,
		v_audit_region_sids
	);
	
END;

PROCEDURE INTERNAL_BeginAuditUsers(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_initiative_user_group_id IN  initiative_user_group.initiative_user_group_id%TYPE,
	out_user_sids				OUT	security_pkg.T_SID_IDS
)
AS
BEGIN
	SELECT user_sid
	  BULK COLLECT INTO out_user_sids
	  FROM initiative_user
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_user_group_id = in_initiative_user_group_id
	   AND initiative_sid = in_initiative_sid;
END;

PROCEDURE INTERNAL_EndAuditUsers(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_initiative_user_group_id IN  initiative_user_group.initiative_user_group_id%TYPE,
	in_user_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_group_name				initiative_user_group.label%TYPE;
	v_tbl						security.T_SID_TABLE;					
BEGIN
	
	v_tbl := security_pkg.SidArrayToTable(in_user_sids);
	
	SELECT label
	  INTO v_group_name
	  FROM initiative_user_group
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_user_group_id = in_initiative_user_group_id;
	   
	FOR r IN (
		SELECT iu.user_sid, cu.full_name
		  FROM initiative_user iu
		  JOIN csr_user cu ON cu.app_sid = iu.app_sid AND cu.csr_user_sid = iu.user_sid
		 WHERE iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND iu.initiative_sid = in_initiative_sid
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM TABLE(v_tbl) a
		 	 WHERE a.column_value = iu.user_sid
		 )
	) LOOP
		-- User added
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'User {0} added to group {2}.',
			r.full_name,
			v_group_name
		);
	END LOOP;
	
	FOR r IN (
		SELECT a.column_value user_sid, cu.full_name
		  FROM TABLE(v_tbl) a
		  JOIN csr_user cu ON cu.csr_user_sid = a.column_value
		 WHERE cu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM initiative_user iu
		 	 WHERE iu.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND iu.initiative_sid = in_initiative_sid
		 	   AND iu.user_sid = a.column_value
		 )
	) LOOP
		-- User removed
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'User {0} removed from group {2}.',
			r.full_name,
			v_group_name
		);
	END LOOP;
END;

PROCEDURE SetUsers(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_initiative_user_group_id IN  initiative_user_group.initiative_user_group_id%TYPE,
	in_user_sids				IN	security_pkg.T_SID_IDS
)
AS
	v_audit_user_sids			security_pkg.T_SID_IDS;
	v_sid_table 				security.T_SID_TABLE;
	v_spin						BOOLEAN;
	v_flow_sid 					security_pkg.T_SID_ID;
	v_project_sid				security_pkg.T_SID_ID;
	v_synch_issues				initiative_user_group.synch_issues%TYPE;
BEGIN
	
	-- Init audit info
	INTERNAL_BeginAuditUsers(
		in_initiative_sid,
		in_initiative_user_group_id,
		v_audit_user_sids
	);
	
	v_sid_table := security_pkg.SidArrayToTable(in_user_sids);
	SELECT project_sid, flow_sid
	  INTO v_project_sid, v_flow_sid
	  FROM initiative
	 WHERE initiative_sid = in_initiative_sid;

	SELECT synch_issues
	  INTO v_synch_issues
	  FROM initiative_user_group
	 WHERE initiative_user_group_id = in_initiative_user_group_id;

	v_spin := TRUE;
	WHILE v_spin
	LOOP
		BEGIN
			-- Add new items (insert optimistically)
			FOR r IN (
				SELECT in_initiative_sid initiative_sid, in_initiative_user_group_id initiative_user_group_id, t.column_value user_sid
				  FROM TABLE(v_sid_table) t
				MINUS
				SELECT initiative_sid, initiative_user_group_id, user_sid
				  FROM initiative_user
				 WHERE initiative_sid = in_initiative_sid
				   AND initiative_user_group_id = in_initiative_user_group_id
			)
			LOOP
				INSERT INTO initiative_user (initiative_sid, initiative_user_group_id, user_sid, project_sid)
					VALUES (r.initiative_sid, r.initiative_user_group_id, r.user_sid, v_project_sid);
				
				IF v_synch_issues = 1 THEN
					INSERT INTO issue_involvement (issue_id, user_sid)
						SELECT i.issue_id, r.user_sid
						  FROM issue_initiative ii 
						  JOIN issue i ON ii.issue_initiative_id = i.issue_initiative_id
						 WHERE ii.initiative_sid = r.initiative_sid
						 MINUS
						SELECT ii.issue_id, ii.user_sid
						  FROM issue_involvement ii
						  JOIN issue i ON ii.issue_id = i.issue_id
						  JOIN issue_initiative iit ON i.issue_initiative_id = iit.issue_initiative_id
						 WHERE iit.initiative_sid = in_initiative_sid;
				END IF;
			END LOOP;
			
			-- Delete removed users (there's a cascade delete on initiative_user_flow_State)
			FOR r IN (
			 	SELECT initiative_sid, initiative_user_group_id, user_sid
				  FROM initiative_user
				 WHERE initiative_sid = in_initiative_sid
				   AND initiative_user_group_id = in_initiative_user_group_id
				MINUS
				SELECT in_initiative_sid, in_initiative_user_group_id, t.column_value
				  FROM TABLE(v_sid_table) t
			)
			LOOP
				IF v_synch_issues = 1 THEN 
					DELETE FROM issue_involvement
					 WHERE issue_id IN (
						SELECT issue_id 
						  FROM issue_initiative ii 
						  JOIN issue i ON ii.issue_initiative_id = i.issue_initiative_id 
						 WHERE initiative_sid = in_initiative_sid
					   ) 
					   AND user_sid = r.user_sid;
				END IF;
				
				DELETE FROM initiative_user
				 WHERE initiative_sid = r.initiative_sid
				   AND initiative_user_group_id = r.initiative_user_group_id
				   AND user_sid = r.user_sid;
			END LOOP;
						
			-- the spin stuff is I think an MDW idea because in theory "MINUS" can result
			-- into DUP_VAL_ON_INDEX if two inserts are done concurrently.
			v_spin := FALSE;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	-- Write audit info
	INTERNAL_EndAuditUsers(
		in_initiative_sid,
		in_initiative_user_group_id,
		v_audit_user_sids
	);
	
END;

PROCEDURE INTERNAL_BeginAuditTags(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_tag_ids					OUT security_pkg.T_SID_IDS
)
AS
BEGIN
	SELECT it.tag_id
	  BULK COLLECT INTO out_tag_ids
	  FROM initiative_tag it
	 WHERE it.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND it.initiative_sid = in_initiative_sid;
END;

PROCEDURE INTERNAL_EndAuditTags(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_tag_ids					IN	security_pkg.T_SID_IDS
)
AS
	v_tbl						security.T_SID_TABLE;					
BEGIN
	v_tbl := security_pkg.SidArrayToTable(in_tag_ids);
	
	FOR r IN (
		SELECT a.column_value tag_id, t.tag tag_name, tg.name group_name
		  FROM TABLE(v_tbl) a
		  JOIN v$tag t ON t.tag_id = a.column_value
		  JOIN tag_group_member tgm ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		  JOIN v$tag_group tg ON tg.app_sid = tgm.app_sid AND tg.tag_group_id = tgm.tag_group_id
		 WHERE t.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM initiative_tag it
		 	 WHERE it.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		 	   AND it.initiative_sid = in_initiative_sid
		 	   AND it.tag_id = a.column_value
		 )
	) LOOP
		-- Tag removed
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Tag {0}/{1} removed.',
			r.group_name,
			r.tag_name
		);
	END LOOP;
	
	FOR r IN (
		SELECT it.tag_id, t.tag tag_name, tg.name group_name
		  FROM initiative_tag it
		  JOIN v$tag t ON t.app_sid = it.app_sid AND t.tag_id = it.tag_id
		  JOIN tag_group_member tgm ON tgm.app_sid = t.app_sid AND tgm.tag_id = t.tag_id
		  JOIN v$tag_group tg ON tg.app_sid = tgm.app_sid AND tg.tag_group_id = tgm.tag_group_id
		 WHERE it.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND it.initiative_sid = in_initiative_sid
		   AND NOT EXISTS (
		 	SELECT 1
		 	  FROM TABLE(v_tbl) a
		 	 WHERE a.column_value = it.tag_id
		 )
	) LOOP
		-- Tag added
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Tag {0}/{1} added.',
			r.group_name,
			r.tag_name
		);
	END LOOP;
END;

PROCEDURE SetTags(
	in_initiative_sid 			IN	security_pkg.T_SID_ID,
	in_tag_ids					IN	security_pkg.T_SID_IDS
)
AS
	v_audit_tags				security_pkg.T_SID_IDS;
	v_tag_table 				security.T_SID_TABLE;
	v_spin						BOOLEAN;
BEGIN
	
	INTERNAL_BeginAuditTags(
		in_initiative_sid, 
		v_audit_tags
	);
	
	v_tag_table := security_pkg.SidArrayToTable(in_tag_ids);
	v_spin := TRUE;
	WHILE v_spin
	LOOP
		BEGIN
			-- Add new items (insert optimistically)
			INSERT INTO initiative_tag (initiative_sid, tag_id)
				SELECT in_initiative_sid, t.column_value
				  FROM TABLE(v_tag_table) t
				 WHERE t.column_value IS NOT NULL
			MINUS
			SELECT initiative_sid, tag_id
			  FROM initiative_tag
			 WHERE initiative_sid = in_initiative_sid;

			-- Delete removed items
			DELETE FROM initiative_tag
			 WHERE (initiative_sid, tag_id) IN (
			 	SELECT initiative_sid, tag_id
				  FROM initiative_tag
				 WHERE initiative_sid = in_initiative_sid
				MINUS
				SELECT in_initiative_sid, t.column_value
				  FROM TABLE(v_tag_table) t
			);

			v_spin := FALSE;
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	INTERNAL_EndAuditTags(
		in_initiative_sid, 
		v_audit_tags
	);
END;


PROCEDURE SetExtraInfoValue(
	in_initiative_sid	IN	security_pkg.T_SID_ID,
	in_key		    	IN	VARCHAR2,		
	in_value	    	IN	VARCHAR2
)
AS
	v_path 			VARCHAR2(255) := '/values/field[@id="'||in_key||'"]';
	v_new_node 		VARCHAR2(1024) := '<field id="'||in_key||'">'||htf.escape_sc(in_value)||'</field>';
	v_old_value	    VARCHAR2(1024);
	v_audit_fields	XMLType;
BEGIN
	-- check permission....
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.getACT, in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied altering initiative');
	END IF;
	
	SELECT XMLType(fields_xml), EXTRACTVALUE(XMLType(fields_xml), v_path) 
	  INTO v_audit_fields, v_old_value
	  FROM initiative 
	 WHERE initiative_sid = in_initiative_sid;
	
	-- XXX: this needs to be an XMLtype not a clob(!)
	UPDATE initiative
	   SET fields_xml = extract(
			CASE
				WHEN fields_xml IS NULL THEN
					APPENDCHILDXML(XMLType('<values/>'), '/values',  XmlType(v_new_node))
		    	WHEN EXISTSNODE(XMLType(fields_xml), v_path||'/text()') = 1 THEN
		    		UPDATEXML(XMLType(fields_xml), v_path||'/text()', htf.escape_sc(in_value))
		    	WHEN EXISTSNODE(XMLType(fields_xml), v_path) = 1 THEN
		    		UPDATEXML(XMLType(fields_xml), v_path, XmlType(v_new_node))
		    	ELSE
		    		APPENDCHILDXML(XMLType(fields_xml), '/values', XmlType(v_new_node))
			END, '/').getClobVal()
	WHERE initiative_sid = in_initiative_sid;
	
	-- Audit changes
	FOR r IN (
		SELECT XMLType(fields_xml) fields_xml
		  FROM initiative 
	 	 WHERE initiative_sid = in_initiative_sid
	) LOOP
		INTERNAL_AuditInfoXmlChanges(
			in_initiative_sid,
			v_audit_fields,
			r.fields_xml
		);
	END LOOP;
END;


PROCEDURE SetTeamAndSponsor(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_project_team_names		IN	T_TEAM_NAMES,
	in_project_team_emails		IN	T_TEAM_EMAILS,
	in_sponsor_names			IN	T_TEAM_NAMES,
	in_sponsor_emails			IN	T_TEAM_EMAILS
)
AS
BEGIN
	-- Project team
	-- Delete existing values
	DELETE FROM initiative_project_team
	 WHERE initiative_sid = in_initiative_sid;

	-- Insert names and emails (assumes arrays are of same length)
	IF NOT (in_project_team_names.COUNT = 0 OR (in_project_team_names.COUNT = 1 AND in_project_team_names(1) IS NULL)) THEN
		FOR i IN in_project_team_names.FIRST .. in_project_team_names.LAST
		LOOP
			INSERT INTO initiative_project_team
				(initiative_sid, name, email)
			  VALUES (in_initiative_sid, in_project_team_names(i), in_project_team_emails(i));
		END LOOP;
	END IF;

	-- Initiative sponsor
	-- Delete existing values
	DELETE FROM initiative_sponsor
	 WHERE initiative_sid = in_initiative_sid;

	-- Insert names and emails (assumes arrays are of same length)
	IF NOT (in_sponsor_names.COUNT = 0 OR (in_sponsor_names.COUNT = 1 AND in_sponsor_names(1) IS NULL)) THEN
		FOR i IN in_sponsor_names.FIRST .. in_sponsor_names.LAST
		LOOP
			INSERT INTO initiative_sponsor
				(initiative_sid, name, email)
			  VALUES (in_initiative_sid, in_sponsor_names(i), in_sponsor_emails(i));
		END LOOP;
	END IF;
END;


PROCEDURE AutoGenerateRef(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_ref						OUT	initiative.internal_ref%TYPE
)
AS
	v_ref_gen_proc				initiatives_options.initiative_name_gen_proc%TYPE;
BEGIN
	SELECT initiative_name_gen_proc
	  INTO v_ref_gen_proc
	  FROM initiatives_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF LENGTH(v_ref_gen_proc) > 0 THEN
		EXECUTE IMMEDIATE 'begin '||v_ref_gen_proc||'(:1,:2);end;'
			USING IN in_initiative_sid, OUT out_ref;
		UPDATE initiative
		   SET internal_ref = out_ref
		 WHERE initiative_sid = in_initiative_sid;
	END IF;
END;

PROCEDURE CreateDocLib(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	out_doc_lib_sid				OUT	security_pkg.T_SID_ID
)
AS
BEGIN
	-- create doclib underneath and store doclib_sid
	doc_lib_pkg.CreateLibrary(
		in_parent_sid_id	=> in_initiative_sid,
		in_library_name		=> 'DocLib',
		in_documents_name	=> 'Documents',
		in_trash_name		=> 'Recycling',
		in_app_sid			=> SYS_CONTEXT('SECURITY','APP'),
		out_doc_library_sid	=> out_doc_lib_sid
	);
	
	-- Update the initiative (if it exists)
	UPDATE initiative
	   SET doc_library_sid = out_doc_lib_sid
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_sid = in_initiative_sid;
	   
END;

PROCEDURE CreateInitiative(
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_initiative_sid	IN	security_pkg.T_SID_ID,

	in_name						IN	initiative.name%TYPE,
	in_ref						IN	initiative.internal_ref%TYPE  DEFAULT NULL,
	in_flow_state_id			IN	flow_state.flow_state_id%TYPE DEFAULT NULL,

	in_project_start_dtm		IN	initiative.project_start_dtm%TYPE,
	in_project_end_dtm			IN	initiative.project_end_dtm%TYPE,
	in_running_start_dtm		IN 	initiative.running_start_dtm%TYPE,
	in_running_end_dtm			IN 	initiative.running_end_dtm%TYPE,

	in_period_duration	        IN	initiative.period_duration%TYPE DEFAULT 1,
	in_created_by_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_created_dtm				IN	initiative.created_dtm%TYPE DEFAULT NULL,
	in_is_ramped				IN 	initiative.is_ramped%TYPE DEFAULT 0,
	in_saving_type_id			IN	initiative.saving_type_id%TYPE,

	in_fields_xml				IN	initiative.fields_xml%TYPE DEFAULT NULL,
	in_region_sids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_tags						IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_measured_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_vals			IN	initiative_metric_pkg.T_METRIC_VALS DEFAULT initiative_metric_pkg.INIT_EmptyMetricVals,
	in_proposed_uoms			IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_project_team_names		IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_project_team_emails		IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,
	in_sponsor_names			IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_sponsor_emails			IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_flow_sid 					security_pkg.T_SID_ID;
	v_flow_state_id				flow_state.flow_state_id%TYPE;
	v_live_flow_state_id		flow_state.flow_state_id%TYPE;
	v_flow_state_log_id			flow_state_log.flow_state_log_id%TYPE;
	v_flow_item_id				flow_item.flow_item_id%TYPE;
	v_initiative_sid			security_pkg.T_SID_ID;
	v_ref						initiative.internal_ref%TYPE;
	v_doc_lib_sid 				security_pkg.T_SID_ID;	
	v_helper_pkg				initiative_project.helper_pkg%TYPE;
	v_audit_row					initiative%ROWTYPE;
BEGIN

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, NVL(in_parent_initiative_sid, in_project_sid), security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to crerate initiative under parent sid ' || NVL(in_parent_initiative_sid, in_project_sid));
	END IF;	

	-- Get the flow state to use (either passed in or the default)
	SELECT p.flow_sid, NVL(in_flow_state_id, f.default_state_id), live_flow_state_id, p.helper_pkg
	  INTO v_flow_sid, v_flow_state_id, v_live_flow_state_id, v_helper_pkg
	  FROM initiative_project p, flow f
	 WHERE p.project_sid = in_project_sid
	   AND f.flow_sid = p.flow_sid;


	-- Create the securable object
	SecurableObject_Pkg.CreateSO(
		security_pkg.GetACT,
		NVL(in_parent_initiative_sid, in_project_sid),
		class_pkg.getClassID('Initiative'),
		NULL, -- Create with null name the use UniqueSORename to ensure unique
		v_initiative_sid
	);

	-- XXX: Do we care if the names in the initiative table are non unique?
	-- XXX: Do we care that the names in the initiative tabel don't exactly match the ones in the security tree?
/*	utils_pkg.UniqueSORename(
		security_pkg.GetACT,
		v_initiative_sid,
		SUBSTR(Replace(in_name,'/','\'), 0, 255) --'
	);
*/
	-- Create the document library under the initiative node
	CreateDocLib(
		v_initiative_sid,
		v_doc_lib_sid
	);

	-- Create the associated flow item.
	INSERT INTO flow_item
		(flow_item_id, flow_sid, current_state_id)
	VALUES
		(flow_item_id_seq.NEXTVAL, v_flow_sid, v_flow_state_id)
	RETURNING
		flow_item_id INTO v_flow_item_id;

	v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => v_flow_item_id);


	-- Create the initiative table entry
	INSERT INTO initiative
		(initiative_sid, project_sid, parent_sid, flow_sid, flow_item_id, name, doc_library_sid,
			project_start_dtm, project_end_dtm, running_start_dtm, running_end_dtm,
			fields_xml, internal_ref, period_duration, created_by_sid, created_dtm, is_ramped, saving_type_id)
	VALUES
		(v_initiative_sid, in_project_sid, in_parent_initiative_sid, v_flow_sid, v_flow_item_id, in_name, v_doc_lib_sid,
	  		in_project_start_dtm, in_project_end_dtm, in_running_start_dtm, in_running_end_dtm,
	  		in_fields_xml, in_ref, in_period_duration, security_pkg.GetSID, NVL(in_created_dtm, SYSDATE), in_is_ramped, in_saving_type_id);


	-- Audit the fact that the initiative was just created
	csr_data_pkg.WriteAuditLogEntry(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		v_initiative_sid,
		'Initiative created'
	);

	-- Regions
	SetRegions(v_initiative_sid, in_region_sids);

	-- Tags
	SetTags(v_initiative_sid, in_tags);

	-- Team/Sponsor
	SetTeamAndSponsor(
		v_initiative_sid,
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_names,
		in_sponsor_emails
	);

	-- Create metric instances
	initiative_metric_pkg.SetNullMetricVal(
		v_initiative_sid,
		in_measured_ids
	);

	-- Set metric values
	initiative_metric_pkg.SetMetricVals(
		v_initiative_sid,
		in_proposed_ids,
		in_proposed_vals,
		in_proposed_uoms
	);

	-- If the caller passd in in a non-null then use that, other wise generate one
	IF in_ref IS NULL THEN
		-- Right now the initiative is created we might
		-- want to generate a new reference using a helper procedure
		-- AutoGenerateRef will not modify the reference if no
		-- helper is specified in customer options
		AutoGenerateRef(v_initiative_sid, v_ref);
	ELSE
		-- Check reference is unique
		INTERNAL_CheckReference(v_initiative_sid, in_ref);
	END IF;

	initiative_aggr_pkg.RefreshAggrVals(v_initiative_sid);

	-- call helper?
	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
		    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.CreateInitiative(:1);end;'
				USING v_initiative_sid;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	-- Write out details to audit log (v_audit_row is empty)
	-- XXX: Do we want to write out all the details when the initiative is created?
	INTERNAL_EndAuditInitiative(v_initiative_sid, v_audit_row);

	OPEN out_cur FOR
		SELECT initiative_sid, name, internal_ref
		  FROM initiative
		 WHERE initiative_sid = v_initiative_sid;
END;

PROCEDURE AmendInitiative(
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_project_sid				IN	security_pkg.T_SID_ID,
	in_parent_initiative_sid	IN	security_pkg.T_SID_ID,

	in_name						IN	initiative.name%TYPE,
	in_ref						IN	initiative.internal_ref%TYPE,
	in_flow_state_id			IN	flow_state.flow_state_id%TYPE DEFAULT NULL,

	in_project_start_dtm		IN	initiative.project_start_dtm%TYPE,
	in_project_end_dtm			IN	initiative.project_end_dtm%TYPE,
	in_running_start_dtm		IN 	initiative.running_start_dtm%TYPE,
	in_running_end_dtm			IN 	initiative.running_end_dtm%TYPE,

	in_period_duration	        IN	initiative.period_duration%TYPE DEFAULT 1,
	in_created_by_sid			IN	security_pkg.T_SID_ID DEFAULT NULL,
	in_created_dtm				IN	initiative.created_dtm%TYPE DEFAULT NULL,
	in_is_ramped				IN 	initiative.is_ramped%TYPE DEFAULT 0,
	in_saving_type_id			IN	initiative.saving_type_id%TYPE,

	in_fields_xml				IN	initiative.fields_xml%TYPE DEFAULT NULL,
	in_region_sids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_tags						IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_measured_valid			IN	NUMBER DEFAULT 0,
	in_measured_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_proposed_valid			IN	NUMBER DEFAULT 0,
	in_proposed_ids				IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,
	in_proposed_vals			IN	initiative_metric_pkg.T_METRIC_VALS DEFAULT initiative_metric_pkg.INIT_EmptyMetricVals,
	in_proposed_uoms			IN	security_pkg.T_SID_IDS DEFAULT INIT_EmptySidIds,

	in_project_team_valid		IN	NUMBER DEFAULT 0,
	in_project_team_names		IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_project_team_emails		IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	in_sponsor_valid			IN	NUMBER DEFAULT 0,
	in_sponsor_names			IN	T_TEAM_NAMES DEFAULT INIT_EmptyTeamNames,
	in_sponsor_emails			IN	T_TEAM_EMAILS DEFAULT INIT_EmptyTeamEmails,

	out_cur						OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_project_sid				security_pkg.T_SID_ID;
	v_update_ref_on_amend		NUMBER(1) := 0;
	v_flow_item_id				initiative.flow_item_id%TYPE;
	v_flow_state_log_id			flow_state_log.flow_state_log_id%TYPE;
	v_current_state_id			flow_item.current_state_id%TYPE;
	v_flow_state_id				flow_item.current_state_id%TYPE;
	v_flow_sid					security_pkg.T_SID_ID;
	v_old_name					initiative.name%TYPE;
	v_old_parent_sid			security_pkg.T_SID_ID;
	v_ref						initiative.internal_ref%TYPE;
	v_helper_pkg				initiative_project.helper_pkg%TYPE;
	v_audit_row					initiative%ROWTYPE;
	v_is_running				initiative_saving_type.is_running%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to amend initiative with sid ' || in_initiative_sid);
	END IF;

	-- If the project changed then we need to delete the initiative and start again
	SELECT project_sid
	  INTO v_project_sid
	  FROM initiative
	 WHERE initiative_sid = in_initiative_sid;

	 -- Get get some information about the initiative
	SELECT i.flow_item_id, f.current_state_id, i.name, i.parent_sid, NVL(in_flow_state_id, f.current_state_id), i.flow_sid
	  INTO v_flow_item_id, v_current_state_id, v_old_name, v_old_parent_sid, v_flow_state_id, v_flow_sid
	  FROM initiative i, flow_item f
	 WHERE i.initiative_sid = in_initiative_sid
	   AND f.flow_item_id = i.flow_item_id;

	-- Fetch initial state for audit
	INTERNAL_BeginAuditInitiative(in_initiative_sid, v_audit_row);

	-- Parent changed
	IF in_parent_initiative_sid != v_old_parent_sid THEN
		-- NULL out the name before moving
		securableobject_pkg.RenameSO(
			security_pkg.GetACT,
			in_initiative_sid,
			NULL
		);
		-- Move the object
		securableobject_pkg.MoveSO(
			security_pkg.GetACT,
			in_initiative_sid,
			in_parent_initiative_sid
		);
	END IF;

	-- Object moved or name changed
	IF in_parent_initiative_sid != v_old_parent_sid OR in_name != v_old_name THEN
		-- XXX: Do we care if the names in the initiative table are non unique?
		-- XXX: Do we care that the names in the initiative tabel don't exactly match the ones in the security tree?
		utils_pkg.UniqueSORename(
			security_pkg.GetACT,
			in_initiative_sid,
			SUBSTR(Replace(in_name,'/','\'), 0, 255) -- '
		);
	END IF;

  -- Update the related inititiative_user table
	UPDATE initiative_user
       SET project_sid = in_project_sid
     WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
       AND initiative_sid = in_initiative_sid
       AND project_sid = v_project_sid;
	   
	-- Determine the is_running value based on the incoming saving_type parameter
	SELECT t.is_running
	  INTO v_is_running
	  FROM initiative_saving_type t
	 WHERE t.saving_type_id = in_saving_type_id;
	 
	-- Update the initiative table
	IF v_is_running = 0 THEN  -- Temporary so not interested in any ongoing/running dates.
		UPDATE initiative
			SET parent_sid			= NVL(in_parent_initiative_sid, parent_sid),
				name				= in_name,
				project_sid			= in_project_sid,
				internal_ref		= in_ref,
				project_start_dtm	= in_project_start_dtm,	
				project_end_dtm		= in_project_end_dtm,	
				running_start_dtm	= null,					
				running_end_dtm		= null,					
				fields_xml			= in_fields_xml,
				period_duration		= in_period_duration,
				created_by_sid		= NVL(in_created_by_sid, created_by_sid),
				created_dtm			= NVL(in_created_dtm, created_dtm),
				is_ramped			= in_is_ramped,
				saving_type_id		= in_saving_type_id
		 WHERE   initiative_sid      = in_initiative_sid;
	ELSE  -- Ongoing so both temp/project and ongoing/running dates are possible
		UPDATE initiative
			SET parent_sid			= NVL(in_parent_initiative_sid, parent_sid),
				name				= in_name,
				project_sid			= in_project_sid,
				internal_ref		= in_ref,
				project_start_dtm	= in_project_start_dtm,	
				project_end_dtm		= in_project_end_dtm,	
				running_start_dtm	= in_running_start_dtm,	
				running_end_dtm		= in_running_end_dtm,	
				fields_xml			= in_fields_xml,
				period_duration		= in_period_duration,
				created_by_sid		= NVL(in_created_by_sid, created_by_sid),
				created_dtm			= NVL(in_created_dtm, created_dtm),
				is_ramped			= in_is_ramped,
				saving_type_id		= in_saving_type_id
		 WHERE   initiative_sid      = in_initiative_sid;
	END IF;

	-- Update the flow state
	-- XXX: We might want to check the state change corrasponds to a valid transition.
	-- State updates carried out via ament initiative here will probably come
	-- from an import, so the state might be getting a correction?
	-- Here a NULL state passed in  means "leave it alone"
	IF in_flow_state_id IS NOT NULL THEN
		UPDATE flow_item
		   SET current_state_id = in_flow_state_id
		 WHERE flow_item_id = v_flow_item_id;
		v_flow_state_log_id := flow_pkg.AddToLog(in_flow_item_id => v_flow_item_id);
	END IF;

	-- Regions
	SetRegions(in_initiative_sid, in_region_sids);

	-- Tags
	SetTags(in_initiative_sid, in_tags);

	-- Team/Sponsor
	SetTeamAndSponsor(
		in_initiative_sid,
		in_project_team_names,
		in_project_team_emails,
		in_sponsor_names,
		in_sponsor_emails
	);
	
	-- Clear up any existing metrics that AREN'T associated with this project.
	-- This prevents adding metrics that already exist for an initiative that has had it's project changed.
	DELETE FROM initiative_metric_val
	 WHERE project_sid != in_project_sid
	   AND initiative_sid = in_initiative_sid;

	-- Create metric instances
	initiative_metric_pkg.SetNullMetricVal(
		in_initiative_sid,
		in_measured_ids
	);

	-- Set metric values
	initiative_metric_pkg.SetMetricVals(
		in_initiative_sid,
		in_proposed_ids,
		in_proposed_vals,
		in_proposed_uoms
	);

	-- Only generate a new referecne if that option is
	-- enabled and the caller hasn't specified a reference.
	SELECT update_ref_on_amend
	  INTO v_update_ref_on_amend
	  FROM initiatives_options
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

	IF in_ref IS NULL AND v_update_ref_on_amend != 0 THEN
		-- Generating new references may be desirabe if the client uses
		-- information that may have changed to generate the reference.
		AutoGenerateRef(in_initiative_sid, v_ref);
	ELSE
		-- Check reference is unique
		INTERNAL_CheckReference(in_initiative_sid, in_ref);
	END IF;

	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);

	-- call helper?		
	SELECT p.helper_pkg
	  INTO v_helper_pkg
	  FROM initiative i
	  JOIN initiative_project p ON i.project_sid = p.project_sid
	 WHERE i.initiative_sid = in_initiative_sid;

	IF v_helper_pkg IS NOT NULL THEN
		BEGIN
		    EXECUTE IMMEDIATE 'begin '||v_helper_pkg||'.AmendInitiative(:1);end;'
				USING in_initiative_sid;
		EXCEPTION
			WHEN PROC_NOT_FOUND THEN
				NULL; -- it is acceptable that it is not supported
		END;
	END IF;
	
	INTERNAL_EndAuditInitiative(in_initiative_sid, v_audit_row);

	-- Seelct current name and sid
	OPEN out_cur FOR
		SELECT initiative_sid, name, internal_ref
		  FROM initiative
		 WHERE initiative_sid = in_initiative_sid;

END;

FUNCTION HasAuditAccess (
	in_initiative_sid			IN	security_pkg.T_SID_ID
) RETURN BOOLEAN
AS
BEGIN
	IF security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) AND
	   csr_data_pkg.CheckCapability('View initiatives audit log') THEN
		RETURN TRUE;
	END IF;  

	RETURN FALSE;
END;

PROCEDURE GetInitiativeDetails(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_is_viewable_audit		NUMBER(1):= 0;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	IF HasAuditAccess(in_initiative_sid) THEN
		v_is_viewable_audit:= 1;
	END IF;
	
	OPEN out_cur FOR
		SELECT i.initiative_sid, i.project_sid, ip.name project_name, i.parent_sid, i.flow_sid, i.flow_item_id, i.name, i.doc_library_sid,
			i.project_start_dtm, i.project_end_dtm, i.running_start_dtm, i.running_end_dtm, i.rag_status_id,
			i.fields_xml, i.internal_ref, i.period_duration, i.created_by_sid, i.created_dtm, i.is_ramped, i.saving_type_id,
			f.current_state_id, s.label state_label, s.lookup_key state_lookup, s.attributes_xml state_attributes_xml,
			s.is_deleted state_is_deleted, s.state_colour, s.is_final state_is_final,
			NVL(mi.is_editable, 0) is_editable,
			v_is_viewable_audit is_viewable_audit
		  FROM initiative i
		  JOIN initiative_project ip ON ip.app_sid = i.app_sid AND ip.project_sid = i.project_sid
		  JOIN flow_item f ON i.flow_item_id = f.flow_item_id AND i.app_sid = f.app_sid
		  JOIN flow_state s ON f.current_state_id = s.flow_state_id AND f.app_sid = s.app_sid
		  -- We can't just use v$my_initiatives instead of initiatives because the importer relies 
		  -- on being able to get initiative details for any initiative regardless of user association, 
		  -- ultimatley using this procedure via the object model (the importer doesn't care about the is_editable flag).
		  LEFT JOIN (
		  	-- XXX: Can't remember if there's a good reasing v$my_initiatives returns more than one row for 
		  	-- an initiative if the role matches *and* the user is associated with th einitiaitve. 
		  	-- It's quite possible this behaviour is ueed somewhere.
		  	SELECT initiative_sid, MAX(is_editable) is_editable
		  	  FROM v$my_initiatives
		  	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		  	   AND initiative_sid = in_initiative_sid
		  	 GROUP BY initiative_sid
		  ) mi ON mi.initiative_sid = i.initiative_sid
		 WHERE i.initiative_sid = in_initiative_sid;
END;

PROCEDURE SaveComment(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_comment_text			IN  initiative_comment.comment_text%TYPE
)
AS
BEGIN
	-- TODO: anyone who can see can add a comment -- is that right?
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	INSERT INTO initiative_comment (initiative_comment_id, initiative_sid, user_sid, posted_dtm, comment_text)
		VALUES (initiative_comment_id_seq.nextval, in_initiative_sid, SYS_CONTEXT('SECURITY','SID'), SYSDATE, in_comment_text);
END;
		

PROCEDURE GetInitiativeComments(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	OPEN out_cur FOR
		SELECT ic.initiative_comment_id, ic.user_sid, cu.full_name, cu.email, ic.posted_dtm, ic.comment_text
		  FROM initiative_comment ic
		  JOIN csr_user cu ON ic.user_sid = cu.csr_user_sid AND ic.app_sid = cu.app_sid
		 WHERE initiative_sid = in_initiative_sid
		 ORDER BY posted_dtm DESC;
END;


PROCEDURE GetInitiativeRegions(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	OPEN out_cur FOR
		SELECT ir.initiative_sid, ir.region_sid, r.description, r.region_ref
		  FROM initiative_region ir, v$region r
		 WHERE r.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ir.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND ir.initiative_sid = in_initiative_sid
		   AND r.region_sid = ir.region_sid;
END;


PROCEDURE GetUserGroups(
	out_cur		OUT	SYS_REFCURSOR
)
AS
BEGIN
	-- security?
	OPEN out_cur FOR
		SELECT initiative_user_group_id, lookup_key, label 
		  FROM initiative_user_group
		 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
END;

PROCEDURE GetTagGroups(
	out_cur		OUT	SYS_REFCURSOR,
	out_members OUT SYS_REFCURSOR
)
AS
BEGIN
	-- what permissions should we check for this?

	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name, tg.multi_select, tg.mandatory, tg.lookup_key
		  FROM v$tag_group tg
		 WHERE tg.applies_to_initiatives = 1
		 ORDER BY tg.name;
	
	OPEN out_members FOR
		SELECT tg.tag_group_id, t.tag_id, t.tag, t.lookup_key
		  FROM tag_group tg 
			JOIN tag_group_member tgm ON tg.tag_group_id = tgm.tag_group_id AND tg.app_sid = tgm.app_sid
			JOIN v$tag t ON tgm.tag_Id = t.tag_id AND tgm.app_sid = t.app_sid
		 WHERE tg.applies_to_initiatives = 1
		 ORDER BY tg.tag_group_id, tgm.pos;
END;


PROCEDURE GetInitiativeTags(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	OPEN out_cur FOR
		SELECT tg.tag_group_id, tg.name tag_group_name, t.tag_id, t.tag tag_value
		  FROM initiative_tag tt, v$tag t, tag_group_member tgm, v$tag_group tg
		 WHERE tt.initiative_sid = in_initiative_sid
		   AND t.tag_id = tt.tag_id
		   AND tgm.tag_id = t.tag_id
		   AND tg.tag_group_id = tgm.tag_group_id;

END;


PROCEDURE GetInitiativeUsers(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_users_cur			OUT	security_pkg.T_OUTPUT_CUR,
	out_groups_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	OPEN out_users_cur FOR
		SELECT iu.initiative_sid, u.csr_user_sid user_sid, u.user_name, u.full_name, u.email, NVL(igfs.is_editable,0) is_editable,
			ipug.initiative_user_group_id
		  FROM initiative_user iu
		  JOIN v$csr_user u ON iu.user_sid = u.csr_user_sid AND iu.app_sid = u.app_sid
		  JOIN initiative i ON iu.initiative_sid = i.initiative_sid AND iu.app_sid = i.app_sid
		  JOIN flow_item fi ON i.flow_item_id = fi.flow_item_id AND i.app_sid = fi.app_sid
		  JOIN initiative_project_user_group ipug
		    ON iu.initiative_user_group_id = ipug.initiative_user_group_id 
		   AND iu.project_sid = ipug.project_sid
		   AND iu.app_sid = ipug.app_sid
		  LEFT JOIN initiative_group_flow_state igfs 
		    ON iu.initiative_user_group_id = igfs.initiative_user_group_id
		   AND fi.current_state_id = igfs.flow_state_id
		   AND iu.app_sid = igfs.app_sid
		   AND igfs.project_sid = i.project_sid
		 WHERE iu.initiative_sid = in_initiative_sid
		   AND u.active = 1;

	OPEN out_groups_cur FOR
		SELECT iug.initiative_user_group_id, iug.label, iug.lookup_key
		  FROM initiative_user_group iug
		  JOIN initiative_project_user_group ipug ON iug.initiative_user_group_id = ipug.initiative_user_group_id AND iug.app_sid = ipug.app_sid
		  JOIN initiative i ON ipug.project_sid = i.project_sid AND ipug.app_sid = i.app_sid
		 WHERE i.initiative_sid = in_initiative_sid
		 ORDER BY iug.label;
END;

PROCEDURE GetInitiativeTeam(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, email
		  FROM initiative_project_team
		 WHERE initiative_sid = in_initiative_sid
		 	ORDER BY name;
END;

PROCEDURE GetInitiativeSponsors(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT name, email
		  FROM initiative_sponsor
		 WHERE initiative_sid = in_initiative_sid
		 	ORDER BY name;
END;

PROCEDURE GetInitiativeIssues(
	in_initiative_sid	IN	initiative.initiative_sid%TYPE,
	out_cur				OUT SYS_REFCURSOR
)
AS
	v_user_sid				security_pkg.T_SID_ID;
	v_show_rag_status		NUMBER(1);
BEGIN
	v_user_sid := security_pkg.GetSID;

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	SELECT CASE WHEN COUNT(*) > 0 THEN 1 ELSE 0 END
	  INTO v_show_rag_status
	  FROM issue_initiative ii
	  JOIN issue i ON ii.app_sid = i.app_sid AND ii.issue_initiative_id = i.issue_initiative_id
	  JOIN issue_type_rag_status itrs ON itrs.app_sid = i.app_sid AND itrs.issue_type_id = i.issue_type_id
	 WHERE ii.initiative_sid = in_initiative_sid;
	
	OPEN out_cur FOR
		SELECT	i.issue_id, i.label, i.description, i.due_dtm, i.raised_dtm, i.resolved_dtm,
				i.manual_completion_dtm, i.manual_comp_dtm_set_dtm, i.is_critical,
				i.region_sid, re.description region_name,
				i.assigned_to_role_sid, r.name assigned_to_role_name,
				i.assigned_to_user_sid, cuass.full_name assigned_to_full_name,
				i.raised_by_user_sid, curai.full_name raised_by_full_name,
				i.closed_dtm, itrs.label rag_status_label, itrs.colour rag_status_colour, v_show_rag_status show_rag_status,
				ii.issue_initiative_id,
				ist.issue_type_id, ist.label issue_type_label,
				CASE
					WHEN i.closed_dtm IS NOT NULL
					THEN 'Closed'
					WHEN i.resolved_dtm IS NOT NULL
					THEN 'Resolved'
					WHEN i.rejected_dtm IS NOT NULL
					THEN 'Rejected'
					ELSE 'Ongoing'
				END status,
				CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1 END is_closed,
				CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1 END is_resolved,
				CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1 END is_rejected,
				CASE
					WHEN closed_by_user_sid  IS NULL
						 AND resolved_by_user_sid IS NULL
						 AND rejected_by_user_sid IS NULL
						 AND SYSDATE > NVL(forecast_dtm, due_dtm)
					THEN 1
					ELSE 0
				END is_overdue,
				CASE WHEN i.assigned_to_user_sid = v_user_sid OR iiu.user_sid IS NOT NULL THEN 1 ELSE 0 END is_involved
		  FROM	issue i, issue_initiative ii, issue_type ist, v$issue_involved_user iiu,
				csr_user curai, csr_user cuass, role r, v$region re, v$issue_type_rag_status itrs
		 WHERE	i.app_sid = ii.app_sid
		   AND	i.deleted = 0
		   AND	i.issue_initiative_id = ii.issue_initiative_id
		   AND	ii.initiative_sid = in_initiative_sid
		   AND	i.app_sid = ist.app_sid
		   AND i.issue_type_id = ist.issue_type_id
		   AND i.app_sid = iiu.app_sid(+)
		   AND i.issue_id = iiu.issue_id(+)
		   AND v_user_sid = iiu.user_sid(+)
		   AND i.app_sid = curai.app_sid(+)
		   AND i.raised_by_user_sid = curai.csr_user_sid(+)
		   AND i.app_sid = cuass.app_sid(+)
		   AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
		   AND i.app_sid = r.app_sid(+)
		   AND i.assigned_to_role_sid = r.role_sid(+)
		   AND i.app_sid = re.app_sid(+)
		   AND i.region_sid = re.region_sid(+)
		   AND i.app_sid = itrs.app_sid(+)
		   AND i.rag_status_id = itrs.rag_status_id(+)
		   AND i.issue_type_id = itrs.issue_type_id(+)
		 ORDER BY i.issue_initiative_id DESC;
END;

PROCEDURE GetIssuesByDueDtm (
	in_initiative_sid			IN	security_pkg.T_SID_ID,
	in_start_dtm				IN	issue.due_dtm%TYPE,
	in_end_dtm					IN	issue.due_dtm%TYPE,
	in_my_issues				IN	NUMBER,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- some security check
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT vi.issue_id, vi.status, vi.issue_type_label, vi.is_overdue, vi.is_closed,
			   vi.is_rejected, vi.is_resolved, vi.label, vi.description, vi.source_label, vi.raised_full_name,
			   vi.assigned_to_full_name, vi.assigned_to_role_name, vi.due_dtm, vi.raised_dtm,
			   vi.forecast_dtm, vi.show_forecast_dtm, vi.resolved_dtm, vi.manual_completion_dtm, vi.is_critical
		  FROM issue_initiative ii 
		  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_initiative_id = ii.issue_initiative_id
		  JOIN v$issue vi ON vi.app_sid = i.app_sid AND vi.issue_id = i.issue_id
		 WHERE ii.initiative_sid = in_initiative_sid
		   AND COALESCE(vi.manual_completion_dtm, vi.resolved_dtm, vi.forecast_dtm, vi.due_dtm) >= in_start_dtm
		   AND COALESCE(vi.manual_completion_dtm, vi.resolved_dtm, vi.forecast_dtm, vi.due_dtm) < in_end_dtm
		   AND (in_my_issues = 0 OR (
				vi.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
				OR vi.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
				OR vi.issue_id IN (
					SELECT issue_id 
					  FROM issue_involvement 
					 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
					   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
				))
		   )
		 ORDER BY NVL(vi.resolved_dtm, NVL(vi.forecast_dtm, vi.due_dtm));
END;

PROCEDURE GetInitiative(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_initiative			OUT	security_pkg.T_OUTPUT_CUR,
	out_regions				OUT	security_pkg.T_OUTPUT_CUR,
	out_tags				OUT	security_pkg.T_OUTPUT_CUR,
	out_users				OUT	security_pkg.T_OUTPUT_CUR,
	out_user_groups			OUT	security_pkg.T_OUTPUT_CUR,
	out_metrics				OUT	security_pkg.T_OUTPUT_CUR,
	out_uoms				OUT	security_pkg.T_OUTPUT_CUR,
	out_assoc				OUT	security_pkg.T_OUTPUT_CUR,
	out_team				OUT	security_pkg.T_OUTPUT_CUR,
	out_sponsor				OUT	security_pkg.T_OUTPUT_CUR,
	out_issues				OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_teamroom_sid	NUMBER(10);
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;
	
	-- Check if the initiative is from a teamroom. If it is, make sure user has access to the teamroom#
	BEGIN
		SELECT teamroom_sid
		  INTO v_teamroom_sid
		  FROM teamroom_initiative 
		 WHERE initiative_sid = in_initiative_sid;
		EXCEPTION 
			 WHEN NO_DATA_FOUND THEN
				NULL;
	END;
	
	IF v_teamroom_sid IS NOT NULL THEN
	BEGIN
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_teamroom_sid, security_pkg.PERMISSION_READ) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read teamroom initiative with sid ' || in_initiative_sid);
		END IF;
	END;
	END IF;
	
	-- TODO: should this check the workflow to see if it's visible?
	-- or do we assume that security has ultimate say-so, so hiding it via workflow
	-- is merely a cosmetic thing?

	GetInitiativeDetails(in_initiative_sid, out_initiative);
	GetInitiativeRegions(in_initiative_sid, out_regions);
	GetInitiativeTags(in_initiative_sid, out_tags);
	GetInitiativeUsers(in_initiative_sid, out_users, out_user_groups);
	initiative_metric_pkg.GetInitiativeMetrics(in_initiative_sid, out_metrics, out_uoms, out_assoc);
	GetInitiativeTeam(in_initiative_sid, out_team);
	GetInitiativeSponsors(in_initiative_sid, out_sponsor);
	GetInitiativeIssues(in_initiative_sid, out_issues);
END;

PROCEDURE GetAllowedTransitions(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	OPEN out_cur FOR
		-- Transiations available based on role, initiative and initiative's associated regions
		SELECT DISTINCT trm.flow_item_id, trm.flow_state_transition_id, trm.verb, trm.from_state_id, trm.to_state_id,
			trm.transition_pos, trm.from_state_label, trm.to_state_label, trm.ask_for_comment, trm.to_state_colour, trm.button_icon_path --, trm.is_final
		  FROM v$flow_item_trans_role_member trm, initiative i, initiative_region r
		 WHERE trm.flow_item_id = i.flow_item_id
		   AND r.initiative_sid = i.initiative_sid
		   AND trm.region_sid = r.region_sid
		   AND i.initiative_sid = in_initiative_sid
			ORDER BY transition_pos;
END;

PROCEDURE SetState(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment				IN	flow_state_log.comment_text%TYPE
)
AS
	v_to_state_id			flow_state.flow_state_id%TYPE;
	v_to_state_label		flow_state.label%TYPE;
BEGIN
	SetState(
		in_initiative_sid,
		in_transition_id,
		in_comment,
		v_to_state_id,
		v_to_state_label
	);
END;		

PROCEDURE SetState(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_transition_id		IN	flow_state_transition.flow_state_transition_id%TYPE,
	in_comment				IN	flow_state_log.comment_text%TYPE,
	out_to_state_id			OUT	flow_state.flow_state_id%TYPE,
	out_to_state_label		OUT	flow_state.label%TYPE
)
AS
	v_flow_sid				security_pkg.T_SID_ID;
	v_flow_item_id			flow_item.flow_item_id%TYPE;
	v_to_state_id			flow_state.flow_state_id%TYPE;
	v_cache_keys			security_pkg.T_VARCHAR2_ARRAY;
	v_from_state_id			flow_state.flow_state_id%TYPE;
	v_from_state_label		flow_state.label%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to write initiative with sid ' || in_initiative_sid);
	END IF;

	SELECT i.flow_sid, i.flow_item_id, fi.current_state_id, fs.label
	  INTO v_flow_sid, v_flow_item_id, v_from_state_id, v_from_state_label
	  FROM initiative i
	  JOIN flow_item fi ON fi.flow_sid = i.flow_sid AND fi.flow_item_id = i.flow_item_id
	  JOIN flow_State fs ON fs.flow_sid = i.flow_sid AND fs.flow_state_id = fi.current_state_id
	 WHERE i.initiative_sid = in_initiative_sid;

	SELECT to_state_id
	  INTO v_to_state_id
	  FROM flow_state_transition
	 WHERE flow_sid = v_flow_sid
	   AND flow_state_transition_id = in_transition_id;

	flow_pkg.SetItemState(
		in_flow_item_id		=> v_flow_item_id,
		in_to_state_id		=> v_to_state_id,
		in_comment_text		=> in_comment,
		in_cache_keys		=> v_cache_keys,
		in_force			=> 0,
		in_cancel_alerts	=> 0
	);

	-- get the new state
	SELECT fi.current_state_id, fs.label
	  INTO out_to_state_id, out_to_state_label
	  FROM flow_item fi
	  JOIN flow_state fs ON fs.flow_sid = fi.flow_sid AND fs.flow_state_id = fi.current_state_id
	 WHERE flow_item_id = v_flow_item_id;

	initiative_aggr_pkg.RefreshAggrVals(in_initiative_sid);
	
	-- Audit any changes to state
	csr_data_pkg.AuditValueDescChange(
		security_pkg.GetACT,
		csr_data_pkg.AUDIT_TYPE_INITIATIVE,
		security_pkg.GetAPP,
		in_initiative_sid,
		'Initiative state',
		v_from_state_id,
		out_to_state_id,
		v_from_state_label,
		out_to_state_label
	);	
END;

PROCEDURE AddIssue(
	in_initiative_sid				IN initiative.initiative_sid%TYPE,
	in_label						IN	issue.label%TYPE,
	in_description					IN	issue_log.message%TYPE,
	in_issue_type_id				IN	issue.issue_type_id%TYPE,
	in_due_dtm						IN	issue.due_dtm%TYPE,
	in_source_url					IN	issue.source_url%TYPE,
	in_assigned_to_user_sid			IN	issue.assigned_to_user_sid%TYPE,
	in_is_urgent					IN	NUMBER,
	in_is_critical					IN	issue.is_critical%TYPE DEFAULT 0,
	out_issue_id					OUT issue.issue_id%TYPE
)
AS
	v_issue_initiative_id	issue_initiative.issue_initiative_id%TYPE;
BEGIN
	issue_pkg.CreateIssue(
		in_label				=> in_label,
		in_description			=> in_description,
		in_source_label			=> NULL,
		in_issue_type_id		=> in_issue_type_id,
		in_correspondent_id		=> NULL,
		in_raised_by_user_sid	=> SYS_CONTEXT('SECURITY', 'SID'),
		in_assigned_to_user_sid	=> in_assigned_to_user_sid,
		in_assigned_to_role_sid	=> NULL,
		in_priority_id			=> NULL,
		in_due_dtm				=> in_due_dtm,
		in_source_url			=> in_source_url,
		in_region_sid			=> NULL,
		in_is_urgent			=> in_is_urgent,
		in_is_critical			=> in_is_critical,
		out_issue_id			=> out_issue_id
	);

	INSERT INTO issue_initiative (issue_initiative_id, initiative_sid) VALUES (issue_initiative_id_seq.NEXTVAL, in_initiative_sid)
	RETURNING issue_initiative_id INTO v_issue_initiative_id;
	
	-- stick in users ( this ought to be based upon some setting in INITIATIVE_PROJECT_USER_GROUP?)
	INSERT INTO issue_involvement (issue_id, user_sid)
		SELECT DISTINCT out_issue_Id, iu.user_sid
		  FROM initiative_user iu
		  JOIN initiative_project_user_group ipug ON iu.initiative_user_group_id = ipug.initiative_user_group_id AND iu.project_sid = ipug.project_sid 
		  JOIN initiative_user_group iug ON ipug.initiative_user_group_id = iug.initiative_user_group_id
		 WHERE iug.synch_issues = 1
		   AND iu.initiative_sid = in_initiative_sid
		   AND iu.user_sid NOT IN (
			SELECT user_sid FROM issue_involvement WHERE issue_id = out_issue_id
		 );
		 
	UPDATE issue 
	   SET issue_initiative_id = v_issue_initiative_id
	 WHERE issue_id = out_issue_id;
END;

PROCEDURE GetSavingTypes (
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
As
BEGIN
	OPEN out_cur FOR
		SELECT st.saving_type_id, st.lookup_key, st.label, 
			NVL(cst.is_during, st.is_during) is_during,
			NVL(cst.is_running, st.is_running) is_running
		  FROM customer_init_saving_type cst, initiative_saving_type st
		 WHERE cst.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND cst.saving_type_id = st.saving_type_id
		   	ORDER BY st.saving_type_id; -- XXX Add pos to cst
END;

PROCEDURE GetUpcomingEvents(
	in_initiative_sid	IN 	security_pkg.T_SID_ID,
	in_max_events		IN	NUMBER,	
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT * 
		FROM (
			SELECT ie.initiative_event_id event_id, 'event' event_type, ie.description, ie.start_dtm event_date, 
				ie.created_by_sid, ie.created_dtm
			  FROM initiative_event ie
			 WHERE ie.initiative_sid = in_initiative_sid
			   AND ie.start_dtm > SYSDATE			 
			 UNION	
			SELECT i.issue_id event_id, 'issue' event_type, i.label description, COALESCE(i.manual_completion_dtm, i.resolved_dtm, i.forecast_dtm, i.due_dtm) event_date,
				i.raised_by_user_sid created_by_sid, i.raised_dtm created_dtm					
			  FROM issue_initiative ii 
			  JOIN issue i ON i.app_sid = ii.app_sid AND i.issue_initiative_id = ii.issue_initiative_id
			 WHERE ii.initiative_sid = in_initiative_sid
			   AND i.deleted = 0
			   AND COALESCE(i.manual_completion_dtm, i.resolved_dtm, i.forecast_dtm, i.due_dtm) > SYSDATE
			   -- limit to my issues only
			   AND (i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') 
					OR i.assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID')
					OR i.issue_id IN (
						SELECT issue_id 
						  FROM issue_involvement 
						 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
						   AND user_sid = SYS_CONTEXT('SECURITY', 'SID')
					)
				)
			ORDER BY event_date
		)		
		WHERE ROWNUM <= in_max_events;		
END;

PROCEDURE GetEvents(
	in_start_dtm		IN	DATE,
	in_end_dtm			IN	DATE,
	in_initiative_sid 	IN 	security_pkg.T_SID_ID,
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT DISTINCT ie.initiative_sid, i.name initiative_name, ie.initiative_event_id event_id, ie.description, ie.start_dtm, ie.end_dtm, ie.location, ie.created_by_sid, ie.created_dtm
		  FROM initiative_event ie
		  JOIN v$my_initiatives mi ON mi.app_sid = ie.app_sid AND mi.initiative_sid = ie.initiative_sid
		  JOIN initiative i ON i.app_sid = mi.app_sid AND i.initiative_sid = mi.initiative_sid
		 WHERE (in_initiative_sid IS NULL OR ie.initiative_sid = in_initiative_sid)
		   AND (in_start_dtm IS NULL OR ie.start_dtm < in_end_dtm)
		   AND (in_end_dtm IS NULL OR NVL(ie.end_dtm, in_end_dtm) > in_start_dtm);
END;

PROCEDURE AddEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_description			IN  initiative_event.description%TYPE,
	in_start_dtm			IN	initiative_event.start_dtm%TYPE,
	in_end_dtm				IN	initiative_event.end_dtm%TYPE,
	in_location				IN  initiative_event.location%TYPE
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to initiative with sid '||in_initiative_sid);
	END IF;

	INSERT INTO initiative_event (initiative_event_id, initiative_sid, description, start_dtm, end_dtm, location, created_by_sid, created_dtm)
		VALUES (initiative_event_id_seq.nextval, in_initiative_sid, in_description, in_start_dtm, in_end_dtm, in_location, SYS_CONTEXT('SECURITY','SID'), SYSDATE);
END;

PROCEDURE AmendEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_initiative_event_id 	IN  initiative_event.initiative_event_id%TYPE,
	in_description			IN  initiative_event.description%TYPE,
	in_start_dtm			IN	initiative_event.start_dtm%TYPE,
	in_end_dtm				IN	initiative_event.end_dtm%TYPE,
	in_location				IN  initiative_event.location%TYPE
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to initiative with sid '||in_initiative_sid);
	END IF;

	UPDATE initiative_event
	   SET description = in_description,
		   start_dtm = in_start_dtm,
		   end_dtm = in_end_dtm,
		   location = in_location
	 WHERE initiative_sid = in_initiative_sid
	   AND initiative_event_id = in_initiative_event_id;
END;

PROCEDURE DeleteEvent(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_initiative_event_id 	IN  initiative_event.initiative_event_id%TYPE
)
AS
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to initiative with sid '||in_initiative_sid);
	END IF;

	DELETE FROM initiative_event
	 WHERE initiative_sid = in_initiative_sid
	   AND initiative_event_id = in_initiative_event_id;
END;

PROCEDURE GetCalendars(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_act						security_pkg.T_ACT_ID DEFAULT security_pkg.GetAct;
	v_app						security_pkg.T_SID_ID DEFAULT security_pkg.GetApp;
BEGIN
	OPEN out_cur FOR
		SELECT p.js_class, p.js_class js_class_type /*TEMP - backwards compatibility*/, p.cs_class, p.js_include, p.description, cal.calendar_sid, cal.applies_to_teamrooms, cal.applies_to_initiatives
		  FROM plugin p
		  JOIN calendar cal ON p.plugin_id = cal.plugin_id AND p.plugin_type_id = 12
		  JOIN TABLE(securableObject_pkg.GetChildrenWithPermAsTable(v_act, securableobject_pkg.GetSIDFromPath(v_act, v_app, 'Calendars'), security_pkg.PERMISSION_READ)) so ON cal.calendar_sid = so.sid_id
		 WHERE cal.applies_to_initiatives = 1;	 
END;

FUNCTION HasProjectTabs RETURN NUMBER
AS
	v_count				NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM initiative_project_tab ipt
	  JOIN initiative_project_tab_group iptg ON ipt.project_sid = iptg.project_sid AND ipt.plugin_id = iptg.plugin_id AND ipt.app_sid = iptg.app_sid
	  JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y ON iptg.group_sid = y.column_value;
	  
	  
	IF v_count > 0 THEN
		RETURN 1;
	ELSE
		RETURN 0;
	END IF;
END;

-- Initiative tab procedures
PROCEDURE GetInitiativeTabs (
	in_project_sid				 	IN  security_pkg.T_SID_ID,
	in_initiative_sid 				IN  security_pkg.T_SID_ID,
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no security used since we check group membership - 
	-- SHOULDN'T THIS CHECK WORKFLOW TOO?
	OPEN out_cur FOR
		SELECT project_sid, plugin_id, cs_class, js_include, js_class, tab_label, pos, plugin_type_id, min(is_read_only) is_read_only, form_path, tab_sid, form_sid
 		  FROM (
			SELECT ipt.project_sid, ipt.plugin_id, p.cs_class, p.js_include, p.js_class, ipt.tab_label, ipt.pos, ipt.plugin_type_id, iptg.is_read_only,
			       p.form_path, p.tab_sid, p.form_sid
			  FROM initiative_project_tab ipt 
			  JOIN initiative_project_tab_group iptg ON ipt.project_sid = iptg.project_sid AND ipt.plugin_id = iptg.plugin_id AND ipt.app_sid = iptg.app_sid
			  JOIN plugin p ON ipt.plugin_id = p.plugin_id 
			  JOIN TABLE(act_pkg.GetUsersAndGroupsInACT(security_pkg.GetACT)) y
				ON iptg.group_sid = y.column_value
			 WHERE ipt.project_sid = in_project_sid
		 )
		 GROUP BY project_sid, plugin_id, cs_class, js_include, js_class, tab_label, plugin_type_id, pos, form_path, tab_sid, form_sid
		 ORDER BY pos;	
END;

PROCEDURE InsertTab(
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_js_class 		 			IN  plugin.js_class%TYPE,
	in_tab_label					IN  initiative_project_tab.tab_label%TYPE,
	in_pos 							IN  initiative_project_tab.pos%TYPE
)
AS
	v_plugin_id						plugin.plugin_id%TYPE;
	v_dummy							SYS_REFCURSOR;
BEGIN
	-- security check inside SaveInitiativeTab
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM plugin 
	 WHERE js_class = in_js_class 
	   AND plugin_type_id IN (csr_data_pkg.PLUGIN_TYPE_INITIAT_TAB, csr_data_pkg.PLUGIN_TYPE_INITIAT_MAIN_TAB);
	   
	SaveInitiativeTab(in_project_sid, v_plugin_id, in_tab_label, in_pos, v_dummy);
END;

PROCEDURE SaveInitiativeTab (
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_plugin_id 		 			IN  plugin.plugin_id%TYPE,
	in_tab_label					IN  initiative_project_tab.tab_label%TYPE,
	in_pos 							IN  initiative_project_tab.pos%TYPE,
	out_cur							OUT SYS_REFCURSOR
)
AS
	v_pos 							initiative_project_tab.pos%TYPE;
	v_plugin_type_id				plugin.plugin_type_id%TYPE;
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can add/update initiative tabs.');
	END IF;
	
	SELECT plugin_type_id
	  INTO v_plugin_type_id
	  FROM plugin 
	 WHERE plugin_id = in_plugin_id 
	   AND plugin_type_id IN (csr_data_pkg.PLUGIN_TYPE_INITIAT_TAB, csr_data_pkg.PLUGIN_TYPE_INITIAT_MAIN_TAB);
	   
	v_pos := in_pos;	
	IF in_pos IS NULL OR in_pos < 0 THEN
		SELECT NVL(max(pos) + 1, 1) 
		  INTO v_pos 
		  FROM initiative_project_tab
		 WHERE project_sid = in_project_sid;
	END IF;
	 
	BEGIN
		INSERT INTO initiative_project_tab (project_sid, plugin_id, plugin_type_id, pos, tab_label)
			VALUES (in_project_sid, in_plugin_id, v_plugin_type_id, v_pos, in_tab_label);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE initiative_project_tab
			   SET pos = v_pos, tab_label = in_tab_label
			 WHERE plugin_id = in_plugin_id
			   AND project_sid = in_project_sid;
	END;
	
	-- assume registered users
	BEGIN
		INSERT INTO initiative_project_tab_group (project_sid, plugin_id, group_sid, is_read_only)
		     VALUES (in_project_sid, in_plugin_id, security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, security.security_pkg.GetApp, 'groups/RegisteredUsers'), 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	OPEN out_cur FOR
		SELECT p.plugin_id, p.plugin_type_id, p.cs_class, p.js_include, p.js_class, p.description, 
		       p.details, p.preview_image_path, it.pos, it.tab_label, it.project_sid
		  FROM plugin p
		  JOIN initiative_project_tab it ON p.plugin_id = it.plugin_id
		 WHERE it.plugin_id = in_plugin_id
		   AND it.project_sid = in_project_sid;
END;	

PROCEDURE RemoveInitiativeTab(
	in_project_sid					IN  security_pkg.T_SID_ID,
	in_plugin_id					IN  meter_tab.plugin_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only built-in admin or a user with system management capability can modify initiative plugins');
	END IF;
	
	DELETE FROM initiative_project_tab_group
	 WHERE plugin_id = in_plugin_id
	   AND project_sid = in_project_sid
	   AND app_sid = security_pkg.GetApp;
	   
	DELETE FROM initiative_project_tab
	 WHERE plugin_id = in_plugin_id
	   AND project_sid = in_project_sid
	   AND app_sid = security_pkg.GetApp;
END;
-- End of initiative tab procedures

PROCEDURE GetRagOptions (
	in_initiative_sid 		IN 	 security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;
	
	OPEN out_cur FOR
		SELECT rs.rag_status_id, rs.colour, rs.label, rs.lookup_key 
		  FROM initiative i  
		  JOIN initiative_project_rag_status iprs ON iprs.app_sid = i.app_sid AND iprs.project_sid = i.project_sid
		  JOIN rag_status rs ON rs.app_sid = iprs.app_sid AND rs.rag_status_id = iprs.rag_status_id
		 WHERE i.initiative_sid = in_initiative_sid
		   AND i.app_sid = SYS_CONTEXT('SECURITY','APP')		   
		 ORDER BY iprs.pos;
END;

PROCEDURE SetRagStatus(
	in_initiative_sid 			IN 	 security_pkg.T_SID_ID,
	in_rag_status_id			IN  issue.rag_status_id%TYPE
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to initiative with sid '||in_initiative_sid);
	END IF;
	
	UPDATE initiative 
	   SET rag_status_id = in_rag_status_id
	 WHERE initiative_sid = in_initiative_sid;
END;



PROCEDURE GetUserMsgReplies(
	in_reply_to_msg_id			IN  user_msg.user_msg_id%TYPE,
	in_no_of_replies			IN	NUMBER DEFAULT NULL,
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
)
AS
	v_msgs_sql					VARCHAR2(1000);
	v_files_sql					VARCHAR2(1000);
	v_likes_sql					VARCHAR2(1000);
BEGIN
	-- err... why is this concatenting SQL...? 
	-- It should probably just select some IDs into a temporary table and then run some bog
	-- standard SQL statements. This kind of thing without bind paramteres is very bad news for Oracle!!
	-- re above.. entire method from teamroom_body. both need fixing.
	v_msgs_sql := '
		SELECT user_msg_id, user_sid, full_name, email, msg_dtm, msg_text FROM (
		SELECT um.user_msg_id, um.user_sid, um.full_name, um.email, um.msg_dtm, um.msg_text, ROWNUM AS rn
		  FROM v$user_msg um
		 WHERE um.reply_to_msg_id = ' || in_reply_to_msg_id || ' ORDER BY um.msg_dtm DESC) rply';

	IF in_no_of_replies IS NOT NULL THEN
		v_msgs_sql := v_msgs_sql || ' WHERE ROWNUM <= ' || in_no_of_replies;
	END IF;
	v_msgs_sql := v_msgs_sql || ' ORDER BY msg_dtm ASC';
	
	OPEN out_msgs_cur FOR v_msgs_sql;

	v_files_sql := '
		SELECT umf.user_msg_file_id, umf.user_msg_id, umf.sha1, umf.mime_type
		  FROM v$user_msg_file umf
		  JOIN ( ' || v_msgs_sql || ') msg_reply ON umf.user_msg_id = msg_reply.user_msg_id';
	OPEN out_files_cur FOR v_files_sql;

	v_likes_sql := '
		SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, uml.full_name, uml.email
		  FROM v$user_msg_like uml
		  JOIN ( ' || v_msgs_sql || ') msg_reply ON uml.user_msg_id = msg_reply.user_msg_id';
	OPEN out_likes_cur FOR v_likes_sql;

END;

PROCEDURE AddUserMsgReply(
	in_reply_to_msg_id 		IN  user_msg.user_msg_id%TYPE,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
)
AS
	v_initiative_sid				security_pkg.T_SID_ID; 
	v_cache_key_tbl				security.T_VARCHAR2_TABLE;
	v_user_msg_id  				user_msg.user_msg_id%TYPE;
BEGIN
	
	SELECT initiative_sid 
	  INTO v_initiative_sid
	  FROM initiative_user_msg
	 WHERE user_msg_id = in_reply_to_msg_id;

	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), v_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to initiative sid '||v_initiative_sid);
	END IF;

	INSERT INTO user_msg (user_msg_Id, user_sid, msg_text, msg_dtm, reply_to_msg_id)
		VALUES (user_msg_id_seq.nextval, SYS_CONTEXT('SECURITY','SID'), in_msg_text, SYSDATE, in_reply_to_msg_id)
		RETURNING user_msg_id INTO v_user_msg_id;

	/*
	SELECT name
	  INTO v_name
	  FROM teamroom
	 WHERE teamroom_sid = in_teamroom_sid;

	user_profile_pkg.WriteToUserFeed(
		in_user_feed_action_id	=> csr_data_pkg.USER_FEED_ACTIVITY_POST, 
		in_target_teamroom_sid	=> in_teamroom_sid,
		in_target_param_1		=> v_user_msg_id
	);
	*/

	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO user_msg_file (user_msg_file_id, user_msg_id, filename, mime_type, data, sha1) 
			SELECT user_msg_file_id_seq.nextval, v_user_msg_id, filename, mime_type, object, 
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache 
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)     
			 );
	END IF;	

	OPEN out_msg_cur FOR
		SELECT user_msg_id, user_sid, full_name, email, msg_dtm, msg_text
		  FROM v$user_msg
		 WHERE user_msg_id = v_user_msg_id;

	OPEN out_files_cur FOR		
		SELECT user_msg_file_id, user_msg_id, sha1, mime_type
		  FROM v$user_msg_file
		 WHERE user_msg_id = v_user_msg_id;
END;


PROCEDURE GetUserMsgs(
	in_initiative_sid 			IN  security_pkg.T_SID_ID, 
	out_msgs_cur 				OUT SYS_REFCURSOR,
	out_files_cur  				OUT SYS_REFCURSOR,
	out_likes_cur				OUT SYS_REFCURSOR
)
AS
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading teamroom sid '||in_initiative_sid);
	END IF;

	OPEN out_msgs_cur FOR
		SELECT um.user_msg_id, um.user_sid, um.full_name, um.email, um.msg_dtm, um.msg_text, NVL(reply_count, 0) AS reply_count
		  FROM initiative_user_msg ium
		  JOIN v$user_msg um ON ium.user_msg_id = um.user_msg_id
	 LEFT JOIN (
					SELECT reply_to_msg_id, COUNT(*) AS reply_count
					  FROM v$user_msg um
					 GROUP BY reply_to_msg_id
			   ) msg_reply
		    ON um.user_msg_id = msg_reply.reply_to_msg_id
		 WHERE ium.initiative_sid = in_initiative_sid
		 ORDER BY um.msg_dtm DESC;

	OPEN out_files_cur FOR
		SELECT umf.user_msg_file_id, umf.user_msg_id, umf.sha1, umf.mime_type
		  FROM initiative_user_msg ium
		  JOIN v$user_msg_file umf ON ium.user_msg_id = umf.user_msg_id
		 WHERE ium.initiative_sid = in_initiative_sid;

	OPEN out_likes_cur FOR
		SELECT uml.user_msg_id, uml.liked_by_user_sid, uml.liked_dtm, uml.full_name, uml.email
		  FROM initiative_user_msg ium
		  JOIN v$user_msg_like uml ON ium.user_msg_id = uml.user_msg_id
		 WHERE ium.initiative_sid = in_initiative_sid;
END;



PROCEDURE AddUserMsg(
	in_initiative_sid 		IN  security_pkg.T_SID_ID,
	in_msg_text				IN  user_msg.msg_text%TYPE,
	in_cache_keys			IN	security_pkg.T_VARCHAR2_ARRAY,
	out_msg_cur 			OUT SYS_REFCURSOR,
	out_files_cur  			OUT SYS_REFCURSOR
)
AS
	v_cache_key_tbl		security.T_VARCHAR2_TABLE;
	v_user_msg_id  		user_msg.user_msg_id%TYPE;
	--v_name 				teamroom.label%TYPE;
BEGIN	
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing to teamroom sid '||in_initiative_sid);
	END IF;

	INSERT INTO user_msg (user_msg_Id, user_sid, msg_text, msg_dtm)
		VALUES (user_msg_id_seq.nextval, SYS_CONTEXT('SECURITY','SID'), in_msg_text, SYSDATE)
		RETURNING user_msg_id INTO v_user_msg_id;

	INSERT INTO initiative_user_msg (initiative_sid, user_msg_id)
		VALUES (in_initiative_sid, v_user_msg_id);

	/*
	SELECT name
	  INTO v_name
	  FROM teamroom
	 WHERE teamroom_sid = in_teamroom_sid;

	user_profile_pkg.WriteToUserFeed(
		in_user_feed_action_id	=> csr_data_pkg.USER_FEED_ACTIVITY_POST, 
		in_target_teamroom_sid	=> in_teamroom_sid,
		in_target_param_1		=> v_user_msg_id
	);
	*/

	-- crap hack for ODP.NET
    IF in_cache_keys IS NULL OR (in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		-- do nothing
        NULL;
    ELSE
		v_cache_key_tbl := security_pkg.Varchar2ArrayToTable(in_cache_keys);
		INSERT INTO user_msg_file (user_msg_file_id, user_msg_id, filename, mime_type, data, sha1) 
			SELECT user_msg_file_id_seq.nextval, v_user_msg_id, filename, mime_type, object, 
				   dbms_crypto.hash(object, dbms_crypto.hash_sh1)
			  FROM aspen2.filecache 
			 WHERE cache_key IN (
				SELECT value FROM TABLE(v_cache_key_tbl)     
			 );
	END IF;	

	OPEN out_msg_cur FOR
		SELECT user_msg_id, user_sid, full_name, email, msg_dtm, msg_text
		  FROM v$user_msg
		 WHERE user_msg_id = v_user_msg_id;

	OPEN out_files_cur FOR		
		SELECT user_msg_file_id, user_msg_id, sha1, mime_type
		  FROM v$user_msg_file
		 WHERE user_msg_id = v_user_msg_id;
END;

-- Tab element procedures.
PROCEDURE SaveTabElement (
	in_element_id		IN	init_tab_element_layout.element_id%TYPE,
	in_plugin_id		IN	init_tab_element_layout.plugin_id%TYPE,
	in_tag_group_id		IN  init_tab_element_layout.tag_group_id%TYPE,
	in_xml_field_id		IN	init_tab_element_layout.xml_field_id%TYPE,
	in_pos				IN	init_tab_element_layout.pos%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;
	
	IF in_element_id IS NULL THEN
		INSERT INTO init_tab_element_layout (element_id, plugin_id, tag_group_id, xml_field_id, pos)
		VALUES (init_create_page_el_id_seq.nextval, in_plugin_id, in_tag_group_id, in_xml_field_id, in_pos);
	ELSE
		UPDATE init_tab_element_layout
		   SET plugin_id = in_plugin_id,
			   pos = in_pos,
			   tag_group_id = in_tag_group_id,
			   xml_field_id = in_xml_field_id
		 WHERE element_id = in_element_id;
	END IF;
END;

PROCEDURE DeleteTabElement (
	in_element_id	IN	init_tab_element_layout.element_id%TYPE
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;
	
	DELETE FROM init_tab_element_layout 
	 WHERE element_id = in_element_id 
	   AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetTabElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT iel.element_id, iel.plugin_id, p.description plugin_description, iel.tag_group_id, tg.name tag_group_name, xml_field_id, iel.pos
		  FROM init_tab_element_layout iel
		  LEFT JOIN v$tag_group tg ON iel.app_sid = tg.app_sid AND iel.tag_group_id = tg.tag_group_id
		  LEFT JOIN plugin p ON iel.plugin_id = p.plugin_id
		 WHERE iel.app_sid = security.security_pkg.GetApp
		 ORDER BY p.description, iel.pos;
END;
-- End tab element procedures.

-- Create page element procedures.
PROCEDURE SaveCreatePageElement (
	in_element_id		IN	init_create_page_el_layout.element_id%TYPE,
	in_tag_group_id		IN  init_create_page_el_layout.tag_group_id%TYPE,
	in_xml_field_id		IN	init_create_page_el_layout.xml_field_id%TYPE,
	in_pos				IN	init_create_page_el_layout.pos%TYPE,
	in_section_id		IN	init_create_page_el_layout.section_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;
	
	IF in_element_id IS NULL THEN
		INSERT INTO init_create_page_el_layout (element_id, tag_group_id, xml_field_id, pos, section_id)
		VALUES (init_create_page_el_id_seq.nextval, in_tag_group_id, in_xml_field_id, in_pos, in_section_id);
	ELSE
		UPDATE init_create_page_el_layout
		   SET pos = in_pos,
			   section_id = in_section_id,
			   tag_group_id = in_tag_group_id,
			   xml_field_id = in_xml_field_id
		 WHERE element_id = in_element_id;
	END IF;
END;

PROCEDURE DeleteCreatePageElement (
	in_element_id	IN	init_create_page_el_layout.element_id%TYPE
)
AS
	v_ind_sid						security_pkg.T_SID_ID;
BEGIN	
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;
	
	DELETE FROM init_create_page_el_layout 
	 WHERE element_id = in_element_id 
	   AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE GetCreatePageElements (
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT iel.element_id, iel.pos, iel.tag_group_id, tg.name tag_group_name, xml_field_id, section_id
		  FROM init_create_page_el_layout iel
		  LEFT JOIN v$tag_group tg ON iel.app_sid = tg.app_sid AND iel.tag_group_id = tg.tag_group_id
		 WHERE iel.app_sid = security.security_pkg.GetApp
		 ORDER BY section_id, iel.pos;
END;

-- End create page element procedures.

-- Header element procedures
PROCEDURE GetHeaderElements (
	out_cur							OUT SYS_REFCURSOR
)
AS
BEGIN
	-- no permission checks, its just layout config
	OPEN out_cur FOR
		SELECT ihe.initiative_header_element_id, ihe.pos, ihe.col, ihe.init_header_core_element_id,
		       ihe.initiative_metric_id, im.label metric_label, ihe.tag_group_id, tg.name tag_group_name
		  FROM initiative_header_element ihe
		  LEFT JOIN initiative_metric im ON ihe.initiative_metric_id = im.initiative_metric_id
		  LEFT JOIN v$tag_group tg ON ihe.tag_group_id = tg.tag_group_id
		 ORDER BY ihe.pos, ihe.col;
END;

PROCEDURE SaveHeaderElement (
	in_init_header_element_id		IN	initiative_header_element.initiative_header_element_id%TYPE DEFAULT NULL,
	in_pos							IN	initiative_header_element.pos%TYPE,
	in_col							IN	initiative_header_element.col%TYPE,
	in_initiative_metric_id			IN  initiative_header_element.initiative_metric_id%TYPE DEFAULT NULL,
	in_tag_group_id					IN  initiative_header_element.tag_group_id%TYPE DEFAULT NULL,
	in_init_header_core_element_id	IN  initiative_header_element.init_header_core_element_id%TYPE DEFAULT NULL,
	out_init_header_element_id		OUT	initiative_header_element.initiative_header_element_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;
	
	IF in_init_header_element_id IS NULL THEN
		INSERT INTO initiative_header_element (initiative_header_element_id, pos, col, initiative_metric_id, tag_group_id, init_header_core_element_id)
		VALUES (init_header_element_id_seq.nextval, in_pos, in_col, in_initiative_metric_id, in_tag_group_id, in_init_header_core_element_id)
		RETURNING initiative_header_element_id INTO out_init_header_element_id;
	ELSE
		UPDATE initiative_header_element
		   SET pos = in_pos,
		       col = in_col
		 WHERE initiative_header_element_id = in_init_header_element_id;
		
		out_init_header_element_id := in_init_header_element_id;
	END IF;
END;

PROCEDURE DeleteHeaderElement (
	in_init_header_element_id		IN	initiative_header_element.initiative_header_element_id%TYPE
)
AS
BEGIN
	IF NOT (security_pkg.IsAdmin(security_pkg.GetAct) OR csr_data_pkg.CheckCapability('System management')) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Only the built-in admin or a user with system management capability can edit initiative elements.');
	END IF;

	DELETE FROM initiative_header_element
	 WHERE initiative_header_element_id = in_init_header_element_id
	   AND app_sid = security.security_pkg.GetApp;
END;

-- End of header element procedures

PROCEDURE GetAuditLogPaged(
	in_initiative_sid	IN	security_pkg.T_SID_ID,
	in_order_by			IN	VARCHAR2, -- redundant but needed for quick list output
	in_start_row		IN	NUMBER,
	in_page_size		IN	NUMBER,
	in_start_date		IN	DATE,
	in_end_date			IN	DATE,
	out_total			OUT	NUMBER,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_app_sid security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY','APP');
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(SYS_CONTEXT('SECURITY','ACT'), in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied reading initiative sid '||in_initiative_sid);
	END IF;
	
	INSERT INTO temp_audit_log_ids(row_id, audit_dtm)
    (SELECT /*+ INDEX (audit_log IDX_AUDIT_LOG_OBJECT_SID) */ rowid, audit_date
	   FROM csr.audit_log
	  WHERE app_sid = v_app_sid AND object_sid = in_initiative_sid 
        AND audit_date >= in_start_date AND audit_date <= in_end_date
	  UNION
	 SELECT rowid, audit_date
	   FROM csr.audit_log 
	  WHERE app_sid = v_app_sid AND user_sid = in_initiative_sid
        AND audit_date >= in_start_date AND audit_date <= in_end_date);
	
	 SELECT COUNT(row_id)
	   INTO out_total
	   FROM temp_audit_log_ids;

	  	
	OPEN out_cur FOR			
		SELECT al.audit_date, aut.label, cu.user_name, cu.full_name, al.param_1, al.param_2, 
			   al.param_3, al.description, al.remote_addr
		  FROM (SELECT row_id, rn
                  FROM (SELECT row_id, rownum rn
                          FROM (SELECT row_id
                                  FROM temp_audit_log_ids
                              ORDER BY audit_dtm DESC, row_id DESC)
                         WHERE rownum < in_start_row + in_page_size)
                 WHERE rn >= in_start_row) alr
          JOIN audit_log al ON al.rowid = alr.row_id 
		  JOIN csr_user cu ON cu.csr_user_sid = al.user_sid
		  JOIN audit_type aut ON aut.audit_type_id = al.audit_type_id
	  ORDER BY alr.rn;
END;


END initiative_pkg;
/
