-- Please update version.sql too -- this keeps clean builds in sync
define version=717
@update_header

DROP TYPE csr.T_EDIEL_ERROR_TABLE;

CREATE OR REPLACE TYPE csr.T_EDIEL_ERROR_ROW AS
	OBJECT (
		POS				NUMBER(10, 0),
		MSG				VARCHAR(4000),
		DTM				DATE,
		SID				NUMBER(10)
	);
/
GRANT EXECUTE ON csr.T_EDIEL_ERROR_ROW TO PUBLIC;

CREATE OR REPLACE TYPE csr.T_EDIEL_ERROR_TABLE AS
	TABLE OF csr.T_EDIEL_ERROR_ROW;
/

ALTER TABLE csr.ISSUE_METER_RAW_DATA ADD (
	REGION_SID                 NUMBER(10, 0)
);

ALTER TABLE csr.ISSUE_METER_RAW_DATA ADD CONSTRAINT RefALL_METER2215 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES csr.ALL_METER(APP_SID, REGION_SID)
;

DECLARE
	v_role_sid			security_pkg.T_SID_ID;
	v_class_id			security_pkg.T_CLASS_ID;
	v_groups_sid		security_pkg.T_SID_ID;
BEGIN
	-- The applications we want to update wull have 
	-- the ISSUE_METER_ALARM type associated with them
	FOR r IN (
		SELECT c.host
		  FROM csr.issue_type it, csr.customer c
		 WHERE it.issue_type_id = 7 /*csr_data_pkg.ISSUE_METER_ALARM*/
		   AND c.app_sid = it.app_sid
	) LOOP
		user_pkg.logonadmin(r.host);
		INSERT INTO csr.issue_type (issue_type_id, label) VALUES (8 /*csr_data_pkg.ISSUE_METER_RAW_DATA*/, 'Meter raw data');
			
	    -- TODO: this will break!!
		UPDATE csr.role
		   SET name = 'Meter raw data errors'
		 WHERE LOWER(name) = LOWER('Meter raw data errors')
		   AND app_sid = security_pkg.getApp
		 RETURNING role_sid INTO v_role_sid;
		 
		-- insert if it doesn't do anything
		IF SQL%ROWCOUNT = 0 THEN        
	        v_class_id := class_pkg.GetClassId('CSRRole');
	        v_groups_sid := securableobject_pkg.GetSidFromPath(security_pkg.getACT, security_pkg.getApp, 'Groups');
	        group_pkg.CreateGroupWithClass(security_pkg.getACT, v_groups_sid, security_pkg.GROUP_TYPE_SECURITY,
	            REPLACE('Meter raw data errors','/','\'), v_class_id, v_role_sid);
	        
			INSERT INTO csr.role 
				(role_sid, app_sid, name) 
			VALUES 
				(v_role_sid, security_pkg.getApp, 'Meter raw data errors');
		END IF;

		user_pkg.logonadmin(NULL);
	END LOOP;
END;
/

ALTER TABLE csr.METER_SOURCE_TYPE ADD (
	REALTIME_METERING          NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    SHOW_IN_METER_LIST         NUMBER(1, 0)     DEFAULT 1 NOT NULL,
    CHECK (REALTIME_METERING IN(0,1)),
    CHECK (SHOW_IN_METER_LIST IN(0,1))
);

BEGIN
	-- Previously things were only showin in the meter 
	-- list if they were manual data entry items
	UPDATE csr.meter_source_type
	   SET show_in_meter_list = manual_data_entry;
	-- Set the new realtime-metering flag
	FOR r IN (
		SELECT DISTINCT am.app_sid, am.meter_source_type_id
		  FROM csr.all_meter am, csr.meter_live_data ld
		 WHERE am.region_sid = ld.region_sid
	) LOOP
		UPDATE csr.meter_source_type
		   SET realtime_metering = 1
		 WHERE app_sid = r.app_sid
		   AND meter_source_type_id = r.meter_source_type_id;
	END LOOP;
END;
/

BEGIN
	INSERT INTO csr.region_type (region_type, label, class_name) 
		VALUES(8, 'Real-time meter', 'CSRRealtimeMeterRegion'); -- csr_data_pkg.REGION_TYPE_REALTIME_METER
END;
/

@../csr_data_pkg
@../issue_pkg
@../meter_monitor_pkg
@../meter_pkg

@../issue_body
@../meter_monitor_body
@../region_body
@../meter_alarm_body
@../meter_body

@update_tail
