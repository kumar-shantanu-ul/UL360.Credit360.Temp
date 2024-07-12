-- Please update version.sql too -- this keeps clean builds in sync
define version=2970
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.EMISSION_FACTOR_PROFILE_FACTOR ADD CONSTRAINT FK_EMISSION_FACTOR_PROFILE 
    FOREIGN KEY (APP_SID, PROFILE_ID)
    REFERENCES CSR.EMISSION_FACTOR_PROFILE(APP_SID, PROFILE_ID) ON DELETE CASCADE
;

ALTER TABLE CSR.EMISSION_FACTOR_PROFILE DROP COLUMN ACTIVE;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.batched_export_type (BATCH_EXPORT_TYPE_ID, LABEL, ASSEMBLY)
VALUES (8, 'Emission profile export', 'Credit360.ExportImport.Export.Batched.Exporters.EmissionProfileExporter');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../factor_pkg
@../factor_body


@update_tail
