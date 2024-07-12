-- Please update version.sql too -- this keeps clean builds in sync
define version=652
@update_header

ALTER TABLE csr.CUSTOMER ADD (
    ALLOW_DELEG_PLAN    NUMBER(1, 0)      DEFAULT 0 NOT NULL
);

@..\schema_body
@..\csr_app_body

@update_tail


