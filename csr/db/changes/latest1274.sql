-- Please update version.sql too -- this keeps clean builds in sync
define version=1274
@update_header

--alter column pct to amount
ALTER TABLE ct.ht_consumption_region ADD amount NUMBER(20,10) NULL;
ALTER TABLE ct.ht_consumption_region ADD CONSTRAINT cc_cons_region_amount CHECK (amount >= 0);

BEGIN
	UPDATE ct.ht_consumption_region cr
	   SET cr.amount = (SELECT c.amount 
					      FROM ct.ht_consumption c
					     WHERE c.ht_consumption_category_id = 3
						   AND c.app_sid = cr.app_sid
						   AND c.company_sid = cr.company_sid);
						   

END;
/

ALTER TABLE ct.ht_consumption_region MODIFY amount NUMBER(20,10) NOT NULL;
ALTER TABLE ct.ht_consumption_region DROP CONSTRAINT cc_pct;
ALTER TABLE ct.ht_consumption_region DROP COLUMN pct;

--TODO: check order, path and id dummy package needed
@..\ct\consumption_pkg
@..\ct\consumption_body


@update_tail
	