-- Please update version.sql too -- this keeps clean builds in sync
define version=1970
@update_header

ALTER TABLE CSR.CUSTOMER_INIT_SAVING_TYPE ADD (
    IS_RUNNING        NUMBER(1, 0),
    IS_DURING         NUMBER(1, 0),
    CHECK (IS_RUNNING IS NULL OR IS_RUNNING IN (0,1)),
    CHECK (IS_DURING IS NULL OR IS_DURING IN (0,1))
);

@../initiative_body

@update_tail
