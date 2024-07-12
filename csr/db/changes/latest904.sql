-- Please update version.sql too -- this keeps clean builds in sync
define version=904
@update_header

ALTER TABLE csr.csr_user ADD enable_aria NUMBER(1, 0) DEFAULT 0 NOT NULL;

@..\csr_user_pkg
@..\csr_user_body

@update_tail
