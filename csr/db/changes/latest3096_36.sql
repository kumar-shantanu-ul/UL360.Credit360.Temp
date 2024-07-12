-- Please update version.sql too -- this keeps clean builds in sync
define version=3096
define minor_version=36
@update_header

-- *** DDL ***
-- Create table
CREATE TABLE CHAIN.DD_CUSTOMER_BLCKLST_EMAIL(
	APP_SID						NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	EMAIL_DOMAIN				VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DD_CUSTOMER_BLCKLST_EMAIL PRIMARY KEY(APP_SID, EMAIL_DOMAIN)
);

CREATE TABLE CHAIN.DD_DEF_BLCKLST_EMAIL(
	EMAIL_DOMAIN				VARCHAR2(255) NOT NULL,
	CONSTRAINT PK_DD_DEF_BLCKLST_EMAIL PRIMARY KEY (EMAIL_DOMAIN)
);

CREATE TABLE CSRIMP.CHAIN_DD_CUST_BLCKLST_EMAIL(
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	EMAIL_DOMAIN				VARCHAR2(255)	NOT NULL,
	CONSTRAINT PK_CHAIN_DD_CUST_BLCKLST_EML PRIMARY KEY(CSRIMP_SESSION_ID, EMAIL_DOMAIN)
);

-- Alter tables

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON CHAIN.DD_CUSTOMER_BLCKLST_EMAIL TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.CHAIN_DD_CUST_BLCKLST_EMAIL TO TOOL_USER;
GRANT SELECT, INSERT ON CHAIN.DD_CUSTOMER_BLCKLST_EMAIL TO CSR;
GRANT SELECT ON CHAIN.DD_DEF_BLCKLST_EMAIL TO CSR;
-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN

	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('example');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('gmail');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('googlemail');
	INSERT INTO CHAIN.DD_DEF_BLCKLST_EMAIL (EMAIL_DOMAIN) VALUES ('yahoo');
END;
/
	
BEGIN	
	INSERT INTO chain.dd_customer_blcklst_email (app_sid, email_domain)
	SELECT co.app_sid, ddc.email_domain 
	  FROM chain.customer_options co
	  CROSS JOIN chain.dd_def_blcklst_email ddc
	 WHERE co.enable_dedupe_preprocess = 1;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages **
@../schema_pkg
@../schema_body
@../enable_body

@../chain/company_body
@../chain/company_dedupe_pkg
@../chain/company_dedupe_body
@../chain/dedupe_preprocess_pkg
@../chain/dedupe_preprocess_body
@../chain/setup_body

@../csrimp/imp_body

@update_tail
