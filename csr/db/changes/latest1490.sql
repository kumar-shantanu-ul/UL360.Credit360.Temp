-- Please update version.sql too -- this keeps clean builds in sync
define version=1490
@update_header

BEGIN
	security.user_pkg.LogonAdmin(null);
	FOR r IN (
		SELECT app_sid
		  FROM chain.v$chain_host
		 WHERE chain_implementation = 'RFA'
	)
	LOOP
		--Set POs Null for every duplicate entry, so we can apply the index after (right now, there are no duplicates under live)
		UPDATE chain.purchase
		   SET purchase_order = NULL
	     WHERE ROWID IN (
			SELECT sub.ROWID
		      FROM(
				SELECT p.purchase_order, RANK() OVER (PARTITION BY product_id, purchaser_company_sid, purchase_order ORDER BY purchase_id) rnk
				  FROM chain.purchase p
			  )sub
			 WHERE sub.rnk >1
		       AND sub.purchase_order IS NOT NULL
		);
  END LOOP;
END;
/

--ALTER TABLE chain.purchase ADD CONSTRAINT CC_PROD_PURCH_COMP_PURCH_ORDER UNIQUE (product_id, purchaser_company_sid, purchase_order);


@update_tail