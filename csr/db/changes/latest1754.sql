-- Please update version.sql too -- this keeps clean builds in sync
define version=1754
@update_header

ALTER TABLE ACTIONS.CUSTOMER_OPTIONS ADD(
	UPDATE_REF_ON_AMEND              NUMBER(1, 0)      DEFAULT 0 NOT NULL,
    CHECK (UPDATE_REF_ON_AMEND IN(0,1))
);

@../actions/initiative_body

@update_tail


