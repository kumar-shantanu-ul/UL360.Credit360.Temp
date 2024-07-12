-- Please update version.sql too -- this keeps clean builds in sync
define version=3250
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
GRANT DELETE ON ACTIONS.RECKONER_TAG_GROUP TO CSR;
GRANT DELETE ON ACTIONS.RECKONER_TAG TO CSR;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body
@../chain/chain_body

@update_tail
