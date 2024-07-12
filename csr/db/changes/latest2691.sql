-- Please update version.sql too -- this keeps clean builds in sync
define version=2691
@update_header

--fixes 2684
DECLARE
	v_count	number(10);
BEGIN
	SELECT COUNT(*) 
	  INTO v_count 
	  FROM all_indexes 
	 WHERE owner = 'UPD' 
	   AND index_name = 'UI_SUPPL_REL_PURCH_FLOW_ITEM';

	IF v_count = 1 THEN
		EXECUTE IMMEDIATE 'DROP INDEX UI_SUPPL_REL_PURCH_FLOW_ITEM';
	END IF;
	
	-- Check it isn't already correct for DBs who have run clean since this was initially created!
	-- (i.e. installed customers).
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_indexes
	 WHERE owner = 'CHAIN'
	   AND index_name = 'UI_SUPPL_REL_PURCH_FLOW_ITEM';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CHAIN.UI_SUPPL_REL_PURCH_FLOW_ITEM ON CHAIN.SUPPLIER_RELATIONSHIP(APP_SID, PURCHASER_COMPANY_SID, NVL2(FLOW_ITEM_ID, FLOW_ITEM_ID, SUPPLIER_COMPANY_SID))';
	END IF;
END;
/

@update_tail
