-- Please update version.sql too -- this keeps clean builds in sync
define version=2358
@update_header

-- FB48790
CREATE TABLE CSR.DELEGATION_DESCRIPTION (
	APP_SID             NUMBER(10)          DEFAULT sys_context('security','app') NOT NULL,
	DELEGATION_SID      NUMBER(10)          NOT NULL,
	LANG                VARCHAR2(10)        NOT NULL,
	DESCRIPTION         VARCHAR2(1023)      NOT NULL,
	CONSTRAINT PK_DELEGATION_DESCRIPTION PRIMARY KEY (APP_SID, DELEGATION_SID, LANG),
	CONSTRAINT FK_DELEGATION_DESCRIPTION FOREIGN KEY (APP_SID, DELEGATION_SID) REFERENCES CSR.DELEGATION (APP_SID, DELEGATION_SID) ON DELETE CASCADE
);

CREATE OR REPLACE VIEW csr.v$delegation AS
	SELECT d.*, NVL(dd.description, d.name) as description, dp.submit_confirmation_text
	  FROM (
		SELECT delegation.*, CONNECT_BY_ROOT(delegation_sid) root_delegation_sid
		  FROM delegation
		 START WITH parent_sid = app_sid
	   CONNECT BY parent_sid = prior delegation_sid) d
	  LEFT JOIN delegation_description dd ON dd.delegation_sid = root_delegation_sid 
	   AND dd.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	  LEFT JOIN delegation_policy dp ON dp.delegation_sid = root_delegation_sid
;

CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_COL AS
	SELECT deleg_plan_col_id, deleg_plan_sid, d.name label, dpc.is_hidden, 'Delegation' type, dpcd.delegation_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_deleg dpcd ON dpc.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
		JOIN v$delegation d ON dpcd.delegation_sid = d.delegation_sid
	 UNION
	SELECT deleg_plan_col_id, deleg_plan_sid, qs.label, dpc.is_hidden, 'Survey' type, dpcs.survey_sid object_sid
	  FROM deleg_plan_col dpc
		JOIN deleg_plan_col_survey dpcs ON dpc.deleg_plan_col_survey_id = dpcs.deleg_plan_col_survey_id
		JOIN v$quick_survey qs ON dpcs.survey_sid = qs.survey_sid
	;
	

-- For CSRImp
CREATE TABLE CSRIMP.DELEGATION_DESCRIPTION (
	CSRIMP_SESSION_ID		NUMBER(10) 			DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	DELEGATION_SID      	NUMBER(10)          NOT NULL,
	LANG                	VARCHAR2(10)        NOT NULL,
	DESCRIPTION               VARCHAR2(1023)    NOT NULL,
	CONSTRAINT PK_DELEGATION_DESCRIPTION PRIMARY KEY (DELEGATION_SID, LANG),
	CONSTRAINT FK_DELEGATION_DESCRIPTION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

grant select,insert,update on csr.delegation_description to csrimp;
grant insert,select,update,delete on csrimp.delegation_description to web_user;


DECLARE
    FEATURE_NOT_ENABLED EXCEPTION;
    PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
    POLICY_ALREADY_EXISTS EXCEPTION;
    PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
    TYPE T_TABS IS TABLE OF VARCHAR2(30);
    v_list T_TABS;
BEGIN
    v_list := t_tabs(
        'DELEGATION_DESCRIPTION'
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



@..\csr_app_body
@..\csr_user_body
@..\csrimp\imp_body
@..\deleg_plan_body
@..\delegation_pkg
@..\delegation_body
@..\indicator_body
@..\measure_body
@..\region_body
@..\schema_pkg
@..\schema_body



@update_tail

