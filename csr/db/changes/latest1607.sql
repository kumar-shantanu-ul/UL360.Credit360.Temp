-- Please update version.sql too -- this keeps clean builds in sync
define version=1607
@update_header


INSERT INTO csr.capability (name, allow_by_default) VALUES ('Ask for section edit message', 1);
INSERT INTO csr.capability (name, allow_by_default) VALUES ('Ask for section state change message', 1);

ALTER TABLE csr.customer ADD ALLOW_SECTION_IN_MANY_CARTS    NUMBER(1, 0)      DEFAULT 1 NOT NULL;

@../csr_app_body

@update_tail
