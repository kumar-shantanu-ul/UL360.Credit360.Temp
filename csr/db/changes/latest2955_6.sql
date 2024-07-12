-- Please update version.sql too -- this keeps clean builds in sync
define version=2955
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
CREATE INDEX CHAIN.IX_COMPANY_REFERENCE_VAL ON CHAIN.COMPANY_REFERENCE(APP_SID, REFERENCE_ID, VALUE);

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
@..\chain\chain_link_pkg

@..\chain\chain_link_body
@..\chain\company_body
@..\chain\helper_body
@..\chain\message_body

@update_tail
