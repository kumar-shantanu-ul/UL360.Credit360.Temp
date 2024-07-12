-- Please update version.sql too -- this keeps clean builds in sync
define version=2115
@update_header

-- Default behaviour should be to batch delegation plan application
ALTER TABLE CSR.CUSTOMER MODIFY (
	DYNAMIC_DELEG_PLANS_BATCHED       NUMBER(1, 0)      DEFAULT 1
);

BEGIN
	-- Update all non-otto sites to 
	-- batch delegation plan application
	UPDATE csr.customer
	   SET dynamic_deleg_plans_batched = 1
	 WHERE dynamic_deleg_plans_batched = 0
	   AND not host like '%otto%';
END;
/

@update_tail