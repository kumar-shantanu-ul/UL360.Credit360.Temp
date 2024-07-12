
-- Initiaitve user relationship for logged on user
CREATE OR REPLACE VIEW ACTIONS.V$USER_INITIATIVES
AS (
	SELECT t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name,
		t.start_dtm, t.end_dtm, t.fields_xml, t.is_container, t.internal_ref,
		t.period_duration, t.budget, t.short_name, t.last_task_period_dtm, 
		t.owner_sid, t.created_dtm, t.input_ind_sid, t.target_ind_sid, t.output_ind_sid, 
	    t.weighting, t.action_type, t.entry_type, x.region_sid, 
	    ts.label task_status_label, ts.is_live, ts.is_rejected, ts.is_stopped, 
	    ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.owner_can_see
	  FROM task t, task_status ts, (
		  -- The user is associated with a region/role that corrasponds to the current status
		  SELECT t.task_sid, tr.region_sid
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr.region_role_member rrm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND rrm.region_sid = tr.region_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = rrm.role_sid
		     AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  UNION
		  -- The user is associated with a project/region/role that corrasponds to the current status
		  SELECT t.task_sid, tr.region_sid
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, project_region_role_member rrm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND rrm.region_sid = tr.region_sid
		     AND rrm.project_sid = t.project_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = rrm.role_sid
		     AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  UNION
		  -- The user is associated with a task/role that corrasponds to the current status (regardless of region)
		  SELECT t.task_sid, tr.region_sid
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr_task_role_member trm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND trm.task_sid = t.task_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = trm.role_sid
		     AND trm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
		  UNION
		  -- The user is the owner and the current status specifies that the task belongs to the owner
		  SELECT t.task_sid, tr.region_sid
		    FROM task t, task_region tr, task_status ts
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid(+) = t.task_sid
		     AND t.owner_sid = SYS_CONTEXT('SECURITY', 'SID')
		     AND (ts.belongs_to_owner = 1
		       OR ts.owner_can_see = 1
		     )
		) x
	WHERE t.task_sid = x.task_sid
  	  AND ts.task_status_id = t.task_status_id
  	  AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), x.task_sid, 1 /*security_pkg.PERMISSION_READ*/) = 1
);

-- Initiaitve user relationship for all users
CREATE OR REPLACE VIEW ACTIONS.V$USERS_INITIATIVES
AS (
	SELECT x.app_sid, x.user_sid, t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name,
		t.start_dtm, t.end_dtm, t.fields_xml, t.is_container, t.internal_ref,
		t.period_duration, t.budget, t.short_name, t.last_task_period_dtm, 
		t.owner_sid, t.created_dtm, t.input_ind_sid, t.target_ind_sid, t.output_ind_sid, 
	    t.weighting, t.action_type, t.entry_type, x.region_sid, 
	    ts.label task_status_label, ts.is_live, ts.is_rejected, ts.is_stopped, 
	    ts.means_completed, ts.means_terminated, ts.belongs_to_owner, ts.owner_can_see, x.generate_alerts
	  FROM task t, task_status ts, (
		  -- The user is associated with a region/role that corrasponds to the current status
		  SELECT t.app_sid, t.task_sid, tr.region_sid, rrm.user_sid, tsr.generate_alerts
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr.region_role_member rrm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND rrm.region_sid = tr.region_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = rrm.role_sid
		  UNION
		  -- The user is associated with a project/region/role that corrasponds to the current status
		  SELECT t.app_sid, t.task_sid, tr.region_sid, rrm.user_sid, tsr.generate_alerts
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, project_region_role_member rrm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND rrm.region_sid = tr.region_sid
		     AND rrm.project_sid = t.project_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = rrm.role_sid
		  UNION
		  -- The user is associated with a task/role that corrasponds to the current status (regardless of region)
		  SELECT t.app_sid, t.task_sid, tr.region_sid, trm.user_sid, trm.generate_alerts
		    FROM task t, task_region tr, task_status ts, task_status_role tsr, csr_task_role_member trm
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid = t.task_sid
		     AND trm.task_sid = t.task_sid
		     AND tsr.task_status_id = ts.task_status_id
		     AND tsr.role_sid = trm.role_sid
		  UNION
		  -- The user is the owner and the current status specifies that the task belongs to the owner
		  SELECT t.app_sid, t.task_sid, tr.region_sid, t.owner_sid user_sid, ts.belongs_to_owner generate_alerts
		    FROM task t, task_region tr, task_status ts
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid(+) = t.task_sid
		     AND (ts.belongs_to_owner = 1
		       OR ts.owner_can_see = 1
		     )
		) x
	WHERE t.task_sid = x.task_sid
  	  AND ts.task_status_id = t.task_status_id
);

-- The table of users and their local times
CREATE OR REPLACE VIEW ACTIONS.V$USER_DTM AS (
	SELECT u.app_sid, ut.sid_id user_sid, 
  		SYSTIMESTAMP dtm_gmt, 
  		SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') dtm_tz
  	   FROM csr.csr_user u, security.application a, security.user_table ut
  	  WHERE a.application_sid_id = u.app_sid
        AND u.app_sid = a.application_sid_id
        AND ut.sid_id = u.csr_user_sid
);

-- The next fire date for each user and alert type
-- Not needed as we now use NPSL.Recurrence
/*
CREATE OR REPLACE VIEW ACTIONS.V$ALERT_FIRE_DATE AS (
	SELECT x.app_sid, csr_user_sid, alert_type_id, last_fire_date,
	  CASE 
	    WHEN last_fire_date IS NOT NULL AND last_fire_date >= next_fire THEN
	      ADD_MONTHS(next_fire, period_duration)
	    WHEN last_fire_date IS NULL AND TRUNC(ud.dtm_tz, 'DD') > next_fire THEN
	      ADD_MONTHS(next_fire, period_duration)
	    ELSE
	      next_fire
	  END next_fire_date
	  FROM (
		SELECT u.app_sid, u.csr_user_sid, pa.alert_type_id, pa.month_day, pa.period_duration, pu.last_fire_date, pa.start_month,
	      ADD_MONTHS(TRUNC(NVL(last_fire_date, SYSDATE), 'MONTH') + month_day - 1, MOD(TO_CHAR(NVL(last_fire_date, SYSDATE), 'MM') + start_month - 2, period_duration)) next_fire
		  FROM periodic_alert pa, periodic_alert_user pu, (
		    SELECT u.app_sid, u.csr_user_sid, pa.alert_type_id 
		      FROM csr.csr_user u, periodic_alert pa
		     WHERE u.app_sid = pa.app_sid
		  ) u
		 WHERE pa.alert_type_id = u.alert_type_id
		   AND pu.alert_type_id(+) = u.alert_type_id
		   AND pu.csr_user_sid(+) = u.csr_user_sid
	) x, v$user_dtm ud
		WHERE x.app_sid = ud.app_sid
		  AND x.csr_user_sid = ud.user_sid
);
*/
