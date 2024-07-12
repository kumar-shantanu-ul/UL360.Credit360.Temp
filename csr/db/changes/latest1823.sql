-- Please update version.sql too -- this keeps clean builds in sync
define version=1823
@update_header

CREATE TABLE CSR.BENCHMARK_DASHBOARD(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BENCHMARK_DASHBOARD_SID    		NUMBER(10, 0)   NOT NULL,
    NAME                    		VARCHAR2(255)   NOT NULL,
	START_DTM	 					DATE 			NOT NULL,
	END_DTM							DATE,
	INTERVAL						VARCHAR2(10) 	DEFAULT 'y' NOT NULL,	
	YEAR_BUILT_IND_SID				NUMBER(10, 0),
    CONSTRAINT PK_BENCHMARK_DASHBOARD	PRIMARY KEY (APP_SID, BENCHMARK_DASHBOARD_SID)
)
;
  
CREATE TABLE CSR.BENCHMARK_DASHBOARD_IND(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BENCHMARK_DASHBOARD_SID    		NUMBER(10, 0)	NOT NULL,
    IND_SID                 		NUMBER(10, 0)	NOT NULL,
	DISPLAY_NAME					VARCHAR2(255),
	SCENARIO_RUN_SID				NUMBER(10, 0),
	FLOOR_AREA_IND_SID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_IND PRIMARY KEY (APP_SID, BENCHMARK_DASHBOARD_SID, IND_SID)
)
;

CREATE TABLE CSR.BENCHMARK_DASHBOARD_PLUGIN(
    APP_SID                 		NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    BENCHMARK_DASHBOARD_SID    		NUMBER(10, 0)	NOT NULL,
    PLUGIN_ID						NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_PLUGIN PRIMARY KEY (APP_SID, BENCHMARK_DASHBOARD_SID, PLUGIN_ID)
)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD ADD CONSTRAINT FK_BENCH_DASH_CUSTOMER
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD ADD CONSTRAINT FK_BENCH_DASH_YEAR_BUILT_IND 
    FOREIGN KEY (APP_SID, YEAR_BUILT_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_IND ADD CONSTRAINT FK_BENCH_DASH_IND_BENCH_DASH 
    FOREIGN KEY (APP_SID, BENCHMARK_DASHBOARD_SID)
    REFERENCES CSR.BENCHMARK_DASHBOARD(APP_SID, BENCHMARK_DASHBOARD_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_IND ADD CONSTRAINT FK_BENCH_DASH_IND_IND 
    FOREIGN KEY (APP_SID, IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_IND ADD CONSTRAINT FK_BENCH_DASH_IND_INT_FA_IND 
    FOREIGN KEY (APP_SID, FLOOR_AREA_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_IND ADD CONSTRAINT FK_BENCH_DASH_IND_SCN_RUN 
    FOREIGN KEY (APP_SID, SCENARIO_RUN_SID)
    REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_PLUGIN ADD CONSTRAINT FK_BENCH_DASH_PLG_BENCH_DASH 
    FOREIGN KEY (APP_SID, BENCHMARK_DASHBOARD_SID)
    REFERENCES CSR.BENCHMARK_DASHBOARD(APP_SID, BENCHMARK_DASHBOARD_SID)
;

ALTER TABLE CSR.BENCHMARK_DASHBOARD_PLUGIN ADD CONSTRAINT FK_BENCH_DASH_PLG_PLUGIN_ID 
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;

CREATE INDEX csr.ix_bench_dash_year_built_ind ON csr.BENCHMARK_DASHBOARD(APP_SID, YEAR_BUILT_IND_SID);	

CREATE INDEX csr.ix_bench_dash_ind_ind ON csr.BENCHMARK_DASHBOARD_IND(APP_SID, IND_SID);	

CREATE INDEX csr.ix_bench_dash_ind_fa_ind ON csr.BENCHMARK_DASHBOARD_IND(APP_SID, FLOOR_AREA_IND_SID);	

CREATE INDEX csr.ix_bench_dash_plg_plugin_id ON csr.BENCHMARK_DASHBOARD_PLUGIN(PLUGIN_ID);	


DECLARE
	new_class_id 	security.security_pkg.T_SID_ID;
	v_act 			security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_ACT);	
	BEGIN	
		security.class_pkg.CreateClass(v_act, NULL, 'CSRBenchmarkingDashboard', 'csr.benchmarking_dashboard_pkg', NULL, new_class_id);
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
		'BENCHMARK_DASHBOARD',
		'BENCHMARK_DASHBOARD_IND',
		'BENCHMARK_DASHBOARD_PLUGIN' 		
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

@..\benchmarking_dashboard_pkg
@..\benchmarking_dashboard_body

grant execute on csr.benchmarking_dashboard_pkg to web_user;
grant execute on csr.benchmarking_dashboard_pkg to security;
	
@update_tail