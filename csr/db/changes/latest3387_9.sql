-- Please update version.sql too -- this keeps clean builds in sync
define version=3387
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.home_page DROP PRIMARY KEY;

ALTER TABLE csrimp.home_page ADD (
	priority	NUMBER(10, 0)
);

ALTER TABLE csrimp.home_page RENAME COLUMN host TO created_by_host;

ALTER TABLE csrimp.home_page ADD CONSTRAINT PK_HOME_PAGE PRIMARY KEY (csrimp_session_id, sid_id);

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
@../landing_page_body
@../schema_body
@../site_name_management_body
@../csrimp/imp_body

@update_tail
