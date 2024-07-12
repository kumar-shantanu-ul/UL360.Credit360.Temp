define version=3088
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

CREATE SEQUENCE CSR.APPLICATION_PAUSE_ID_SEQ;
CREATE TABLE CSR.COMPL_PERMIT_APPLICATION_PAUSE (
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	APPLICATION_PAUSE_ID	NUMBER(10, 0)	NOT NULL,
	PERMIT_APPLICATION_ID	NUMBER(10, 0)	NOT NULL,
	PAUSED_DTM				DATE			NOT NULL,
	RESUMED_DTM				DATE,
	CONSTRAINT PK_COMPL_PERMIT_APP_PAUSE PRIMARY KEY (APP_SID, APPLICATION_PAUSE_ID)
)
;
ALTER TABLE CSR.COMPL_PERMIT_APPLICATION_PAUSE ADD CONSTRAINT FK_COMPL_PERM_APP_PAUSE_CPA
    FOREIGN KEY (APP_SID, PERMIT_APPLICATION_ID)
    REFERENCES CSR.COMPLIANCE_PERMIT_APPLICATION(APP_SID, PERMIT_APPLICATION_ID)
;
CREATE TABLE CSRIMP.COMPL_PERMIT_APPLICATION_PAUSE (
	CSRIMP_SESSION_ID		NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	APPLICATION_PAUSE_ID	NUMBER(10, 0)	NOT NULL,
	PERMIT_APPLICATION_ID	NUMBER(10, 0)	NOT NULL,
	PAUSED_DTM				DATE			NOT NULL,
	RESUMED_DTM				DATE,
	CONSTRAINT PK_COMPL_PERMIT_APP_PAUSE PRIMARY KEY (CSRIMP_SESSION_ID, APPLICATION_PAUSE_ID),
	CONSTRAINT FK_CSRIMP_SESSION_ID FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
)
;
CREATE INDEX csr.ix_compl_permit_app_permit_app ON csr.compl_permit_application_pause (app_sid, permit_application_id);

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_ROLLOUTLVL_RT AS
	OBJECT (
		REGION_SID					NUMBER(10),
		REGION_TYPE					NUMBER(2)
	);
/

CREATE OR REPLACE TYPE CSR.T_COMPLIANCE_RLLVL_RT_TABLE AS
	TABLE OF CSR.T_COMPLIANCE_ROLLOUTLVL_RT;
/

ALTER TABLE CSR.COMPLIANCE_ROOT_REGIONS ADD (ROLLOUT_LEVEL NUMBER(10,0) DEFAULT 1);

ALTER TABLE CSRIMP.COMPLIANCE_ROOT_REGIONS ADD (ROLLOUT_LEVEL NUMBER(10,0));

CREATE TABLE chain.product_metric (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	applies_to_product			NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	applies_to_prod_supplier	NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	product_metric_icon_id		NUMBER(10, 0)	NULL,
	is_mandatory				NUMBER(1, 0)	DEFAULT 0 NOT NULL,
	show_measure				NUMBER(1, 0)	DEFAULT 1 NOT NULL,
	CONSTRAINT pk_product_metric PRIMARY KEY (app_sid, ind_sid),
	CONSTRAINT chk_prod_metric_mand CHECK (is_mandatory IN (0,1)),
	CONSTRAINT chk_prod_met_app_to_prod CHECK (applies_to_product IN (0,1)),
	CONSTRAINT chk_prod_met_app_to_pr_supp CHECK (applies_to_prod_supplier IN (0,1)),
	CONSTRAINT chk_prod_metric_shw_msr CHECK (show_measure IN (0,1))
);
CREATE TABLE chain.product_metric_icon (
	product_metric_icon_id		NUMBER(10,0) 	NOT NULL,
	description					VARCHAR2(255)	NOT NULL,
	icon_path					VARCHAR2(500)	NOT NULL,
	CONSTRAINT pk_product_metric_icon PRIMARY KEY (product_metric_icon_id)
);
CREATE TABLE chain.product_metric_product_type (
	app_sid						NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	product_type_id				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_product_metric_product_type PRIMARY KEY (app_sid, ind_sid, product_type_id)
);
CREATE TABLE csrimp.chain_product_metric (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	applies_to_product			NUMBER(1, 0)	NOT NULL,
	applies_to_prod_supplier	NUMBER(1, 0)	NOT NULL,
	product_metric_icon_id		NUMBER(10, 0)	NULL,
	is_mandatory				NUMBER(1, 0)	NOT NULL,
	show_measure				NUMBER(1, 0)	NOT NULL,
	CONSTRAINT pk_chain_product_metric PRIMARY KEY (csrimp_session_id, ind_sid),
	CONSTRAINT fk_chain_product_metric_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE TABLE csrimp.chain_prd_mtrc_prd_type (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ind_sid						NUMBER(10, 0)	NOT NULL,
	product_type_id				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_chain_prd_mtrc_prd_type PRIMARY KEY (csrimp_session_id, ind_sid, product_type_id),
	CONSTRAINT fk_chain_prd_mtrc_prd_type_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csr.flow_inv_type_alert_class (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_involvement_type_id		NUMBER(10) NOT NULL,
	flow_alert_class				VARCHAR2(256) NOT NULL,
	CONSTRAINT pk_flow_inv_type_alert_class PRIMARY KEY (app_sid, flow_involvement_type_id, flow_alert_class)
);
CREATE TABLE csrimp.flow_inv_type_alert_class (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_involvement_type_id		NUMBER(10) NOT NULL,
	flow_alert_class				VARCHAR2(256) NOT NULL,
	CONSTRAINT pk_flow_inv_type_alert_class PRIMARY KEY (csrimp_session_id, flow_involvement_type_id, flow_alert_class)
);

ALTER TABLE csr.question_tag ADD (SHOW_IN_SURVEY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csr.question_tag ADD CONSTRAINT CK_QUESTION_TAG_SHOW_IN_SURVEY CHECK (SHOW_IN_SURVEY IN (0,1));
ALTER TABLE csrimp.question_tag ADD (SHOW_IN_SURVEY NUMBER(1, 0) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.question_tag ADD CONSTRAINT CK_QUESTION_TAG_SHOW_IN_SURVEY CHECK (SHOW_IN_SURVEY IN (0,1));
BEGIN
  FOR r IN (SELECT p.app_sid, p.profile_id, p.name FROM CSR.EMISSION_FACTOR_PROFILE p
			  JOIN CSR.EMISSION_FACTOR_PROFILE s ON p.app_sid = s.app_sid AND p.name = s.name AND s.profile_id != p.profile_id
			 ORDER BY p.app_sid)
	LOOP
		UPDATE CSR.EMISSION_FACTOR_PROFILE
		   SET name = r.name||'('||r.profile_id||')'
		 WHERE app_sid = r.app_sid
		   AND profile_id = r.profile_id;
	END LOOP;
END;
/
ALTER TABLE CSR.EMISSION_FACTOR_PROFILE ADD CONSTRAINT UK_EMISSION_FACTOR_PROFILE UNIQUE (APP_SID, NAME);
ALTER TABLE csr.compliance_options ADD (
	PERMIT_DOC_LIB_SID 			NUMBER(10)
);
ALTER TABLE csr.doc_folder ADD (
	PERMIT_ITEM_ID	 			NUMBER(10)
);
ALTER TABLE csr.doc_folder ADD CONSTRAINT FK_DOC_FOLDER_PERMIT_ITEM_ID
	FOREIGN KEY (app_sid, permit_item_id)
	REFERENCES csr.compliance_permit(app_sid, compliance_permit_id)
;
ALTER TABLE csr.compliance_options ADD CONSTRAINT FK_COMP_OPTIONS_DOC_LIB_SID
	FOREIGN KEY (app_sid, permit_doc_lib_sid)
	REFERENCES csr.doc_library (app_sid, doc_library_sid)
;
ALTER TABLE csrimp.compliance_options ADD (
	PERMIT_DOC_LIB_SID 			NUMBER(10)
);
ALTER TABLE csrimp.doc_folder ADD (
	PERMIT_ITEM_ID	 			NUMBER(10)
);
CREATE INDEX csr.ix_compli_op_permit_doc_lib ON csr.compliance_options (app_sid, permit_doc_lib_sid);
CREATE INDEX csr.ix_doc_folder_compli_permit ON csr.doc_folder (app_sid, permit_item_id);
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP
  ADD ignore_file_not_found_excptn NUMBER(1) DEFAULT 0 NOT NULL;
  
ALTER TABLE CSR.AUTOMATED_IMPORT_CLASS_STEP
  ADD CONSTRAINT ck_ignore_file_nt_fnd_excptn CHECK (ignore_file_not_found_excptn IN (0, 1));
ALTER TABLE chain.product_metric_val DROP CONSTRAINT fk_product_metric_val_ind;
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	FROM all_constraints
	WHERE constraint_name = 'FK_SUPPLIED_PRDUCT_MTRC_VL_IND' AND owner = 'CHAIN' AND table_name = 'PRODUCT_SUPPLIER_METRIC_VAL';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PRODUCT_SUPPLIER_METRIC_VAL DROP CONSTRAINT FK_SUPPLIED_PRDUCT_MTRC_VL_IND';
	END IF;
END;
/
DECLARE
	v_count NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_count
	FROM all_constraints
	WHERE constraint_name = 'FK_PRODUCT_SUPPLR_MTRC_VL_IND' AND owner = 'CHAIN' AND table_name = 'PRODUCT_SUPPLIER_METRIC_VAL';
	IF v_count > 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.PRODUCT_SUPPLIER_METRIC_VAL DROP CONSTRAINT FK_PRODUCT_SUPPLR_MTRC_VL_IND';
	END IF;
END;
/
DROP TABLE chain.product_metric_ind;
ALTER TABLE chain.product_metric_val ADD CONSTRAINT fk_prd_mtrc_val_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid);
ALTER TABLE chain.product_supplier_metric_val ADD CONSTRAINT fk_prd_suppl_mtrc_val_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid);	
ALTER TABLE chain.product_metric ADD CONSTRAINT fk_prd_mtrc_prd_mtrc_icon
	FOREIGN KEY (product_metric_icon_id)
	REFERENCES chain.product_metric_icon (product_metric_icon_id);
ALTER TABLE chain.product_metric_product_type ADD CONSTRAINT fk_prd_mtrc_prd_type_prd_type
	FOREIGN KEY (app_sid, product_type_id)
	REFERENCES chain.product_type (app_sid, product_type_id)
;
ALTER TABLE chain.product_metric_product_type ADD CONSTRAINT fk_prd_mtrc_prd_type_prd_mtrc
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric (app_sid, ind_sid)
;
DROP TABLE CMS.TT_ID_NO_INDEX;
ALTER TABLE csr.flow_inv_type_alert_class
  ADD CONSTRAINT fk_flow_inv_type_alert_class FOREIGN KEY (app_sid, flow_involvement_type_id)
	  REFERENCES csr.flow_involvement_type (app_sid, flow_involvement_type_id);
ALTER TABLE csr.flow_inv_type_alert_class
  ADD CONSTRAINT fk_inv_type_flow_alert_class FOREIGN KEY (app_sid, flow_alert_class)
	  REFERENCES csr.customer_flow_alert_class (app_sid, flow_alert_class);
ALTER TABLE csrimp.flow_inv_type_alert_class
  ADD CONSTRAINT fk_flow_inv_type_alert_cls_is FOREIGN KEY (csrimp_session_id)
	  REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
ALTER TABLE csr.flow_involvement_type RENAME COLUMN flow_alert_class TO product_area;
ALTER TABLE csrimp.flow_involvement_type RENAME COLUMN flow_alert_class TO product_area;
create index csr.ix_flow_inv_type_flow_alert_cl on csr.flow_inv_type_alert_class (app_sid, flow_alert_class);


GRANT SELECT,INSERT,UPDATE ON CSR.COMPL_PERMIT_APPLICATION_PAUSE TO CSRIMP;
GRANT SELECT ON CSR.APPLICATION_PAUSE_ID_SEQ TO CSRIMP;
grant select, insert, update on chain.product_metric to csrimp;
grant select, insert, update on chain.product_metric_product_type to csrimp;
grant select, insert, update, delete on csrimp.chain_product_metric to tool_user;
grant select, insert, update, delete on csrimp.chain_prd_mtrc_prd_type to tool_user;
grant select, insert, update on chain.product_metric to CSR;
grant select, insert, update on chain.product_metric_product_type to CSR;
BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description)
	VALUES (97, 'API integrations', 'EnableApiIntegrations', '(In development - Dont run unless you know what you are doing!) Enables API integrations. Will create a user if the specified username doesnt exist yet');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'User name', 0, 'The name of the user the integration will connect as. If the name specified doesnt exist, it will be created (as a hidden user).');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'Client id', 1, 'A secure string for the client ID. Generate a GUID perhaps.');
	INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
	VALUES (97, 'Client secret', 2, 'Akin to a password. Should be kept secure. Generate a GUID perhaps.');
END;
/
GRANT SELECT, DELETE ON csr.region_role_member TO chain WITH GRANT OPTION;
GRANT SELECT, INSERT, REFERENCES ON csr.flow_inv_type_alert_class TO chain;
GRANT INSERT ON csr.flow_inv_type_alert_class TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_inv_type_alert_class TO tool_user;
GRANT SELECT ON chain.v$all_purchaser_involvement TO csr;
GRANT SELECT ON chain.v$purchaser_involvement TO csr;


ALTER TABLE chain.product_metric  ADD CONSTRAINT fk_product_metric_ind
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES csr.ind (app_sid, ind_sid)
;


CREATE OR REPLACE VIEW csr.v$doc_folder AS
	SELECT df.doc_folder_sid, df.description, df.lifespan_is_override, df.lifespan,
		   df.approver_is_override, df.approver_sid, df.company_sid, df.is_system_managed,
		   df.property_sid, dfnt.lang, dfnt.translated, df.permit_item_id
	  FROM doc_folder df
	  JOIN doc_folder_name_translation dfnt ON df.app_sid = dfnt.app_sid AND df.doc_folder_sid = dfnt.doc_folder_sid
	 WHERE dfnt.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');
CREATE OR REPLACE VIEW csr.v$flow_involvement_type AS
	SELECT fit.app_sid, fit.flow_involvement_type_id, fit.product_area, fit.label, fit.css_class, fit.lookup_key,
		   fitac.flow_alert_class
	  FROM csr.flow_involvement_type fit
	  JOIN csr.flow_inv_type_alert_class fitac ON fit.flow_involvement_type_id = fitac.flow_involvement_type_id;




INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (32, 'application', 'Determination paused');
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.NEXTVAL, 21, 'Permit document library', '/csr/site/compliance/controls/DocLibTab.js', 
	'Credit360.Compliance.Controls.DocLibTab', 'Credit360.Compliance.Plugins.DocLibTab', 'Shows document library for a permit item.');

CREATE OR REPLACE PACKAGE  CSR.doc_folder_pkg  AS
-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
);
END;
/
CREATE OR REPLACE PACKAGE BODY CSR.doc_folder_pkg  AS
-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;
END;
/

CREATE OR REPLACE PACKAGE CSR.doc_lib_pkg AS

-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
);

END;
/

CREATE OR REPLACE PACKAGE BODY CSR.doc_lib_pkg AS

-- security interface procs
PROCEDURE CreateObject(
	in_act					IN security_pkg.T_ACT_ID, 
	in_sid_id				IN security_pkg.T_SID_ID, 
	in_class_id				IN security_pkg.T_CLASS_ID, 
	in_name					IN security_pkg.T_SO_NAME, 
	in_parent_sid_id		IN security_pkg.T_SID_ID
)
AS
BEGIN
	NULL;
END;
END;
/

DECLARE
	v_comp_lib_folder_sid		NUMBER(10);
	v_doclib_sid				NUMBER(10);
	v_act_id					security.security_pkg.T_ACT_ID;
	PROCEDURE CreateLibrary(
		in_parent_sid_id			IN	security.security_pkg.T_SID_ID,
		in_library_name				IN	security.security_pkg.T_SO_NAME,
		in_documents_name			IN	security.security_pkg.T_SO_NAME,
		in_trash_name				IN	security.security_pkg.T_SO_NAME,
		in_app_sid					IN	security.security_pkg.T_SID_ID,
		out_doc_library_sid			OUT	security.security_pkg.T_SID_ID
	)
	AS
		v_documents_sid				security.security_pkg.T_SID_ID;
		v_trash_folder_sid			security.security_pkg.T_SID_ID;
		PROCEDURE CreateFolder(
			in_parent_sid					IN	security.security_pkg.T_SID_ID,
			in_name							IN	security.security_pkg.T_SO_NAME,
			in_description					IN	csr.doc_folder.description%TYPE DEFAULT EMPTY_CLOB(),
			in_approver_is_override			IN	csr.doc_folder.approver_is_override%TYPE DEFAULT 0,
			in_approver_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_lifespan_is_override			IN	csr.doc_folder.lifespan_is_override%TYPE DEFAULT 0,
			in_lifespan						IN	csr.doc_folder.lifespan%TYPE DEFAULT NULL,
			in_company_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_property_sid					IN	security.security_pkg.T_SID_ID DEFAULT NULL,
			in_is_system_managed			IN	csr.doc_folder.is_system_managed%TYPE DEFAULT 0,
			in_permit_item_id				IN  security.security_pkg.T_SID_ID DEFAULT NULL,
			out_sid_id						OUT	security.security_pkg.T_SID_ID
		)
		AS
			v_lifespan						csr.doc_folder.lifespan%TYPE;
			v_approver_sid					security.security_pkg.T_SID_ID;
			v_company_sid					security.security_pkg.T_SID_ID;
			v_property_sid					security.security_pkg.T_SID_ID;
			v_parent_is_doc_lib				security.security_pkg.T_SID_ID;
			v_name							security.security_pkg.T_SO_NAME := in_name;
			v_permit_item_id				security.security_pkg.T_SID_ID;
		BEGIN
			-- For system managed folders e.g. Documents, Recycle bin keep so name else set so name to null
			IF in_is_system_managed = 0 THEN
				v_name := NULL;
			END IF;
		
			security.Securableobject_Pkg.CreateSO(security.security_pkg.GetACT(), in_parent_sid, 
				security.class_pkg.GetClassId('DocFolder'), v_name, out_sid_id);
			
			BEGIN
				SELECT lifespan, approver_sid, company_sid, property_sid, permit_item_id
				  INTO v_lifespan, v_approver_sid, v_company_sid, v_property_sid, v_permit_item_id
				  FROM csr.doc_folder
				 WHERE doc_folder_sid = in_parent_sid;
			EXCEPTION	
				WHEN NO_DATA_FOUND THEN
					NULL; -- ignore - probably this is under the root
			END;
			
			INSERT INTO csr.doc_folder (doc_folder_sid, description, lifespan, approver_sid, company_sid, 
									property_sid, is_system_managed, permit_item_id)		  
				SELECT out_sid_id doc_folder_sid, in_description description, 
					CASE WHEN in_lifespan_is_override = 1 THEN in_lifespan ELSE v_lifespan END, 
					CASE WHEN in_approver_is_override = 1 THEN in_approver_sid ELSE v_approver_sid END,
					NVL(in_company_sid, v_company_sid), NVL(in_property_sid, v_property_sid), in_is_system_managed,
					NVL(in_permit_item_id, v_permit_item_id)
				  FROM dual;
		
			INSERT INTO csr.doc_folder_name_translation (doc_folder_sid, lang, translated)
			SELECT out_sid_id, lang, in_name
			  FROM csr.v$customer_lang;
		END;
	BEGIN
		security.securableObject_pkg.CreateSO(security.security_pkg.GetACT(), in_parent_sid_id, 
			security.class_pkg.GetClassId('DocLibrary'), in_library_name, out_doc_library_sid);
		
		CreateFolder(
			in_parent_sid			=> out_doc_library_sid, 
			in_name					=> in_documents_name,
			in_is_system_managed	=> 1,
			out_sid_id				=> v_documents_sid
		);
	
		CreateFolder(
			in_parent_sid			=> out_doc_library_sid, 
			in_name					=> in_trash_name,
			in_is_system_managed	=> 1,
			out_sid_id				=> v_trash_folder_sid
		);
	
		INSERT INTO csr.doc_library (app_sid, doc_library_sid, documents_sid, trash_folder_sid)
		VALUES (in_app_sid, out_doc_library_sid, v_documents_sid, v_trash_folder_sid);
	END;	
BEGIN
	security.user_pkg.LogonAdmin();
	
	FOR r IN (
		SELECT co.app_sid, c.host 
		  FROM csr.compliance_options co
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	)
	LOOP
		security.user_pkg.LogonAdmin(r.host);
		v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
		
		BEGIN
			security.SecurableObject_pkg.CreateSO(v_act_id, r.app_sid, security.security_pkg.SO_CONTAINER, 'ComplianceDocLibs', v_comp_lib_folder_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_comp_lib_folder_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'ComplianceDocLibs');
		END;
		BEGIN
			CreateLibrary(
				v_comp_lib_folder_sid,
				'Permits',
				'Documents',
				'Recycle bin',
				r.app_sid,
				v_doclib_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				v_doclib_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'ComplianceDocLibs/Permits');
		END;
		UPDATE csr.compliance_options
		   SET permit_doc_lib_sid = v_doclib_sid
		 WHERE app_sid = r.app_sid;
		 
		 security.user_pkg.LogonAdmin();
	END LOOP;
END;
/
INSERT INTO chain.product_metric_icon(product_metric_icon_id, description, icon_path) VALUES(1, 'Weight', '/fp/shared/images/productWeight.gif');
INSERT INTO chain.product_metric_icon(product_metric_icon_id, description, icon_path) VALUES(2, 'Volume', '/fp/shared/images/productVolume.gif');
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
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
/
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  								/* CT_COMPANIES */
		in_capability		=> 'Product metric values', 			/* PRODUCT_METRIC_VAL */
		in_perm_type		=> 0 									/* SPECIFIC_PERMISSION */
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  									/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product metric values of suppliers',/* PRODUCT_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 									/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 10,  								/* CT_COMPANIES */
		in_capability		=> 'Supplier product metric values',	/* PRD_SUPP_METRIC_VAL */
		in_perm_type		=> 0 									/* SPECIFIC_PERMISSION */
	);
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  									/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product metric values of suppliers',/* PRD_SUPP_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 									/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;
create or replace procedure csr.createIndex(
	in_sql							in	varchar2
) authid current_user
as
	e_name_in_use					exception;
	pragma exception_init(e_name_in_use, -00955);
begin
	begin
		dbms_output.put_line(in_sql);
		execute immediate in_sql;
	exception
		when e_name_in_use then
			null;
	end;
end;
/
begin
	csr.createIndex('create index chain.ix_prd_mtrc_prd_mtrc_icon on chain.product_metric (product_metric_icon_id)');
	csr.createIndex('create index chain.ix_prd_mtrc_prd_type_prd_type on chain.product_metric_product_type (app_sid, product_type_id)');
	csr.createIndex('create index chain.ix_prd_mtrc_prd_type_prd_mtrc on chain.product_metric_product_type (app_sid, ind_sid)');
end;
/
drop procedure csr.createIndex;
create or replace package csr.period_span_pattern_pkg as end;
/
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) values (66, 'Permit module types import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (66, 'Permit module types import', 'Credit360.ExportImport.Batched.Import.Importers.PermitModuleTypesImporter');
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (67, 'Permits import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (67, 'Permits import', 'Credit360.ExportImport.Batched.Import.Importers.PermitsImporter');
INSERT INTO csr.batch_job_type (batch_job_type_id, description, plugin_name, notify_address, max_retries, priority, timeout_mins) 
VALUES (68, 'Conditions import', 'batch-importer', 'support@credit360.com', 3, 1, 120);
INSERT INTO csr.batched_import_type (BATCH_JOB_TYPE_ID, LABEL, ASSEMBLY)
VALUES (68, 'Conditions import', 'Credit360.ExportImport.Batched.Import.Importers.ConditionsImporter');
BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.flow_inv_type_alert_class (app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT fit.app_sid, fit.flow_involvement_type_id, fit.product_area
	  FROM csr.flow_involvement_type fit
	 WHERE NOT EXISTS (
		SELECT 1
		  FROM csr.flow_inv_type_alert_class
		 WHERE app_sid = fit.app_sid
		   AND flow_involvement_type_id = fit.flow_involvement_type_id
		   AND flow_alert_class = fit.product_area
	);
	security.user_pkg.LogOff(SYS_CONTEXT('SECURITY', 'ACT'));
END;
/
CREATE OR REPLACE PROCEDURE chain.Temp_RegisterCapability (
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
/
BEGIN
	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  									/* CT_ON_BEHALF_OF */
		in_capability		=> 'Supplier product metric values of suppliers',/* PRD_SUPP_METRIC_VAL_SUPP */
		in_perm_type		=> 0, 									/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/
DROP PROCEDURE chain.Temp_RegisterCapability;




CREATE OR REPLACE PACKAGE chain.product_metric_pkg AS
    PROCEDURE dummy;
END;
/
CREATE OR REPLACE PACKAGE BODY chain.product_metric_pkg AS
    PROCEDURE dummy
    AS
    BEGIN
        NULL;
    END;
END;
/
GRANT EXECUTE ON chain.product_metric_pkg TO web_user;
grant execute on csr.period_span_pattern_pkg TO web_user;
CREATE OR REPLACE PACKAGE csr.permit_data_import_pkg AS END;
/
GRANT EXECUTE ON csr.permit_data_import_pkg TO web_user;


@..\question_library_pkg
@..\automated_export_pkg
@..\automated_export_import_pkg
@..\csr_data_pkg
@..\permit_pkg
@..\schema_pkg
@..\doc_lib_pkg
@..\doc_folder_pkg
@..\automated_import_pkg
@..\chain\chain_pkg
@..\chain\product_metric_pkg
@..\enable_pkg
@..\period_span_pattern_pkg
@..\issue_pkg
@..\permit_data_import_pkg
@..\compliance_pkg
@..\flow_pkg


@..\question_library_body
@..\issue_report_body
@..\enable_body
@..\templated_report_body
@..\factor_body
@..\automated_export_body
@..\automated_export_import_body
@..\permit_body
@..\compliance_setup_body
@..\schema_body
@..\csrimp\imp_body
@..\doc_folder_body
@..\doc_lib_body
@..\doc_body
@..\automated_import_body
@..\compliance_body
@..\chain\chain_body
@..\chain\product_body
@..\chain\product_metric_body
@..\meter_monitor_body
@..\..\..\aspen2\cms\db\filter_body
@ ..\quick_survey_body
@..\period_span_pattern_body
@..\issue_body
@..\permit_data_import_body
@..\quick_survey_body
@..\csr_app_body
@..\flow_body
@..\audit_body
@..\training_flow_helper_body
@..\chain\setup_body
@..\indicator_body
@..\sheet_body

@update_tail
