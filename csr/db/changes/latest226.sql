-- Please update version.sql too -- this keeps clean builds in sync
define version=226
@update_header

-- not used any more
drop package league_pkg;

@update_tail
