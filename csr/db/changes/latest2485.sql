-- Please update version.sql too -- this keeps clean builds in sync
define version=2485
@update_header

@../../../Yam/db/webmail_body.sql

@update_tail
