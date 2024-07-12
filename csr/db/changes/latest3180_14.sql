-- Please update version.sql too -- this keeps clean builds in sync
define version=3180
define minor_version=14
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
UPDATE security.securable_object so
   SET name = 'csr_question_library_surveys'
 WHERE EXISTS (SELECT NULL 
				 FROM security.menu
				WHERE sid_id = so.sid_id
				  AND action = '/csr/site/quicksurvey/library/list.acds');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../enable_body

@update_tail
