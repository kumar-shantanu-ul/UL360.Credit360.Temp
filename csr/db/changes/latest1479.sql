-- Please update version.sql too -- this keeps clean builds in sync
define version=1479
@update_header

BEGIN
	security.user_pkg.LogonAdmin(null);
	FOR r IN (
		SELECT app_sid
		  FROM chain.v$chain_host
		 WHERE chain_implementation = 'RFA'
	)
	LOOP
		UPDATE chain.purchase
		   SET invoice_number = NULL
		 WHERE end_date IS NOT NULL
		   AND invoice_number IS NOT NULL;
		   
		UPDATE chain.purchase
		   SET purchase_order = NULL
		 WHERE end_date IS NOT NULL
		   AND purchase_order IS NOT NULL;
  END LOOP;
END;
/

ALTER TABLE chain.purchase ADD CONSTRAINT CC_INV_NUM_PURCH_ORD_END_DATE
	CHECK (END_DATE IS NULL OR (END_DATE IS NOT NULL AND INVOICE_NUMBER IS NULL AND PURCHASE_ORDER IS NULL));

@update_tail

