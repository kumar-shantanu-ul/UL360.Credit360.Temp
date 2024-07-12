-- Please update version.sql too -- this keeps clean builds in sync
define version=3162
define minor_version=6
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
BEGIN
	security.user_pkg.logonadmin;

	UPDATE chain.supplier_relationship
	   SET deleted = 1,
	   	   active = 0
	 WHERE purchaser_company_sid = supplier_company_sid;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/company_body

@update_tail
