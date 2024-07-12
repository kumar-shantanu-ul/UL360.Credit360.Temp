-- Please update version.sql too -- this keeps clean builds in sync
define version=1649
@update_header

@../chain/company_filter_body
@../help_body
@../quick_survey_body
@../section_body
@../supplier_body

@update_tail
