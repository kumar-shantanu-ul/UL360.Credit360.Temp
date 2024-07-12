-- Please update version.sql too -- this keeps clean builds in sync
define version=2950
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.CUSTOMER ADD ALLOW_OLD_CHART_ENGINE NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE CSRIMP.CUSTOMER ADD ALLOW_OLD_CHART_ENGINE NUMBER(1) NOT NULL;

ALTER TABLE CSR.CUSTOMER ADD CONSTRAINT CK_CUST_ALLOW_OLD_CHART_ENGINE CHECK (ALLOW_OLD_CHART_ENGINE IN (0,1));
ALTER TABLE CSRIMP.CUSTOMER ADD CONSTRAINT CK_CUST_ALLOW_OLD_CHART_ENGINE CHECK (ALLOW_OLD_CHART_ENGINE IN (0,1));

-- *** Grants ***
-- Unrelated to this story, but not compiling...
GRANT SELECT, INSERT, UPDATE ON csr.internal_audit TO CSRIMP;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- All existing clients will be allowed to use the old charting engine.
-- New clients will always be disallowed from using the old charting engine.
UPDATE CSR.CUSTOMER SET ALLOW_OLD_CHART_ENGINE = 1;

INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID, UTIL_SCRIPT_NAME, DESCRIPTION, UTIL_SCRIPT_SP, WIKI_ARTICLE)
VALUES (15, 'Allow Old Chart Engine', 'Allow (1) or disallow (0) old chart engine. Default for new clients is disallow.', 'AllowOldChartEngine', NULL);

INSERT INTO CSR.UTIL_SCRIPT_PARAM (util_script_id, param_name, param_hint, pos)
VALUES (15, 'Setting value (0 off, 1 on)', 'The setting to use.', 0);


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../customer_body
@../schema_body
@../csrimp/imp_body

@../util_script_pkg
@../util_script_body

@update_tail
