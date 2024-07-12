-- Please update version.sql too -- this keeps clean builds in sync
define version=48

@update_header

-- rename battery -> power source
ALTER TABLE SUPPLIER.GT_PDESIGN_ANSWERS
RENAME COLUMN CONTAINS_BATTERIES TO ELECTRIC_POWERED;
	
@update_tail