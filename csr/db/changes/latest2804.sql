-- Please update version.sql too -- this keeps clean builds in sync
define version=2804
define minor_version=0
define is_combined=0
@update_header

@../chain/company_filter_body

@update_tail
