define version=3304
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

CREATE TABLE CSR.DATA_BUCKET(
	APP_SID					NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	DATA_BUCKET_SID			NUMBER(10, 0)		NOT NULL,
	DESCRIPTION				VARCHAR2(1024)		NOT NULL,
	ENABLED					NUMBER(1, 0)		DEFAULT 1 NOT NULL,
	ACTIVE_INSTANCE_ID		NUMBER(10, 0),
	CONSTRAINT CK_DATA_BUCKET_ENABLED CHECK (ENABLED IN (0,1)),
	CONSTRAINT PK_DATA_BUCKET PRIMARY KEY (APP_SID, DATA_BUCKET_SID)
);
CREATE TABLE CSR.DATA_BUCKET_INSTANCE(
	APP_SID						NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	DATA_BUCKET_SID				NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_INSTANCE_ID		NUMBER(10, 0)		NOT NULL,
	COMPLETED_DTM				DATE,
	JOB_ID						NUMBER(10, 0),
	FETCH_TIME					NUMBER(10, 2),
	WRITE_TIME					NUMBER(10, 2),
	CONSTRAINT PK_DATA_BUCKET_INSTANCE PRIMARY KEY (APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID)
);
CREATE SEQUENCE CSR.DATA_BUCKET_INSTANCE_ID_SEQ CACHE 5;
CREATE TABLE CSR.DATA_BUCKET_VAL(
	APP_SID						NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	DATA_BUCKET_SID				NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_INSTANCE_ID		NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_VAL_ID			NUMBER(10, 0)		NOT NULL,
	IND_SID						NUMBER(10, 0)		NOT NULL,
	REGION_SID					NUMBER(10, 0)		NOT NULL,
	PERIOD_START_DTM			DATE				NOT NULL,
	PERIOD_END_DTM				DATE				NOT NULL,
	SOURCE_TYPE_ID				NUMBER(10, 0)		NOT NULL,
	VAL_NUMBER					NUMBER(24, 10)		NOT NULL,
	VAL_KEY						VARCHAR2(1024),
	CONSTRAINT PK_DATA_BUCKET_VAL PRIMARY KEY (APP_SID, DATA_BUCKET_VAL_ID)
);
CREATE SEQUENCE CSR.DATA_BUCKET_VAL_ID_SEQ CACHE 5;
CREATE TABLE CSR.DATA_BUCKET_SOURCE_DETAIL(
	APP_SID							NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	DATA_BUCKET_SID					NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_INSTANCE_ID			NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_SOURCE_DETAIL_ID	NUMBER(10, 0)		NOT NULL,
	ID								VARCHAR2(1024)		NOT NULL,
	DETAIL_ONE						VARCHAR2(1024),
	DETAIL_TWO						VARCHAR2(1024),
	VAL_KEY							VARCHAR2(1024)		NOT NULL,
	CONSTRAINT PK_DATA_BUCKET_SOURCE_DETAIL PRIMARY KEY (APP_SID, DATA_BUCKET_SOURCE_DETAIL_ID)
);
CREATE SEQUENCE CSR.DATA_BUCKET_SOURCE_DETAIL_ID_SEQ CACHE 5;
CREATE TABLE CSR.BATCH_JOB_DATA_BUCKET_AGG_IND(
	APP_SID					NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_SID			NUMBER(10, 0)		NOT NULL,
	AGGREGATE_IND_GROUP_ID	NUMBER(10, 0)		NOT NULL,
	CONSTRAINT PK_DATA_BUCKET_BATCH_JOB PRIMARY KEY (APP_SID, BATCH_JOB_ID)
);
CREATE TABLE CSR.AGG_IND_DATA_BUCKET_PENDING_JOB(
	APP_SID					NUMBER(10, 0)		DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	BATCH_JOB_ID			NUMBER(10, 0)		NOT NULL,
	DATA_BUCKET_SID			NUMBER(10, 0)		NOT NULL,
	CONSTRAINT PK_AGG_IND_DATA_BUCKET_PENDING_JOB PRIMARY KEY (APP_SID, DATA_BUCKET_SID)
);
--Failed to locate all sections of latest3303_11.sql


ALTER TABLE CSR.DATA_BUCKET ADD CONSTRAINT FK_DATA_BUCKET_ACTIVE_INSTANCE
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID, ACTIVE_INSTANCE_ID)
	REFERENCES CSR.DATA_BUCKET_INSTANCE(APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID);
ALTER TABLE CSR.DATA_BUCKET_INSTANCE ADD CONSTRAINT FK_DATA_BUCKET_INSTANCE_BUCKET
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID)
	REFERENCES CSR.DATA_BUCKET(APP_SID, DATA_BUCKET_SID);
ALTER TABLE CSR.DATA_BUCKET_VAL ADD CONSTRAINT FK_DATA_BUCKET_VAL_INSTANCE
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID)
	REFERENCES CSR.DATA_BUCKET_INSTANCE(APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID);
ALTER TABLE CSR.DATA_BUCKET_VAL ADD CONSTRAINT FK_DATA_BUCKET_VAL_IND
	FOREIGN KEY (APP_SID, IND_SID)
	REFERENCES CSR.IND(APP_SID, IND_SID);
ALTER TABLE CSR.DATA_BUCKET_VAL ADD CONSTRAINT FK_DATA_BUCKET_VAL_REGION
	FOREIGN KEY (APP_SID, REGION_SID)
	REFERENCES CSR.REGION(APP_SID, REGION_SID);
ALTER TABLE CSR.DATA_BUCKET_SOURCE_DETAIL ADD CONSTRAINT DATA_BUCKET_SOURCE_DTL_INSTNC
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID)
	REFERENCES CSR.DATA_BUCKET_INSTANCE(APP_SID, DATA_BUCKET_SID, DATA_BUCKET_INSTANCE_ID);
ALTER TABLE CSR.BATCH_JOB_DATA_BUCKET_AGG_IND ADD CONSTRAINT FK_BJ_DTA_BCKT_AGG_IND_JB_ID
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID);
ALTER TABLE CSR.BATCH_JOB_DATA_BUCKET_AGG_IND ADD CONSTRAINT FK_BJ_DTA_BCKT_AGG_IND_BCKT_SID
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID)
	REFERENCES CSR.DATA_BUCKET(APP_SID, DATA_BUCKET_SID);
ALTER TABLE CSR.BATCH_JOB_DATA_BUCKET_AGG_IND ADD CONSTRAINT FK_BJ_DTA_BCKT_AGG_IND_GRP_ID
	FOREIGN KEY (APP_SID, AGGREGATE_IND_GROUP_ID)
	REFERENCES CSR.AGGREGATE_IND_GROUP(APP_SID, AGGREGATE_IND_GROUP_ID);
ALTER TABLE CSR.AGG_IND_DATA_BUCKET_PENDING_JOB ADD CONSTRAINT FK_AGG_IND_DT_BCKT_PNDNG_JB_JOB
	FOREIGN KEY (APP_SID, BATCH_JOB_ID)
	REFERENCES CSR.BATCH_JOB(APP_SID, BATCH_JOB_ID);
ALTER TABLE CSR.AGG_IND_DATA_BUCKET_PENDING_JOB ADD CONSTRAINT FK_AGG_IND_DT_BCKT_PNDNG_JB_BCKET
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID)
	REFERENCES CSR.DATA_BUCKET(APP_SID, DATA_BUCKET_SID);
ALTER TABLE CSR.AGGREGATE_IND_GROUP
ADD DATA_BUCKET_SID NUMBER(10, 0);
ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD CONSTRAINT FK_AGGREGATE_IND_GRP_DATA_BCKT
	FOREIGN KEY (APP_SID, DATA_BUCKET_SID)
	REFERENCES CSR.DATA_BUCKET(APP_SID, DATA_BUCKET_SID);
CREATE UNIQUE INDEX CSR.IK_AGG_IND_GRP_DATA_BUCKET 
	ON CSR.AGGREGATE_IND_GROUP(APP_SID, NVL(DATA_BUCKET_SID, AGGREGATE_IND_GROUP_ID))
;
ALTER TABLE CSR.AGGREGATE_IND_GROUP
ADD DATA_BUCKET_FETCH_SP VARCHAR2(255);
ALTER TABLE CSR.AGGREGATE_IND_GROUP ADD CONSTRAINT CK_AGG_IND_GRP_FETCH_SP
	CHECK ((DATA_BUCKET_FETCH_SP IS NULL AND DATA_BUCKET_SID IS NULL) 
	   OR (DATA_BUCKET_FETCH_SP IS NOT NULL AND DATA_BUCKET_SID IS NOT NULL));
CREATE TABLE CSRIMP.DATA_BUCKET (
    CSRIMP_SESSION_ID              NUMBER(10)		 DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    DATA_BUCKET_SID                NUMBER(10, 0)		NOT NULL,
    DESCRIPTION                    VARCHAR2(1024)		NOT NULL,
    ENABLED                        NUMBER(1, 0)		DEFAULT 1 NOT NULL,
    ACTIVE_INSTANCE_ID             NUMBER(10, 0),
    CONSTRAINT CK_DATA_BUCKET_ENABLED CHECK (ENABLED IN (0,1)),
    CONSTRAINT PK_DATA_BUCKET PRIMARY KEY (CSRIMP_SESSION_ID, DATA_BUCKET_SID),
    CONSTRAINT FK_DATA_BUCKET_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);
ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP
ADD DATA_BUCKET_SID NUMBER(10, 0);
ALTER TABLE CSRIMP.AGGREGATE_IND_GROUP
ADD DATA_BUCKET_FETCH_SP VARCHAR2(255);
create index csr.ix_aggregate_ind_data_bucket_s on csr.aggregate_ind_group (app_sid, data_bucket_sid);
create index csr.ix_agg_ind_data__batch_job_id on csr.agg_ind_data_bucket_pending_job (app_sid, batch_job_id);
create index csr.ix_batch_job_dat_aggregate_ind on csr.batch_job_data_bucket_agg_ind (app_sid, aggregate_ind_group_id);
create index csr.ix_batch_job_dat_data_bucket_s on csr.batch_job_data_bucket_agg_ind (app_sid, data_bucket_sid);
create index csr.ix_data_bucket_data_bucket_s on csr.data_bucket (app_sid, data_bucket_sid, active_instance_id);
create index csr.ix_data_bucket_s_data_bucket_s on csr.data_bucket_source_detail (app_sid, data_bucket_sid, data_bucket_instance_id);
create index csr.ix_data_bucket_v_ind_sid on csr.data_bucket_val (app_sid, ind_sid);
create index csr.ix_data_bucket_v_region_sid on csr.data_bucket_val (app_sid, region_sid);
create index csr.ix_data_bucket_v_data_bucket_s on csr.data_bucket_val (app_sid, data_bucket_sid, data_bucket_instance_id);
ALTER TABLE csr.deleg_plan_deleg_region ADD (
  REGION_TYPE 		NUMBER(10,0)
);
ALTER TABLE csrimp.deleg_plan_deleg_region ADD (
  REGION_TYPE 		NUMBER(10,0)
);






CREATE OR REPLACE VIEW chain.v$purchaser_involvement AS
	SELECT sit.flow_involvement_type_id, sr.supplier_company_sid
	  FROM supplier_relationship sr
	  JOIN company pc ON pc.company_sid = sr.purchaser_company_sid
	  LEFT JOIN csr.supplier ps ON ps.company_sid = pc.company_sid
	  JOIN company sc ON sc.company_sid = sr.supplier_company_sid
	  JOIN supplier_involvement_type sit
		ON (sit.user_company_type_id IS NULL OR sit.user_company_type_id = pc.company_type_id)
	   AND (sit.page_company_type_id IS NULL OR sit.page_company_type_id = sc.company_type_id)
	   AND (sit.purchaser_type = 1 /*chain_pkg.PURCHASER_TYPE_ANY*/
		OR (sit.purchaser_type = 2 /*chain_pkg.PURCHASER_TYPE_PRIMARY*/ AND sr.is_primary = 1)
		OR (sit.purchaser_type = 3 /*chain_pkg.PURCHASER_TYPE_OWNER*/ AND pc.company_sid = sc.parent_sid)
	   )
	  LEFT JOIN csr.region_role_member rrm
	    ON rrm.region_sid = ps.region_sid
	   AND rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID')
	   AND rrm.role_sid = sit.restrict_to_role_sid
	 WHERE pc.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY')
	   AND pc.deleted = 0
	   AND sc.deleted = 0
	   AND sr.deleted = 0
	   AND (sit.restrict_to_role_sid IS NULL OR rrm.user_sid IS NOT NULL);
CREATE OR REPLACE VIEW csr.V$DELEG_PLAN_DELEG_REGION AS
	SELECT dpc.app_sid, dpc.deleg_plan_sid, dpdr.deleg_plan_col_deleg_id, dpc.deleg_plan_col_id, dpc.is_hidden,
		   dpcd.delegation_sid, dpdr.region_sid, dpdr.pending_deletion, dpdr.region_selection,
		   dpdr.tag_id, dpdr.region_type
	  FROM deleg_plan_deleg_region dpdr
	  JOIN deleg_plan_col_deleg dpcd ON dpdr.app_sid = dpcd.app_sid AND dpdr.deleg_plan_col_deleg_id = dpcd.deleg_plan_col_deleg_id
	  JOIN deleg_plan_col dpc ON dpcd.app_sid = dpc.app_sid AND dpcd.deleg_plan_col_deleg_id = dpc.deleg_plan_col_deleg_id;




DECLARE
	v_id		NUMBER(10);
BEGIN
	security.user_pkg.logonadmin;
	security.class_pkg.CreateClass(SYS_CONTEXT('SECURITY','ACT'), null, 'CSRDataBucket', 'csr.data_bucket_pkg', null, v_Id);
EXCEPTION
	WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
		NULL;
END;
/
INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
	VALUES (93, 'Data bucket aggregate ind group processor', NULL, 'data-bucket-agg-ind-processor', 1, NULL);
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (110, 'Data buckets', 'EnableDataBuckets', 'Enable data buckets.');
DECLARE
	PROCEDURE Temp_RegisterCapability (
		in_capability_type			IN  NUMBER,
		in_capability				IN  VARCHAR2, 
		in_perm_type				IN  NUMBER,
		in_is_supplier				IN  NUMBER DEFAULT 0
	)
	AS
		v_count						NUMBER(10);
		v_ct						NUMBER(10);
	BEGIN
		IF in_capability_type = 10 /*chain_pkg.CT_COMPANIES*/ THEN
			Temp_RegisterCapability(1 /*chain_pkg.CT_COMPANY*/, in_capability, in_perm_type);
			Temp_RegisterCapability(2 /*chain_pkg.CT_SUPPLIERS*/, in_capability, in_perm_type, 1);
			RETURN;	
		END IF;
		
		IF in_capability_type = 1 AND in_is_supplier <> 0 /* chain_pkg.IS_NOT_SUPPLIER_CAPABILITY */ THEN
			RAISE_APPLICATION_ERROR(-20001, 'Company capabilities cannot be supplier centric');
		ELSIF in_capability_type = 2 /* chain_pkg.CT_SUPPLIERS */ AND in_is_supplier <> 1 /* chain_pkg.IS_SUPPLIER_CAPABILITY */ THEN
			RAISE_APPLICATION_ERROR(-20001, 'Supplier capabilities must be supplier centric');
		END IF;
		
		SELECT COUNT(*)
		INTO v_count
		FROM chain.capability
		WHERE capability_name = in_capability
		AND capability_type_id = in_capability_type
		AND perm_type = in_perm_type;
		
		IF v_count > 0 THEN
			-- this is already registered
			RETURN;
		END IF;
		
		SELECT COUNT(*)
		INTO v_count
		FROM chain.capability
		WHERE capability_name = in_capability
		AND perm_type <> in_perm_type;
		
		IF v_count > 0 THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' already exists using a different permission type');
		END IF;
		
		SELECT COUNT(*)
		INTO v_count
		FROM chain.capability
		WHERE capability_name = in_capability
		AND (
				(capability_type_id = 0 /*chain_pkg.CT_COMMON*/ AND (in_capability_type = 0 /*chain_pkg.CT_COMPANY*/ OR in_capability_type = 2 /*chain_pkg.CT_SUPPLIERS*/))
				OR (in_capability_type = 0 /*chain_pkg.CT_COMMON*/ AND (capability_type_id = 1 /*chain_pkg.CT_COMPANY*/ OR capability_type_id = 2 /*chain_pkg.CT_SUPPLIERS*/))
			);
		
		IF v_count > 0 THEN
			RAISE_APPLICATION_ERROR(security.security_pkg.ERR_ACCESS_DENIED, 'A capability named '''||in_capability||''' is already registered as a different capability type');
		END IF;
		
		INSERT INTO chain.capability 
		(capability_id, capability_name, capability_type_id, perm_type, is_supplier) 
		VALUES 
		(chain.capability_id_seq.NEXTVAL, in_capability, in_capability_type, in_perm_type, in_is_supplier);
		
END;
BEGIN
	security.user_pkg.LogonAdmin;
	Temp_RegisterCapability(
		in_capability_type	=> 3,  															/* CT_ON_BEHALF_OF*/
		in_capability		=> 'Set primary purchaser in a relationship between A and B', 	/* SET_PRIMARY_PRCHSR */
		in_perm_type		=> 1, 															/* BOOLEAN_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/

DECLARE
	v_act		security.security_pkg.T_ACT_ID;
	v_sid		security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act);
	FOR r IN (
		SELECT application_sid_id, web_root_sid_id
		  FROM security.website
		 WHERE application_sid_id in (
		SELECT app_sid FROM csr.customer
		)
	)
	LOOP
		BEGIN
			security.web_pkg.CreateResource(v_act, r.web_root_sid_id, r.web_root_sid_id, 'api.brandingsettings', v_sid);
			security.acl_pkg.AddACE(v_act, 
			security.acl_pkg.GetDACLIDForSID(v_sid), 
			security.security_pkg.ACL_INDEX_LAST, 
			security.security_pkg.ACE_TYPE_ALLOW,
			security.security_pkg.ACE_FLAG_DEFAULT, 
			security.securableobject_pkg.getsidfrompath(v_act, r.application_sid_id, 'Groups/RegisteredUsers'), security.security_pkg.PERMISSION_STANDARD_READ);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
END;
/




CREATE OR REPLACE PACKAGE csr.data_bucket_pkg AS
	PROCEDURE DUMMY;
END;
/
CREATE OR REPLACE PACKAGE BODY csr.data_bucket_pkg AS
	PROCEDURE DUMMY
AS
	BEGIN
		NULL;
	END;
END;
/
GRANT EXECUTE ON csr.data_bucket_pkg TO security;
GRANT EXECUTE ON csr.data_bucket_pkg TO web_user;
GRANT EXECUTE ON csr.aggregate_ind_pkg TO web_user;
GRANT INSERT ON csr.data_bucket TO csrimp;


@..\data_bucket_pkg
@..\batch_job_pkg
@..\aggregate_ind_pkg
@..\schema_pkg
@..\enable_pkg
@..\calc_pkg
@..\csrimp\imp_pkg
@..\chain\product_metric_report_pkg
@..\chain\prdct_supp_mtrc_report_pkg
@..\csr_data_pkg
@..\unit_test_pkg
@..\branding_pkg
@..\util_script_pkg
@..\region_tree_pkg
@..\compliance_pkg
@..\permit_pkg
@..\automated_import_pkg
@..\meter_pkg
@..\deleg_plan_pkg
@..\tag_pkg


@..\region_metric_body
@..\data_bucket_body
@..\aggregate_ind_body
@..\schema_body
@..\csr_app_body
@..\enable_body
@..\calc_body
@..\csrimp\imp_body
@..\chain\activity_report_body
@..\chain\prdct_supp_mtrc_report_body
@..\chain\product_metric_report_body
@..\tag_body
@..\unit_test_body
@..\saml_body
@..\csr_user_body
@..\compliance_library_report_body
@..\branding_body
@..\util_script_body
@..\region_tree_body
@..\compliance_body
@..\permit_body
@..\automated_import_body
@..\meter_body
@..\deleg_plan_body
@..\campaigns\campaign_body
@..\meter_monitor_body
@..\audit_body
@..\issue_body



@update_tail
