-- Please update version.sql too -- this keeps clean builds in sync
define version=1579
@update_header

ALTER TABLE csr.issue_type ADD email_involved_roles NUMBER (1, 0) DEFAULT 1 NOT NULL;
ALTER TABLE csr.issue_type ADD CONSTRAINT chk_email_involved_roles_1_0 CHECK (email_involved_roles IN (1, 0));

ALTER TABLE csrimp.issue_type ADD email_involved_roles NUMBER (1, 0);
UPDATE csrimp.issue_type SET email_involved_roles = 1;
ALTER TABLE csrimp.issue_type MODIFY email_involved_roles NOT NULL;
ALTER TABLE csrimp.issue_type ADD CONSTRAINT chk_email_involved_roles_1_0 CHECK (email_involved_roles IN (1, 0));
ALTER TABLE csrimp.issue_type MODIFY can_be_public DEFAULT NULL;

@../schema_body
@../csrimp/imp_body
@../issue_pkg
@../issue_body

@update_tail
