-- Please update version too -- this keeps clean builds in sync
define version=1847
@update_header

-- FB 34405 Boots Green Tick system - issue with product notification
-- records missing from gt_product_user meaning records misssed from search (due to join)
BEGIN

	FOR x IN (
		SELECT host FROM csr.customer WHERE LOWER(host) = 'bootssupplier.credit360.com'
	)
	LOOP

		security.user_pkg.logonadmin(x.host);
	   -- user_pkg.logonadmin('bs.credit360.com');
		
		-- find all gt products with no entry in gt_ptoduct_user for a provider or supplier user
		FOR r IN (
			select distinct x.product_id, user_sid from 
			 (
				select distinct pqp.product_id, provider_sid user_sid 
				  from supplier.product_questionnaire_provider pqp, supplier.gt_product gt 
				 where gt.product_id = pqp.product_id 
				   and (pqp.product_id, provider_sid) not in (select product_id, user_sid from supplier.gt_product_user)
			   UNION
				select distinct pqp.product_id, approver_sid user_sid
				  from supplier.product_questionnaire_approver pqp, supplier.gt_product gt 
				 where gt.product_id = pqp.product_id 
				   and (pqp.product_id, approver_sid) not in (select product_id, user_sid from supplier.gt_product_user)
			) x, supplier.product p
			where x.product_id = p.product_id 
			  AND p.deleted = 0 
		)
		LOOP
			DBMS_OUTPUT.PUT_LINE('for ' || x.host || ' added gt product user for for ' || r.product_id || '/'|| r.user_sid);
			INSERT INTO supplier.gt_product_user (app_sid, product_id, user_sid, company_sid, started)
				VALUES (security.security_pkg.getapp, r.product_id, r.user_sid, NULL, 0);
		END LOOP;
	
	END LOOP;
END;
/

@../supplier/product_body


@update_tail
