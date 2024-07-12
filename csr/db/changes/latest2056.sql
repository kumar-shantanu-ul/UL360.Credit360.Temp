-- Please update version.sql too -- this keeps clean builds in sync
define version=2056
@update_header

CREATE TABLE CSRIMP.CHAIN_CUSTOMER_OPTIONS (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ADD_CSR_USER_TO_TOP_COMP NUMBER(1,0) NOT NULL,
	ADMIN_HAS_DEV_ACCESS NUMBER(1,0) NOT NULL,
	ALLOW_ADD_EXISTING_CONTACTS NUMBER(1,0) NOT NULL,
	ALLOW_CC_ON_INVITE NUMBER(1,0) NOT NULL,
	ALLOW_COMPANY_SELF_REG NUMBER(1,0) NOT NULL,
	ALLOW_NEW_USER_REQUEST NUMBER(1,0) NOT NULL,
	CHAIN_IS_VISIBLE_TO_TOP NUMBER(1,0) NOT NULL,
	COMPANY_USER_CREATE_ALERT NUMBER(1,0) NOT NULL,
	COUNTRIES_HELPER_SP VARCHAR2(100),
	DASHBOARD_TASK_SCHEME_ID NUMBER(10,0),
	DEFAULT_AUTO_APPROVE_USERS NUMBER(1,0) NOT NULL,
	DEFAULT_QNR_INVITATION_WIZ NUMBER(1,0) NOT NULL,
	DEFAULT_RECEIVE_SCHED_ALERTS NUMBER(1,0) NOT NULL,
	DEFAULT_SHARE_QNR_WITH_ON_BHLF NUMBER(1,0) NOT NULL,
	DEFAULT_URL VARCHAR2(4000),
	ENABLE_QNNAIRE_REMINDER_ALERTS NUMBER(1,0) NOT NULL,
	INVITATION_EXPIRATION_DAYS NUMBER(10,0) NOT NULL,
	INVITE_FROM_NAME_ADDENDUM VARCHAR2(4000),
	INV_MGR_NORM_USER_FULL_ACCESS NUMBER(1,0) NOT NULL,
	LANDING_URL VARCHAR2(1000),
	LAST_GENERATE_ALERT_DTM TIMESTAMP(6) NOT NULL,
	LINK_HOST VARCHAR2(100),
	LOGIN_PAGE_MESSAGE VARCHAR2(4000),
	NEWSFLASH_SUMMARY_SP VARCHAR2(100),
	OVERRIDE_SEND_QI_PATH VARCHAR2(2000),
	PRODUCT_URL VARCHAR2(4000),
	PRODUCT_URL_READ_ONLY VARCHAR2(4000),
	PURCHASED_COMP_AUTO_MAP NUMBER(1,0) NOT NULL,
	QUESTIONNAIRE_FILTER_CLASS VARCHAR2(100),
	REGISTRATION_TERMS_URL VARCHAR2(4000),
	REGISTRATION_TERMS_VERSION NUMBER(10,5),
	REQ_QNNAIRE_INVITATION_LANDING VARCHAR2(1000),
	RESTRICT_CHANGE_EMAIL_DOMAINS NUMBER(1,0) NOT NULL,
	SCHEDULED_ALERT_INTVL_MINUTES NUMBER(10,0) NOT NULL,
	SCHED_ALERTS_ENABLED NUMBER(1,0) NOT NULL,
	SEND_CHANGE_EMAIL_ALERT NUMBER(1,0) NOT NULL,
	SITE_NAME VARCHAR2(200),
	SUPPORT_EMAIL VARCHAR2(255),
	TASK_MANAGER_HELPER_TYPE VARCHAR2(1000),
	TOP_COMPANY_SID NUMBER(10,0),
	USE_COMPANY_TYPE_CSS_CLASS NUMBER(1,0) NOT NULL,
	USE_COMPANY_TYPE_USER_GROUPS NUMBER(1,0) NOT NULL,
	USE_TYPE_CAPABILITIES NUMBER(1,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CUSTOMER_OPTIONS PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_CHAIN_CUSTOMER_OPTIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_COMPANY_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	ALLOW_LOWER_CASE NUMBER(1,0) NOT NULL,
	CSS_CLASS VARCHAR2(255),
	IS_DEFAULT NUMBER(1,0) NOT NULL,
	IS_TOP_COMPANY NUMBER(1,0) NOT NULL,
	LOOKUP_KEY VARCHAR2(100) NOT NULL,
	PLURAL VARCHAR2(100) NOT NULL,
	POSITION NUMBER(10,0) NOT NULL,
	SINGULAR VARCHAR2(100) NOT NULL,
	USER_GROUP_SID NUMBER(10,0),
	USER_ROLE_SID NUMBER(10,0),
	USE_USER_ROLE NUMBER(1,0) NOT NULL,
	CONSTRAINT PK_CHAIN_COMPANY_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_COMPANY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_COMPANY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	ACTIVATED_DTM DATE,
	ACTIVE NUMBER(1,0) NOT NULL,
	ADDRESS_1 VARCHAR2(255),
	ADDRESS_2 VARCHAR2(255),
	ADDRESS_3 VARCHAR2(255),
	ADDRESS_4 VARCHAR2(255),
	ALLOW_STUB_REGISTRATION NUMBER(1,0) NOT NULL,
	APPROVE_STUB_REGISTRATION NUMBER(1,0) NOT NULL,
	AUTO_APPROVE_USERS NUMBER(1,0) NOT NULL,
	CAN_SEE_ALL_COMPANIES NUMBER(1,0) NOT NULL,
	COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	COUNTRY_CODE VARCHAR2(2) NOT NULL,
	CREATED_DTM DATE,
	DELETED NUMBER(1,0) NOT NULL,
	DETAILS_CONFIRMED NUMBER(1,0) NOT NULL,
	FAX VARCHAR2(255),
	MAPPING_APPROVAL_REQUIRED NUMBER(1,0) NOT NULL,
	NAME VARCHAR2(255) NOT NULL,
	PHONE VARCHAR2(255),
	POSTCODE VARCHAR2(255),
	SECTOR_ID NUMBER(10,0),
	STATE VARCHAR2(255),
	STUB_REGISTRATION_GUID VARCHAR2(38),
	SUPP_REL_CODE_LABEL VARCHAR2(100),
	SUPP_REL_CODE_LABEL_MAND NUMBER(10,0) NOT NULL,
	TOWN VARCHAR2(255),
	USER_LEVEL_MESSAGING NUMBER(10,0) NOT NULL,
	WEBSITE VARCHAR2(1000),
	XXX_REFERENCE_ID_1 VARCHAR2(50),
	XXX_REFERENCE_ID_2 VARCHAR2(50),
	XXX_REFERENCE_ID_3 VARCHAR2(50),
	CONSTRAINT PK_CHAIN_COMPANY PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID),
	CONSTRAINT FK_CHAIN_COMPANY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SUPPLIER_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SUPPLIER_SCORE_ID NUMBER(10,0) NOT NULL,
	SCORE NUMBER(15,5),
	SCORE_THRESHOLD_ID NUMBER(10,0),
	SET_DTM DATE NOT NULL,
	SUPPLIER_SID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_SUPPLIER_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, SUPPLIER_SCORE_ID),
	CONSTRAINT FK_SUPPLIER_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.SUPPLIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	LAST_SUPPLIER_SCORE_ID NUMBER(10,0),
	LOGO_FILE_SID NUMBER(10,0),
	RECIPIENT_SID NUMBER(10,0),
	REGION_SID NUMBER(10,0),
	CONSTRAINT PK_SUPPLIER PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID),
	CONSTRAINT FK_SUPPLIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_APPLI_COMPA_CAPABI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	GROUP_CAPABILITY_ID NUMBER(10,0) NOT NULL,
	PERMISSION_SET NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_APPLI_COMPA_CAPABI PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID, GROUP_CAPABILITY_ID, PERMISSION_SET),
	CONSTRAINT FK_CHAIN_APPLI_COMPA_CAPABI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_CHAIN_USER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	USER_SID NUMBER(10,0) NOT NULL,
	DEFAULT_COMPANY_SID NUMBER(10,0),
	DEFAULT_CSS_PATH VARCHAR2(200),
	DEFAULT_HOME_PAGE VARCHAR2(200),
	DEFAULT_STYLESHEET VARCHAR2(200),
	DELETED NUMBER(1,0) NOT NULL,
	DETAILS_CONFIRMED NUMBER(1,0) NOT NULL,
	MERGED_TO_USER_SID NUMBER(10,0),
	NEXT_SCHEDULED_ALERT_DTM TIMESTAMP(6) NOT NULL,
	RECEIVE_SCHEDULED_ALERTS NUMBER(1,0) NOT NULL,
	REGISTRATION_STATUS_ID NUMBER(10,0) NOT NULL,
	SCHEDULED_ALERT_TIME TIMESTAMP(6) NOT NULL,
	TMP_IS_CHAIN_USER NUMBER(1,0) NOT NULL,
	VISIBILITY_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_CHAIN_USER PRIMARY KEY (CSRIMP_SESSION_ID, USER_SID),
	CONSTRAINT FK_CHAIN_CHAIN_USER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_COMPANY_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPANY_SID NUMBER(10,0) NOT NULL,
	COMPANY_GROUP_TYPE_ID NUMBER(10,0) NOT NULL,
	GROUP_SID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_COMPANY_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_SID, COMPANY_GROUP_TYPE_ID),
	CONSTRAINT FK_CHAIN_COMPANY_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_COMPAN_TYPE_RELATI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRIMARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SECONDARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	USE_USER_ROLES NUMBER(1,0) NOT NULL,
	CONSTRAINT PK_CHAIN_COMPAN_TYPE_RELATI PRIMARY KEY (CSRIMP_SESSION_ID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_COMPAN_TYPE_RELATI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_COMPAN_TYPE_CAPABI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CAPABILITY_ID NUMBER(10,0) NOT NULL,
	PERMISSION_SET NUMBER(10,0) NOT NULL,
	PRIMARY_COMPANY_GROUP_TYPE_ID NUMBER(10,0) NOT NULL,
	PRIMARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SECONDARY_COMPANY_TYPE_ID NUMBER(10,0),
	TERTIARY_COMPANY_TYPE_ID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_COMPAN_TYPE_CAPABI PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_CHAIN_COMPAN_TYPE_CAPABI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_GROUP_CAPAB_OVERRI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	GROUP_CAPABILITY_ID NUMBER(10,0) NOT NULL,
	HIDE_GROUP_CAPABILITY NUMBER(1,0) NOT NULL,
	PERMISSION_SET_OVERRIDE NUMBER(10,0),
	CONSTRAINT PK_CHAIN_GROUP_CAPAB_OVERRI PRIMARY KEY (CSRIMP_SESSION_ID, GROUP_CAPABILITY_ID),
	CONSTRAINT FK_CHAIN_GROUP_CAPAB_OVERRI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_IMPLEMENTATION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	EXECUTE_ORDER NUMBER(10,0) NOT NULL,
	LINK_PKG VARCHAR2(100),
	NAME VARCHAR2(100) NOT NULL,
	CONSTRAINT PK_CHAIN_IMPLEMENTATION PRIMARY KEY (CSRIMP_SESSION_ID),
	CONSTRAINT FK_CHAIN_IMPLEMENTATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_SECTOR (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	SECTOR_ID NUMBER(10,0) NOT NULL,
	ACTIVE NUMBER(1,0) NOT NULL,
	DESCRIPTION VARCHAR2(255),
	IS_OTHER NUMBER(1,0) NOT NULL,
	PARENT_SECTOR_ID NUMBER(10,0),
	CONSTRAINT PK_CHAIN_SECTOR PRIMARY KEY (CSRIMP_SESSION_ID, SECTOR_ID),
	CONSTRAINT FK_CHAIN_SECTOR_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.CHAIN_TERTIARY_RELATIONS (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PRIMARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	SECONDARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	TERTIARY_COMPANY_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_CHAIN_TERTIARY_RELATIONS PRIMARY KEY (CSRIMP_SESSION_ID, PRIMARY_COMPANY_TYPE_ID, SECONDARY_COMPANY_TYPE_ID, TERTIARY_COMPANY_TYPE_ID),
	CONSTRAINT FK_CHAIN_TERTIARY_RELATIONS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Map tables
CREATE TABLE CSRIMP.MAP_SUPPLIER_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUPPLIER_SCORE_ID NUMBER(10) NOT NULL,
	NEW_SUPPLIER_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SUPPLIER_SCORE PRIMARY KEY (OLD_SUPPLIER_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_SUPPLIER_SCORE UNIQUE (NEW_SUPPLIER_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_SUPPLIER_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_GROUP_CAPABILI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_GROUP_CAPABILITY_ID NUMBER(10) NOT NULL,
	NEW_GROUP_CAPABILITY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_GROUP_CAPABILI PRIMARY KEY (OLD_GROUP_CAPABILITY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_GROUP_CAPABILI UNIQUE (NEW_GROUP_CAPABILITY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_GROUP_CAPABILI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPANY_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPANY_TYPE PRIMARY KEY (OLD_COMPANY_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPANY_TYPE UNIQUE (NEW_COMPANY_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPANY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Package grants
grant select, insert, update, delete on csrimp.chain_customer_options to web_user;
grant select, insert, update, delete on csrimp.chain_company_type to web_user;
grant select, insert, update, delete on csrimp.chain_company to web_user;
grant select, insert, update, delete on csrimp.supplier_score to web_user;
grant select, insert, update, delete on csrimp.supplier to web_user;
grant select, insert, update, delete on csrimp.chain_appli_compa_capabi to web_user;
grant select, insert, update, delete on csrimp.chain_chain_user to web_user;
grant select, insert, update, delete on csrimp.chain_company_group to web_user;
grant select, insert, update, delete on csrimp.chain_compan_type_relati to web_user;
grant select, insert, update, delete on csrimp.chain_compan_type_capabi to web_user;
grant select, insert, update, delete on csrimp.chain_group_capab_overri to web_user;
grant select, insert, update, delete on csrimp.chain_implementation to web_user;
grant select, insert, update, delete on csrimp.chain_sector to web_user;
grant select, insert, update, delete on csrimp.chain_tertiary_relations to web_user;

-- Object grants
grant select, insert, update on chain.customer_options to csrimp;
grant select, insert, update on chain.customer_options to CSR;
grant select, insert, update on chain.company_type to csrimp;
grant select, insert, update on chain.company_type to CSR;
grant select, insert, update on chain.company to csrimp;
grant select, insert, update on chain.company to CSR;
grant select, insert, update on csr.supplier_score to csrimp;
grant select, insert, update on csr.supplier to csrimp;
grant select, insert, update on chain.applied_company_capability to csrimp;
grant select, insert, update on chain.applied_company_capability to CSR;
grant select, insert, update on chain.chain_user to csrimp;
grant select, insert, update on chain.chain_user to CSR;
grant select, insert, update on chain.company_group to csrimp;
grant select, insert, update on chain.company_group to CSR;
grant select, insert, update on chain.company_type_relationship to csrimp;
grant select, insert, update on chain.company_type_relationship to CSR;
grant select, insert, update on chain.company_type_capability to csrimp;
grant select, insert, update on chain.company_type_capability to CSR;
grant select, insert, update on chain.group_capability_override to csrimp;
grant select, insert, update on chain.group_capability_override to CSR;
grant select, insert, update on chain.implementation to csrimp;
grant select, insert, update on chain.implementation to CSR;
grant select, insert, update on chain.sector to csrimp;
grant select, insert, update on chain.sector to CSR;
grant select, insert, update on chain.tertiary_relationships to csrimp;
grant select, insert, update on chain.tertiary_relationships to CSR;

grant select on csr.supplier_score_id_seq to csrimp;
grant select on chain.group_capability_id_seq to csrimp;
grant select on chain.group_capability_id_seq to CSR;
grant select on chain.company_type_id_seq to csrimp;
grant select on chain.company_type_id_seq to CSR;

@@../schema_pkg
@@../schema_body

@@../csrimp/rls

@@../csrimp/imp_pkg
@@../csrimp/imp_body

@update_tail
