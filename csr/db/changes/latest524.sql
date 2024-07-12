-- Please update version.sql too -- this keeps clean builds in sync
define version=524
@update_header

ALTER TABLE REGION_TYPE ADD (
	CLASS_NAME	VARCHAR2(64)
);

BEGIN
	UPDATE region_type SET class_name = 'CSRMeterRegion' WHERE region_type = 1; --csr_data_pkg.REGION_TYPE_METER;
	UPDATE region_type SET class_name = 'Container' WHERE region_type = 2; --csr_data_pkg.REGION_TYPE_ROOT;
	UPDATE region_type SET class_name = 'CSRPropertyRegion' WHERE region_type = 3; --csr_data_pkg.REGION_TYPE_PROPERTY;
	UPDATE region_type SET class_name = 'CSRTenantRegion' WHERE region_type = 4; --csr_data_pkg.REGION_TYPE_TENANT;
	UPDATE region_type SET class_name = 'CSRRateRegion' WHERE region_type = 5; --csr_data_pkg.REGION_TYPE_RATE;
	UPDATE region_type SET class_name = 'CSRAgentRegion' WHERE region_type = 6; --csr_data_pkg.REGION_TYPE_AGENT;
	UPDATE region_type SET class_name = 'CSRRegion' WHERE class_name IS NULL;
END;
/

ALTER TABLE REGION_TYPE MODIFY CLASS_NAME NOT NULL;

INSERT INTO region_type (region_type, label, class_name) VALUES (7, 'Supplier', 'CSRSupplierRegion');

@..\csr_data_pkg
@..\supplier_pkg
@..\region_pkg


@..\csr_data_body
@..\indicator_body
@..\meter_body
@..\supplier_body
@..\region_body
@..\utility_body.sql
@..\utility_report_body.sql

@update_tail


