-- Please update version.sql too -- this keeps clean builds in sync
define version=3353
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL
MODIFY SOURCE_FILE_REF VARCHAR2(4000)
;

ALTER TABLE CSR.AUTO_IMP_CORE_DATA_VAL_FAIL
MODIFY SOURCE_FILE_REF VARCHAR2(4000)
;
-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../automated_import_body

@update_tail
