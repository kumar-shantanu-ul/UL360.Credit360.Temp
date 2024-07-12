define version=3183
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

CREATE OR REPLACE TYPE CHAIN.T_REF_PERM_ROW AS
  OBJECT (
	REFERENCE_ID				NUMBER(10),
	PRIMARY_COMPANY_TYPE_ID		NUMBER(10),
	SECONDARY_COMPANY_TYPE_ID	NUMBER(10),
	PERMISSION_SET				NUMBER(10)
  );
/
CREATE OR REPLACE TYPE CHAIN.T_REF_PERM_TABLE AS
  TABLE OF CHAIN.T_REF_PERM_ROW;
/
CREATE TABLE CHAIN.REFERENCE_CAPABILITY (
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	REFERENCE_ID					NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10, 0),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10, 0),
	SECONDARY_COMPANY_TYPE_ID		NUMBER(10, 0),
	PERMISSION_SET					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT CK_REF_CAP_ROLE_XOR CHECK (
		(PRIMARY_COMPANY_GROUP_TYPE_ID IS NOT NULL AND PRIMARY_COMPANY_TYPE_ROLE_SID IS NULL) OR
		(PRIMARY_COMPANY_GROUP_TYPE_ID IS NULL AND PRIMARY_COMPANY_TYPE_ROLE_SID IS NOT NULL)
	),
	CONSTRAINT FK_REF_CAP_REF FOREIGN KEY (APP_SID, REFERENCE_ID) REFERENCES CHAIN.REFERENCE (APP_SID, REFERENCE_ID),
	CONSTRAINT FK_REF_CAP_PRI_COMP_TYPE FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID, COMPANY_TYPE_ID),
	CONSTRAINT FK_REF_CAP_SEC_COMP_TYPE FOREIGN KEY (APP_SID, SECONDARY_COMPANY_TYPE_ID) REFERENCES CHAIN.COMPANY_TYPE (APP_SID, COMPANY_TYPE_ID),
	CONSTRAINT FK_REF_CAP_PRI_COMP_GRP FOREIGN KEY (PRIMARY_COMPANY_GROUP_TYPE_ID) REFERENCES CHAIN.COMPANY_GROUP_TYPE (COMPANY_GROUP_TYPE_ID)
);
CREATE INDEX CHAIN.IX_REF_CAP_REF ON CHAIN.REFERENCE_CAPABILITY (APP_SID, REFERENCE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_TYPE ON CHAIN.REFERENCE_CAPABILITY (APP_SID, PRIMARY_COMPANY_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_SEC_COMP_TYPE ON CHAIN.REFERENCE_CAPABILITY (APP_SID, SECONDARY_COMPANY_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_GRP ON CHAIN.REFERENCE_CAPABILITY (PRIMARY_COMPANY_GROUP_TYPE_ID);
CREATE INDEX CHAIN.IX_REF_CAP_PRI_COMP_ROL ON CHAIN.REFERENCE_CAPABILITY (APP_SID, PRIMARY_COMPANY_TYPE_ROLE_SID);
CREATE UNIQUE INDEX CHAIN.UX_REFERENCE_CAPABILITY ON CHAIN.REFERENCE_CAPABILITY (
	APP_SID,
	REFERENCE_ID,
	PRIMARY_COMPANY_TYPE_ID,
	NVL2(PRIMARY_COMPANY_GROUP_TYPE_ID, 'CTG_' || PRIMARY_COMPANY_GROUP_TYPE_ID, 'CTR_' || PRIMARY_COMPANY_TYPE_ROLE_SID),
	NVL(SECONDARY_COMPANY_TYPE_ID, 0)
);
CREATE TABLE CSRIMP.CHAIN_REFERENCE_CAPABILITY (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	REFERENCE_ID					NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_TYPE_ID			NUMBER(10, 0)	NOT NULL,
	PRIMARY_COMPANY_GROUP_TYPE_ID	NUMBER(10, 0),
	PRIMARY_COMPANY_TYPE_ROLE_SID	NUMBER(10, 0),
	SECONDARY_COMPANY_TYPE_ID		NUMBER(10, 0),
	PERMISSION_SET					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT FK_CHAIN_REF_CAP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
/* http://radino.eu/2008/05/31/bitwise-or-aggregate-function/ */
CREATE OR REPLACE TYPE csr.bitor_impl AS OBJECT
(
  bitor NUMBER,
  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER,
  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER,
  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER,
  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER
)
/
CREATE OR REPLACE TYPE BODY csr.bitor_impl IS
  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER IS
  BEGIN
    ctx := bitor_impl(0);
    RETURN ODCIConst.Success;
  END ODCIAggregateInitialize;
  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + VALUE - bitand(SELF.bitor, VALUE);
    RETURN ODCIConst.Success;
  END ODCIAggregateIterate;
  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + ctx2.bitor - bitand(SELF.bitor, ctx2.bitor);
    RETURN ODCIConst.Success;
  END ODCIAggregateMerge;
  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER IS
  BEGIN
    returnvalue := SELF.bitor;
    RETURN ODCIConst.Success;
  END ODCIAggregateTerminate;
END;
/
CREATE OR REPLACE FUNCTION csr.bitoragg(x IN NUMBER) RETURN NUMBER
PARALLEL_ENABLE
AGGREGATE USING bitor_impl;
/
CREATE SEQUENCE csr.audit_migration_fail_seq;
CREATE TABLE csr.audit_migration_failure(
	app_sid						NUMBER(10, 0)   DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	audit_migration_failure_id 	NUMBER(10, 0) 	NOT NULL,
	object_sid					NUMBER(10, 0) 	NOT NULL,
	grantee_sid					NUMBER(10, 0),
	validation_type_id			NUMBER(1) 		NOT NULL,	
	message						VARCHAR(128),
	CONSTRAINT pk_audit_migration_failure PRIMARY KEY (app_sid, audit_migration_failure_id)
);


CREATE INDEX csr.ix_audit_comparison_response ON csr.internal_audit(app_sid, comparison_response_id);
ALTER TABLE csr.customer
	ADD site_type VARCHAR(10) DEFAULT 'Customer' NOT NULL
	CONSTRAINT ck_site_type CHECK (
		site_type IN ('Customer', 'Prospect', 'Sandbox', 'Staff', 'Retired'));
ALTER TABLE csrimp.customer ADD site_type VARCHAR(10) NOT NULL;
ALTER TABLE CHAIN.REFERENCE DROP CONSTRAINT FK_REF_AC_REF_PURCHASER DROP INDEX;
DROP INDEX chain.ix_reference_purchaser_ref;
ALTER TABLE CHAIN.REFERENCE DROP CONSTRAINT FK_REF_AC_REF_SUPPLIER DROP INDEX;
DROP INDEX chain.ix_reference_supplier_ref_;
DROP TABLE CHAIN.REFERENCE_ACCESS_LEVEL;
ALTER TABLE CHAIN.REFERENCE RENAME COLUMN supplier_ref_access_level_id TO xxx_supplier_lvl;
ALTER TABLE CHAIN.REFERENCE RENAME COLUMN purchaser_ref_access_level_id TO xxx_purchaser_lvl;
ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN supplier_ref_access_level_id;
ALTER TABLE CSRIMP.CHAIN_REFERENCE DROP COLUMN purchaser_ref_access_level_id;
ALTER TABLE csr.delegation_date_schedule DROP CONSTRAINT CK_DATES DROP INDEX;
ALTER TABLE csr.delegation_date_schedule ADD CONSTRAINT CK_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.delegation_date_schedule DROP CONSTRAINT CK_DATES DROP INDEX;
ALTER TABLE csrimp.delegation_date_schedule ADD CONSTRAINT CK_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csr.sheet_date_schedule DROP CONSTRAINT CK_START_DTM DROP INDEX;
ALTER TABLE csrimp.sheet_date_schedule DROP CONSTRAINT CK_START_DTM DROP INDEX;
ALTER TABLE csr.deleg_plan DROP CONSTRAINT CK_DELEG_TPL_DATES DROP INDEX;
ALTER TABLE csr.deleg_plan ADD CONSTRAINT CK_DELEG_TPL_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.deleg_plan DROP CONSTRAINT CK_DELEG_TPL_DATES DROP INDEX;
ALTER TABLE csrimp.deleg_plan ADD CONSTRAINT CK_DELEG_TPL_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csr.delegation DROP CONSTRAINT CK_DELEGATION_DATES DROP INDEX;
ALTER TABLE csr.delegation ADD CONSTRAINT CK_DELEGATION_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.delegation DROP CONSTRAINT CK_DELEGATION_DATES DROP INDEX;
ALTER TABLE csrimp.delegation ADD CONSTRAINT CK_DELEGATION_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csr.sheet DROP CONSTRAINT CK_SHEET_DATES DROP INDEX;
ALTER TABLE csr.sheet ADD CONSTRAINT CK_SHEET_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csrimp.sheet DROP CONSTRAINT CK_SHEET_DATES DROP INDEX;
ALTER TABLE csrimp.sheet ADD CONSTRAINT CK_SHEET_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;
ALTER TABLE csr.sheet_val_change_log DROP CONSTRAINT CK_SHEET_VAL_CHANGE_LOG_DATES DROP INDEX;
ALTER TABLE csr.sheet_val_change_log ADD CONSTRAINT CK_SHEET_VAL_CHANGE_LOG_DATES CHECK (END_DTM > START_DTM) ENABLE NOVALIDATE;


GRANT SELECT, INSERT, UPDATE ON CHAIN.REFERENCE_CAPABILITY TO CSR;
GRANT SELECT, INSERT, UPDATE ON CHAIN.REFERENCE_CAPABILITY TO CSRIMP;
GRANT SELECT, INSERT, UPDATE, DELETE ON CSRIMP.CHAIN_REFERENCE_CAPABILITY TO TOOL_USER;
GRANT UPDATE ON security.acl TO csr;


ALTER TABLE CHAIN.REFERENCE_CAPABILITY
	ADD CONSTRAINT FK_REF_CAP_PRI_COMP_ROL
	FOREIGN KEY (APP_SID, PRIMARY_COMPANY_TYPE_ROLE_SID)
	REFERENCES CSR.ROLE (APP_SID, ROLE_SID);




INSERT INTO csr.module (module_id, module_name, enable_sp, description) VALUES (104, 'API Suggestions', 'EnableSuggestionsApi', 'Enables the Suggestions Api.');


BEGIN
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.AutomatedExportImport',
		attribute	=> 'job_action',
		/**/value		=> 'BEGIN csr.automated_export_import_pkg.ScheduleRun(); commit; END;'
	);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.BATCHEDEXPORTSCLEARUP',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.batch_exporter_pkg.ScheduledFileClearup(); security.user_pkg.logoff(security.security_pkg.GetAct); commit; END;'
	);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.BATCHEDIMPORTSCLEARUP',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.batch_importer_pkg.ScheduledFileClearUp; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterRawDataJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateRawDataJobsForApps; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterMatchJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.meter_monitor_pkg.CreateMatchJobsForApps; security.user_pkg.LogOff(security.security_pkg.GetAct); commit; END;'
	);
	DBMS_SCHEDULER.SET_ATTRIBUTE (
		name		=> 'csr.MeterMatchJob',
		attribute	=> 'job_action',
		value		=> 'BEGIN security.user_pkg.logonadmin(); csr.customer_pkg.RefreshCalcWindows; security.user_pkg.LogOff(security.security_pkg.GetAct); END;'
	);
END;
/
UPDATE security.act_timeout
   SET timeout = 86400
 WHERE timeout IN (
	SELECT application_sid_id
	  FROM security.website
 );
UPDATE csr.customer
	SET site_type = CASE
		WHEN host LIKE '%-dev.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-sandbox.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-test.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-training.credit360.com' THEN 'Sandbox'
		WHEN host LIKE '%-demo.credit360.com' THEN 'Prospect'
		WHEN host LIKE '%-pilot.credit360.com' THEN 'Prospect'
		WHEN host LIKE '%-imp.credit360.com' THEN 'Staff'
		WHEN host LIKE '%-staff.credit360.com' THEN 'Staff'
		WHEN host LIKE '%-zap.credit360.com' THEN 'Retired'
		ELSE 'Customer'
	END;
DECLARE
	v_primary_cap_id		NUMBER;
	v_secondary_cap_id		NUMBER;
BEGIN
	SELECT capability_id
	  INTO v_primary_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Company';
	
	SELECT capability_id
	  INTO v_secondary_cap_id
	  FROM chain.capability
	 WHERE capability_name = 'Suppliers';
	security.user_pkg.logonadmin;
	FOR s IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c 
		 WHERE EXISTS (
			SELECT NULL FROM chain.reference WHERE app_sid = c.app_sid
		 )
	) LOOP
		security.user_pkg.logonadmin(s.host);
		
		FOR r IN (
			SELECT r.reference_id, r.xxx_supplier_lvl, r.xxx_purchaser_lvl,
				   rct.company_type_id
			  FROM chain.reference r
			  LEFT JOIN chain.reference_company_type rct ON rct.reference_id = r.reference_id
		) LOOP
			IF r.xxx_supplier_lvl > 0 THEN
				INSERT INTO chain.reference_capability
							(reference_id, primary_company_type_id,
							 primary_company_group_type_id, primary_company_type_role_sid,
							 secondary_company_type_id,
							 permission_set)
				SELECT r.reference_id, ctc.primary_company_type_id,
					   ctc.primary_company_group_type_id, ctc.primary_company_type_role_sid,
					   ctc.secondary_company_type_id,
					   LEAST(ctc.permission_set, CASE r.xxx_supplier_lvl
							WHEN 2 then 3
							ELSE 1
					   END)
				  FROM chain.company_type_capability ctc
				 WHERE ctc.capability_id = v_primary_cap_id 
				   AND NVL(r.company_type_id, ctc.primary_company_type_id) = ctc.primary_company_type_id
				   AND ctc.permission_set > 0;
			END IF;
			IF r.xxx_purchaser_lvl > 0 THEN
				INSERT INTO chain.reference_capability
							(reference_id, primary_company_type_id,
							 primary_company_group_type_id, primary_company_type_role_sid,
							 secondary_company_type_id,
							 permission_set)
				SELECT r.reference_id, ctc.primary_company_type_id,
					   ctc.primary_company_group_type_id, ctc.primary_company_type_role_sid,
					   ctc.secondary_company_type_id,
					   LEAST(ctc.permission_set, CASE r.xxx_purchaser_lvl
							WHEN 2 then 3
							ELSE 1
					   END)
				  FROM chain.company_type_capability ctc
				 WHERE ctc.capability_id = v_secondary_cap_id
				   AND NVL(r.company_type_id, ctc.secondary_company_type_id) = ctc.secondary_company_type_id
				   AND ctc.permission_set > 0;
			END IF;
		END LOOP;
	END LOOP;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (56, 'Validate audit workflow migration', 
  'Checks if audits on this site can be migrated to a workflow. Will complete successfully if the validation passes, otherwise will throw an error. Find error details in "csr/site/admin/auditmigration/validationfailures.acds" page', 'CanMigrateAudits', NULL);
INSERT INTO CSR.STD_MEASURE_CONVERSION (STD_MEASURE_CONVERSION_ID, STD_MEASURE_ID, DESCRIPTION, A, B, C, DIVISIBLE) VALUES (28221, 13, '1/m', 1, 1, 0, 1);




CREATE OR REPLACE PACKAGE csr.audit_migration_pkg AS END;
/
GRANT EXECUTE ON csr.audit_migration_pkg TO web_user;


@..\region_api_pkg
@..\csr_data_pkg
@..\enable_pkg
@..\indicator_api_pkg 
@..\csr_app_pkg
@..\chain\chain_pkg
@..\chain\helper_pkg
@..\schema_pkg
@..\audit_migration_pkg
@..\unit_test_pkg
@..\util_script_pkg
@..\chain\test_chain_utils_pkg
@..\deleg_plan_pkg
@..\campaign_pkg
@..\flow_pkg
@..\factor_pkg


@..\region_api_body
@..\delegation_body 
@..\chain\scheduled_alert_body
@..\chain\bsci_body
@..\chain\questionnaire_body
@..\chain\dedupe_preprocess_body
@..\energy_star_job_body
@..\stored_calc_datasource_body
@..\region_tree_body
@..\sheet_body
@..\indicator_body
@..\aggregate_ind_body
@..\audit_body
@..\automated_import_body
@..\enable_body
@..\indicator_api_body 
@..\quick_survey_body
@..\csrimp\imp_body
@..\csr_app_body
@..\schema_body
@..\forecasting_body
@..\scenario_body
@..\chain\chain_body
@..\chain\helper_body
@..\chain\company_body
@..\chain\business_rel_report_body
@..\chain\company_filter_body
@..\chain\higg_setup_body
@..\audit_migration_body
@..\unit_test_body
@..\util_script_body
@..\chain\test_chain_utils_body
@..\quick_survey_report_body
@..\section_body
@..\deleg_plan_body
@..\campaign_body
@..\flow_body
@..\permit_report_body
@..\factor_body



@update_tail
