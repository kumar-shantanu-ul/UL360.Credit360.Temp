-- Please update version.sql too -- this keeps clean builds in sync
define version=3259
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD CHART_ALGORITHM_VERSION NUMBER(10);
ALTER TABLE CSRIMP.CUSTOMER ADD CHART_ALGORITHM_VERSION NUMBER(1);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (64, 'Chart Algorithm Version', 'Algorithm for DE charts', 'ChartAlgorithmVersion', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos) VALUES (64, 'Version (1 (default), 2)', 'The version to use.', 0);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../customer_body
@../schema_body
@../util_script_pkg
@../util_script_body

@../csrimp/imp_body

@update_tail
