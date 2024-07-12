-- Please update version.sql too -- this keeps clean builds in sync
define version=428
@update_header

update model_sheet set sheet_index = sheet_index - 1;

@update_tail
