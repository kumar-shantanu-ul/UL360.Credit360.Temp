-- Please update version.sql too -- this keeps clean builds in sync
define version=2881
define minor_version=9
@update_header

-- *** DDL ***
-- Create tables

CREATE SEQUENCE csr.meter_element_layout_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE SEQUENCE csr.meter_input_id_seq
    START WITH 100
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

-- Does this need to hang off meter_type? 
CREATE TABLE csr.meter_element_layout (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	meter_element_layout_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT pk_meter_element_layout PRIMARY KEY (app_sid, meter_element_layout_id),
	CONSTRAINT fk_meter_el_layout_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_meter_el_layout_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT chk_meter_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL))
);

CREATE TABLE csrimp.meter_element_layout (	
	csrimp_session_id				NUMBER(10,0)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	meter_element_layout_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	CONSTRAINT pk_meter_element_layout PRIMARY KEY (csrimp_session_id, meter_element_layout_id),
	CONSTRAINT chk_meter_el_layout_ind_tg_grp 
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL) OR (ind_sid IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_meter_element_layout_is FOREIGN KEY
        (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_input (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_meter_input_id    NUMBER(10) NOT NULL,
    new_meter_input_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_meter_input primary key (csrimp_session_id, old_meter_input_id) USING INDEX,
    CONSTRAINT uk_map_meter_input unique (csrimp_session_id, new_meter_input_id) USING INDEX,
    CONSTRAINT fk_map_meter_input_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);
	
-- fk indexes
create index csr.ix_meter_element_tag_group_id on csr.meter_element_layout (app_sid, tag_group_id);
create index csr.ix_meter_element_ind_sid on csr.meter_element_layout (app_sid, ind_sid);

CREATE UNIQUE INDEX csr.UK_METER_EL_LAYOUT ON csr.meter_element_layout(app_sid, ind_sid, tag_group_id);

-- Alter tables

-- *** Grants ***
grant select,insert,update,delete on csrimp.meter_element_layout to web_user;
grant insert on csr.meter_element_layout to csrimp;
grant select on csr.meter_element_layout_id_seq to csrimp;
grant select on csr.meter_input_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.


-- Triggers
CREATE OR REPLACE TRIGGER CSR.METER_IND_TRIGGER
AFTER INSERT OR UPDATE
	ON CSR.ALL_METER
	FOR EACH ROW
DECLARE
	v_consumption_input_id	csr.meter_input.meter_input_id%TYPE;
	v_cost_input_id			csr.meter_input.meter_input_id%TYPE;
BEGIN
	IF :NEW.app_sid != :OLD.app_sid OR
	   :NEW.region_sid != :OLD.region_sid OR
	   :NEW.primary_ind_sid != :OLD.primary_ind_sid OR
	   NVL(:NEW.primary_measure_conversion_id, -1) != NVL(:OLD.primary_measure_conversion_id, -1) OR
	   NVL(:NEW.cost_ind_sid, -1) != NVL(:OLD.cost_ind_sid, -1) OR
	   NVL(:NEW.cost_measure_conversion_id, -1) != NVL(:OLD.cost_measure_conversion_id, -1) THEN
	   	
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
	END IF;

	-- Associate any inputs which are not CONSUMPTION or COST
	FOR i IN (
		SELECT mi.meter_input_id, mi.lookup_key, mia.aggregator
		  FROM csr.meter_input mi
		  JOIN csr.meter_input_aggregator mia ON mia.app_sid = mi.app_sid AND mia.meter_input_id = mi.meter_input_id
		 WHERE mi.lookup_key NOT IN ('CONSUMPTION', 'COST')
	) LOOP
		BEGIN
			INSERT INTO csr.meter_input_aggr_ind (region_sid, meter_input_id, aggregator)
			VALUES (:NEW.region_sid, i.meter_input_id, i.aggregator);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL; -- Nothing to do
		END;
	END LOOP;

END;
/

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg
@../meter_pkg
@../property_pkg

@../schema_body
@../csrimp/imp_body
@../csr_app_body
@../indicator_body
@../tag_body
@../meter_body
@../property_body
@../meter_monitor_body
@../meter_aggr_body

@update_tail
