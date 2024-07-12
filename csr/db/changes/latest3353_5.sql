-- Please update version.sql too -- this keeps clean builds in sync
define version=3353
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables
DROP INDEX CONTEXT_SENSITIVE_HELP_BASE_UK;
CREATE UNIQUE INDEX CSR.CONTEXT_SENSITIVE_HELP_BASE_UK ON CSR.CONTEXT_SENSITIVE_HELP_BASE ('1');

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
