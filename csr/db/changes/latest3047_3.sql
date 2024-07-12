-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- normally I'd try to move the data in here into the new columns,
-- but no customers are using this yet so we don't need to do that.
drop table chain.company_product_version_tr;
drop table chain.company_product_version;
drop view chain.v$company_product_current_vers;
drop view chain.v$company_product_version;

/* COMPANY PRODUCT */

delete from chain.company_product;
ALTER TABLE chain.company_product DROP CONSTRAINT fk_company_product_edit_user;
ALTER TABLE chain.company_product DROP COLUMN last_edited_by;
ALTER TABLE chain.company_product DROP COLUMN last_edited_dtm;

ALTER TABLE chain.company_product ADD (
	SKU						VARCHAR2(1024) NOT NULL,
	IS_ACTIVE					NUMBER(1) NOT NULL
);

CREATE UNIQUE INDEX CHAIN.IX_COMPANY_PRODUCT_SKU ON CHAIN.COMPANY_PRODUCT(APP_SID, COMPANY_SID, LOWER(SKU));

CREATE TABLE chain.company_product_tr (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id				NUMBER(10) NOT NULL,
	lang					VARCHAR2(10) NOT NULL,
	description				VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPANY_PRODUCT_VERSION_TR PRIMARY KEY (app_sid, product_id, lang),
	CONSTRAINT FK_COMPANY_PRODUCT_VERSION_TR FOREIGN KEY (app_sid, product_id) REFERENCES chain.company_product (app_sid, product_id)
);

/* SUPPLIED PRODUCT */

CREATE SEQUENCE chain.product_supplier_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.product_supplier (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id					NUMBER(10) NOT NULL,
	product_supplier_id			NUMBER(10) NOT NULL,
	purchaser_company_sid		NUMBER(10) NOT NULL,
	supplier_company_sid		NUMBER(10) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE,
	CONSTRAINT pk_product_supplier PRIMARY KEY (app_sid, product_supplier_id),
	CONSTRAINT uk_product_supplier UNIQUE (product_id, purchaser_company_sid, supplier_company_sid)
);

ALTER TABLE chain.product_supplier ADD CONSTRAINT fk_product_supplier_rel
	FOREIGN KEY (app_sid, supplier_company_sid, purchaser_company_sid) 
	REFERENCES chain.supplier_relationship(app_sid, supplier_company_sid, purchaser_company_sid);
	
ALTER TABLE chain.product_supplier ADD CONSTRAINT fk_product_supplier_product
	FOREIGN KEY (app_sid, product_id)
	REFERENCES chain.company_product (app_sid, product_id);

/* PLUGINS */
DROP TABLE chain.product_header;
DROP TABLE chain.product_tab;
DROP TABLE csrimp.chain_product_header;
DROP TABLE csrimp.chain_product_tab;

CREATE TABLE CHAIN.PRODUCT_HEADER(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	VIEWING_OWN_PRODUCT    NUMBER(1),
	VIEWING_AS_SUPPLIER    NUMBER(1),
	PRODUCT_COL_SID		   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	CONSTRAINT CHK_PRD_HEAD_VIEW_OWN_CMP_1_0 CHECK (VIEWING_OWN_PRODUCT IS NULL OR VIEWING_OWN_PRODUCT IN (1, 0)),
	CONSTRAINT CHK_PRD_HEAD_VIEW_AS_SUPP_1_0 CHECK (VIEWING_AS_SUPPLIER IS NULL OR VIEWING_AS_SUPPLIER IN (1, 0)),
	CONSTRAINT PRODUCT_HEADER_PK PRIMARY KEY (APP_SID, PRODUCT_HEADER_ID)
);

CREATE TABLE CHAIN.PRODUCT_HEADER_PRODUCT_TYPE (
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	PRODUCT_TYPE_ID		   NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PRODUCT_HEADER_PRODUCT_TYPE PRIMARY KEY (APP_SID, PRODUCT_HEADER_ID, PRODUCT_TYPE_ID)
);

ALTER TABLE CHAIN.PRODUCT_HEADER_PRODUCT_TYPE ADD CONSTRAINT FK_PRODUCT_HEADER_PROD_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_HEADER_ID)
    REFERENCES CHAIN.PRODUCT_HEADER(APP_SID, PRODUCT_HEADER_ID)
;

ALTER TABLE CHAIN.PRODUCT_HEADER_PRODUCT_TYPE ADD CONSTRAINT FK_PRODUCT_HEADER_PROD_TYPE_PT
    FOREIGN KEY (APP_SID, PRODUCT_TYPE_ID)
    REFERENCES CHAIN.PRODUCT_TYPE(APP_SID, PRODUCT_TYPE_ID)
;

CREATE TABLE CHAIN.PRODUCT_HEADER_COMPANY_TYPE (
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	COMPANY_TYPE_ID		   NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PRODUCT_HEADER_COMPANY_TYPE PRIMARY KEY (APP_SID, PRODUCT_HEADER_ID, COMPANY_TYPE_ID)
);

ALTER TABLE CHAIN.PRODUCT_HEADER_COMPANY_TYPE ADD CONSTRAINT FK_PRODUCT_HEADER_COMP_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_HEADER_ID)
    REFERENCES CHAIN.PRODUCT_HEADER(APP_SID, PRODUCT_HEADER_ID)
;

ALTER TABLE CHAIN.PRODUCT_HEADER_COMPANY_TYPE ADD CONSTRAINT FK_PRODUCT_HEADER_COMP_TYPE_CT
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

CREATE TABLE CHAIN.PRODUCT_TAB(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	LABEL                  VARCHAR2(254)     NOT NULL,
	VIEWING_OWN_PRODUCT    NUMBER(1),
	VIEWING_AS_SUPPLIER    NUMBER(1),
	PRODUCT_COL_SID		   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	CONSTRAINT CHK_PRD_TAB_VIEW_OWN_CMP_1_0 CHECK (VIEWING_OWN_PRODUCT IS NULL OR VIEWING_OWN_PRODUCT IN (1, 0)),
	CONSTRAINT CHK_PRD_TAB_VIEW_AS_SUPP_1_0 CHECK (VIEWING_AS_SUPPLIER IS NULL OR VIEWING_AS_SUPPLIER IN (1, 0)),
	CONSTRAINT PRODUCT_TAB_PK PRIMARY KEY (APP_SID, PRODUCT_TAB_ID)
);

CREATE TABLE CHAIN.PRODUCT_TAB_PRODUCT_TYPE (
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	PRODUCT_TYPE_ID		   NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PRODUCT_TAB_PRODUCT_TYPE PRIMARY KEY (APP_SID, PRODUCT_TAB_ID, PRODUCT_TYPE_ID)
);

ALTER TABLE CHAIN.PRODUCT_TAB_PRODUCT_TYPE ADD CONSTRAINT FK_PRODUCT_TAB_PROD_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_TAB_ID)
    REFERENCES CHAIN.PRODUCT_TAB(APP_SID, PRODUCT_TAB_ID)
;

ALTER TABLE CHAIN.PRODUCT_TAB_PRODUCT_TYPE ADD CONSTRAINT FK_PRODUCT_TAB_PROD_TYPE_PT
    FOREIGN KEY (APP_SID, PRODUCT_TYPE_ID)
    REFERENCES CHAIN.PRODUCT_TYPE(APP_SID, PRODUCT_TYPE_ID)
;

CREATE TABLE CHAIN.PRODUCT_TAB_COMPANY_TYPE (
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	COMPANY_TYPE_ID		   NUMBER(10, 0)     NOT NULL,
	CONSTRAINT PK_PRODUCT_TAB_COMPANY_TYPE PRIMARY KEY (APP_SID, PRODUCT_TAB_ID, COMPANY_TYPE_ID)
);

ALTER TABLE CHAIN.PRODUCT_TAB_COMPANY_TYPE ADD CONSTRAINT FK_PRODUCT_TAB_COMP_TYPE_PH
    FOREIGN KEY (APP_SID, PRODUCT_TAB_ID)
    REFERENCES CHAIN.PRODUCT_TAB(APP_SID, PRODUCT_TAB_ID)
;

ALTER TABLE CHAIN.PRODUCT_TAB_COMPANY_TYPE ADD CONSTRAINT FK_PRODUCT_TAB_COMP_TYPE_CT
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;

CREATE TABLE CSRIMP.CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	VIEWING_OWN_PRODUCT    NUMBER(1),
	VIEWING_AS_SUPPLIER    NUMBER(1),
	PRODUCT_COL_SID		   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	CONSTRAINT PK_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_HEADER_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	LABEL                  VARCHAR2(254)     NOT NULL,
	VIEWING_OWN_PRODUCT    NUMBER(1),
	VIEWING_AS_SUPPLIER    NUMBER(1),
	PRODUCT_COL_SID		   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	CONSTRAINT PK_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_TAB_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

/* METRICS */
CREATE TABLE chain.product_metric_agg_rule (
	rule_type_id				NUMBER(2) NOT NULL,
	label						VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_product_metric_agg_rule PRIMARY KEY (rule_type_id)
);

CREATE TABLE chain.product_metric_ind (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	ind_sid						NUMBER(10) NOT NULL,
	agg_rule_type_id			NUMBER(2) NOT NULL,
	CONSTRAINT pk_product_metric_ind PRIMARY KEY (app_sid, ind_sid)
);

ALTER TABLE chain.product_metric_ind ADD CONSTRAINT fk_product_metric_ind_rule_typ
	FOREIGN KEY (agg_rule_type_id)
	REFERENCES chain.product_metric_agg_rule (rule_type_id);

CREATE SEQUENCE chain.product_metric_val_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE chain.product_metric_val (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_metric_val_id		NUMBER(10) NOT NULL,
	product_id					NUMBER(10) NOT NULL,
	ind_sid						NUMBER(10) NOT NULL,
	start_dtm					DATE NOT NULL,
	end_dtm						DATE NOT NULL,
	val_number					NUMBER(24, 10) NOT NULL,
	entered_as_val_number		NUMBER(24, 10),
	measure_conversion_id		NUMBER(10),
	entered_dtm					DATE,
	entered_by_sid				NUMBER(10) NOT NULL,
	CONSTRAINT pk_product_metric_val PRIMARY KEY (app_sid, product_metric_val_id),
	CONSTRAINT uk_product_metric_val UNIQUE (app_sid, product_id, ind_sid, start_dtm),
	CONSTRAINT ck_product_metric_val_dtm CHECK (start_dtm < end_dtm)
);

ALTER TABLE chain.product_metric_val ADD CONSTRAINT fk_product_metric_val_product
	FOREIGN KEY (app_sid, product_id)
	REFERENCES chain.company_product (app_sid, product_id);

ALTER TABLE chain.product_metric_val ADD CONSTRAINT fk_product_metric_val_ind
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric_ind (app_sid, ind_sid);

CREATE SEQUENCE chain.product_supplr_mtrc_val_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
	
CREATE TABLE chain.product_supplier_metric_val (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	supplier_product_metric_val_id	NUMBER(10) NOT NULL,
	product_supplier_id				NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10) NOT NULL,
	start_dtm						DATE NOT NULL,
	end_dtm							DATE NOT NULL,
	val_number						NUMBER(24, 10) NOT NULL,
	entered_as_val_number			NUMBER(24, 10),
	measure_conversion_id			NUMBER(10),
	entered_dtm						DATE,
	entered_by_sid					NUMBER(10) NOT NULL,
	CONSTRAINT pk_product_supplier_metric_val PRIMARY KEY (app_sid, supplier_product_metric_val_id),
	CONSTRAINT uk_product_supplier_metric_val UNIQUE (app_sid, product_supplier_id, ind_sid, start_dtm),
	CONSTRAINT ck_product_supplr_mtrc_vl_dtm CHECK (start_dtm < end_dtm)
);

ALTER TABLE chain.product_supplier_metric_val ADD CONSTRAINT fk_product_supplr_mtrc_prduct
	FOREIGN KEY (app_sid, product_supplier_id)
	REFERENCES chain.product_supplier (app_sid, product_supplier_id);

ALTER TABLE chain.product_supplier_metric_val ADD CONSTRAINT fk_product_supplr_mtrc_vl_ind
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES chain.product_metric_ind (app_sid, ind_sid);	
	
/* CERTIFICATIONS */
CREATE TABLE chain.company_product_required_cert	(
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id					NUMBER(10) NOT NULL,
	certification_type_id		NUMBER(10) NOT NULL,
	from_dtm					DATE NOT NULL,
	to_dtm						DATE,
	CONSTRAINT pk_company_product_reqrd_crt PRIMARY KEY (app_sid, product_id, certification_type_id)
);

ALTER TABLE chain.company_product_required_cert ADD CONSTRAINT fk_cmpny_prdct_rqrd_crt_prdct
	FOREIGN KEY (app_sid, product_id)
	REFERENCES chain.company_product (app_sid, product_id);
	
CREATE TABLE chain.company_product_certification (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id					NUMBER(10) NOT NULL,
	certification_id			NUMBER(10) NOT NULL,
	applied_dtm					DATE NOT NULL,
	CONSTRAINT pk_company_product_certificatn PRIMARY KEY (app_sid, product_id, certification_id)
);	

ALTER TABLE chain.company_product_certification ADD CONSTRAINT fk_company_product_cert_prdct
	FOREIGN KEY (app_sid, product_id)
	REFERENCES chain.company_product (app_sid, product_id);


CREATE TABLE chain.product_supplier_certification (
	app_sid						NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_supplier_id			NUMBER(10) NOT NULL,
	certification_id			NUMBER(10) NOT NULL,
	applied_dtm					DATE NOT NULL,
	CONSTRAINT pk_product_supplier_certifictn PRIMARY KEY (app_sid, product_supplier_id, certification_id)
);	

ALTER TABLE chain.product_supplier_certification ADD CONSTRAINT fk_product_supplier_cert_prdct
	FOREIGN KEY (app_sid, product_supplier_id)
	REFERENCES chain.product_supplier (app_sid, product_supplier_id);
	
-- Alter tables
DECLARE
	v_nextval		NUMBER(10,0);
BEGIN
	SELECT chain.certification_id_seq.NEXTVAL INTO v_nextval FROM dual;
	EXECUTE IMMEDIATE 'DROP SEQUENCE chain.certification_id_seq';
	EXECUTE IMMEDIATE 'CREATE SEQUENCE chain.certification_type_id_seq START WITH '  || v_nextval || ' INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

ALTER TABLE chain.certification RENAME TO certification_type;
ALTER TABLE chain.certification_type RENAME COLUMN certification_id TO certification_type_id;

ALTER TABLE csrimp.chain_certification RENAME TO chain_certification_type;
ALTER TABLE csrimp.chain_certification_type RENAME COLUMN certification_id TO certification_type_id;

ALTER TABLE chain.certification_audit_type RENAME TO cert_type_audit_type;
ALTER TABLE chain.cert_type_audit_type DROP CONSTRAINT fk_cert_audit_type_cert;
ALTER TABLE chain.cert_type_audit_type RENAME COLUMN certification_id TO certification_type_id;
ALTER TABLE chain.cert_type_audit_type ADD CONSTRAINT fk_cert_audit_type_cert 
	FOREIGN KEY (app_sid, certification_type_id)
	REFERENCES chain.certification_type(app_sid, certification_type_id);
	
ALTER TABLE csrimp.chain_cert_aud_type RENAME TO chain_cert_type_audit_type;
ALTER TABLE csrimp.chain_cert_type_audit_type RENAME COLUMN certification_id TO certification_type_id;

ALTER TABLE csrimp.map_chain_certification RENAME TO map_chain_cert_type;
ALTER TABLE csrimp.map_chain_cert_type RENAME COLUMN old_certification_id TO old_cert_type_id;
ALTER TABLE csrimp.map_chain_cert_type RENAME COLUMN new_certification_id TO new_cert_type_id;
	
ALTER TABLE chain.company_product_required_cert ADD CONSTRAINT fk_cmpny_prdct_rqrd_crt_crt
	FOREIGN KEY (app_sid, certification_type_id)
	REFERENCES chain.certification_type (app_sid, certification_type_id);

-- *** Grants ***
grant select on chain.certification_type_id_seq to csrimp;
grant select, insert on chain.product_header to csr;
grant select, insert on chain.product_tab to csr;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID);

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID);

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PRODUCT_HDR_PRODUCT_COL
	FOREIGN KEY (APP_SID, PRODUCT_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PRODUCT_HDR_USER_COMP_COL
	FOREIGN KEY (APP_SID, USER_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_PRODUCT_COL
	FOREIGN KEY (APP_SID, product_col_sid)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_USER_COMP_COL
	FOREIGN KEY (APP_SID, USER_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);

ALTER TABLE chain.company_product_certification ADD CONSTRAINT fk_comp_prod_cert_cert
	FOREIGN KEY (app_sid, certification_id)
	REFERENCES csr.internal_audit (app_sid, internal_audit_sid);
	
ALTER TABLE chain.product_supplier_certification ADD CONSTRAINT fk_prod_supp_cert_cert
	FOREIGN KEY (app_sid, certification_id)
	REFERENCES csr.internal_audit (app_sid, internal_audit_sid);

ALTER TABLE chain.product_metric_ind  ADD CONSTRAINT fk_product_metric_ind_ind
	FOREIGN KEY (app_sid, ind_sid)
	REFERENCES csr.ind (app_sid, ind_sid);

ALTER TABLE chain.product_metric_val ADD CONSTRAINT fk_product_mtrc_val_entrd_usr
	FOREIGN KEY (app_sid, entered_by_sid)
	REFERENCES csr.csr_user (app_sid, csr_user_sid);
	
ALTER TABLE chain.product_supplier_metric_val ADD CONSTRAINT fk_prdct_spld_mtrc_vl_entd_usr
	FOREIGN KEY (app_sid, entered_by_sid)
	REFERENCES csr.csr_user (app_sid, csr_user_sid);

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.	  

CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.product_id, tr.description product_name, cp.company_sid, cp.product_type_id,
		   cp.sku, cp.lookup_key, cp.is_active
	  FROM chain.company_product cp
	  JOIN chain.company_product_tr tr ON tr.product_id = cp.product_id AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en');

CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_type_id, ia.internal_audit_sid certification_id,
		   ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.cert_type_audit_type cat 
	JOIN csr.internal_audit ia ON ia.internal_audit_type_id = cat.internal_audit_type_id
	 AND cat.app_sid = ia.app_sid
	 AND ia.deleted = 0
	JOIN csr.supplier s  ON ia.region_sid = s.region_sid AND s.app_sid = ia.app_sid
	LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id 
	 AND ia.internal_audit_type_id = atct.internal_audit_type_id
	 AND ia.app_sid = atct.app_sid
	LEFT JOIN csr.audit_closure_type act ON atct.audit_closure_type_id = act.audit_closure_type_id 
	 AND act.app_sid = atct.app_sid
   WHERE NVL(act.is_failure, 0) = 0
	 AND (ia.flow_item_id IS NULL 
	  OR EXISTS(
			SELECT fi.flow_item_id 
			  FROM csr.flow_item fi 
			  JOIN csr.flow_state fs ON fs.flow_state_id = fi.current_state_id AND fs.is_final = 1 
			 WHERE fi.flow_item_id = ia.flow_item_id));
	   
-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO chain.product_metric_agg_rule (rule_type_id, label) VALUES (1, 'Sum');
	INSERT INTO chain.product_metric_agg_rule (rule_type_id, label) VALUES (2, 'Average');
	INSERT INTO chain.product_metric_agg_rule (rule_type_id, label) VALUES (3, 'Take lowest');	
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
		in_capability_type	=> 10,  							/* CT_COMPANIES*/
		in_capability		=> 'Create products', 		 		/* CREATE_PRODUCTS */
		in_perm_type		=> 1 								/* BOOLEAN_PERMISSION */
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 1,  								/* CT_COMPANY */
		in_capability		=> 'Products as supplier', 			/* PRODUCTS_AS_SUPPLIER */
		in_perm_type		=> 1 								/* BOOLEAN_PERMISSION */
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  								/* CT_SUPPLIER */
		in_capability		=> 'Product suppliers', 			/* PRODUCT_SUPPLIERS */
		in_perm_type		=> 0, 								/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  								/* CT_ON_BEHALF_OF */
		in_capability		=> 'Product suppliers', 			/* PRODUCT_SUPPLIERS */
		in_perm_type		=> 0, 								/* SPECIFIC_PERMISSION */
		in_is_supplier		=> 1
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 2,  								/* CT_SUPPLIER */
		in_capability		=> 'Add supplier to products', 		/* ADD_PRODUCT_SUPPLIER */
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier		=> 1
	);

	chain.Temp_RegisterCapability(
		in_capability_type	=> 3,  								/* CT_ON_BEHALF_OF */
		in_capability		=> 'Add supplier to products', 		/* ADD_PRODUCT_SUPPLIER */
		in_perm_type		=> 1, 								/* BOOLEAN_PERMISSION */
		in_is_supplier		=> 1
	);
END;
/

DROP PROCEDURE chain.Temp_RegisterCapability;

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Company Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductCompanyFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productCompanyFilterAdapter.js';
	v_js_class := 'Credit360.Chain.Filters.ProductCompanyFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;

	v_desc := 'Product Supplier Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierFilterAdapter.js';
	v_js_class := 'Credit360.Chain.Filters.ProductSupplierFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

DECLARE
	v_card_id						NUMBER(10);
BEGIN
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Chain.Filters.ProductCompanyFilterAdapter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Company Filter Adapter', 'chain.product_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Chain.Filters.ProductSupplierFilterAdapter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Filter Adapter', 'chain.product_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_data_pkg
@../chain/chain_pkg
@../chain/certification_pkg
@../chain/certification_report_pkg
@../chain/company_product_pkg
@../chain/plugin_pkg
@../chain/product_report_pkg
@../chain/product_type_pkg

@../chain/chain_body
@../chain/certification_body
@../chain/certification_report_body
@../chain/company_filter_body
@../chain/company_product_body
@../chain/plugin_body
@../chain/product_report_body
@../chain/product_type_body
@../enable_body
@../schema_body
@../csrimp/imp_body

@update_tail
