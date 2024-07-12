-- Please update version.sql too -- this keeps clean builds in sync
define version=1043
@update_header

alter table csr.scenario drop constraint ck_auto_update_runs;
alter table csr.scenario add CONSTRAINT CK_AUTO_UPDATE_RUNS CHECK 
((auto_update = 0 and auto_update_merged_run_sid is null and auto_update_unmerged_run_sid is null) or 
 (auto_update = 1 and (auto_update_merged_run_sid is not null or auto_update_unmerged_run_sid is not null)));

@update_tail
