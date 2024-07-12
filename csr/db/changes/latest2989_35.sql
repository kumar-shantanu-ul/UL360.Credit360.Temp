-- Please update version.sql too -- this keeps clean builds in sync
define version=2989
define minor_version=35
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$all_audit_validity AS --more basic version of v$audit_next_due that returns all audits carried out and their validity instead of just the most recent of each 	 
	SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	CASE (atct.re_audit_due_after_type)
		WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
		WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
		WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
		WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
		ELSE ia.ovw_validity_dtm
	END next_audit_due_dtm, atct.reminder_offset_days, act.label closure_label,
	act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id, ia.ovw_validity_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	 WHERE ia.deleted = 0;	 
	 
-- /csr/db/create_views.sql
CREATE OR REPLACE VIEW csr.v$audit_validity AS --more restrictive version of v$all_audit_validity that only returns audits that have a validity
	SELECT internal_audit_sid, internal_audit_type_id, region_sid,
	previous_audit_dtm, audit_closure_type_id, app_sid,
    next_audit_due_dtm, reminder_offset_days, closure_label,
	is_failure, previous_audit_label, icon_image_filename,
	previous_auditor_user_sid, flow_item_id
	  FROM v$all_audit_validity ia
	   WHERE (ia.audit_closure_type_id IS NOT NULL OR ia.ovw_validity_dtm IS NOT NULL);


-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_helper_pkg
@../quick_survey_pkg

@../audit_helper_body
@../quick_survey_body
@../flow_body
@update_tail
