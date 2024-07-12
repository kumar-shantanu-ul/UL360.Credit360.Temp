-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=3
@update_header
/*
DROP TABLE csr.degreeday_settings;
DROP TABLE csr.degreeday_region;
DROP TABLE csr.degreeday_data;
DROP TABLE csr.degreeday_account;
DROP TABLE csrimp.degreeday_settings;
DROP TABLE csrimp.degreeday_region;
DELETE FROM csr.module_param WHERE module_id = 74;
DELETE FROM csr.module WHERE module_id = 74;
*/

-- *** DDL ***
-- Create tables
CREATE TABLE csr.degreeday_account (
	account_name					VARCHAR2(128) NOT NULL,
	account_key						VARCHAR2(1024) NOT NULL,
	security_key					VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_degreeday_account PRIMARY KEY (account_name)
);

CREATE TABLE csr.degreeday_data (
	station_id						VARCHAR2(32) NOT NULL,
	calculation_type				NUMBER(1, 0) NOT NULL,
	period_dtm						DATE NOT NULL,
	base_temp						NUMBER(3, 1) NOT NULL,
	degree_days						NUMBER(9, 1) NULL,
	CONSTRAINT pk_degreeday_data PRIMARY KEY (station_id, calculation_type, period_dtm, base_temp),
	CONSTRAINT ck_degreeday_data_calc CHECK (calculation_type IN (0, 1))
);

CREATE TABLE csr.degreeday_settings (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	account_name					VARCHAR2(128) NOT NULL,
	download_enabled				NUMBER(1, 0) NOT NULL,
	earliest_fetch_dtm				DATE NOT NULL,
	average_years					NUMBER(3, 0) NOT NULL,
	heating_base_temp_ind_sid		NUMBER(10, 0) NULL,
	cooling_base_temp_ind_sid		NUMBER(10, 0) NULL,
	heating_degree_days_ind_sid		NUMBER(10, 0) NULL,
	cooling_degree_days_ind_sid		NUMBER(10, 0) NULL,
	heating_average_ind_sid			NUMBER(10, 0) NULL,
	cooling_average_ind_sid			NUMBER(10, 0) NULL,
	last_sync_dtm					DATE NULL,
	CONSTRAINT pk_degreeday_settings PRIMARY KEY (app_sid),
	CONSTRAINT fk_degreeday_settings_account 
		FOREIGN KEY (account_name) REFERENCES csr.degreeday_account (account_name),
	CONSTRAINT fk_degreeday_settings_ind_1
		FOREIGN KEY (app_sid, heating_base_temp_ind_sid) REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_degreeday_settings_ind_2
		FOREIGN KEY (app_sid, cooling_base_temp_ind_sid) REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_degreeday_settings_ind_3
		FOREIGN KEY (app_sid, heating_degree_days_ind_sid) REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_degreeday_settings_ind_4
		FOREIGN KEY (app_sid, cooling_degree_days_ind_sid) REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_degreeday_settings_ind_5
		FOREIGN KEY (app_sid, heating_average_ind_sid) REFERENCES csr.ind (app_sid, ind_sid),
	CONSTRAINT fk_degreeday_settings_ind_6
		FOREIGN KEY (app_sid, cooling_average_ind_sid) REFERENCES csr.ind (app_sid, ind_sid)
);
CREATE INDEX csr.ix_degreeday_set_account_name ON csr.degreeday_settings (account_name);
CREATE INDEX csr.ix_degreeday_set_heating_base ON csr.degreeday_settings (app_sid, heating_base_temp_ind_sid);
CREATE INDEX csr.ix_degreeday_set_cooling_base ON csr.degreeday_settings (app_sid, cooling_base_temp_ind_sid);
CREATE INDEX csr.ix_degreeday_set_cooling_avg ON csr.degreeday_settings (app_sid, cooling_average_ind_sid);
CREATE INDEX csr.ix_degreeday_set_heating_avg ON csr.degreeday_settings (app_sid, heating_average_ind_sid);
CREATE INDEX csr.ix_degreeday_set_cooling_val ON csr.degreeday_settings (app_sid, cooling_degree_days_ind_sid);
CREATE INDEX csr.ix_degreeday_set_heating_val ON csr.degreeday_settings (app_sid, heating_degree_days_ind_sid);

CREATE TABLE csr.degreeday_region (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	region_sid						NUMBER(10) NOT NULL,
	station_id						VARCHAR2(32) NOT NULL,
	station_description				VARCHAR2(512) NULL,
	station_update_dtm				DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT pk_degreeday_region PRIMARY KEY (app_sid, region_sid),
	CONSTRAINT fk_degreeday_region_region 
		FOREIGN KEY (app_sid, region_sid) REFERENCES csr.region (app_sid, region_sid)
);

-- CSRIMP
CREATE TABLE csrimp.degreeday_settings (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	account_name					VARCHAR2(128) NOT NULL,
	download_enabled				NUMBER(1, 0) NOT NULL,
	earliest_fetch_dtm				DATE NOT NULL,
	average_years					NUMBER(3, 0) NOT NULL,
	heating_base_temp_ind_sid		NUMBER(10, 0) NULL,
	cooling_base_temp_ind_sid		NUMBER(10, 0) NULL,
	heating_degree_days_ind_sid		NUMBER(10, 0) NULL,
	cooling_degree_days_ind_sid		NUMBER(10, 0) NULL,
	heating_average_ind_sid			NUMBER(10, 0) NULL,
	cooling_average_ind_sid			NUMBER(10, 0) NULL,
	last_sync_dtm					DATE NULL,
	CONSTRAINT pk_degreeday_settings PRIMARY KEY (csrimp_session_id),
    CONSTRAINT fk_degreeday_settings_session 
		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.degreeday_region (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	region_sid						NUMBER(10) NOT NULL,
	station_id						VARCHAR2(32) NOT NULL,
	station_description				VARCHAR2(512) NULL,
	station_update_dtm				DATE NOT NULL,
	CONSTRAINT pk_degreeday_region PRIMARY KEY (csrimp_session_id, region_sid, station_id),
    CONSTRAINT fk_degreeday_region_session 
		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.degreeday_settings TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.degreeday_region TO web_user;
GRANT SELECT, INSERT, UPDATE ON csr.degreeday_settings TO csrimp;
GRANT SELECT, INSERT, UPDATE ON csr.degreeday_region TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.degreeday_account (account_name, account_key, security_key)
VALUES ('test', 'test-test-test', 'test-test-test-test-test-test-test-test-test-test-test-test-test');

INSERT INTO csr.degreeday_account (account_name, account_key, security_key)
VALUES ('default', 'fbfg-cssj-pgff', 'nspq-yg4a-c4qh-ck9n-nhnj-qx2c-jkc2-s48r-54hu-6fsj-q6mn-zzpw-ndhv');

-- Merge Risk!
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
VALUES (74, 'Properties - Degree Days.net ', 'EnableDegreeDays', 'Enables integration with Degree Days.net (<a href="http://emu.helpdocsonline.com/degreedays">setup instructions</a>).', 1);

-- ** New package grants **
@../degreedays_pkg
grant execute on csr.degreedays_pkg to web_user;

-- *** Conditional Packages ***

-- *** Packages ***
@../csrimp/imp_pkg
@../enable_pkg
@../schema_pkg

@../csrimp/imp_body
@../csr_app_body
@../enable_body
@../degreedays_body
@../schema_body

@update_tail
