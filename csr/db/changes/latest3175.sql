define version=3175
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


drop sequence aspen2.profile_id_seq;
drop table aspen2.profile_step;
drop table aspen2.profile;
drop package aspen2.profile_pkg;










BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
	VALUES (81, 'Batch Company Geocode', 'chain-company-geocode', 1, 'support@credit360.com', 3, 120);
	INSERT INTO csr.util_script (util_script_id,util_script_name,description,util_script_sp,wiki_article) VALUES (52, 'Geotag companies', 'Geotag all companies that have some address data besides country and do not currently have a location specified. Note this will use part of our monthly mapquest transaction allowance (even in test environments).', 'GeotagCompanies', NULL);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
DECLARE 
	v_cnt NUMBER(10) := 0;
BEGIN
	FOR r IN (
		SELECT app_sid, compliance_item_id 
		  FROM csr.compliance_item
		 WHERE reference_code IS NULL
	) 
	LOOP 
		v_cnt := v_cnt +1;
		UPDATE csr.compliance_item
		   SET reference_code = 'AUTO_GEN_REF_' || v_cnt
		 WHERE app_sid = r.app_sid
		   AND compliance_item_id = r.compliance_item_id;
	END LOOP;
END;
/
ALTER TABLE csr.compliance_item MODIFY (reference_code NOT NULL);
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, in_order, notify_address, max_retries, timeout_mins)
VALUES (82, 'Compliance item import', 'batch-importer', 0, 'support@credit360.com', 3, 120);
	
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (82, 'Compliance item import', 'Credit360.ExportImport.Batched.Import.Importers.ComplianceItemImporter');






@..\indicator_api_pkg
@..\batch_job_pkg
@..\util_script_pkg
@..\chain\company_pkg
@..\compliance_pkg
@..\flow_pkg


@..\indicator_api_body
@..\tag_body
@..\chain\company_body
@..\chain\company_product_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body
@..\permit_body
@..\chain\helper_body
@..\csr_user_body
@..\supplier_body
@..\teamroom_body
@..\util_script_body
@..\compliance_body
@..\flow_body
@..\factor_body
@..\compliance_library_report_body



@update_tail
