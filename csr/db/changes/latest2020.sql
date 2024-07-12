define version=2020
@update_header

ALTER TABLE CSR.aggregate_ind_group ADD (
	JS_INCLUDE		VARCHAR2(255)
);
	
@..\delegation_body
	
@update_tail