-- Please update version.sql too -- this keeps clean builds in sync
define version=2726
@update_header

INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (45, 'Delegation summary export', 'EnableDelegationSummary', 'Enables the delegation summary export (formally annual summary) on delegation sheets, and grants the capability to registered users.');

-- *** Packages ***

@../enable_pkg
@../enable_body

@update_tail