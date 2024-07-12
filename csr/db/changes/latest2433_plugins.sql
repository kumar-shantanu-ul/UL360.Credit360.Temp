-- Please update version.sql too -- this keeps clean builds in sync
--define version=2428
--@update_header

CREATE OR REPLACE PACKAGE csr.latest_xxx_pkg
IS
	FUNCTION SetCorePlugin(
		in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
		in_js_class						IN  csr.plugin.js_class%TYPE,
		in_description					IN  csr.plugin.description%TYPE,
		in_js_include					IN  csr.plugin.js_include%TYPE,
		in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
		in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
		in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
		in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
		in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
	) RETURN plugin.plugin_id%TYPE;
END;
/

CREATE OR REPLACE PACKAGE BODY csr.latest_xxx_pkg
IS
	FUNCTION SetCorePlugin(
		in_plugin_type_id				IN 	csr.plugin.plugin_type_id%TYPE,
		in_js_class						IN  csr.plugin.js_class%TYPE,
		in_description					IN  csr.plugin.description%TYPE,
		in_js_include					IN  csr.plugin.js_include%TYPE,
		in_cs_class						IN  csr.plugin.cs_class%TYPE DEFAULT 'Credit360.Plugins.PluginDto',
		in_details						IN  csr.plugin.details%TYPE DEFAULT NULL,
		in_preview_image_path			IN  csr.plugin.preview_image_path%TYPE DEFAULT NULL,
		in_tab_sid						IN  csr.plugin.tab_sid%TYPE DEFAULT NULL,
		in_form_path					IN  csr.plugin.form_path%TYPE DEFAULT NULL
	) RETURN plugin.plugin_id%TYPE
	AS
		v_plugin_id		csr.plugin.plugin_id%TYPE;
	BEGIN
		BEGIN
			INSERT INTO plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
								details, preview_image_path, tab_sid, form_path)
				 VALUES (NULL, plugin_id_seq.nextval, in_plugin_type_id, in_description,  in_js_include, in_js_class, 
						 in_cs_class, in_details, in_preview_image_path, in_tab_sid, in_form_path)
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
END;
/

DECLARE 
	v_plugin_id		csr.plugin.plugin_id%TYPE;
BEGIN
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Actions',
		in_js_class => 'Chain.ManageCompany.IssuesPanel',
		in_js_include => '/csr/site/chain/manageCompany/controls/IssuesPanel.js',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_issues.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Delegations',
		in_js_class => 'Chain.ManageCompany.DelegationPanel',
		in_js_include => '/csr/site/chain/manageCompany/controls/DelegationPanel.js',
		in_cs_class => 'Credit360.Chain.Plugins.DelegationDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_delegations.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Questionnaires',
		in_js_class => 'Chain.ManageCompany.QuestionnaireList',
		in_js_include => '/csr/site/chain/manageCompany/controls/QuestionnaireList.js',
		in_cs_class => 'Credit360.Chain.Plugins.QuestionnaireListDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_questionnaires.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Supplier Audits',
		in_js_class => 'Chain.ManageCompany.SupplierAuditList',
		in_js_include => '/csr/site/chain/manageCompany/controls/SupplierAuditList.js',
		in_cs_class => 'Credit360.Chain.Plugins.SupplierAuditListDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_supplier_audits.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Data Collection',
		in_details => 'Shows delegations, questionnaires and supplier audits on a single tab',
		in_js_class => 'Chain.ManageCompany.DataCollection',
		in_js_include => '/csr/site/chain/manageCompany/controls/DataCollection.js',
		in_cs_class => 'Credit360.Chain.Plugins.DataCollectionDto',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_data_collection.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Messages',
		in_js_class => 'Chain.ManageCompany.MessagesTab',
		in_js_include => '/csr/site/chain/manageCompany/controls/MessagesTab.js',
		in_preview_image_path	=> '/csr/shared/plugins/screenshots/company_tab_messages.png'
	);
	
	v_plugin_id := csr.latest_xxx_pkg.SetCorePlugin(
		in_plugin_type_id => 10, -- Company tab
		in_description => 'Portlets',
		in_js_class => 'Chain.ManageCompany.PortalTab',
		in_js_include => '/csr/site/chain/manageCompany/controls/PortalTab.js',
		in_cs_class => 'Credit360.Chain.Plugins.PortalDto',
		in_details => 'This tab shows any portlets configured for regions (via /csr/site/portal/Region.acds), setting the region context for the portlets to be that of the company. Each tab configured shows as a separate tab in the company management page.'
	);

END;
/

DROP PACKAGE csr.latest_xxx_pkg;

--@update_tail
