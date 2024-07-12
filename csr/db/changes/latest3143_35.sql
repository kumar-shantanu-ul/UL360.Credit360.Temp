-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE SURVEYS.SECTION_TEMPLATE MODIFY (CREATED_DTM DATE DEFAULT SYSDATE);
ALTER TABLE SURVEYS.SECTION_TEMPLATE MODIFY (LAST_UPDATED_DTM DATE);

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
--@../surveys/template_body

@update_tail
