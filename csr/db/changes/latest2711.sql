-- Please update version.sql too -- this keeps clean builds in sync
define version=2711
@update_header

grant delete on chem.substance_process_use_file to csr;
grant delete on chem.subst_process_cas_dest_change to csr;
grant delete on chem.process_cas_default to csr;
grant delete on chem.substance_process_cas_dest to csr;
grant delete on chem.substance_process_use to csr;
grant delete on chem.substance_process_use_change to csr;
grant delete on chem.substance_audit_log to csr;
grant delete on chem.substance_cas to csr;
grant delete on chem.substance_file to csr;
grant delete on chem.substance_region_process to csr;
grant delete on chem.usage_audit_log to csr;
grant delete on chem.waiver to csr;
grant delete on chem.substance to csr;
grant delete on chem.substance_region to csr;

@../csr_app_body

@update_tail
