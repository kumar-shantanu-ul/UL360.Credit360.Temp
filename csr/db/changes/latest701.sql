-- Please update version.sql too -- this keeps clean builds in sync
define version=701
@update_header

ALTER TABLE csr.location ADD IS_APPROVED NUMBER(1, 0) DEFAULT 0 NOT NULL;

UPDATE csr.location
   SET is_approved = 1
 WHERE latitude IS NOT NULL;

@update_tail
