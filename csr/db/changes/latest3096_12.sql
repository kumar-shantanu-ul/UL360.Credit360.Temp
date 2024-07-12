-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX CSR.UK_CI_LOOKUP_KEY;
CREATE UNIQUE INDEX CSR.UK_CI_LOOKUP_KEY ON CSR.COMPLIANCE_ITEM (APP_SID,NVL(LOOKUP_KEY, 'COMP_ITEM_' || COMPLIANCE_ITEM_ID));

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

@update_tail
