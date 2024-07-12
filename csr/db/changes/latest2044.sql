-- Please update version.sql too -- this keeps clean builds in sync
define version=2044
@update_header

ALTER TABLE csrimp.scenario
DROP CONSTRAINT CK_AUTO_UPDATE_RUNS;

ALTER TABLE csrimp.scenario
ADD auto_update_unmergedlp_run_sid NUMBER(10, 0);

ALTER TABLE csrimp.scenario
ADD CONSTRAINT
CK_AUTO_UPDATE_RUNS CHECK ((auto_update = 0 and auto_update_merged_run_sid is null and auto_update_unmerged_run_sid is null and auto_update_unmergedlp_run_sid is null) or 
 (auto_update = 1 and (auto_update_merged_run_sid is not null or auto_update_unmerged_run_sid is not null or auto_update_unmergedlp_run_sid is not null)));

@..\csrimp\imp_body

@update_tail
