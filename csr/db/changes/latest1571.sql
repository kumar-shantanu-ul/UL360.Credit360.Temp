-- Please update version.sql too -- this keeps clean builds in sync
define version=1571
@update_header

DROP INDEX CHAIN.UK_SUPP_REL_CODE;

CREATE UNIQUE INDEX CHAIN.UK_SUPP_REL_CODE ON CHAIN.SUPPLIER_RELATIONSHIP
(
	CASE  
		WHEN "SUPP_REL_CODE" IS NULL THEN NULL 
		WHEN "DELETED" = 1 THEN NULL
		ELSE TO_CHAR("APP_SID")||'-'||TO_CHAR("PURCHASER_COMPANY_SID")||'-'||"SUPP_REL_CODE" 
	END 
);

@../chain/company_body

@update_tail
