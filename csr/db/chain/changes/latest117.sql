define version=117
@update_header

@latest117_packages

ALTER TABLE CHAIN.PRODUCT ADD (
	PUBLISHED					NUMBER(1,0) DEFAULT 0 NOT NULL,
	LAST_PUBLISHED_DTM			TIMESTAMP NULL,
	LAST_PUBLISHED_BY_USER_SID	NUMBER(10,0) NULL,
	CONSTRAINT CHK_PRODUCT_PUBLISHED CHECK (PUBLISHED IN (1,0)),
	CONSTRAINT FK_PRDCT_PUB_USER_SID FOREIGN KEY (APP_SID, LAST_PUBLISHED_BY_USER_SID) REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID)
);

CREATE OR REPLACE VIEW chain.v$product AS
	SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, 
			p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
			cmp.description, cmp.component_code, cmp.deleted,
			p.company_sid, cmp.created_by_sid, cmp.created_dtm,
			p.published, p.last_published_dtm, p.last_published_by_user_sid
	  FROM product p, component cmp
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.app_sid = cmp.app_sid
	   AND p.product_id = cmp.component_id
;

exec user_pkg.logonadmin;

BEGIN
	----------------------------------------------------------------------------
	--		MAPPED_PRODUCTS_TO_PUBLISH
	----------------------------------------------------------------------------
	chain.message_pkg.DefineMessage(
		in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH,
		in_message_template 		=> 'One or more products you sell {productsYouSell:OPEN}need finishing{productsYouSell:CLOSE}.',
		in_repeat_type 				=> chain_pkg.REPEAT_IF_CLOSED,
		in_completion_type 			=> chain_pkg.CODE_ACTION,
		in_completed_template 		=> 'All products you sell were last published {relCompletedDtm}',
		in_css_class 				=> 'background-icon company-icon',
		in_addressing_type			=> chain_pkg.COMPANY_ADDRESS
	);

		chain.message_pkg.DefineMessageParam(
			in_primary_lookup 			=> chain_pkg.MAPPED_PRODUCTS_TO_PUBLISH, 
			in_param_name 				=> 'productsYouSell', 
			in_href 					=> '/csr/site/chain/products/productsMyCompanySells.acds?showUnpublished=true'
		);
END;
/

@..\product_pkg
@..\product_body
@..\purchased_component_body

@update_tail