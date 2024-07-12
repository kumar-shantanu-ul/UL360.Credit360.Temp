-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.audit_non_compliance DROP CONSTRAINT fk_anc_repeat_anc;
ALTER TABLE csr.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csr.audit_non_compliance MODIFY (
	audit_non_compliance_id				NULL
);
-- csr.ix_audit_non_compliance will do for now as a primary key

ALTER TABLE csrimp.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csrimp.audit_non_compliance MODIFY (
	audit_non_compliance_id				NULL
);
ALTER TABLE csrimp.audit_non_compliance ADD (
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(csrimp_session_id, internal_audit_sid, non_compliance_id)
);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
