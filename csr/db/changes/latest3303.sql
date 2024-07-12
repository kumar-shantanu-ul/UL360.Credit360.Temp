define version=3303
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


CREATE TABLE csr.auto_exp_class_qc_settings (
    app_sid                         NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    automated_export_class_sid      NUMBER(10, 0)   NOT NULL,
	saved_filter_sid				NUMBER(10, 0)   NOT NULL,
    CONSTRAINT pk_auto_exp_class_qc_settings PRIMARY KEY (app_sid, automated_export_class_sid)
);


ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG
 DROP CONSTRAINT UK_CIVL_I;
ALTER TABLE CSR.COMPLIANCE_ITEM_VERSION_LOG
  ADD CONSTRAINT UK_CIVL_I UNIQUE (APP_SID, COMPLIANCE_ITEM_ID, MAJOR_VERSION, MINOR_VERSION, IS_MAJOR_CHANGE, LANG_ID, CHANGE_TYPE);

DECLARE 
	PROCEDURE UNSEC_RemoveFollowerRoles (
		in_purchaser_company_sid NUMBER,
		in_supplier_company_sid	 NUMBER,
		in_role_sid				 NUMBER
	) 
	IS	
		v_role_member_count NUMBER;
	BEGIN
		FOR r IN (
			SELECT rrm.region_sid, rrm.user_sid
			  FROM chain.supplier_follower sf
			  JOIN csr.supplier s ON s.company_sid = sf.supplier_company_sid
			  JOIN csr.region_role_member rrm ON rrm.region_sid = s.region_sid 
			   AND rrm.role_sid = in_role_sid
			   AND rrm.user_sid = sf.user_sid
			 WHERE sf.purchaser_company_sid = in_purchaser_company_sid
			   AND sf.supplier_company_sid = in_supplier_company_sid
		) LOOP
			DELETE FROM csr.region_role_member
			 WHERE role_sid = in_role_sid
			   AND inherited_from_sid = r.region_sid  -- The top most region is marked as inherited from itself, so we delete that and anything inherited from it.
			   AND user_sid = r.user_sid;
			
			IF SQL%ROWCOUNT > 0 THEN
				SELECT COUNT(*)
				  INTO v_role_member_count
				  FROM csr.region_role_member
				 WHERE role_sid = in_role_sid
				   AND user_sid = r.user_sid;
				--If the user is no longer a member of this role, delete him from the group too
				IF v_role_member_count =  0 THEN
					DELETE FROM security.group_members
					 WHERE member_sid_id = r.user_sid
					   AND group_sid_id = in_role_sid;
				END IF;
			END IF;
		END LOOP;
	END UNSEC_RemoveFollowerRoles;
BEGIN
	security.user_pkg.logonAdmin;
	FOR i IN (
		SELECT DISTINCT sf.app_sid, sf.purchaser_company_sid, sf.supplier_company_sid, ctr.follower_role_sid
		  FROM chain.supplier_follower sf
		  JOIN chain.company p ON p.app_sid = sf.app_sid AND p.company_sid = sf.purchaser_company_sid
		  JOIN chain.company s ON s.app_sid = sf.app_sid AND s.company_sid = sf.supplier_company_sid
		  JOIN CHAIN.company_type_relationship ctr ON ctr.app_sid = p.app_sid 
		   AND ctr.primary_company_type_id = p.company_type_id 
		   AND ctr.secondary_company_type_id = s.company_type_id
		 WHERE ctr.follower_role_sid IS NOT NULL
		   AND EXISTS(
			SELECT 1 
			  FROM chain.supplier_relationship sr 
			 WHERE sr.purchaser_company_sid = p.company_sid 
			   AND sr.supplier_company_sid = s.company_sid
			   AND sr.deleted = 1
			)
		 ORDER BY sf.app_sid
	)
	LOOP
		security.security_pkg.setapp(i.app_sid);
		UNSEC_RemoveFollowerRoles (
			in_purchaser_company_sid => i.purchaser_company_sid,
			in_supplier_company_sid	 => i.supplier_company_sid,
			in_role_sid				 => i.follower_role_sid
		);
		
		DELETE FROM chain.supplier_follower 
		 WHERE purchaser_company_sid = i.purchaser_company_sid
		   AND supplier_company_sid = i.supplier_company_sid;
	END LOOP;
	security.security_pkg.setapp(NULL);
	security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/
INSERT INTO csr.auto_exp_exporter_plugin_type (plugin_type_id, label)
VALUES (5, 'Quick Chart Exporter');

INSERT INTO csr.auto_exp_exporter_plugin (
	plugin_id, label, exporter_assembly, outputter_assembly, dsv_outputter, plugin_type_id
) VALUES (
	23,
	'Quick Chart Export',
	'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartExporter',
	'Credit360.ExportImport.Automated.Export.Exporters.QuickChart.QuickChartOutputter',
	0,
	5
);
INSERT INTO csr.schema_table (owner, table_name) VALUES ('CSR', 'AUTO_EXP_CLASS_QC_SETTINGS');






@..\chain\test_chain_utils_pkg
@..\deleg_plan_pkg
@..\supplier_pkg
@..\audit_pkg
@..\automated_export_pkg


@..\supplier_body
@..\chain\test_chain_utils_body
@..\permit_body
@..\deleg_plan_body
@..\chain\company_body
@..\factor_body
@..\compliance_body
@..\delegation_body
@..\audit_body
@..\automated_export_body



@update_tail
