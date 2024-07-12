-- Please update version.sql too -- this keeps clean builds in sync
define version=2811
define minor_version=0
@update_header

-- SORRY, I NEED TO UPDATE THE TRIGGER FIRST
CREATE OR REPLACE TRIGGER CSR.METER_IND_TRIGGER
AFTER INSERT OR UPDATE
	ON CSR.ALL_METER
	FOR EACH ROW
DECLARE
	v_consumption_input_id	csr.meter_input.meter_input_id%TYPE;
	v_cost_input_id			csr.meter_input.meter_input_id%TYPE;
BEGIN
	IF :NEW.app_sid = :OLD.app_sid AND
	   :NEW.region_sid = :OLD.region_sid AND
	   :NEW.primary_ind_sid = :OLD.primary_ind_sid AND
	   NVL(:NEW.primary_measure_conversion_id, -1) = NVL(:OLD.primary_measure_conversion_id, -1) AND
	   NVL(:NEW.cost_ind_sid, -1) = NVL(:OLD.cost_ind_sid, -1) AND
	   NVL(:NEW.cost_measure_conversion_id, -1) = NVL(:OLD.cost_measure_conversion_id, -1) THEN
	   	RETURN; -- NOTHING TO DO!
	END IF;

	SELECT meter_input_id
	  INTO v_consumption_input_id
	  FROM csr.meter_input
	 WHERE app_sid = :NEW.app_sid
	   AND lookup_key = 'CONSUMPTION';
	
	SELECT meter_input_id
	  INTO v_cost_input_id
	  FROM csr.meter_input
	 WHERE app_sid = :NEW.app_sid
	   AND lookup_key = 'COST';
	
	FOR r IN (
		SELECT :NEW.app_sid app_sid, :NEW.region_sid region_sid, 
			pia.aggregator primary_aggregator, :NEW.primary_ind_sid primary_ind_sid, pi.measure_sid primary_measure_sid, :NEW.primary_measure_conversion_id primary_measure_conversion_id,
			cia.aggregator cost_aggregator, :NEW.cost_ind_sid cost_ind_sid, ci.measure_sid cost_measure_sid, :NEW.cost_measure_conversion_id cost_measure_conversion_id
		  FROM csr.ind pi
		  JOIN csr.meter_input_aggregator pia ON pia.app_sid = pi.app_sid AND pia.meter_input_id = v_consumption_input_id
		  LEFT JOIN csr.ind ci ON ci.app_sid = pi.app_sid AND ci.ind_sid = :NEW.cost_ind_sid
		  LEFT JOIN csr.meter_input_aggregator cia ON cia.app_sid = ci.app_sid AND cia.meter_input_id = v_cost_input_id
		 WHERE pi.app_sid = :NEW.app_sid
		   AND pi.ind_sid = :NEW.primary_ind_sid
	) LOOP
		-- Set the consumption indicator/measure/conversion
		BEGIN
			INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
			VALUES (r.app_sid, r.region_sid, v_consumption_input_id, r.primary_aggregator, r.primary_ind_sid, r.primary_measure_sid, r.primary_measure_conversion_id);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.meter_input_aggr_ind
				   SET ind_sid = r.primary_ind_sid,
					   measure_sid = r.primary_measure_sid, 
					   measure_conversion_id = r.primary_measure_conversion_id
				 WHERE app_sid = r.app_sid
				   AND region_sid = r.region_sid
				   AND meter_input_id = v_consumption_input_id
				   AND aggregator = r.primary_aggregator;
		END;
		
		-- Set the cost indicator/measure/conversion
		IF r.cost_ind_sid IS NOT NULL THEN
			BEGIN
				INSERT INTO csr.meter_input_aggr_ind (app_sid, region_sid, meter_input_id, aggregator, ind_sid, measure_sid, measure_conversion_id)
				VALUES (r.app_sid, r.region_sid, v_cost_input_id, r.cost_aggregator, r.cost_ind_sid, r.cost_measure_sid, r.cost_measure_conversion_id);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN
					UPDATE csr.meter_input_aggr_ind
					   SET ind_sid = r.cost_ind_sid,
						   measure_sid = r.cost_measure_sid, 
						   measure_conversion_id = r.cost_measure_conversion_id
					 WHERE app_sid = r.app_sid
					   AND region_sid = r.region_sid
					   AND meter_input_id = v_cost_input_id
					   AND aggregator = r.cost_aggregator;
			END;
		ELSE
			DELETE FROM csr.meter_input_aggr_ind
			  WHERE app_sid = r.app_sid
			    AND region_sid = r.region_sid
			    AND meter_input_id = v_cost_input_id;
		END IF;
	END LOOP;
END;
/


ALTER TABLE CSR.ALL_METER ADD (
	METERING_VERSION	NUMBER(10)	DEFAULT 1 NOT NULL
);

BEGIN
	MERGE INTO csr.all_meter m
	USING (
		SELECT app_sid, meter_source_type_id
		  FROM csr.meter_source_type
		 WHERE realtime_metering = 1
	) st
	ON (m.app_sid = st.app_sid AND m.meter_source_type_id = st.meter_source_type_id)
	WHEN MATCHED THEN UPDATE SET m.metering_version = 2;
END;
/

ALTER TABLE CSR.ALL_METER MODIFY (
	METERING_VERSION	NUMBER(10)	DEFAULT 2
);

@../meter_pkg
@../meter_body

@update_tail
