define version=109
@update_header

-- Unforunately we don't know the names of the check constraints we want to remove
BEGIN
	FOR r IN (SELECT constraint_name
			    FROM all_cons_columns
			   WHERE owner='CHAIN'
			     AND table_name='PRODUCT'
			     AND column_name IN ('CODE2_MANDATORY','CODE3_MANDATORY','CODE2','CODE3')
			   GROUP BY constraint_name
			  HAVING COUNT(*)>1) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE chain.PRODUCT DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/

ALTER TABLE chain.product DROP COLUMN CODE2_MANDATORY;
ALTER TABLE chain.product DROP COLUMN CODE3_MANDATORY;

@..\product_pkg
@..\product_body
@..\component_body
@..\purchased_component_body

@update_tail