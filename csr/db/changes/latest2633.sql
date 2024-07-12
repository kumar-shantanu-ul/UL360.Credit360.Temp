--Please update version.sql too -- this keeps clean builds in sync
define version=2633
@update_header

ALTER TABLE CSR.SUPPLIER ADD DEFAULT_REGION_MOUNT_SID NUMBER(10) DEFAULT NULL;
ALTER TABLE CSRIMP.SUPPLIER ADD DEFAULT_REGION_MOUNT_SID NUMBER(10) DEFAULT NULL;

@../schema_body
@../csrimp/imp_body
@../supplier_body
	
@update_tail