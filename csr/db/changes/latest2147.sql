-- Please update version.sql too -- this keeps clean builds in sync
define version=2147
@update_header

alter table csr.BATCH_JOB_STRUCTURE_IMPORT modify input varchar2(4000);

@update_tail
