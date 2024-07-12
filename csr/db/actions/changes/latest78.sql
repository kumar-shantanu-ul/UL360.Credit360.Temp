-- Please update version.sql too -- this keeps clean builds in sync
define version=78
@update_header

ALTER TABLE TASK_STATUS ADD(
	OWNER_CAN_SEE       NUMBER(1, 0)      DEFAULT 0 NOT NULL
                        CHECK (OWNER_CAN_SEE IN(0,1))
);


-- Initiaitve user relationship for logged on user
CREATE OR REPLACE VIEW V$USER_INITIATIVES
AS (
	SELECT t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name,
		t.start_dtm, t.end_dtm, t.fields_xml, t.is_container, t.internal_ref,
		t.period_duration, t.budget, t.short_name, t.last_task_period_dtm, 
		t.owner_sid, t.created_dtm, t.input_ind_sid, t.target_ind_sid, t.output_ind_sid, 
	    t.weighting, t.action_type, t.entry_type, x.region_sid, 
	    ts.label task_status_label, ts.is_live, ts.is_rejected, ts.is_stopped, 
	    ts.means_completed, ts.means_terminated, ts.belongs_to_owner
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
		     AND ts.belongs_to_owner = 1 
		     AND t.owner_sid = SYS_CONTEXT('SECURITY', 'SID')
		) x
	WHERE t.task_sid = x.task_sid
  	  AND ts.task_status_id = t.task_status_id
  	  AND security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), x.task_sid, 1 /*security_pkg.PERMISSION_READ*/) = 1
);

-- Initiaitve user relationship for all users
CREATE OR REPLACE VIEW V$USERS_INITIATIVES
AS (
	SELECT x.app_sid, x.user_sid, t.task_sid, t.project_sid, t.parent_task_sid, t.task_status_id, t.name,
		t.start_dtm, t.end_dtm, t.fields_xml, t.is_container, t.internal_ref,
		t.period_duration, t.budget, t.short_name, t.last_task_period_dtm, 
		t.owner_sid, t.created_dtm, t.input_ind_sid, t.target_ind_sid, t.output_ind_sid, 
	    t.weighting, t.action_type, t.entry_type, x.region_sid, 
	    ts.label task_status_label, ts.is_live, ts.is_rejected, ts.is_stopped, 
	    ts.means_completed, ts.means_terminated, ts.belongs_to_owner, x.generate_alerts
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
		  SELECT t.app_sid, t.task_sid, tr.region_sid, t.owner_sid user_sid, 1 generate_alerts
		    FROM task t, task_region tr, task_status ts
		   WHERE ts.task_status_id = t.task_status_id
		     AND tr.task_sid(+) = t.task_sid
		     AND ts.belongs_to_owner = 1 
		) x
	WHERE t.task_sid = x.task_sid
  	  AND ts.task_status_id = t.task_status_id
);

-- The table of users and their local times
CREATE OR REPLACE VIEW V$USER_DTM AS (
	SELECT u.app_sid, ut.sid_id user_sid, 
  		SYSTIMESTAMP dtm_gmt, 
  		SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') dtm_tz
  	   FROM csr.csr_user u, security.application a, security.user_table ut
  	  WHERE a.application_sid_id = u.app_sid
        AND u.app_sid = a.application_sid_id
        AND ut.sid_id = u.csr_user_sid
);

@../initiative_body

@update_tail
