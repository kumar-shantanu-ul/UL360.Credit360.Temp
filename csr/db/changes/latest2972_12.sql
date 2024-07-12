-- Please update version.sql too -- this keeps clean builds in sync
define version=2972
define minor_version=12
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
declare
	v_num number;
begin
	select csr.plugin_id_seq.nextval into v_num from dual;
	if v_num < 10000 then
		execute immediate 'drop sequence csr.plugin_id_seq';
		execute immediate 'create sequence csr.plugin_id_seq start with 10000 nocache';
		execute immediate 'grant select on csr.plugin_Id_seq to csrimp';
	end if;
end;
/

alter table csr.non_comp_default_issue drop constraint CHK_NON_COMP_DEF_ISS_DUE_UNIT;
alter table csr.non_comp_default_issue add
	CONSTRAINT CHK_NON_COMP_DEF_ISS_DUE_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m'));
alter table csrimp.non_comp_default_issue drop constraint CHK_NON_COMP_DEF_ISS_DUE_UNIT;
alter table csrimp.non_comp_default_issue add
	CONSTRAINT CHK_NON_COMP_DEF_ISS_DUE_UNIT CHECK (DUE_DTM_RELATIVE_UNIT IN ('d','m'));

alter TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION drop
	CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK ;
alter TABLE CSRIMP.QUICK_SURVEY_EXPR_ACTION add
    CONSTRAINT CHK_QS_EXPR_ACTION_TYPE_FK CHECK (
	(ACTION_TYPE = 'nc' AND QS_EXPR_NON_COMPL_ACTION_ID IS NOT NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'msg' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NOT NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NOT NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'mand_q' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NOT NULL AND SHOW_PAGE_ID IS NULL)
	OR
	(ACTION_TYPE = 'show_p' AND QS_EXPR_NON_COMPL_ACTION_ID IS NULL
	  AND QS_EXPR_MSG_ACTION_ID IS NULL AND SHOW_QUESTION_ID IS NULL
	  AND MANDATORY_QUESTION_ID IS NULL AND SHOW_PAGE_ID IS NOT NULL)
    );
 
drop index CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ;
CREATE UNIQUE INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ON CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE (
		CSRIMP_SESSION_ID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID, SCORE_TYPE_AGG_TYPE_ID); 

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
begin
	begin
		INSERT INTO csr.plugin_type
			(plugin_type_id, description)
		VALUES
			(17, 'Emission factor tab');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

declare
	procedure sp(
		in_plugin_id					IN	csr.plugin.plugin_id%TYPE,
		in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
		in_description					IN  csr.plugin.description%TYPE,
		in_js_include					IN  csr.plugin.js_include%TYPE,
		in_js_class						IN  csr.plugin.js_class%TYPE,
		in_cs_class						IN  csr.plugin.cs_class%TYPE,
		in_details						IN  csr.plugin.details%TYPE,
		in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE,
		in_r_script_path				IN	csr.plugin.r_script_path%TYPE
	)
	as
		v_plugin_id						csr.plugin.plugin_id%type;
		v_cnt							number;
	begin
		v_plugin_id := in_plugin_id;
		select count(*) into v_cnt from csr.plugin where plugin_id = in_plugin_id;
		if v_cnt > 0 then
			select count(*) into v_cnt from csr.plugin where plugin_id = in_plugin_id and plugin_type_id = in_plugin_type_id and js_class = in_js_class and app_sid is null;
			if v_cnt = 0 then
				select csr.plugin_id_seq.nextval into v_plugin_id from dual;
			end if;
		end if;
	
		begin
			INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
				details, preview_image_path, r_script_path)
			VALUES (NULL, v_plugin_id, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
				in_cs_class, in_details, in_preview_image_path, in_r_script_path);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.plugin 
				   SET description = in_description,
					   js_include = in_js_include,
					   cs_class = in_cs_class,
					   details = in_details,
					   preview_image_path = in_preview_image_path,
					   r_script_path = in_r_script_path
				 WHERE plugin_type_id = in_plugin_type_id
				   AND js_class = in_js_class
				   AND app_sid IS NULL;
		end;
	end;
begin
	sp(1, 2, 'ListEditor CMS Plugin', '/csr/shared/plugins/ListEditorCMSPlugin.js', 'Credit360.plugins.ListEditorCMSPlugin', 'Credit360.Plugins.EmptyDto', '', '', '');
	sp(2, 1, 'Spaces', '/csr/site/property/properties/controls/SpaceListMetricPanel.js', 'Controls.SpaceListMetricPanel', 'Credit360.Plugins.PluginDto', 'This tab shows a list of spaces (sub-regions) at the selected property. It allows you to create new spaces, and set space metrics that have been configured for the chosen space type.', '/csr/shared/plugins/screenshots/property_tab_space_list_metric.png', '');
	sp(3, 1, 'Delegations tab', '/csr/site/property/properties/controls/DelegationPanel.js', 'Controls.DelegationPanel', 'Credit360.Property.Plugins.DelegationDto', 'This tab shows any delegation forms that the logged in user needs to enter data or approve for the property they are viewing.', '/csr/shared/plugins/screenshots/property_tab_delegation.png', '');
	sp(4, 4, 'My feed', '/csr/site/activity/controls/MyFeedPanel.js', 'Activity.MyFeedPanel', 'Credit360.UserProfile.MyFeedDto', '', '', '');
	sp(5, 4, 'My activities', '/csr/site/activity/controls/MyActivitiesPanel.js', 'Activity.MyActivitiesPanel', 'Credit360.UserProfile.MyActivitiesDto', '', '', '');
	sp(6, 1, 'Actions tab', '/csr/site/property/properties/controls/IssuesPanel.js', 'Controls.IssuesPanel', 'Credit360.Plugins.PluginDto', 'This tab shows a list of actions (issues) associated with the property.', '/csr/shared/plugins/screenshots/property_tab_actions.png', '');
	sp(7, 5, 'Summary', '/csr/site/teamroom/controls/SummaryPanel.js', 'Teamroom.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(8, 5, 'Documents', '/csr/site/teamroom/controls/DocumentsPanel.js', 'Teamroom.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(9, 5, 'Calendar', '/csr/site/teamroom/controls/CalendarPanel.js', 'Teamroom.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(10, 5, 'Actions', '/csr/site/teamroom/controls/IssuesPanel.js', 'Teamroom.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(11, 5, 'Projects', '/csr/site/teamroom/controls/InitiativesPanel.js', 'Teamroom.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin', '', '', '');
	sp(12, 8, 'Details', '/csr/site/initiatives/detail/controls/SummaryPanel.js', 'Credit360.Initiatives.SummaryPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(13, 8, 'Documents', '/csr/site/initiatives/detail/controls/DocumentsPanel.js', 'Credit360.Initiatives.DocumentsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(14, 8, 'Calendar', '/csr/site/initiatives/detail/controls/CalendarPanel.js', 'Credit360.Initiatives.CalendarPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(15, 8, 'Actions', '/csr/site/initiatives/detail/controls/IssuesPanel.js', 'Credit360.Initiatives.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(16, 1, 'Property Surveys Tab', '/csr/site/property/properties/controls/surveysTab.js', 'Controls.SurveysTab', 'Credit360.Property.Plugins.SurveysTab', 'This tab shows the list of surveys the logged in user has access to for the property being viewed.', '/csr/shared/plugins/screenshots/property_tab_surveys.png', '');
	sp(17, 1, 'Initiatives', '/csr/site/property/properties/controls/InitiativesPanel.js', 'Controls.InitiativesPanel', 'Credit360.Plugins.InitiativesPlugin', 'This tab lists the initiatives associated with the property. It supports creating, exporting, importing the intiatives from within the tab.', '/csr/shared/plugins/screenshots/property_tab_initiatives.png', '');
	sp(18, 10, 'Supplier list', '/csr/site/chain/managecompany/controls/SupplierListTab.js', 'Chain.ManageCompany.SupplierListTab', 'Credit360.Chain.Plugins.SupplierListDto', 'This tab shows the suppliers of the company being viewed as a list, and allows drill down to view the company management page for the chosen supplier.', '/csr/shared/plugins/screenshots/company_tab_suppliers.png', '');
	sp(19, 10, 'Activity Summary', '/csr/site/chain/managecompany/controls/ActivitySummaryTab.js', 'Chain.ManageCompany.ActivitySummaryTab', 'Credit360.Chain.CompanyManagement.ActivitySummaryTab', 'This tab displays a summary of upcoming/overdue activities for a supplier, that required the logged in user to set the outcome of.', '/csr/shared/plugins/screenshots/company_tab_activity_summary.png', '');
	sp(20, 10, 'Activity List', '/csr/site/chain/managecompany/controls/ActivityListTab.js', 'Chain.ManageCompany.ActivityListTab', 'Credit360.Chain.CompanyManagement.ActivityListTab', 'This tab displays a filterable/searchable table of all activities raised against the supplier being viewed, that the logged in user has permission to see.', '/csr/shared/plugins/screenshots/company_tab_activity_list.png', '');
	sp(21, 11, 'Score header for company management page', '/csr/site/chain/managecompany/controls/ScoreHeader.js', 'Chain.ManageCompany.ScoreHeader', 'Credit360.Chain.Plugins.ScoreHeaderDto', 'This header shows any survey scores for the supplier, and allows the user to set the score if it has been configured to allow manual editing (via /csr/site/quicksurvey/admin/thresholds/list.acds).', '/csr/shared/plugins/screenshots/company_header_scores.png', '');
	sp(22, 10, 'Activity Calendar', '/csr/site/chain/managecompany/controls/CalendarTab.js', 'Chain.ManageCompany.CalendarTab', 'Credit360.Chain.CompanyManagement.CalendarTab', 'This tab displays a calendar that can show activities relating to the supplier being viewed.', '/csr/shared/plugins/screenshots/company_tab_calendar.png', '');
	sp(23, 12, 'Audits', '/csr/shared/calendar/includes/audits.js', 'Credit360.Calendars.Audits', 'Credit360.Audit.AuditCalendarDto', '', '', '');
	sp(24, 12, 'Events', '/csr/shared/calendar/includes/initiatives.js', 'Credit360.Calendars.Initiatives', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(25, 12, 'Issues coming due', '/csr/shared/calendar/includes/issues.js', 'Credit360.Calendars.Issues', 'Credit360.Issues.IssueCalendarDto', '', '', '');
	sp(26, 12, 'Teamroom events', '/csr/shared/calendar/includes/teamrooms.js', 'Credit360.Calendars.Teamrooms', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(27, 12, 'Activities', '/csr/shared/calendar/includes/activities.js', 'Credit360.Calendars.Activities', 'Credit360.Chain.Activities.ActivityCalendarDto', '', '', '');
	sp(28, 12, 'Teamroom actions', '/csr/site/teamroom/controls/calendar/issues.js', 'Teamroom.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(29, 12, 'Actions', '/csr/site/initiatives/calendar/issues.js', 'Credit360.Initiatives.Calendars.Issues', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(30, 11, 'Company management indicators', '/csr/site/chain/managecompany/controls/IndicatorsHeader.js', 'Chain.ManageCompany.IndicatorsHeader', 'Credit360.Chain.Plugins.ChainIndicatorPluginDto', 'This plugin gives the ability to show some indicator values associated with the company in the header panel.', '', '');
	sp(31, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js', 'Controls.PortalTab', 'Credit360.Property.Plugins.PortalDto', 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the property. Each tab configured shows as a separate tab in the property page.', '', '');
	sp(32, 10, 'Product types', '/csr/site/chain/managecompany/controls/ProductTypesTab.js', 'Chain.ManageCompany.ProductTypesTab', 'Credit360.Chain.CompanyManagement.ProductTypesTab', 'This tab shows the product types that a supplier supplies, and providing the user has the write capability for products, it will also let the user edit the list.', '/csr/shared/plugins/screenshots/company_tab_product_types.png', '');
	sp(33, 14, 'Full audit details header', '/csr/site/audit/controls/FullAuditHeader.js', 'Audit.Controls.FullAuditHeader', 'Credit360.Audit.Plugins.FullAuditHeader', 'This header gives the original view of an audit, showing the audit region and date, auditor organisation, audit type, workflow status, closure results, audit notes and a link to the audit survey.', '/csr/shared/plugins/screenshots/audit_header_full_details.png', '');
	sp(34, 1, 'Chemicals Inventory', '/csr/site/property/properties/controls/ChemicalInventoryTab.js', 'Controls.ChemicalInventoryTab', 'Credit360.Plugins.PluginDto', 'This tab shows a list chemicals associated with the property.', '', '');
	sp(35, 10, 'Actions', '/csr/site/chain/manageCompany/controls/IssuesPanel.js', 'Chain.ManageCompany.IssuesPanel', 'Credit360.Plugins.PluginDto', '', '/csr/shared/plugins/screenshots/company_tab_issues.png', '');
	sp(36, 10, 'Delegations', '/csr/site/chain/manageCompany/controls/DelegationPanel.js', 'Chain.ManageCompany.DelegationPanel', 'Credit360.Chain.Plugins.DelegationDto', '', '/csr/shared/plugins/screenshots/company_tab_delegations.png', '');
	sp(37, 10, 'Questionnaires', '/csr/site/chain/manageCompany/controls/QuestionnaireList.js', 'Chain.ManageCompany.QuestionnaireList', 'Credit360.Chain.Plugins.QuestionnaireListDto', '', '/csr/shared/plugins/screenshots/company_tab_questionnaires.png', '');
	sp(38, 10, 'Supplier Audits', '/csr/site/chain/manageCompany/controls/SupplierAuditList.js', 'Chain.ManageCompany.SupplierAuditList', 'Credit360.Chain.Plugins.SupplierAuditListDto', '', '/csr/shared/plugins/screenshots/company_tab_supplier_audits.png', '');
	sp(39, 10, 'Data Collection', '/csr/site/chain/manageCompany/controls/DataCollection.js', 'Chain.ManageCompany.DataCollection', 'Credit360.Chain.Plugins.DataCollectionDto', 'Shows delegations, questionnaires and supplier audits on a single tab', '/csr/shared/plugins/screenshots/company_tab_data_collection.png', '');
	sp(40, 10, 'Messages', '/csr/site/chain/manageCompany/controls/MessagesTab.js', 'Chain.ManageCompany.MessagesTab', 'Credit360.Plugins.PluginDto', '', '/csr/shared/plugins/screenshots/company_tab_messages.png', '');
	sp(41, 10, 'Portlets', '/csr/site/chain/manageCompany/controls/PortalTab.js', 'Chain.ManageCompany.PortalTab', 'Credit360.Chain.Plugins.PortalDto', 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the company. Each tab configured shows as a separate tab in the company management page.', '', '');
	sp(42, 1, 'Enhesa Regulatory Monitoring', '/csr/site/property/properties/controls/EnhesaTopicsTab.js', 'Controls.EnhesaTopicsTab', 'Credit360.Property.Plugins.EnhesaTopicsTab', 'This tab shows a list of Enhesa Regulatory Monitoring topics for a property.', '/csr/shared/plugins/screenshots/property_tab_enhesa_topics.png', '');
	sp(43, 10, 'Subsidiaries', '/csr/site/chain/manageCompany/controls/SubsidiaryTab.js', 'Chain.ManageCompany.SubsidiaryTab', 'Credit360.Chain.Plugins.SubsidiaryDto', 'This tab shows the subsidiaries of the selected company, and given the correct permissions, will allow adding new subsidiaries.', '', '');
	sp(44, 10, 'Supply Chain Graph', '/csr/site/chain/manageCompany/controls/CompaniesGraph.js', 'Chain.ManageCompany.CompaniesGraph', 'Credit360.Chain.Plugins.CompaniesGraphDto', 'This tab shows a graph of the supply chain for the selected company.', '', '');
	sp(45, 10, 'Company users', '/csr/site/chain/manageCompany/controls/CompanyUsers.js', 'Chain.ManageCompany.CompanyUsers', 'Credit360.Chain.Plugins.CompanyUsersDto', 'This tab shows the users of the selected company, and given the correct permissions, will allow updateding / adding new users.', '', '');
	sp(46, 10, 'Company details', '/csr/site/chain/manageCompany/controls/CompanyDetails.js', 'Chain.ManageCompany.CompanyDetails', 'Credit360.Chain.Plugins.CompanyDetailsDto', 'This tab allows editing of the core company details such as address.', '', '');
	sp(47, 10, 'Relationships', '/csr/site/chain/manageCompany/controls/RelationshipsTab.js', 'Chain.ManageCompany.RelationshipsTab', 'Credit360.Chain.Plugins.RelationshipsTabDto', 'This tab allows adding/removing relationships to a company.', '', '');
	sp(48, 10, 'Business Relationships', '/csr/site/chain/manageCompany/controls/BusinessRelationships.js', 'Chain.ManageCompany.BusinessRelationships', 'Credit360.Chain.Plugins.BusinessRelationshipsDto', 'This tab shows the business relationships for a company.', '', '');
	sp(49, 10, 'My Details', '/csr/site/chain/manageCompany/controls/MyDetailsTab.js', 'Chain.ManageCompany.MyDetailsTab', 'Credit360.Chain.Plugins.MyDetailsDto', 'This tab allows a user to maintain their personal details. This tab would normally only be used when looking at your own company.', '', '');
	sp(50, 13, 'Findings', '/csr/site/audit/controls/FindingTab.js', 'Audit.Controls.FindingTab', 'Credit360.Audit.Plugins.FindingTab', 'Findings', '', '');
	sp(51, 13, 'Finding score summary', '/csr/site/audit/controls/NcScoreSummaryTab.js', 'Audit.Controls.NcScoreSummaryTab', 'Credit360.Audit.Plugins.NcScoreSummaryTab', 'Summarises the findings score for the audit, broken down by finding type', '', '');
	sp(52, 13, 'Documents', '/csr/site/audit/controls/DocumentsTab.js', 'Audit.Controls.Documents', 'Credit360.Audit.Plugins.FullAuditTab', 'Documents', '', '');
	sp(53, 13, 'Executive Summary', '/csr/site/audit/controls/ExecutiveSummaryTab.js', 'Audit.Controls.ExecutiveSummary', 'Credit360.Audit.Plugins.FullAuditTab', 'Executive Summary', '', '');
	sp(54, 13, 'Audit Log', '/csr/site/audit/controls/AuditLogTab.js', 'Audit.Controls.AuditLog', 'Credit360.Audit.Plugins.FullAuditTab', 'Audit Log', '', '');
	sp(55, 13, 'Full audit details tab', '/csr/site/audit/controls/FullAuditTab.js', 'Audit.Controls.FullAuditTab', 'Credit360.Audit.Plugins.FullAuditTab', 'This tab gives the original view of an audit, showing the executive summary, audit documents and non-compliances each in its own section.', '/csr/shared/plugins/screenshots/audit_tab_full_details.png', '');
	sp(56, 12, 'Course schedules', '/csr/shared/calendar/includes/training.js', 'Credit360.Calendars.Training', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(57, 1, 'Portlets', '/csr/site/property/properties/controls/PortalTab.js', 'Portlets', 'Credit360.Property.Plugins.PortalDto', '', '', '');
	sp(58, 6, 'Settings', '/csr/site/teamroom/controls/edit/SettingsPanel.js', 'MarksAndSpencer.Teamroom.Edit.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(59, 7, 'Settings', '/csr/site/teamroom/controls/mainTab/SettingsPanel.js', 'MarksAndSpencer.Teamroom.MainTab.SettingsPanel', 'Credit360.Plugins.PluginDto', '', '', '');
	sp(60, 1, 'Meter Raw Data', '/csr/site/property/properties/controls/MeterRawDataTab.js', 'Controls.MeterRawDataTab', 'Credit360.Plugins.PluginDto', 'This tab shows raw data for real time metering.', '', '');
	sp(61, 8, 'Audit Log', '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel', 'Credit360.Plugins.PluginDto', 'Audit Log', '', '');
	sp(62, 13, 'Finding List', '/csr/site/audit/controls/NonComplianceListTab.js', 'Audit.Controls.NonComplianceListTab', 'Credit360.Audit.Plugins.NonComplianceList', 'This tab shows a filterable list of findings.', '', '');
	sp(63, 13, 'Survey List', '/csr/site/audit/controls/SurveysTab.js', 'Audit.Controls.SurveysTab', 'Credit360.Audit.Plugins.SurveysTab', 'This tab shows a list of surveys against an audit.  It is intended for customers who have purchased the "multiple audit surveys" feature.', '', '');
	sp(64, 1, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterListTab', 'Credit360.Metering.Plugins.MeterList', 'Quick Charts tab for meter data', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');
	sp(65, 15, 'Validation report', '/csr/site/rreports/reports/Validation.js', 'Credit360.RReports.Validation', 'Credit360.RReports.Runners.ValidationReportRunner', '', '', '/csr/rreports/validation_V5/validation_V5.R');
	sp(66, 16, 'Raw meter data', '/csr/site/meter/controls/meterRawDataTab.js', 'Credit360.Metering.MeterRawDataTab', 'Credit360.Metering.Plugins.MeterRawData', 'Display, filter, search, and export raw readings for the meter.', '/csr/shared/plugins/screenshots/meter_raw_data.png', '');
	sp(67, 16, 'Meter data quick chart', '/csr/site/meter/controls/meterListTab.js', 'Credit360.Metering.MeterQuickChartTab', 'Credit360.Metering.Plugins.MeterQuickChartTab', 'Display data for the meter in a calendar view, chart, list, or pivot table.', '/csr/shared/plugins/screenshots/property_tab_meter_list.png', '');
	sp(68, 16, 'Meter audit log', '/csr/site/meter/controls/AuditLogTab.js', 'Credit360.Metering.AuditLogTab', 'Credit360.Metering.Plugins.AuditLogTab', 'Log changes to the meter region and any patches made to the meter data.', '/csr/shared/plugins/screenshots/meter_audit_log_tab.png', '');
	sp(69, 16, 'Actions tab', '/csr/site/meter/controls/IssuesTab.js', 'Credit360.Metering.IssuesTab', 'Credit360.Plugins.PluginDto', 'Show all actions associated with the meter, and raise new actions.', '/csr/shared/plugins/screenshots/meter_issue_list_tab.png', '');
	sp(70, 16, 'Hi-res chart', '/csr/site/meter/controls/meterHiResChartTab.js', 'Credit360.Metering.MeterHiResChartTab', 'Credit360.Metering.Plugins.MeterHiResChart', 'Display a detailed interactive chart showing all inputs for the meter, and patch data for the meter.', '/csr/shared/plugins/screenshots/meter_hi_res_chart.png', '');
	sp(71, 16, 'Low-res chart', '/csr/site/meter/controls/meterLowResChartTab.js', 'Credit360.Metering.MeterLowResChartTab', 'Credit360.Metering.Plugins.MeterLowResChart', 'Display a simple chart showing total and average consumption for the lifetime of the meter.', '/csr/shared/plugins/screenshots/meter_low_res_chart.png', '');
	sp(72, 16, 'Readings', '/csr/site/meter/controls/meterReadingTab.js', 'Credit360.Metering.MeterReadingTab', 'Credit360.Metering.Plugins.MeterReading', 'Enter readings and check percentage tolerances.', '/csr/shared/plugins/screenshots/meter_readings.png', '');
	sp(73, 16, 'Meter Characteristics', '/csr/site/meter/controls/meterCharacteristicsTab.js', 'Credit360.Metering.MeterCharacteristicsTab', 'Credit360.Metering.Plugins.MeterCharacteristics', 'Edit meter data.', '', '');
	sp(74, 17, 'Emissions profiles', '/csr/site/admin/emissionFactors/controls/EmissionProfilesTab.js', 'Controls.EmissionProfilesTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage emission factor profiles.', '', '');
	sp(75, 17, 'Map indicators', '/csr/site/admin/emissionFactors/controls/MapIndicatorsTab.js', 'Credit360.EmissionFactors.MapIndicatorsTab', 'Credit360.Plugins.PluginDto', 'This tab will hold the options to manage the emission factor indicator mappings.', '', '');
	sp(76, 8, 'Initiative details - What', '/csr/site/initiatives/detail/controls/WhatPanel.js', 'Credit360.Initiatives.Plugins.WhatPanel', 'Credit360.Plugins.PluginDto', 'Contains core details about the initiative, including the name, reference, project type and description.', '/csr/shared/plugins/screenshots/initiative_tab_what.png', '');
	sp(77, 8, 'Initiative details - Where', '/csr/site/initiatives/detail/controls/WherePanel.js', 'Credit360.Initiatives.Plugins.WherePanel', 'Credit360.Plugins.PluginDto', 'Contains location information about the initiative, i.e. the regions the initiative will apply to.', '/csr/shared/plugins/screenshots/initiative_tab_where.png', '');
	sp(78, 8, 'Initiative details - When', '/csr/site/initiatives/detail/controls/WhenPanel.js', 'Credit360.Initiatives.Plugins.WhenPanel', 'Credit360.Plugins.PluginDto', 'Contains timing information about when the initiative will run.', '/csr/shared/plugins/screenshots/initiative_tab_when.png', '');
	sp(79, 8, 'Initiative details - Why', '/csr/site/initiatives/detail/controls/WhyPanel.js', 'Credit360.Initiatives.Plugins.WhyPanel', 'Credit360.Plugins.PluginDto', 'Contains metrics about the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_why.png', '');
	sp(80, 8, 'Initiative details - Who', '/csr/site/initiatives/detail/controls/WhoPanel.js', 'Credit360.Initiatives.Plugins.WhoPanel', 'Credit360.Plugins.PluginDto', 'Contains details of who is involved with the initiative.', '/csr/shared/plugins/screenshots/initiative_tab_who.png', '');
	sp(81, 8, 'Initiative details', '/csr/site/initiatives/detail/controls/InitiativeDetailsPanel.js', 'Credit360.Initiatives.Plugins.InitiativeDetailsPanel', 'Credit360.Plugins.PluginDto', 'Contains all the details of the initiative in one tab (use this instead of the individual what, where, when, why, who tabs).', '/csr/shared/plugins/screenshots/initiative_tab_initiative_details.png', '');
	sp(82, 10, 'Supplier followers', '/csr/site/chain/manageCompany/controls/SupplierFollowersTab.js', 'Chain.ManageCompany.SupplierFollowersTab', 'Credit360.Chain.Plugins.SupplierFollowersDto', 'This tab shows the followers of the selected company, and given the correct permissions, will allow adding/removing followers.', '', '');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
