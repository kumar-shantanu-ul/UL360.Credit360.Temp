/***********************************************************************
v$user_alert_entry_type - used to get alert_entry_type information including app specific overrides AND user overrides
THIS IS AN EXPENSIVE VIEW, USE SPARINGLY
***********************************************************************/
  CREATE OR REPLACE VIEW CHAIN.v$user_alert_entry_type AS
	SELECT vaet.app_sid, 
		   users.csr_user_sid user_sid,
		   users.email,
		   users.friendly_name,
		   vaet.alert_entry_type_id, 
		   vaet.std_alert_type_id,
		   vaet.description, 
		   vaet.generator_sp,
		   NVL(uaet.schedule_xml, vaet.schedule_xml) schedule_xml,
		   DECODE(vaet.force_disable, 0, NVL(uaet.enabled, vaet.enabled), 1, 0) enabled,
		   last_sa.last_sent_alert_dtm,
		   DECODE(last_sa.last_sent_alert_dtm, NULL, NULL, csr.RECURRENCE_PATTERN_pkg.GetNextOccurrence(XmlType(NVL(uaet.schedule_xml, vaet.schedule_xml)), last_sa.last_sent_alert_dtm)) next_alert_dtm
	  FROM chain.v$alert_entry_type vaet
      --JOIN chain.v$chain_user users
	--	ON users.app_sid = SYS_CONTEXT('SECURITY','APP')
	    JOIN csr.v$csr_user users
		  ON users.app_sid = SYS_CONTEXT('SECURITY','APP')
		 AND users.csr_user_sid NOT IN ( SELECT csr_user_sid FROM csr.superadmin )
	  LEFT JOIN chain.user_alert_entry_type uaet
		ON vaet.alert_entry_type_id = uaet.alert_entry_type_id
	   AND users.csr_user_sid = uaet.user_sid
	   AND vaet.app_sid = SYS_CONTEXT('SECURITY','APP')
	  LEFT JOIN ( 
          SELECT sa.user_sid, sa.alert_entry_type_id, sa.sent_dtm last_sent_alert_dtm
            FROM chain.scheduled_alert sa
           WHERE sent_dtm = ( SELECT MAX(sent_dtm) FROM chain.scheduled_alert WHERE app_sid = SYS_CONTEXT('SECURITY','APP') AND user_sid = sa.user_sid AND alert_entry_type_id = sa.alert_entry_type_id)
             AND sa.app_sid = SYS_CONTEXT('SECURITY','APP') ) last_sa
		ON last_sa.user_sid = users.csr_user_sid
	   AND last_sa.alert_entry_type_id = vaet.alert_entry_type_id;

/***********************************************************************
v$audit_request
***********************************************************************/
 CREATE OR REPLACE VIEW CHAIN.V$AUDIT_REQUEST AS
	SELECT ar.app_sid,
		   ar.audit_request_id,
		   ar.auditor_company_sid,
		   cor.name auditor_company_name,
		   ar.auditee_company_sid,
		   cee.name auditee_company_name,
		   ar.requested_by_company_sid,
		   crq.name requested_by_company_name,
		   ar.requested_by_user_sid,
		   cu.full_name requested_by_user_full_name,
		   cu.friendly_name req_by_user_friendly_name,
		   cu.email requested_by_user_email,
		   ar.requested_at_dtm,
		   ar.notes,
		   ar.proposed_dtm,
		   ar.audit_sid,
		   ia.label audit_label,
		   ia.audit_dtm,
		   ia.audit_closure_type_id,
		   act.label audit_closure_type_label
	  FROM chain.audit_request ar
	  JOIN chain.company cor ON cor.company_sid = ar.auditor_company_sid AND cor.app_sid = ar.app_sid
	  JOIN chain.company cee ON cee.company_sid = ar.auditee_company_sid AND cee.app_sid = ar.app_sid
	  JOIN chain.company crq ON crq.company_sid = ar.requested_by_company_sid AND crq.app_sid = ar.app_sid
	  JOIN csr.csr_user cu ON cu.csr_user_sid = ar.requested_by_user_sid AND cu.app_sid = ar.app_sid
	  LEFT JOIN csr.internal_audit ia ON ia.internal_audit_sid = ar.audit_sid AND ia.app_sid = ar.app_sid
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND act.app_sid = ia.app_sid;

