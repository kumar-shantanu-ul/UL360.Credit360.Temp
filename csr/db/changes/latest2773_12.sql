-- Please update version.sql too -- this keeps clean builds in sync
define version=2773
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.internal_audit_type_group ADD (issue_type_id NUMBER(10,0));
ALTER TABLE csr.internal_audit_type_group ADD CONSTRAINT fk_issue_type FOREIGN KEY (app_sid, issue_type_id) REFERENCES csr.issue_type (app_sid, issue_type_id);

ALTER TABLE csr.issue_type ADD (applies_to_audit NUMBER(10,0) DEFAULT 0 NOT NULL);

ALTER TABLE csrimp.internal_audit_type_group ADD (issue_type_id NUMBER(10,0));
ALTER TABLE csrimp.internal_audit_type_group ADD CONSTRAINT fk_issue_type FOREIGN KEY (csrimp_session_id, issue_type_id) REFERENCES csrimp.issue_type (csrimp_session_id, issue_type_id);

ALTER TABLE csrimp.issue_type ADD (applies_to_audit NUMBER(10,0) DEFAULT 0 NOT NULL);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

UPDATE csr.issue_type
   SET applies_to_audit = 1 -- csr_data_pkg.IT_APPLIES_TO_AUDIT (not compiled yet)
 WHERE issue_type_id = 11;

-- ** New package grants **

-- *** Packages ***
@..\csr_data_pkg
@..\audit_body
@..\issue_body
@..\enable_body
@..\csrimp\imp_body

@update_tail
