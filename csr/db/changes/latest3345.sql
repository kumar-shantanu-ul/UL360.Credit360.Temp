define version=3345
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

CREATE TABLE CSR.MSAL_USER_TOKEN_CACHE (
	APP_SID						NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	LOGIN_HINT					VARCHAR2(500)		NOT NULL,
	CACHE_KEY					VARCHAR2(1024)		NOT NULL,
	TOKEN						BLOB				NOT NULL,
	CONSTRAINT PK_MSAL_USR_TKN_CACHE PRIMARY KEY (APP_SID, CACHE_KEY)
);
CREATE TABLE CSR.MSAL_USER_CONSENT_FLOW (
	ACT_ID						CHAR(36 BYTE)		NOT NULL,
	REDIRECT_URL				VARCHAR2(1024)		NOT NULL,
	PKCE						VARCHAR2(1024)		NOT NULL,
	CONSTRAINT UK_MSAL_USR_CF_ACT_RED UNIQUE (ACT_ID, REDIRECT_URL)
);


ALTER TABLE csr.module ADD (
	post_enable_class	VARCHAR2(1024)
);
ALTER TABLE CSR.CREDENTIAL_MANAGEMENT ADD (
	CACHE_KEY					VARCHAR2(1024)
);










BEGIN
	dbms_scheduler.create_job (
		job_name		=> 'CSR.UPDATE_METRIC_VALS',
		job_type		=> 'PLSQL_BLOCK',
		job_action		=> 'BEGIN security.user_pkg.logonadmin(); csr.region_metric_pkg.RefreshSystemValues; security.user_pkg.LogOff(security.security_pkg.GetAct); END;',
		job_class		=> 'low_priority_job',
		start_date		=> to_timestamp_tz(TO_CHAR(ADD_MONTHS(TRUNC(SYSDATE, 'MONTH'), 1), 'YYYY/MM/DD') || ' 02:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
		repeat_interval	=> 'FREQ=MONTHLY;INTERVAL=1;BYMONTHDAY=2;BYHOUR=02;BYMINUTE=00;BYSECOND=00',
		enabled			=> TRUE,
		auto_drop		=> FALSE,
		comments		=> 'Update end date of region metrics values'
	);
	
	dbms_scheduler.run_job(
		job_name			=> 'CSR.UPDATE_METRIC_VALS',
		use_current_session	=> false
	);
END;
/
UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableQuestionLibrary';
UPDATE csr.module SET enable_class = null, post_enable_class = 'Credit360.Enable.EnableFileSharing' WHERE enable_sp = 'EnableFileSharingApi';
UPDATE csr.std_measure_conversion
   SET std_measure_id = 8, A = 0.0283168466
 WHERE description LIKE 'kg/scf';
UPDATE csr.authentication_type
SET auth_type_name = 'Azure Active Directory (User based authentication)'
WHERE auth_type_id = 1;




CREATE OR REPLACE PACKAGE csr.msal_user_token_cache_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.msal_user_token_cache_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.msal_user_token_cache_pkg TO web_user;


@..\region_metric_pkg
@..\msal_user_token_cache_pkg
@..\credentials_pkg


@..\indicator_body
@..\region_metric_body
@..\campaigns\campaign_body
@..\enable_body
@..\msal_user_token_cache_body
@..\credentials_body
@..\dataview_body
@..\deleg_plan_body



@update_tail
