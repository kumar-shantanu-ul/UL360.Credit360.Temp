-- Please update version.sql too -- this keeps clean builds in sync
define version=10
@update_header

-- rename col in prod type table - this is now a scoring factor that applies to MANUFACTURED and FORMULATED products - so old name was wrong
ALTER TABLE GT_PRODUCT_TYPE
	RENAME COLUMN PROD_USE_PER_APP_ML TO WATER_USAGE_FACTOR;
	
ALTER TABLE GT_PRODUCT_TYPE MODIFY(MNFCT_ENERGY_SCORE  NULL);

@update_tail