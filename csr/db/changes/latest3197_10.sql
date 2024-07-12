-- Please update version.sql too -- this keeps clean builds in sync
define version=3197
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO cms.col_type (col_type, description) VALUES (43, 'Latitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (44, 'Longitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (45, 'Altitude');
	INSERT INTO cms.col_type (col_type, description) VALUES (46, 'Horizontal accuracy');
	INSERT INTO cms.col_type (col_type, description) VALUES (47, 'Vertical accuracy');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../../../aspen2/cms/db/tab_pkg
@../../../aspen2/cms/db/filter_pkg

@../../../aspen2/cms/db/tab_body
@../../../aspen2/cms/db/filter_body

@update_tail
