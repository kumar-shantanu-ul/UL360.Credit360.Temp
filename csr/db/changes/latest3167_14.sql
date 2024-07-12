-- Please update version.sql too -- this keeps clean builds in sync
define version=3167
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSR.SCRAGPP_STATUS(
	APP_SID						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	OLD_SCRAG					NUMBER(1)	DEFAULT 1 NOT NULL,
	TESTCUBE_ENABLED			NUMBER(1)	DEFAULT 0 NOT NULL,
	VALIDATION_APPROVED_REF		VARCHAR2(1023),
	SCRAGPP_ENABLED				NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SCRAGPP_STATUS PRIMARY KEY (APP_SID),
	CONSTRAINT CHK_SCRAGPP_STATUS_OLD_SCRAG CHECK (OLD_SCRAG IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_TESTCUBE CHECK (TESTCUBE_ENABLED IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_SCRAGPP CHECK (SCRAGPP_ENABLED IN (0,1))
)
;
CREATE TABLE CSRIMP.SCRAGPP_STATUS(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCRAG					NUMBER(1)	DEFAULT 1 NOT NULL,
	TESTCUBE_ENABLED			NUMBER(1)	DEFAULT 0 NOT NULL,
	VALIDATION_APPROVED_REF		VARCHAR2(1023),
	SCRAGPP_ENABLED				NUMBER(1)	DEFAULT 0 NOT NULL,
	CONSTRAINT PK_SCRAGPP_STATUS PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_SCRAGPP_STATUS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE,
	CONSTRAINT CHK_SCRAGPP_STATUS_OLD_SCRAG CHECK (OLD_SCRAG IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_TESTCUBE CHECK (TESTCUBE_ENABLED IN (0,1)),
	CONSTRAINT CHK_SCRAGPP_STATUS_SCRAGPP CHECK (SCRAGPP_ENABLED IN (0,1))
)
;
CREATE TABLE CSR.SCRAGPP_AUDIT_LOG(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ACTION					VARCHAR2(1023)	NOT NULL,
	ACTION_DTM				DATE,
	USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCRAGPP_AUDIT_LOG PRIMARY KEY (APP_SID, ACTION, ACTION_DTM)
)
;
CREATE TABLE CSRIMP.SCRAGPP_AUDIT_LOG(
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ACTION					VARCHAR2(1023)	NOT NULL,
	ACTION_DTM				DATE,
	USER_SID				NUMBER(10, 0) NOT NULL,
	CONSTRAINT PK_SCRAGPP_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, ACTION, ACTION_DTM),
	CONSTRAINT FK_SCRAGPP_AUDIT_LOG FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
)
;

-- Alter tables

-- *** Grants ***
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.scragpp_status TO tool_user;
GRANT SELECT,INSERT,UPDATE,DELETE ON csrimp.scragpp_audit_log TO tool_user;
GRANT INSERT ON csr.scragpp_audit_log TO csrimp;
GRANT INSERT ON csr.scragpp_status TO csrimp;

CREATE OR REPLACE PACKAGE csr.scrag_pp_pkg
AS
PROCEDURE dummy;
END;
/

GRANT EXECUTE ON csr.scrag_pp_pkg TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.scragpp_status (app_sid, old_scrag, scragpp_enabled)
SELECT app_sid, 1, 0
  FROM csr.customer
 WHERE unmerged_scenario_run_sid IS NULL OR merged_scenario_run_sid IS NULL;

INSERT INTO csr.scragpp_status (app_sid, old_scrag, scragpp_enabled)
SELECT app_sid, 0, 1
  FROM csr.customer
 WHERE unmerged_scenario_run_sid IS NOT NULL AND merged_scenario_run_sid IS NOT NULL;

CREATE OR REPLACE FUNCTION csr.Temp_SecurableObjectExists(
	in_path IN VARCHAR2,
	in_parent_sid_id IN Security_Pkg.T_SID_ID
)
RETURN BOOLEAN
AS
v_securableObject_sid	security.security_pkg.T_SID_ID;
BEGIN
	v_securableObject_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), in_parent_sid_id, in_path);
	RETURN TRUE;
	EXCEPTION
		WHEN OTHERS THEN
			RETURN FALSE;
END;
/

DECLARE
	v_app_sid					security.security_pkg.T_SID_ID;
	v_scenarios_sid				security.security_pkg.T_SID_ID;
	v_test_scenario_exists		BOOLEAN;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN 
	(
	SELECT host 
	  FROM csr.customer
	)
	LOOP
	BEGIN
		security.user_pkg.logonadmin(r.host);
		v_app_sid := SYS_CONTEXT('SECURITY', 'APP');
		
		IF csr.Temp_SecurableObjectExists('Scenarios', v_app_sid) THEN
			v_scenarios_sid := security.securableObject_pkg.GetSidFromPath(SYS_CONTEXT('SECURITY', 'ACT'), v_app_sid, 'Scenarios');
			v_test_scenario_exists := csr.Temp_SecurableObjectExists('New calc engine scenario run', v_scenarios_sid);
			
			IF v_test_scenario_exists THEN
				UPDATE csr.scragpp_status
				   SET testcube_enabled = 1
				 WHERE app_sid = v_app_sid;
			END IF;
		END IF;
	END;
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/

DROP FUNCTION csr.Temp_SecurableObjectExists;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\scrag_pp_pkg
@..\scrag_pp_body

@update_tail
