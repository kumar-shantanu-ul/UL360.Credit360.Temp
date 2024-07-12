-- WARNING: Looking for next base ID? The ID is not a static ID! On live IDs are all over the place, use csr.plugin_id_seq.nextval in latest script.
BEGIN
	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(1, 2, 'ListEditor CMS Plugin', '/csr/shared/plugins/ListEditorCMSPlugin.js', 'Credit360.plugins.ListEditorCMSPlugin', 'Credit360.Plugins.EmptyDto', '', '', '');

	INSERT INTO  csr.plugin 	
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(2, 1, 'Spaces', '/csr/site/property/properties/controls/SpaceListMetricPanel.js',
		'Controls.SpaceListMetricPanel', 'Credit360.Plugins.PluginDto',
		'This tab shows a list of spaces (sub-regions) at the selected property. It allows you to create new spaces, and set space metrics that have been configured for the chosen space type.',
		'/csr/shared/plugins/screenshots/property_tab_space_list_metric.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(3, 1, 'Delegations tab', '/csr/site/property/properties/controls/DelegationPanel.js',
		'Controls.DelegationPanel', 'Credit360.Property.Plugins.DelegationDto',
		'This tab shows any delegation forms that the logged in user needs to enter data or approve for the property they are viewing.',
		'/csr/shared/plugins/screenshots/property_tab_delegation.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(4, 4, 'My feed', '/csr/site/activity/controls/MyFeedPanel.js', 'Activity.MyFeedPanel', 'Credit360.UserProfile.MyFeedDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(5, 4, 'My activities', '/csr/site/activity/controls/MyActivitiesPanel.js', 'Activity.MyActivitiesPanel', 'Credit360.UserProfile.MyActivitiesDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(6, 1, 'Actions tab', '/csr/site/property/properties/controls/IssuesPanel.js',
		'Controls.IssuesPanel', 'Credit360.Property.Plugins.IssuesPanel',
		'This tab shows a list of actions (issues) associated with the property.', '/csr/shared/plugins/screenshots/property_tab_actions.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(7, 5, 'Summary', '/csr/site/teamroom/controls/SummaryPanel.js', 'Teamroom.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(8, 5, 'Documents', '/csr/site/teamroom/controls/DocumentsPanel.js', 'Teamroom.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(9, 5, 'Calendar', '/csr/site/teamroom/controls/CalendarPanel.js', 'Teamroom.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(10, 5, 'Actions', '/csr/site/teamroom/controls/IssuesPanel.js', 'Teamroom.IssuesPanel', 'Credit360.Teamroom.IssuesPanel', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(11, 5, 'Projects', '/csr/site/teamroom/controls/InitiativesPanel.js', 'Teamroom.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(12, 8, 'Details', '/csr/site/initiatives/detail/controls/SummaryPanel.js', 'Credit360.Initiatives.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(13, 8, 'Documents', '/csr/site/initiatives/detail/controls/DocumentsPanel.js', 'Credit360.Initiatives.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(14, 8, 'Calendar', '/csr/site/initiatives/detail/controls/CalendarPanel.js', 'Credit360.Initiatives.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(15, 8, 'Actions', '/csr/site/initiatives/detail/controls/IssuesPanel.js', 'Credit360.Initiatives.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(16, 1, 'Property Surveys Tab', '/csr/site/property/properties/controls/surveysTab.js',
		'Controls.SurveysTab', 'Credit360.Property.Plugins.SurveysTab',
		'This tab shows the list of surveys the logged in user has access to for the property being viewed.',
		'/csr/shared/plugins/screenshots/property_tab_surveys.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(17, 1, 'Initiatives', '/csr/site/property/properties/controls/InitiativesPanel.js',
		'Controls.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin',
		'This tab lists the initiatives associated with the property. It supports creating, exporting, importing the intiatives from within the tab.',
		'/csr/shared/plugins/screenshots/property_tab_initiatives.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(18, 10, 'Supplier list', '/csr/site/chain/managecompany/controls/SupplierListTab.js',
		'Chain.ManageCompany.SupplierListTab', 'Credit360.Chain.Plugins.SupplierListDto',
		'This tab shows the suppliers of the company being viewed as a list, and allows drill down to view the company management page for the chosen supplier.',
		'/csr/shared/plugins/screenshots/company_tab_suppliers.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(19, 10, 'Activity Summary', '/csr/site/chain/managecompany/controls/ActivitySummaryTab.js',
		'Chain.ManageCompany.ActivitySummaryTab', 'Credit360.Chain.CompanyManagement.ActivitySummaryTab',
		'This tab displays a summary of upcoming/overdue activities for a supplier, that required the logged in user to set the outcome of.',
		'/csr/shared/plugins/screenshots/company_tab_activity_summary.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(20, 10, 'Activity List', '/csr/site/chain/managecompany/controls/ActivityListTab.js',
		'Chain.ManageCompany.ActivityListTab',
		'Credit360.Chain.CompanyManagement.ActivityListTab',
		'This tab displays a filterable/searchable table of all activities raised against the supplier being viewed, that the logged in user has permission to see.',
		'/csr/shared/plugins/screenshots/company_tab_activity_list.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(21, 11, 'Supplier scores', '/csr/site/chain/managecompany/controls/ScoreHeader.js',
		'Chain.ManageCompany.ScoreHeader', 'Credit360.Chain.Plugins.ScoreHeaderDto',
		'This header shows any survey scores for the supplier, and allows the user to set the score if it has been configured to allow manual editing (via /csr/site/quicksurvey/admin/thresholds/list.acds).',
		'/csr/shared/plugins/screenshots/company_header_scores.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(22, 10, 'Activity Calendar', '/csr/site/chain/managecompany/controls/CalendarTab.js',
		'Chain.ManageCompany.CalendarTab', 'Credit360.Chain.CompanyManagement.CalendarTab',
		'This tab displays a calendar that can show activities relating to the supplier being viewed.',
		'/csr/shared/plugins/screenshots/company_tab_calendar.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(23, 12, 'Audits', '/csr/shared/calendar/includes/audits.js', 'Credit360.Calendars.Audits', 'Credit360.Audit.AuditCalendarDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(24, 12, 'Events', '/csr/shared/calendar/includes/initiatives.js', 'Credit360.Calendars.Initiatives', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(25, 12, 'Issues coming due', '/csr/shared/calendar/includes/issues.js', 'Credit360.Calendars.Issues', 'Credit360.Issues.IssueCalendarDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(26, 12, 'Teamroom events', '/csr/shared/calendar/includes/teamrooms.js', 'Credit360.Calendars.Teamrooms', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(27, 12, 'Activities', '/csr/shared/calendar/includes/activities.js', 'Credit360.Calendars.Activities', 'Credit360.Chain.Activities.ActivityCalendarDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(28, 12, 'Teamroom actions', '/csr/site/teamroom/controls/calendar/issues.js', 'Teamroom.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(29, 12, 'Actions', '/csr/site/initiatives/calendar/issues.js', 'Credit360.Initiatives.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(30, 11, 'Company management indicators', '/csr/site/chain/managecompany/controls/IndicatorsHeader.js',
		'Chain.ManageCompany.IndicatorsHeader', 'Credit360.Chain.Plugins.ChainIndicatorPluginDto',
		'This plugin gives the ability to show some indicator VALUES associated with the company in the header panel.', '', '');

	INSERT INTO csr.plugin 
	
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(31, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js',
		'Controls.PortalTab', 'Credit360.Property.Plugins.PortalDto',
		'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the property. Each tab configured shows as a separate tab in the property page.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(32, 10, 'Product types', '/csr/site/chain/managecompany/controls/ProductTypesTab.js',
		'Chain.ManageCompany.ProductTypesTab', 'Credit360.Chain.CompanyManagement.ProductTypesTab',
		'This tab shows the product types that a supplier supplies, and providing the user has the write capability for products, it will also let the user edit the list.', '/csr/shared/plugins/screenshots/company_tab_product_types.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(33, 14, 'Full audit details header', '/csr/site/audit/controls/FullAuditHeader.js',
		'Audit.Controls.FullAuditHeader', 'Credit360.Audit.Plugins.FullAuditHeader',
		'This header gives the original view of an audit, showing the audit region and date, auditor organisation, audit type, workflow status, closure results, audit notes and a link to the audit survey.', '/csr/shared/plugins/screenshots/audit_header_full_details.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(34, 1, 'Chemicals Inventory', '/csr/site/property/properties/controls/ChemicalInventoryTab.js',
		'Controls.ChemicalInventoryTab', 'Credit360.Plugins.PluginDto',
		'This tab shows a list chemicals associated with the property.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(35, 10, 'Actions', '/csr/site/chain/manageCompany/controls/IssuesPanel.js',
		'Chain.ManageCompany.IssuesPanel', 'Credit360.Chain.Plugins.IssuesPanel',
		'', '/csr/shared/plugins/screenshots/company_tab_issues.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(36, 10, 'Delegations', '/csr/site/chain/manageCompany/controls/DelegationPanel.js',
		'Chain.ManageCompany.DelegationPanel', 'Credit360.Chain.Plugins.DelegationDto', '',
		'/csr/shared/plugins/screenshots/company_tab_delegations.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(37, 10, 'Questionnaires', '/csr/site/chain/manageCompany/controls/QuestionnaireList.js',
		'Chain.ManageCompany.QuestionnaireList', 'Credit360.Chain.Plugins.QuestionnaireListDto',
		'', '/csr/shared/plugins/screenshots/company_tab_questionnaires.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(38, 10, 'Supplier Audits', '/csr/site/chain/manageCompany/controls/SupplierAuditList.js',
		'Chain.ManageCompany.SupplierAuditList', 'Credit360.Chain.Plugins.SupplierAuditListDto',
		'', '/csr/shared/plugins/screenshots/company_tab_supplier_audits.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(39, 10, 'Data Collection', '/csr/site/chain/manageCompany/controls/DataCollection.js',
		'Chain.ManageCompany.DataCollection', 'Credit360.Chain.Plugins.DataCollectionDto',
		'Shows delegations, questionnaires and supplier audits on a single tab',
		'/csr/shared/plugins/screenshots/company_tab_data_collection.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(40, 10, 'Messages', '/csr/site/chain/manageCompany/controls/MessagesTab.js',
		'Chain.ManageCompany.MessagesTab', 'Credit360.Plugins.PluginDto', '',
		'/csr/shared/plugins/screenshots/company_tab_messages.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(41, 10, 'Portlets', '/csr/site/chain/manageCompany/controls/PortalTab.js',
		'Chain.ManageCompany.PortalTab', 'Credit360.Chain.Plugins.PortalDto',
		'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the company. Each tab configured shows as a separate tab in the company management page.',
		'', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(43, 10, 'Subsidiaries', '/csr/site/chain/manageCompany/controls/SubsidiaryTab.js',
		'Chain.ManageCompany.SubsidiaryTab', 'Credit360.Chain.Plugins.SubsidiaryDto',
		'This tab shows the subsidiaries of the selected company, and given the correct permissions, will allow adding new subsidiaries.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(44, 10, 'Supply Chain Graph', '/csr/site/chain/manageCompany/controls/CompaniesGraph.js',
		'Chain.ManageCompany.CompaniesGraph', 'Credit360.Chain.Plugins.CompaniesGraphDto',
		'This tab shows a graph of the supply chain for the selected company.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(45, 10, 'Company users', '/csr/site/chain/manageCompany/controls/CompanyUsers.js',
		'Chain.ManageCompany.CompanyUsers', 'Credit360.Chain.Plugins.CompanyUsersDto',
		'This tab shows the users of the selected company, and given the correct permissions, will allow updateding / adding new users.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(46, 10, 'Company details', '/csr/site/chain/manageCompany/controls/CompanyDetails.js',
		'Chain.ManageCompany.CompanyDetails', 'Credit360.Chain.Plugins.CompanyDetailsDto',
		'This tab allows editing of the core company details such as address.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(47, 10, 'Relationships', '/csr/site/chain/manageCompany/controls/RelationshipsTab.js',
		'Chain.ManageCompany.RelationshipsTab', 'Credit360.Chain.Plugins.RelationshipsTabDto',
		'This tab allows adding/removing relationships to a company.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(48, 10, 'Business Relationship List', '/csr/site/chain/managecompany/controls/BusinessRelationshipListTab.js',
		'Chain.ManageCompany.BusinessRelationshipListTab', 'Credit360.Chain.CompanyManagement.BusinessRelationshipListTab',
		'This tab displays a filterable and searchable table of all business relationships of which the supplier being viewed is a member, that the logged in user has permission to see.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(49, 10, 'My Details', '/csr/site/chain/manageCompany/controls/MyDetailsTab.js',
		'Chain.ManageCompany.MyDetailsTab', 'Credit360.Chain.Plugins.MyDetailsDto',
		'This tab allows a user to maintain their personal details. This tab would normally only be used when looking at your own company.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(50, 13, 'Findings', '/csr/site/audit/controls/FindingTab.js', 'Audit.Controls.FindingTab', 'Credit360.Audit.Plugins.FindingTab', 'Findings', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(51, 13, 'Finding score summary', '/csr/site/audit/controls/NcScoreSummaryTab.js',
		'Audit.Controls.NcScoreSummaryTab', 'Credit360.Audit.Plugins.NcScoreSummaryTab',
		'Summarises the findings score for the audit, broken down by finding type', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(52, 13, 'Documents', '/csr/site/audit/controls/DocumentsTab.js', 'Audit.Controls.Documents', 'Credit360.Audit.Plugins.FullAuditTab', 'Documents', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(53, 13, 'Executive Summary', '/csr/site/audit/controls/ExecutiveSummaryTab.js', 'Audit.Controls.ExecutiveSummary', 'Credit360.Audit.Plugins.FullAuditTab',
	'Executive Summary', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(54, 13, 'Audit Log', '/csr/site/audit/controls/AuditLogTab.js', 'Audit.Controls.AuditLog', 'Credit360.Audit.Plugins.FullAuditTab', 'Audit Log', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(55, 13, 'Full audit details tab', '/csr/site/audit/controls/FullAuditTab.js',
		'Audit.Controls.FullAuditTab', 'Credit360.Audit.Plugins.FullAuditTab',
		'This tab gives the original view of an audit, showing the executive summary, audit documents and non-compliances each in its own section.',
		'/csr/shared/plugins/screenshots/audit_tab_full_details.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(56, 12, 'Course schedules', '/csr/shared/calendar/includes/training.js', 'Credit360.Calendars.Training', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(57, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js', 'Portlets', 'Credit360.Property.Plugins.PortalDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(58, 6, 'Settings', '/csr/site/teamroom/controls/edit/SettingsPanel.js', 'MarksAndSpencer.Teamroom.Edit.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(59, 7, 'Settings', '/csr/site/teamroom/controls/mainTab/SettingsPanel.js', 'MarksAndSpencer.Teamroom.MainTab.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(60, 1, 'Meter Raw Data', '/csr/site/property/properties/controls/MeterRawDataTab.js', 'Controls.MeterRawDataTab', 'Credit360.Plugins.PluginDto',
	'This tab shows raw data for real time metering.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(61, 8, 'Audit Log', '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'Audit Log', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(62, 13, 'Finding List', '/csr/site/audit/controls/NonComplianceListTab.js', 'Audit.Controls.NonComplianceListTab', 'Credit360.Audit.Plugins.NonComplianceList',
	'This tab shows a filterable list of findings.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(63, 13, 'Survey List', '/csr/site/audit/controls/SurveysTab.js',
		'Audit.Controls.SurveysTab', 'Credit360.Audit.Plugins.SurveysTab',
		'This tab shows a list of surveys against an audit.  It is intended for customers who have purchased the multiple audit surveys feature.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(64, 1, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js',
		'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList',
		'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(65, 15, 'Validation report', '/csr/site/rreports/reports/Validation.js',
		'Credit360.RReports.Validation', 'Credit360.RReports.Runners.ValidationReportRunner',
		'', '', '/csr/rreports/validation_V5/validation_V5.R');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(66, 16, 'Raw meter data', '/csr/site/meter/controls/meterRawDataTab.js',
		'Credit360.Metering.MeterRawDataTab', 'Credit360.Metering.Plugins.MeterRawData',
		'Display, filter, search, and export raw readings for the meter.', '/csr/shared/plugins/screenshots/meter_raw_data.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(67, 16, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js',
		'Credit360.Metering.MeterQuickChartTab', 'Credit360.Metering.Plugins.MeterQuickChartTab',
		'Display data for the meter in a calendar view, chart, list, or pivot table.', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(68, 16, 'Meter audit log', '/csr/site/meter/controls/AuditLogTab.js',
		'Credit360.Metering.AuditLogTab', 'Credit360.Metering.Plugins.AuditLogTab',
		'Log changes to the meter region and any patches made to the meter data.', '/csr/shared/plugins/screenshots/meter_audit_log_tab.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(69, 16, 'Actions tab', '/csr/site/meter/controls/IssuesTab.js',
		'Credit360.Metering.IssuesTab', 'Credit360.Metering.Plugins.IssuesTab',
		'Show all actions associated with the meter, and raise new actions.', '/csr/shared/plugins/screenshots/meter_issue_list_tab.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(70, 16, 'Hi-res chart', '/csr/site/meter/controls/meterHiResChartTab.js',
		'Credit360.Metering.MeterHiResChartTab', 'Credit360.Metering.Plugins.MeterHiResChart',
		'Display a detailed interactive chart showing all inputs for the meter, and patch data for the meter.',
		'/csr/shared/plugins/screenshots/meter_hi_res_chart.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(71, 16, 'Low-res chart', '/csr/site/meter/controls/meterLowResChartTab.js',
		'Credit360.Metering.MeterLowResChartTab', 'Credit360.Metering.Plugins.MeterLowResChart',
		'Display a simple chart showing total and average consumption for the lifetime of the meter.', '/csr/shared/plugins/screenshots/meter_low_res_chart.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(72, 16, 'Readings', '/csr/site/meter/controls/meterReadingTab.js',
		'Credit360.Metering.MeterReadingTab', 'Credit360.Metering.Plugins.MeterReading',
		'Enter readings and check percentage tolerances.', '/csr/shared/plugins/screenshots/meter_readings.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(73, 16, 'Meter Characteristics', '/csr/site/meter/controls/meterCharacteristicsTab.js',
		'Credit360.Metering.MeterCharacteristicsTab', 'Credit360.Metering.Plugins.MeterCharacteristics', 'Edit meter data.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(74, 17, 'Emissions profiles', '/csr/site/admin/emissionFactors/controls/EmissionProfilesTab.js',
		'Controls.EmissionProfilesTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage emission factor profiles.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(75, 17, 'Map indicators', '/csr/site/admin/emissionFactors/controls/MapIndicatorsTab.js', 'Credit360.EmissionFactors.MapIndicatorsTab', 'Credit360.Plugins.PluginDto',
	'This tab will hold the options to manage the emission factor indicator mappings.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(76, 8, 'Initiative details - What', '/csr/site/initiatives/detail/controls/WhatPanel.js',
		'Credit360.Initiatives.Plugins.WhatPanel', 'Credit360.Plugins.PluginDto',
		'Contains core details about the initiative, including the name, reference, project type and description.',
		'/csr/shared/plugins/screenshots/initiative_tab_what.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(77, 8, 'Initiative details - Where', '/csr/site/initiatives/detail/controls/WherePanel.js', 'Credit360.Initiatives.Plugins.WherePanel', 'Credit360.Plugins.PluginDto',
	'Contains location information about the initiative, i.e. the regions the initiative will apply to.', '/csr/shared/plugins/screenshots/initiative_tab_where.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(78, 8, 'Initiative details - When', '/csr/site/initiatives/detail/controls/WhenPanel.js',
		'Credit360.Initiatives.Plugins.WhenPanel', 'Credit360.Plugins.PluginDto',
		'Contains timing information about when the initiative will run.', '/csr/shared/plugins/screenshots/initiative_tab_when.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(79, 8, 'Initiative details - Why', '/csr/site/initiatives/detail/controls/WhyPanel.js',
		'Credit360.Initiatives.Plugins.WhyPanel', 'Credit360.Plugins.PluginDto',
		'Contains metrics about the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_why.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(80, 8, 'Initiative details - Who', '/csr/site/initiatives/detail/controls/WhoPanel.js',
		'Credit360.Initiatives.Plugins.WhoPanel', 'Credit360.Plugins.PluginDto',
		'Contains details of who is involved with the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_who.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(81, 8, 'Initiative details', '/csr/site/initiatives/detail/controls/InitiativeDetailsPanel.js',
		'Credit360.Initiatives.Plugins.InitiativeDetailsPanel', 'Credit360.Plugins.PluginDto',
		'Contains all the details of the initiative in one tab (use this instead of the individual what, where, when, why, who tabs).',
		'/csr/shared/plugins/screenshots/initiative_tab_initiative_details.png', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(82, 10, 'Supplier followers', '/csr/site/chain/manageCompany/controls/SupplierFollowersTab.js',
		'Chain.ManageCompany.SupplierFollowersTab', 'Credit360.Chain.Plugins.SupplierFollowersDto',
		'This tab shows the followers of the selected company, and given the correct permissions, will allow adding/removing followers.', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details) 
	VALUES 
	(83, 10, 'Document library', '/csr/site/chain/managecompany/controls/DocLibTab.js',
		'Chain.ManageCompany.DocLibTab', 'Credit360.Chain.Plugins.DocLibTabDto',
		'This tab will show the document library for the selected company.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(84, 1, 'Property audit log', '/csr/site/property/properties/controls/AuditLogPanel.js',
		'Controls.AuditLogPanel', 'Credit360.Plugins.PluginDto',
		'This tab shows an audit log of this property and all associated spaces, meters and metrics', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path)
	VALUES 
	(85, 13, 'Actions', '/csr/site/audit/controls/ActionsTab.js',
		'Audit.Controls.ActionsTab', 'Credit360.Audit.Plugins.ActionsTab',
		'This tab shows a list of actions from findings against an audit', '', '');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, r_script_path, allow_multiple)
	VALUES 
	(86, 10, 'Business Relationship Graph', '/csr/site/chain/manageCompany/controls/BusinessRelationshipGraph.js',
		'Chain.ManageCompany.BusinessRelationshipGraph', 'Credit360.Chain.Plugins.BusinessRelationshipGraphDto',
		'This tab shows a graph of business relationships for a company.', '', '', 1);

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(87, 10, 'Audits tab', '/csr/site/chain/manageCompany/controls/AuditList.js',
		'Chain.ManageCompany.AuditList', 'Credit360.Chain.Plugins.AuditListPlugin', 'A list of audits associated with the supplier.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(88, 10, 'Audit request list tab', '/csr/site/chain/manageCompany/controls/AuditRequestList.js',
		'Chain.ManageCompany.AuditRequestList', 'Credit360.Chain.Plugins.AuditRequestListPlugin', 'A list of open audit requests for the supplier.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(89, 1, 'Audits tab', '/csr/site/property/properties/controls/AuditList.js',
		'Controls.AuditList', 'Credit360.Property.Plugins.AuditListPlugin', 'A list of audits associated with the property.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(90, 10, 'Supplier list expandable', '/csr/site/chain/managecompany/controls/SupplierListExpandableTab.js',
		'Chain.ManageCompany.SupplierListExpandableTab', 'Credit360.Chain.Plugins.SupplierListExpandable',
		'Same as supplier list plus extra column with expandable row with companies related to a particular company.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES 
	(91, 11, 'Certifications', '/csr/site/chain/managecompany/controls/CertificationHeader.js',
		'Chain.ManageCompany.CertificationHeader', 'Credit360.Chain.Plugins.CertificationHeaderDto',
		'This header shows any certifications for a company.', '/csr/shared/plugins/screenshots/company_header_certifications.png');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(92, 18, 'Chain Product Header', '/csr/site/chain/manageProduct/controls/ProductHeader.js',
		'Chain.ManageProduct.ProductHeader', 'Credit360.Plugins.EmptyDto', 'Product header');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(94, 19, 'Suppliers Tab', '/csr/site/chain/manageProduct/controls/ProductSuppliersTab.js',
		'Chain.ManageProduct.ProductSuppliersTab', 'Credit360.Chain.Plugins.ProductSuppliersDto', 'This tab shows the suppliers who contribute to a product.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(95, 20, 'Supplier Details Tab', '/csr/site/chain/manageProduct/controls/ProductSupplierDetailsTab.js',
		'Chain.ManageProduct.ProductSupplierDetailsTab', 'Credit360.Chain.Plugins.ProductSupplierDetailsDto',
		'This tab shows the details of a supplier who contributes to a product.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(96, 19, 'Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductCertificationsTab.js',
		'Chain.ManageProduct.ProductCertificationsTab', 'Credit360.Chain.Plugins.ProductCertificationsDto',
		'This tab shows the certifications attached to a product.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(97, 20, 'Supplier Certifications Tab', '/csr/site/chain/manageProduct/controls/ProductSupplierCertificationsTab.js',
		'Chain.ManageProduct.ProductSupplierCertificationsTab', 'Credit360.Chain.Plugins.ProductSupplierCertificationsDto',
		'This tab shows the certifications attached to a product supplier.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(98, 18, 'Certification Requirements Header', '/csr/site/chain/manageProduct/controls/CertificationRequirementsHeader.js',
		'Chain.ManageProduct.CertificationRequirementsHeader', 'Credit360.Chain.Plugins.CertificationRequirementsDto',
		'This header shows the certification requirements for a product.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(99, 10, 'Product list (Company)', '/csr/site/chain/manageCompany/controls/ProductListTab.js',
		'Chain.ManageCompany.ProductListTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a company.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(100, 10, 'Product list (Supplier)', '/csr/site/chain/manageCompany/controls/ProductListSupplierTab.js',
		'Chain.ManageCompany.ProductListSupplierTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a supplier.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(101, 21, 'Permit details tab', '/csr/site/compliance/controls/PermitDetailsTab.js',
		'Credit360.Compliance.Controls.PermitDetailsTab', 'Credit360.Compliance.Plugins.PermitDetailsTab', 'Shows basic permit details');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(102, 21, 'Permit applications tab', '/csr/site/compliance/controls/PermitApplicationTab.js',
		'Credit360.Compliance.Controls.PermitApplicationTab', 'Credit360.Compliance.Plugins.PermitApplicationTab', 'Shows all of the applications for a permit.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(103, 21, 'Permit conditions tab', '/csr/site/compliance/controls/PermitConditionsTab.js',
		'Credit360.Compliance.Controls.PermitConditionsTab', 'Credit360.Compliance.Plugins.PermitConditionsTab', 'Shows permit conditions.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES 
	(104, 11, 'Supplier relationship scores', '/csr/site/chain/managecompany/controls/SuppRelScoreHeader.js',
		'Chain.ManageCompany.SuppRelScoreHeader', 'Credit360.Chain.Plugins.SuppRelScoreHeaderDto',
		'This header shows any scores on the relationship between the company you are logged in as and the company you are viewing.',
		'/csr/shared/plugins/screenshots/supplier_relationship_scores.png');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES 
	(105, 11, 'Primary purchasers', '/csr/site/chain/managecompany/controls/PrimaryPurchasersHeader.js',
		'Chain.ManageCompany.PrimaryPurchasersHeader', 'Credit360.Chain.Plugins.PrimaryPurchasersHeaderDto',
		'This header shows any primary purchasers for a company.', '/csr/shared/plugins/screenshots/company_header_primary_purchasers.png');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(106, 21, 'Permit audit log tab', '/csr/site/compliance/controls/FlowItemAuditLogTab.js',
		'Credit360.Compliance.Controls.FlowItemAuditLogTab', 'Credit360.Compliance.Plugins.FlowItemAuditLogTab',
		'Shows the audit history of a permit item.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(107, 21, 'Permit actions tab', '/csr/site/compliance/controls/PermitActionsTab.js',
		'Credit360.Compliance.Controls.PermitActionsTab', 'Credit360.Compliance.Plugins.PermitActionsTab', 'Shows permit actions.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(108, 21, 'Permit document library', '/csr/site/compliance/controls/DocLibTab.js',
		'Credit360.Compliance.Controls.DocLibTab', 'Credit360.Compliance.Plugins.DocLibTab',
		'Shows document library for a permit item.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(109, 21, 'Permit scheduled actions tab', '/csr/site/compliance/controls/PermitScheduledActionsTab.js',
		'Credit360.Compliance.Controls.PermitScheduledActionsTab', 'Credit360.Compliance.Plugins.PermitScheduledActionsTab',
		'Shows permit scheduled actions.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(111, 1, 'Compliance Tab', '/csr/site/property/properties/controls/ComplianceTab.js',
		'Controls.ComplianceTab', 'Credit360.Property.Plugins.CompliancePlugin', 'Shows Compliance Legal Register.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(112, 19, 'Product Metric', '/csr/site/chain/manageProduct/controls/ProductMetricValTab.js',
		'Chain.ManageProduct.ProductMetricValTab', 'Credit360.Chain.Plugins.ProductMetricValPlugin', 'Product Metric tab.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(113, 21, 'Permit audit tab', '/csr/site/compliance/controls/AuditList.js',
		'Credit360.Compliance.Controls.AuditList', 'Credit360.Compliance.Plugins.AuditListPlugin', 'Shows permit audits.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(114, 22, 'Permit score', '/csr/site/compliance/permits/ScoreHeader.js',
		'Credit360.Compliance.Permits.ScoreHeader', 'Credit360.Compliance.Plugins.ScoreHeaderDto', 'This header shows some stuff.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(115, 20, 'Product supplier metric', '/csr/site/chain/manageProduct/controls/ProductSupplierMetricValTab.js',
		'Chain.ManageProduct.ProductSupplierMetricValTab', 'Credit360.Chain.Plugins.ProductSupplierMetricValPlugin', 'Product Supplier Metric tab.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(116, 10, 'Product list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductListPurchaserTab.js',
		'Chain.ManageCompany.ProductListPurchaserTab', 'Credit360.Chain.Plugins.ProductListDto', 'This tab shows the product list for a purchaser.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(117, 10, 'Product supplier list (Company)', '/csr/site/chain/manageCompany/controls/ProductSupplierListTab.js',
		'Chain.ManageCompany.ProductSupplierListTab', 'Credit360.Chain.Plugins.ProductSupplierListDto',
		'This tab shows the product supplier list for a company.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(118, 10, 'Product supplier list (Purchaser)', '/csr/site/chain/manageCompany/controls/ProductSupplierListPurchaserTab.js',
		'Chain.ManageCompany.ProductSupplierListPurchaserTab', 'Credit360.Chain.Plugins.ProductSupplierListDto',
		'This tab shows the product supplier list for a purchaser.');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(119, 10, 'Product supplier list (Supplier)', '/csr/site/chain/manageCompany/controls/ProductSupplierListSupplierTab.js',
		'Chain.ManageCompany.ProductSupplierListSupplierTab', 'Credit360.Chain.Plugins.ProductSupplierListDto',
		'This tab shows the product supplier list for a supplier.');

	/* BSCI now obsolete
	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(120, 10, 'BSCI supplier details', '/csr/site/chain/manageCompany/controls/BsciSupplierDetailsTab.js',
		'Chain.ManageCompany.BsciSupplierDetailsTab', 'Credit360.Chain.Plugins.BsciSupplierDetailsDto', 'This tab shows the BSCI details for a supplier.');
 
	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
	VALUES 
	(121, 13, 'BSCI supplier details', '/csr/site/audit/controls/BsciSupplierDetailsTab.js',
		'Audit.Controls.BsciSupplierDetailsTab', 'Credit360.Audit.Plugins.BsciSupplierDetailsDto',
		'This tab shows the current BSCI details for the company being audited.');
	*/

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, allow_multiple)
	VALUES 
	(122, 10, 'Integration supplier details', '/csr/site/chain/manageCompany/controls/IntegrationSupplierDetailsTab.js',
		'Chain.ManageCompany.IntegrationSupplierDetailsTab', 'Credit360.Chain.Plugins.IntegrationSupplierDetailsDto',
		'This tab shows the Integration details for a supplier.', 1);
		
	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES 
	(123, 13, 'Integration Question/Answers List', '/csr/site/audit/controls/IntegrationQuestionAnswerTab.js',
		'Audit.Controls.IntegrationQuestionAnswerTab', 'Credit360.Audit.Plugins.IntegrationQuestionAnswerList',
		'This tab shows question and answer records usually received via an integration',
		'/csr/shared/plugins/screenshots/audit_tab_iqa_list.png');

	INSERT INTO csr.plugin 
	(plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path)
	VALUES 
	(124, 1, 'Certifications', '/csr/site/property/properties/controls/CertificationsTab.js',
		'Controls.CertificationsTab', 'Credit360.Property.Plugins.CertificationsTab', 'Certifications Tab',null);
END;
/

COMMIT;
