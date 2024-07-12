-- Please update version.sql too -- this keeps clean builds in sync
define version=2779
define minor_version=1
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.plugin ADD (
	SAVED_FILTER_SID		NUMBER(10, 0),
	RESULT_MODE				NUMBER(10, 0)
);

ALTER TABLE csrimp.plugin ADD (
	SAVED_FILTER_SID		NUMBER(10, 0),
	RESULT_MODE				NUMBER(10, 0)
);

-- I'm renaming chk_plugin_cms_tab_form to ck_plugin_refs because it's only one-third to do with cms now.
ALTER TABLE csr.plugin
ADD CONSTRAINT ck_plugin_refs 
	CHECK (
		(
			tab_sid IS NULL AND form_path IS NULL AND
			group_key IS NULL AND 
			saved_filter_sid IS NULL AND
			control_lookup_keys IS NULL
		) OR (
			app_sid IS NOT NULL AND
			(
				(
					tab_sid IS NOT NULL AND form_path IS NOT NULL AND 
					group_key IS NULL AND
					saved_filter_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NOT NULL AND
					saved_filter_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NULL AND
					saved_filter_sid IS NOT NULL
				)
			)
		)
	);

ALTER TABLE csr.plugin
DROP CONSTRAINT chk_plugin_cms_tab_form;

DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid);

-- *** Grants ***

-- ** Cross schema constraints ***
ALTER TABLE csr.plugin 
ADD CONSTRAINT fk_plugin_saved_filter 
FOREIGN KEY (app_sid, saved_filter_sid) 
REFERENCES chain.saved_filter(app_sid, saved_filter_sid);

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class,
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 13, 'Finding List',  '/csr/site/audit/controls/NonComplianceListTab.js', 'Audit.Controls.NonComplianceListTab',
			         'Credit360.Audit.Plugins.NonComplianceList', 'This tab shows a filterable list of findings.', NULL, NULL, NULL);
	EXCEPTION WHEN dup_val_on_index THEN
		UPDATE csr.plugin
		   SET description = 'Non-Compliance List',
		   	   js_include = '/csr/site/audit/controls/NonComplianceListTab.js',
			   cs_class = 'Credit360.Audit.Plugins.NonComplianceList',
		   	   details = 'This tab shows a filterable list of non-compliances.'
		 WHERE plugin_type_id = 13
		   AND js_class = 'Audit.Controls.NonComplianceListTab'
		   AND app_sid IS NULL
		   AND tab_sid IS NULL;
	END;
END;
/

-- ** New package grants **

-- *** Packages ***
@../plugin_pkg

@../audit_body
@../non_compliance_report_body
@../plugin_body
@../schema_body
@../csrimp/imp_body

@update_tail
