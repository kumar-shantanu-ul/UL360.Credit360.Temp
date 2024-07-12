-- Please update version.sql too -- this keeps clean builds in sync
define version=2827
define minor_version=1
define is_combined=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- csrimp.map_plugin_type was missing from csr/db/csrimp/map_tables.sql
DECLARE
	v_count			NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_count
	  FROM all_tables
	 WHERE UPPER(owner) = 'CSRIMP'
	   AND UPPER(table_name) = 'MAP_PLUGIN_TYPE';
	
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE
			'CREATE TABLE csrimp.map_plugin_type ('||
			'    CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT(''SECURITY'', ''CSRIMP_SESSION_ID'') NOT NULL,'||
			'    old_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    new_plugin_type_id		NUMBER(10) NOT NULL,'||
			'    CONSTRAINT pk_map_plugin_type_id PRIMARY KEY (csrimp_session_id, old_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT uk_map_plugin_type_id UNIQUE (csrimp_session_id, new_plugin_type_id) USING INDEX,'||
			'    CONSTRAINT fk_map_plugin_type_is FOREIGN KEY'||
			'        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)'||
			'        ON DELETE CASCADE'||
			')';
	ELSE
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint PK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint PK_MAP_PLUGIN_TYPE_ID PRIMARY KEY (CSRIMP_SESSION_ID,OLD_PLUGIN_TYPE_ID)';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE DROP constraint UK_MAP_PLUGIN_TYPE_ID DROP INDEX';
		EXECUTE IMMEDIATE 'ALTER TABLE CSRIMP.MAP_PLUGIN_TYPE ADD constraint UK_MAP_PLUGIN_TYPE_ID UNIQUE (CSRIMP_SESSION_ID,NEW_PLUGIN_TYPE_ID)';
	END IF;
END;
/

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Packages ***

@update_tail
