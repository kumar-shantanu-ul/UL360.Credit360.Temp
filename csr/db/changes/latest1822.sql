-- Please update version.sql too -- this keeps clean builds in sync
define version=1822
@update_header

CREATE TABLE CSR.METRIC_DASHBOARD(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METRIC_DASHBOARD_SID    		NUMBER(10, 0)   NOT NULL,
    NAME                    		VARCHAR2(255)   NOT NULL,
	START_DTM 						DATE 			NOT NULL,
	END_DTM							DATE,
	INTERVAL						VARCHAR2(10) 	DEFAULT 'y' NOT NULL,	
    CONSTRAINT PK_METRIC_DASHBOARD	PRIMARY KEY (APP_SID, METRIC_DASHBOARD_SID)
)
;
  
CREATE TABLE CSR.METRIC_DASHBOARD_IND(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METRIC_DASHBOARD_SID    		NUMBER(10, 0)	NOT NULL,
    IND_SID                 		NUMBER(10, 0)	NOT NULL,
    POS								NUMBER(10, 0)	NOT NULL,
	BLOCK_TITLE						VARCHAR2(32)	NOT NULL,
	BLOCK_CSS_CLASS					VARCHAR2(32)	NOT NULL,
	INTEN_VIEW_SCENARIO_RUN_SID		NUMBER(10, 0),
	INTEN_VIEW_FLOOR_AREA_IND_SID	NUMBER(10, 0)	NOT NULL,
	ABSOL_VIEW_SCENARIO_RUN_SID		NUMBER(10, 0),
	CONSTRAINT PK_METRIC_DASHBOARD_IND PRIMARY KEY (APP_SID, METRIC_DASHBOARD_SID, IND_SID)
)
;

CREATE TABLE CSR.METRIC_DASHBOARD_PLUGIN(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METRIC_DASHBOARD_SID    		NUMBER(10, 0)	NOT NULL,
    PLUGIN_ID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD_PLUGIN PRIMARY KEY (APP_SID, METRIC_DASHBOARD_SID, PLUGIN_ID)
)
;

ALTER TABLE CSR.METRIC_DASHBOARD ADD CONSTRAINT FK_METRIC_DASHBOARD_CUSTOMER
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_IND ADD CONSTRAINT FK_METRIC_DASH_IND_METRIC_DASH 
    FOREIGN KEY (APP_SID, METRIC_DASHBOARD_SID)
    REFERENCES CSR.METRIC_DASHBOARD(APP_SID, METRIC_DASHBOARD_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_IND ADD CONSTRAINT FK_METRIC_DASH_IND_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_IND ADD CONSTRAINT FK_METRIC_DASH_IND_INT_FA_IND 
    FOREIGN KEY (APP_SID, INTEN_VIEW_FLOOR_AREA_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_IND ADD CONSTRAINT FK_METRIC_DASH_IND_INT_SCN_RUN 
    FOREIGN KEY (APP_SID, INTEN_VIEW_SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_IND ADD CONSTRAINT FK_METRIC_DASH_IND_ABS_SCN_RUN  
    FOREIGN KEY (APP_SID, ABSOL_VIEW_SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_PLUGIN ADD CONSTRAINT FK_METRIC_DASH_PLG_METRIC_DASH 
    FOREIGN KEY (APP_SID, METRIC_DASHBOARD_SID)
    REFERENCES CSR.METRIC_DASHBOARD(APP_SID, METRIC_DASHBOARD_SID)
;

ALTER TABLE CSR.METRIC_DASHBOARD_PLUGIN ADD CONSTRAINT FK_METRIC_DASH_PLG_PLUGIN_ID 
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

CREATE INDEX csr.ix_metric_dash_ind_ind ON csr.METRIC_DASHBOARD_IND(APP_SID, IND_SID);	

CREATE INDEX csr.ix_metric_dash_ind_fa_ind ON csr.METRIC_DASHBOARD_IND(APP_SID, INTEN_VIEW_FLOOR_AREA_IND_SID);	

CREATE INDEX csr.ix_metric_dash_plg_plugin_id ON csr.METRIC_DASHBOARD_PLUGIN(PLUGIN_ID);	


DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRMetricDashboard', 'csr.metric_dashboard_pkg', NULL, new_class_id);
	EXCEPTION
		WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
			NULL;
	END;
END;
/

DECLARE
	policy_already_exists exception;
	pragma exception_init(policy_already_exists, -28101);

	type t_tabs is table of varchar2(30);
	v_list t_tabs;
	v_null_list t_tabs;
BEGIN	
	v_list := t_tabs(
		'METRIC_DASHBOARD',
		'METRIC_DASHBOARD_IND',
		'METRIC_DASHBOARD_PLUGIN' 		
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
				end;
			end loop;
		end;
	end loop;
END;
/

@..\metric_dashboard_pkg
@..\metric_dashboard_body

GRANT EXECUTE ON csr.metric_dashboard_pkg TO web_user;
GRANT EXECUTE ON csr.metric_dashboard_pkg TO SECURITY;

INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (3, 'Metric dashboards');
	
@update_tail