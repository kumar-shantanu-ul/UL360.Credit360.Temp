-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
DROP INDEX csr.uk_compliance_item_ref;

CREATE UNIQUE INDEX csr.uk_compliance_item_ref ON csr.compliance_item (
	app_sid,
	DECODE(compliance_item_type, 2, TO_CHAR("COMPLIANCE_ITEM_ID"), DECODE("SOURCE", 0, NVL("REFERENCE_CODE", TO_CHAR("COMPLIANCE_ITEM_ID")), TO_CHAR("COMPLIANCE_ITEM_ID")))
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
