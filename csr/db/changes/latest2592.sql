-- Please update version.sql too -- this keeps clean builds in sync
define version=2592
@update_header

declare
	v_documents_plugin_id		csr.plugin.plugin_id%TYPE;
	v_ex_summary_plugin_id		csr.plugin.plugin_id%TYPE;
	v_findings_plugin_id		csr.plugin.plugin_id%TYPE;
	v_audit_log_plugin_id		csr.plugin.plugin_id%TYPE;
	
	v_old_full_audit_plugin_id	csr.plugin.plugin_id%TYPE;
begin
	--Add Documents plugin (csr.plugin_pkg.SetCorePlugin)
	INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
						details, preview_image_path, tab_sid, form_path)
		 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Documents',  '/csr/site/audit/controls/DocumentsTab.js', 'Audit.Controls.Documents', 
				 'Credit360.Audit.Plugins.FullAuditTab', 'Documents', NULL, NULL, NULL)
	  RETURNING plugin_id INTO v_documents_plugin_id;
	
	--Add Executive Summary plugin (csr.plugin_pkg.SetCorePlugin)
	INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
					details, preview_image_path, tab_sid, form_path)
		 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Executive Summary',  '/csr/site/audit/controls/ExecutiveSummaryTab.js', 'Audit.Controls.ExecutiveSummary', 
				 'Credit360.Audit.Plugins.FullAuditTab', 'Executive Summary', NULL, NULL, NULL)
	  RETURNING plugin_id INTO v_ex_summary_plugin_id;
	
	--Add Audit Log plugin (csr.plugin_pkg.SetCorePlugin)
	INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
					details, preview_image_path, tab_sid, form_path)
		 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Audit Log',  '/csr/site/audit/controls/AuditLogTab.js', 'Audit.Controls.AuditLog', 
				 'Credit360.Audit.Plugins.FullAuditTab', 'Audit Log', NULL, NULL, NULL)
	  RETURNING plugin_id INTO v_audit_log_plugin_id;
	
	SELECT p2.plugin_id
	  INTO v_findings_plugin_id
	  FROM csr.plugin p2
	 WHERE p2.js_class = 'Audit.Controls.FindingTab';
	
	SELECT plugin_id
	  INTO v_old_full_audit_plugin_id
	  FROM csr.plugin p
	 WHERE p.js_include = '/csr/site/audit/controls/FullAuditTab.js';

	--Make room for the new plugins
	UPDATE csr.audit_type_tab a
	   SET a.pos = a.pos + 2
	 WHERE a.plugin_id <> v_old_full_audit_plugin_id
	   AND EXISTS (
		SELECT app_sid, internal_audit_type_id
		  FROM csr.audit_type_tab b
		 WHERE b.plugin_id = v_old_full_audit_plugin_id
		   AND b.app_sid = a.app_sid
		   AND b.internal_audit_type_id = a.internal_audit_type_id
	  );
	
	--Add the new plugins where the old plugin existed (csr.audit_pkg.SetAuditTab)
	INSERT INTO csr.audit_type_tab (app_sid, internal_audit_type_id, plugin_type_id, plugin_id, pos, tab_label)
		SELECT att.app_sid, att.internal_audit_type_id, 13, natt.plugin_id, natt.pos, natt.tab_label 
		  FROM csr.audit_type_tab att
		  JOIN (
			--These are the newly added plugins, plus the findings plugin
			SELECT v_ex_summary_plugin_id plugin_id, 0 pos, 'Executive summary' tab_label
			  FROM dual
			 UNION ALL
			 SELECT v_findings_plugin_id plugin_id, 1 pos, 'Findings' tab_label
			  FROM dual
			 UNION ALL
			 SELECT v_documents_plugin_id plugin_id, 2 pos, 'Documents' tab_label
			  FROM dual
			 UNION ALL
			 SELECT v_audit_log_plugin_id plugin_id, 6 pos, 'Audit Log' tab_label
			  FROM dual
		  ) natt
			ON natt.plugin_id <> v_findings_plugin_id
			OR NOT EXISTS ( --If the plugin we want to add is the findings one, this checks that it's not already added for the current audit type
				SELECT 1
				  FROM csr.audit_type_tab a
				 WHERE a.plugin_id = v_findings_plugin_id
				   AND a.app_sid = att.app_sid
				   AND a.internal_audit_type_id = att.internal_audit_type_id
			)
		 WHERE att.plugin_id = v_old_full_audit_plugin_id;

	--Remove the old plugin from audit tabs (csr.audit_pkg.RemoveAuditTab)
	DELETE FROM csr.audit_type_tab att
	WHERE att.plugin_id = v_old_full_audit_plugin_id;
	
	--Also delete the old plugin (csr.plugin_pkg.DeletePlugin)
	DELETE FROM csr.plugin
	 WHERE plugin_id = v_old_full_audit_plugin_id;
end;
/

--FB52305
BEGIN
INSERT INTO csr.audit_type(audit_type_id, label, audit_type_group_id)
VALUES (22, 'Audit Document Update', 1);
END;
/

@..\csr_data_pkg
@..\audit_body

@update_tail
