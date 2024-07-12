-- Please update version.sql too -- this keeps clean builds in sync
define version=2889
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- CSR
CREATE SEQUENCE csr.benchmark_dashb_char_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	NOCACHE
	NOORDER
;

CREATE TABLE csr.benchmark_dashboard_char (
	app_sid							NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10) 		NOT NULL,
	benchmark_dashboard_char_id		NUMBER(10) 		NOT NULL,
	pos								NUMBER(10) 		NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT PK_BENCHMARK_DAS_CHAR PRIMARY KEY (app_sid, benchmark_dashboard_char_id),
	CONSTRAINT FK_BENCHMARK_DAS_REGION_METRIC FOREIGN KEY (app_sid, ind_sid) REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT FK_BENCHMARK_DAS_TAG_GRP FOREIGN KEY (app_sid, tag_group_id) REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT UK_BENCHMARK_DAS_IND_TAG_GRP UNIQUE (app_sid, benchmark_dashboard_sid, ind_sid, tag_group_id),
	CONSTRAINT CHK_BENCHMARK_DAS_IND_TAG_GRP CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

-- indexes
CREATE INDEX csr.IX_BENCHMARK_DAS_CHAR_IND_SID ON csr.benchmark_dashboard_char (app_sid, benchmark_dashboard_sid);
-- FK indexes
CREATE INDEX csr.IX_BENCHMARK_DAS_IND_SID ON csr.benchmark_dashboard_char (app_sid, ind_sid);
CREATE INDEX csr.IX_BENCHMARK_DAS_TAG_GROUP_ID ON csr.benchmark_dashboard_char (app_sid, tag_group_id);

-- translate year_built_ind_sid to a characteristic
DECLARE
BEGIN
	FOR r IN (
		SELECT app_sid, benchmark_dashboard_sid, year_built_ind_sid
		  FROM csr.benchmark_dashboard
		 WHERE year_built_ind_sid IS NOT NULL
	)
	LOOP
		INSERT INTO csr.benchmark_dashboard_char (app_sid, benchmark_dashboard_sid, benchmark_dashboard_char_id, pos, ind_sid)
			 VALUES (r.app_sid, r.benchmark_dashboard_sid, csr.benchmark_dashb_char_id_seq.NEXTVAL, 1, r.year_built_ind_sid);
	END LOOP;
END;
/

-- drop year_built_ind_sid
ALTER TABLE csr.benchmark_dashboard DROP CONSTRAINT FK_BENCH_DASH_YEAR_BUILT_IND;
ALTER TABLE csr.benchmark_dashboard DROP COLUMN year_built_ind_sid;

-- CSRIMP
CREATE TABLE csrimp.benchmark_dashboard (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	name							VARCHAR2(255)	NOT NULL,
	start_dtm						DATE 			NOT NULL,
	end_dtm							DATE,
	lookup_key						VARCHAR2(255),
	period_set_id					NUMBER(10)		NOT NULL,
	period_interval_id				NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_char (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	benchmark_dashboard_char_id		NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT PK_BENCHMARK_DASHB_CHAR PRIMARY KEY (csrimp_session_id, benchmark_dashboard_char_id),
	CONSTRAINT UK_BENCHMARK_DASHB_IND_TG_GRP UNIQUE (csrimp_session_id, benchmark_dashboard_sid, ind_sid, tag_group_id),
	CONSTRAINT CHK_BENCHMARK_DASHB_IND_TG_GRP CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_CHAR_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_ind (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10)		NOT NULL,
	display_name					VARCHAR2(255),
	scenario_run_sid				NUMBER(10),
	floor_area_ind_sid				NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_IND PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid, ind_sid),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_IND_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.benchmark_dashboard_plugin (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	benchmark_dashboard_sid			NUMBER(10)		NOT NULL,
	plugin_id						NUMBER(10)		NOT NULL,
	CONSTRAINT PK_BENCHMARK_DASHBOARD_PLUGIN PRIMARY KEY (csrimp_session_id, benchmark_dashboard_sid, plugin_id),
	CONSTRAINT FK_BENCHMARK_DASHBOARD_PLG_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	name							VARCHAR2(255)	NOT NULL,
	start_dtm						DATE 			NOT NULL,
	end_dtm							DATE,
	lookup_key						VARCHAR2(255),
	period_set_id					NUMBER(10)		NOT NULL,
	period_interval_id				NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD PRIMARY KEY (csrimp_session_id, metric_dashboard_sid),
	CONSTRAINT FK_METRIC_DASHBOARD_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard_ind (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	ind_sid							NUMBER(10)		NOT NULL,
	pos								NUMBER(10)		NOT NULL,
	block_title						VARCHAR2(32)	NOT NULL,
	block_css_class					VARCHAR2(32)	NOT NULL,
	inten_view_scenario_run_sid		NUMBER(10)		NOT NULL,
	inten_view_floor_area_ind_sid	NUMBER(10),
	absol_view_scenario_run_sid		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD_IND PRIMARY KEY (csrimp_session_id, metric_dashboard_sid, ind_sid),
	CONSTRAINT FK_METRIC_DASHBOARD_IND_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.metric_dashboard_plugin (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	metric_dashboard_sid			NUMBER(10)		NOT NULL,
	plugin_id						NUMBER(10)		NOT NULL,
	CONSTRAINT PK_METRIC_DASHBOARD_PLUGIN PRIMARY KEY (csrimp_session_id, metric_dashboard_sid, plugin_id),
	CONSTRAINT FK_METRIC_DASHBOARD_PLUGIN_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- CSRIMP MAP
CREATE TABLE csrimp.map_benchmark_dashboard_char (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	new_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_MAP_BENCHMARK_DAS_CHAR PRIMARY KEY (csrimp_session_id, old_benchmark_das_char_id) USING INDEX,
	CONSTRAINT UK_MAP_BENCHMARK_DAS_CHAR UNIQUE (csrimp_session_id, new_benchmark_das_char_id) USING INDEX,
	CONSTRAINT FK_MAP_BENCHMARK_DAS_CHAR_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_char TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_ind TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.benchmark_dashboard_plugin TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard_ind TO web_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.metric_dashboard_plugin TO web_user;

GRANT INSERT ON csr.benchmark_dashboard TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_char TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_ind TO csrimp;
GRANT INSERT ON csr.benchmark_dashboard_plugin TO csrimp;
GRANT INSERT ON csr.metric_dashboard TO csrimp;
GRANT INSERT ON csr.metric_dashboard_ind TO csrimp;
GRANT INSERT ON csr.metric_dashboard_plugin TO csrimp;

GRANT SELECT ON csr.benchmark_dashb_char_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (64, 'Property dashboards', 'EnablePropertyDashboards', 'Enables the Property Benchmarking and Performance dashboards');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

UPDATE csr.benchmark_dashboard SET name = 'Benchmarking' WHERE lookup_key = 'DEFAULT_BENCHMARKING_DASHBOARD';
UPDATE csr.metric_dashboard SET name = 'Performance' WHERE lookup_key = 'DEFAULT_METRIC_DASHBOARD';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\benchmarking_dashboard_pkg
@..\property_pkg
@..\enable_pkg
@..\csrimp\imp_pkg
@..\schema_pkg

@..\benchmarking_dashboard_body
@..\property_body
@..\enable_body
@..\csrimp\imp_body
@..\schema_body
@..\indicator_body
@..\tag_body

@update_tail
