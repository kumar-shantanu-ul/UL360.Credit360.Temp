-- Please update version.sql too -- this keeps clean builds in sync
define version=3443
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

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

-- Alter tables

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

-- *** Grants ***

grant select,insert,update,delete on csrimp.calc_baseline_config_dependency to tool_user;
grant insert on csr.calc_baseline_config_dependency to csrimp;

grant select on csr.baseline_config_id_seq to csrimp;
grant select on csr.baseline_config_period_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../calc_pkg
@../csr_data_pkg
@../indicator_pkg
@../schema_pkg
@../csrimp/imp_pkg
@../baseline_pkg

@../csr_app_body
@../calc_body
@../indicator_body
@../schema_body
@../baseline_body

@../csrimp/imp_body

@update_tail
