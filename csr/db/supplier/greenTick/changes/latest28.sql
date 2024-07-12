-- Please update version.sql too -- this keeps clean builds in sync
define version=28
@update_header

ALTER TABLE SUPPLIER.GT_PRODUCT_TYPE DROP COLUMN AV_WATER_CONTENT_PCT;	
	
@..\create_views
	
@update_tail