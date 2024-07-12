-- Please update version.sql too -- this keeps clean builds in sync
define version=3084
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

ALTER TABLE chain.bsci_audit
RENAME COLUMN execsumm_audit_rpt TO xxx_execsumm_audit_rpt;

ALTER TABLE chain.bsci_audit
ADD execsumm_audit_rpt CLOB;

ALTER TABLE csrimp.chain_bsci_audit
DROP COLUMN execsumm_audit_rpt;

ALTER TABLE csrimp.chain_bsci_audit
ADD execsumm_audit_rpt CLOB NULL;

BEGIN
	security.user_pkg.LogonAdmin;
	UPDATE chain.bsci_audit
	   SET execsumm_audit_rpt = TO_CLOB(xxx_execsumm_audit_rpt);
END;
/

ALTER TABLE chain.bsci_audit
DROP COLUMN xxx_execsumm_audit_rpt;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\chain\bsci_pkg
@..\chain\bsci_body

@update_tail
