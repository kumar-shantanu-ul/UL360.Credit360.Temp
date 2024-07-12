-- Please update version.sql too -- this keeps clean builds in sync
define version=2946
define minor_version=19
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE csr.urjanet_service_type DROP CONSTRAINT PK_URJANET_SERVICE_TYPE DROP INDEX;
ALTER TABLE csr.urjanet_service_type ADD (
	raw_data_source_id NUMBER(10),
	CONSTRAINT PK_URJANET_SERVICE_TYPE PRIMARY KEY (app_sid, service_type, raw_data_source_id)
);

BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT app_sid, MAX(raw_data_source_id) raw_data_source_id
		  FROM csr.meter_raw_data_source
		 WHERE raw_data_source_type_id = 3 -- urjanet
		 GROUP BY app_sid
	) LOOP	
		UPDATE csr.urjanet_service_type 
		   SET raw_data_source_id = r.raw_data_source_id
		 WHERE raw_data_source_id IS NULL
		   AND app_sid = r.app_sid;
	END LOOP;
END;
/

ALTER TABLE csr.urjanet_service_type MODIFY raw_data_source_id NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE csr.urjanet_service_type ADD CONSTRAINT srv_type_raw_data_src_id FOREIGN KEY (app_sid, raw_data_source_id) REFERENCES csr.meter_raw_data_source(app_sid, raw_data_source_id);

ALTER TABLE csr.meter_raw_data_source
   ADD (
		create_meters NUMBER(1),
		automated_import_class_sid NUMBER(10,0),
		holding_region_sid NUMBER(10,0)
	);
	
ALTER TABLE csrimp.meter_raw_data_source
   ADD (
		create_meters NUMBER(1),
		automated_import_class_sid NUMBER(10,0),
		holding_region_sid NUMBER(10,0)
	);

UPDATE csr.meter_raw_data_source
   SET create_meters = 0
 WHERE create_meters IS NULL;
   
ALTER TABLE csr.meter_raw_data_source MODIFY create_meters NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.meter_raw_data_source ADD CONSTRAINT raw_data_auto_imp FOREIGN KEY (app_sid, automated_import_class_sid) REFERENCES csr.automated_import_class(app_sid, automated_import_class_sid);

ALTER TABLE csr.meter_excel_mapping ADD (create_meters_map_column VARCHAR2(255));
ALTER TABLE csrimp.meter_excel_mapping ADD (create_meters_map_column VARCHAR2(255));

ALTER TABLE csr.meter_raw_data_source ADD meter_date_format VARCHAR2(255);
ALTER TABLE csrimp.meter_raw_data_source ADD meter_date_format VARCHAR2(255);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_monitor_pkg
@../meter_monitor_body
@../meter_pkg
@../meter_body
@../automated_import_body


@update_tail
