-- Please update version.sql too -- this keeps clean builds in sync
define version=338
@update_header

DROP TABLE METER_SOURCE_TYPE CASCADE CONSTRAINTS;

CREATE TABLE METER_SOURCE_TYPE(
    APP_SID                    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_SOURCE_TYPE_ID       NUMBER(10, 0)    NOT NULL,
    NAME                       VARCHAR2(256)    NOT NULL,
    DESCRIPTION                VARCHAR2(512)    NOT NULL,
    MANUAL_DATA_ENTRY          NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    SUPPLIER_DATA_MANDATORY    NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CHECK (MANUAL_DATA_ENTRY IN (0,1)),
    CHECK (SUPPLIER_DATA_MANDATORY IN (0,1)),
    CONSTRAINT PK570 PRIMARY KEY (APP_SID, METER_SOURCE_TYPE_ID)
)
;

ALTER TABLE METER_SOURCE_TYPE ADD CONSTRAINT RefCUSTOMER1236 
    FOREIGN KEY (APP_SID)
    REFERENCES CUSTOMER(APP_SID)
;

DECLARE
	v_metering_enabled Security_Pkg.T_SO_ATTRIBUTE_NUMBER;
BEGIN
	FOR r IN (
		SELECT app_sid, host
		  FROM csr.customer c
	) LOOP
		BEGIN
			user_pkg.logonadmin(r.host);
			v_metering_enabled := securableobject_pkg.GetNamedNumberAttribute(
				security_pkg.GetACT, 
				securableobject_pkg.GetSIDFromPath(security_pkg.GetACT, security_pkg.GetAPP, 'csr'), 
				'modules-metering'
			);
			IF v_metering_enabled IS NOT NULL AND v_metering_enabled > 0 THEN
				INSERT INTO meter_source_type
				  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
				  VALUES (r.app_sid, 1, 'point', 'Point in time', 1, 0);
				INSERT INTO meter_source_type
				  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
				  VALUES (r.app_sid, 2, 'period', 'Arbitrary period', 1, 0);
				INSERT INTO meter_source_type
				  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
				  VALUES (r.app_sid, 3, 'amr', 'AMR (CSR form)', 0, 0);
			END IF;
			security_pkg.SetApp(NULL);
		EXCEPTION
			-- IGNORE WEBSITE NOT FOUND ERROR
			WHEN security_pkg.OBJECT_NOT_FOUND THEN
				NULL; 
		END;
	END LOOP;
	-- Now mop up any cases where there are meters but the 
	-- modules-metring attribute may have been switched off
	--
	FOR r IN (
		SELECT DISTINCT app_sid 
		  FROM all_meter
	) LOOP
		BEGIN 
			INSERT INTO meter_source_type
			  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
			  VALUES (r.app_sid, 1, 'point', 'Point in time', 1, 0);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore if already esists
		END;
		BEGIN
			INSERT INTO meter_source_type
			  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
			  VALUES (r.app_sid, 2, 'period', 'Arbitrary period', 1, 0);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore if already esists
		END;
		BEGIN
			INSERT INTO meter_source_type
			  	(app_sid, meter_source_type_id, name, description, manual_data_entry, supplier_data_mandatory)
			  VALUES (r.app_sid, 3, 'amr', 'AMR (CSR form)', 0, 0);
		EXCEPTION 
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Ignore if already esists
		END;
	END LOOP;
END;
/

ALTER TABLE ALL_METER ADD CONSTRAINT RefMETER_SOURCE_TYPE1113 
    FOREIGN KEY (APP_SID, METER_SOURCE_TYPE_ID)
    REFERENCES METER_SOURCE_TYPE(APP_SID, METER_SOURCE_TYPE_ID)
;


@../rls


@update_tail
