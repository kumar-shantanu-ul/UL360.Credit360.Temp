-- Please update version.sql too -- this keeps clean builds in sync
define version=2799
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.portal_dashboard DROP CONSTRAINT uk_portal_menu_sid;
CREATE UNIQUE INDEX csr.ux_portal_dashboard_menu_sid ON csr.portal_dashboard (CASE WHEN menu_sid IS NOT NULL THEN app_sid END, menu_sid);

ALTER TABLE csr.plugin ADD (
	portal_sid					NUMBER(10, 0),
	CONSTRAINT fk_plugin_portal FOREIGN KEY (app_sid, portal_sid) REFERENCES csr.portal_dashboard(app_sid, portal_sid)
);

ALTER TABLE csr.plugin DROP CONSTRAINT ck_plugin_refs;
ALTER TABLE csr.plugin ADD CONSTRAINT ck_plugin_refs 
	CHECK (
		(
			tab_sid IS NULL AND form_path IS NULL AND
			group_key IS NULL AND 
			saved_filter_sid IS NULL AND
			control_lookup_keys IS NULL AND
			portal_sid IS NULL
		) OR (
			app_sid IS NOT NULL AND
			(
				(
					tab_sid IS NOT NULL AND form_path IS NOT NULL AND 
					group_key IS NULL AND
					saved_filter_sid IS NULL AND
					portal_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NOT NULL AND
					saved_filter_sid IS NULL AND
					portal_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NULL AND
					saved_filter_sid IS NOT NULL AND
					portal_sid IS NULL
				) OR (
					tab_sid IS NULL AND form_path IS NULL AND
					group_key IS NULL AND
					saved_filter_sid IS NULL AND
					portal_sid IS NOT NULL
				)
			)
		)
	);

DROP INDEX csr.plugin_js_class;
CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key, saved_filter_sid, result_mode, portal_sid);

ALTER TABLE csrimp.plugin ADD (
	portal_sid					NUMBER(10, 0)
);

-- *** Grants ***
GRANT select ON csr.portal_dashboard TO chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***
@../plugin_pkg

@../plugin_body
@../property_body
@../schema_body
@../chain/plugin_body
@../csrimp/imp_body

@update_tail
