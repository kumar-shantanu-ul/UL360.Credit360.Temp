-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=47
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***
grant select, insert, update, delete on csrimp.chain_certification to tool_user;
grant select, insert, update, delete on csrimp.chain_cert_aud_type to tool_user;
-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
--csr/db/chain/create_views.sql
CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_id, ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.certification_audit_type cat 
	JOIN csr.internal_audit ia ON ia.internal_audit_type_id = cat.internal_audit_type_id
	 AND cat.app_sid = ia.app_sid
	 AND ia.deleted = 0
	JOIN csr.supplier s  ON ia.region_sid = s.region_sid AND s.app_sid = ia.app_sid
	LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id 
	 AND ia.internal_audit_type_id = atct.internal_audit_type_id
	 AND ia.app_sid = atct.app_sid
	LEFT JOIN csr.audit_closure_type act ON atct.audit_closure_type_id = act.audit_closure_type_id 
	 AND act.app_sid = atct.app_sid
   WHERE NVL(act.is_failure, 0) = 0
	 AND (ia.flow_item_id IS NULL 
	  OR EXISTS(
			SELECT fi.flow_item_id 
			  FROM csr.flow_item fi 
			  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.is_final = 1 
			 WHERE fi.flow_item_id = ia.flow_item_id));

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
