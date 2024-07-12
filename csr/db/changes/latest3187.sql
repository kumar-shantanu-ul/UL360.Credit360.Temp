define version=3187
define minor_version=0
define is_combined=1
@update_header

SET TIMING ON

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_ABILITY AS
	OBJECT (
		FLOW_CAPABILITY_ID  NUMBER(10),
		PERMISSION_SET		NUMBER(10) 
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_ABILITY_TABLE AS
	TABLE OF CSR.T_AUDIT_ABILITY;
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_MIGRATED_GROUP AS
	OBJECT (
		ORIGINAL_SID  	NUMBER(10),
		NEW_GROUP_SID	NUMBER(10) 
	);
/
CREATE OR REPLACE TYPE CSR.T_AUDIT_MIGRATED_GROUP_MAP AS
	TABLE OF CSR.T_AUDIT_MIGRATED_GROUP;
/
CREATE TABLE CSR.MIGRATED_AUDIT (
	APP_SID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	INTERNAL_AUDIT_SID		NUMBER(10) NOT NULL,
	MIGRATED_DTM			DATE DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_MIGRATED_AUDIT PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID),
	CONSTRAINT FK_MIG_AUDIT_INT_AUDIT FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
	REFERENCES CSR.INTERNAL_AUDIT (APP_SID, INTERNAL_AUDIT_SID) ON DELETE CASCADE
);


 ALTER TABLE csr.customer
MODIFY display_cookie_policy DEFAULT (1);
ALTER TABLE csr.automated_export_class ADD CONTAINS_PII NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.automated_import_class ADD CONTAINS_PII NUMBER(1,0) DEFAULT 0 NOT NULL;


GRANT EXECUTE ON csr.csr_app_pkg TO chain;
GRANT EXECUTE ON csr.unit_test_pkg TO chain;
GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;
GRANT EXECUTE ON chain.test_chain_utils_pkg TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE, REFERENCES ON security.acl TO csr;

DECLARE
	v_capability_name		VARCHAR2(100) := 'View supplier company reference fields';
	v_primary_cap_id		NUMBER;
	v_secondary_cap_id		NUMBER;
	v_company_cap_id		NUMBER;
	v_suppliers_cap_id		NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;
	
	SELECT capability_id
	  INTO v_primary_cap_id
	  FROM chain.capability
	 WHERE capability_name = v_capability_name
	   AND capability_type_id = 1;
	
	SELECT capability_id
	  INTO v_secondary_cap_id
	  FROM chain.capability
	 WHERE capability_name = v_capability_name
	   AND capability_type_id = 2;
	SELECT capability_id
	  INTO v_company_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	
	SELECT capability_id
	  INTO v_suppliers_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';
	DELETE FROM chain.company_type_capability
	 WHERE capability_id IN (v_primary_cap_id, v_secondary_cap_id);
	-- capability_flow_capability and card_group_card have no rows
	-- on live pointing to these capabilities, but I had some locally.
	-- CFC is easy to deal with; CGC has a bunch of child rows so I try
	-- migrating them to the company/supplier capability instead.
	DELETE FROM chain.capability_flow_capability
	 WHERE capability_id IN (
			SELECT capability_id
			  FROM chain.capability
			 WHERE capability_name = v_capability_name
	 );
	UPDATE chain.card_group_card
	   SET required_capability_id = v_company_cap_id,
		   required_permission_set = CASE required_permission_set WHEN 2 THEN 1 ELSE required_permission_set END
	 WHERE required_capability_id = v_primary_cap_id;
	UPDATE chain.card_group_card
	   SET required_capability_id = v_suppliers_cap_id,
		   required_permission_set = CASE required_permission_set WHEN 2 THEN 1 ELSE required_permission_set END
	 WHERE required_capability_id = v_secondary_cap_id;
	-- chain.group_capability.capability_id points to capability, but no rows 
	-- on live point to these capabilities, and I _think_ they're basedata
	-- so it should be OK to leave it alone.
	
	DELETE FROM chain.capability
	 WHERE capability_id IN (v_primary_cap_id, v_secondary_cap_id);
END;
/
UPDATE csr.util_script 
   SET util_script_name = 'Enable/Disable lazy load of region role membership on user and region edit',
	   description = 'Enable or disable automatic loading of region role membership for users on editing a user or a region'
 WHERE util_script_id = 37;
UPDATE csr.customer
   SET display_cookie_policy = 1
 WHERE display_cookie_policy = 0;
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000947817120
 WHERE std_measure_conversion_id = 28214;
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000948043428
 WHERE std_measure_conversion_id = 28215;
UPDATE csr.std_measure_conversion
   SET A = 0.000000000000947813394
 WHERE std_measure_conversion_id = 28216;
    
DECLARE
	v_company_cap_id			NUMBER;
	v_suppliers_cap_id			NUMBER;
	v_company_scores_pri_cap_id	NUMBER;
	v_company_scores_sec_cap_id	NUMBER;
BEGIN
	security.user_pkg.logonadmin;
	-- Only these capabilities actually use anything other than Read and Write, and they only additional use Delete:
	
	SELECT capability_id INTO v_company_cap_id				FROM chain.capability WHERE capability_name = 'Company';
	SELECT capability_id INTO v_suppliers_cap_id			FROM chain.capability WHERE capability_name = 'Suppliers';
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 0;
	SELECT capability_id INTO v_company_scores_pri_cap_id	FROM chain.capability WHERE capability_name = 'Company scores' AND is_supplier = 1;
	UPDATE chain.company_type_capability
	   SET permission_set = CASE
				WHEN capability_id IN (v_company_cap_id, v_suppliers_cap_id, v_company_scores_pri_cap_id, v_company_scores_pri_cap_id) THEN BITAND(permission_set, 7)
				ELSE BITAND(permission_set, 3)
		   END;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (57, 'Enable Scrag++ test cube', 
  'Enables the Scrag++ test cube', 'EnableTestCube', NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (58, 'Enable Scrag++ merged scenario', 
  'Migrates the test cube to the Scrag++ merged scenario and creates the unmerged scenario', 'EnableScragPP', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (58, 'Reference/comment', 'Reference/comment for approval of Scrag++ migration', 1, NULL);
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (59, 'Migrate non-WF audits', 
  'Migrate non-WF audits to a Workflow. Migration will fail if the site doesn''t pass the validation (see "Validate audit workflow migration" util script). Use "force migration" to skip the validation', 'MigrateAudits', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (59, 'Force (skips validation)', 'Force = 1, Don''t force = 0', 1, 0);

@..\chain\chain_pkg
@..\chain\setup_pkg
@..\chain\type_capability_pkg
@..\automated_export_pkg
@..\automated_import_pkg
@..\role_pkg
@..\chain\company_type_pkg
@..\util_script_pkg
@..\scrag_pp_pkg
@..\delegation_pkg
@..\deleg_admin_pkg
@..\sheet_pkg
@..\audit_pkg
@..\audit_migration_pkg


@..\automated_import_body
@..\audit_body
@..\chain\chain_body
@..\chain\setup_body
@..\deleg_plan_body
@..\region_api_body
@..\chain\capability_body
@..\chain\type_capability_body
@..\compliance_body
@..\automated_export_body
@..\chain\filter_body
@..\role_body
@..\chain\company_type_body
@..\quick_survey_body
@..\csr_app_body
@..\util_script_body
@..\scrag_pp_body
@..\auto_approve_body
@..\delegation_body
@..\deleg_admin_body
@..\issue_body
@..\schema_body
@..\sheet_body
@..\supplier_body
@..\user_cover_body
@..\val_datasource_body
@..\csrimp\imp_body
@..\..\..\aspen2\cms\db\filter_body
@..\..\..\security\db\oracle\accountpolicyhelper_body
@..\audit_migration_body



@update_tail
