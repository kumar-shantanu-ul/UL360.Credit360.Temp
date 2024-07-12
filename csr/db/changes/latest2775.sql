-- Please update version.sql too -- this keeps clean builds in sync
define version=2775
define minor_version=0
define is_combined=0
@update_header

CREATE OR REPLACE VIEW CSR.V$AUDIT_CAPABILITY AS
	SELECT ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id,
		   MAX(BITAND(fsrc.permission_set, 1)) + -- security_pkg.PERMISSION_READ
		   MAX(BITAND(fsrc.permission_set, 2)) permission_set -- security_pkg.PERMISSION_WRITE
	  FROM internal_audit ia
	  JOIN flow_item fi ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  JOIN flow_state_role_capability fsrc ON fi.app_sid = fsrc.app_sid AND fi.current_state_id = fsrc.flow_state_id
	  LEFT JOIN region_role_member rrm ON ia.app_sid = rrm.app_sid AND ia.region_sid = rrm.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = fsrc.role_sid
	  LEFT JOIN (
		SELECT fii.flow_involvement_type_id, fii.flow_item_id, fsi.flow_state_id
		  FROM flow_item_involvement fii
		  JOIN flow_state_involvement fsi 
	        ON fsi.flow_involvement_type_id = fii.flow_involvement_type_id
		 WHERE fii.user_sid = SYS_CONTEXT('SECURITY','SID')
		) finv 
		ON finv.flow_item_id = fi.flow_item_id 
	   AND finv.flow_involvement_type_id = fsrc.flow_involvement_type_id 
	   AND finv.flow_state_id = fi.current_state_id
	 WHERE ia.deleted = 0
	   AND ((fsrc.flow_involvement_type_id = 1 -- csr_data_pkg.FLOW_INV_TYPE_AUDITOR
	   AND (ia.auditor_user_sid = SYS_CONTEXT('SECURITY', 'SID')
		OR ia.auditor_user_sid IN (SELECT user_being_covered_sid FROM v$current_user_cover)))
		OR (ia.auditor_company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND fsrc.flow_involvement_type_id = 2)	   -- csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY
	    OR finv.flow_involvement_type_id IS NOT NULL
		OR rrm.role_sid IS NOT NULL
		OR security.security_pkg.SQL_IsAccessAllowedSID(SYS_CONTEXT('SECURITY', 'ACT'), security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits'), 16) = 1) -- security.security_pkg.PERMISSION_TAKE_OWNERSHIP
	 GROUP BY ia.app_sid, ia.internal_audit_sid, fsrc.flow_capability_id;

@..\audit_body


@update_tail
