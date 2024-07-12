-- Please update version.sql too -- this keeps clean builds in sync
define version=1372
@update_header

CREATE TABLE CSR.ISSUE_STATE(
    ISSUE_STATE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION       VARCHAR2(100)    NOT NULL,
    CONSTRAINT PK_ISSUE_STATE PRIMARY KEY (ISSUE_STATE_ID)
)
;

CREATE TABLE CSR.ISSUE_CUSTOM_FIELD_STATE_PERM(
    APP_SID                  NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_CUSTOM_FIELD_ID    NUMBER(10, 0)    NOT NULL,
    ISSUE_STATE_ID           NUMBER(10, 0)    NOT NULL,
    REQUIRE_SET              NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_SET                NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_ICFSP_REQUIRE_SET CHECK (REQUIRE_SET IN (0, 1)),
    CONSTRAINT CHK_ICFSP_ALLOW_SET CHECK (ALLOW_SET IN (0, 1)),
    CONSTRAINT PK_ISSUE_CUSTOM_FIELD_STATE_PE PRIMARY KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID, ISSUE_STATE_ID)
)
;

CREATE TABLE CSR.ISSUE_TYPE_STATE_PERM(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    ISSUE_TYPE_ID          NUMBER(10, 0)    NOT NULL,
    ISSUE_STATE_ID         NUMBER(10, 0)    NOT NULL,
    REQUIRE_DUE_DATE       NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_DUE_DATE         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    REQUIRE_PRIORITY       NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_PRIORITY         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    REQUIRE_ASSIGN_USER    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_ASSIGN_USER      NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    REQUIRE_ASSIGN_ROLE    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_ASSIGN_ROLE      NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    REQUIRE_REGION         NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    ALLOW_REGION           NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CONSTRAINT CHK_ITSP_REQUIRE_DUE_DATE CHECK (REQUIRE_DUE_DATE IN (0, 1)),
    CONSTRAINT CHK_ITSP_ALLOW_DUE_DATE CHECK (ALLOW_DUE_DATE IN (0, 1)),
    CONSTRAINT CHK_ITSP_REQUIRE_PRIORITY CHECK (REQUIRE_PRIORITY IN (0, 1)),
    CONSTRAINT CHK_ITSP_ALLOW_PRIORITY CHECK (ALLOW_PRIORITY IN (0, 1)),
    CONSTRAINT CHK_ITSP_REQUIRE_ASSIGN_USER CHECK (REQUIRE_ASSIGN_USER IN (0, 1)),
    CONSTRAINT CHK_ITSP_ALLOW_ASSIGN_USER CHECK (ALLOW_ASSIGN_USER IN (0, 1)),
    CONSTRAINT CHK_ITSP_REQUIRE_ASSIGN_ROLE CHECK (REQUIRE_ASSIGN_ROLE IN (0, 1)),
    CONSTRAINT CHK_ITSP_ALLOW_ASSIGN_ROLE CHECK (ALLOW_ASSIGN_ROLE IN (0, 1)),
    CONSTRAINT CHK_ITSP_REQUIRE_REGION CHECK (REQUIRE_REGION IN (0, 1)),
    CONSTRAINT CHK_ITSP_ALLOW_REGION CHECK (ALLOW_REGION IN (0, 1)),
    CONSTRAINT PK_ISSUE_TYPE_STATE_PERM PRIMARY KEY (APP_SID, ISSUE_TYPE_ID, ISSUE_STATE_ID)
)
;

ALTER TABLE CSR.ISSUE_TYPE ADD (
	CREATE_RAW                       NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	REGION_LINK_TYPE                 NUMBER(1, 0)     DEFAULT 1 NOT NULL,
	DEFAULT_ASSIGN_TO_USER_SID       NUMBER(10, 0),
	DEFAULT_ASSIGN_TO_ROLE_SID       NUMBER(10, 0),
	ALERT_PENDING_DUE_DAYS           NUMBER(10, 0),
    ALERT_OVERDUE_DAYS               NUMBER(10, 0),
    POSITION		                 NUMBER(10, 0),
    CONSTRAINT CHK_IT_ALERT_PENDING_DAYS CHECK (ALERT_PENDING_DUE_DAYS >= 1),
	CONSTRAINT CHK_IT_ALERT_OVERDUE_DAYS CHECK (ALERT_OVERDUE_DAYS >= 0),
	CONSTRAINT CHK_IT_CREATE_RAW CHECK (CREATE_RAW IN (0, 1)),
    CONSTRAINT CHK_IT_RLT_NONE_OPT_MAND CHECK (REGION_LINK_TYPE IN (0, 1, 2)),	
	CONSTRAINT CHK_IT_UNIQUE_ASSIGN CHECK (NOT (DEFAULT_ASSIGN_TO_USER_SID IS NOT NULL AND DEFAULT_ASSIGN_TO_ROLE_SID IS NOT NULL))
);

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_STATE_PERM ADD CONSTRAINT FK_ICF_ICFSP 
    FOREIGN KEY (APP_SID, ISSUE_CUSTOM_FIELD_ID)
    REFERENCES CSR.ISSUE_CUSTOM_FIELD(APP_SID, ISSUE_CUSTOM_FIELD_ID)
;

ALTER TABLE CSR.ISSUE_CUSTOM_FIELD_STATE_PERM ADD CONSTRAINT FK_IS_ICFSP 
    FOREIGN KEY (ISSUE_STATE_ID)
    REFERENCES CSR.ISSUE_STATE(ISSUE_STATE_ID)
;

ALTER TABLE CSR.ISSUE_TYPE ADD CONSTRAINT FK_CSRU_IT_DEFAULT_ROLE 
    FOREIGN KEY (APP_SID, DEFAULT_ASSIGN_TO_ROLE_SID)
    REFERENCES CSR.ROLE(APP_SID, ROLE_SID)
;

ALTER TABLE CSR.ISSUE_TYPE ADD CONSTRAINT FK_CSRU_IT_DEFAULT_USER 
    FOREIGN KEY (APP_SID, DEFAULT_ASSIGN_TO_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;

ALTER TABLE CSR.ISSUE_TYPE_STATE_PERM ADD CONSTRAINT FK_IS_ITSP 
    FOREIGN KEY (ISSUE_STATE_ID)
    REFERENCES CSR.ISSUE_STATE(ISSUE_STATE_ID)
;

ALTER TABLE CSR.ISSUE_TYPE_STATE_PERM ADD CONSTRAINT FK_IT_ITSP 
    FOREIGN KEY (APP_SID, ISSUE_TYPE_ID)
    REFERENCES CSR.ISSUE_TYPE(APP_SID, ISSUE_TYPE_ID)
;


CREATE SEQUENCE CSR.ISSUE_TYPE_ID_SEQ
    START WITH 10000
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

BEGIN
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (0, 'Default Permissions');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (1, 'Open');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (2, 'Resolve');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (3, 'Closed');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (4, 'Assign To');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (5, 'Email User');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (6, 'Email Correspondent');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (7, 'Reject');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (8, 'Email Role');
	INSERT INTO CSR.ISSUE_STATE (ISSUE_STATE_ID, DESCRIPTION) VALUES (9, 'Create');
END;
/

CREATE OR REPLACE VIEW csr.v$issue_type_perm_default
AS
	SELECT t.app_sid, t.issue_type_id,
			NVL(p.require_due_date, 0) require_due_date, NVL(p.allow_due_date, 1) allow_due_date, 
			NVL(p.require_priority, 0) require_priority, NVL(p.allow_priority, 1) allow_priority, 
			NVL(p.require_assign_user, 0) require_assign_user, NVL(p.allow_assign_user, 1) allow_assign_user, 
			NVL(p.require_assign_role, 0) require_assign_role, NVL(p.allow_assign_role, 1) allow_assign_role, 
			NVL(p.require_region, 0) require_region, NVL(p.allow_region, 1) allow_region
	  FROM issue_type t, (SELECT * FROM issue_type_state_perm WHERE issue_state_id = 0) p
	 WHERE t.app_sid = p.app_sid(+)
	   AND t.issue_type_id = p.issue_type_id(+);

CREATE OR REPLACE VIEW csr.v$issue_type_perm 
AS
	SELECT ts.app_sid, ts.issue_type_id, ts.issue_state_id,
			NVL(p.require_due_date, d.require_due_date) require_due_date, NVL(p.allow_due_date, d.allow_due_date) allow_due_date,
			NVL(p.require_priority, d.require_priority) require_priority, NVL(p.allow_priority, d.allow_priority) allow_priority,
			NVL(p.require_assign_user, d.require_assign_user) require_assign_user, NVL(p.allow_assign_user, d.allow_assign_user) allow_assign_user,
			NVL(p.require_assign_role, d.require_assign_role) require_assign_role, NVL(p.allow_assign_role, d.allow_assign_role) allow_assign_role,
			NVL(p.require_region, d.require_region) require_region, NVL(p.allow_region, d.allow_region) allow_region
	  FROM (SELECT t.app_sid, t.issue_type_id, s.issue_state_id FROM issue_type t, issue_state s WHERE s.issue_state_id <> 0) ts, 
	       issue_type_state_perm p, 
		   v$issue_type_perm_default d
	 WHERE ts.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND ts.app_sid = p.app_sid(+)
	   AND ts.issue_state_id = p.issue_state_id(+)
	   AND ts.issue_type_id = p.issue_type_id(+)
	   AND ts.app_sid = d.app_sid
	   AND ts.issue_type_id = d.issue_type_id;

declare
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found NUMBER;
begin	
	v_list := t_tabs(
		'ISSUE_CUSTOM_FIELD_STATE_PERM',
		'ISSUE_TYPE_STATE_PERM'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					select count(*) 
					  into v_found
					  from all_tab_columns 
					 where owner = 'CSR' 
					   and table_name = UPPER(v_list(i))
					   and column_name = 'APP_SID';

					if v_found = 0 then
						raise_application_error(-20001, 'CSR.'||v_list(i)||' does not have an app_sid column');
					end if;
					
					if v_i = 1 then
						v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
					else
						v_name := SUBSTR(v_list(i), 1, 21)||'_POLICY_'||v_i;
					end if;
					dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CSR',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CSR',
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

@..\issue_pkg
@..\issue_body

@update_tail
