-- Please update version.sql too -- this keeps clean builds in sync
define version=50
@update_header

GRANT DELETE ON DONATIONS.SCHEME_DONATION_STATUS TO CSR;

@update_tail
