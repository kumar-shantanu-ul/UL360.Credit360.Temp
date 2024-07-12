-- Please update version.sql too -- this keeps clean builds in sync
define version=2459
@update_header

@../calc_body.sql
@../indicator_pkg.sql
@../indicator_body.sql

@update_tail

