-- Please update version too -- this keeps clean builds in sync
define version=1844
@update_header

ALTER TABLE chain.company_type ADD css_class VARCHAR2(255);
ALTER TABLE chain.customer_options ADD use_company_type_css_class NUMBER(1);
	
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.customer_options SET use_company_type_css_class = 0;	
END;
/

ALTER TABLE chain.customer_options MODIFY use_company_type_css_class NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT CHK_USE_CT_CSS_CLASS CHECK (use_company_type_css_class IN (0, 1));

@../chain/company_type_pkg

@../chain/helper_body
@../chain/company_type_body

@update_tail
