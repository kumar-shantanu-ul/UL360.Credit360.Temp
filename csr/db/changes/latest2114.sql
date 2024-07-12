-- Please update version.sql too -- this keeps clean builds in sync
define version=2114
@update_header

/* Show all components in product page */
ALTER TABLE chain.customer_options ADD(
	show_all_components     		NUMBER(1, 0)   
	CONSTRAINT chk_co_show_all_components CHECK (show_all_components IN (0, 1))
);

UPDATE chain.customer_options SET show_all_components = 1;

ALTER TABLE chain.customer_options MODIFY show_all_components DEFAULT 1 NOT NULL;

@../chain/helper_pkg
--@../chain/company_pkg  --build after the web servers release
@../chain/company_user_pkg
@../chain/purchased_component_pkg

@../chain/helper_body
--@../chain/company_body
@../chain/company_user_body
@../chain/purchased_component_body
@../chain/component_body

@update_tail