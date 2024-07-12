-- Please update version.sql too -- this keeps clean builds in sync
define version=1218
@update_header

ALTER TABLE CT.CUSTOMER_OPTIONS ADD SNAPSHOT_TAKEN NUMBER(1) DEFAULT 0;

ALTER TABLE CT.CUSTOMER_OPTIONS ADD CONSTRAINT CC_CUST_OPT_SNPSHT_TKN 
    CHECK (SNAPSHOT_TAKEN IN (1,0));

@..\ct\snapshot_pkg
@..\ct\snapshot_body
@..\ct\excel_body
@..\ct\breakdown_type_body
	
@update_tail
