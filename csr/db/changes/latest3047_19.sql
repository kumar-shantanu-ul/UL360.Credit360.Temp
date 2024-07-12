-- Please update version.sql too -- this keeps clean builds in sync
define version=3047
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_permit_type (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	permit_type_id					NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_compliance_permit_type
		PRIMARY KEY (app_sid, permit_type_id)
);

CREATE SEQUENCE csr.compliance_permit_type_seq;

CREATE TABLE csr.compliance_permit_sub_type (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	permit_type_id					NUMBER(10,0) NOT NULL,
	permit_sub_type_id				NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_compliance_permit_sub_type
		PRIMARY KEY (app_sid, permit_type_id, permit_sub_type_id),
	CONSTRAINT fk_permit_sub_type
		FOREIGN KEY (app_sid, permit_type_id)
		REFERENCES csr.compliance_permit_type (app_sid, permit_type_id)
);

CREATE SEQUENCE csr.compliance_permit_sub_type_seq;

CREATE TABLE csr.compliance_condition_type (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	condition_type_id				NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_compliance_condition_type
		PRIMARY KEY (app_sid, condition_type_id)
);

CREATE SEQUENCE csr.compliance_condition_type_seq;

CREATE TABLE csr.compliance_condition_sub_type (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	condition_type_id				NUMBER(10,0) NOT NULL,
	condition_sub_type_id			NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_condition_sub_type
		PRIMARY KEY (app_sid, condition_type_id, condition_sub_type_id),
	CONSTRAINT fk_condition_sub_type
		FOREIGN KEY (app_sid, condition_type_id)
		REFERENCES csr.compliance_condition_type (app_sid, condition_type_id)
);

CREATE SEQUENCE csr.compliance_cond_sub_type_seq;

CREATE TABLE csr.compliance_activity_type (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	activity_type_id				NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_compliance_activity_type
		PRIMARY KEY (app_sid, activity_type_id)
);

CREATE SEQUENCE csr.compliance_activity_type_seq;

CREATE TABLE csr.compliance_application_type (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	application_type_id				NUMBER(10,0) NOT NULL,
	description						VARCHAR2(1024) NOT NULL,
	CONSTRAINT pk_compliance_application_type
		PRIMARY KEY (app_sid, application_type_id)
);

CREATE SEQUENCE csr.compliance_application_tp_seq;

CREATE TABLE csr.compliance_permit (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_permit_id			NUMBER(10,0) NOT NULL,
	region_sid						NUMBER(10,0) NOT NULL,
	flow_item_id					NUMBER(10,0) NOT NULL,
	title							VARCHAR2(1024) NOT NULL,
	details							CLOB,
	permit_reference				VARCHAR2(255),
	activity_start_dtm				DATE,
	activity_end_dtm				DATE,
	permit_type_id					NUMBER(10,0) NOT NULL,
	permit_sub_type_id				NUMBER(10,0) NOT NULL,
	permit_start_dtm				DATE,
	permit_end_dtm					DATE,
	activity_type_id				NUMBER(10,0) NOT NULL,
    CONSTRAINT pk_compliance_permit
		PRIMARY KEY (app_sid, compliance_permit_id),
	CONSTRAINT fk_compliance_permit_region
		FOREIGN KEY (app_sid, region_sid) 
		REFERENCES csr.region (app_sid, region_sid),
	CONSTRAINT fk_compliance_permit_type
		FOREIGN KEY (app_sid, permit_type_id)
		REFERENCES csr.compliance_permit_type (app_sid, permit_type_id),
	CONSTRAINT fk_compliance_permit_sub_type
		FOREIGN KEY (app_sid, permit_type_id, permit_sub_type_id)
		REFERENCES csr.compliance_permit_sub_type (app_sid, permit_type_id, permit_sub_type_id),
	CONSTRAINT fk_compliance_activity_type
		FOREIGN KEY (app_sid, activity_type_id)
		REFERENCES csr.compliance_activity_type (app_sid, activity_type_id)
);

CREATE UNIQUE INDEX csr.uk_cp_permit_reference ON csr.compliance_permit 
	(app_sid, NVL(LOWER(permit_reference), compliance_permit_id));

CREATE INDEX csr.ix_compliance_permit_region 
	ON csr.compliance_permit (app_sid, region_sid);

CREATE INDEX csr.ix_compliance_permit_type 
	ON csr.compliance_permit (app_sid, permit_type_id, permit_sub_type_id);

CREATE INDEX csr.ix_compliance_activity_type 
	ON csr.compliance_permit (app_sid, activity_type_id);

CREATE SEQUENCE csr.compliance_permit_seq;

CREATE TABLE csr.compliance_permit_application  (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	permit_application_id			NUMBER(10,0) NOT NULL,
	permit_id						NUMBER(10,0) NOT NULL,
	notes							CLOB,
	application_reference			VARCHAR2(255),
	application_type_id				NUMBER(10) NOT NULL,
	submission_dtm					DATE,
	duly_made_dtm					DATE,
	determined_dtm					DATE,
	CONSTRAINT pk_compliance_permit_applicati
		PRIMARY KEY (app_sid, permit_application_id),
	CONSTRAINT fk_cpa_cp
		FOREIGN KEY (app_sid, permit_id)
		REFERENCES csr.compliance_permit (app_sid, compliance_permit_id)
);

CREATE SEQUENCE csr.compliance_permit_appl_seq;

CREATE UNIQUE INDEX csr.uk_cp_permit_app_reference ON csr.compliance_permit_application 
	(app_sid, NVL(LOWER(application_reference), permit_application_id));

CREATE INDEX csr.ix_cpa_cpat
    ON csr.compliance_permit_application (app_sid, application_type_id); 

CREATE INDEX csr.ix_cpa_permit
    ON csr.compliance_permit_application (app_sid, permit_id, permit_application_id);

CREATE TABLE csr.compliance_permit_condition (
	app_sid							NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	compliance_permit_id			NUMBER(10,0) NOT NULL,
	condition_type_id				NUMBER(10,0) NOT NULL,
	condition_sub_type_id			NUMBER(10,0) NOT NULL,
    CONSTRAINT pk_compliance_permit_condition
		PRIMARY KEY (app_sid, compliance_item_id),
	CONSTRAINT fk_compliance_permit_cond
		FOREIGN KEY (app_sid, compliance_item_id) 
		REFERENCES csr.compliance_item (app_sid, compliance_item_id),
	CONSTRAINT fk_cpc_cp
		FOREIGN KEY (app_sid, compliance_permit_id) 
		REFERENCES csr.compliance_permit (app_sid, compliance_permit_id),
	CONSTRAINT fk_compliance_permit_cond_type
		FOREIGN KEY (app_sid, condition_type_id)
		REFERENCES csr.compliance_condition_type (app_sid, condition_type_id),
	CONSTRAINT fk_cpc_cct
		FOREIGN KEY (app_sid, condition_type_id, condition_sub_type_id)
		REFERENCES csr.compliance_condition_sub_type (app_sid, condition_type_id, condition_sub_type_id)
);

CREATE INDEX csr.ix_compliance_permit_cond_type
	ON csr.compliance_permit_condition (app_sid, condition_type_id, condition_sub_type_id);

CREATE INDEX csr.ix_compliance_pe_compliance_pe 
	ON csr.compliance_permit_condition (app_sid, compliance_permit_id);

CREATE TABLE csr.compliance_item_rollout (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_id				NUMBER(10,0) NOT NULL,
	country							VARCHAR2(2),
	region							VARCHAR2(2),
	country_group					VARCHAR2(3),
	region_group					VARCHAR2(3),
	rollout_dtm						DATE,
	rollout_pending					NUMBER(1) DEFAULT 0 NOT NULL,
    CONSTRAINT pk_compliance_item_rollout PRIMARY KEY (app_sid, compliance_item_id),
	CONSTRAINT fk_compliance_item_rollout
		FOREIGN KEY (app_sid, compliance_item_id) 
		REFERENCES csr.compliance_item (app_sid, compliance_item_id),
	CONSTRAINT fk_cir_sn
		FOREIGN KEY (country_group)
		REFERENCES csr.country_group(country_group_id),
	CONSTRAINT fk_cir_rg
		FOREIGN KEY (region_group)
		REFERENCES csr.region_group (region_group_id),
	CONSTRAINT fk_cir_pcr
		FOREIGN KEY (country, region)
		REFERENCES postcode.region (country, region),
	CONSTRAINT fk_cir_pcc
		FOREIGN KEY (country)
		REFERENCES postcode.country (country)
);

CREATE INDEX csr.ix_compliance_rollout_pcr ON csr.compliance_item_rollout (country, region);
CREATE INDEX csr.ix_compliance_rollout_cg ON csr.compliance_item_rollout (country_group);
CREATE INDEX csr.ix_compliance_rollout_rg ON csr.compliance_item_rollout (region_group);

-- CSRIMP
CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERMIT_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_PERMIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, PERMIT_TYPE_ID),
	CONSTRAINT FK_COMPLIANCE_PERMIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_CONDITION_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CONDITION_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_CONDITION_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, CONDITION_TYPE_ID),
	CONSTRAINT FK_COMPLIANC_CONDITION_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_ACTIVITY_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ACTIVITY_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_ACTIVITY_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, ACTIVITY_TYPE_ID),
	CONSTRAINT FK_COMPLIANCE_ACTIVITY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_APPLICATION_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	APPLICATION_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_APPLICATION_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, APPLICATION_TYPE_ID),
	CONSTRAINT FK_COMPLIANC_APPLICATI_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_PERMIT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_PERMIT_ID NUMBER(10,0) NOT NULL,
	ACTIVITY_END_DTM DATE,
	ACTIVITY_START_DTM DATE,
	ACTIVITY_TYPE_ID NUMBER(10,0) NOT NULL,
	DETAILS CLOB,
	FLOW_ITEM_ID NUMBER(10,0) NOT NULL,
	PERMIT_END_DTM DATE,
	PERMIT_REFERENCE VARCHAR2(255),
	PERMIT_START_DTM DATE,
	PERMIT_SUB_TYPE_ID NUMBER(10,0) NOT NULL,
	PERMIT_TYPE_ID NUMBER(10,0) NOT NULL,
	REGION_SID NUMBER(10,0) NOT NULL,
	TITLE VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_PERMIT PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_PERMIT_ID),
	CONSTRAINT FK_COMPLIANCE_PERMIT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_ITEM_ROLLOUT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_ITEM_ID NUMBER(10,0) NOT NULL,
	COUNTRY VARCHAR2(2),
	COUNTRY_GROUP VARCHAR2(3),
	REGION VARCHAR2(2),
	REGION_GROUP VARCHAR2(3),
	ROLLOUT_DTM DATE,
	ROLLOUT_PENDING NUMBER(1,0) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_ITEM_ROLLOUT PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_ITEM_ID),
	CONSTRAINT FK_COMPLIANCE_ITEM_ROLLOUT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERMIT_TYPE_ID NUMBER(10,0) NOT NULL,
	PERMIT_SUB_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_PERMIT_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, PERMIT_TYPE_ID, PERMIT_SUB_TYPE_ID),
	CONSTRAINT FK_COMPLIAN_PERMIT_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_CONDITION_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	CONDITION_TYPE_ID NUMBER(10,0) NOT NULL,
	CONDITION_SUB_TYPE_ID NUMBER(10,0) NOT NULL,
	DESCRIPTION VARCHAR2(1024) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_CONDITION_SB_TYP PRIMARY KEY (CSRIMP_SESSION_ID, CONDITION_TYPE_ID, CONDITION_SUB_TYPE_ID),
	CONSTRAINT FK_COMPLIA_CONDITI_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_APPLICATION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	PERMIT_APPLICATION_ID NUMBER(10,0) NOT NULL,
	APPLICATION_REFERENCE VARCHAR2(255),
	APPLICATION_TYPE_ID NUMBER(10,0) NOT NULL,
	DETERMINED_DTM DATE,
	DULY_MADE_DTM DATE,
	NOTES CLOB,
	PERMIT_ID NUMBER(10,0) NOT NULL,
	SUBMISSION_DTM DATE,
	CONSTRAINT PK_COMPLIANCE_PERMIT_APPL PRIMARY KEY (CSRIMP_SESSION_ID, PERMIT_APPLICATION_ID),
	CONSTRAINT FK_COMPLIAN_PERMIT_APPLICAT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.COMPLIANCE_PERMIT_CONDITION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	COMPLIANCE_ITEM_ID NUMBER(10,0) NOT NULL,
	COMPLIANCE_PERMIT_ID NUMBER(10,0) NOT NULL,
	CONDITION_SUB_TYPE_ID NUMBER(10,0) NOT NULL,
	CONDITION_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_COMPLIANCE_PERMIT_CONDITION PRIMARY KEY (CSRIMP_SESSION_ID, COMPLIANCE_ITEM_ID),
	CONSTRAINT FK_COMPLIAN_PERMIT_CONDITIO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Map tables
CREATE TABLE CSRIMP.MAP_COMPLIAN_PERMIT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_PERMIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_PERMIT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_PERMIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIA_CONDITI_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIA_CONDITI_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIA_CONDITI_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIA_CONDITI_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIA_ACTIVIT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANC_ACTIVITY_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANC_ACTIVITY_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIA_ACTIVIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIA_ACTIVIT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIA_ACTIVIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIAN_APPLICAT_TP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANC_APPLICATIO_TP_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANC_APPLICATIO_TP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_APPLICAT_TP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_APPLICATIO_TP_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_APPLICAT_TP UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_APPLICATIO_TP_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_APPLICAT_TP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIANCE_PERMIT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIANCE_PERMIT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIANCE_PERMIT UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIANCE_PERMIT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPL_PERMI_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIA_PERMIT_SUB_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIA_PERMIT_SUB_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPL_PERMI_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIANCE_CONDITION_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_CONDITION_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_CONDITION_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_CONDIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIAN_PERMIT_APPL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_APPL_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_APPL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_PERMIT_APPL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_APPL_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_PERMIT_APPL UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_APPL_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_PERMIT_APPL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIA_CONDITION_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMP_CONDITION_SUB_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMP_CONDITION_SUB_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMP_CONDITION_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMP_CONDITION_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMP_CONDIT_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables
INSERT INTO csr.compliance_item_rollout (app_sid, compliance_item_id, country, region,
										 country_group, region_group, rollout_dtm, rollout_pending)
	SELECT app_sid, compliance_item_id, country, region, 
		   country_group, region_group, rollout_dtm, rollout_pending
	  FROM csr.compliance_item;

ALTER TABLE csr.compliance_item DROP CONSTRAINT fk_ci_sn;
ALTER TABLE csr.compliance_item DROP CONSTRAINT fk_ci_pcr;
ALTER TABLE csr.compliance_item DROP CONSTRAINT fk_ci_pcc;

-- Named differently on live vs create_schema
DECLARE 
	nonexistent_constraint EXCEPTION;
	PRAGMA EXCEPTION_INIT(nonexistent_constraint, -2443);
BEGIN
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.compliance_item DROP CONSTRAINT fk_ci_rg';
	EXCEPTION
		WHEN nonexistent_constraint THEN NULL;
	END;
	BEGIN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.compliance_item DROP CONSTRAINT fk_ci_reg_grp';
	EXCEPTION
		WHEN nonexistent_constraint THEN NULL;
	END;
END;
/

DROP INDEX csr.ix_compliance_item_pcr;
DROP INDEX csr.ix_compliance_item_cg;

ALTER TABLE csr.compliance_item DROP (
	country,
	region,
	country_group,
	region_group,
	rollout_dtm,
	rollout_pending	
);

ALTER TABLE csrimp.compliance_item DROP (
	country,
	region,
	country_group,
	region_group,
	rollout_dtm,
	rollout_pending	
);

-- *** Grants ***
-- Package grants
grant select, insert, update, delete on csrimp.compliance_activity_type to tool_user;
grant select, insert, update, delete on csrimp.compliance_application_type to tool_user;
grant select, insert, update, delete on csrimp.compliance_condition_sub_type to tool_user;
grant select, insert, update, delete on csrimp.compliance_condition_type to tool_user;
grant select, insert, update, delete on csrimp.compliance_item_rollout to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_application to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_condition to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_sub_type to tool_user;
grant select, insert, update, delete on csrimp.compliance_permit_type to tool_user;

-- Object grants
grant select, insert, update on csr.compliance_activity_type to csrimp;
grant select, insert, update on csr.compliance_application_type to csrimp;
grant select, insert, update on csr.compliance_condition_sub_type to csrimp;
grant select, insert, update on csr.compliance_condition_type to csrimp;
grant select, insert, update on csr.compliance_item_rollout to csrimp;
grant select, insert, update on csr.compliance_permit to csrimp;
grant select, insert, update on csr.compliance_permit_application to csrimp;
grant select, insert, update on csr.compliance_permit_condition to csrimp;
grant select, insert, update on csr.compliance_permit_sub_type to csrimp;
grant select, insert, update on csr.compliance_permit_type to csrimp;

grant select on csr.compliance_activity_type_seq to csrimp;
grant select on csr.compliance_application_tp_seq to csrimp;
grant select on csr.compliance_cond_sub_type_seq to csrimp;
grant select on csr.compliance_condition_type_seq to csrimp;
grant select on csr.compliance_permit_appl_seq to csrimp;
grant select on csr.compliance_permit_seq to csrimp;
grant select on csr.compliance_permit_sub_type_seq to csrimp;
grant select on csr.compliance_permit_type_seq to csrimp;
grant select on csr.compliance_permit_type_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../compliance_pkg
@../csr_app_body
@../csrimp/imp_body
@../schema_body
@../compliance_body
@../compliance_library_report_body
@../compliance_register_report_body
@../region_body

@update_tail
