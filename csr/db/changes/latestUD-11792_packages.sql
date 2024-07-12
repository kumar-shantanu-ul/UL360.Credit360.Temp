------------ csr.temp_audit_pkg --------------------------

CREATE OR REPLACE PACKAGE csr.temp_audit_pkg IS

FUNCTION AreAllAuditsInTrash(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
) RETURN BOOLEAN;

PROCEDURE DeleteAuditTypeClosureType(
	in_internal_audit_type_id	IN	audit_type_closure_type.internal_audit_type_id%TYPE,
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE
);

PROCEDURE DeleteInternalAuditType(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
);

END temp_audit_pkg;
/

CREATE OR REPLACE PACKAGE BODY csr.temp_audit_pkg IS

FUNCTION AreAllAuditsInTrash(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
)
RETURN BOOLEAN
AS
	v_count	NUMBER;
BEGIN
	FOR r IN (
		SELECT 1
		  FROM internal_audit
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND deleted = 0
		   AND app_sid = security_pkg.GetApp
	) LOOP
		RETURN FALSE;
	END LOOP;

	RETURN TRUE;
END;

PROCEDURE DeleteAuditTypeClosureType(
	in_internal_audit_type_id	IN	audit_type_closure_type.internal_audit_type_id%TYPE,
	in_audit_closure_type_id	IN	audit_closure_type.audit_closure_type_id%TYPE
)
AS
	v_audits_sid				security.security_pkg.T_SID_ID;
BEGIN
	v_audits_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

	IF NOT security.security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security.security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
	END IF;

	DELETE FROM audit_type_closure_type
	 WHERE internal_audit_type_id = in_internal_audit_type_id
	   AND audit_closure_type_id = in_audit_closure_type_id
	   AND app_sid = security.security_pkg.GetApp;
END;

PROCEDURE DeleteTrashedAudits(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
)
AS
BEGIN
	FOR r IN
	(
		SELECT internal_audit_sid
		  FROM internal_audit a
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND deleted = 1
		   AND app_sid = security_pkg.GetApp
	)
	LOOP
		securableobject_pkg.DeleteSO(security_pkg.GetAct, r.internal_audit_sid);
	END LOOP;
END;

PROCEDURE DeleteInternalAuditType(
	in_internal_audit_type_id	IN	internal_audit_type.internal_audit_type_id%TYPE
)
AS
	v_audits_sid				security_pkg.T_SID_ID;
BEGIN
	v_audits_sid := securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'Audits');

	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetAct, v_audits_sid, security_pkg.PERMISSION_TAKE_OWNERSHIP) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Cannot update internal audit types');
	END IF;

	IF AreAllAuditsInTrash(in_internal_audit_type_id) THEN
		FOR r IN (
			SELECT audit_closure_type_id
			  FROM audit_type_closure_type
			 WHERE internal_audit_type_id = in_internal_audit_type_id
			   AND app_sid = security_pkg.GetApp
		) LOOP
			DeleteAuditTypeClosureType(in_internal_audit_type_id, r.audit_closure_type_id);
		END LOOP;

		DELETE FROM audit_type_expiry_alert_role
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM audit_type_tab
		 WHERE internal_audit_type_id = in_internal_audit_type_id
			AND app_sid = security_pkg.GetApp;

		DELETE FROM audit_type_header
		 WHERE internal_audit_type_id = in_internal_audit_type_id
			AND app_sid = security_pkg.GetApp;

		DELETE FROM non_comp_type_audit_type
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM non_comp_type_rpt_audit_type
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM flow_state_audit_ind
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM internal_audit_type_carry_fwd
		 WHERE (
				from_internal_audit_type_id = in_internal_audit_type_id OR
				to_internal_audit_type_id = in_internal_audit_type_id
		 ) AND app_sid = security_pkg.GetApp;

		DeleteTrashedAudits(in_internal_audit_type_id);

		DELETE FROM internal_audit_type_survey
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM internal_audit_type_report
		 WHERE internal_audit_type_id = in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;

		DELETE FROM internal_audit_type
		 WHERE internal_audit_type_id=in_internal_audit_type_id
		   AND app_sid = security_pkg.GetApp;
	ELSE
		RAISE_APPLICATION_ERROR(csr_data_pkg.ERR_AUDIT_TYPE_AUDIT_EXISTS, 'Audit type: '||in_internal_audit_type_id||' cannot be deleted, because there are undeleted audits with this type!');
	END IF;
END;

END temp_audit_pkg;
/
