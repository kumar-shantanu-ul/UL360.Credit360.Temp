-- Please update version.sql too -- this keeps clean builds in sync
define version=3376
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DELETE FROM csr.module
 WHERE module_id = 120
  AND enable_sp = 'EnableIntegrationQuestionAnswerApi';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg
@../enable_body

@update_tail
