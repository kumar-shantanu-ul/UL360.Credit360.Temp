-- Please update version.sql too -- this keeps clean builds in sync
define version=2886
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables
CREATE SEQUENCE csr.r_report_type_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;

CREATE TABLE csr.r_report_type (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	R_REPORT_TYPE_ID				NUMBER(10, 0) NOT NULL,
	LABEL							VARCHAR2(100) NOT NULL,
	PLUGIN_TYPE_ID					NUMBER(10, 0) NOT NULL,
	PLUGIN_ID						NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_r_report_type PRIMARY KEY (app_sid, r_report_type_id),
	CONSTRAINT uk_r_report_type_label UNIQUE (app_sid, label),
	CONSTRAINT fk_r_report_type_plugin FOREIGN KEY (plugin_type_id, plugin_id) REFERENCES csr.plugin (plugin_type_id, plugin_id),
	CONSTRAINT ck_r_report_type_plugin CHECK (plugin_type_id = 15)
);

CREATE TABLE csr.r_report_job (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_ID					NUMBER(10, 0) NOT NULL,
	R_REPORT_TYPE_ID				NUMBER(10, 0) NOT NULL,
	JS_DATA							CLOB,
	CONSTRAINT pk_r_report_job PRIMARY KEY (app_sid, batch_job_id),
	CONSTRAINT fk_r_report_job_report_type FOREIGN KEY (app_sid, r_report_type_id) REFERENCES csr.r_report_type (app_sid, r_report_type_id)
);

CREATE TABLE csr.r_report (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	R_REPORT_SID					NUMBER(10, 0) NOT NULL,
	R_REPORT_TYPE_ID				NUMBER(10, 0) NOT NULL,
	JS_DATA							CLOB,
	REQUESTED_BY_USER_SID			NUMBER(10, 0) NOT NULL,
	PREPARED_DTM					DATE NOT NULL,
	CONSTRAINT pk_r_report PRIMARY KEY (app_sid, r_report_sid),
	CONSTRAINT fk_r_report_report_type FOREIGN KEY (app_sid, r_report_type_id) REFERENCES csr.r_report_type (app_sid, r_report_type_id),
	CONSTRAINT fk_r_report_user FOREIGN KEY (app_sid, requested_by_user_sid) REFERENCES csr.csr_user (app_sid, csr_user_sid)
);

CREATE SEQUENCE csr.r_report_file_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;

CREATE TABLE csr.r_report_file (
	APP_SID							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	R_REPORT_FILE_ID				NUMBER(10, 0) NOT NULL,
	R_REPORT_SID					NUMBER(10, 0) NOT NULL,
	SHOW_AS_TAB						NUMBER(1) DEFAULT 0 NOT NULL,
	SHOW_AS_DOWNLOAD				NUMBER(1) DEFAULT 0 NOT NULL,
	TITLE							VARCHAR2(255) NOT NULL,
	FILENAME						VARCHAR2(255) NOT NULL,
	MIME_TYPE						VARCHAR2(255) NOT NULL,
	DATA							BLOB NOT NULL,
	CONSTRAINT pk_r_report_file PRIMARY KEY (app_sid, r_report_file_id),
	CONSTRAINT fk_r_report_file_report FOREIGN KEY (app_sid, r_report_sid) REFERENCES csr.r_report (app_sid, r_report_sid),
	CONSTRAINT ck_r_report_file_tab CHECK (show_as_tab IN (0, 1)),
	CONSTRAINT ck_r_report_file_dl CHECK (show_as_download IN (0, 1)),
	CONSTRAINT ck_r_report_file_visible CHECK (show_as_tab = 1 OR show_as_download = 1)
);

CREATE TABLE CSRIMP.R_REPORT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	R_REPORT_TYPE_ID NUMBER(10,0) NOT NULL,
	LABEL VARCHAR2(100) NOT NULL,
	PLUGIN_ID NUMBER(10,0) NOT NULL,
	PLUGIN_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_R_REPORT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, R_REPORT_TYPE_ID),
	CONSTRAINT FK_R_REPORT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.R_REPORT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	R_REPORT_SID NUMBER(10,0) NOT NULL,
	JS_DATA CLOB,
	PREPARED_DTM DATE NOT NULL,
	REQUESTED_BY_USER_SID NUMBER(10,0) NOT NULL,
	R_REPORT_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_R_REPORT PRIMARY KEY (CSRIMP_SESSION_ID, R_REPORT_SID),
	CONSTRAINT FK_R_REPORT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.R_REPORT_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	R_REPORT_FILE_ID NUMBER(10,0) NOT NULL,
	DATA BLOB NOT NULL,
	FILENAME VARCHAR2(255) NOT NULL,
	MIME_TYPE VARCHAR2(255) NOT NULL,
	R_REPORT_SID NUMBER(10,0) NOT NULL,
	SHOW_AS_DOWNLOAD NUMBER(1,0) NOT NULL,
	SHOW_AS_TAB NUMBER(1,0) NOT NULL,
	TITLE VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_R_REPORT_FILE PRIMARY KEY (CSRIMP_SESSION_ID, R_REPORT_FILE_ID),
	CONSTRAINT FK_R_REPORT_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_R_REPORT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_R_REPORT_TYPE_ID NUMBER(10) NOT NULL,
	NEW_R_REPORT_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_R_REPORT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_R_REPORT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_R_REPORT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_R_REPORT_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_R_REPORT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_R_REPORT_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_R_REPORT_FILE_ID NUMBER(10) NOT NULL,
	NEW_R_REPORT_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_R_REPORT_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_R_REPORT_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_R_REPORT_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_R_REPORT_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_R_REPORT_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE csr.plugin ADD (
	R_SCRIPT_PATH					VARCHAR2(1024)
);

DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid, result_mode, portal_sid, r_script_path);

-- *** Grants ***
grant select, insert, update, delete on csrimp.r_report_type to web_user;
grant select, insert, update, delete on csrimp.r_report to web_user;
grant select, insert, update, delete on csrimp.r_report_file to web_user;
grant select, insert, update on csr.r_report_type to csrimp;
grant select, insert, update on csr.r_report to csrimp;
grant select, insert, update on csr.r_report_file to csrimp;
grant select on csr.r_report_type_id_seq to csrimp;
grant select on csr.r_report_file_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
    v_class_id    NUMBER(10);
BEGIN   
    security.user_pkg.logonadmin;
    security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRRReport', 'csr.r_report_pkg', null, v_class_id);
EXCEPTION
    WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
END;
/

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
		 VALUES (9999, 'R Reports', 'EnableRReports', 'Enables R reports');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
	INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (15, 'R Report');

	INSERT INTO csr.plugin (plugin_type_id, plugin_id, description,
							js_include, js_class, cs_class, r_script_path)
	VALUES (15, csr.plugin_id_seq.NEXTVAL, 'Validation report',
			'/csr/site/rreports/reports/Validation.js', 'Credit360.RReports.Validation',
			'Credit360.RReports.Runners.ValidationReportRunner', '/csr/rreports/validation_V5/validation_V5.R');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

BEGIN
    INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, one_at_a_time)
         VALUES (22, 'R Reports', 'r-reports', 1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/

-- ** New package grants **
CREATE OR REPLACE PACKAGE csr.r_report_pkg AS END;
/

grant execute on csr.r_report_pkg to web_user;
grant execute on csr.r_report_pkg to security;

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../calc_pkg
@../csr_data_pkg
@../enable_pkg
@../indicator_pkg
@../region_pkg
@../plugin_pkg
@../r_report_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../calc_body
@../csr_app_body
@../csr_user_body
@../enable_body
@../indicator_body
@../region_body
@../plugin_body
@../r_report_body
@../schema_body
@../csrimp/imp_body

@update_tail
