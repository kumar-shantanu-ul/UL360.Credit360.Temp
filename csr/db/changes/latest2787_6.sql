-- Please update version.sql too -- this keeps clean builds in sync
define version=2787
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- new aggregate types
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (41 /*chain.filter_pkg.FILTER_TYPE_AUDITS*/, 7 /*csr.audit_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES*/, 'Number of closed actions');

	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
	VALUES (42 /*chain.filter_pkg.FILTER_TYPE_NON_COMPLIANCES*/, 7 /*csr.non_compliance_report_pkg.AGG_TYPE_COUNT_CLOSED_ISSUES*/, 'Number of closed actions');
END;
/

-- ** New package grants **

-- *** Packages ***
@..\audit_report_pkg
@..\non_compliance_report_pkg

@..\audit_report_body
@..\non_compliance_report_body

@update_tail
