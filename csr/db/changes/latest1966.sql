-- Please update version.sql too -- this keeps clean builds in sync
define version=1966
@update_header

CREATE TABLE csr.xx_ind_val_rule_2014_01_13 AS (SELECT * FROM csr.ind_validation_rule);

UPDATE csr.ind_validation_rule
   SET expr = (CASE WHEN expr LIKE '%(%' OR expr LIKE '%'||chr(38)||'%' 
					THEN '('||expr||') || value == null'
					ELSE expr||' || value == null'
					END)
WHERE lower(expr) NOT LIKE '%null%';
/

INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) values (1040,'Pivot Table','Credit360.Portlets.PivotTable',EMPTY_CLOB(),'/csr/site/portal/portlets/PivotTable.js');

CREATE TABLE csr.ISSUE_TYPE_AGGREGATE_IND_GRP (
	APP_SID						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ISSUE_TYPE_ID				NUMBER(10) NOT NULL,
	AGGREGATE_IND_GROUP_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISS_TPY_AGG_IND_GRP PRIMARY KEY (APP_SID, ISSUE_TYPE_ID, AGGREGATE_IND_GROUP_ID),
	CONSTRAINT FK_ISS_TYP_AGG_GRP_AGG_GRP FOREIGN KEY (APP_SID, AGGREGATE_IND_GROUP_ID) REFERENCES CSR.AGGREGATE_IND_GROUP (APP_SID, AGGREGATE_IND_GROUP_ID),
	CONSTRAINT FK_ISS_TYP_AGG_GRP_ISS_TYP FOREIGN KEY (APP_SID, ISSUE_TYPE_ID) REFERENCES CSR.ISSUE_TYPE (APP_SID, ISSUE_TYPE_ID)
);

CREATE TABLE csrimp.ISSUE_TYPE_AGGREGATE_IND_GRP (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ISSUE_TYPE_ID				NUMBER(10) NOT NULL,
	AGGREGATE_IND_GROUP_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_ISS_TPY_AGG_IND_GRP PRIMARY KEY (CSRIMP_SESSION_ID, ISSUE_TYPE_ID, AGGREGATE_IND_GROUP_ID),
	CONSTRAINT FK_ISS_TPY_AGG_IND_GRP_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CMS.TAB_ISSUE_AGGREGATE_IND (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    RAISED_IND_SID NUMBER(10),
    REJECTED_IND_SID NUMBER(10),
    CLOSED_ON_TIME_IND_SID NUMBER(10),
    CLOSED_LATE_IND_SID NUMBER(10),
    CLOSED_LATE_U30_IND_SID NUMBER(10),
    CLOSED_LATE_U60_IND_SID NUMBER(10),
    CLOSED_LATE_U90_IND_SID NUMBER(10),
    CLOSED_LATE_O90_IND_SID NUMBER(10),
    CONSTRAINT PK_TAB_ISSUE_AGGREGATE_IND PRIMARY KEY (APP_SID, TAB_SID)
);

CREATE TABLE CMS.TAB_AGGREGATE_IND (
    APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    TAB_AGGREGATE_IND_ID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    COLUMN_SID NUMBER(10),
    IND_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_TAB_AGGREGATE_IND PRIMARY KEY (APP_SID, TAB_AGGREGATE_IND_ID),
    CONSTRAINT TUC_TAB_AGGREGATE_IND_1 UNIQUE (APP_SID, TAB_SID, COLUMN_SID)
);

ALTER TABLE CMS.TAB_ISSUE_AGGREGATE_IND ADD CONSTRAINT TAB_TAB_ISSUE_AGGREGATE_IND 
    FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID,TAB_SID);

ALTER TABLE CMS.TAB_AGGREGATE_IND ADD CONSTRAINT TAB_TAB_AGGREGATE_IND 
    FOREIGN KEY (APP_SID, TAB_SID) REFERENCES CMS.TAB (APP_SID,TAB_SID);

ALTER TABLE CMS.TAB_AGGREGATE_IND ADD CONSTRAINT TAB_COLUMN_TAB_AGGREGATE_IND 
    FOREIGN KEY (APP_SID, COLUMN_SID) REFERENCES CMS.TAB_COLUMN (APP_SID,COLUMN_SID);
	
CREATE SEQUENCE CMS.TAB_AGGREGATE_IND_ID_SEQ;

CREATE TABLE CSRIMP.CMS_TAB_ISSUE_AGGREGATE_IND (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    RAISED_IND_SID NUMBER(10),
    REJECTED_IND_SID NUMBER(10),
    CLOSED_ON_TIME_IND_SID NUMBER(10),
    CLOSED_LATE_IND_SID NUMBER(10),
    CLOSED_LATE_U30_IND_SID NUMBER(10),
    CLOSED_LATE_U60_IND_SID NUMBER(10),
    CLOSED_LATE_U90_IND_SID NUMBER(10),
    CLOSED_LATE_O90_IND_SID NUMBER(10),
    CONSTRAINT PK_CMS_TAB_ISSUE_AGG_IND PRIMARY KEY (CSRIMP_SESSION_ID, TAB_SID),
	CONSTRAINT FK_CMS_TAB_ISSUE_AGG_IND_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CMS_TAB_AGGREGATE_IND (
    CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    TAB_AGGREGATE_IND_ID NUMBER(10) NOT NULL,
    TAB_SID NUMBER(10) NOT NULL,
    COLUMN_SID NUMBER(10),
    IND_SID NUMBER(10) NOT NULL,
    CONSTRAINT PK_CMS_TAB_AGG_IND PRIMARY KEY (CSRIMP_SESSION_ID, TAB_AGGREGATE_IND_ID),
    CONSTRAINT TUC_TAB_AGG_IND_1 UNIQUE (CSRIMP_SESSION_ID, TAB_SID, COLUMN_SID),
	CONSTRAINT FK_CMS_TAB_AGG_IND_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'ISSUE_TYPE_AGGREGATE_IND_GRP'
    );
    FOR I IN 1 .. v_list.count
    LOOP
        BEGIN
            DBMS_RLS.ADD_POLICY(
                object_schema   => 'CSR',
                object_name     => v_list(i),
                policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
                function_schema => 'CSR',
                policy_function => 'appSidCheck',
                statement_types => 'select, insert, update, delete',
                update_check    => true,
                policy_type     => dbms_rls.context_sensitive );
                DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
        EXCEPTION
            WHEN POLICY_ALREADY_EXISTS THEN
                DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
            WHEN FEATURE_NOT_ENABLED THEN
                DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
        END;
    END LOOP;
END;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
begin	
	v_list := t_tabs(
		'ISSUE_TYPE_AGGREGATE_IND_GRP',
		'CMS_TAB_AGGREGATE_IND',
		'CMS_TAB_ISSUE_AGGREGATE_IND'
	);
	for i in 1 .. v_list.count loop
		begin					
			dbms_rls.add_policy(
				object_schema   => 'CSRIMP',
				object_name     => v_list(i),
				policy_name     => (SUBSTR(v_list(i), 1, 26) || '_POL') , 
				function_schema => 'CSRIMP',
				policy_function => 'SessionIDCheck',
				statement_types => 'select, insert, update, delete',
				update_check	=> TRUE,
				policy_type     => dbms_rls.context_sensitive);
		exception
			when policy_already_exists then
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policy '||v_list(i)||' not applied as feature not enabled');
		end;
	end loop;
end;
/

DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
begin	
	v_list := t_tabs(
		'TAB_ISSUE_AGGREGATE_IND',
		'TAB_AGGREGATE_IND'
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
					
					--dbms_output.put_line('doing '||v_name);
				    dbms_rls.add_policy(
				        object_schema   => 'CMS',
				        object_name     => v_list(i),
				        policy_name     => v_name,
				        function_schema => 'CMS',
				        policy_function => 'appSidCheck',
				        statement_types => 'select, insert, update, delete',
				        update_check	=> true,
				        policy_type     => dbms_rls.context_sensitive );
				    -- dbms_output.put_line('done  '||v_name);
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

grant select,insert,update,delete on csrimp.issue_type_aggregate_ind_grp to web_user;
grant insert on csr.issue_type_aggregate_ind_grp to csrimp;
grant select,insert,update,delete on csrimp.cms_tab_aggregate_ind to web_user;
grant select,insert,update,delete on csrimp.cms_tab_issue_aggregate_ind to web_user;
grant insert on cms.tab_aggregate_ind to csrimp;
grant insert on cms.tab_issue_aggregate_ind to csrimp;
grant select on cms.tab_aggregate_ind_id_seq to csrimp;

BEGIN
	-- Copy audit aggregate inds to new table
	BEGIN
		INSERT INTO csr.issue_type_aggregate_ind_grp (app_sid, issue_type_id, aggregate_ind_group_id)
			SELECT app_sid, csr.csr_data_pkg.ISSUE_NON_COMPLIANCE, aggregate_ind_group_id
			  FROM csr.aggregate_ind_group
			 WHERE name = 'InternalAudit'
			   AND app_sid IN (SELECT DISTINCT app_sid FROM csr.issue_type WHERE issue_type_id = csr.csr_data_pkg.ISSUE_NON_COMPLIANCE);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

ALTER TABLE csr.issue_type ADD (involve_min_users_in_issue NUMBER(1) DEFAULT 0 NOT NULL);

-- Add not null column to csrimp
ALTER TABLE csrimp.issue_type ADD (involve_min_users_in_issue NUMBER(1));
UPDATE csrimp.issue_type SET involve_min_users_in_issue=0;
ALTER TABLE csrimp.issue_type MODIFY involve_min_users_in_issue NOT NULL;

@..\audit_pkg
@..\issue_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\aggregate_ind_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\util_pkg

@..\schema_body
@..\csrimp\imp_body
@..\issue_body
@..\audit_body
@..\aggregate_ind_body
@..\..\..\aspen2\cms\db\tab_body
@..\..\..\aspen2\cms\db\util_body

@..\..\..\aspen2\cms\db\pivot_pkg
@..\..\..\aspen2\cms\db\pivot_body

@update_tail