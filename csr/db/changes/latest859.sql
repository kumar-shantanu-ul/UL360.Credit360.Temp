-- Please update version.sql too -- this keeps clean builds in sync
define version=859
@update_header

ALTER TABLE donations.BUDGET ADD (IS_ACTIVE NUMBER(1,0) DEFAULT 1 NOT NULL);

@../donations/donation_pkg
@../donations/donation_body
@../donations/budget_body

@update_tail
