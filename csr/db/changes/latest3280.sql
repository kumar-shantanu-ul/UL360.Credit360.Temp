define version=3280
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/








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
		   ia.auditor_user_sid previous_auditor_user_sid, ia.flow_item_id,
		   cast(act.icon_image_sha1 as VARCHAR2(40)) icon_image_sha1
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
		  FROM csr.internal_audit
		 WHERE deleted = 0
		   ) ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
	 WHERE rn = 1
	   AND r.active=1
	   AND ia.deleted = 0
       AND CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm
		   END IS NOT NULL;




UPDATE csr.audit_alert 
   SET overdue_sent_dtm = DATE '2020-01-01'
 WHERE INTERNAL_AUDIT_SID in (
SELECT ia.internal_audit_sid
	  FROM (
		SELECT internal_audit_sid, internal_audit_type_id, region_sid, audit_dtm,
			   ROW_NUMBER() OVER (
					PARTITION BY internal_audit_type_id, region_sid
					ORDER BY audit_dtm DESC) rn, -- take most recent audit of each type/region
			   audit_closure_type_id, app_sid, label, auditor_user_sid, flow_item_id, deleted, ovw_validity_dtm
		  FROM csr.internal_audit
		 WHERE deleted = 0
		   ) ia
	  LEFT JOIN csr.audit_type_closure_type atct
		ON ia.audit_closure_type_id = atct.audit_closure_type_id
	   AND ia.app_sid = atct.app_sid
	   AND ia.internal_audit_type_id = atct.internal_audit_type_id
	  LEFT JOIN csr.audit_closure_type act
		ON atct.audit_closure_type_id = act.audit_closure_type_id
	   AND atct.app_sid = act.app_sid
	  JOIN csr.region r ON ia.region_sid = r.region_sid AND ia.app_sid = r.app_sid
      LEFT JOIN csr.audit_alert aa ON ia.internal_audit_sid = aa.internal_audit_sid AND ia.app_sid = aa.app_sid
	 WHERE rn = 1
	   AND r.active=1
	   AND ia.deleted = 0
       AND CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm
		   END <= DATE '2020-01-01'
       )
   AND overdue_sent_dtm IS NULL;






@..\period_pkg
@..\stored_calc_datasource_pkg
@..\audit_pkg
@..\branding_pkg


@..\period_body
@..\stored_calc_datasource_body
@..\audit_body
@..\quick_survey_body
@..\branding_body



@update_tail
