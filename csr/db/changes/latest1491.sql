-- Please update version.sql too -- this keeps clean builds in sync
define version=1491
@update_header

BEGIN
	-- Drop constraint CC_PROD_PURCH_COMP_PURCH_ORDER in case it was created in latest1490
	FOR r IN (
         SELECT owner, constraint_name, table_name, search_condition
           FROM all_constraints
          WHERE owner = 'CHAIN' 
            AND table_name ='PURCHASE' 
			AND constraint_type='CC_PROD_PURCH_COMP_PURCH_ORDER'
    )
    LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
    END LOOP;
END;
/


@update_tail