-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=15
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
	security.user_pkg.logonadmin();
	
	UPDATE chain.default_message_param 
	   SET href = '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reCompanySid}' 
	 WHERE href = '/csr/site/chain/supplierDetails.acds?companySid={reCompanySid}';
	 
	UPDATE chain.default_message_param 
	   SET href = '/csr/site/chain/manageCompany/manageCompany.acds?companySid={reSecondaryCompanySid}' 
	 WHERE href = '/csr/site/chain/supplierDetails.acds?companySid={reSecondaryCompanySid}';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../issue_body

@update_tail
