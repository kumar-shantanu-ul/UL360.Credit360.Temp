-- Please update version.sql too -- this keeps clean builds in sync
define version=341
@update_header

-- Just in case it all goes horribly wrong.

CREATE TABLE csr.pending_dataset_backup AS SELECT * FROM csr.pending_dataset;
CREATE TABLE csr.approval_step_backup AS SELECT * FROM csr.approval_step;
CREATE TABLE csr.pending_ind_backup AS SELECT * FROM csr.pending_ind;
CREATE TABLE csr.pending_period_backup AS SELECT * FROM csr.pending_period;
CREATE TABLE csr.pending_region_backup AS SELECT * FROM csr.pending_region;
CREATE TABLE csr.pvc_region_recalc_job_backup AS SELECT * FROM csr.pvc_region_recalc_job;
CREATE TABLE csr.pvc_stored_calc_job_backup AS SELECT * FROM csr.pvc_stored_calc_job;

-- We'll need these later.

--DROP TABLE csr.pending_dataset_backup;
--DROP TABLE csr.approval_step_backup;
--DROP TABLE csr.pending_ind_backup;
--DROP TABLE csr.pending_period_backup;
--DROP TABLE csr.pending_region_backup;
--DROP TABLE csr.pvc_region_recalc_job_backup;
--DROP TABLE csr.pvc_stored_calc_job_backup;

-- Counts to provide a sanity check. Before and after should be the same!

SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_dataset GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.approval_step GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_ind GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_period GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_region GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pvc_region_recalc_job GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pvc_stored_calc_job GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;

-- Update pending_dataset_id values to securable objects. pending_dataset.new_sid already contains a valid securable object for each dataset. If a new dataset has been added, it will
-- have taken a new SID for its pending_dataset_id and new_sid will be null to indicate that the ID doesn't need updating.

ALTER TABLE csr.approval_step DISABLE CONSTRAINT refpending_dataset497 KEEP INDEX;
ALTER TABLE csr.pending_ind DISABLE CONSTRAINT refpending_dataset476 KEEP INDEX;
ALTER TABLE csr.pending_period DISABLE CONSTRAINT refpending_dataset479 KEEP INDEX;
ALTER TABLE csr.pending_region DISABLE CONSTRAINT refpending_dataset481 KEEP INDEX;
ALTER TABLE csr.pvc_region_recalc_job DISABLE CONSTRAINT refpending_dataset722 KEEP INDEX;
ALTER TABLE csr.pvc_stored_calc_job DISABLE CONSTRAINT refpending_dataset725 KEEP INDEX;

-- This only works because the securable object ID sequence is way ahead of the old pending dataset ID sequence. (i.e. There is no chance of new_sid being an existing pending_dataset_id.)

UPDATE csr.pvc_stored_calc_job SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pvc_stored_calc_job.pending_dataset_id AND app_sid = pvc_stored_calc_job.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pvc_stored_calc_job.pending_dataset_id AND app_sid = pvc_stored_calc_job.app_sid) IS NOT NULL;
UPDATE csr.pvc_region_recalc_job SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pvc_region_recalc_job.pending_dataset_id AND app_sid = pvc_region_recalc_job.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pvc_region_recalc_job.pending_dataset_id AND app_sid = pvc_region_recalc_job.app_sid) IS NOT NULL;
UPDATE csr.pending_region SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_region.pending_dataset_id AND app_sid = pending_region.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_region.pending_dataset_id AND app_sid = pending_region.app_sid) IS NOT NULL;
UPDATE csr.pending_period SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_period.pending_dataset_id AND app_sid = pending_period.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_period.pending_dataset_id AND app_sid = pending_period.app_sid) IS NOT NULL;
UPDATE csr.pending_ind SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_ind.pending_dataset_id AND app_sid = pending_ind.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = pending_ind.pending_dataset_id AND app_sid = pending_ind.app_sid) IS NOT NULL;
UPDATE csr.approval_step SET pending_dataset_id = (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = approval_step.pending_dataset_id AND app_sid = approval_step.app_sid) WHERE (SELECT new_sid FROM csr.pending_dataset WHERE pending_dataset_id = approval_step.pending_dataset_id AND app_sid = approval_step.app_sid) IS NOT NULL;
UPDATE csr.pending_dataset SET pending_dataset_id = new_sid, new_sid = NULL WHERE new_sid IS NOT NULL;

COMMIT;

-- This is the quickest way or re-enabling the constraints (and doesn't take locks).

ALTER TABLE csr.approval_step ENABLE NOVALIDATE CONSTRAINT refpending_dataset497;
ALTER TABLE csr.pending_ind ENABLE NOVALIDATE CONSTRAINT refpending_dataset476;
ALTER TABLE csr.pending_period ENABLE NOVALIDATE CONSTRAINT refpending_dataset479;
ALTER TABLE csr.pending_region ENABLE NOVALIDATE CONSTRAINT refpending_dataset481;
ALTER TABLE csr.pvc_region_recalc_job ENABLE NOVALIDATE CONSTRAINT refpending_dataset722;
ALTER TABLE csr.pvc_stored_calc_job ENABLE NOVALIDATE CONSTRAINT refpending_dataset725;

ALTER TABLE csr.approval_step ENABLE VALIDATE CONSTRAINT refpending_dataset497;
ALTER TABLE csr.pending_ind ENABLE VALIDATE CONSTRAINT refpending_dataset476;
ALTER TABLE csr.pending_period ENABLE VALIDATE CONSTRAINT refpending_dataset479;
ALTER TABLE csr.pending_region ENABLE VALIDATE CONSTRAINT refpending_dataset481;
ALTER TABLE csr.pvc_region_recalc_job ENABLE VALIDATE CONSTRAINT refpending_dataset722;
ALTER TABLE csr.pvc_stored_calc_job ENABLE VALIDATE CONSTRAINT refpending_dataset725;

SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_dataset GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.approval_step GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_ind GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_period GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pending_region GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pvc_region_recalc_job GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;
SELECT app_sid, pending_dataset_id, COUNT(*) FROM csr.pvc_stored_calc_job GROUP BY app_sid, pending_dataset_id ORDER BY app_sid, pending_dataset_id;

@update_tail
