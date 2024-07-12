create or replace PACKAGE BODY csr.internal_audit_listener_pkg AS

PROCEDURE GetLastUpdated(
	in_tenant_id				IN	csr.internal_audit_listener_last_update.tenant_id%TYPE,
	in_external_parent_ref		IN	csr.internal_audit_listener_last_update.external_parent_ref%TYPE,
	in_external_ref				IN	csr.internal_audit_listener_last_update.external_ref%TYPE,
	out_cur						OUT SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
	SELECT last_update
	  FROM csr.INTERNAL_AUDIT_LISTENER_LAST_UPDATE
	 WHERE tenant_id = in_tenant_id
	   AND external_parent_ref = in_external_parent_ref
	   AND external_ref = in_external_ref;
END;

PROCEDURE SetLastUpdated(
	in_tenant_id				IN csr.internal_audit_listener_last_update.tenant_id%TYPE,
	in_external_parent_ref		IN csr.internal_audit_listener_last_update.external_parent_ref%TYPE,
	in_external_ref				IN csr.internal_audit_listener_last_update.external_ref%TYPE,
	in_last_updated_dtm			IN csr.internal_audit_listener_last_update.last_update%TYPE,
	in_correlation_id			IN csr.internal_audit_listener_last_update.correlation_id%TYPE
)
AS
BEGIN
	INSERT INTO csr.INTERNAL_AUDIT_LISTENER_LAST_UPDATE (tenant_id, external_parent_ref, external_ref, last_update, correlation_id)
		VALUES (in_tenant_id, in_external_parent_ref, in_external_ref, in_last_updated_dtm, in_correlation_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE csr.INTERNAL_AUDIT_LISTENER_LAST_UPDATE
			   SET last_update = in_last_updated_dtm,
				   correlation_id = in_correlation_id
			 WHERE tenant_id = in_tenant_id 
			   AND external_parent_ref = in_external_parent_ref 
			   AND external_ref = in_external_ref;
END;

END internal_audit_listener_pkg;
/