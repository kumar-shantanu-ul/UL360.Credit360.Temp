-- Please update version.sql too -- this keeps clean builds in sync
define version=1424
@update_header

ALTER TABLE CHAIN.PURCHASE MODIFY (APP_SID DEFAULT SYS_CONTEXT('SECURITY', 'APP'));

DECLARE
	v_count number;
BEGIN
	-- Chain clean script had an incorrect FK constraint, pointing to wrong table - fix if neccessary
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints a
	  JOIN all_constraints b
		ON a.r_constraint_name = b.constraint_name
	   AND a.r_owner = b.owner
	 WHERE a.owner = 'CHAIN' 
	   AND a.constraint_name = 'FK_PURCHASE_PRODUCT' 
	   AND a.table_name = 'PURCHASE'
	   AND b.table_name = 'PRODUCT';	
	
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PURCHASE DROP CONSTRAINT FK_PURCHASE_PRODUCT';
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PURCHASE ADD CONSTRAINT FK_PURCHASE_PRODUCT FOREIGN KEY (APP_SID, PRODUCT_ID) REFERENCES CHAIN.PURCHASED_COMPONENT (APP_SID, COMPONENT_ID)';
	END IF;
	
	
	-- Chain clean script had missing FK constraint, add if neccessary
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_constraints 
	 WHERE owner = 'CHAIN' 
	   AND constraint_name = 'FK_PURCHASE_COMPANY' 
	   AND table_name = 'PURCHASE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PURCHASE ADD CONSTRAINT FK_PURCHASE_COMPANY FOREIGN KEY (APP_SID, PURCHASER_COMPANY_SID) REFERENCES CHAIN.COMPANY(APP_SID, COMPANY_SID)';
	END IF;
END;
/

@update_tail
