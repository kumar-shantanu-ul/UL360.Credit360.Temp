-- Please update version.sql too -- this keeps clean builds in sync
define version=83
@update_header

CREATE TABLE PROJECT_REGION_ROLE_MEMBER(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID           NUMBER(10, 0)    NOT NULL,
    REGION_SID            NUMBER(10, 0)    NOT NULL,
    ROLE_SID              NUMBER(10, 0)    NOT NULL,
    USER_SID              NUMBER(10, 0)    NOT NULL,
    INHERITED_FROM_SID    NUMBER(10, 0)    NOT NULL,
    GENERATE_ALERTS       NUMBER(1, 0)     DEFAULT 0 NOT NULL
                          CHECK (GENERATE_ALERTS IN(0,1)),
    CONSTRAINT PK145 PRIMARY KEY (APP_SID, PROJECT_SID, REGION_SID, ROLE_SID, USER_SID, INHERITED_FROM_SID)
)
;


ALTER TABLE PROJECT_REGION_ROLE_MEMBER ADD CONSTRAINT RefROLE291 
    FOREIGN KEY (APP_SID, ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE PROJECT_REGION_ROLE_MEMBER ADD CONSTRAINT RefCSR_USER292 
    FOREIGN KEY (APP_SID, USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE PROJECT_REGION_ROLE_MEMBER ADD CONSTRAINT RefREGION293 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE PROJECT_REGION_ROLE_MEMBER ADD CONSTRAINT RefREGION294 
    FOREIGN KEY (APP_SID, INHERITED_FROM_SID)
    REFERENCES CSR.REGION(APP_SID, REGION_SID)
;

ALTER TABLE PROJECT_REGION_ROLE_MEMBER ADD CONSTRAINT RefPROJECT295 
    FOREIGN KEY (APP_SID, PROJECT_SID)
    REFERENCES PROJECT(APP_SID, PROJECT_SID)
;

begin
	-- select from ALL_POLICIES and restrict by OBJECT_OWNER in case we have to run this as another user with grant execute on dbms_rls
	for r in (select object_name, policy_name from all_policies where object_owner='ACTIONS') loop
		dbms_rls.drop_policy(
            object_schema   => 'ACTIONS',
            object_name     => r.object_name,
            policy_name     => r.policy_name
        );
    end loop;
end;
/

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'AGGR_TASK_IND_DEPENDENCY',
		'AGGR_TASK_PERIOD',
		'AGGR_TASK_PERIOD_OVERRIDE',
		'AGGR_TASK_TASK_DEPENDENCY',
		'ALLOW_TRANSITION',
		'CUSTOMER_OPTIONS',
		'CSR_TASK_ROLE_MEMBER',
		'FILE_UPLOAD',
		'IMPORT_MAPPING_MRU',
		'IND_TEMPLATE',
		'INITIATIVE_EXTRA_INFO',
		'INITIATIVE_PROJECT_TEAM',
		'PERIODIC_ALERT',
		'PERIODIC_ALERT_USER',
		'PERIODIC_REPORT_TEMPLATE',
		'PROJECT',
		'PROJECT_IND_TEMPLATE',
		'PROJECT_IND_TEMPLATE_INSTANCE',
		'PROJECT_REGION_ROLE_MEMBER',
		'PROJECT_ROLE',
		'PROJECT_ROLE_MEMBER',
		'PROJECT_TAG_GROUP',
		'PROJECT_TASK_PERIOD_STATUS',
		'PROJECT_TASK_STATUS',
		'ROLE',
		'ROOT_IND_TEMPLATE_INSTANCE',
		'SCRIPT',
		'TAG',
		'TAG_GROUP',
		'TAG_GROUP_MEMBER',
		'TASK',
		'TASK_BUDGET_HISTORY',
		'TASK_BUDGET_PERIOD',
		'TASK_COMMENT',
		'TASK_FILE_UPLOAD',
		'TASK_INDICATOR',
		'TASK_IND_DEPENDENCY',
		'TASK_IND_TEMPLATE_INSTANCE',
		'TASK_INSTANCE',
		'TASK_PERIOD',
		'TASK_PERIOD_FILE_UPLOAD',
		'TASK_PERIOD_OVERRIDE',
		'TASK_PERIOD_STATUS',
		'TASK_RECALC_JOB',
		'TASK_REGION',
		'TASK_ROLE_MEMBER',
		'TASK_STATUS',
		'TASK_STATUS_HISTORY',
		'TASK_STATUS_ROLE',
		'TASK_STATUS_TRANSITION',
		'TASK_TAG',
		'TASK_TASK_DEPENDENCY',
		'FILE_UPLOAD',
		'FILE_UPLOAD_GROUP',
		'FILE_UPLOAD_GROUP_MEMBER',
		'PROJECT_FILE_UPLOAD_GROUP',
		'RECKONER_TAG',
		'RECKONER_TAG_GROUP',
		'TASK_RECALC_REGION',
		'TASK_RECALC_PERIOD'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					
					-- dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'ACTIONS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'ACTIONS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
				end;
			end loop;
		end;
	end loop;
end;
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
CREATE OR REPLACE VIEW V$USERS_INITIATIVES
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
CREATE OR REPLACE VIEW V$USER_DTM AS (
	SELECT u.app_sid, ut.sid_id user_sid, 
  		SYSTIMESTAMP dtm_gmt, 
  		SYSTIMESTAMP AT TIME ZONE COALESCE(ut.timezone, a.timezone, 'Etc/GMT') dtm_tz
  	   FROM csr.csr_user u, security.application a, security.user_table ut
  	  WHERE a.application_sid_id = u.app_sid
        AND u.app_sid = a.application_sid_id
        AND ut.sid_id = u.csr_user_sid
);


grant select, insert, update, delete, references on project_region_role_member to csr;

connect csr/csr@&_CONNECT_IDENTIFIER

grant execute on role_pkg to actions;
@../../region_body

connect actions/actions@&_CONNECT_IDENTIFIER

@../initiative_body
@../role_pkg
@../role_body

grant execute on aggr_dependency_pkg to web_user;
grant execute on dependency_pkg to web_user;
grant execute on file_upload_pkg to web_user;
grant execute on gantt_pkg to web_user;
grant execute on ind_template_pkg to web_user;
grant execute on initiative_pkg to web_user;
grant execute on initiative_reporting_pkg to web_user;
grant execute on options_pkg to web_user;
grant execute on project_pkg to web_user;
grant execute on setup_pkg to web_user;
grant execute on tag_pkg to web_user;
grant execute on task_pkg to web_user;
grant execute on reckoner_pkg to web_user;
grant execute on importer_pkg to web_user;
grant execute on role_pkg to web_user;

@update_tail
