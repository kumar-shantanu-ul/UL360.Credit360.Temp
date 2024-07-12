-- Please update version.sql too -- this keeps clean builds in sync
define version=2302
@update_header

ALTER TABLE csr.property_tab  ADD CONSTRAINT fk_property_tab_customer 
	FOREIGN KEY (app_sid) 
	REFERENCES csr.customer (app_sid);

@update_tail
