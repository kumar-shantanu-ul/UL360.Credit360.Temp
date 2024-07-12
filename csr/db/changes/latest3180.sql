define version=3180
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE CSR.METER_PROCESSING_JOB (
	APP_SID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	CONTAINER_ID		VARCHAR2(256)	NOT NULL,
	JOB_ID				VARCHAR2(256)	NOT NULL,
	JOB_DTM				DATE			DEFAULT SYSDATE NOT NULL,
	FETCH_COUNT			NUMBER(10)		DEFAULT 0 NOT NULL,
	EXPIRED_COUNT		NUMBER(10)		DEFAULT 0 NOT NULL,
	LAST_FETCH_DTM		DATE			NULL,
	HIDE_UNTIL			DATE			NULL,
	LOCAL_STATUS		VARCHAR2(256)	NOT NULL,
	LOCAL_RESULT_PATH	VARCHAR2(2048)	NULL,
	REMOTE_STATUS		VARCHAR2(256)	NULL,
	UPLOAD_URI			VARCHAR2(2048)	NULL,
	RESULT_URI			VARCHAR2(2048)	NULL,
	REMOTE_RESULT_PATH	VARCHAR2(2048)	NULL,
	CONSTRAINT PK_METER_PROCESSING_JOB PRIMARY KEY (APP_SID, CONTAINER_ID, JOB_ID),
	CONSTRAINT FK_CUSTOMER_METER_PROC_JOB
		FOREIGN KEY (APP_SID)
		REFERENCES CSR.CUSTOMER (APP_SID)
);
CREATE INDEX CSR.IX_CUSTOMER_METER_PROC_JOB ON CSR.METER_PROCESSING_JOB (APP_SID);
CREATE OR REPLACE DIRECTORY DIR_SCRIPTS AS '/meterdata';
CREATE OR REPLACE DIRECTORY DIR_EXT_METER_DATA AS '/meterdata';
CREATE TABLE CSR.EXT_METER_DATA (
	CONTAINER_ID	VARCHAR2(1024),
	JOB_ID			VARCHAR2(1024),
	SERIAL_ID		VARCHAR2(1024),
	BUCKET_NAME		VARCHAR2(256),
	START_DTM		DATE,
	VAL				NUMBER(24, 10)
)
ORGANIZATION EXTERNAL 
(
	TYPE ORACLE_LOADER 
	DEFAULT DIRECTORY DIR_EXT_METER_DATA 
	ACCESS PARAMETERS 
	( 
		RECORDS DELIMITED BY NEWLINE
		PREPROCESSOR DIR_SCRIPTS:'concatAllFiles.sh'
		FIELDS TERMINATED BY ','
		OPTIONALLY ENCLOSED BY '"'
		MISSING FIELD VALUES ARE NULL 
		(
			CONTAINER_ID,
			JOB_ID,
			SERIAL_ID,
			BUCKET_NAME,
			START_DTM DATE 'YYYY-MM-DD HH24:MI:SS',
			VAL
		) 
	)
	LOCATION('path.txt') 
)
REJECT LIMIT UNLIMITED;


ALTER TABLE CSR.METERING_OPTIONS ADD (
	PROC_USE_SERVICE		NUMBER(1)		DEFAULT 0 NOT NULL,
	PROC_API_BASE_URI		VARCHAR2(1024),
	PROC_LOCAL_PATH			VARCHAR2(1024),
	PROC_KICK_TIMEOUT		NUMBER(10),
	CONSTRAINT CK_PROC_USE_SERVICE CHECK (PROC_USE_SERVICE IN (0, 1)),
	CONSTRAINT CK_PROC_OPRIONS_IN_USE CHECK (
		PROC_USE_SERVICE = 0 OR (
			PROC_API_BASE_URI IS NOT NULL AND 
			PROC_LOCAL_PATH IS NOT NULL AND 
			PROC_KICK_TIMEOUT IS NOT NULL
		)
	)
);
ALTER TABLE CSRIMP.METERING_OPTIONS ADD (
	PROC_USE_SERVICE		NUMBER(1)		NOT NULL,
	PROC_API_BASE_URI		VARCHAR2(1024),
	PROC_LOCAL_PATH			VARCHAR2(1024),
	PROC_KICK_TIMEOUT		NUMBER(10),
	CONSTRAINT CK_PROC_USE_SERVICE CHECK (PROC_USE_SERVICE IN (0, 1)),
	CONSTRAINT CK_PROC_OPRIONS_IN_USE CHECK (
		PROC_USE_SERVICE = 0 OR (
			PROC_API_BASE_URI IS NOT NULL AND 
			PROC_LOCAL_PATH IS NOT NULL AND 
			PROC_KICK_TIMEOUT IS NOT NULL
		)
	)
);
DECLARE
	does_not_exist EXCEPTION;
	PRAGMA EXCEPTION_INIT(does_not_exist, -4043);
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE CSR.T_COMPLIANCE_RLLVL_RT_TABLE';
	EXCEPTION WHEN does_not_exist THEN
		NULL;
	END;
	BEGIN
		EXECUTE IMMEDIATE 'DROP TYPE CSR.T_COMPLIANCE_ROLLOUTLVL_RT';
	EXCEPTION WHEN does_not_exist THEN
		NULL;
	END;
END;
/


GRANT READ, EXECUTE ON DIRECTORY DIR_SCRIPTS TO csr;
GRANT READ, EXECUTE ON DIRECTORY DIR_SCRIPTS TO web_user;
GRANT READ, WRITE ON DIRECTORY DIR_EXT_METER_DATA TO csr;
GRANT READ, WRITE ON DIRECTORY DIR_EXT_METER_DATA TO web_user;




CREATE OR REPLACE VIEW csr.v$comp_item_rollout_location AS
	SELECT cir.app_sid, cir.compliance_item_id,
			listagg(pc.name, ', ') within GROUP(ORDER BY pc.name) AS countries,
			listagg(pr.name, ', ') within GROUP(order by pr.name) AS regions,
			listagg(rg.group_name, ', ') within GROUP(ORDER BY region_group_id) AS region_group_names,
			listagg(cg.group_name, ', ') within GROUP(ORDER BY country_group_id) AS country_group_names
	  FROM csr.compliance_item_rollout cir
	  LEFT JOIN postcode.country pc ON cir.country = pc.country
	  LEFT JOIN postcode.region pr ON cir.country = pr.country AND cir.region = pr.region
	  LEFT JOIN csr.region_group rg ON cir.region_group = rg.region_group_id
	  LEFT JOIN csr.country_group cg ON cir.country_group = cg.country_group_id
	 GROUP BY cir.app_sid, cir.compliance_item_id
;




BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.EXPIRE_REMOTE_JOBS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'csr.customer_pkg.ExpireJobs;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz('2018/01/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MINUTELY;INTERVAL=10',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Roll-back or expire meter processing jobs that are no longer locked but in a status that means they were processing'
	);
END;
/
BEGIN
	INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
		VALUES(1003 /* csr_data_pkg.FLOW_CAP_CAMPAIGN_ACTIONS */, 'campaign', 'Survey actions', 0 /*Specific*/, 1 /*security_pkg.PERMISSION_READ*/);
END;
/




CREATE OR REPLACE PACKAGE csr.workflow_api_pkg AS
	PROCEDURE dummy;
END;
/
GRANT EXECUTE ON csr.workflow_api_pkg TO web_user;
CREATE OR REPLACE PACKAGE csr.meter_processing_job_pkg
IS
BEGIN
END;
/
GRANT execute ON csr.meter_processing_job_pkg TO web_user;


@..\workflow_api_pkg
@..\unit_test_pkg
@..\tests\test_user_cover_pkg
@..\region_api_pkg
@..\indicator_api_pkg
@..\meter_processing_job_pkg
@..\meter_pkg
@..\measure_api_pkg
@..\deleg_plan_pkg
@..\compliance_pkg
@..\chain\company_pkg
@..\chain\business_relationship_pkg
@..\csr_data_pkg


@..\workflow_api_body
@..\unit_test_body
@..\enable_body
@..\csr_app_body
@..\delegation_body
@..\..\..\aspen2\cms\db\tab_body
@..\region_api_body
@..\indicator_api_body
@..\meter_processing_job_body
@..\meter_body
@..\schema_body
@..\csrimp\imp_body
@..\chain\business_relationship_body
@..\chain\company_score_body
@..\measure_api_body
@..\chain\company_filter_body
@..\factor_body
@..\chain\bsci_2009_audit_report_body
@..\chain\bsci_2014_audit_report_body
@..\deleg_plan_body
@..\compliance_body
@..\chain\company_body



@update_tail
