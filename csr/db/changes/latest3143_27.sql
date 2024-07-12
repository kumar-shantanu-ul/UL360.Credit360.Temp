-- Please update version.sql too -- this keeps clean builds in sync
define version=3143
define minor_version=27
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE cms.tab ADD (
	managed_version					NUMBER(10)
);

UPDATE cms.tab
   SET managed_version = 1
 WHERE managed = 1;
 
ALTER TABLE cms.tab ADD (
	CONSTRAINT chk_mngd_version CHECK (managed = 1 AND managed_version IS NOT NULL OR managed = 0)
);

ALTER TABLE csrimp.cms_tab ADD (
	managed_version					NUMBER(10),
	CONSTRAINT chk_mngd_version CHECK (managed = 1 AND managed_version IS NOT NULL OR managed = 0)
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
@../../../aspen2/cms/db/tab_pkg
@../unit_test_pkg

@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body
@../unit_test_body
@../csrimp/imp_body

@update_tail
