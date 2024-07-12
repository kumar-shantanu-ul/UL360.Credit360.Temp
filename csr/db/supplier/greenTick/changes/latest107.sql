-- Please update version.sql too -- this keeps clean builds in sync
define version=107
@update_header 


BEGIN
	FOR c IN (SELECT app_sid FROM supplier.customer_options) 
	LOOP
		FOR r IN (SELECT DISTINCT p.product_id pid, p.app_sid, pqp.provider_sid user_sid FROM supplier.product p 
					 JOIN supplier.product_questionnaire_provider pqp ON p.product_id=pqp.product_id
					 WHERE p.app_sid = c.app_sid
					UNION
					SELECT DISTINCT p.product_id pid, p.app_sid, pqa.approver_sid user_sid FROM supplier.product p 
					 JOIN supplier.product_questionnaire_approver pqa ON p.product_id=pqa.product_id
					 WHERE p.app_sid = c.app_sid) 
		LOOP
		  BEGIN
			INSERT INTO supplier.gt_product_user VALUES (r.app_sid, r.pid, r.user_sid, NULL, 1);
		  EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
			  NULL;
		  END;
		END LOOP;
	END LOOP;
END;
/

@update_tail