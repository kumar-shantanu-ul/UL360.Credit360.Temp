-- Please update version.sql too -- this keeps clean builds in sync
define version=3352
define minor_version=3
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
@latestUD7697_packages

DECLARE
	v_issue_log_id			csr.issue_log.issue_log_id%TYPE;
BEGIN
	FOR r IN (
		SELECT issue_id, label, region_sid, due_dtm, host
		  FROM csr.issue i
          JOIN csr.customer c on c.app_sid = i.app_sid
		 WHERE source_url LIKE '/meter%'
		   AND issue_type_id = 20
           AND issue_meter_id IS NULL
	) LOOP
        security.user_pkg.logonadmin(r.host, 60);

		INSERT INTO csr.issue_meter (
			app_sid, issue_meter_id, region_sid, issue_dtm)
		VALUES (
			security.security_pkg.GetAPP, csr.issue_meter_id_seq.NEXTVAL, r.region_sid, r.due_dtm
		);

		UPDATE csr.issue
		   SET issue_meter_id = csr.issue_meter_id_seq.CURRVAL,
			   source_url = NULL
		 WHERE issue_id = r.issue_id;
		 
		csr.temp_issue_pkg.AddLogEntry(security.security_pkg.GetACT, r.issue_id, 1, 'Correct issue_meter_id', null, null, null, v_issue_log_id);
	END LOOP;
END;
/

DROP PACKAGE csr.temp_csr_data_pkg;
DROP PACKAGE csr.temp_audit_pkg;
DROP PACKAGE csr.temp_calc_pkg;
DROP PACKAGE csr.temp_aggregate_ind_pkg;
DROP PACKAGE csr.temp_batch_job_pkg;
DROP PACKAGE csr.temp_issue_pkg;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\meter_pkg
@..\meter_body
@..\issue_body

@update_tail
