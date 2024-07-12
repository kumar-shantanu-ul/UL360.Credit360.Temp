-- Please update version.sql too -- this keeps clean builds in sync
define version=2150
@update_header

@../chain/component_report_pkg
@../chain/component_report_body

@update_tail