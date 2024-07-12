-- Please update version.sql too -- this keeps clean builds in sync
define version=2986
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.forecasting_slot (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	number_of_years				NUMBER(10, 0) NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					VARCHAR2(10),
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0) NOT NULL,
	created_dtm 				DATE NOT NULL,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	include_all_inds			NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_FORECASTING			PRIMARY KEY	(APP_SID, FORECASTING_SID),
	CONSTRAINT FK_FORCSTING_SCNRIO_RUN	FOREIGN KEY	(APP_SID, SCENARIO_RUN_SID) REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID),
	CONSTRAINT FK_FORCSTING_CREATED_BY	FOREIGN KEY	(APP_SID, CREATED_BY_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_FORCSTING_RFRSHED_BY	FOREIGN KEY	(APP_SID, LAST_REFRESH_USER_SID) REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID),
	CONSTRAINT FK_FORCSTING_PERIOD_INT	FOREIGN KEY	(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID) REFERENCES CSR.PERIOD_INTERVAL(APP_SID, PERIOD_SET_ID, PERIOD_INTERVAL_ID),
	CONSTRAINT CK_FORCSTING_RULE_TYPE 	CHECK (RULE_TYPE IN ('Fixed', '*', '+')),
	CONSTRAINT CK_FORCSTING_ALL_INDS	CHECK (INCLUDE_ALL_INDS IN (0, 1))
);

CREATE TABLE csrimp.forecasting_slot (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	name						VARCHAR2(255) NOT NULL,
	period_start_dtm			DATE NOT NULL,
	number_of_years				NUMBER(10, 0) NOT NULL,
	period_set_id				NUMBER(10, 0) NOT NULL,
	period_interval_id			NUMBER(10, 0) NOT NULL,
	rule_type					VARCHAR2(10),
	scenario_run_sid			NUMBER(10, 0) NOT NULL,
	created_by_user_sid			NUMBER(10, 0) NOT NULL,
	created_dtm 				DATE NOT NULL,
	last_refresh_user_sid 		NUMBER(10, 0),
	last_refresh_dtm 			DATE,
	include_all_inds			NUMBER(1, 0) NOT NULL,
	CONSTRAINT PK_FORECASTING			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID),
	CONSTRAINT FK_FORECASTING_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE,
	CONSTRAINT CK_FORCSTING_RULE_TYPE 	CHECK (RULE_TYPE IN ('Fixed', '*', '+')),
	CONSTRAINT CK_FORCSTING_ALL_INDS	CHECK (INCLUDE_ALL_INDS IN (0, 1))
);


CREATE TABLE csr.forecasting_indicator (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_IND			PRIMARY KEY	(APP_SID, FORECASTING_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_IND 		FOREIGN KEY	(APP_SID, IND_SID) REFERENCES CSR.IND(APP_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_FOR_SID	FOREIGN KEY	(APP_SID, FORECASTING_SID) REFERENCES CSR.FORECASTING_SLOT(APP_SID, FORECASTING_SID)
);

CREATE TABLE csrimp.forecasting_indicator (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_IND			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID, IND_SID),
	CONSTRAINT FK_FORCSTNG_IND_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csr.forecasting_region (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_REGION		PRIMARY KEY	(APP_SID, FORECASTING_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REG_REG 		FOREIGN KEY	(APP_SID, REGION_SID) REFERENCES CSR.REGION(APP_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REG_FOR_SID	FOREIGN KEY	(APP_SID, FORECASTING_SID) REFERENCES CSR.FORECASTING_SLOT(APP_SID, FORECASTING_SID)
);

CREATE TABLE csrimp.forecasting_region (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_FORCSTNG_REGION			PRIMARY KEY	(CSRIMP_SESSION_ID, FORECASTING_SID, REGION_SID),
	CONSTRAINT FK_FORCSTNG_REGION_SESSION	FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


-- US5270
CREATE TABLE csr.forecasting_rule (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	rule_type					VARCHAR2(10) NOT NULL,
	rule_val					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_RULE				PRIMARY KEY	(app_sid, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_RULE_SLOT_SID 	FOREIGN KEY	(app_sid, forecasting_sid) REFERENCES csr.forecasting_slot(app_sid, forecasting_sid),
	CONSTRAINT FK_FORECAST_RULE_IND_SID 	FOREIGN KEY	(app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid),
	CONSTRAINT FK_FORECAST_RULE_REGION_SID 	FOREIGN KEY	(app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid),
	CONSTRAINT CK_FORECAST_RULE_RULE_TYPE 	CHECK (rule_type IN ('Fixed', '*', '+'))
);

CREATE TABLE csr.forecasting_val (
	app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	val_number					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_VAL				PRIMARY KEY	(app_sid, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_VAL_SLOT_SID 	FOREIGN KEY	(app_sid, forecasting_sid) REFERENCES csr.forecasting_slot(app_sid, forecasting_sid),
	CONSTRAINT FK_FORECAST_VAL_IND_SID 		FOREIGN KEY	(app_sid, ind_sid) REFERENCES csr.ind(app_sid, ind_sid),
	CONSTRAINT FK_FORECAST_VAL_REGION_SID 	FOREIGN KEY	(app_sid, region_sid) REFERENCES csr.region(app_sid, region_sid)
);


CREATE TABLE csrimp.forecasting_rule (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	rule_type					VARCHAR2(10) NOT NULL,
	rule_val					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_RULE			PRIMARY KEY	(csrimp_session_id, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_RULE_SESSION	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.forecasting_val (
	csrimp_session_id			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	forecasting_sid				NUMBER(10, 0) NOT NULL,
	ind_sid						NUMBER(10, 0) NOT NULL,
	region_sid					NUMBER(10, 0) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	val_number					NUMBER(24, 10) NOT NULL,
	CONSTRAINT PK_FORECAST_VAL			PRIMARY KEY	(csrimp_session_id, forecasting_sid, ind_sid, region_sid, start_dtm, end_dtm),
	CONSTRAINT FK_FORECAST_VAL_SESSION	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);


-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.property_mandatory_roles TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_slot TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_indicator TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_region TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_rule TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.forecasting_val TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_id    NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRForecasting', 'csr.forecasting_pkg', null, v_id);
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
	NULL;
END;
/

-- ** New package grants **
-- Create dummy packages for the grant
create or replace package csr.forecasting_pkg as
	procedure dummy;
end;
/
create or replace package body csr.forecasting_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/
grant execute on csr.forecasting_pkg to security;
grant execute on csr.forecasting_pkg to web_user;
-- *** Conditional Packages ***

-- *** Packages ***
@../forecasting_pkg
@../forecasting_body
@../csrimp/imp_pkg
@../schema_pkg
@../csrimp/imp_body
@../schema_body
@../enable_pkg
@../enable_body

@update_tail
