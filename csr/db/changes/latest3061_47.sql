-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=47
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE CSR.METER_SOURCE_TYPE ADD (
	ALLOW_NULL_START_DTM		NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE CSR.METER_INSERT_DATA MODIFY (
	START_DTM					TIMESTAMP WITH TIME ZONE	NULL
);

ALTER TABLE CSRIMP.METER_SOURCE_TYPE ADD (
	ALLOW_NULL_START_DTM		NUMBER(1) DEFAULT 0 NOT NULL
);

DROP INDEX CSR.UK_METER_SOURCE_DATA;

CREATE UNIQUE INDEX CSR.UK_METER_SOURCE_DATA ON CSR.METER_SOURCE_DATA(APP_SID, REGION_SID, METER_INPUT_ID, PRIORITY, START_DTM, END_DTM);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_old_meter_source_type_id		csr.meter_source_type.meter_source_type_id%TYPE;
	v_new_meter_source_type_id		csr.meter_source_type.meter_source_type_id%TYPE;
	v_next_meter_source_type_id		csr.meter_source_type.meter_source_type_id%TYPE;
BEGIN
	FOR c IN (
		SELECT host
		  FROM csr.customer
		 WHERE host IN (
		 	'adobe.credit360.com',
		 	'jmfamily.credit360.com')
	) LOOP
		
		security.user_pkg.logonadmin(c.host);

		BEGIN
			SELECT meter_source_type_id
			  INTO v_new_meter_source_type_id
			  FROM csr.meter_source_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND name = 'period-null-start-dtm';

		EXCEPTION
			WHEN NO_DATA_FOUND THEN

				SELECT NVL(MAX(meter_source_type_id), 0) + 1
				  INTO v_next_meter_source_type_id
				  FROM csr.meter_source_type
				 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP');

				v_new_meter_source_type_id := v_next_meter_source_type_id;
				
				INSERT INTO csr.meter_source_type (app_sid, meter_source_type_id, name, description,
					arbitrary_period, add_invoice_data, show_in_meter_list, allow_null_start_dtm)
				VALUES (security.security_pkg.GetAPP, v_new_meter_source_type_id, 
					'period-null-start-dtm', 'Allow null start date', 1, 0, 1, 1);
		END;

		BEGIN
			SELECT meter_source_type_id
			  INTO v_old_meter_source_type_id
			  FROM csr.meter_source_type
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND name = 'period';

			UPDATE csr.all_meter
			   SET meter_source_type_id = v_new_meter_source_type_id
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
			   AND meter_source_type_id = v_old_meter_source_type_id
			   AND manual_data_entry = 0;
		EXCEPTION
			WHEN NO_DATA_FOUND THEN
				NULL;
		END;

		security.user_pkg.logonadmin;

	END LOOP;
END;
/

BEGIN
	INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (96, 'Metering - Urjanet start date kludge', 'EnableUrjanetStartDateKludge', 
		'Enable the Urjanet "null start date kludge". This adds a source type called "Allow null start date" which will allow reading data with a null start date to be processed for meters with this source type.', 1);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../enable_pkg

@../enable_body
@../meter_body
@../meter_monitor_body
@../schema_body

@../csrimp/imp_body

@update_tail
