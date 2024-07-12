define version=2075
@update_header


DECLARE
    new_class_id    security.security_pkg.T_SID_ID;
    v_act           security.security_pkg.T_ACT_ID;
BEGIN
    security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, NULL, v_act); 
    BEGIN   
        security.class_pkg.CreateClass(v_act, null, 'GeoMap', 'csr.geo_map_pkg', null, new_class_id);
    EXCEPTION
        WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
            new_class_id := security.class_pkg.getClassId('GeoMap');
    END;
END;
/

ALTER TABLE CSR.GEO_TILESET ADD BASE_CSS_CLASS VARCHAR2(255) NOT NULL;

ALTER TABLE CSR.GEO_MAP DROP CONSTRAINT FK_TAG_GROUP_GEO_MAP;
ALTER TABLE CSR.GEO_MAP DROP COLUMN TAG_GROUP_ID;

ALTER TABLE CSR.GEO_MAP ADD TAG_ID NUMBER(10, 0);
ALTER TABLE CSR.GEO_MAP ADD CONSTRAINT FK_TAG_GEO_MAP 
    FOREIGN KEY (APP_SID, TAG_ID)
    REFERENCES CSR.TAG(APP_SID, TAG_ID);

ALTER TABLE CSR.GEO_MAP_TAB_TYPE ADD MAP_BUILDER_JS_CLASS VARCHAR2(255) NULL;
ALTER TABLE CSR.GEO_MAP_TAB_TYPE ADD MAP_BUILDER_CS_CLASS VARCHAR2(255) NULL;    	

UPDATE CSR.GEO_MAP_TAB_TYPE
SET MAP_BUILDER_JS_CLASS = 'Controls.GeoMapPopupTab.Property', MAP_BUILDER_CS_CLASS = 'Credit360.GeoMap.MapBuilder.PropertyTabDto'
WHERE GEO_MAP_TAB_TYPE_ID = 1;

UPDATE CSR.GEO_MAP_TAB_TYPE
SET MAP_BUILDER_JS_CLASS = 'Controls.GeoMapPopupTab.Chart', MAP_BUILDER_CS_CLASS = 'Credit360.GeoMap.MapBuilder.ChartTabDto'
WHERE GEO_MAP_TAB_TYPE_ID = 2;

ALTER TABLE CSR.GEO_MAP_TAB_TYPE MODIFY (MAP_BUILDER_JS_CLASS NOT NULL);
ALTER TABLE CSR.GEO_MAP_TAB_TYPE MODIFY (MAP_BUILDER_CS_CLASS NOT NULL);
	
CREATE OR REPLACE PACKAGE CSR.geo_map_pkg
AS
END;
/

GRANT EXECUTE ON csr.geo_map_pkg TO WEB_USER;
GRANT EXECUTE ON csr.geo_map_pkg TO SECURITY;

@..\geo_map_pkg
@..\geo_map_body


@update_tail
