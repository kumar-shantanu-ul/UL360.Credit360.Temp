-- Please update version.sql too -- this keeps clean builds in sync
define version=2050
@update_header

-- new columns
ALTER TABLE csr.scenario
  ADD auto_update_run_sid	NUMBER(10);

ALTER TABLE csr.scenario
  ADD recalc_trigger_type	NUMBER(10);

ALTER TABLE csr.scenario
  ADD data_source			NUMBER(10);

-- FK
ALTER TABLE CSR.scenario ADD CONSTRAINT FK_SCENARIO_AURS_SCENARIO_RUN
	FOREIGN KEY (APP_SID, AUTO_UPDATE_RUN_SID)
	REFERENCES CSR.SCENARIO_RUN(APP_SID, SCENARIO_RUN_SID)
;

-- constraints
ALTER TABLE csr.scenario ADD CONSTRAINT CK_SCENARIO_RECALC_TRIG_TYPE
CHECK (recalc_trigger_type IN (0, 1));

ALTER TABLE csr.scenario ADD CONSTRAINT CK_SCENARIO_DATA_SOURCE
CHECK (data_source IN (0, 1, 2));

-- move data to new columns
UPDATE csr.scenario
   SET auto_update_run_sid = NVL(auto_update_merged_run_sid, auto_update_unmerged_run_sid),
       recalc_trigger_type =
		CASE WHEN auto_update_merged_run_sid IS NOT NULL THEN 0
			WHEN auto_update_unmerged_run_sid IS NOT NULL THEN 1
			ELSE NULL
		END,
       data_source =
		CASE WHEN auto_update_merged_run_sid IS NOT NULL THEN 0
			WHEN auto_update_unmerged_run_sid IS NOT NULL THEN 1
			ELSE 0
		END;

-- didn't exist on live but is in the schema so should have done
ALTER TABLE csr.scenario
 DROP CONSTRAINT CK_AUTO_UPDATE_RUNS;

ALTER TABLE csr.scenario
 DROP CONSTRAINT CK_SCENARIO_AUTO_UPDATE;

ALTER TABLE csr.scenario
 DROP CONSTRAINT FK_SCN_MERGED_RUN_SCN_RUN;

ALTER TABLE csr.scenario
 DROP CONSTRAINT FK_SCN_UNMERGED_RUN_SCN_RUN;

ALTER TABLE csr.scenario
 DROP (auto_update, auto_update_merged_run_sid, auto_update_unmerged_run_sid, auto_update_unmergedlp_run_sid);

-- calc_job
ALTER TABLE csr.calc_job
  ADD calc_job_type	NUMBER(10);

ALTER TABLE csr.calc_job
 DROP CONSTRAINT UK_CALC_JOB DROP INDEX;

ALTER TABLE csr.calc_job
  ADD CONSTRAINT UK_CALC_JOB  UNIQUE (APP_SID, CALC_JOB_TYPE, SCENARIO_RUN_SID, PROCESSING);

ALTER TABLE csr.calc_job
 DROP COLUMN data_source;

CREATE OR REPLACE VIEW csr.v$calc_job AS
	SELECT cj.app_sid, c.host, cj.calc_job_id, cj.calc_job_type, cj.scenario_run_sid, cj.processing, cj.start_dtm, cj.end_dtm, cj.last_attempt_dtm,
		   cj.phase, cjp.description phase_description, cj.work_done, cj.total_work, cj.updated_dtm, cj.running_on
	  FROM csr.calc_job cj, csr.calc_job_phase cjp, csr.customer c
	 WHERE cj.phase = cjp.phase
	   AND cj.app_sid = c.app_sid;

-- equivalent changes for csrimp
ALTER TABLE csrimp.scenario
  ADD auto_update_run_sid	NUMBER(10);

ALTER TABLE csrimp.scenario
  ADD recalc_trigger_type	NUMBER(10);

ALTER TABLE csrimp.scenario
  ADD data_source			NUMBER(10);

-- seems to be missing
ALTER TABLE csrimp.scenario
  ADD file_based			NUMBER(1);

ALTER TABLE csrimp.scenario
 DROP (auto_update, auto_update_merged_run_sid, auto_update_unmerged_run_sid, auto_update_unmergedlp_run_sid);

-- no need to csrimp calc_job

GRANT EXECUTE ON csr.stored_calc_datasource_pkg TO actions;

@../stored_calc_datasource_pkg
@../stored_calc_datasource_body
@../region_body
@../scenario_body
@../csr_data_body
@../system_status_body
@../actions/scenario_body
@../schema_body
@../csrimp/imp_body

@update_tail
