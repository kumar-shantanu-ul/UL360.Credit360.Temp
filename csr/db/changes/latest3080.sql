-- Please update version.sql too -- this keeps clean builds in sync
define version=3080
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csrimp.issue_type DROP CONSTRAINT CHK_IT_ACARD_VALID;

ALTER TABLE csrimp.issue_type ADD CONSTRAINT CHK_IT_ACARD_VALID CHECK (AUTO_CLOSE_AFTER_RESOLVE_DAYS >= 0);

-- *** Grants ***

GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.enhesa_options TO tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../schema_body
@../csrimp/imp_body

@update_tail
