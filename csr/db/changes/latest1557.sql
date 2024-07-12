-- Please update version.sql too -- this keeps clean builds in sync
define version=1557
@update_header

ALTER TABLE csrimp.issue MODIFY IS_PUBLIC DEFAULT NULL;
ALTER TABLE csrimp.issue MODIFY ALLOW_AUTO_CLOSE DEFAULT NULL;

@../audit_pkg
@../issue_pkg
@../audit_body
@../issue_body

@update_tail
