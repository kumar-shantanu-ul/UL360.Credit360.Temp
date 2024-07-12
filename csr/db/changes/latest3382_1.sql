-- Please update version.sql too -- this keeps clean builds in sync
define version=3382
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.form_response_import_options
ADD uses_new_sp_signature NUMBER(1) DEFAULT 0;

ALTER TABLE cms.form_response_import_options
MODIFY uses_new_sp_signature NOT NULL;

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
@../../../aspen2/cms/db/form_response_import_pkg
@../../../aspen2/cms/db/form_response_import_body

@update_tail
