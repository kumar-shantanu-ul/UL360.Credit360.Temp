-- Please update version.sql too -- this keeps clean builds in sync
define version=2043
@update_header

ALTER TABLE csr.scenario
DROP CONSTRAINT CK_AUTO_UPDATE_RUNS;

ALTER TABLE csr.scenario
ADD auto_update_unmergedlp_run_sid NUMBER(10, 0);

ALTER TABLE csr.scenario
ADD CONSTRAINT
CK_AUTO_UPDATE_RUNS CHECK ((auto_update = 0 and auto_update_merged_run_sid is null and auto_update_unmerged_run_sid is null and auto_update_unmergedlp_run_sid is null) or 
 (auto_update = 1 and (auto_update_merged_run_sid is not null or auto_update_unmerged_run_sid is not null or auto_update_unmergedlp_run_sid is not null)));

ALTER TABLE csr.calc_job
DROP CONSTRAINT CK_CALC_JOB_DATA_SOURCE;

ALTER TABLE csr.calc_job
ADD CONSTRAINT CK_CALC_JOB_DATA_SOURCE CHECK (DATA_SOURCE IN (0,1,2,4)); -- was (0,1,2)

@..\stored_calc_datasource_pkg
@..\stored_calc_datasource_body
@..\scenario_body

@update_tail
