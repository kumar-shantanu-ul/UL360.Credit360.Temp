-- Please update version.sql too -- this keeps clean builds in sync
define version=1944
@update_header

CREATE TABLE CSR.PROJECT_TAG_FILTER(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROJECT_SID     NUMBER(10, 0)    NOT NULL,
    TAG_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    TAG_ID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_PROJECT_TAG_FILTER PRIMARY KEY (APP_SID, PROJECT_SID, TAG_GROUP_ID, TAG_ID)
)
;

ALTER TABLE CSR.PROJECT_TAG_FILTER ADD CONSTRAINT FK_PRJTAGGRP_PRJTAGFLT 
    FOREIGN KEY (APP_SID, PROJECT_SID, TAG_GROUP_ID)
    REFERENCES CSR.PROJECT_TAG_GROUP(APP_SID, PROJECT_SID, TAG_GROUP_ID)
;

ALTER TABLE CSR.PROJECT_TAG_FILTER ADD CONSTRAINT FK_TAGGRPMBR_PRJTAGFLT 
    FOREIGN KEY (APP_SID, TAG_GROUP_ID, TAG_ID)
    REFERENCES CSR.TAG_GROUP_MEMBER(APP_SID, TAG_GROUP_ID, TAG_ID)
;

CREATE INDEX CSR.IX_PRJTAGGRP_PRJTAGFLT ON CSR.PROJECT_TAG_FILTER(APP_SID, PROJECT_SID, TAG_GROUP_ID);
CREATE INDEX CSR.IX_TAGGRPMBR_PRJTAGFLT ON CSR.PROJECT_TAG_FILTER(APP_SID, TAG_GROUP_ID, TAG_ID);

-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);
	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
	v_found number;
begin	
	v_list := t_tabs(
		'PROJECT_TAG_FILTER'
	);
	for i in 1 .. v_list.count loop
		declare
			v_name varchar2(30);
			v_i pls_integer default 1;
		begin
			loop
				begin
					
					-- verify that the table has an app_sid column (dev helper)
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
				  	exit;
				exception
					when policy_already_exists then
						v_i := v_i + 1;
					WHEN FEATURE_NOT_ENABLED THEN
						DBMS_OUTPUT.PUT_LINE('RLS policy '||v_name||' not applied as feature not enabled');
						exit;
				end;
			end loop;
		end;
	end loop;
end;
/

@../initiative_project_pkg
@../initiative_project_body

@update_tail