-- Please update version.sql too -- this keeps clean builds in sync
define version=3358
define minor_version=1
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
DECLARE
	v_app_sid		security.security_pkg.T_SID_ID;
	v_score_type_id security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin();
	FOR r IN (
		SELECT app_sid, internal_audit_type_id
		  FROM csr.internal_audit_type
		 WHERE lookup_key IN ('RBA_INITIAL_AUDIT', 'RBA_CLOSURE_AUDIT', 'RBA_PRIORITY_CLOSURE_AUDIT')
		 ORDER BY app_sid
	) LOOP
		IF r.app_sid != v_app_sid THEN 
			security.user_pkg.logonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 600, r.app_sid, security.security_pkg.GetAct);
			
			INSERT INTO csr.score_type
			(score_type_id, label, pos, hidden, allow_manual_set, lookup_key, reportable_months, format_mask, applies_to_audits)
			VALUES
			(csr.score_type_id_seq.nextval, 'Score', 1, 0, 0, 'RBA_AUDIT_SCORE', 24, '##0.00', 1)
			RETURNING score_type_id INTO v_score_type_id;
		END IF;	
		
		INSERT INTO csr.score_type_audit_type
		(score_type_id, internal_audit_type_id)
		VALUES
		(v_score_type_id, r.internal_audit_type_id);
	END LOOP:
	security.user_pkg.logonadmin();
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../quick_survey_pkg

@../audit_body
@../audit_report_body
@../enable_body
@../quick_survey_body

@update_tail
