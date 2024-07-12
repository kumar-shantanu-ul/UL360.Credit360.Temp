-- Please update version.sql too -- this keeps clean builds in sync
define version=60
@update_header

grant select, references on customer to donations;

@update_tail
