-- Please update version.sql too -- this keeps clean builds in sync
define version=849
@update_header

grant select, update, references on csr.scenario to actions;
grant select, update, references on csr.scenario_rule to actions;
grant select, update, insert, delete, references on csr.scenario_auto_run_request to actions;

grant execute on csr.scenario_pkg to actions;
grant execute on csr.scenario_run_pkg to actions;

ALTER TABLE ACTIONS.TASK_STATUS ADD (
	SHOW_IN_FILTER      NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    CHECK (SHOW_IN_FILTER IN(0,1))
)
;

CREATE TABLE ACTIONS.SCENARIO_FILTER_STATUS(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID      NUMBER(10, 0)    NOT NULL,
    RULE_ID           NUMBER(10, 0)    NOT NULL,
    TASK_STATUS_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK164 PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID, TASK_STATUS_ID)
)
;

CREATE TABLE ACTIONS.SCENARIO_FILTER(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SCENARIO_SID    NUMBER(10, 0)    NOT NULL,
    RULE_ID         NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK161 PRIMARY KEY (APP_SID, SCENARIO_SID, RULE_ID)
)
;

ALTER TABLE ACTIONS.SCENARIO_FILTER_STATUS ADD CONSTRAINT RefTASK_STATUS327 
    FOREIGN KEY (APP_SID, TASK_STATUS_ID)
    REFERENCES ACTIONS.TASK_STATUS(APP_SID, TASK_STATUS_ID)
;

ALTER TABLE ACTIONS.SCENARIO_FILTER_STATUS ADD CONSTRAINT RefSCENARIO_FLTER328 
    FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID)
    REFERENCES ACTIONS.SCENARIO_FILTER(APP_SID, SCENARIO_SID, RULE_ID)
;

-- Cross schema
ALTER TABLE ACTIONS.SCENARIO_FILTER ADD CONSTRAINT FK_SCN_RULE_FILTER
    FOREIGN KEY (APP_SID, SCENARIO_SID, RULE_ID)
    REFERENCES CSR.SCENARIO_RULE(APP_SID, SCENARIO_SID, RULE_ID)
;

-- FK indexes
create index actions.ix_scn_filter_task_status on actions.scenario_filter_status (app_sid, task_status_id);
create index actions.ix_scn_filter_filter_status on actions.scenario_filter_status (app_sid, scenario_sid, rule_id);

-- RLS
BEGIN
	dbms_rls.add_policy(
		object_schema   => 'ACTIONS',
		object_name     => 'SCENARIO_FILTER',
		policy_name     => 'SCENARIO_FILTER_POLICY',
		function_schema => 'ACTIONS',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
		
	dbms_rls.add_policy(
		object_schema   => 'ACTIONS',
		object_name     => 'SCENARIO_FILTER_STATUS',
		policy_name     => 'SCENARIO_FILTER_STATUS_POLICY',
		function_schema => 'ACTIONS',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.context_sensitive );
END;
/

grant delete on actions.scenario_filter to csr;
grant delete on actions.scenario_filter_status to csr;

-- CSR packages
@../scenario_pkg
@../stored_calc_datasource_pkg
@../scenario_body
@../stored_calc_datasource_body
@../alert_body
@../indicator_body

-- ACTIONS packages
@../actions/initiative_pkg
@../actions/scenario_pkg
@../actions/initiative_body
@../actions/scenario_body

grant execute on actions.scenario_pkg to web_user;

@update_tail
