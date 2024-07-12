-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=26
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.mgt_company_tree_sync_job (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	tree_root_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_mgt_company_tree_sync_job PRIMARY KEY (app_sid, tree_root_sid),
	CONSTRAINT fk_mctsj_region FOREIGN KEY (app_sid, tree_root_sid) REFERENCES csr.region (app_sid, region_sid)
);

CREATE TABLE csrimp.mgt_company_tree_sync_job (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	tree_root_sid					NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_mgt_company_tree_sync_job PRIMARY KEY (csrimp_session_id, tree_root_sid),
	CONSTRAINT fk_mctsj_session FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.mgt_company_tree_sync_job TO web_user;
GRANT SELECT, INSERT, UPDATE ON csr.mgt_company_tree_sync_job TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	FOR r IN (SELECT *
			    FROM dba_scheduler_jobs 
			   WHERE owner = 'CSR' 
				 AND job_name = 'TRIGGERREGIONTREESYNCJOBS')
	LOOP
		DBMS_SCHEDULER.DROP_JOB(
			job_name             => 'csr.TriggerRegionTreeSyncJobs'
		);
	END LOOP;

    DBMS_SCHEDULER.CREATE_JOB(
       job_name             => 'csr.TriggerRegionTreeSyncJobs',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'region_tree_pkg.TriggerRegionTreeSyncJobs;',
       job_class            => 'low_priority_job',
       start_date           => TO_DATE('2016-05-24 02:00:00','yyyy-mm-dd hh24:mi:ss'),
       repeat_interval      => 'FREQ=DAILY;BYHOUR=2',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Synchronise secondary trees'
    );
END;
/

-- Merge risk!
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (72, 'Management company secondary tree', 'EnableManagementCompanyTree', 'Enables the management company secondary tree.');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../region_tree_pkg
@../enable_pkg
@../schema_pkg

@../region_tree_body
@../enable_body
@../csr_app_body
@../schema_body
@../csrimp/imp_body

@update_tail
