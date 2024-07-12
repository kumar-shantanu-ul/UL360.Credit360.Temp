-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=32
@update_header

-- *** DDL ***
-- Create tables
CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_COMP_REGION_LVL_IDS (
	REGION_SID			NUMBER(10)		NOT NULL,
	REGION_DESCRIPTION	VARCHAR(1023)	NOT NULL,
	MGR_FULL_NAME		VARCHAR(255)
) ON COMMIT DELETE ROWS;

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
INSERT INTO csr.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH)
VALUES (1063, 'Site compliance levels', 'Credit360.Portlets.SiteComplianceLevels', EMPTY_CLOB(),'/csr/site/portal/portlets/SiteComplianceLevels.js');

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@@..\compliance_pkg

@@..\compliance_body
@@..\enable_body

@update_tail
