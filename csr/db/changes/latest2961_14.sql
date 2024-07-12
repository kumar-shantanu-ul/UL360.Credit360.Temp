-- Please update version.sql too -- this keeps clean builds in sync
define version=2961
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE aspen2.application ADD (
	monitor_with_new_relic NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csrimp.aspen2_application ADD (
	monitor_with_new_relic NUMBER(1)
);

UPDATE csrimp.aspen2_application
   SET monitor_with_new_relic = 0;

ALTER TABLE csrimp.aspen2_application
	MODIFY monitor_with_new_relic NOT NULL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (21,'Start monitoring site in New Relic','Adds the site to those monitored by New Relic to diagnose performance problems and trends','AddNewRelicToSite',null);
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (22,'Stop monitoring site in New Relic','Disables New Relic client-side monitoring','RemoveNewRelicFromSite',null);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@..\util_script_pkg

@..\..\..\aspen2\db\aspenapp_body
@..\csrimp\imp_body
@..\schema_body
@..\util_script_body

@update_tail
