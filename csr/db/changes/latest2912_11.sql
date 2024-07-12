-- Please update version.sql too -- this keeps clean builds in sync
define version=2912
define minor_version=11
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DATAVIEW ADD (show_variance_explanations NUMBER(1,0) DEFAULT 0 NOT NULL);
ALTER TABLE CSR.DATAVIEW_HISTORY ADD (show_variance_explanations NUMBER(1,0) DEFAULT 0 NOT NULL);

ALTER TABLE CSRIMP.DATAVIEW ADD (show_variance_explanations NUMBER(1,0) NOT NULL);
ALTER TABLE CSRIMP.DATAVIEW_HISTORY ADD (show_variance_explanations NUMBER(1,0) NOT NULL);


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
@../dataview_pkg
@../dataview_body
@../scenario_pkg
@../scenario_body
@../schema_body
@../csrimp/imp_body

@update_tail
