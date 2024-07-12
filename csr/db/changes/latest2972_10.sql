-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

 -- Data
BEGIN
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'usingAdvancedFilter', 'BOOLEAN', 'Using advanced filter');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'includeFinalState', 'BOOLEAN', 'Advanced filter setting - Whether to include final state dashboards');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'groupedBy', 'STRING', 'What the dashboards are grouped by');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'textSearch', 'STRING', 'Advanced filter setting - Text search');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'startDtm', 'STRING', 'Advanced filter setting - Exclude dashboards before');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'endDtm', 'STRING', 'Advanced filter setting - Exclude dashboards after');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'actionState', 'NUMBER', 'Advanced filter setting - The action state selection');
	INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.PORTLETS.APPROVALDASHBOARDFILTER', 'workflowState', 'STRING', 'Advanced filter setting - Workflow state to filter to');
	INSERT INTO CSR.portlet (PORTLET_ID,NAME,TYPE,DEFAULT_STATE,SCRIPT_PATH) 
	VALUES (1060,'My approval dashboards filter','Credit360.Portlets.ApprovalDashboardFilter', EMPTY_CLOB(),'/csr/site/portal/portlets/ApprovalDashboardFilter.js');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../approval_dashboard_pkg
@../approval_dashboard_body
 
@update_tail
