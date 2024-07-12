-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=44
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_IMPORTER_CMS DROP CONSTRAINT CK_AUTO_IMP_IMPORTER_SEP;

ALTER TABLE CSR.AUTO_IMP_IMPORTER_CMS ADD CONSTRAINT CK_AUTO_IMP_IMPORTER_SEP CHECK (DSV_SEPARATOR IN ('PIPE','TAB','COMMA','SEMICOLON') OR DSV_SEPARATOR IS NULL);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
