-- Please update version.sql too -- this keeps clean builds in sync
define version=3132
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- These tables have already been dropped in trunk. Leave empty script to maintain version number sequence
-- alter table chain.bsci_supplier modify address varchar2(4000);
-- alter table csrimp.chain_bsci_supplier modify address varchar2(4000);

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
