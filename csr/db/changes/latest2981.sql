-- Please update version.sql too -- this keeps clean builds in sync
define version=2981
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CHAIN.BSCI_IMPORT (
	APP_SID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	BSCI_ID				NUMBER(10),
	BATCH_JOB_ID 		NUMBER(10),
	CONSTRAINT PK_BSCI_BATCH_IMPORT PRIMARY KEY (APP_SID, BSCI_ID, BATCH_JOB_ID)
);

-- Alter tables

-- *** Grants ***
GRANT SELECT ON chain.bsci_import TO csr;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.BSCI_IMPORT ADD CONSTRAINT FK_BSCI_BATCH_JOB
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID
);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, one_at_a_time, notify_address, notify_after_attempts)
VALUES (28, 'BSCI single import', 'chain-bsci-audit-single', 1, 'support@credit360.com', 3);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../flow_body
@../batch_job_pkg
@../audit_body
@../schema_pkg
@../schema_body

@../chain/bsci_pkg
@../chain/bsci_body


@update_tail
