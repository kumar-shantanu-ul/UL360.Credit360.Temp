-- Please update version.sql too -- this keeps clean builds in sync
define version=775
@update_header

ALTER TABLE CSR.LOGISTICS_DEFAULT ADD
    AUTO_CREATE_CUSTOM_LOCATION    NUMBER(1, 0)     DEFAULT 0 NOT NULL
;



@update_tail
