-- Please update version.sql too -- this keeps clean builds in sync
define version=3008
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables
create index chain.ix_bsci_associat_company_sid_a on chain.bsci_associate (app_sid, company_sid, audit_ref);
create index chain.ix_bsci_finding_company_sid_a on chain.bsci_finding (app_sid, company_sid, audit_ref);

-- Alter tables

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
