-- Please update version.sql too -- this keeps clean builds in sync
define version=2747
define minor_version=8
@update_header

@..\chain\company_filter_body

@update_tail
