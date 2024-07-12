CREATE OR REPLACE PACKAGE BODY CSR.initiative_alert_pkg
IS

PROCEDURE GenerateExtraFLowAlertEntries(
	in_flow_item_id					IN	flow_item.flow_item_id%TYPE,
	in_set_by_user_sid				IN	security_pkg.T_SID_ID,
	in_flow_state_transition_id 	IN  flow_state_transition.flow_state_transition_id%TYPE,
	in_flow_state_log_id			IN	flow_state_log.flow_state_log_id%TYPE
)
AS
	v_to_state_id	flow_state_transition.to_state_id%TYPE;
BEGIN
	SELECT to_state_id
	  INTO v_to_state_id
	  FROM flow_state_transition
	 WHERE app_sid = security_pkg.getapp
	   AND flow_state_transition_id = in_flow_state_transition_id;
	   
	-- Users associated directly with the initiative in its new state (with generate_alerts flag set)
	--that will create multiple entries per each flow_transition_alert ending to this state
	INSERT INTO flow_item_generated_alert (app_sid, flow_item_generated_alert_id, flow_transition_alert_id, 
			from_user_sid, to_user_sid, to_column_sid, flow_item_id, flow_state_log_id)
	--user might belong to more than 1 groups for the same flow_state
	SELECT security_pkg.getapp, 
			flow_item_gen_alert_id_seq.nextval,
			flow_transition_alert_id,
			in_set_by_user_sid,
			to_user_sid, -- Associated by initiative/new state
			NULL,
			in_flow_item_id,
			in_flow_state_log_id
	  FROM (
		SELECT DISTINCT 
				fta.flow_transition_alert_id,
				iu.user_sid to_user_sid -- Associated by initiative/new state
		  FROM initiative i
		  JOIN initiative_saving_type ist ON ist.saving_type_id = i.saving_type_id
		  JOIN initiative_user iu ON iu.initiative_sid = i.initiative_sid
		  JOIN initiative_group_flow_state igfs 
			ON igfs.initiative_user_group_id = iu.initiative_user_group_id 
		   AND igfs.flow_state_id = v_to_state_id 
		   AND igfs.project_sid = i.project_sid 
		   AND igfs.generate_alerts = 1
		  CROSS JOIN flow_transition_alert fta 
		 WHERE i.app_sid = security_pkg.getapp
		   AND i.flow_item_id = in_flow_item_id
		   AND  flow_state_transition_id = in_flow_state_transition_id 
		   AND fta.deleted = 0
		   AND fta.to_initiator = 0 
		   AND NOT EXISTS(
				SELECT 1 
				  FROM flow_item_generated_alert figa
				 WHERE figa.app_sid = i.app_sid
				   AND figa.flow_transition_alert_id = fta.flow_transition_alert_id
				   AND figa.flow_state_log_id = in_flow_state_log_id
				   AND figa.to_user_sid = iu.user_sid
		  )
	  );
END;


FUNCTION GetFlowRegionSids(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN security.T_SID_TABLE
AS
	v_region_sids_t			security.T_SID_TABLE DEFAULT security.T_SID_TABLE();
BEGIN
	SELECT ir.region_sid
	  BULK COLLECT INTO v_region_sids_t
	  FROM initiative i
	  JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid
	 WHERE i.app_sid = security_pkg.getApp
	   AND i.flow_item_id = in_flow_item_id;
	
	RETURN v_region_sids_t;
END;

FUNCTION FlowItemRecordExists(
	in_flow_item_id		IN	csr.flow_item.flow_item_id%TYPE
)RETURN NUMBER
AS
	v_count					NUMBER;
BEGIN
	
	SELECT DECODE(count(*), 0, 0, 1)
	  INTO v_count
	  FROM initiative i
	  JOIN initiative_region ir ON i.initiative_sid = ir.initiative_sid
	 WHERE i.app_sid = security_pkg.getApp
	   AND i.flow_item_id = in_flow_item_id;
	   
	RETURN v_count;
END;

PROCEDURE GetFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
	--that will return multiple rows per initiative for each one of the regions. 
	--Would it make better sense to concat them?
		SELECT x.app_sid, x.flow_state_transition_id, x.flow_item_generated_alert_id, x.flow_item_id,
			   x.customer_alert_type_id, x.flow_state_log_id, x.from_state_label, x.to_state_label, 
			   x.set_by_user_sid, x.set_by_email, x.set_by_full_name, x.set_by_user_name,
			   x.to_user_sid,
			   x.flow_alert_helper,
			   i.initiative_sid, i.name initiative_name, i.internal_ref initiative_ref, 
			   i.project_start_dtm, i.project_end_dtm,
			   i.running_start_dtm, i.running_end_dtm,
			   ist.label saving_type,
			   ir.region_sid, r.description region_desc
		  FROM v$open_flow_item_gen_alert x
		  JOIN initiative i ON i.flow_item_id = x.flow_item_id AND i.app_sid = x.app_sid
		  JOIN initiative_saving_type ist ON ist.saving_type_id = i.saving_type_id
		  JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid AND ir.app_sid = i.app_sid
		  LEFT JOIN v$region r ON ir.region_sid = r.region_sid AND ir.app_sid = r.app_sid 
		 ORDER BY x.app_sid, x.customer_alert_type_id, x.to_user_sid, x.flow_item_id, LOWER(i.name) -- Order matters!
		;
END;

-- Get all flows that are classified as initiatives
PROCEDURE GetFlowAlertTypes(
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT f.app_sid, f.flow_sid, a.customer_alert_type_id
		  FROM flow f
		  JOIN flow_state_alert a ON a.flow_sid = f.flow_sid
		 WHERE f.flow_alert_class = 'initiatives'
		   --AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), f.flow_sid, security_pkg.PERMISSION_READ) = 1
		;
END;

-- Have to run flow_pkg.BeginAlertBatchRun before calling 
-- this as that populates temp_flow_state_alert_run
PROCEDURE GetPeriodicFlowAlerts(
	out_cur				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN		
	OPEN out_cur FOR
		SELECT app_sid,
			flow_state_alert_id,
			customer_alert_type_id, 
			state_label, 
			to_user_sid,
			flow_alert_helper,
			initiative_sid,
			initiative_name,
			initiative_ref, 
			project_start_dtm, 
			project_end_dtm,
			running_start_dtm, 
			running_end_dtm,
			saving_type,
			region_sid,
			region_desc
	 	  FROM (
			-- Any user associated with the initiative by state/role where
			-- the role on the alert matches the role on the initiative
			SELECT i.app_sid,
				fa.flow_state_alert_id,
				fa.customer_alert_type_id, 
				fs.label state_label, 
				rrm.user_sid to_user_sid,
				fa.flow_alert_helper,
				i.initiative_sid,
				i.name initiative_name,
				i.internal_ref initiative_ref, 
				i.project_start_dtm, 
				i.project_end_dtm,
				i.running_start_dtm, 
				i.running_end_dtm,
				st.label saving_type,
				ir.region_sid,
				r.description region_desc
			  FROM temp_flow_state_alert_run t
			  -- initiatives in states associated with the alerts
			  JOIN flow_state_alert fa ON fa.flow_sid = t.flow_sid AND fa.flow_state_alert_id = t.flow_state_alert_id
			  JOIN flow_state fs ON fs.flow_sid = fa.flow_sid AND fs.flow_State_id = fa.flow_state_id
			  JOIN flow_item fi ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = t.flow_sid
			  JOIN initiative i ON i.flow_item_id = fi.flow_item_id
			  -- where the state role matches the alert role
			  JOIN flow_state_alert_role fsar ON fsar.flow_sid = t.flow_sid AND fsar.flow_state_alert_id = t.flow_state_alert_id
			  JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid
			  JOIN region_role_member rrm ON rrm.role_sid = fsar.role_sid AND rrm.region_sid = ir.region_sid AND rrm.user_sid = t.user_sid
			  JOIN flow_state_role fsr ON fsr.role_sid = rrm.role_sid AND fsr.flow_state_id = fs.flow_state_id
			  -- region and saving type info
			  JOIN initiative_saving_type st ON st.saving_type_id = i.saving_type_id
			  JOIN v$region r ON r.region_sid = ir.region_sid
			UNION
			-- Any user asssociated with the initiative, regardless of role
			SELECT i.app_sid,
				fa.flow_state_alert_id,
				fa.customer_alert_type_id, 
				fs.label state_label, 
				iu.user_sid to_user_sid,
				fa.flow_alert_helper,
				i.initiative_sid,
				i.name initiative_name,
				i.internal_ref initiative_ref, 
				i.project_start_dtm, 
				i.project_end_dtm,
				i.running_start_dtm, 
				i.running_end_dtm,
				st.label saving_type,
				ir.region_sid,
				r.description region_desc
			  FROM temp_flow_state_alert_run t
			  -- initiatives in states associated with the alerts
			  JOIN flow_state_alert fa ON fa.flow_sid = t.flow_sid AND fa.flow_state_alert_id = t.flow_state_alert_id
			  JOIN flow_state fs ON fs.flow_sid = fa.flow_sid AND fs.flow_State_id = fa.flow_state_id
			  JOIN flow_item fi ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = t.flow_sid
			  JOIN initiative i ON i.flow_item_id = fi.flow_item_id
			  -- where the user is associated directly with the initiative
			  JOIN initiative_user iu ON iu.initiative_sid = i.initiative_sid AND iu.user_sid = t.user_sid
			  JOIN initiative_group_flow_state gfs ON gfs.initiative_user_group_id = iu.initiative_user_group_id AND gfs.flow_state_id = fs.flow_state_id AND gfs.project_sid = i.project_sid
			  -- region and saving type info
			  JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid
			  JOIN initiative_saving_type st ON st.saving_type_id = i.saving_type_id
			  JOIN v$region r ON r.region_sid = ir.region_sid 
			 -- where the user group specifies alerts should be generated
			 WHERE gfs.generate_alerts = 1
			UNION
			-- Any user specified explicitley in the alert, regardless of initiative association
			SELECT i.app_sid,
				fa.flow_state_alert_id,
				fa.customer_alert_type_id, 
				fs.label state_label, 
				fau.user_sid to_user_sid,
				fa.flow_alert_helper,
				i.initiative_sid,
				i.name initiative_name,
				i.internal_ref initiative_ref, 
				i.project_start_dtm, 
				i.project_end_dtm,
				i.running_start_dtm, 
				i.running_end_dtm,
				st.label saving_type,
				ir.region_sid,
				r.description region_desc
			  FROM temp_flow_state_alert_run t
			  -- initiatives in states associated with the alerts
			  JOIN flow_state_alert fa ON fa.flow_sid = t.flow_sid AND fa.flow_state_alert_id = t.flow_state_alert_id
			  JOIN flow_state fs ON fs.flow_sid = fa.flow_sid AND fs.flow_State_id = fa.flow_state_id
			  JOIN flow_item fi ON fi.current_state_id = fs.flow_state_id AND fi.flow_sid = t.flow_sid
			  JOIN initiative i ON i.flow_item_id = fi.flow_item_id
			  -- where the user is associated directly with the alert
			  JOIN flow_state_alert_user fau ON fau.flow_sid = t.flow_sid AND fau.flow_state_alert_id = t.flow_state_alert_id AND fau.user_sid = t.user_sid
			  -- region and saving type info
			  JOIN initiative_region ir ON ir.initiative_sid = i.initiative_sid
			  JOIN initiative_saving_type st ON st.saving_type_id = i.saving_type_id
			  JOIN v$region r ON r.region_sid = ir.region_sid 
		) 
		ORDER BY app_sid, customer_alert_type_id, to_user_sid, flow_state_alert_id, LOWER(initiative_name) -- Order matters!
		;
END;	

END initiative_alert_pkg;
/
