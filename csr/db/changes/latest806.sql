-- Please update version.sql too -- this keeps clean builds in sync
define version=806
@update_header

alter table csr.temp_delegation_detail add child_sheet_colour varchar2(1);

@..\delegation_body

@update_tail