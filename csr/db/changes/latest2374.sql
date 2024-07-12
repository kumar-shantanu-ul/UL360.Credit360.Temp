-- Please update version.sql too -- this keeps clean builds in sync
define version=2374
@update_header

ALTER TABLE csr.plugin ADD (
	group_key					VARCHAR2(255),
	control_lookup_keys			VARCHAR2(255)
);

DECLARE
  COUNT_INDEXES INTEGER;
BEGIN
  SELECT COUNT(*) INTO COUNT_INDEXES
    FROM USER_INDEXES
    WHERE LOWER(INDEX_NAME) = 'plugin_js_class'
	  AND LOWER(INDEX_OWNER) = 'csr';

  IF COUNT_INDEXES > 0 THEN
    EXECUTE IMMEDIATE 'DROP INDEX csr.plugin_js_class';
  END IF;
END;
/

CREATE UNIQUE INDEX csr.plugin_js_class ON csr.plugin (app_sid, js_class, form_path, group_key);

ALTER TABLE csr.plugin DROP CONSTRAINT chk_plugin_cms_tab_form;
ALTER TABLE csr.plugin ADD CONSTRAINT chk_plugin_cms_tab_form 
	CHECK ((tab_sid IS NULL AND form_path IS NULL AND group_key IS NULL AND control_lookup_keys IS NULL) 
	OR (app_sid IS NOT NULL AND ((tab_sid IS NOT NULL AND form_path IS NOT NULL AND group_key IS NULL) OR (group_key IS NOT NULL AND form_path IS NULL))));
	
	
ALTER TABLE csrimp.plugin ADD (	
	group_key					VARCHAR2(255),
	control_lookup_keys			VARCHAR2(255)
);

@..\plugin_pkg

@..\schema_body
@..\csrimp\imp_body
@..\plugin_body
@..\property_body

@update_tail

