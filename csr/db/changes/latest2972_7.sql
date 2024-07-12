-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=7
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.non_comp_type_rpt_audit_type (
	app_sid										NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	non_compliance_type_id						NUMBER(10, 0) NOT NULL,
	internal_audit_type_id						NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_nc_type_rpt_ia_type			PRIMARY KEY (app_sid, non_compliance_type_id, internal_audit_type_id),
	CONSTRAINT fk_nc_type_rpt_ia_type_nc_type	FOREIGN KEY (app_sid, non_compliance_type_id) REFERENCES csr.non_compliance_type (app_sid, non_compliance_type_id),
	CONSTRAINT fk_nc_type_rpt_ia_type_ia_type	FOREIGN KEY (app_sid, internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
);

CREATE TABLE CSRIMP.NON_COM_TYP_RPT_AUDI_TYP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	NON_COMPLIANCE_TYPE_ID NUMBER(10,0) NOT NULL,
	INTERNAL_AUDIT_TYPE_ID NUMBER(10,0) NOT NULL,
	CONSTRAINT PK_NON_COM_TYP_RPT_AUDI_TYP PRIMARY KEY (CSRIMP_SESSION_ID, NON_COMPLIANCE_TYPE_ID, INTERNAL_AUDIT_TYPE_ID),
	CONSTRAINT FK_NON_COM_TYP_RPT_AUDI_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- Alter tables

-- *** Grants ***
grant select, insert, update, delete on csrimp.non_com_typ_rpt_audi_typ to web_user;
grant select, insert, update on csr.non_comp_type_rpt_audit_type to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../audit_pkg
@../schema_pkg
@../csrimp/imp_pkg

@../audit_body
@../schema_body
@../csrimp/imp_body

@update_tail
