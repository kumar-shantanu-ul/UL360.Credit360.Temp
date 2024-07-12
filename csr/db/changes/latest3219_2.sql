-- Please update version.sql too -- this keeps clean builds in sync
define version=3219
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

INSERT INTO chem.usage_audit_log (app_sid, changed_by, changed_dtm, description, end_dtm, param_1, param_2, region_sid, root_delegation_sid, start_dtm, substance_id, usage_audit_log_id)
SELECT app_sid, changed_by, changed_dtm, 'Copied forward substance {0}', end_dtm, NULL, NULL, region_sid, root_delegation_sid, start_dtm, substance_id, chem.usage_audit_log_id_seq.NEXTVAL
  FROM (
	SELECT app_sid, changed_by, changed_dtm, end_dtm, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, retired_dtm,
		LAG(mass_value, 1) OVER (ORDER BY substance_id, region_sid, root_delegation_sid, start_dtm, changed_dtm) AS mass_value_prev
	  FROM chem.substance_process_use_change
) c
WHERE c.mass_value IS NULL
AND c.mass_value_prev IS NOT NULL
AND NOT EXISTS (
	SELECT NULL
	  FROM chem.usage_audit_log l
	 WHERE l.substance_id = c.substance_id
	   AND l.region_sid = c.region_sid
	   AND l.start_dtm = c.start_dtm
	   AND l.end_dtm = c.end_dtm
	   AND l.root_delegation_sid = c.root_delegation_sid
	   AND l.changed_dtm = c.changed_dtm
);

INSERT INTO chem.usage_audit_log (app_sid, changed_by, changed_dtm, description, end_dtm, param_1, param_2, region_sid, root_delegation_sid, start_dtm, substance_id, usage_audit_log_id)
SELECT app_sid, changed_by, changed_dtm, 'Chemical consumption changed for {0} from {1}kg to {2}kg', end_dtm, mass_value_prev, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, chem.usage_audit_log_id_seq.NEXTVAL
  FROM (
	SELECT app_sid, changed_by, changed_dtm, end_dtm, mass_value, region_sid, root_delegation_sid, start_dtm, substance_id, retired_dtm,
		LAG(mass_value, 1, -1) OVER (ORDER BY substance_id, region_sid, root_delegation_sid, start_dtm, changed_dtm) AS mass_value_prev
	  FROM chem.substance_process_use_change
) c
WHERE DECODE(c.mass_value_prev, -1, 0, 1) = 1 
AND c.mass_value IS NOT NULL
AND NOT EXISTS (
	SELECT NULL
	  FROM chem.usage_audit_log l
	 WHERE l.substance_id = c.substance_id
	   AND l.region_sid = c.region_sid
	   AND l.start_dtm = c.start_dtm
	   AND l.end_dtm = c.end_dtm
	   AND l.root_delegation_sid = c.root_delegation_sid
	   AND l.changed_dtm = c.changed_dtm
);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../chem/audit_body
@../chem/substance_body
@../chem/substance_helper_body

@update_tail
