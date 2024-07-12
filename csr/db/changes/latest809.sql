-- Please update version.sql too -- this keeps clean builds in sync
define version=809
@update_header

ALTER TABLE CSR.CUSTOMER ADD (
	ISSUE_EDITOR_URL                 VARCHAR2(200)     DEFAULT '/csr/site/issues/EditIssueDialog.js' NOT NULL
);

@..\issue_pkg
@..\issue_body

@update_tail