-- Please update version.sql too -- this keeps clean builds in sync
define version=2987
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_PCT;
ALTER TABLE CSR.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_ABS;
ALTER TABLE CSR.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_START;

ALTER TABLE CSR.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_PCT;
ALTER TABLE CSR.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_ABS;
ALTER TABLE CSR.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_START;


ALTER TABLE CSRIMP.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_PCT;
ALTER TABLE CSRIMP.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_ABS;
ALTER TABLE CSRIMP.DATAVIEW DROP COLUMN SHOW_LAYER_VARIANCE_START;

ALTER TABLE CSRIMP.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_PCT;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_ABS;
ALTER TABLE CSRIMP.DATAVIEW_HISTORY DROP COLUMN SHOW_LAYER_VARIANCE_START;

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
@../schema_body
@../csrimp/imp_body

@update_tail
