-- Please update version.sql too -- this keeps clean builds in sync
define version=3331
define minor_version=6
@update_header

-- *** DDL ***
-- Create tables

CREATE OR REPLACE TYPE CSR.T_FLOW_ITEM_PERM_ROW AS
	OBJECT (
		FLOW_ITEM_ID				NUMBER(10),
		PERMISSION_SET				NUMBER(10)
	);
/

CREATE OR REPLACE TYPE CSR.T_FLOW_ITEM_PERM_TABLE IS TABLE OF CSR.T_FLOW_ITEM_PERM_ROW;
/

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

EXEC security.user_pkg.LogonAdmin;

INSERT INTO csr.plugin 
		(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, app_sid, details) 
SELECT csr.plugin_id_seq.nextval, 10, 'Surveys 2 Campaign Responses', 
'/csr/site/chain/managecompany/controls/SurveyResponses.js', 'Chain.ManageCompany.SurveyResponses', 
'Credit360.Chain.Plugins.SurveyResponses', c.app_sid, 
'Displays a list of Surveys 2 Campaign Responses for the page company that the user has read access to. Includes a link to the survey for each response.'
  FROM csr.customer c
 WHERE c.question_library_enabled = 1;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@..\flow_pkg
@..\campaigns\campaign_pkg

@..\enable_body
@..\flow_body
@..\campaigns\campaign_body

@update_tail
