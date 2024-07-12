-- Please update version.sql too -- this keeps clean builds in sync
define version=706
@update_header

ALTER TABLE csr.location ADD IS_GOOGLE_FAIL NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.custom_location ADD IS_GOOGLE_FAIL NUMBER(1, 0) DEFAULT 0 NOT NULL;

@update_tail
