-- Please update version.sql too -- this keeps clean builds in sync
define version=807
@update_header

alter table csr.temp_delegation_detail drop column child_sheet_colour;

@..\delegation_body

@update_tail