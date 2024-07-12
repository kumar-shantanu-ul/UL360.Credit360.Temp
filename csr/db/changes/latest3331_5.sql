-- Please update version.sql too -- this keeps clean builds in sync
define version=3331
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.customer_saml_sso
ADD use_first_last_name_attrs NUMBER(1) DEFAULT 0 NOT NULL;

ALTER TABLE csr.customer_saml_sso
ADD first_name_attribute VARCHAR2(255);

ALTER TABLE csr.customer_saml_sso
ADD last_name_attribute VARCHAR2(255);

ALTER TABLE csr.customer_saml_sso
ADD CONSTRAINT CHK_USE_FIRST_LAST_NAME_ATTRS CHECK ((use_basic_user_management IS NULL OR use_basic_user_management = 0) OR (use_first_last_name_attrs IS NULL OR use_first_last_name_attrs = 0) OR (use_basic_user_management = 1 AND use_first_last_name_attrs = 1 AND first_name_attribute IS NOT NULL AND last_name_attribute IS NOT NULL));

ALTER TABLE csr.customer_saml_sso
DROP CONSTRAINT CHK_BASIC_USR_MGMT_ATTRS;

ALTER TABLE csr.customer_saml_sso
ADD CONSTRAINT CHK_BASIC_USR_MGMT_ATTRS CHECK ((use_basic_user_management IS NULL OR use_basic_user_management = 0) OR (use_basic_user_management = 1 AND full_name_attribute IS NOT NULL AND email_attribute IS NOT NULL) OR (use_basic_user_management = 1 AND use_first_last_name_attrs = 1));

-- Added to correct any databases that have been created since mismatch in schema & latest script (3324).
DECLARE
	v_is_nullable 	VARCHAR2(1);
BEGIN
	SELECT nullable
	  INTO v_is_nullable
	  FROM all_tab_cols
	 WHERE table_name = 'CUSTOMER_SAML_SSO'
	   AND owner = 'CSR'
	   AND column_name = 'USE_BASIC_USER_MANAGEMENT';

	IF v_is_nullable = 'Y' THEN
		UPDATE csr.customer_saml_sso
		   SET use_basic_user_management = 0
		 WHERE use_basic_user_management IS NULL;
	
		EXECUTE IMMEDIATE 'ALTER TABLE csr.customer_saml_sso MODIFY use_basic_user_management NOT NULL';
	END IF;
END;
/

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
@../saml_pkg
@../saml_body

@update_tail
