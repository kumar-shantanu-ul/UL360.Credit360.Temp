define version=3242
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

INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (90, 'Compliance item export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (90, 'Compliance item export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemExporter');
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (91, 'Compliance item variant export', 'batch-exporter', 0, 'support@credit360.com', 3, 120);
INSERT INTO csr.batched_export_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (91, 'Compliance item variant export', 'Credit360.ExportImport.Export.Batched.Exporters.ComplianceItemVariantExporter');

@..\flow_pkg
@..\compliance_pkg

@..\flow_body
@..\compliance_body
@..\csr_app_body

@update_tail
