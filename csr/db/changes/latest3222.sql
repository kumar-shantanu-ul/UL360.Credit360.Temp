-- Please update version.sql too -- this keeps clean builds in sync
define version=3222
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

GRANT DELETE ON ACTIONS.FILE_UPLOAD_GROUP TO CSR;
GRANT DELETE ON ACTIONS.FILE_UPLOAD_GROUP_MEMBER TO CSR;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
