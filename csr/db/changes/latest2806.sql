-- Please update version.sql too -- this keeps clean builds in sync
define version=2806
define minor_version=0
define is_combined=0
@update_header

@../measure_pkg
@../measure_body
@../sheet_body

@update_tail
