-- Please update version.sql too -- this keeps clean builds in sync
define version=3040
define minor_version=50
@update_header

-- *** DDL ***
-- Create tables

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

-- Alter tables

create index csr.ix_locked_tag on csr.internal_audit_locked_tag(app_sid, tag_id);

-- *** Grants ***
grant select, insert, update on csr.internal_audit_locked_tag to csrimp;
grant select,insert,update,delete on csrimp.internal_audit_locked_tag to tool_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_pkg
@..\audit_body
@..\schema_pkg
@..\schema_body
@..\csrimp\imp_body

@update_tail
