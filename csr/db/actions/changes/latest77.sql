-- Please update version.sql too -- this keeps clean builds in sync
define version=77
@update_header

connect security/security@&_CONNECT_IDENTIFIER
grant select, references on application to actions;
grant select, references on user_table to actions;

connect csr/csr@&_CONNECT_IDENTIFIER
grant execute on alert_pkg to actions;
grant select, references on temp_alert_batch_run to actions;

connect actions/actions@&_CONNECT_IDENTIFIER


CREATE TABLE PERIODIC_ALERT(
    APP_SID            NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ALERT_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    DATA_SP            VARCHAR2(256)    DEFAULT 'periodic_alert_pkg.GenericAlertData' NOT NULL,
    RECURRENCE_XML    SYS.XMLType      	NOT NULL,
    CONSTRAINT PK136 PRIMARY KEY (APP_SID, ALERT_TYPE_ID)
)
;

CREATE TABLE PERIODIC_ALERT_USER(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ALERT_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID      NUMBER(10, 0)    NOT NULL,
    LAST_FIRE_DATE    DATE,
    NEXT_FIRE_DATE    DATE,
    CONSTRAINT PK138 PRIMARY KEY (APP_SID, ALERT_TYPE_ID, CSR_USER_SID)
)
;



ALTER TABLE TASK_STATUS_ROLE ADD (
	GENERATE_ALERTS    NUMBER(1, 0)     DEFAULT 1 NOT NULL
                       CHECK (GENERATE_ALERTS IN(0,1))
);

ALTER TABLE CSR_TASK_ROLE_MEMBER ADD (
	GENERATE_ALERTS    NUMBER(1, 0)     DEFAULT 1 NOT NULL
                       CHECK (GENERATE_ALERTS IN(0,1))
);


ALTER TABLE PERIODIC_ALERT ADD CONSTRAINT RefCUSTOMER271 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE PERIODIC_ALERT ADD CONSTRAINT RefALERT_TYPE272 
    FOREIGN KEY (ALERT_TYPE_ID)
    REFERENCES CSR.ALERT_TYPE(ALERT_TYPE_ID)
;

ALTER TABLE PERIODIC_ALERT_USER ADD CONSTRAINT RefPERIODIC_ALERT273 
    FOREIGN KEY (APP_SID, ALERT_TYPE_ID)
    REFERENCES PERIODIC_ALERT(APP_SID, ALERT_TYPE_ID)
;

ALTER TABLE PERIODIC_ALERT_USER ADD CONSTRAINT RefCSR_USER274 
    FOREIGN KEY (APP_SID, CSR_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

---- PERIODIC REMINDER ALERT ----

BEGIN
	INSERT INTO csr.alert_type (ALERT_TYPE_ID, PARENT_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM) VALUES (2013, NULL, 'Initiatives periodic reminder', 'Periodically, the recurrence schedule is configurable.', 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
	
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2013, 'TO_NAME', 'Recipient name', 'The full name of the user who is responsible for the next action on the initiative.', 0, 1);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2013, 'TO_EMAIL', 'Recipient e-mail', 'The e-mail address of the user who is responsible for the next action on the initiative.', 0, 2);
	INSERT INTO csr.alert_type_param (alert_type_id, field_name, description, help_text, repeats, display_pos) VALUES (2013, 'INITIATIVE_LIST', 'Initiative list', 'A list of the initiatives assigned to the user.', 0, 3);

	INSERT INTO csr.customer_alert_type 
		(app_sid, alert_type_id) (
			SELECT app_sid, 2013
			  FROM customer_options
		);
END;
/



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

@../periodic_alert_pkg
@../periodic_alert_body
@../web_grants

@update_tail
