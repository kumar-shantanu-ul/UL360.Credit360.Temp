-- Please update version.sql too -- this keeps clean builds in sync
define version=82
@update_header

CREATE SEQUENCE REPORT_TEMPLATE_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;


CREATE TABLE PERIODIC_REPORT_TEMPLATE(
    APP_SID               NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REPORT_TEMPLATE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION           VARCHAR2(1024)   NOT NULL,
    TEMPLATE_XML          SYS.XMLType      NOT NULL,
    CONSTRAINT PK143 PRIMARY KEY (APP_SID, REPORT_TEMPLATE_ID)
)
;


ALTER TABLE PERIODIC_REPORT_TEMPLATE ADD CONSTRAINT RefCUSTOMER282 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

@../initiative_reporting_pkg
@../initiative_reporting_body

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

@update_tail
