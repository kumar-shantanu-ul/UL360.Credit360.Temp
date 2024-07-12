-- Please update version.sql too -- this keeps clean builds in sync
define version=2879
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

--csr/db/create_views.sql

CREATE OR REPLACE VIEW csr.v$audit_validity AS
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
	ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
	  FROM csr.internal_audit ia
	  JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	 WHERE ia.deleted = 0;


CREATE OR REPLACE VIEW csr.v$audit_next_due AS
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
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
		  FROM csr.internal_audit
		 WHERE deleted = 0
		   ) ia
	  JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND atct.re_audit_due_after IS NOT NULL
	   AND r.active=1
	   AND ia.audit_closure_type_id IS NOT NULL
	   AND ia.deleted = 0;
   

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
