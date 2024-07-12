-- Please update version.sql too -- this keeps clean builds in sync
define version=3200
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE csr.scndry_region_tree_log_id_seq;

CREATE TABLE CSR.SECONDARY_REGION_TREE_LOG
(
	APP_SID 			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	LOG_ID				NUMBER(10,0) NOT NULL,
	REGION_SID			NUMBER(10, 0) NOT NULL,
	USER_SID			NUMBER(10, 0) NOT NULL,
	LOG_DTM				DATE NOT NULL,
	PRESYNC_TREE		BLOB,
	POSTSYNC_TREE		BLOB,
	CONSTRAINT PK_SCNDRY_REGION_TREE_LOG PRIMARY KEY (APP_SID, LOG_ID, REGION_SID)
);

CREATE TABLE CSRIMP.SECONDARY_REGION_TREE_LOG
(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	LOG_ID				NUMBER(10,0) NOT NULL,
	REGION_SID			NUMBER(10, 0) NOT NULL,
	USER_SID			NUMBER(10, 0) NOT NULL,
	LOG_DTM				DATE NOT NULL,
	PRESYNC_TREE		BLOB,
	POSTSYNC_TREE		BLOB,
	CONSTRAINT PK_SCNDRY_REGION_TREE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, LOG_ID, REGION_SID)
);

-- Alter tables

ALTER TABLE csr.secondary_region_tree_ctrl DROP CONSTRAINT pk_secondary_region_tree_log;
ALTER TABLE csr.secondary_region_tree_ctrl ADD CONSTRAINT pk_secondary_region_tree_ctrl
	PRIMARY KEY (app_sid, region_sid)
;

ALTER TABLE csrimp.secondary_region_tree_ctrl DROP CONSTRAINT pk_secondary_region_tree_log;
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD CONSTRAINT pk_secondary_region_tree_ctrl
	PRIMARY KEY (csrimp_session_id, region_sid)
;



ALTER TABLE csr.secondary_region_tree_log ADD CONSTRAINT fk_scndry_rgn_tree_log_region
	FOREIGN KEY (app_sid, region_sid)
	REFERENCES csr.region(app_sid, region_sid)
;
ALTER TABLE csr.secondary_region_tree_log ADD CONSTRAINT fk_scndry_rgn_tree_log_user
	FOREIGN KEY (app_sid, user_sid)
	REFERENCES csr.csr_user (app_sid, csr_user_sid)
;

ALTER TABLE csr.secondary_region_tree_ctrl ADD active_only NUMBER(1) DEFAULT NULL;
ALTER TABLE csr.secondary_region_tree_ctrl ADD CONSTRAINT ck_srt_active_only CHECK (active_only IN (1,0));

ALTER TABLE csrimp.secondary_region_tree_ctrl ADD active_only NUMBER(1);
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD CONSTRAINT ck_srt_active_only CHECK (active_only IN (1,0));

ALTER TABLE csr.secondary_region_tree_ctrl ADD ignore_sids CLOB DEFAULT NULL;
ALTER TABLE csrimp.secondary_region_tree_ctrl ADD ignore_sids CLOB DEFAULT NULL;


create index csr.ix_scndry_reg_log_user_sid on csr.secondary_region_tree_log (app_sid, user_sid);
create index csr.ix_scndry_reg_log_region_sid on csr.secondary_region_tree_log (app_sid, region_sid);

-- *** Grants ***

GRANT INSERT ON csr.secondary_region_tree_log TO csrimp;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.secondary_region_tree_log TO tool_user;



CREATE TABLE CSR.BATCH_JOB_SRT_REFRESH
(
	APP_SID 			NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BATCH_JOB_ID		NUMBER(10,0)	NOT NULL,
	REGION_SID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_BATCH_JOB_SRT_REFRESH PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp, timeout_mins)
	VALUES (84, 'Secondary Region Tree Refresh', null, 'secondary-region-tree-refresh', 0, null, 120);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../schema_pkg
@../region_tree_pkg

@../csrimp/imp_body

@../csr_app_body
@../schema_body

@../enable_body
@../region_tree_body

@update_tail
