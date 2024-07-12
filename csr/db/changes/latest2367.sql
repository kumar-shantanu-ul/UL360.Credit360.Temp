-- Please update version.sql too -- this keeps clean builds in sync
define version=2367
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***

-- *** Data changes ***
-- RLS

-- Data

-- fix the plugin type id for this one to be csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_HEAD as it seems to have been created incorrectly
UPDATE csr.plugin
   SET plugin_type_id = 11
 WHERE js_class = 'Chain.ManageCompany.ScoreHeader';
 
CREATE OR REPLACE FUNCTION csr.TEMP_SetCorePlugin(
	in_plugin_type_id				IN 	plugin.plugin_type_id%TYPE,
	in_js_class						IN  plugin.js_class%TYPE,
	in_description					IN  plugin.description%TYPE,
	in_js_include					IN  plugin.js_include%TYPE,
	in_cs_class						IN  plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
	in_details						IN  plugin.details%TYPE DEFAULT NULL,
	in_preview_image_path			IN  plugin.preview_image_path%TYPE DEFAULT NULL,
	in_tab_sid						IN  plugin.tab_sid%TYPE DEFAULT NULL,
	in_form_path					IN  plugin.form_path%TYPE DEFAULT NULL
) RETURN plugin.plugin_id%TYPE
AS
	v_plugin_id		plugin.plugin_id%TYPE;
BEGIN
	BEGIN
		INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
		  RETURNING plugin_id INTO v_plugin_id;
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE plugin 
		   SET description = in_description,
		   	   js_include = in_js_include,
		   	   cs_class = in_cs_class,
		   	   details = in_details,
		   	   preview_image_path = in_preview_image_path,
		   	   form_path = in_form_path
		 WHERE plugin_type_id = in_plugin_type_id
		   AND js_class = in_js_class
		   AND app_sid IS NULL
		   AND ((tab_sid IS NULL AND in_tab_sid IS NULL) OR (tab_sid = in_tab_sid))
	 		   RETURNING plugin_id INTO v_plugin_id;
	END;

	RETURN v_plugin_id;
END;
/
 
DECLARE
    v_plugin_id     csr.plugin.plugin_id%TYPE;
BEGIN
	/*Property*/
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.SpaceListMetricPanel',
		in_description			=> 'Spaces',
		in_js_include			=> '/csr/site/property/properties/controls/SpaceListMetricPanel.js',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_space_list_metric.png',
		in_details				=> 'This tab shows a list of spaces (sub-regions) at the selected property. It allows you to create new spaces, and set space metrics that have been configured for the chosen space type.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.DelegationPanel',
		in_description			=> 'Delegations tab',
		in_js_include			=> '/csr/site/property/properties/controls/DelegationPanel.js',
		in_cs_class				=> 'Credit360.Property.Plugins.DelegationDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_delegation.png',
		in_details				=> 'This tab shows any delegation forms that the logged in user needs to enter data or approve for the property they are viewing.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.IssuesPanel',
		in_description			=> 'Actions tab',
		in_js_include			=> '/csr/site/property/properties/controls/IssuesPanel.js',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_actions.png',
		in_details				=> 'This tab shows a list of actions (issues) associated with the property.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.SurveysTab',
		in_description			=> 'Property Surveys Tab',
		in_js_include			=> '/csr/site/property/properties/controls/surveysTab.js',
		in_cs_class				=> 'Credit360.Property.Plugins.SurveysTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_surveys.png',
		in_details				=> 'This tab shows the list of surveys the logged in user has access to for the property being viewed.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.InitiativesPanel',
		in_description			=> 'Initiatives',
		in_js_include			=> '/csr/site/property/properties/controls/InitiativesPanel.js',
		in_cs_class				=> 'Credit360.Plugins.InitiativesPlugin',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/property_tab_initiatives.png',
		in_details				=> 'This tab lists the initiatives associated with the property. It supports creating, exporting, importing the intiatives from within the tab.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 1, --csr.csr_data_pkg.PLUGIN_TYPE_PROPERTY_TAB,
		in_js_class				=> 'Controls.PortalTab',
		in_description			=> 'Portlets',
		in_js_include			=> '/csr/site/property/properties/controls/PortalTab.js',
		in_cs_class				=> 'Credit360.Property.Plugins.PortalDto',
		in_details				=> 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the property. Each tab configured shows as a separate tab in the property page.'
	);
	
	
	 v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 2, --csr.csr_data_pkg.PLUGIN_TYPE_FUND_FORM,
        in_js_class         => 'Credit360.plugins.ListEditorCMSPlugin',
        in_description      => 'ListEditor CMS Plugin',
        in_js_include       => '/csr/shared/plugins/ListEditorCMSPlugin.js',
        in_cs_class         => 'Credit360.Plugins.EmptyDto'
    );

    /* TEAMROOM */
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.SummaryPanel',
        in_description      => 'Summary',
        in_js_include       => '/csr/site/teamroom/controls/SummaryPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.DocumentsPanel',
        in_description      => 'Documents',
        in_js_include       => '/csr/site/teamroom/controls/DocumentsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.CalendarPanel',
        in_description      => 'Calendar',
        in_js_include       => '/csr/site/teamroom/controls/CalendarPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.IssuesPanel',
        in_description      => 'Actions',
        in_js_include       => '/csr/site/teamroom/controls/IssuesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 5, --csr.csr_data_pkg.PLUGIN_TYPE_TEAMROOM_TAB,
        in_js_class         => 'Teamroom.InitiativesPanel',
        in_description      => 'Projects',
        in_js_include       => '/csr/site/teamroom/controls/InitiativesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    
    /* INITIATIVES PAGE -- TODO: REMOVE TEAMROOM PREFIX and change PLUGIN_TYPE_TMRM_INIT_TAB => PLUGIN_TYPE_INITIATIVE_TAB? */
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Credit360.Initiatives.SummaryPanel',
        in_description      => 'Summary',
        in_js_include       => '/csr/site/initiatives/detail/controls/SummaryPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Credit360.Initiatives.DocumentsPanel',
        in_description      => 'Documents',
        in_js_include       => '/csr/site/initiatives/detail/controls/DocumentsPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Credit360.Initiatives.CalendarPanel',
        in_description      => 'Calendar',
        in_js_include       => '/csr/site/initiatives/detail/controls/CalendarPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   => 8, --csr.csr_data_pkg.PLUGIN_TYPE_TMRM_INIT_TAB,
        in_js_class         => 'Credit360.Initiatives.IssuesPanel',
        in_description      => 'Actions',
        in_js_include       => '/csr/site/initiatives/detail/controls/IssuesPanel.js',
        in_cs_class         => 'Credit360.Plugins.PluginDto'
    );
	
	/*Chain Company*/
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 10,-- csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB,
		in_js_class				=> 'Chain.ManageCompany.ActivityListTab',
		in_description			=> 'Activity List',
		in_js_include			=> '/csr/site/chain/managecompany/controls/ActivityListTab.js',
		in_cs_class				=> 'Credit360.Chain.CompanyManagement.ActivityListTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_activity_list.png',
		in_details				=> 'This tab displays a filterable/searchable table of all activities raised against the supplier being viewed, that the logged in user has permission to see.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB,
		in_js_class				=> 'Chain.ManageCompany.ActivitySummaryTab',
		in_description			=> 'Activity Summary',
		in_js_include			=> '/csr/site/chain/managecompany/controls/ActivitySummaryTab.js',
		in_cs_class				=> 'Credit360.Chain.CompanyManagement.ActivitySummaryTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_activity_summary.png',
		in_details				=> 'This tab displays a summary of upcoming/overdue activities for a supplier, that required the logged in user to set the outcome of.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB,
		in_js_class				=> 'Chain.ManageCompany.CalendarTab', 
		in_description			=> 'Activity Calendar', 
		in_js_include			=> '/csr/site/chain/managecompany/controls/CalendarTab.js', 
		in_cs_class				=> 'Credit360.Chain.CompanyManagement.CalendarTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_calendar.png',
		in_details				=> 'This tab displays a calendar that can show activities relating to the supplier being viewed.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB,
		in_js_class				=> 'Chain.ManageCompany.ProductTypesTab',
		in_description			=> 'Product types',
		in_js_include			=> '/csr/site/chain/managecompany/controls/ProductTypesTab.js',
		in_cs_class				=> 'Credit360.Chain.CompanyManagement.ProductTypesTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_product_types.png',
		in_details				=> 'This tab shows the product types that a supplier supplies, and providing the user has the write capability for products, it will also let the user edit the list.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 10, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_TAB,
		in_js_class				=> 'Chain.ManageCompany.SupplierList',
		in_description			=> 'Supplier list',
		in_js_include			=> '/csr/site/chain/managecompany/controls/SupplierList.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.SupplierListDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_suppliers.png',
		in_details				=> 'This tab shows the suppliers of the company being viewed as a list, and allows drill down to view the company management page for the chosen supplier.'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 11, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_HEAD,
		in_js_class				=> 'Chain.ManageCompany.ScoreHeader',
		in_description			=> 'Score header for company management page',
		in_js_include			=> '/csr/site/chain/managecompany/controls/ScoreHeader.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.ScoreHeaderDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_header_scores.png',
		in_details				=> 'This header shows any survey scores for the supplier, and allows the user to set the score if it has been configured to allow manual editing (via /csr/site/quicksurvey/admin/thresholds/list.acds).'
	);
	
	v_plugin_id := csr.TEMP_SetCorePlugin(
		in_plugin_type_id		=> 11, --csr.csr_data_pkg.PLUGIN_TYPE_CHAIN_COMPANY_HEAD,
		in_js_class				=> 'Chain.ManageCompany.IndicatorsHeader',
		in_description			=> 'Company management indicators',
		in_js_include			=> '/csr/site/chain/managecompany/controls/IndicatorsHeader.js',
		in_cs_class				=> 'Credit360.Chain.Plugins.ChainIndicatorPluginDto',
		in_details				=> 'This plugin gives the ability to show some indicator values associated with the company in the header panel.'
	);
	
	/*Audit*/
    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id   	=> 13, --csr.csr_data_pkg.PLUGIN_TYPE_AUDIT_TAB,
        in_js_class         	=> 'Audit.Controls.FullAuditTab',
        in_description      	=> 'Full audit details tab',
        in_js_include       	=> '/csr/site/audit/controls/FullAuditTab.js',
        in_cs_class         	=> 'Credit360.Audit.Plugins.FullAuditTab',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/audit_tab_full_details.png',
		in_details				=> 'This tab gives the original view of an audit, showing the executive summary, audit documents and non-compliances each in its own section.'
    );

    v_plugin_id := csr.TEMP_SetCorePlugin(
        in_plugin_type_id  		=> 14, --csr.csr_data_pkg.PLUGIN_TYPE_AUDIT_HEADER,
        in_js_class        		=> 'Audit.Controls.FullAuditHeader',
        in_description     		=> 'Full audit details header',
        in_js_include      		=> '/csr/site/audit/controls/FullAuditHeader.js',
        in_cs_class        		=> 'Credit360.Audit.Plugins.FullAuditHeader',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/audit_header_full_details.png',
		in_details				=> 'This header gives the original view of an audit, showing the audit region and date, auditor organisation, audit type, workflow status, closure results, audit notes and a link to the audit survey.'
    );

END;
/

DROP FUNCTION csr.TEMP_SetCorePlugin;

 

-- ** New package grants **

-- *** Packages ***
@..\quick_survey_pkg
@..\campaign_pkg
@..\plugin_pkg
@..\property_pkg
@..\chain\company_pkg
@..\audit_pkg

@..\quick_survey_body
@..\campaign_body
@..\plugin_body
@..\calendar_body
@..\property_body
@..\audit_body
@..\chain\setup_body
@..\chain\company_body

@update_tail
