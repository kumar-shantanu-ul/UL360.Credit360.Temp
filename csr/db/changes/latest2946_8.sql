-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
alter table csrimp.delegation add (
	TAG_VISIBILITY_MATRIX_GROUP_ID	NUMBER(10),
	ALLOW_MULTI_PERIOD		 		NUMBER(1)		   NOT NULL
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
@../schema_body
@../csrimp/imp_body

@update_tail
