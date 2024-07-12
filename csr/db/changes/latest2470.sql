-- Please update version.sql too -- this keeps clean builds in sync
define version=2470
@update_header

-- this was missed from manual_schema_changes
alter table csr.BATCH_JOB_STRUCTURE_IMPORT modify input varchar2(4000);

@update_tail