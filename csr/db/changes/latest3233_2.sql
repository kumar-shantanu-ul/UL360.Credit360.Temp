-- Please update version.sql too -- this keeps clean builds in sync
define version=3233
define minor_version=2
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

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_pkg
@..\campaigns\campaign_pkg
@..\chain\company_dedupe_pkg

@..\audit_body
@..\campaigns\campaign_body
@..\chain\card_body
@..\chain\company_dedupe_body
@..\..\..\aspen2\cms\db\tab_body

@update_tail
