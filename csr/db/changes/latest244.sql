-- Please update version.sql too -- this keeps clean builds in sync
define version=244
@update_header

-- unused
drop table related_val_change;

@update_tail
