define version=3381
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

CREATE OR REPLACE TYPE CSR.T_USER AS 
	OBJECT (
	CSR_USER_SID				NUMBER(10),
	EMAIL						VARCHAR2(256),
	FULL_NAME					VARCHAR2(256),
	USER_NAME					VARCHAR2(256),
	FRIENDLY_NAME				VARCHAR2(255),
	JOB_TITLE					VARCHAR2(100),
	ACTIVE						NUMBER(1),
	USER_REF					VARCHAR2(255),
	LINE_MANAGER_SID			NUMBER(10)
);
/


DECLARE
	v_is_null		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_is_null
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'SCHEDULED_STORED_PROC'
	   AND column_name = 'SSP_ID'
	   AND nullable = 'Y';
	
	IF v_is_null = 1 THEN
		-- Correct PK.
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc DROP CONSTRAINT PK_SSP DROP INDEX');
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc MODIFY ssp_id NOT NULL');
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc ADD CONSTRAINT PK_SSP PRIMARY KEY (csrimp_session_id, ssp_id)');
	END IF;
END;
/
DECLARE
	v_is_null		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_is_null
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'SCHEDULED_STORED_PROC'
	   AND column_name = 'ARGS'
	   AND nullable = 'N';
	
	IF v_is_null = 1 THEN
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc MODIFY args NULL');
	END IF;
END;
/
DECLARE
	v_is_null		NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_is_null
	  FROM all_tab_columns
	 WHERE owner = 'CSRIMP'
	   AND table_name = 'SCHEDULED_STORED_PROC'
	   AND column_name = 'NEXT_RUN_DTM'
	   AND nullable = 'N';
	
	IF v_is_null = 1 THEN
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc MODIFY next_run_dtm NULL');
	END IF;
END;
/
ALTER TABLE csrimp.scheduled_stored_proc
ADD CONSTRAINT FK_SSP_IS FOREIGN KEY(csrimp_session_id)
REFERENCES csrimp.csrimp_session(csrimp_session_id) ON DELETE CASCADE;
CREATE TABLE CSRIMP.SCHEDULED_STORED_PROC_LOG (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SSP_LOG_ID				NUMBER(10)	NOT NULL,
	SSP_ID					NUMBER(10)	NOT NULL,
	RUN_DTM					TIMESTAMP,
	RESULT_CODE				NUMBER(10),
	RESULT_MSG				VARCHAR2(1024),
	RESULT_EX				CLOB,
	ONE_OFF					NUMBER(1),
	ONE_OFF_USER			NUMBER(10),
	ONE_OFF_DATE			TIMESTAMP,
	CONSTRAINT PK_SSPL PRIMARY KEY (CSRIMP_SESSION_ID, SSP_LOG_ID),
	CONSTRAINT FK_SSPL_IS FOREIGN KEY (CSRIMP_SESSION_ID)
	REFERENCES CSRIMP.CSRIMP_SESSION(CSRIMP_SESSION_ID) ON DELETE CASCADE
);


GRANT SELECT, INSERT, UPDATE ON csr.scheduled_stored_proc_log TO csrimp;
GRANT INSERT ON csrimp.scheduled_stored_proc_log TO tool_user;
GRANT SELECT ON csr.ssp_id_seq TO csrimp;
GRANT SELECT ON csr.sspl_id_seq TO csrimp;












CREATE OR REPLACE PACKAGE CSR.CORE_ACCESS_PKG
AS
PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY CSR.CORE_ACCESS_PKG
AS
PROCEDURE dummy
AS
BEGIN
	NULL;
END;
END;
/
GRANT EXECUTE ON CSR.CORE_ACCESS_PKG TO web_user;


@..\dataview_pkg
@..\tag_pkg
@..\region_pkg
@..\csr_user_pkg
@..\..\..\aspen2\cms\db\tab_pkg
@..\core_access_pkg
@..\schema_pkg
@..\chain\company_pkg


@..\dataview_body
@..\tag_body
@..\region_body
@..\csr_user_body
@..\..\..\aspen2\cms\db\tab_body
@..\core_access_body
@..\schema_body
@..\imp_body
@..\chain\company_body
@..\integration_question_answer_report_body



@update_tail
