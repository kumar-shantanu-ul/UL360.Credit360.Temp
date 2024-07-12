-- Please update version.sql too -- this keeps clean builds in sync
define version=2888
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables
--
CREATE TABLE CHAIN.COMPANY_TYPE_TAG_GROUP(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	COMPANY_TYPE_ID		NUMBER(10, 0)	NOT NULL,
	TAG_GROUP_ID		NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_COMPANY_TYPE_TAG_GROUP PRIMARY KEY (APP_SID, COMPANY_TYPE_ID, TAG_GROUP_ID)
);
	
CREATE TABLE CSR.INTERNAL_AUDIT_TYPE_TAG_GROUP(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	INTERNAL_AUDIT_TYPE_ID	NUMBER(10, 0)	NOT NULL,
	TAG_GROUP_ID			NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_INTERNAL_AUDIT_TYPE_TAG_GR PRIMARY KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID, TAG_GROUP_ID)
);
	
CREATE TABLE CSR.INTERNAL_AUDIT_TAG(
	APP_SID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	INTERNAL_AUDIT_SID	NUMBER(10, 0)	NOT NULL,
	TAG_ID				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_INTERNAL_AUDIT_TAG PRIMARY KEY (APP_SID, INTERNAL_AUDIT_SID, TAG_ID)
);

CREATE TABLE CSR.NON_COMPLIANCE_TYPE_TAG_GROUP(
	APP_SID					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	NON_COMPLIANCE_TYPE_ID	NUMBER(10, 0)	NOT NULL,
	TAG_GROUP_ID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_NON_COMPLIANCE_TYPE_TAG_GR PRIMARY KEY (APP_SID, NON_COMPLIANCE_TYPE_ID, TAG_GROUP_ID)
);

	
/* csrimp */
CREATE TABLE csrimp.chain_company_type_tag_group(
	csrimp_session_id	NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	company_type_id		NUMBER(10, 0)	NOT NULL,
	tag_group_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_COMPANY_TYPE_TAG_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, TAG_GROUP_ID)
);

CREATE TABLE csrimp.internal_audit_type_tag_group(
	csrimp_session_id	NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	internal_audit_type_id	NUMBER(10, 0)	NOT NULL,
	tag_group_id			NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_INTERNAL_AUDIT_TYPE_TAG_GR PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_TYPE_ID, TAG_GROUP_ID)
);
	
CREATE TABLE csrimp.internal_audit_tag(
	csrimp_session_id	NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	internal_audit_sid	NUMBER(10, 0)	NOT NULL,
	tag_id				NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_INTERNAL_AUDIT_TAG PRIMARY KEY (CSRIMP_SESSION_ID, INTERNAL_AUDIT_SID, TAG_ID)
);

CREATE TABLE csrimp.non_compliance_type_tag_group(
	csrimp_session_id		NUMBER(10,0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	non_compliance_type_id	NUMBER(10, 0)	NOT NULL,
	tag_group_id			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_NON_COMPLIANCE_TYPE_TAG_GR PRIMARY KEY (csrimp_session_id, non_compliance_type_id, tag_group_id)
);


-- Alter tables
ALTER TABLE CHAIN.COMPANY_TYPE_TAG_GROUP ADD CONSTRAINT FK_COMP_TYPE_TAG_GR_COMP_TYPE
	FOREIGN KEY (APP_SID, COMPANY_TYPE_ID)
	REFERENCES CHAIN.COMPANY_TYPE(APP_SID, COMPANY_TYPE_ID);	

ALTER TABLE CSR.INTERNAL_AUDIT_TYPE_TAG_GROUP ADD CONSTRAINT FK_INT_AUDIT_TYPE_TAG_GR_AU_TY
	FOREIGN KEY (APP_SID, INTERNAL_AUDIT_TYPE_ID)
	REFERENCES CSR.INTERNAL_AUDIT_TYPE(APP_SID, INTERNAL_AUDIT_TYPE_ID);
	
ALTER TABLE CSR.INTERNAL_AUDIT_TYPE_TAG_GROUP ADD CONSTRAINT FK_INT_AUDIT_TYP_TAG_GR_TAG_GR
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID);
	
ALTER TABLE CSR.INTERNAL_AUDIT_TAG ADD CONSTRAINT FK_INT_AUDIT_TAG_IA
	FOREIGN KEY (APP_SID, INTERNAL_AUDIT_SID)
	REFERENCES CSR.INTERNAL_AUDIT(APP_SID, INTERNAL_AUDIT_SID);
	
ALTER TABLE CSR.INTERNAL_AUDIT_TAG ADD CONSTRAINT FK_INT_AUDIT_TAG_TAG
	FOREIGN KEY (APP_SID, TAG_ID)
	REFERENCES CSR.TAG(APP_SID, TAG_ID);

ALTER TABLE CSR.non_compliance_type_tag_group ADD CONSTRAINT FK_NON_COMPL_TYPE_TAG_GR_NON_C
	FOREIGN KEY (APP_SID, NON_COMPLIANCE_TYPE_ID)
	REFERENCES CSR.NON_COMPLIANCE_TYPE(APP_SID, NON_COMPLIANCE_TYPE_ID);
	
ALTER TABLE CSR.non_compliance_type_tag_group ADD CONSTRAINT FK_NON_COMPL_TYP_TAG_GR_TAG_GR
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID);
	
ALTER TABLE CSR.TAG_GROUP ADD APPLIES_TO_AUDITS NUMBER(1,0) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.TAG_GROUP ADD APPLIES_TO_AUDITS NUMBER(1,0);




ALTER TABLE csrimp.chain_company_type_tag_group ADD CONSTRAINT fk_chain_company_type_tag_gr 
	FOREIGN KEY (csrimp_session_id) 
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

ALTER TABLE csrimp.internal_audit_type_tag_group ADD CONSTRAINT fk_internal_audit_type_tag_gr 
	FOREIGN KEY (csrimp_session_id) 
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
	
ALTER TABLE csrimp.internal_audit_tag ADD CONSTRAINT fk_internal_audit_tag
	FOREIGN KEY (csrimp_session_id) 
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
	
ALTER TABLE csrimp.non_compliance_type_tag_group ADD CONSTRAINT fk_non_compliance_type_tag_gr
	FOREIGN KEY (csrimp_session_id) 
	REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
	
-- *** Grants ***
GRANT ALL ON CHAIN.COMPANY_TYPE_TAG_GROUP TO CSR;
grant insert on csr.non_compliance_type_tag_group to csrimp;
grant insert on csr.internal_audit_type_tag_group to csrimp;
grant insert on csr.internal_audit_tag to csrimp;
grant select, insert, update on chain.company_type_tag_group to csrimp;

-- ** Cross schema constraints ***
ALTER TABLE CHAIN.COMPANY_TYPE_TAG_GROUP ADD CONSTRAINT FK_COMP_TYPE_TAG_GR_TAG_GROUP
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID);

-- *** Views ***
DROP VIEW csr.v$audit_tag;
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../tag_pkg
@../audit_pkg
@../audit_report_pkg
@../schema_pkg
@../chain/type_capability_pkg

@../tag_body
@../audit_body
@../audit_report_body
@../schema_body
@../supplier_body
@../chain/company_user_body
@../chain/company_filter_body
@../chain/company_body
@../chain/type_capability_body
@../csrimp/imp_body

@update_tail
