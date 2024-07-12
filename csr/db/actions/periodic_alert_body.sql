CREATE OR REPLACE PACKAGE BODY ACTIONS.periodic_alert_pkg
IS

PROCEDURE SetRecurrence(
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_recurrence_xml			IN	periodic_alert.recurrence_xml%TYPE
)
AS
BEGIN
	BEGIN
		INSERT INTO periodic_alert
			(app_sid, alert_type_id, recurrence_xml)
		  VALUES (security_pkg.GetAPP, in_alert_type_id, in_recurrence_xml);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE periodic_alert
			   SET recurrence_xml = in_recurrence_xml
			 WHERE app_sid = security_pkg.GetAPP
			   AND alert_type_id = in_alert_type_id;
	END;
	
	-- Now delete the next fire times from the periodic_alert_user table 
	-- this will ensure that the next fire time is updated according to the 
	-- new schedule the next time the alert job is run for a given user
	UPDATE periodic_alert_user
	   SET next_fire_date = NULL
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND alert_type_id = in_alert_type_id;
END;

PROCEDURE GetAlertTypes(
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN	
	OPEN out_cur FOR
		SELECT DISTINCT alert_type_id
		  FROM periodic_alert;
END;


PROCEDURE BeginBatchRun(
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- Begin the batch run
	csr.alert_pkg.BeginStdAlertBatchRun(in_alert_type_id);
	
	-- Return all app sids and recurrence specs for this alert type
	OPEN out_cur FOR
		SELECT p.app_sid, p.recurrence_xml
		  FROM periodic_alert p
		 WHERE p.alert_type_id = in_alert_type_id;
END;

PROCEDURE GetAlertData (
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_default_fire_date		IN	periodic_alert_user.next_fire_date%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	
	-- Insert a default next fire date for all users we 
	-- want to process and who have never had a run
	INSERT INTO periodic_alert_user 
		(app_sid, alert_type_id, csr_user_sid, next_fire_date) (
		SELECT app_sid, std_alert_type_id, csr_user_sid, TRUNC(in_default_fire_date, 'DD')
		  FROM csr.temp_alert_batch_run
		 WHERE app_sid = in_app_sid
		   AND std_alert_type_id = in_alert_type_id
		MINUS 
		SELECT app_sid, alert_type_id, csr_user_sid, TRUNC(in_default_fire_date, 'DD')
		  FROM periodic_alert_user 
		 WHERE app_sid = in_app_sid
		   AND alert_type_id = in_alert_type_id
	);
	
	-- Set the default date for any entries that have had their 
	-- next fire times reset due to a change of schedule
	UPDATE periodic_alert_user
	   SET next_fire_date = TRUNC(in_default_fire_date, 'DD')
	 WHERE app_sid = in_app_sid
	   AND alert_type_id = in_alert_type_id
	   AND next_fire_date IS NULL;
	
	-- Remember this
	COMMIT;
	
	FOR r IN (
		SELECT data_sp
		  FROM periodic_alert
		 WHERE alert_type_id = in_alert_type_id
		   AND app_sid = in_app_sid
	) LOOP
		EXECUTE IMMEDIATE 'BEGIN '||r.data_sp||'(:1, :2, :3); END;'
			USING IN in_app_sid, IN in_alert_type_id, OUT out_cur;
	END LOOP;
END;


PROCEDURE RecordUserBatchRun(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_csr_user_sid				IN	csr.csr_user.csr_user_sid%TYPE,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_next_fire_date			IN	periodic_alert_user.next_fire_date%TYPE
)
AS
BEGIN
	-- Reecord the fact we've fired for this user and update their next fire date
	UPDATE periodic_alert_user
	   SET last_fire_date = TRUNC(SYSDATE, 'DD'),
		   next_fire_date = in_next_fire_date
	 WHERE (app_sid, alert_type_id, csr_user_sid) IN (
	 	SELECT app_sid, std_alert_type_id, csr_user_sid
	 	  FROM csr.temp_alert_batch_run
	 	 WHERE app_sid = in_app_sid
	 	   AND std_alert_type_id = in_alert_type_id
	 	   AND csr_user_sid = in_csr_user_sid
	 );
	
	-- Call into alert_pkg (this will commit for us)
	csr.alert_pkg.RecordUserBatchRun(in_app_sid, in_csr_user_sid, in_alert_type_id);

END;

PROCEDURE EndAppRun(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	in_next_fire_date			IN	periodic_alert_user.next_fire_date%TYPE
)
As
BEGIN
	-- Update the next fire date for all users joined on the temp_alert_batch_run 
	-- table who were scheduled to run so that we know we have run for them this period
	FOR r IN (
		SELECT p.app_sid, p.alert_type_id, p.csr_user_sid, p.next_fire_date, d.dtm_tz
		  FROM csr.temp_alert_batch_run t, periodic_alert_user p, v$user_dtm d
		 WHERE p.app_sid = t.app_sid
		   AND p.alert_type_id = t.std_alert_type_id
		   AND p.csr_user_sid = t.csr_user_sid
		   AND d.user_sid = t.csr_user_sid
		   AND TRUNC(p.next_fire_date, 'DD') <= TRUNC(d.dtm_tz, 'DD')
	) LOOP
		UPDATE periodic_alert_user
	   	   SET next_fire_date = in_next_fire_date
	   	 WHERE app_sid = r.app_sid
	   	   AND alert_type_id = r.alert_type_id
	   	   AND csr_user_sid = r.csr_user_sid;
	END LOOP;
	
	COMMIT;
END;


PROCEDURE EndBatchRun(
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE
)
AS
BEGIN
	-- End the batch run
	csr.alert_pkg.EndStdAlertBatchRun(in_alert_type_id);
END;


-- SOME DIFFERENT ALERT DATA SELECTIONS

PROCEDURE GenericAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ui.task_sid, ui.project_sid, ui.parent_task_sid, ui.task_status_id, ui.name,
	      	ui.start_dtm, ui.end_dtm, ui.fields_xml, ui.is_container, ui.internal_ref,
	      	ui.period_duration, ui.budget, ui.short_name, ui.last_task_period_dtm, 
	      	ui.owner_sid, ui.created_dtm, ui.input_ind_sid, ui.target_ind_sid, ui.output_ind_sid, 
		    ui.weighting, ui.action_type, ui.entry_type, ui.region_sid, 
		    ui.task_status_label, ui.is_live, ui.is_rejected, ui.is_stopped, 
		    ui.means_completed, ui.means_terminated, ui.belongs_to_owner,
		    cu.csr_user_sid, cu.user_name, cu.full_name, cu.email,
		    p.name project_name
		  FROM csr.temp_alert_batch_run ta, v$user_dtm ud, periodic_alert_user pa, v$users_initiatives ui, csr.csr_user cu, project p
		 WHERE ta.app_sid = in_app_sid
		   AND ud.app_sid = ta.app_sid
		   AND ud.user_sid = ta.csr_user_sid
		   AND pa.app_sid = ta.app_sid
		   AND pa.csr_user_sid = ta.csr_user_sid
		   AND pa.alert_type_id = ta.std_alert_type_id
		   AND ui.app_sid = ta.app_sid
		   AND ui.user_sid = ta.csr_user_sid
		   AND cu.app_sid = ta.app_sid
		   AND cu.csr_user_sid = ta.csr_user_sid
		   AND p.project_sid = ui.project_sid
		   AND TRUNC(pa.next_fire_date, 'DD') <= TRUNC(ud.dtm_tz, 'DD')
		   AND ui.generate_alerts = 1
		 ORDER BY cu.app_sid, cu.csr_user_sid, p.name, ui.name
		;
END;

PROCEDURE OwnerAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ui.task_sid, ui.project_sid, ui.parent_task_sid, ui.task_status_id, ui.name,
	      	ui.start_dtm, ui.end_dtm, ui.fields_xml, ui.is_container, ui.internal_ref,
	      	ui.period_duration, ui.budget, ui.short_name, ui.last_task_period_dtm, 
	      	ui.owner_sid, ui.created_dtm, ui.input_ind_sid, ui.target_ind_sid, ui.output_ind_sid, 
		    ui.weighting, ui.action_type, ui.entry_type, ui.region_sid, 
		    ui.task_status_label, ui.is_live, ui.is_rejected, ui.is_stopped, 
		    ui.means_completed, ui.means_terminated, ui.belongs_to_owner,
		    cu.csr_user_sid, cu.user_name, cu.full_name, cu.email,
		    p.name project_name
		  FROM csr.temp_alert_batch_run ta, v$user_dtm ud, periodic_alert_user pa, v$users_initiatives ui, csr.csr_user cu, project p
		 WHERE ta.app_sid = in_app_sid
		   AND ud.app_sid = ta.app_sid
		   AND ud.user_sid = ta.csr_user_sid
		   AND pa.app_sid = ta.app_sid
		   AND pa.csr_user_sid = ta.csr_user_sid
		   AND pa.alert_type_id = ta.std_alert_type_id
		   AND ui.app_sid = ta.app_sid
		   AND ui.user_sid = ta.csr_user_sid
		   AND cu.app_sid = ta.app_sid
		   AND cu.csr_user_sid = ta.csr_user_sid
		   AND p.project_sid = ui.project_sid
		   AND TRUNC(pa.next_fire_date, 'DD') <= TRUNC(ud.dtm_tz, 'DD')
		   AND ui.generate_alerts = 1
		   -- Only users that are the owner and in statuses that belong to the owner
		   AND ui.user_sid = ui.owner_sid
		   AND ui.belongs_to_owner = 1
		 ORDER BY cu.csr_user_sid, p.name, ui.name
		;
END;

PROCEDURE DueAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ui.task_sid, ui.project_sid, ui.parent_task_sid, ui.task_status_id, ui.name,
	      	ui.start_dtm, ui.end_dtm, ui.fields_xml, ui.is_container, ui.internal_ref,
	      	ui.period_duration, ui.budget, ui.short_name, ui.last_task_period_dtm, 
	      	ui.owner_sid, ui.created_dtm, ui.input_ind_sid, ui.target_ind_sid, ui.output_ind_sid, 
		    ui.weighting, ui.action_type, ui.entry_type, ui.region_sid, 
		    ui.task_status_label, ui.is_live, ui.is_rejected, ui.is_stopped, 
		    ui.means_completed, ui.means_terminated, ui.belongs_to_owner,
		    cu.csr_user_sid, cu.user_name, cu.full_name, cu.email,
		    p.name project_name
		  FROM csr.temp_alert_batch_run ta, v$user_dtm ud, periodic_alert_user pa, v$users_initiatives ui, csr.csr_user cu, project p
		 WHERE ta.app_sid = in_app_sid
		   AND ud.app_sid = ta.app_sid
		   AND ud.user_sid = ta.csr_user_sid
		   AND pa.app_sid = ta.app_sid
		   AND pa.csr_user_sid = ta.csr_user_sid
		   AND pa.alert_type_id = ta.std_alert_type_id
		   AND ui.app_sid = ta.app_sid
		   AND ui.user_sid = ta.csr_user_sid
		   AND cu.app_sid = ta.app_sid
		   AND cu.csr_user_sid = ta.csr_user_sid
		   AND p.project_sid = ui.project_sid
		   AND TRUNC(pa.next_fire_date, 'DD') <= TRUNC(ud.dtm_tz, 'DD')
		   AND ui.generate_alerts = 1
		   -- Only users that are the owner and in statuses that belong to the owner...
		   AND ui.user_sid = ui.owner_sid
		   AND ui.belongs_to_owner = 1
		   -- .. and that are live (so need updating)
		   AND ui.is_live = 1
		   -- ...and that are due an update or are overdue
		   AND ADD_MONTHS(TRUNC(NVL(ui.last_task_period_dtm, ui.start_dtm), 'MONTH'), ui.period_duration) <= TRUNC(SYSDATE, 'MONTH')
		 ORDER BY cu.csr_user_sid, p.name, ui.name
		;
END;

PROCEDURE NonOwnerAlertData(
	in_app_sid					IN	security_pkg.T_SID_ID,
	in_alert_type_id			IN	periodic_alert.alert_type_id%TYPE,
	out_cur						OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT ui.task_sid, ui.project_sid, ui.parent_task_sid, ui.task_status_id, ui.name,
	      	ui.start_dtm, ui.end_dtm, ui.fields_xml, ui.is_container, ui.internal_ref,
	      	ui.period_duration, ui.budget, ui.short_name, ui.last_task_period_dtm, 
	      	ui.owner_sid, ui.created_dtm, ui.input_ind_sid, ui.target_ind_sid, ui.output_ind_sid, 
		    ui.weighting, ui.action_type, ui.entry_type, ui.region_sid, 
		    ui.task_status_label, ui.is_live, ui.is_rejected, ui.is_stopped, 
		    ui.means_completed, ui.means_terminated, ui.belongs_to_owner,
		    cu.csr_user_sid, cu.user_name, cu.full_name, cu.email,
		    p.name project_name
		  FROM csr.temp_alert_batch_run ta, v$user_dtm ud, periodic_alert_user pa, v$users_initiatives ui, csr.csr_user cu, project p
		 WHERE ta.app_sid = in_app_sid
		   AND ud.app_sid = ta.app_sid
		   AND ud.user_sid = ta.csr_user_sid
		   AND pa.app_sid = ta.app_sid
		   AND pa.csr_user_sid = ta.csr_user_sid
		   AND pa.alert_type_id = ta.std_alert_type_id
		   AND ui.app_sid = ta.app_sid
		   AND ui.user_sid = ta.csr_user_sid
		   AND cu.app_sid = ta.app_sid
		   AND cu.csr_user_sid = ta.csr_user_sid
		   AND p.project_sid = ui.project_sid
		   AND TRUNC(pa.next_fire_date, 'DD') <= TRUNC(ud.dtm_tz, 'DD')
		   AND ui.generate_alerts = 1
		   -- Only where the initiative is in a state where it doesn't belong to the owner
		   -- i.e. where someone in a role is responsible for the next action against the initiative
		   AND ui.belongs_to_owner = 0
		 ORDER BY cu.csr_user_sid, p.name, ui.name
		;
END;

END periodic_alert_pkg;
/
