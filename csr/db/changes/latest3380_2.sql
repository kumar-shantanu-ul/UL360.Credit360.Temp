-- Please update version.sql too -- this keeps clean builds in sync
define version=3380
define minor_version=2
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'DELETE FROM csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	COMMIT;
END;
/

-- *** DDL ***
-- Create tables

-- Alter tables
-- Schema was correct but no latest script modifying columns or PK.
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
		EXECUTE IMMEDIATE('ALTER TABLE csrimp.scheduled_stored_proc DROP CONSTRAINT PK_SSP');
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

-- Fix fudged CSRIMP schema changes from latest3193_3.sql
-- Missing in schema. This has to happen after the above because of the FK.
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

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.scheduled_stored_proc_log TO csrimp;
GRANT INSERT ON csrimp.scheduled_stored_proc_log TO tool_user;
GRANT SELECT ON csr.ssp_id_seq TO csrimp;
GRANT SELECT ON csr.sspl_id_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\schema_pkg
@..\schema_body
@..\imp_body

@update_tail
