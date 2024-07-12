-- Please update version.sql too -- this keeps clean builds in sync
define version=75
@update_header

CREATE TABLE CSR_TASK_ROLE_MEMBER(
    APP_SID     NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    TASK_SID    NUMBER(10, 0)    NOT NULL,
    ROLE_SID    NUMBER(10, 0)    NOT NULL,
    USER_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_TASK_ROLE_MEMBER_1 PRIMARY KEY (APP_SID, TASK_SID, ROLE_SID, USER_SID)
);


ALTER TABLE CSR_TASK_ROLE_MEMBER ADD CONSTRAINT RefROLE257 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE CSR_TASK_ROLE_MEMBER ADD CONSTRAINT RefTASK258 
    FOREIGN KEY (APP_SID, TASK_SID)
    REFERENCES TASK(APP_SID, TASK_SID)
;

ALTER TABLE CSR_TASK_ROLE_MEMBER ADD CONSTRAINT RefCSR_USER265 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

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


@../task_pkg
@../task_body

@update_tail
