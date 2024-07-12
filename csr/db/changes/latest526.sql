-- Please update version.sql too -- this keeps clean builds in sync
define version=526
@update_header

ALTER TABLE CUSTOMER ADD (
    USE_CARBON_EMISSION    NUMBER(1, 0)      DEFAULT 0 NOT NULL
);

@update_tail


