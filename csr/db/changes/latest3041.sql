-- Please update version.sql too -- this keeps clean builds in sync
define version=3041
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
UPDATE csr.deleg_plan dp
   SET (last_applied_dynamic) = (
      SELECT is_dynamic_plan
        FROM csr.deleg_plan_job dpj
       WHERE batch_job_id IN (
            SELECT MAX(batch_job_id)
             FROM csr.deleg_plan_job
            GROUP BY deleg_plan_sid
         )
         AND dp.deleg_plan_sid = dpj.deleg_plan_sid
   )
 WHERE dp.last_applied_dynamic IS NULL
   AND EXISTS (
       SELECT 1
         FROM csr.deleg_plan_job dpj2
        WHERE dpj2.deleg_plan_sid = dp.deleg_plan_sid
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
