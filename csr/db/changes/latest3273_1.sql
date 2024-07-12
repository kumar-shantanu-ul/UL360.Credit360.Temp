-- Please update version.sql too -- this keeps clean builds in sync
define version=3273
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csr.internal_audit_type add 
    involve_auditor_in_issues number(1,0) default 0 not null;

alter table csrimp.internal_audit_type add 
    involve_auditor_in_issues number(1,0) default 0 not null;

alter table csr.internal_audit_type add constraint chk_involve_auditor_in_issues check (involve_auditor_in_issues in (1,0));
alter table csrimp.internal_audit_type add constraint chk_involve_auditor_in_issues check (involve_auditor_in_issues in (1,0));

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\audit_pkg

@..\audit_body
@..\enable_body
@..\schema_body
@..\csrimp\imp_body
@..\issue_body
@..\issue_report_body

@update_tail
