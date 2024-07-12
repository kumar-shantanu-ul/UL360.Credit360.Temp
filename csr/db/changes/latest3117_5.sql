-- Please update version.sql too -- this keeps clean builds in sync
define version=3117
define minor_version=5
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.dataview ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);

ALTER TABLE csr.dataview_history ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);

ALTER TABLE csrimp.dataview ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);

ALTER TABLE csrimp.dataview_history ADD (
	region_selection				NUMBER(1,0) DEFAULT(6) NOT NULL
);

--UPDATE csr.dataview SET region_selection = 6;

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
