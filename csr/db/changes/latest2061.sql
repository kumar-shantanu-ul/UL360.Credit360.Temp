-- Please update version.sql too -- this keeps clean builds in sync
define version=2061
@update_header

ALTER TABLE CSRIMP.CUSTOMER ADD (
	PROPERTY_FLOW_SID NUMBER(10, 0)
);

@../schema_body
@../csrimp/imp_body

@update_tail
