-- Please update version.sql too -- this keeps clean builds in sync
define version=702
@update_header

ALTER TABLE csr.custom_location ADD IS_APPROVED NUMBER(1, 0) DEFAULT 0 NOT NULL;

UPDATE csr.custom_location
   SET is_approved = 1
 WHERE location_type_id = 1
    OR location_type_id = 2;

@update_tail
