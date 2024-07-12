-- Please update version.sql too -- this keeps clean builds in sync
define version=2927
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.TEMP_METER_PATCH_IMPORT_ROWS
  ADD note VARCHAR2(800);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.audit_type(audit_type_id, label, audit_type_group_id)
VALUES(24, 'Meter patch updated', 1);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\csr_data_pkg
@..\meter_patch_pkg

@..\meter_patch_body

@update_tail
