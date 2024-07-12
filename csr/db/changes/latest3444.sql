define version=3444
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE TABLE CSR.CALC_BASELINE_CONFIG_DEPENDENCY (
    APP_SID                 NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    CALC_IND_SID            NUMBER(10, 0)    NOT NULL,
    BASELINE_CONFIG_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CALC_BASELINE_DEP PRIMARY KEY (APP_SID, CALC_IND_SID, BASELINE_CONFIG_ID)
)
;
CREATE TABLE CSRIMP.CALC_BASELINE_CONFIG_DEPENDENCY(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    CALC_IND_SID                    NUMBER(10, 0)    NOT NULL,
    BASELINE_CONFIG_ID              NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_CALC_BASELINE_CONFIG_DEP PRIMARY KEY (CSRIMP_SESSION_ID, CALC_IND_SID, BASELINE_CONFIG_ID),
    CONSTRAINT FK_BASELINE_CONFIG_DEPENDENCY_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_baseline_config (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_baseline_config_id			NUMBER(10)	NOT NULL,
	new_baseline_config_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_baseline_config primary key (csrimp_session_id, old_baseline_config_id) USING INDEX,
	CONSTRAINT uk_map_baseline_config unique (csrimp_session_id, new_baseline_config_id) USING INDEX,
    CONSTRAINT FK_MAP_BASELINE_CONFIG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE csrimp.map_baseline_config_period (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_baseline_config_period_id			NUMBER(10)	NOT NULL,
	new_baseline_config_period_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_baseline_period_config primary key (csrimp_session_id, old_baseline_config_period_id) USING INDEX,
	CONSTRAINT uk_map_baseline_period_config unique (csrimp_session_id, new_baseline_config_period_id) USING INDEX,
    CONSTRAINT FK_MAP_BASELINE_PERIOD_CONFIG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


ALTER TABLE csr.BASELINE_CONFIG
DROP CONSTRAINT uk_baseline_lookup_key DROP INDEX;
ALTER TABLE csr.BASELINE_CONFIG
ADD CONSTRAINT uk_baseline_lookup_key UNIQUE (APP_SID, BASELINE_LOOKUP_KEY);
ALTER TABLE CSR.CALC_BASELINE_CONFIG_DEPENDENCY ADD CONSTRAINT FK_CALC_BASELINE_DEP_CALC
    FOREIGN KEY (APP_SID, CALC_IND_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID)
;
ALTER TABLE CSR.CALC_BASELINE_CONFIG_DEPENDENCY ADD CONSTRAINT FK_CALC_BASELINE_DEP_BASELINE
    FOREIGN KEY (APP_SID, BASELINE_CONFIG_ID)
    REFERENCES CSR.BASELINE_CONFIG(APP_SID, BASELINE_CONFIG_ID)
;
ALTER TABLE CSRIMP.CREDENTIAL_MANAGEMENT MODIFY AUTH_SCOPE_ID NULL;
create index csr.ix_calc_baseline_config_depe_baseline_config_id on csr.calc_baseline_config_dependency (app_sid, baseline_config_id);


grant select,insert,update,delete on csrimp.calc_baseline_config_dependency to tool_user;
grant insert on csr.calc_baseline_config_dependency to csrimp;
grant select on csr.baseline_config_id_seq to csrimp;
grant select on csr.baseline_config_period_id_seq to csrimp;














@..\csr_data_pkg
@..\energy_star_job_pkg
@..\calc_pkg
@..\indicator_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@..\baseline_pkg


@..\user_report_body
@..\quick_survey_body
@..\deleg_plan_body
@..\enable_body
@..\energy_star_job_body
@..\non_compliance_report_body
@..\delegation_body
@..\csr_app_body
@..\calc_body
@..\indicator_body
@..\schema_body
@..\baseline_body
@..\csrimp\imp_body



@update_tail
