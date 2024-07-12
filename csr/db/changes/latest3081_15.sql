-- Please update version.sql too -- this keeps clean builds in sync
define version=3081
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE CSR.APPLICATION_PAUSE_ID_SEQ;

CREATE TABLE CSR.COMPL_PERMIT_APPLICATION_PAUSE (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	APPLICATION_PAUSE_ID	NUMBER(10, 0)	NOT NULL,
	PERMIT_APPLICATION_ID	NUMBER(10, 0)	NOT NULL,
	PAUSED_DTM				DATE			NOT NULL,
	RESUMED_DTM				DATE,
	CONSTRAINT PK_COMPL_PERMIT_APP_PAUSE PRIMARY KEY (APP_SID, APPLICATION_PAUSE_ID)
)
;

ALTER TABLE CSR.COMPL_PERMIT_APPLICATION_PAUSE ADD CONSTRAINT FK_COMPL_PERM_APP_PAUSE_CPA
    FOREIGN KEY (APP_SID, PERMIT_APPLICATION_ID)
    REFERENCES CSR.COMPLIANCE_PERMIT_APPLICATION(APP_SID, PERMIT_APPLICATION_ID)
;

CREATE TABLE CSRIMP.COMPL_PERMIT_APPLICATION_PAUSE (
	CSRIMP_SESSION_ID		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	APPLICATION_PAUSE_ID	NUMBER(10, 0)	NOT NULL,
	PERMIT_APPLICATION_ID	NUMBER(10, 0)	NOT NULL,
	PAUSED_DTM				DATE			NOT NULL,
	RESUMED_DTM				DATE,
	CONSTRAINT PK_COMPL_PERMIT_APP_PAUSE PRIMARY KEY (CSRIMP_SESSION_ID, APPLICATION_PAUSE_ID),
	CONSTRAINT FK_CSRIMP_SESSION_ID FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;

CREATE INDEX csr.ix_compl_permit_app_permit_app ON csr.compl_permit_application_pause (app_sid, permit_application_id);

-- Alter tables

-- *** Grants ***

GRANT SELECT,INSERT,UPDATE ON CSR.COMPL_PERMIT_APPLICATION_PAUSE TO CSRIMP;
GRANT SELECT ON CSR.APPLICATION_PAUSE_ID_SEQ TO CSRIMP;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (32, 'application', 'Determination paused');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../permit_pkg
@../permit_body
@../compliance_setup_body

@../schema_pkg
@../schema_body
@../csrimp/imp_body

@update_tail
