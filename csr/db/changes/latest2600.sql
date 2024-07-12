-- Please update version.sql too -- this keeps clean builds in sync
define version=2600
@update_header

declare	
	v_old_full_audit_plugin_id	csr.plugin.plugin_id%TYPE;
begin
	--Add old audit plugin back in (csr.plugin_pkg.SetCorePlugin)
	INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
						details, preview_image_path, tab_sid, form_path)
		 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Full audit details tab',  '/csr/site/audit/controls/FullAuditTab.js', 'Audit.Controls.FullAuditTab', 
				 'Credit360.Audit.Plugins.FullAuditTab', 'This tab gives the original view of an audit, showing the executive summary, audit documents and non-compliances each in its own section.', '/csr/shared/plugins/screenshots/audit_tab_full_details.png', NULL, NULL)
	  RETURNING plugin_id INTO v_old_full_audit_plugin_id;
	
	--Add the old plugin where the new plugins exist
	INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, pos, tab_label)
		SELECT att.app_sid, att.internal_audit_type_id, 13, v_old_full_audit_plugin_id, 0, 'Audit details'
		  FROM csr.audit_type_tab att
		 WHERE att.plugin_id = (
			SELECT plugin_id
			  FROM csr.plugin
			 WHERE js_class = 'Audit.Controls.FindingTab'
		);

	--Remove the new plugins from audit tabs
	DELETE FROM csr.audit_type_tab
	 WHERE plugin_id IN (
		SELECT plugin_id
		  FROM csr.plugin
		 WHERE js_class IN (
			'Audit.Controls.Documents',
			'Audit.Controls.ExecutiveSummary',
			'Audit.Controls.FindingTab'
		 )
	);
end;
/

@..\audit_body

@update_tail
