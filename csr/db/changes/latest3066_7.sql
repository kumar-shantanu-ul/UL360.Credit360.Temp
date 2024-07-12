-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=7
@update_header

-- *** Conditional Packages ***

@..\audit_report_body
@..\non_compliance_report_body

@update_tail
