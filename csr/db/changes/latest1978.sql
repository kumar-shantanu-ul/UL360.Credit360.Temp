-- Please update version.sql too -- this keeps clean builds in sync
define version=1978
@update_header

GRANT SELECT ON security.sessionstate TO chain;

@../chain/filter_body

@update_tail
