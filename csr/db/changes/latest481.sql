-- Please update version.sql too -- this keeps clean builds in sync
define version=481
@update_header

grant select on egrid to postcode;

@update_tail
