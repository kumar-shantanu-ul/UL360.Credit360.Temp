-- Please update version.sql too -- this keeps clean builds in sync
define version=52

@update_header

ALTER TABLE SUPPLIER.GT_PDA_BATTERY
MODIFY(GT_BATTERY_USE_ID  NULL);

	
@update_tail