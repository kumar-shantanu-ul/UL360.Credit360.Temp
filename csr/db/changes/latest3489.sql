define version=3489
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE OR REPLACE TYPE CSR.T_REGIONS AS TABLE OF CSR.T_REGION;
/


ALTER TABLE csr.ind ADD (
    TOLERANCE_NUMBER_OF_PERIODS  NUMBER(10, 0),
    TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE    NUMBER(10, 0)
);
ALTER TABLE csrimp.ind ADD (
    TOLERANCE_NUMBER_OF_PERIODS  NUMBER(10, 0),
    TOLERANCE_NUMBER_OF_STANDARD_DEVIATIONS_FROM_AVERAGE    NUMBER(10, 0)
);






create or replace view csr.v$ind as
	select i.app_sid, i.ind_sid, i.parent_sid, i.name, id.description, i.ind_type, i.tolerance_type,
		   i.pct_upper_tolerance, i.pct_lower_tolerance, 
		   i.tolerance_number_of_periods, i.tolerance_number_of_standard_deviations_from_average,
		   i.measure_sid, i.multiplier, i.scale,
		   i.format_mask, i.last_modified_dtm, i.active, i.target_direction, i.pos, i.info_xml,
		   i.start_month, i.divisibility, i.null_means_null, i.aggregate, i.period_set_id, i.period_interval_id,
		   i.calc_start_dtm_adjustment, i.calc_end_dtm_adjustment, i.calc_fixed_start_dtm,
		   i.calc_fixed_end_dtm, i.calc_xml, i.gri, i.lookup_key, i.owner_sid,
		   i.ind_activity_type_id, i.core, i.roll_forward, i.factor_type_id, i.map_to_ind_sid,
		   i.gas_measure_sid, i.gas_type_id, i.calc_description, i.normalize,
		   i.do_temporal_aggregation, i.prop_down_region_tree_sid, i.is_system_managed,
		   i.calc_output_round_dp
	  from ind i, ind_description id
	 where id.app_sid = i.app_sid and i.ind_sid = id.ind_sid
	   and id.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');




INSERT INTO csr.capability (name, allow_by_default, description) VALUES ('Enable multi frequency variance options', 0, 'Delegations:  Enables new multi frequency variance options on delegations');
UPDATE csr.user_profile up
SET email_address = CONCAT(up.csr_user_sid, '@credit360.com')
WHERE EXISTS(
    SELECT 1
      FROM csr.csr_user cu
     WHERE up.csr_user_sid = cu.csr_user_sid
       AND cu.anonymised = 1
);
UPDATE csr.csr_user
SET email = CONCAT(csr_user_sid, '@credit360.com')
WHERE anonymised = 1;
UPDATE csr.csr_user
SET send_alerts = 0
WHERE anonymised = 1;
MERGE INTO security.securable_object so USING(
    SELECT cu.csr_user_sid, cu.user_name
      FROM csr.csr_user cu
      LEFT JOIN csr.trash t
        ON cu.csr_user_sid = t.trash_sid
      LEFT JOIN csr.superadmin sa
        ON cu.csr_user_sid = sa.csr_user_sid
     WHERE cu.anonymised = 1
       AND t.trash_sid IS NULL
       AND sa.csr_user_sid IS NULL
) src ON (so.sid_id = src.csr_user_sid)
WHEN MATCHED THEN UPDATE SET so.name = src.user_name;
MERGE INTO csr.trash t USING(
    SELECT cu.user_name, so.sid_id
      FROM security.securable_object so
      JOIN csr.csr_user cu
        ON cu.csr_user_sid = so.sid_id
     WHERE cu.anonymised = 1
) src ON (t.trash_sid = src.sid_id)
WHEN MATCHED THEN UPDATE SET t.so_name = src.user_name, t.description = src.user_name;
DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_app_sid						security.security_pkg.T_SID_ID;
	v_groups_sid					security.security_pkg.T_SID_ID;
	v_admins	 					security.security_pkg.T_SID_ID;
	v_exportimport_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_imports_container_sid 	security.security_pkg.T_SID_ID;
	v_auto_exports_container_sid 	security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE security.menu
	   SET action = '/csr/site/automatedExportImport/admin/list.acds'
	 WHERE action = '/csr/site/automatedExportImport/impinstances.acds';
	FOR r IN (
		SELECT DISTINCT host 
		  FROM csr.customer c
		  JOIN security.website w ON c.host = w.website_name
		 WHERE EXISTS (
			SELECT * 
			  FROM security.securable_object
			 WHERE name = 'AutomatedImports'
			   AND application_sid_id = c.app_sid
		  )
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		v_act_id := SYS_CONTEXT('SECURITY','ACT');
		v_app_sid := SYS_CONTEXT('SECURITY','APP');
		BEGIN
			security.securableobject_pkg.CreateSO(v_act_id,
				v_app_sid,
				security.security_pkg.SO_CONTAINER,
				'AutomatedExportImport',
				v_exportimport_container_sid
			);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_exportimport_container_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'AutomatedExportImport');
		END;
		FOR r IN (
			SELECT sid_id
			  FROM security.SECURABLE_OBJECT
			WHERE name IN ('AutomatedExports', 'AutomatedImports')
			  AND application_sid_id = v_app_sid
			  AND parent_sid_id = v_app_sid
		)
		LOOP
			security.securableobject_pkg.MoveSO(v_act_id, r.sid_id, v_exportimport_container_sid);
		END LOOP;
	END LOOP;
	security.user_pkg.LogonAdmin;
END;
/






@..\core_access_pkg
@..\chain\company_pkg
@..\csr_user_pkg
@..\automated_export_pkg
@..\automated_import_pkg
@..\automated_export_import_pkg
@..\csr_data_pkg
@..\indicator_pkg


@..\core_access_body
@..\csr_user_body
@..\deleg_plan_body
@..\chain\company_body
@..\batch_job_body
@..\csr_data_body
@..\enable_body
@..\automated_export_body
@..\automated_import_body
@..\automated_export_import_body
@..\dataview_body
@..\delegation_body
@..\indicator_api_body
@..\indicator_body
@..\schema_body
@..\stored_calc_datasource_body
@..\val_datasource_body
@..\csrimp\imp_body



@update_tail
