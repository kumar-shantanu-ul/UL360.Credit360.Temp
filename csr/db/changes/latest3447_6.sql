-- Please update version.sql too -- this keeps clean builds in sync
define version=3447
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE CSRIMP.STD_FACTOR_SET_ACTIVE(
	CSRIMP_SESSION_ID       NUMBER(10, 0)   DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	STD_FACTOR_SET_ID		NUMBER(10, 0)   NOT NULL,
	CONSTRAINT PK_STD_FACTOR_SET_ACTIVE PRIMARY KEY (CSRIMP_SESSION_ID, STD_FACTOR_SET_ID),
	CONSTRAINT FK_STD_FACTOR_SET_ACTIVE_IS FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);


-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csrimp.std_factor_set_active TO tool_user;
GRANT SELECT, INSERT, UPDATE ON csr.std_factor_set_active TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (95, 'Emission Profile import', 'batch-importer', 0, 'support@credit360.com', 3, 120);

	INSERT INTO csr.batched_import_type (batch_job_type_id, label, assembly)
	VALUES (95, 'Emission Profile import', 'Credit360.ExportImport.Import.Batched.Importers.EmissionProfileImporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_pkg
@../schema_pkg

@../csr_app_body
@../factor_body
@../schema_body
@../csrimp/imp_body

@update_tail
