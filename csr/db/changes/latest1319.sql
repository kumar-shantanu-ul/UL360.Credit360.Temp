-- Please update version.sql too -- this keeps clean builds in sync
define version=1319
@update_header

BEGIN
	INSERT INTO ct.template_key (lookup_key, description, position) VALUES ('value_chain_report_primary_no_branding', 'Value Chain Report - Primary (no branding)', 9);
END;
/

@update_tail
