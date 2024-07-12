define version=3044
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
CREATE TABLE chain.company_product (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id				NUMBER(10) NOT NULL,
	company_sid				NUMBER(10) NOT NULL,
	product_type_id			NUMBER(10) NOT NULL,
	lookup_key				VARCHAR2(1024),
	last_edited_by			NUMBER(10) NOT NULL,
	last_edited_dtm			DATE NOT NULL,
	CONSTRAINT pk_company_product PRIMARY KEY (app_sid, product_id)
);
ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_product
	FOREIGN KEY (app_sid, product_id) 
	REFERENCES chain.product(app_sid, product_id);
ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_company_sid
	FOREIGN KEY (app_sid, company_sid) 
	REFERENCES chain.company(app_sid, company_sid);
ALTER TABLE chain.company_product ADD CONSTRAINT fk_company_product_product_typ
	FOREIGN KEY (app_sid, product_type_id) 
	REFERENCES chain.product_type (app_sid, product_type_id);
CREATE UNIQUE INDEX chain.company_product_lookup ON chain.company_product(app_sid, lower(lookup_key));
CREATE TABLE chain.company_product_version (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id						NUMBER(10) NOT NULL,
	version_number					NUMBER(10) NOT NULL,
	sku								VARCHAR2(1024) NOT NULL,
	product_active					NUMBER(1) NOT NULL,
	version_created_by				NUMBER(10) NOT NULL,
	version_created_dtm				DATE NOT NULL,
	version_activated_by			NUMBER(10),
	version_activated_dtm			DATE,
	version_deactivated_by			NUMBER(10),
	version_deactivated_dtm			DATE,
	CONSTRAINT pk_company_product_vers PRIMARY KEY (app_sid, product_id, version_number),
	CONSTRAINT ck_company_product_vers_active CHECK (product_active IN (0, 1))
);
ALTER TABLE chain.company_product_version ADD CONSTRAINT fk_chain_company_ver_product
	FOREIGN KEY (app_sid, product_id) 
	REFERENCES chain.company_product (app_sid, product_id);
CREATE TABLE chain.company_product_version_tr (
	app_sid					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	product_id				NUMBER(10) NOT NULL,
	version_number			NUMBER(10) NOT NULL,
	lang					VARCHAR2(10) NOT NULL,
	description				VARCHAR2(1024) NOT NULL,
	last_changed_dtm		DATE,
	CONSTRAINT pk_company_product_version_tr PRIMARY KEY (app_sid, product_id, version_number, lang)
);
ALTER TABLE chain.company_product_version_tr ADD CONSTRAINT fk_company_prod_vers_tr_prod
	FOREIGN KEY (app_sid, product_id, version_number) 
	REFERENCES chain.company_product_version (app_sid, product_id, version_number);
--Failed to locate all sections of latest3040_4.sql
--Failed to locate all sections of latest3040_5.sql
--Failed to locate all sections of latest3040_6.sql
CREATE TABLE csr.enhesa_account(
	only_one_row NUMBER(1) DEFAULT 0 NOT NULL,
	username VARCHAR2(1024) NOT NULL,
	password VARCHAR2(1024) NOT NULL,
	CONSTRAINT CK_ENHESA_ACCOUNT_ONE_ROW CHECK (only_one_row = 0),
    CONSTRAINT PK_ENHESA_ACCOUNT PRIMARY KEY (only_one_row)
);
INSERT INTO csr.enhesa_account (username, password)
SELECT username, password
  FROM csr.enhesa_options
 WHERE rownum = 1;
CREATE TABLE chain.company_type_score_calc (
    app_sid								NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	company_type_id						NUMBER(10, 0) NOT NULL,
	score_type_id						NUMBER(10, 0) NOT NULL,
	calc_type							VARCHAR2(50) NOT NULL,
	operator_type						VARCHAR2(10),
	supplier_score_type_id				NUMBER(10, 0),
    CONSTRAINT pk_cmp_typ_scr_clc PRIMARY KEY (app_sid, company_type_id, score_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_cmp_typ FOREIGN KEY (app_sid, company_type_id) REFERENCES chain.company_type (app_sid, company_type_id),
	CONSTRAINT ck_cmp_typ_scr_clc_opr_typ CHECK (operator_type IS NULL OR operator_type IN ('sum', 'avg', 'max', 'min')),
	CONSTRAINT ck_cmp_typ_scr_clc_calc CHECK (
		calc_type = 'supplier_scores' AND operator_type IS NOT NULL AND supplier_score_type_id IS NOT NULL
	)
);
CREATE INDEX chain.ix_cmp_typ_scr_clc_cmp_typ ON chain.company_type_score_calc (app_sid, company_type_id);
CREATE TABLE chain.comp_type_score_calc_comp_type (
    app_sid								NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	company_type_id						NUMBER(10, 0) NOT NULL,
	score_type_id						NUMBER(10, 0) NOT NULL,
	supplier_company_type_id			NUMBER(10, 0) NOT NULL,
    CONSTRAINT pk_cmp_typ_scr_clc_cmp_typ PRIMARY KEY (app_sid, company_type_id, score_type_id, supplier_company_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_parent FOREIGN KEY (app_sid, company_type_id, score_type_id) REFERENCES chain.company_type_score_calc (app_sid, company_type_id, score_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_ct FOREIGN KEY (app_sid, company_type_id) REFERENCES chain.company_type (app_sid, company_type_id),
	CONSTRAINT fk_cmp_typ_scr_clc_ct_sct FOREIGN KEY (app_sid, supplier_company_type_id) REFERENCES chain.company_type (app_sid, company_type_id)
);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_parent ON chain.comp_type_score_calc_comp_type (app_sid, company_type_id, score_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_ct ON chain.comp_type_score_calc_comp_type (app_sid, company_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_sct ON chain.comp_type_score_calc_comp_type (app_sid, supplier_company_type_id);
CREATE TABLE CSRIMP.CHAIN_COM_TYPE_SCOR_CALC (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	CALC_TYPE VARCHAR2(50) NOT NULL,
	OPERATOR_TYPE VARCHAR2(10),
	SUPPLIER_SCORE_TYPE_ID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_COM_TYPE_SCOR_CALC PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, SCORE_TYPE_ID),
	CONSTRAINT FK_CHAIN_COM_TYPE_SCOR_CALC_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_CO_TY_SC_CAL_CO_TY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	SUPPLIER_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CO_TY_SC_CAL_CO_TY PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, SCORE_TYPE_ID, SUPPLIER_COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_CO_TY_SC_CAL_CO_TY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE csr.internal_audit_score (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	internal_audit_sid				NUMBER(10, 0) NOT NULL,
	score_type_id					NUMBER(10, 0) NOT NULL,
    score							NUMBER(15, 5),
    score_threshold_id				NUMBER(10, 0),
	CONSTRAINT pk_internal_audit_score PRIMARY KEY (app_sid, internal_audit_sid, score_type_id),
	CONSTRAINT fk_internal_audit_score_ia FOREIGN KEY (app_sid, internal_audit_sid) REFERENCES csr.internal_audit (app_sid, internal_audit_sid),
	CONSTRAINT fk_internal_audit_score_st FOREIGN KEY (app_sid, score_type_id) REFERENCES csr.score_type (app_sid, score_type_id),
	CONSTRAINT fk_internal_audit_score_sth FOREIGN KEY (app_sid, score_threshold_id) REFERENCES csr.score_threshold (app_sid, score_threshold_id)
);
CREATE INDEX csr.ix_internal_audit_score_ia ON csr.internal_audit_score (app_sid, internal_audit_sid);
CREATE INDEX csr.ix_internal_audit_score_st ON csr.internal_audit_score (app_sid, score_type_id);
CREATE INDEX csr.ix_internal_audit_score_sth ON csr.internal_audit_score (app_sid, score_threshold_id);
CREATE TABLE CSRIMP.INTERNAL_AUDIT_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_SID NUMBER(10,0) NOT NULL,
	SCORE_TYPE_ID NUMBER(10,0) NOT NULL,
	SCORE NUMBER(15,5),
	SCORE_THRESHOLD_ID NUMBER(10,0),
	CONSTRAINT PK_INTERNAL_AUDIT_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, SCORE_TYPE_ID),
	CONSTRAINT FK_INTERNAL_AUDIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE SEQUENCE CHAIN.PRODUCT_HEADER_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE SEQUENCE CHAIN.PRODUCT_TAB_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
CREATE TABLE CHAIN.PRODUCT_HEADER(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	viewing_own_company    NUMBER(1) DEFAULT 0 NOT NULL,
	PAGE_COMPANY_COL_SID   NUMBER(10, 0),
	USER_COMPANY_COL_SID   NUMBER(10, 0),
	CONSTRAINT CHK_PRD_HEAD_VIEW_OWN_CMP_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT CHK_PRD_HEAD_VIEWING_OWN_TYPES CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id)),
	CONSTRAINT PRODUCT_HEADER_PK PRIMARY KEY (APP_SID, PRODUCT_HEADER_ID)
);
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;
CREATE TABLE CHAIN.PRODUCT_TAB(
	APP_SID                NUMBER(10, 0)     DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)     NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)     NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)     NOT NULL,
	POS                    NUMBER(10, 0)     NOT NULL,
	LABEL                  VARCHAR2(254)     NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)     NOT NULL,
	VIEWING_OWN_COMPANY    NUMBER(1) DEFAULT 0 NOT NULL,
	OPTIONS				   VARCHAR2(255),
	PAGE_COMPANY_COL_SID   NUMBER(10) NULL,
	USER_COMPANY_COL_SID   NUMBER(10) NULL,
	FLOW_CAPABILITY_ID	   NUMBER(10) NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10) NULL,
	CONSTRAINT CHK_PRD_TAB_VIEW_OWN_CMP_1_0 CHECK (viewing_own_company IN (1, 0)),
	CONSTRAINT CHK_PRD_TAB_VIEWING_OWN_TYPES CHECK (viewing_own_company = 0 OR (user_company_type_id = page_company_type_id)),
	CONSTRAINT PRODUCT_TAB_PK PRIMARY KEY (APP_SID, PRODUCT_TAB_ID)
);
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PAGE_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, PAGE_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_USER_CT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, USER_COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;
CREATE TABLE CSRIMP.CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_HEADER_ID      NUMBER(10, 0)	NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)	NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)	NOT NULL,
	POS                    NUMBER(10, 0)	NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	viewing_own_company    NUMBER(1)		NOT NULL,
	PAGE_COMPANY_COL_SID   NUMBER(10, 0),
	USER_COMPANY_COL_SID   NUMBER(10, 0),
	CONSTRAINT PK_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_HEADER_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRODUCT_TAB_ID         NUMBER(10, 0)	NOT NULL,
	PLUGIN_ID              NUMBER(10, 0)	NOT NULL,
	PLUGIN_TYPE_ID         NUMBER(10, 0)	NOT NULL,
	POS                    NUMBER(10, 0)	NOT NULL,
	LABEL                  VARCHAR2(254)	NOT NULL,
	PAGE_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	USER_COMPANY_TYPE_ID   NUMBER(10, 0)	NOT NULL,
	VIEWING_OWN_COMPANY    NUMBER(1)		NOT NULL,
	OPTIONS				   VARCHAR2(255),
	PAGE_COMPANY_COL_SID   NUMBER(10)		NULL,
	USER_COMPANY_COL_SID   NUMBER(10)		NULL,
	FLOW_CAPABILITY_ID	   NUMBER(10)		NULL,
	BUSINESS_RELATIONSHIP_TYPE_ID	NUMBER(10) NULL,
	CONSTRAINT PK_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, PRODUCT_TAB_ID),
	CONSTRAINT FK_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_HEADER UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE SEQUENCE CSR.COMPLIANCE_REGION_MAP_ID_SEQ;
CREATE TABLE CSR.COMPLIANCE_REGION_MAP
(
	COMPLIANCE_REGION_MAP_ID	NUMBER(10) NOT NULL,
	COMPLIANCE_ITEM_SOURCE_ID	NUMBER(3),
	SOURCE_COUNTRY				VARCHAR2(3),
	SOURCE_COUNTRY_LABEL		VARCHAR2(1024),
	SOURCE_REGION				VARCHAR2(3),
	SOURCE_REGION_LABEL			VARCHAR2(1024),
	COUNTRY						VARCHAR2(2),
	REGION						VARCHAR2(2),
	CONSTRAINT PK_COM_REG_MAP PRIMARY KEY (COMPLIANCE_REGION_MAP_ID),
	CONSTRAINT UK_COM_REG_MAP UNIQUE (COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_REGION, COUNTRY, REGION)
);
CREATE TABLE CSR.REGION_GROUP
(
	REGION_GROUP_ID				VARCHAR2(3),
	GROUP_NAME					VARCHAR2(1024),
	CONSTRAINT PK_REG_GRP PRIMARY KEY (REGION_GROUP_ID)
);
CREATE TABLE CSR.REGION_GROUP_REGION
(
	REGION_GROUP_ID				VARCHAR2(3) NOT NULL,
	COUNTRY						VARCHAR2(2),
	REGION						VARCHAR2(2),
	CONSTRAINT PK_REG_GRP_REG PRIMARY KEY (REGION_GROUP_ID, COUNTRY, REGION)
);
CREATE INDEX CSR.IX_COMP_REG_MAP_REG ON CSR.COMPLIANCE_REGION_MAP(COUNTRY, REGION);
CREATE INDEX CSR.IX_COMP_REG_MAP_CI_SRC ON CSR.COMPLIANCE_REGION_MAP(COMPLIANCE_ITEM_SOURCE_ID);
CREATE INDEX CSR.IX_REG_GRP_REG_REG ON CSR.REGION_GROUP_REGION(COUNTRY, REGION);
CREATE INDEX CSR.IX_REG_GRP_REG_REG_GRP ON CSR.REGION_GROUP_REGION(REGION_GROUP_ID);
CREATE TABLE CHAIN.COMPANY_TAB_RELATED_CO_TYPE(
	APP_SID							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	COMPANY_TAB_ID					NUMBER(10, 0)	NOT NULL,
	COMPANY_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT COMPANY_TAB_REL_CO_TYPE_PK PRIMARY KEY (APP_SID, COMPANY_TAB_ID, COMPANY_TYPE_ID)
);
ALTER TABLE CHAIN.COMPANY_TAB_RELATED_CO_TYPE ADD CONSTRAINT REF_RCT_COMPANY_TAB 
    FOREIGN KEY (APP_SID, COMPANY_TAB_ID)
    REFERENCES CHAIN.COMPANY_TAB(APP_SID, COMPANY_TAB_ID)
;
ALTER TABLE CHAIN.COMPANY_TAB_RELATED_CO_TYPE ADD CONSTRAINT REF_RCT_COMPANY_TYPE 
    FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
    REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID)
;
CREATE TABLE CSRIMP.CHAIN_CO_TAB_RELATED_CO_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TAB_ID					NUMBER(10, 0)	NOT NULL,
	COMPANY_TYPE_ID					NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_CO_TAB_REL_CO_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TAB_ID, COMPANY_TYPE_ID),
	CONSTRAINT FK_CO_TAB_REL_CO_TYPE FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSR.INTERNAL_AUDIT_LOCKED_TAG(
	APP_SID							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	INTERNAL_AUDIT_SID				NUMBER(10) NOT NULL,
	TAG_GROUP_ID					NUMBER(10) NOT NULL,
	TAG_ID							NUMBER(10),
	CONSTRAINT PK_IA_LOCKED_TAG PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, TAG_GROUP_ID),
	CONSTRAINT FK_AUD_SURV_LOCK_TAG_AUDIT FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID) REFERENCES CSR.INTERNAL_AUDIT (APP_SID, INTERNAL_AUDIT_SID),
	CONSTRAINT FK_AUD_SURV_LOCK_TAG_TAG_GROUP FOREIGN KEY (APP_SID, TAG_GROUP_ID) REFERENCES CSR.TAG_GROUP (APP_SID, TAG_GROUP_ID),
	CONSTRAINT FK_AUD_SURV_LOCK_TAG_TAG FOREIGN KEY (APP_SID, TAG_ID) REFERENCES CSR.TAG (APP_SID, TAG_ID)
);
CREATE TABLE CSRIMP.INTERNAL_AUDIT_LOCKED_TAG(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	INTERNAL_AUDIT_SID				NUMBER(10) NOT NULL,
	TAG_GROUP_ID					NUMBER(10) NOT NULL,
	TAG_ID							NUMBER(10),
	CONSTRAINT PK_IA_LOCKED_TAG PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, TAG_GROUP_ID),
	CONSTRAINT FK_AUD_SURV_LOCK_TAG FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


drop package csr.job_pkg;
drop table csr.job;
drop user dyntab cascade;
drop package csr.logging_form_pkg;
drop package csr.diary_pkg;
drop table csr.diary_event_group;
drop table csr.diary_event;
ALTER TABLE csr.enhesa_options
DROP (username, password);
ALTER TABLE csrimp.enhesa_options
DROP (username, password);
drop type csr.t_diary_event_table;
drop type csr.t_diary_event_row;
ALTER TABLE csr.compliance_options
ADD (rollout_option NUMBER(10) DEFAULT 0 NOT NULL);
ALTER TABLE csrimp.compliance_options
ADD (rollout_option NUMBER(10) NOT NULL);
CREATE GLOBAL TEMPORARY TABLE CHAIN.TEMP_GRID_EXTENSION_MAP
(
	SOURCE_ID			NUMBER(10, 0)	NOT NULL,
	LINKED_TYPE			NUMBER(10,0)	NOT NULL,
	LINKED_ID			NUMBER(10, 0)	NOT NULL
)
ON COMMIT DELETE ROWS;
ALTER TABLE chain.dedupe_staging_link ADD staging_source_lookup_col_sid	NUMBER (10, 0);
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD staging_source_lookup_col_sid	NUMBER (10, 0);
ALTER TABLE csr.score_type ADD (
	applies_to_audits				NUMBER(1, 0) DEFAULT 0 NOT NULL,
    CONSTRAINT ck_score_type_app_to_aud_1_0 CHECK (applies_to_audits IN (0, 1)),
	CONSTRAINT ck_score_type_not_aud_and_nc	CHECK (applies_to_audits = 0 OR applies_to_non_compliances = 0)
);
ALTER TABLE csrimp.score_type ADD (
	applies_to_audits				NUMBER(1, 0) NOT NULL,
    CONSTRAINT ck_score_type_app_to_aud_1_0 CHECK (applies_to_audits IN (0, 1)),
	CONSTRAINT ck_score_type_not_aud_and_nc	CHECK (applies_to_audits = 0 OR applies_to_non_compliances = 0)
);
ALTER TABLE chain.bsci_supplier MODIFY industry NULL;
ALTER TABLE csrimp.chain_bsci_supplier MODIFY industry NULL;
ALTER TABLE CSR.COMPLIANCE_ITEM ADD (
	REGION_GROUP		VARCHAR2(3)
);
ALTER TABLE CSRIMP.COMPLIANCE_ITEM ADD (
	REGION_GROUP		VARCHAR2(3)
);
CREATE INDEX CSR.IX_CI_REG_GRP ON CSR.COMPLIANCE_ITEM(REGION_GROUP);
CREATE INDEX CSR.IX_CIT_CI ON CSR.COMPLIANCE_ITEM_TAG(APP_SID, COMPLIANCE_ITEM_ID);
CREATE INDEX CSR.IX_COMPLIANCE_ITEM_REGION_CI ON CSR.COMPLIANCE_ITEM_REGION(APP_SID, COMPLIANCE_ITEM_ID);
ALTER TABLE CSR.COMPLIANCE_ITEM ADD CONSTRAINT FK_CI_REG_GRP
	FOREIGN KEY (REGION_GROUP)
	REFERENCES CSR.REGION_GROUP(REGION_GROUP_ID);
ALTER TABLE CSR.COMPLIANCE_ITEM_REGION ADD CONSTRAINT FK_CIR_CI
    FOREIGN KEY (APP_SID, COMPLIANCE_ITEM_ID)
    REFERENCES CSR.COMPLIANCE_ITEM(APP_SID, COMPLIANCE_ITEM_ID);	
	
ALTER TABLE CSR.COMPLIANCE_REGION_MAP ADD CONSTRAINT FK_COM_REG_MAP_CI_SRC
	FOREIGN KEY (COMPLIANCE_ITEM_SOURCE_ID)
	REFERENCES CSR.COMPLIANCE_ITEM_SOURCE(COMPLIANCE_ITEM_SOURCE_ID);
ALTER TABLE CSR.REGION_GROUP_REGION ADD CONSTRAINT FK_REG_GRP_REG_REG_GRP
	FOREIGN KEY (REGION_GROUP_ID)
	REFERENCES CSR.REGION_GROUP(REGION_GROUP_ID);
	
ALTER TABLE csr.temp_question_option MODIFY (lookup_key VARCHAR2(1000));
DROP INDEX csr.ix_qs_question_option;
ALTER TABLE csr.qs_question_option MODIFY (lookup_key VARCHAR2(1000));
CREATE UNIQUE INDEX csr.ix_qs_question_option 
	ON csr.qs_question_option(app_sid, question_id, survey_version, 
							  NVL(UPPER(lookup_key),'QOID_'||TO_CHAR(question_option_id)));
ALTER TABLE csrimp.qs_question_option MODIFY (lookup_key VARCHAR2(1000));
ALTER TABLE chain.higg_module_tag_group
 DROP CONSTRAINT pk_higg_mod_tag_grp;
ALTER TABLE chain.higg_module_tag_group
  ADD CONSTRAINT pk_higg_mod_tag_grp PRIMARY KEY (app_sid, higg_module_id, tag_group_id);
ALTER TABLE csrimp.higg_module_tag_group
 DROP CONSTRAINT pk_higg_module_tag_group;
 
ALTER TABLE csrimp.higg_module_tag_group
  ADD CONSTRAINT pk_higg_module_tag_group PRIMARY KEY (csrimp_session_id, higg_module_id, tag_group_id);
ALTER TABLE CHAIN.COMPANY_TAB ADD 
	DEFAULT_SAVED_FILTER_SID NUMBER(10) NULL
;
ALTER TABLE CHAIN.COMPANY_TAB ADD CONSTRAINT REF_CO_TAB_DEF_SAVED_FILTER
    FOREIGN KEY (APP_SID, DEFAULT_SAVED_FILTER_SID)
    REFERENCES CHAIN.SAVED_FILTER(APP_SID, SAVED_FILTER_SID)
;
ALTER TABLE CSRIMP.CHAIN_COMPANY_TAB ADD 
	DEFAULT_SAVED_FILTER_SID NUMBER(10) NULL
;
ALTER TABLE CSR.quick_survey_type ADD tearoff_toolbar NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSR.quick_survey_type ADD CONSTRAINT CHK_TEAROFF_TOOLBAR CHECK (tearoff_toolbar IN (0,1));
ALTER TABLE CSR.quick_survey_type MODIFY cs_class NULL;
ALTER TABLE CSRIMP.quick_survey_type ADD tearoff_toolbar NUMBER(1) NOT NULL;
ALTER TABLE CSRIMP.quick_survey_type ADD CONSTRAINT CHK_TEAROFF_TOOLBAR CHECK (tearoff_toolbar IN (0,1));
ALTER TABLE CSRIMP.quick_survey_type MODIFY cs_class NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS
ADD ENABLE_PRODUCT_COMPLIANCE NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS ADD CONSTRAINT CHK_ENABLE_PRODUCT_COMPLIANCE CHECK (ENABLE_PRODUCT_COMPLIANCE IN (0,1));
create index csr.ix_locked_tag on csr.internal_audit_locked_tag(app_sid, tag_id);


GRANT SELECT ON csr.v$customer_lang TO chain;
grant select, insert, update on chain.product_type_tr to csr;
grant select, insert, update on chain.product_type_tr to csrimp;
grant select, insert, update, delete on csrimp.chain_product_type_tr to tool_user;
grant select, insert, update, delete on chain.temp_grid_extension_map to csr;
grant select on chain.grid_extension to csr;
GRANT select, references ON csr.current_supplier_score TO chain;
grant select, insert, update, delete on csrimp.chain_com_type_scor_calc to tool_user;
grant select, insert, update, delete on csrimp.chain_co_ty_sc_cal_co_ty to tool_user;
grant select, insert, update on chain.company_type_score_calc to csrimp;
grant select, insert, update on chain.comp_type_score_calc_comp_type to csrimp;
grant select, insert, update on chain.company_type_score_calc to CSR;
grant select, insert, update on chain.comp_type_score_calc_comp_type to CSR;
grant select, insert, update on chain.product_header to CSR;
grant select, insert, update on chain.product_tab to CSR;
grant select on chain.product_header_id_seq to CSR;
grant select on chain.product_tab_id_seq to CSR;
create index chain.ix_product_heade_plugin_id on chain.product_header (plugin_id);
create index chain.ix_product_tab_plugin_id on chain.product_tab (plugin_id);
grant select, insert, update, delete on csrimp.chain_product_header to tool_user;
grant select, insert, update, delete on csrimp.chain_product_tab to tool_user;
grant select, insert, update on chain.product_header to csrimp;
grant select, insert, update on chain.product_tab to csrimp;
grant select on chain.product_header_id_seq to csrimp;
grant select on chain.product_tab_id_seq to csrimp;
GRANT SELECT ON chain.higg_module TO csr;
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_related_co_type TO csr;
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_related_co_type TO csrimp;
grant select, insert, update, delete on csrimp.internal_audit_score to tool_user;
grant select, insert, update on csr.internal_audit_score to csrimp;
grant select, insert, update, delete on csrimp.chain_certification to tool_user;
grant select, insert, update, delete on csrimp.chain_cert_aud_type to tool_user;
grant select, insert, update on csr.internal_audit_locked_tag to csrimp;
grant select,insert,update,delete on csrimp.internal_audit_locked_tag to tool_user;


ALTER TABLE chain.company_product
ADD CONSTRAINT fk_company_product_edit_user
FOREIGN KEY (app_sid, last_edited_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);
ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_create_usr
FOREIGN KEY (app_sid, version_created_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);
ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_activt_usr
FOREIGN KEY (app_sid, version_activated_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);
ALTER TABLE chain.company_product_version
ADD CONSTRAINT fk_company_prod_ver_deact_usr
FOREIGN KEY (app_sid, version_deactivated_by) REFERENCES csr.csr_user (app_sid, csr_user_sid);
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT fk_staging_link_source_col
	FOREIGN KEY (app_sid, staging_tab_sid, staging_source_lookup_col_sid)
	REFERENCES cms.tab_column (app_sid, tab_sid, column_sid);
ALTER TABLE chain.company_type_score_calc
ADD CONSTRAINT fk_cmp_typ_scr_clc_scr_typ
FOREIGN KEY (app_sid, score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_scr_typ
ON chain.company_type_score_calc (app_sid, score_type_id);
ALTER TABLE chain.company_type_score_calc
ADD CONSTRAINT fk_cmp_typ_scr_clc_sup_st
FOREIGN KEY (app_sid, supplier_score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_sup_st
ON chain.company_type_score_calc (app_sid, supplier_score_type_id);
ALTER TABLE chain.comp_type_score_calc_comp_type
ADD CONSTRAINT fk_cmp_typ_scr_clc_ct_st
FOREIGN KEY (app_sid, score_type_id)
REFERENCES csr.score_type (app_sid, score_type_id);
CREATE INDEX chain.ix_cmp_typ_scr_clc_ct_st
ON chain.comp_type_score_calc_comp_type (app_sid, score_type_id);
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;
ALTER TABLE CHAIN.PRODUCT_HEADER ADD CONSTRAINT FK_PR_HD_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_ID_PLUGIN
    FOREIGN KEY (PLUGIN_ID)
    REFERENCES CSR.PLUGIN(PLUGIN_ID)
;
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PR_TB_PLUGIN_TYPE_ID_PLGN_T
    FOREIGN KEY (PLUGIN_TYPE_ID)
    REFERENCES CSR.PLUGIN_TYPE(PLUGIN_TYPE_ID)
;
ALTER TABLE chain.product_header ADD CONSTRAINT fk_product_hdr_page_comp_col 
	FOREIGN KEY (app_sid, page_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid);
ALTER TABLE chain.product_header ADD CONSTRAINT fk_product_hdr_user_comp_col
	FOREIGN KEY (app_sid, user_company_col_sid)
	REFERENCES cms.tab_column(app_sid, column_sid);
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_PAGE_COMP_COL 
	FOREIGN KEY (APP_SID, PAGE_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);
ALTER TABLE CHAIN.PRODUCT_TAB ADD CONSTRAINT FK_PRODUCT_TAB_USER_COMP_COL
	FOREIGN KEY (APP_SID, USER_COMPANY_COL_SID)
	REFERENCES CMS.TAB_COLUMN(APP_SID, COLUMN_SID);
	
ALTER TABLE CSR.COMPLIANCE_REGION_MAP ADD CONSTRAINT FK_COM_REG_MAP_P_REG
	FOREIGN KEY (COUNTRY, REGION)
	REFERENCES POSTCODE.REGION(COUNTRY, REGION);
ALTER TABLE CSR.REGION_GROUP_REGION ADD CONSTRAINT FK_REG_GRP_REG_P_REG
	FOREIGN KEY (COUNTRY, REGION)
	REFERENCES POSTCODE.REGION(COUNTRY, REGION);
	


CREATE OR REPLACE VIEW chain.v$company_product_current_vers AS
	SELECT product_id, max(version_number) current_version_number
	  FROM chain.company_product_version
	 WHERE (version_deactivated_dtm IS NULL AND version_activated_dtm IS NOT NULL)
		OR (version_deactivated_dtm IS NULL AND version_activated_dtm IS NULL)
	   AND app_sid = SYS_CONTEXT('SECURITY', 'APP')
	  GROUP BY product_id;
CREATE OR REPLACE VIEW chain.v$company_product_version AS
	SELECT vers.product_id, vers.version_number, sku, version_created_by, version_created_dtm, version_activated_by, version_activated_dtm, version_deactivated_by, version_deactivated_dtm,
		   product_active, CASE WHEN (version_deactivated_dtm IS NULL AND version_activated_dtm IS NOT NULL) THEN 1 ELSE 0 END published
	  FROM chain.company_product_version vers
	  JOIN chain.v$company_product_current_vers cur ON vers.product_id = cur.product_id 
												   AND vers.version_number = cur.current_version_number
	  WHERE vers.app_sid = SYS_CONTEXT('SECURITY', 'APP');
	
CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.product_id, tr.description product_name, cp.company_sid, c.name company_name, cp.product_type_id, pt.description product_type_name, ver.sku, cp.lookup_key, cp.last_edited_by, 
		   cu.full_name last_edited_name, last_edited_dtm, ver.product_active is_active, 0 weight_val, 'kg' weight_unit, 0 volume_val, 'cm3' volume_unit, 0 is_fully_certified, 1 is_owner, 0 is_supplier, 
       ver.version_number, ver.published
	  FROM chain.company_product cp
 LEFT JOIN csr.csr_user cu ON cp.last_edited_by = cu.csr_user_sid
	  JOIN chain.v$product_type pt ON cp.product_type_id = pt.product_type_id
	  JOIN chain.company c ON cp.company_sid = c.company_sid
	  JOIN chain.v$company_product_version ver ON cp.product_id = ver.product_id
	  JOIN chain.company_product_version_tr tr ON tr.product_id = cp.product_id AND tr.version_number = ver.version_number AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
   
CREATE OR REPLACE VIEW chain.v$company_product AS
	SELECT cp.product_id, tr.description product_name, cp.company_sid, c.name company_name, cp.product_type_id, pt.description product_type_name, ver.sku, cp.lookup_key, cp.last_edited_by, 
		   cu.full_name last_edited_name, last_edited_dtm, ver.product_active is_active,
		   0 weight_val, NULL weight_measure_conv_id, 'kg' weight_unit,
		   0 volume_val, NULL volume_measure_conv_id, 'cm3' volume_unit,
		   0 is_fully_certified, 1 is_owner, 0 is_supplier, 
       ver.version_number, ver.published
	  FROM chain.company_product cp
 LEFT JOIN csr.csr_user cu ON cp.last_edited_by = cu.csr_user_sid
	  JOIN chain.v$product_type pt ON cp.product_type_id = pt.product_type_id
	  JOIN chain.company c ON cp.company_sid = c.company_sid
	  JOIN chain.v$company_product_version ver ON cp.product_id = ver.product_id
	  JOIN chain.company_product_version_tr tr ON tr.product_id = cp.product_id AND tr.version_number = ver.version_number AND tr.lang = NVL(SYS_CONTEXT('SECURITY', 'LANGUAGE'), 'en')
	 WHERE cp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cp.company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
CREATE OR REPLACE VIEW chain.v$supplier_certification AS
	SELECT cat.app_sid, cat.certification_id, ia.internal_audit_sid, s.company_sid, ia.internal_audit_type_id, ia.audit_dtm valid_from_dtm,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, add_months(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm 
			END expiry_dtm, atct.audit_closure_type_id 
	FROM chain.certification_audit_type cat 
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


DELETE FROM csr.module_param WHERE module_id = '80' AND param_name = 'in_username';


BEGIN
	UPDATE csr.plugin
	   SET description = 'Supplier scores'
	 WHERE js_class = 'Chain.ManageCompany.ScoreHeader'
	   AND description = 'Score header for company management page'
	   AND cs_class = 'Credit360.Chain.Plugins.ScoreHeaderDto';
	   
END;
/
BEGIN
	INSERT INTO csr.plugin
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES
		(csr.plugin_id_seq.nextval, 11, 'Certifications', '/csr/site/chain/managecompany/controls/CertificationHeader.js',
			'Chain.ManageCompany.CertificationHeader', 'Credit360.Chain.Plugins.CertificationHeaderDto',
			'This header shows any certifications for a company.',
			'/csr/shared/plugins/screenshots/company_header_certifications.png');
EXCEPTION
	WHEN dup_val_on_index THEN
		NULL;
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (30, 'Reset compliance workflows', 'Resets the requirement and regulation workflows back to the default. Can be used to get the latest updates made to the default workflow','ResyncDefaultComplianceFlows', NULL);
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT app_sid, requirement_flow_sid flow_sid
		  FROM csr.compliance_options
		 UNION 
		SELECT app_sid, regulation_flow_sid flow_sid
		  FROM csr.compliance_options
	) LOOP
		UPDATE csr.flow_state
		   SET lookup_key = 'NOT_CREATED'
		 WHERE label = 'Not created'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'NEW'
		 WHERE label = 'New'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'UPDATED'
		 WHERE label = 'Updated'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'ACTION_REQUIRED'
		 WHERE label = 'Action Required'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'COMPLIANT'
		 WHERE label = 'Compliant'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'NOT_APPLICABLE'
		 WHERE label = 'Not Applicable'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
		   
		UPDATE csr.flow_state
		   SET lookup_key = 'RETIRED'
		 WHERE label = 'Retired'
		   AND flow_sid = r.flow_sid
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/
BEGIN
	security.user_pkg.logonadmin;
	UPDATE chain.filter_page_column SET column_name = 'ncScore' WHERE column_name = 'auditScore';
	INSERT INTO csr.flow_state_trans_helper (app_sid, flow_sid, helper_sp, label)
		 SELECT app_sid, flow_sid, 'csr.audit_helper_pkg.ApplyAuditScoresToSupplier', 'Apply audit scores to supplier'
		   FROM csr.flow f
	      WHERE f.flow_alert_class = 'audit'
		    AND NOT EXISTS (
				SELECT NULL
				  FROM csr.flow_state_trans_helper
				 WHERE app_sid = f.app_sid
				   AND flow_sid = f.flow_sid
				   AND helper_sp = 'csr.audit_helper_pkg.ApplyAuditScoresToSupplier'
		    );
END;
/
UPDATE csr.deleg_plan dp
SET (last_applied_dynamic) = (
    SELECT is_dynamic_plan
    FROM csr.deleg_plan_job dpj
    WHERE batch_job_id IN (
        SELECT MAX(batch_job_id)
        FROM csr.deleg_plan_job
        GROUP BY deleg_plan_sid
    )
    AND dp.deleg_plan_sid = dpj.deleg_plan_sid
)
WHERE dp.last_applied_dynamic IS NULL
AND EXISTS (
    SELECT 1
      FROM csr.deleg_plan_job dpj2
      WHERE dpj2.deleg_plan_sid = dp.deleg_plan_sid
);
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (18, 'Chain Product Header');
INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (19, 'Chain Product Tab');
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 18, 'Chain Product Header', '/csr/site/chain/manageProduct/controls/ProductHeader.js', 'Chain.ManageProduct.ProductHeader', 'Credit360.Chain.Plugins.ProductHeader', 'Product header.');
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 19, 'Chain Product Details Tab', '/csr/site/chain/manageProduct/controls/ProductDetailsTab.js', 'Chain.ManageProduct.ProductDetailsTab', 'Credit360.Chain.Plugins.ProductDetails', 'Product Details tab.');
BEGIN
	security.user_pkg.logonadmin;
END;
/
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Certification Filter';
	v_class := 'Credit360.Chain.Cards.Filters.CertificationFilter';
	v_js_path := '/csr/site/chain/cards/filters/certificationFilter.js';
	v_js_class := 'Chain.Cards.Filters.CertificationFilter';
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
	v_desc := 'Company Certification Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyCertificationFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/companyCertificationFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.CompanyCertificationFilterAdapter';
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
	v_card_id				NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(55 /*chain.filter_pkg.FILTER_TYPE_CERTS*/, 'Certification Filter', 'Allows filtering of certifications', 'chain.certification_report_pkg', NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CertificationFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Certification Filter', 'chain.certification_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
	) LOOP
		BEGIN	
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
				 VALUES (r.app_sid, 55 /*chain.filter_pkg.FILTER_TYPE_CERTS*/, v_card_id, 0);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.CompanyCertificationFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Company Certification Filter Adapter', 'chain.company_filter_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;	
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		   FROM chain.card_group_card
		  WHERE card_group_id = 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/
		  GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
				 VALUES (r.app_sid, 23 /*chain.filter_pkg.FILTER_TYPE_COMPANIES*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/
BEGIN
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'TP', 'East Timor', NULL, NULL, 'tl', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'FR', 'FRANCE', 'NC', 'NEW CALEDONIA', 'nc', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'XB', 'KOREA,NORTH', NULL, NULL, 'kp', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'MAC', 'MACAU', 'mo', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'KO', 'Kosovo', NULL, NULL, 'xk', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'WI', 'VIENNA', 'at', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BY', 'BAVARIA', 'de', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BE', 'BELGIUM', 'BRU', 'BRUSSELS', 'be', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'ZHE', 'ZHEJIANG', 'cn', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'ZH', 'ZUID-HOLLAND', 'nl', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'ZH', 'ZURICH', 'ch', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'ZG', 'ZUG', 'ch', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'ZE', 'ZEELAND', 'nl', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'Z', 'SANTA CRUZ', 'ar', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'YN', 'YUNNAN', 'cn', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'XZ', 'TIBET', 'cn', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'XJ', 'XINJIANG UYGHUR', 'cn', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NA', 'NAMIBIA', 'WH', 'WINDHOEK', 'na', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'WC', 'WESTERN CAPE', 'za', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'WB', 'WEST BENGAL', 'in', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'WA', 'WESTERN AUSTRALIA', 'au', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'VIC', 'VICTORIA', 'au', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'VER', 'VERACRUZ', 'mx', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'VEN', 'VENETO', 'it', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'UT', 'UTRECHT', 'nl', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'UP', 'UTTAR PRADESH', 'in', '36');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'TUS', 'TUSCANY', 'it', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'TN', 'TAMIL NADU', 'in', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TLA', 'TLAXCALA', 'mx', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'TIA', 'TIANJIN', 'cn', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'TI', 'TICINO', 'ch', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'TH', 'THURINGIA', 'de', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'TG', 'THURGAU', 'ch', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'TAS', 'TASMANIA', 'au', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TAM', 'TAMAULIPAS', 'mx', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'TAB', 'TABASCO', 'mx', '27');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'ST', 'SAXONY-ANHALT', 'de', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BA', 'BOSNIA HERCEGOVINA', 'SRP', 'SRPSKA', 'ba', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'SP', 'SÃO PAULO', 'br', '27');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'SON', 'SONORA', 'mx', '26');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'SLP', 'SAN LUIS POTOSI', 'mx', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SL', 'SAARLAND', 'de', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'SK', 'SASKATCHEWAN', 'ca', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHG', 'SHANGHAI', 'cn', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHD', 'SHANDONG', 'cn', '25');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SHA', 'SHAANXI', 'cn', '26');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SH', 'SCHLESWIGHOLSTEIN', 'de', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'SG', 'SERGIPE', 'br', '28');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'RU', 'RUSSIA', 'SAK', 'SAKHALIN', 'ru', '64');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'SA', 'SOUTH AUSTRALIA', 'au', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'SA', 'SAXONY', 'de', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'RS', 'RIO GRANDE DO SUL', 'br', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'RP', 'RHINELANDPALATINATE', 'de', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'RDJ', 'RÍO DE JANEIRO', 'br', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'RAK', 'RAS AL KHAIMA', 'ae', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'QUE', 'QUERÉTARO', 'mx', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'QLD', 'QUEENSLAND', 'au', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'QH', 'QINGHAI', 'cn', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'QC', 'QUEBEC', 'ca', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'PY', 'PUDUCHERRY', 'in', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'PV', 'BASQUE COUNTRY', 'es', '59');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'PUE', 'PUEBLA', 'mx', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'PE', 'PRINCE EDWARD ISLAND', 'ca', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'OV', 'OVERIJSSEL', 'nl', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'ON', 'ONTARIO', 'ca', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'NX', 'NINGXIA HUI', 'cn', '21');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'NW', 'NORTH RHINEWESTPHALIA', 'de', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'NT', 'NORTHERN TERRITORY', 'au', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'NSW', 'NEW SOUTH WALES', 'au', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NS', 'NOVA SCOTIA', 'ca', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'NM', 'INNER MONGOLIA', 'cn', '20');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'NLE', 'NUEVO LEON', 'mx', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NL', 'NEWFOUNDLAND', 'ca', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'NI', 'LOWER SAXONY', 'de', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'NH', 'NOORD-HOLLAND', 'nl', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'NE', 'NEUCHÂTEL', 'ch', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'NB', 'NEW BRUNSWICK', 'ca', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'NB', 'NOORD-BRABANT', 'nl', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'NA', 'NAVARRA', 'es', '32');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'MV', 'MECKLENBURGWESTERN P', 'de', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MP', 'MADHYA PRADESH', 'in', '35');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'RU', 'RUSSIA', 'MOW', 'MOSCOW CITY', 'ru', '48');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MMU', 'MUMBAI', 'in', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'MIC', 'MICHOACÁN', 'mx', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'MH', 'MAHARASHTRA', 'in', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'MG', 'MINAS GERIAS', 'br', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'MEX', 'MEXICO', 'mx', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'MD', 'MADRID', 'es', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'MB', 'MANITOBA', 'ca', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'PT', 'PORTUGAL', 'MAD', 'MADEIRA', 'pt', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'LU', 'LUZERN', 'ch', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'LOM', 'LOMBARDIA', 'it', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'LIA', 'LIAONING', 'cn', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'LI', 'LIMBURG', 'nl', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'KA', 'KARNATAKA', 'in', '19');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'JX', 'JIANGXI', 'cn', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ID', 'INDONESIA', 'JW', 'EAST JAVA', 'id', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'JIL', 'JILIN', 'cn', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ID', 'INDONESIA', 'JB', 'WEST JAVA', 'id', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'JAL', 'JALISCO', 'mx', '14');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'HP', 'HIMACHAL PRADESH', 'in', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HNN', 'HENAN', 'cn', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HN', 'HUNAN', 'cn', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HL', 'HEILONGJIANG', 'cn', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'HID', 'HIDALGO', 'mx', '13');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HI', 'HAINAN', 'cn', '31');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HH', 'HANSEATIC CITY HAMBURG', 'de', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HEB', 'HEBEI', 'cn', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HE', 'HESSEN', 'de', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HB', 'HUBEI', 'cn', '12');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'HB', 'HANSEATIC CITY BREMEN', 'de', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GZ', 'GUIZHOU', 'cn', '18');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GX', 'GUANGXI ZHUANG', 'cn', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GUD', 'GUANGDONG', 'cn', '30');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'GUA', 'GUANAJUATO', 'mx', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'GT', 'GAUTENG', 'za', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GS', 'GANSU', 'cn', '15');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'GR', 'GRONINGEN', 'nl', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'GO', 'GOIAS', 'br', '29');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'GJ', 'GUJARAT', 'in', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GIA', 'JIANGSU', 'cn', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'GE', 'GELDERLAND', 'nl', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'GE', 'GENEVA', 'ch', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'GA', 'GOA', 'in', '33');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'FUJ', 'FUJIAN', 'cn', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'FR', 'FRIESLAND', 'nl', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'FL', 'FLEVOLAND', 'nl', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BR', 'BRAZIL', 'ES', 'ESPÍRITO SANTO', 'br', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'EMI', 'EMILLIA ROMAGNA', 'it', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ZA', 'SOUTH AFRICA', 'EC', 'EASTERN CAPE', 'za', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'DUR', 'DURANGO', 'mx', '10');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'DUB', 'DUBAI', 'ae', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'NL', 'NETHERLANDS', 'DR', 'DRENTHE', 'nl', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'DL', 'DELHI', 'in', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'DIF', 'MEXICO CITY', 'mx', '09');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'ES', 'SPAIN', 'CT', 'CATALONIA', 'es', '56');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CSH', 'SHANXI', 'cn', '24');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CQ', 'CHONGQING', 'cn', '33');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'COL', 'COLIMA', 'mx', '08');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'COA', 'COAHUILA', 'mx', '07');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CHP', 'CHIAPAS', 'mx', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CHH', 'CHIHUAHUA', 'mx', '06');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CCH', 'SICHUAN', 'cn', '32');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IT', 'ITALY', 'CAM', 'CAMPANIA', 'it', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'CAM', 'CAMPECHE', 'mx', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'C', 'CHUBUT', 'ar', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BW', 'BADENWÜRTTEMBERG', 'de', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BST', 'BASEL STADT', 'ch', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CO', 'COLOMBIA', 'BOG', 'BOGOTA', 'co', '34');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BLA', 'BASEL LANDSCHAFT', 'ch', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BA', 'BOSNIA HERCEGOVINA', 'BIH', 'FEDERATION OF BH', 'ba', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CH', 'SWITZERLAND', 'BER', 'BERN', 'ch', '05');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'BEI', 'BEIJING', 'cn', '22');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BE', 'BERLIN', 'de', '16');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'BCN', 'BAJA CALIFORNIA', 'mx', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'BC', 'BRITISH COLUMBIA', 'ca', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'DE', 'GERMANY', 'BB', 'BRANDENBURG', 'de', '11');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'B', 'BUENOS AIRES', 'ar', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'PT', 'PORTUGAL', 'AZO', 'AZORES', 'pt', '23');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'AP', 'ANDHRA PRADESH', 'in', '02');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'ANH', 'ANHUI PROVINCE', 'cn', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'MX', 'MEXICO', 'AGU', 'AGUASCALIENTES', 'mx', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'ACT', 'CAPITAL TERRITORY', 'au', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'ABU', 'ABU DHABI', 'ae', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CA', 'CANADA', 'AB', 'ALBERTA', 'ca', '01');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AR', 'ARGENTINA', 'A', 'SALTA', 'ar', '17');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'NO', 'LOWER AUSTRIA', 'at', '03');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AT', 'AUSTRIA', 'OO', 'UPPER AUSTRIA', 'at', '04');
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AQ', 'Antarctica', 'US', 'US administered', 'aq', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AU', 'AUSTRALIA', 'LG', 'LOCAL GOVERNMENT', 'au', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BE', 'BELGIUM', 'WAL', 'WALLONIA', 'be', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'BA', 'BOSNIA HERCEGOVINA', 'BRC', 'BRCKO', 'ba', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'CHD', 'CHENGDU CITY', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'DAL', 'DALIAN', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'DON', 'DONGGUAN', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GGU', 'GUANGZHOU', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'HNG', 'HENGYANG', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'PIN', 'PINGDINGSHAN', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SQI', 'QINGDAO', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'GSH', 'SHENZHEN', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'SUZ', 'SUZHOU', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'FXI', 'XIAMEN', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'CN', 'CHINA', 'XIA', 'XIAN CITY', 'cn', NULL);
	 
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'BA', 'BANGALORE', 'in', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'IN', 'INDIA', 'TG', 'TELANGANA', 'in', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'YZA', 'JEBEL ALI FREE ZONE', 'ae', NULL);
	
	INSERT INTO CSR.COMPLIANCE_REGION_MAP
	(COMPLIANCE_REGION_MAP_ID, COMPLIANCE_ITEM_SOURCE_ID, SOURCE_COUNTRY, SOURCE_COUNTRY_LABEL, SOURCE_REGION, SOURCE_REGION_LABEL, COUNTRY, REGION)
	VALUES (CSR.COMPLIANCE_REGION_MAP_ID_SEQ.NEXTVAL, 1, 'AE', 'UNITED ARAB EMIRATES', 'RUW', 'RUWAIS', 'ae', NULL);
END;
/
BEGIN
	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('ENG', 'England');
	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('NI', 'Northern Ireland');
	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('SCO', 'Scotland');
	INSERT INTO CSR.REGION_GROUP (REGION_GROUP_ID, GROUP_NAME)
	VALUES ('WAL', 'Wales');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '01');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '03');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'A9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'B9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '79');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '07');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'C9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'D9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '17');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '18');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'E9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '20');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'F9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '22');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'G9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'H9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '28');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'I9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'J9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'K9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'L6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '37');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'M9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'N9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '41');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'O9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '43');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', '45');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'P9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('ENG', 'gb', 'Q5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'Q9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'R9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'S9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('NI', 'gb', 'T4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'U9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '82');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '84');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'V9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'T9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '87');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', '88');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('SCO', 'gb', 'W9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '90');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '91');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '92');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'X1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '94');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y4');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y5');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y6');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y7');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y8');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Y9');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '96');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z1');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z2');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z3');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', '97');
	INSERT INTO CSR.REGION_GROUP_REGION (REGION_GROUP_ID, COUNTRY, REGION)
	VALUES ('WAL', 'gb', 'Z4');
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (93, 'Product Compliance', 'EnableProductCompliance', 'Enables the product compliance pages. !!! This module is currently in development and this script should not be used on live client sites !!!');
BEGIN
	UPDATE csr.compliance_item_source
	   SET description = 'User-defined'
	 WHERE description = 'User-entered';
END;
/
DECLARE
	v_card_id		chain.card.card_id%TYPE;
	v_desc			chain.card.description%TYPE;
	v_class			chain.card.class_type%TYPE;
	v_js_path		chain.card.js_include%TYPE;
	v_js_class		chain.card.js_class_type%TYPE;
	v_css_path		chain.card.css_include%TYPE;
	v_actions		chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductFilter';
	v_js_path := '/csr/site/chain/cards/filters/productFilter.js';
	v_js_class := 'Credit360.Chain.Filters.ProductFilter';
	v_css_path := '';
	security.user_pkg.logonadmin('');
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
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES (56, v_desc, 'Allows filtering of products', 'chain.product_report_pkg', '/csr/site/chain/products/productList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, v_desc , 'chain.product_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 56, v_card_id, 0);
	END LOOP;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (56, 1, 'Number of products');
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
	VALUES (56, 2, 2, 'Last edited');
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType', 'DECIMAL');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('PlantDesignFlowRateType', 'DECIMAL');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('buildingMetricNumeric', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('GJ', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('GJ/m'||UNISTR('\00B2')||'', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('GJ/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kWh', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kWh/m'||UNISTR('\00B2')||'', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kWh/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('Metric Tons CO2e', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kgCO2e/m'||UNISTR('\00B2')||'', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kgCO2e/m'||UNISTR('\00B3')||'PJ', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('kgCO2e/GJ', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('buildingMetricString', 'STRING');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('USD', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('amountOfLaundryProcessedAnnuallyType', 'DECIMAL');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('useDecimalType', 'DECIMAL');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('grossFloorAreaType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('useYesNoType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('coolingEquipmentRedundancyType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('optionalFloorAreaType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('hoursPerDayGuestsOnsiteType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('useIntegerType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('itEnergyConfigurationType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('onsiteLaundryType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('monthsInUseType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('numberOfWeekdaysType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('ownedByType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('percentCooledType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('percentHeatedType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('percentOfficeCooledType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('percentOfficeHeatedType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('poolType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('poolSizeType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('residentPopulationType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('useStringType', 'STRING');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('upsSystemRedundancyType', 'ENUM');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('m'||UNISTR('\00B3')||'', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('m'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'NUMERIC');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('numberOfBuildingsType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_TYPE (TYPE_NAME, BASIC_TYPE) VALUES ('occupancyPercentageType', 'INT');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('GJ', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('GJ/m'||UNISTR('\00B2')||'', 'GJ/m'||UNISTR('\00B2')||'');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('GJ/m'||UNISTR('\00B3')||'PJ', 'GJ/m'||UNISTR('\00B3')||'PJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('Metric Tons CO2e', 'Metric Tons CO2e');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('PlantDesignFlowRateType', 'Cubic Meters per Day');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('PlantDesignFlowRateType', 'Million Gallons per Day');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('USD', 'USD');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('amountOfLaundryProcessedAnnuallyType', 'Kilogram');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('amountOfLaundryProcessedAnnuallyType', 'pounds');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('amountOfLaundryProcessedAnnuallyType', 'short tons');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('buildingMetricNumeric', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('buildingMetricString', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('coolingEquipmentRedundancyType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('grossFloorAreaType', 'Square Feet');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('grossFloorAreaType', 'Square Meters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('hoursPerDayGuestsOnsiteType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('itEnergyConfigurationType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kWh', 'kWh');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kWh/m'||UNISTR('\00B2')||'', 'kWh/m'||UNISTR('\00B2')||'');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kWh/m'||UNISTR('\00B3')||'PJ', 'kWh/m'||UNISTR('\00B3')||'PJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kgCO2e/GJ', 'kgCO2e/GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kgCO2e/m'||UNISTR('\00B2')||'', 'kgCO2e/m'||UNISTR('\00B2')||'');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('kgCO2e/m'||UNISTR('\00B3')||'PJ', 'kgCO2e/m'||UNISTR('\00B3')||'PJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType', 'Feet');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('lengthOfAllOpenClosedRefrigerationUnitsType', 'Meters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('monthsInUseType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('m'||UNISTR('\00B3')||'', 'm'||UNISTR('\00B3')||'');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('m'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('numberOfBuildingsType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('numberOfWeekdaysType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('occupancyPercentageType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('onsiteLaundryType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('optionalFloorAreaType', 'Square Feet');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('optionalFloorAreaType', 'Square Meters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('ownedByType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('percentCooledType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('percentHeatedType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('percentOfficeCooledType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('percentOfficeHeatedType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('poolSizeType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('poolType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('residentPopulationType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('upsSystemRedundancyType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('useDecimalType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('useIntegerType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('useStringType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_UNIT (TYPE_NAME, UOM) VALUES ('useYesNoType', '<null>');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Recreational (20 yards x 15 yards)', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Short Course (25 yards x 20 yards)', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Olympic (50 meters x 25 meters)', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('useYesNoType', 'Yes', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('useYesNoType', 'No', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', 'N', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', 'N+1', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', 'N+2', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', '2N', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', 'Greater than 2N', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('coolingEquipmentRedundancyType', 'None of the Above', 5);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('hoursPerDayGuestsOnsiteType', 'Less Than 15', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('hoursPerDayGuestsOnsiteType', '15 To 19', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('hoursPerDayGuestsOnsiteType', 'More Than 20', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('itEnergyConfigurationType', 'UPS Supports Only IT Equipment', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('itEnergyConfigurationType', 'UPS Include Non IT Load Less Than 10%', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('itEnergyConfigurationType', 'UPS Include Non-IT Load Greater Than 10% Load Submetered', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('itEnergyConfigurationType', 'UPS Include Non IT Load Greater Than 10% Load Not Submetered', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('itEnergyConfigurationType', 'Facility Has No UPS', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('onsiteLaundryType', 'Linens only', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('onsiteLaundryType', 'Terry only', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('onsiteLaundryType', 'Both linens and terry', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('onsiteLaundryType', 'No laundry facility', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('ownedByType', 'For Profit', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('ownedByType', 'Non Profit', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('ownedByType', 'Governmental', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '0', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '10', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '20', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '30', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '40', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '50', 5);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '60', 6);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '70', 7);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '80', 8);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '90', 9);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentCooledType', '100', 10);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '0', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '10', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '20', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '30', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '40', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '50', 5);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '60', 6);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '70', 7);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '80', 8);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '90', 9);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentHeatedType', '100', 10);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeCooledType', '50% or more', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeCooledType', 'Less than 50%', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeCooledType', 'Not Air Conditioned', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeHeatedType', '50% or more', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeHeatedType', 'Less than 50%', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('percentOfficeHeatedType', 'Not Heated', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolType', 'Indoor', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolType', 'Outdoor', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Recreational (20 yards x 15 yards)', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Short Course (25 yards x 20 yards)', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('poolSizeType', 'Olympic (50 meters x 25 meters)', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'No specific resident population', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'Dedicated Student', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'Dedicated Military', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'Dedicated Senior/Independent Living', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'Dedicated Special Accessibility Needs', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('residentPopulationType', 'Other dedicated housing', 5);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', 'N', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', 'N+1', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', 'N+2', 2);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', '2N', 3);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', 'Greater than 2N', 4);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_ENUM (TYPE_NAME, ENUM, POS) VALUES ('upsSystemRedundancyType', 'None of the Above', 5);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('areaOfAllWalkInRefrigerationUnits', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('lengthOfAllOpenClosedRefrigerationUnits', 'lengthOfAllOpenClosedRefrigerationUnitsType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('amountOfLaundryProcessedAnnually', 'amountOfLaundryProcessedAnnuallyType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('averageEffluentBiologicalOxygenDemand', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('averageInfluentBiologicalOxygenDemand', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('averageNumberOfResidents', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('completelyEnclosedFootage', 'grossFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('cookingFacilities', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('coolingEquipmentRedundancy', 'coolingEquipmentRedundancyType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('exteriorEntranceToThePublic', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('fixedFilmTrickleFiltrationProcess', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('fullServiceSpaFloorArea', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('enclosedFloorArea', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('governmentSubsidizedHousing', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('gymCenterFloorArea', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('hasComputerLab', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('hasDiningHall', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('hasLaboratory', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('hoursPerDayGuestsOnsite', 'hoursPerDayGuestsOnsiteType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('isHighSchool', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('isTertiaryCare', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('iceEvents', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfConcertShowEventsPerYear', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfSpecialOtherEventsPerYear', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfSportingEventsPerYear', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfSurgicalOperatingBeds', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('sizeOfElectronicScoreBoards', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('surgeryCenterFloorArea', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('itEnergyMeterConfiguration', 'itEnergyConfigurationType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('laundryFacility', 'onsiteLaundryType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('maximumNumberOfFloors', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('maximumResidentCapacity', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('licensedBedCapacity', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('monthsInUse', 'monthsInUseType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfBedrooms', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfCashRegisters', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfCommercialRefrigerationUnits', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfCommercialWashingMachines', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfComputers', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialLivingUnitsLowRiseSetting', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfFTEWorkers', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfGuestMealsServedPerYear', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfLaundryHookupsInAllUnits', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfLaundryHookupsInCommonArea', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfMriMachines', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfOpenClosedRefrigerationUnits', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfPeople', 'useIntegerType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialLiftSystems', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialLivingUnits', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialWashingMachines', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfRooms', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfHotelRooms', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfStaffedBeds', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfWalkInRefrigerationUnits', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfWeekdaysOpen', 'numberOfWeekdaysType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfWorkers', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('gymnasiumFloorArea', 'optionalFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('studentSeatingCapacity', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('nutrientRemoval', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('onSiteLaundryFacility', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('openFootage', 'grossFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('openOnWeekends', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('ownedBy', 'ownedByType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('partiallyEnclosedFootage', 'grossFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('percentCooled', 'percentCooledType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('percentHeated', 'percentHeatedType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialLivingUnitsMidRiseSetting', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('percentOfGrossFloorAreaThatIsCommonSpaceOnly', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('percentOfficeCooled', 'percentOfficeCooledType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('percentOfficeHeated', 'percentOfficeHeatedType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('plantDesignFlowRate', 'PlantDesignFlowRateType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('poolLocation', 'poolType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('poolSize', 'poolSizeType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('numberOfResidentialLivingUnitsHighRiseSetting', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('residentPopulation', 'residentPopulationType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('schoolDistrict', 'useStringType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('seatingCapacity', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('singleStore', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('totalGrossFloorArea', 'grossFloorAreaType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('upsSystemRedundancy', 'upsSystemRedundancyType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('supplementalHeating', 'useYesNoType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('weeklyOperatingHours', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('enrollment', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_SPACE (ATTR_NAME, TYPE_NAME) VALUES ('grantDollars', 'useDecimalType');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('score', 'buildingMetricNumeric', 0, 'ENERGY STAR Score');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianSiteTotal', 'GJ', 0, 'National Median Site Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianSourceTotal', 'GJ', 0, 'National Median Source Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianSiteIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'National Median Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianSourceIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'National Median Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianWaterWasteWaterSiteIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'National Median Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianWaterWasteWaterSourceIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'National Median Water/Wastewater Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('percentBetterThanSiteIntensityMedian', 'buildingMetricNumeric', 0, 'Difference from National Median Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('percentBetterThanSourceIntensityMedian', 'buildingMetricNumeric', 0, 'Difference from National Median Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('percentBetterThanWaterWasteWaterSiteIntensityMedian', 'buildingMetricNumeric', 0, 'Difference from National Median Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('percentBetterThanWaterWasteWaterSourceIntensityMedian', 'buildingMetricNumeric', 0, 'Difference from National Median Water/Wastewater Source  EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteTotal', 'GJ', 0, 'Site Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceTotal', 'GJ', 0, 'Source Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSiteIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSourceIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteTotalWN', 'GJ', 0, 'Weather Normalized Site Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceTotalWN', 'GJ', 0, 'Weather Normalized Source Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteIntensityWN', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Weather Normalized Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceIntensityWN', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Weather Normalized Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSiteIntensityWN', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Weather Normalized Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSourceIntensityWN', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Weather Normalized Water/Wastewater Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteElectricityTotalWN', 'kWh', 0, 'Weather Normalized Site Electricity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteElectricityIntensityWN', 'kWh/m'||UNISTR('\00B2')||'', 0, 'Weather Normalized Site Electricity Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSiteElectricityIntensityWN', 'kWh/m'||UNISTR('\00B3')||'PJ', 0, 'Weather Normalized Water/Wastewater Site Electricity Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteNaturalGasUseTotalWN', 'GJ', 0, 'Weather Normalized Site Natural Gas Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteNaturalGasUseIntensityWN', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Weather Normalized Site Natural Gas Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSiteNaturalGasUseIntensityWN', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Weather Normalized Water/Wastewater Site Natural Gas Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteEnergyUseAdjustedToCurrentYear', 'GJ', 0, 'Site Energy Use - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceEnergyUseAdjustedToCurrentYear', 'GJ', 0, 'Source Energy Use - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('siteIntensityAdjustedToCurrentYear', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Site EUI - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('sourceIntensityAdjustedToCurrentYear', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Source EUI - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSiteIntensityAdjustedToCurrentYear', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Site EUI - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterSourceIntensityAdjustedToCurrentYear', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Source EUI - Adjusted to Current Year');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianScore', 'buildingMetricNumeric', 0, 'National Median ENERGY STAR Score');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('totalGHGEmissions', 'Metric Tons CO2e', 0, 'Total GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('totalGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Total GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterTotalGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Total GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('directGHGEmissions', 'Metric Tons CO2e', 0, 'Direct GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('directGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Direct GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterDirectGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Direct GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('indirectGHGEmissions', 'Metric Tons CO2e', 0, 'Indirect GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('indirectGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Indirect GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterIndirectGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Indirect GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('biomassGHGEmissions', 'Metric Tons CO2e', 0, 'Biomass GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('biomassGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Biomass GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterWasteWaterBiomassGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B3')||'PJ', 0, 'Water/Wastewater Biomass GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('egridOutputEmissionsRate', 'kgCO2e/GJ', 0, 'eGRID Output Emissions Rate');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('regionalPowerGrid', 'buildingMetricString', 0, 'eGRID Subregion');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('electricDistributionUtility', 'buildingMetricString', 0, 'Electric Distribution Utility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('powerPlant', 'buildingMetricString', 0, 'Power Plant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('medianTotalGHGEmissions', 'Metric Tons CO2e', 0, 'National Median Total GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('energyStarCertificationYears', 'buildingMetricString', 0, 'ENERGY STAR Certification - Year(s) Certified');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('energyStarCertificationEligibility', 'buildingMetricString', 0, 'ENERGY STAR Certification - Eligibility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('energyStarCertificationApplicationStatus', 'buildingMetricString', 0, 'ENERGY STAR Certification - Application Status');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('energyStarCertificationProfilePublished', 'buildingMetricString', 0, 'ENERGY STAR Certification - Profile Published');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetScore', 'buildingMetricNumeric', 0, 'Target ENERGY STAR Score');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetPercentBetterThanSourceIntensityMedian', 'buildingMetricNumeric', 0, 'Target % Better Than Median Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetSiteTotal', 'GJ', 0, 'Target Site Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetSourceTotal', 'GJ', 0, 'Target Source Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetSiteIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Target Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetSourceIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Target Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetWaterWasteWaterSiteIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Target Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetWaterWasteWaterSourceIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Target Water/Wastewater Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetEnergyCost', 'USD', 0, 'Target Energy Cost');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetTotalGHGEmissions', 'Metric Tons CO2e', 0, 'Target Total GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetScore', 'buildingMetricNumeric', 0, 'Design Target ENERGY STAR Score');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetBetterThanMedianSourceIntensity', 'buildingMetricNumeric', 0, 'Design Target % Better Than Median Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetSiteTotal', 'GJ', 0, 'Design Target Site Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetSourceTotal', 'GJ', 0, 'Design Target Source Energy Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetSiteIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Design Target Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetSourceIntensity', 'GJ/m'||UNISTR('\00B2')||'', 0, 'Design Target Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetWaterWasteWaterSiteIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Design Target Water/Wastewater Site EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetWaterWasteWaterSourceIntensity', 'GJ/m'||UNISTR('\00B3')||'PJ', 0, 'Design Target Water/Wastewater Source EUI');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetEnergyCost', 'USD', 0, 'Design Target Energy Cost');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetTotalGHGEmissions', 'Metric Tons CO2e', 0, 'Design Target Total GHG Emissions');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('designTargetTotalGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Design Target Total GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('targetTotalGHGEmissionsIntensity', 'kgCO2e/m'||UNISTR('\00B2')||'', 0, 'Target Total GHG Emissions Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterUPSOutputSiteEnergy', 'kWh', 0, 'Data Center - UPS Output Meter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterPDUInputSiteEnergy', 'kWh', 0, 'Data Center - PDU Input Meter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterPDUOutputSiteEnergy', 'kWh', 0, 'Data Center - PDU Output Meter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterITEquipmentInputSiteEnergy', 'kWh', 0, 'Data Center - IT Equipment Input Meter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterITSiteEnergy', 'kWh', 0, 'Data Center - IT Site Energy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterITSourceEnergy', 'GJ', 0, 'Data Center - IT Source Energy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterSourcePUE', 'buildingMetricNumeric', 0, 'Data Center - PUE');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('dataCenterPUEMedian', 'buildingMetricNumeric', 0, 'Data Center - National Median PUE');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('waterUseTotal', 'm'||UNISTR('\00B3')||'', 0, 'Water Use (All Water Sources)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('indoorWaterUseTotalAllWaterSources', 'm'||UNISTR('\00B3')||'', 0, 'Indoor Water Use (All Water Sources)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('indoorWaterIntensityAllWaterSources', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Indoor Water Intensity (All Water Sources)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('outdoorWaterUseTotalAllWaterSources', 'm'||UNISTR('\00B3')||'', 0, 'Outdoor Water Use (All Water Sources)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedPotableWaterMixedUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Potable Water - Mixed Indoor/Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedPotableWaterIndoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Potable Water - Indoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedPotableWaterIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Municipally Supplied Potable Water - Indoor Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedPotableWaterOutdoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Potable Water - Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedReclaimedWaterMixedUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedReclaimedWaterIndoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Reclaimed Water - Indoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedReclaimedWaterIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Municipally Supplied Reclaimed Water - Indoor Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('municipallySuppliedReclaimedWaterOutdoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Municipally Supplied Reclaimed Water - Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('alternativeWaterGeneratedOnsiteMixedUse', 'm'||UNISTR('\00B3')||'', 0, 'Alternative Water Generated On Site - Mixed Indoor/Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('alternativeWaterGeneratedOnsiteIndoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Alternative Water Generated On Site - Indoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('alternativeWaterGeneratedOnsiteIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Alternative Water Generated On Site - Indoor Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('alternativeWaterGeneratedOnsiteOutdoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Alternative Water Generated On Site - Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('otherWaterSourcesMixedUse', 'm'||UNISTR('\00B3')||'', 0, 'Other Water Sources - Mixed Indoor/Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('otherWaterSourcesIndoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Other Water Sources - Indoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('otherWaterSourcesIndoorIntensity', 'm'||UNISTR('\00B3')||'/m'||UNISTR('\00B2')||'', 0, 'Other Water Sources - Indoor Intensity');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('otherWaterSourcesOutdoorUse', 'm'||UNISTR('\00B3')||'', 0, 'Other Water Sources - Outdoor Use');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('bldgGrossFloorArea', 'grossFloorAreaType', 1, 'Building Gross Floor Area');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('numberOfBuildings', 'numberOfBuildingsType', 0, 'Number of Buildings');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_ATTR_FOR_BUILDING (ATTR_NAME, TYPE_NAME, IS_MANDATORY, LABEL) VALUES ('occupancyPercentage', 'occupancyPercentageType', 0, 'Occupancy Percentage');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('adultEducation', 'Adult Education');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('ambulatorySurgicalCenter', 'Ambulatory Surgical Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('aquarium', 'Aquarium');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('automobileDealership', 'Automobile Dealership');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('bankBranch', 'Bank Branch');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('barNightclub', 'Bar Nightclub');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('barracks', 'Barracks');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('bowlingAlley', 'Bowling Alley');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('casino', 'Casino');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('collegeUniversity', 'College University');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('convenienceStoreWithGasStation', 'Convenience Store With Gas Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('convenienceStoreWithoutGasStation', 'Convenience Store Without Gas Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('conventionCenter', 'Convention Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('courthouse', 'Courthouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('dataCenter', 'Data Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('distributionCenter', 'Distribution Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('drinkingWaterTreatmentAndDistribution', 'Drinking Water Treatment And Distribution');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('enclosedMall', 'Enclosed Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('energyPowerStation', 'Energy Power Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('fastFoodRestaurant', 'Fast Food Restaurant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('financialOffice', 'Financial Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('fireStation', 'Fire Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('fitnessCenterHealthClubGym', 'Fitness Center Health Club Gym');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('foodSales', 'Food Sales');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('foodService', 'Food Service');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('hospital', 'Hospital');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('hotel', 'Hotel');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('iceCurlingRink', 'Ice Curling Rink');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('indoorArena', 'Indoor Arena');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('k12School', 'K12 School');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('laboratory', 'Laboratory');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('library', 'Library');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('lifestyleCenter', 'Lifestyle Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('mailingCenterPostOffice', 'Mailing Center Post Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('manufacturingIndustrialPlant', 'Manufacturing Industrial Plant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('medicalOffice', 'Medical Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('movieTheater', 'Movie Theater');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('multifamilyHousing', 'Multifamily Housing');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('museum', 'Museum');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('nonRefrigeratedWarehouse', 'Non Refrigerated Warehouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('office', 'Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('other', 'Other');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherEducation', 'Other Education');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherEntertainmentPublicAssembly', 'Other Entertainment Public Assembly');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherLodgingResidential', 'Other Lodging Residential');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherMall', 'Other Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherPublicServices', 'Other Public Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherRecreation', 'Other Recreation');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherRestaurantBar', 'Other Restaurant Bar');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherServices', 'Other Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherSpecialityHospital', 'Other Speciality Hospital');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherStadium', 'Other Stadium');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherTechnologyScience', 'Other Technology Science');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('otherUtility', 'Other Utility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('outpatientRehabilitationPhysicalTherapy', 'Outpatient Rehabilitation Physical Therapy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('parking', 'Parking');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('performingArts', 'Performing Arts');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('personalServices', 'Personal Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('policeStation', 'Police Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('preschoolDaycare', 'Preschool Daycare');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('prison', 'Prison');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('raceTrack', 'Race Track');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('refrigeratedWarehouse', 'Refrigerated Warehouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('repairServices', 'Repair Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('residenceHallDormitory', 'Residence Hall Dormitory');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('residentialCareFacility', 'Residential Care Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('restaurant', 'Restaurant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('retail', 'Retail');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('rollerRink', 'Roller Rink');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('selfStorageFacility', 'Self Storage Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('seniorCareCommunity', 'Senior Care Community');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('singleFamilyHome', 'Single Family Home');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('socialMeetingHall', 'Social Meeting Hall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('stadiumClosed', 'Stadium Closed');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('stadiumOpen', 'Stadium Open');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('stripMall', 'Strip Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('supermarket', 'Supermarket');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('swimmingPool', 'Swimming Pool');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('transportationTerminalStation', 'Transportation Terminal Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('urgentCareClinicOtherOutpatient', 'Urgent Care Clinic Other Outpatient');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('veterinaryOffice', 'Veterinary Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('vocationalSchool', 'Vocational School');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('wastewaterTreatmentPlant', 'Wastewater Treatment Plant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('wholesaleClubSupercenter', 'Wholesale Club Supercenter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('worshipFacility', 'Worship Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE (EST_SPACE_TYPE, LABEL) VALUES ('zoo', 'Zoo');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Adult Education');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Ambulatory Surgical Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Aquarium');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Automobile Dealership');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Bank Branch');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Bar/Nightclub');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Barracks');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Bowling Alley');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Casino');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('College/University');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Convenience Store with Gas Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Convenience Store without Gas Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Convention Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Courthouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Data Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Distribution Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Drinking Water Treatment '||'&'||' Distribution');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Enclosed Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Energy/Power Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Fast Food Restaurant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Financial Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Fire Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Fitness Center/Health Club/Gym');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Food Sales');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Food Service');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Hospital (General Medical '||'&'||' Surgical)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Hotel');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Ice/Curling Rink');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Indoor Arena');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('K-12 School');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Laboratory');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Library');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Lifestyle Center');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Mailing Center/Post Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Manufacturing/Industrial Plant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Medical Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Mixed Use Property');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Movie Theater');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Multifamily Housing');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Museum');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Non-Refrigerated Warehouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Education');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Entertainment/Public Assembly');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Lodging/Residential');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Public Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Recreation');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Restaurant/Bar');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Services');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Stadium');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Technology/Science');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other - Utility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Other/Specialty Hospital');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Outpatient Rehabilitation/Physical Therapy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Parking');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Performing Arts');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Personal Services (Health/Beauty, Dry Cleaning, etc)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Police Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Pre-school/Daycare');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Prison/Incarceration');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Race Track');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Refrigerated Warehouse');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Repair Services (Vehicle, Shoe, Locksmith, etc)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Residence Hall/Dormitory');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Residential Care Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Restaurant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Retail Store');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Roller Rink');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Self-Storage Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Senior Care Community');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Single Family Home');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Social/Meeting Hall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Stadium (Closed)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Stadium (Open)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Strip Mall');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Supermarket/Grocery Store');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Swimming Pool');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Transportation Terminal/Station');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Urgent Care/Clinic/Other Outpatient');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Veterinary Office');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Vocational School');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Wastewater Treatment Plant');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Wholesale Club/Supercenter');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Worship Facility');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_PROPERTY_TYPE (EST_PROPERTY_TYPE) VALUES ('Zoo');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'singleStore', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'areaOfAllWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'lengthOfAllOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'licensedBedCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfResidentialLivingUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'averageNumberOfResidents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'maximumResidentCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfCommercialRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfCommercialWashingMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfResidentialWashingMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'numberOfResidentialLiftSystems', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residentialCareFacility', 'licensedBedCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('refrigeratedWarehouse', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('refrigeratedWarehouse', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('refrigeratedWarehouse', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'singleStore', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('retail', 'exteriorEntranceToThePublic', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'hasLaboratory', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'onSiteLaundryFacility', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'maximumNumberOfFloors', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'numberOfStaffedBeds', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'numberOfFTEWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'numberOfMriMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'ownedBy', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'isTertiaryCare', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'licensedBedCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hospital', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'numberOfSurgicalOperatingBeds', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'surgeryCenterFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('medicalOffice', 'numberOfMriMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('dataCenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('dataCenter', 'coolingEquipmentRedundancy', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('dataCenter', 'itEnergyMeterConfiguration', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('dataCenter', 'upsSystemRedundancy', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'percentOfficeCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'percentOfficeHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('courthouse', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('singleFamilyHome', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('singleFamilyHome', 'numberOfBedrooms', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('singleFamilyHome', 'numberOfPeople', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('nonRefrigeratedWarehouse', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfResidentialLivingUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfBedrooms', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfResidentialLivingUnitsMidRiseSetting', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfLaundryHookupsInAllUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfLaundryHookupsInCommonArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfResidentialLivingUnitsLowRiseSetting', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'numberOfResidentialLivingUnitsHighRiseSetting', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'residentPopulation', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('multifamilyHousing', 'governmentSubsidizedHousing', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'percentOfficeCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('office', 'percentOfficeHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'exteriorEntranceToThePublic', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wholesaleClubSupercenter', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfResidentialLivingUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'averageNumberOfResidents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'maximumResidentCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfCommercialRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfCommercialWashingMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfResidentialWashingMachines', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'numberOfResidentialLiftSystems', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('seniorCareCommunity', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('swimmingPool', 'poolSize', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('swimmingPool', 'poolLocation', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('swimmingPool', 'monthsInUse', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'numberOfRooms', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'hasComputerLab', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('residenceHallDormitory', 'hasDiningHall', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'averageInfluentBiologicalOxygenDemand', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'averageEffluentBiologicalOxygenDemand', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'plantDesignFlowRate', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'fixedFilmTrickleFiltrationProcess', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('wastewaterTreatmentPlant', 'nutrientRemoval', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('distributionCenter', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'numberOfCommercialRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'seatingCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('worshipFacility', 'numberOfWeekdaysOpen', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'percentOfficeCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'percentOfficeHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('financialOffice', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('drinkingWaterTreatmentAndDistribution', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('parking', 'supplementalHeating', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('parking', 'openFootage', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('parking', 'completelyEnclosedFootage', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('parking', 'partiallyEnclosedFootage', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'numberOfOpenClosedRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'numberOfCashRegisters', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('supermarket', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'hasComputerLab', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'hasDiningHall', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'numberOfRooms', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barracks', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'fullServiceSpaFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'gymCenterFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'hoursPerDayGuestsOnsite', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'numberOfCommercialRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'numberOfGuestMealsServedPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'numberOfHotelRooms', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'laundryFacility', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'amountOfLaundryProcessedAnnually', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('hotel', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'openOnWeekends', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'cookingFacilities', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'isHighSchool', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'monthsInUse', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'schoolDistrict', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'studentSeatingCapacity', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('k12School', 'gymnasiumFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'percentOfficeCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'percentOfficeHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bankBranch', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'enrollment', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'grantDollars', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('collegeUniversity', 'numberOfFTEWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'enclosedFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'numberOfSportingEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'numberOfConcertShowEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'numberOfSpecialOtherEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'sizeOfElectronicScoreBoards', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'iceEvents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('indoorArena', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'enclosedFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'numberOfSportingEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'numberOfConcertShowEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'numberOfSpecialOtherEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'sizeOfElectronicScoreBoards', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'iceEvents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherStadium', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'enclosedFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'numberOfSportingEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'numberOfConcertShowEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'numberOfSpecialOtherEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'sizeOfElectronicScoreBoards', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'iceEvents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumClosed', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'enclosedFloorArea', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'numberOfSportingEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'numberOfConcertShowEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'numberOfSpecialOtherEventsPerYear', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'sizeOfElectronicScoreBoards', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'iceEvents', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'numberOfWalkInRefrigerationUnits', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'percentCooled', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stadiumOpen', 'percentHeated', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('prison', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('prison', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('prison', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('prison', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('manufacturingIndustrialPlant', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('manufacturingIndustrialPlant', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('manufacturingIndustrialPlant', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('manufacturingIndustrialPlant', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('ambulatorySurgicalCenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('ambulatorySurgicalCenter', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('ambulatorySurgicalCenter', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('ambulatorySurgicalCenter', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bowlingAlley', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bowlingAlley', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bowlingAlley', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('bowlingAlley', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherPublicServices', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherPublicServices', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherPublicServices', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherPublicServices', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherLodgingResidential', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherLodgingResidential', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherLodgingResidential', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherLodgingResidential', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('casino', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('casino', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('casino', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('casino', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('personalServices', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('personalServices', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('personalServices', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('personalServices', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('mailingCenterPostOffice', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('mailingCenterPostOffice', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('mailingCenterPostOffice', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('mailingCenterPostOffice', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('library', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('library', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('library', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('library', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherSpecialityHospital', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherSpecialityHospital', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherSpecialityHospital', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherSpecialityHospital', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('conventionCenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('conventionCenter', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('conventionCenter', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('conventionCenter', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('veterinaryOffice', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('veterinaryOffice', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('veterinaryOffice', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('veterinaryOffice', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('urgentCareClinicOtherOutpatient', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('urgentCareClinicOtherOutpatient', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('urgentCareClinicOtherOutpatient', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('urgentCareClinicOtherOutpatient', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('energyPowerStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('energyPowerStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('energyPowerStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('energyPowerStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherServices', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherServices', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherServices', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherServices', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barNightclub', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barNightclub', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barNightclub', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('barNightclub', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherUtility', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherUtility', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherUtility', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherUtility', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('zoo', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('zoo', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('zoo', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('zoo', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('automobileDealership', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('automobileDealership', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('automobileDealership', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('automobileDealership', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('museum', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('museum', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('museum', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('museum', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRecreation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRecreation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRecreation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRecreation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRestaurantBar', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRestaurantBar', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRestaurantBar', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherRestaurantBar', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('lifestyleCenter', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('lifestyleCenter', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('lifestyleCenter', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('lifestyleCenter', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('policeStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('policeStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('policeStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('policeStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('preschoolDaycare', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('preschoolDaycare', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('preschoolDaycare', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('preschoolDaycare', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('raceTrack', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('raceTrack', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('raceTrack', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('raceTrack', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('selfStorageFacility', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('selfStorageFacility', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('selfStorageFacility', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('selfStorageFacility', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fastFoodRestaurant', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fastFoodRestaurant', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fastFoodRestaurant', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fastFoodRestaurant', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('laboratory', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('laboratory', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('laboratory', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('laboratory', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithoutGasStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('repairServices', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('repairServices', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('repairServices', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('repairServices', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherTechnologyScience', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherTechnologyScience', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherTechnologyScience', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherTechnologyScience', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fireStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fireStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fireStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fireStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodSales', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('performingArts', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('performingArts', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('performingArts', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('performingArts', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('outpatientRehabilitationPhysicalTherapy', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('outpatientRehabilitationPhysicalTherapy', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('outpatientRehabilitationPhysicalTherapy', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('outpatientRehabilitationPhysicalTherapy', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stripMall', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stripMall', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stripMall', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('stripMall', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('rollerRink', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('rollerRink', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('rollerRink', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('rollerRink', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEducation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEducation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEducation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEducation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fitnessCenterHealthClubGym', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fitnessCenterHealthClubGym', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fitnessCenterHealthClubGym', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('fitnessCenterHealthClubGym', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('aquarium', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('aquarium', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('aquarium', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('aquarium', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodService', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodService', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodService', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('foodService', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('restaurant', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('restaurant', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('restaurant', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('restaurant', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('enclosedMall', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('enclosedMall', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('enclosedMall', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('enclosedMall', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('iceCurlingRink', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('iceCurlingRink', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('iceCurlingRink', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('iceCurlingRink', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('adultEducation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('adultEducation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('adultEducation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('adultEducation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEntertainmentPublicAssembly', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEntertainmentPublicAssembly', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEntertainmentPublicAssembly', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherEntertainmentPublicAssembly', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('movieTheater', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('movieTheater', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('movieTheater', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('movieTheater', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('transportationTerminalStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('transportationTerminalStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('transportationTerminalStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('transportationTerminalStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('vocationalSchool', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('vocationalSchool', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('vocationalSchool', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('vocationalSchool', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('socialMeetingHall', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('socialMeetingHall', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('socialMeetingHall', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('socialMeetingHall', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherMall', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherMall', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherMall', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('otherMall', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('convenienceStoreWithGasStation', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('other', 'totalGrossFloorArea', 1);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('other', 'weeklyOperatingHours', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('other', 'numberOfComputers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_SPACE_TYPE_ATTR (EST_SPACE_TYPE, ATTR_NAME, IS_MANDATORY) VALUES ('other', 'numberOfWorkers', 0);
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Alternative Water Generated On-Site - Indoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Alternative Water Generated On-Site - Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Average Influent Flow');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Coal Anthracite');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Coal Bituminous');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Coke');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Diesel');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Chilled Water - Electric-Driven Chiller');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Chilled Water - Other');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Hot Water');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('District Steam');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Electric');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Electric on Site Solar');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Electric on Site Wind');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Fuel Oil No 1');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Fuel Oil No 2');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Fuel Oil No 4');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Fuel Oil No 5 or 6');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('IT Equipment Input Energy (meters on each piece of equipment)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Kerosene');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Potable Water - Indoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Potable Water - Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Reclaimed Water - Indoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Municipally Supplied Reclaimed Water - Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Natural Gas');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Other (Energy)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Other - Indoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Other - Mixed Indoor/Outdoor (Water)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Other - Outdoor');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Power Distribution Unit (PDU) Input Energy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Power Distribution Unit (PDU) Output Energy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Propane');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Uninterruptible Power Supply (UPS) Output Energy');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_TYPE (METER_TYPE) VALUES ('Wood');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'KLbs. (thousand pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'MLbs. (million pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'Tonnes (metric)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'pounds');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coke', 'tons');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Diesel', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Absorption Chiller using Natural Gas', 'ton hours');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Electric-Driven Chiller', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Electric-Driven Chiller', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Electric-Driven Chiller', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Electric-Driven Chiller', 'ton hours');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Engine-Driven Chiller using Natural Gas', 'ton hours');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Other', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Other', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Other', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Chilled Water - Other', 'ton hours');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Hot Water', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Hot Water', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Hot Water', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Hot Water', 'therms');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'KLbs. (thousand pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'MLbs. (million pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'kg');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'pounds');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('District Steam', 'therms');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric', 'MWh (million Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Solar', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Solar', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Solar', 'MWh (million Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Solar', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Solar', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Wind', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Wind', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Wind', 'MWh (million Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Wind', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Electric on Site Wind', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 1', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 2', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 4', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Fuel Oil No 5 or 6', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('IT Equipment Input Energy (meters on each piece of equipment)', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Kerosene', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Indoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Potable Water - Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Indoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Municipally Supplied Reclaimed Water - Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Natural Gas', 'therms');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other (Energy)', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other (Energy)', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Indoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Mixed Indoor/Outdoor (Water)', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Other - Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Power Distribution Unit (PDU) Input Energy', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Power Distribution Unit (PDU) Output Energy', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'ccf');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Propane', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Uninterruptible Power Supply (UPS) Output Energy', 'kWh (thousand Watt-hours)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Wood', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Wood', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Wood', 'Tonnes (metric)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Wood', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Wood', 'tons');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Indoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Mixed Indoor/Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'KGal (thousand gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Kcm (Thousand Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MCF(million cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MGal (million gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'MGal (million gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cGal (hundred gallons) (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cGal (hundred gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Alternative Water Generated On-Site - Outdoor', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'Gallons (UK)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'Gallons (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'KGal (thousand gallons) (US)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'Liters');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'ccf (hundred cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'cf (cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'cm (Cubic meters)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Average Influent Flow', 'kcf (thousand cubic feet)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'KLbs. (thousand pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'MLbs. (million pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'Tonnes (metric)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'pounds');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Anthracite', 'tons');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'GJ');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'KLbs. (thousand pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'MBtu (million Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'MLbs. (million pounds)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'Tonnes (metric)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'kBtu (thousand Btu)');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'pounds');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO CSR.EST_METER_CONV (METER_TYPE, UOM) VALUES ('Coal Bituminous', 'tons');
EXCEPTION WHEN
	DUP_VAL_ON_INDEX THEN
		NULL;
END;
/




CREATE OR REPLACE PACKAGE CHAIN.company_product_pkg AS END;
/
GRANT EXECUTE ON CHAIN.company_product_pkg TO web_user;
create or replace package csr.permission_pkg as end;
/
grant execute on csr.permission_pkg to web_user;
grant execute on aspen2.aspen_user_pkg to web_user;
CREATE OR REPLACE PACKAGE chain.company_score_pkg AS END;
/
GRANT execute ON chain.company_score_pkg TO csr;
GRANT execute ON chain.company_score_pkg TO web_user;
CREATE OR REPLACE PACKAGE chain.certification_report_pkg AS END;
/
GRANT EXECUTE ON chain.certification_report_pkg TO web_user;
grant execute on chain.company_product_pkg to csr;
grant execute on chain.certification_pkg to csr;

@..\flow_pkg
@..\chain\company_product_pkg
@..\schema_pkg
@..\compliance_pkg
@..\csr_user_pkg
@..\permission_pkg
@..\donations\donation_pkg
@..\supplier\company_pkg
@..\supplier\product_pkg
@..\tree_pkg
@..\csrimp\imp_pkg
@..\chain\certification_pkg
@@..\compliance_pkg
@@..\csrimp\imp_pkg
@@..\enable_pkg
@@..\util_script_pkg
@..\chain\company_filter_pkg
@..\chain\company_dedupe_pkg
@..\chain\dedupe_admin_pkg
@..\chain\company_score_pkg
@..\chain\company_type_pkg
@..\csr_data_pkg
@..\supplier_pkg
@..\audit_pkg
@..\audit_helper_pkg
@..\audit_report_pkg
@..\quick_survey_pkg
@..\chain\plugin_pkg
@..\chain\filter_pkg
@..\chain\certification_report_pkg
@..\chain\bsci_pkg
@..\chain\higg_pkg
@..\chain\helper_pkg
@..\chain\product_report_pkg
@..\chain\product_type_pkg
@..\chain\product_pkg
@..\chain\plugin_pkg 


@@..\meter_list_body
@..\chain\company_product_body
@..\schema_body
@..\compliance_body
@..\csrimp\imp_body
@..\csr_user_body
@..\permission_body
@..\donations\donation_body
@..\supplier\company_body
@..\supplier\product_body
@..\tree_body
@..\..\..\aspen2\db\tree_body
@..\csr_app_body
@..\delegation_body
@..\issue_report_body
@..\chain\certification_body
@@..\compliance_body
@@..\csrimp\imp_body
@@..\schema_body
@@..\enable_body
@..\region_body
@@..\util_script_body
@..\chain\activity_report_body
@..\chain\company_filter_body
@..\audit_report_body
@..\non_compliance_report_body
@..\chain\company_dedupe_body
@..\chain\dedupe_admin_body
@..\quick_survey_body
@..\chain\company_score_body
@..\chain\company_type_body
@..\supplier_body
@..\audit_body
@..\audit_helper_body
@..\like_for_like_body
@..\testdata_body
@..\chain\chain_body
@..\chain\plugin_body
@..\chain\certification_report_body
@..\chain\bsci_body
@..\compliance_register_report_body
@..\compliance_library_report_body
@..\chain\higg_body
@@..\compliance_register_report_body
@@..\compliance_library_report_body
@@..\flow_body
@..\chain\helper_body
@..\chain\product_type_body
@@..\quick_survey_body
@..\chain\product_report_body
@..\chain\product_body
@..\templated_report_body
@..\chain\plugin_body 



@update_tail
