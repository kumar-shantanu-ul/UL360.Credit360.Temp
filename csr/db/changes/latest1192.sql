-- Please update version.sql too -- this keeps clean builds in sync
define version=1192
@update_header

ALTER TABLE CT.PS_ITEM
 ADD (KG_CO2  NUMBER(30,20));

ALTER TABLE CT.PS_ITEM
 ADD (EIO_ID  NUMBER(10));

ALTER TABLE ct.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_KG_CO2 
    CHECK (KG_CO2 >= 0);
	

ALTER TABLE ct.PS_ITEM ADD CONSTRAINT EIO_PS_ITEM 
    FOREIGN KEY (EIO_ID) REFERENCES ct.EIO (EIO_ID);
	
	
@..\ct\products_services_pkg
@..\ct\products_services_body
	
@update_tail
