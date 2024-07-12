-- Please update version.sql too -- this keeps clean builds in sync
define version=694
@update_header

ALTER TABLE csr.custom_location MODIFY name NULL;
ALTER TABLE csr.custom_location MODIFY description NULL;
ALTER TABLE csr.custom_location ADD address VARCHAR2(1023);
ALTER TABLE csr.custom_location ADD city VARCHAR2(255);
ALTER TABLE csr.custom_location ADD province VARCHAR2(255);
ALTER TABLE csr.custom_location ADD postcode VARCHAR2(255);

ALTER TABLE csr.location DROP COLUMN address;
ALTER TABLE csr.location DROP COLUMN postcode;

@update_tail
