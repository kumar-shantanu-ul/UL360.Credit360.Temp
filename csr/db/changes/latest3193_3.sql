-- Please update version.sql too -- this keeps clean builds in sync
define version=3193
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CSR.SSP_ID_SEQ;

CREATE SEQUENCE CSR.SSPL_ID_SEQ;

CREATE TABLE CSR.SCHEDULED_STORED_PROC_LOG (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	SSP_LOG_ID						NUMBER(10, 0)	NOT NULL,
	SSP_ID							NUMBER(10, 0)	NOT NULL,
	RUN_DTM							TIMESTAMP,
	RESULT_CODE						NUMBER(10, 0),
	RESULT_MSG						VARCHAR2(1024),
	RESULT_EX						CLOB,
	ONE_OFF							NUMBER(1, 0),
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	CONSTRAINT PK_SSPL PRIMARY KEY (APP_SID, SSP_LOG_ID)
);

-- Alter tables

ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD (
	SSP_ID							NUMBER(10, 0),
	ARGS							VARCHAR2(1024),
	ONE_OFF							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	LAST_SSP_LOG_ID					NUMBER(10, 0),
	ENABLED							NUMBER(1, 0) DEFAULT 0 NOT NULL,
	SCHEDULE_RUN_DTM				TIMESTAMP
);

UPDATE CSR.SCHEDULED_STORED_PROC SET SSP_ID = CSR.SSP_ID_SEQ.NEXTVAL, ENABLED = 1, SCHEDULE_RUN_DTM = NEXT_RUN_DTM;

INSERT INTO CSR.SCHEDULED_STORED_PROC_LOG
(APP_SID, SSP_LOG_ID, SSP_ID, RUN_DTM, RESULT_CODE, RESULT_MSG, RESULT_EX, ONE_OFF, ONE_OFF_USER)
SELECT APP_SID, CSR.SSPL_ID_SEQ.NEXTVAL, SSP_ID, LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX, 0, NULL
  FROM CSR.SCHEDULED_STORED_PROC;

ALTER TABLE CSR.SCHEDULED_STORED_PROC DROP (LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX);

ALTER TABLE CSR.SCHEDULED_STORED_PROC DROP CONSTRAINT PK_SSP;
ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD CONSTRAINT PK_SSP PRIMARY KEY (APP_SID, SSP_ID);
CREATE UNIQUE INDEX CSR.UK_SSP ON CSR.SCHEDULED_STORED_PROC(APP_SID, SP,  NVL(ARGS, ' '));

ALTER TABLE CSR.SCHEDULED_STORED_PROC_LOG ADD CONSTRAINT FK_SSPL_SSP
	FOREIGN KEY (APP_SID, SSP_ID)
	REFERENCES CSR.SCHEDULED_STORED_PROC(APP_SID, SSP_ID)
;

CREATE INDEX CSR.IX_SSPL_SSP ON CSR.SCHEDULED_STORED_PROC_LOG(APP_SID, SSP_ID);

ALTER TABLE CSR.SCHEDULED_STORED_PROC ADD CONSTRAINT FK_SSP_SSPL
	FOREIGN KEY (APP_SID, LAST_SSP_LOG_ID)
	REFERENCES CSR.SCHEDULED_STORED_PROC_LOG(APP_SID, SSP_LOG_ID)
;

CREATE INDEX CSR.IX_SSP_SSPL ON CSR.SCHEDULED_STORED_PROC(APP_SID, LAST_SSP_LOG_ID);

ALTER TABLE CSRIMP.SCHEDULED_STORED_PROC ADD (
	SSP_ID							NUMBER(10, 0),
	ONE_OFF							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	ONE_OFF_USER					NUMBER(10, 0),
	ONE_OFF_DATE					TIMESTAMP,
	LAST_SSP_LOG_ID					NUMBER(10, 0),
	ENABLED							NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	SCHEDULE_RUN_DTM				TIMESTAMP
);

ALTER TABLE CSRIMP.SCHEDULED_STORED_PROC DROP (LAST_RUN_DTM, LAST_RESULT, LAST_RESULT_MSG, LAST_RESULT_EX);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Rerun Scheduled Scripts (SSPs)', 0, 'Allow user to rerun scheduled database scripts (SSPs)');
INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Disable Scheduled Scripts (SSPs)', 0, 'Allow user to enable and disable scheduled database scripts (SSPs)');

DECLARE
	PROCEDURE EnableCapability(
		in_capability  					IN	security.security_pkg.T_SO_NAME,
		in_swallow_dup_exception    	IN  NUMBER DEFAULT 1
	)
	AS
		v_allow_by_default      csr.capability.allow_by_default%TYPE;
		v_capability_sid		security.security_pkg.T_SID_ID;
		v_capabilities_sid		security.security_pkg.T_SID_ID;
	BEGIN
		-- this also serves to check that the capability is valid
		BEGIN
			SELECT allow_by_default
			  INTO v_allow_by_default
			  FROM csr.capability
			 WHERE LOWER(name) = LOWER(in_capability);
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				RAISE_APPLICATION_ERROR(-20001, 'Unknown capability "'||in_capability||'"');
		END;

		-- just create a sec obj of the right type in the right place
		BEGIN
			v_capabilities_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), '/Capabilities');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
					SYS_CONTEXT('SECURITY','APP'), 
					security.security_pkg.SO_CONTAINER,
					'Capabilities',
					v_capabilities_sid
				);
		END;
		
		BEGIN
			security.securableobject_pkg.CreateSO(SYS_CONTEXT('SECURITY','ACT'), 
				v_capabilities_sid, 
				security.class_pkg.GetClassId('CSRCapability'),
				in_capability,
				v_capability_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				IF in_swallow_dup_exception = 0 THEN
					RAISE_APPLICATION_ERROR(security.security_pkg.ERR_DUPLICATE_OBJECT_NAME, SQLERRM);
				END IF;
		END;
	END;
BEGIN
	security.user_pkg.logonAdmin();

	FOR r IN (
		SELECT DISTINCT host
		  FROM csr.scheduled_stored_proc ssp
		  JOIN csr.customer c ON ssp.app_sid = c.app_sid
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		
		EnableCapability('Rerun Scheduled Scripts (SSPs)');
		EnableCapability('Disable Scheduled Scripts (SSPs)');
		
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../ssp_pkg

@../csr_app_body
@../ssp_body
@../schema_body
@../csrimp/imp_body


@update_tail
