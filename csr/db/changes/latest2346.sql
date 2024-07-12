-- Please update version.sql too -- this keeps clean builds in sync
define version=2346
@update_header

alter table CSR.SHEET_DATE_SCHEDULE drop constraint CK_SUBMISSION_DTM;

@update_tail
