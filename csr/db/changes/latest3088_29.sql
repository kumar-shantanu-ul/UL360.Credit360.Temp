-- Please update version.sql too -- this keeps clean builds in sync
define version=3088
define minor_version=29
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.tt_user_details ADD USER_NAME VARCHAR2(256);

ALTER TABLE chain.customer_options ADD allow_duplicate_emails NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_allow_dup_emails CHECK (allow_duplicate_emails IN (0, 1))

ALTER TABLE csrimp.chain_customer_options ADD allow_duplicate_emails NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_allow_dup_emails CHECK (allow_duplicate_emails IN (0, 1));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE chain.customer_options
	   SET allow_duplicate_emails = 1;
END;
/
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\chain\helper_pkg
@..\chain\company_user_pkg

@..\schema_body
@..\chain\company_user_body
@..\chain\helper_body
@..\csrimp\imp_body

@update_tail
