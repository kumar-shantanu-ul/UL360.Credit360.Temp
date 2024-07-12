create or replace PACKAGE csr.internal_audit_listener_pkg AS

PROCEDURE GetLastUpdated(
	in_tenant_id				IN	csr.internal_audit_listener_last_update.tenant_id%TYPE,
	in_external_parent_ref		IN	csr.internal_audit_listener_last_update.external_parent_ref%TYPE,
	in_external_ref				IN	csr.internal_audit_listener_last_update.external_ref%TYPE,
	out_cur						OUT SYS_REFCURSOR
);

PROCEDURE SetLastUpdated(
	in_tenant_id				IN csr.internal_audit_listener_last_update.tenant_id%TYPE,
	in_external_parent_ref		IN csr.internal_audit_listener_last_update.external_parent_ref%TYPE,
	in_external_ref				IN csr.internal_audit_listener_last_update.external_ref%TYPE,
	in_last_updated_dtm			IN csr.internal_audit_listener_last_update.last_update%TYPE,
	in_correlation_id			IN csr.internal_audit_listener_last_update.correlation_id%TYPE
);

END internal_audit_listener_pkg;
/