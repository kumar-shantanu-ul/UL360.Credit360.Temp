-- Please update version.sql too -- this keeps clean builds in sync
define version=3066
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.AUTO_IMP_CORE_DATA_SETTINGS
ADD OVERLAP_ACTION VARCHAR(10) DEFAULT 'ERROR' NOT NULL;

ALTER TABLE CSR.AUTO_IMP_CORE_DATA_SETTINGS
ADD CONSTRAINT CK_AUTO_IMP_COR_DATA_SET_OLAP CHECK (OVERLAP_ACTION IN ('ERROR', 'SUM'));


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
@../automated_import_pkg

@../automated_import_body


@update_tail
