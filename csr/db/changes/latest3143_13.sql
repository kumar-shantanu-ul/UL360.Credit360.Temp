-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE SURVEYS.SECTION_TEMPLATE_TR
	ADD CONSTRAINT SECTION_TEMPLATE_NAME_UNIQUE UNIQUE (APP_SID, LANGUAGE_CODE, NAME)
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
--@../surveys/template_pkg
--@../surveys/template_body

@update_tail
