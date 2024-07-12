define version=2172
@update_header


ALTER TABLE CSR.INTERNAL_AUDIT ADD OVW_VALIDITY_DTM DATE NULL;

--update due date view
CREATE OR REPLACE VIEW csr.v$audit_next_due AS
SELECT ia.internal_audit_sid, ia.internal_audit_type_id, ia.region_sid,
	   ia.audit_dtm previous_audit_dtm, act.audit_closure_type_id, ia.app_sid,
	   CASE (re_audit_due_after_type)
			WHEN 'd' THEN nvl(ovw_validity_dtm, ia.audit_dtm + re_audit_due_after)
			WHEN 'w' THEN nvl(ovw_validity_dtm, ia.audit_dtm + (re_audit_due_after*7))
			WHEN 'm' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after))
			WHEN 'y' THEN nvl(ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, re_audit_due_after*12))
	   END next_audit_due_dtm, act.reminder_offset_days, act.label closure_label,
	   act.is_failure, ia.label previous_audit_label, act.icon_image_filename,
	   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id
  FROM (
	SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
		   ROW_NUMBER() OVER (
				PARTITION BY internal_audit_type_id, region_sid
				ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
		   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, OVW_VALIDITY_DTM
	  FROM csr.internal_audit
	   ) ia
  JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id
   AND ia.app_sid = act.app_sid
  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
 WHERE rn = 1
   AND act.re_audit_due_after IS NOT NULL
   AND r.active=1
   AND ia.audit_closure_type_id IS NOT NULL
   AND ia.deleted = 0;
	
@update_tail