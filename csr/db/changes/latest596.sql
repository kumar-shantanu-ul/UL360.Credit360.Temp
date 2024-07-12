-- Please update version.sql too -- this keeps clean builds in sync
define version=596
@update_header

alter table csr.model add data_source_options varchar2(255) null;

@..\model_pkg
@..\model_body

@update_tail
