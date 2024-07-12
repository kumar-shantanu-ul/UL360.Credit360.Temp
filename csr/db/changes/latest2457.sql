-- Please update version.sql too -- this keeps clean builds in sync
define version=2457
@update_header

@../dataview_pkg
@../dataview_body
@../indicator_body

@update_tail
