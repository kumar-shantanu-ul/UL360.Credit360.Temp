-- Please update version.sql too -- this keeps clean builds in sync
define version=1199
@update_header

ALTER TABLE CT.SUPPLIER ADD DESCRIPTION VARCHAR2(200);

@..\ct\supplier_pkg

@..\ct\supplier_body
@..\ct\products_services_body

@update_tail
