-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=18
@update_header

-- *** DDL ***

-- Drop trigger first
DROP TRIGGER CSR.METER_IND_TRIGGER;

-- Store the any region_sid that are going to change cost/days inds, so that we can recompute them after
EXEC security.user_pkg.LogonAdmin;
CREATE TABLE UPD.FB75315_METERS_FOR_RECOMPUTE AS
	SELECT am.app_sid, am.region_sid
	  FROM csr.all_meter am
	  JOIN csr.meter_ind mi ON am.app_sid = mi.app_sid AND am.meter_ind_id = mi.meter_ind_id
	  JOIN csr.meter_ind emi ON am.app_sid = emi.app_sid AND am.primary_ind_sid = emi.consumption_ind_sid
	  LEFT JOIN csr.trash t ON am.app_sid = t.app_sid AND am.region_sid = t.trash_sid
	 WHERE am.primary_ind_sid != mi.consumption_ind_sid
	   AND t.trash_sid IS NULL
	   AND (DECODE(mi.cost_ind_sid, emi.cost_ind_sid, 1, 0) = 0 OR
			DECODE(mi.days_ind_sid, emi.days_ind_sid, 1, 0) = 0 OR
			DECODE(mi.costdays_ind_sid, emi.costdays_ind_sid, 1, 0) = 0)
	 UNION
	SELECT am.app_sid, am.region_sid
	  FROM csr.all_meter am
	  JOIN csr.meter_ind mi ON am.app_sid = mi.app_sid AND am.meter_ind_id = mi.meter_ind_id AND am.primary_ind_sid = mi.consumption_ind_sid
	  LEFT JOIN csr.trash t ON am.app_sid = t.app_sid AND am.region_sid = t.trash_sid
	 WHERE t.trash_sid IS NULL
	   AND (DECODE(mi.cost_ind_sid, am.cost_ind_sid, 1, 0) = 0 OR
			DECODE(mi.days_ind_sid, am.days_ind_sid, 1, 0) = 0 OR
			DECODE(mi.costdays_ind_sid, am.costdays_ind_sid, 1, 0) = 0);


-- change existing meter_ind_ids on all_meter to point to the one with the same consumption
-- a couple end up changing group_key's on hyatt, but they look wrong on live at the moment anyway
-- 31 changed cost/days/costdays on regions because they will change meter_inds to make the consumptions match
-- 2669 changed cost/days/costdays because they are out of sync with their meter ind
BEGIN
	FOR r IN (
		SELECT c.host, am.app_sid, am.region_sid, am.meter_ind_id old_meter_ind_id, min(emi.meter_ind_id) new_meter_ind_id
		  FROM csr.all_meter am
		  JOIN csr.customer c ON am.app_sid = c.app_sid
		  JOIN csr.meter_ind mi ON am.app_sid = mi.app_sid AND am.meter_ind_id = mi.meter_ind_id
		  JOIN csr.meter_ind emi ON am.app_sid = emi.app_sid AND am.primary_ind_sid = emi.consumption_ind_sid
		 WHERE am.primary_ind_sid != mi.consumption_ind_sid
		 GROUP BY c.host, am.app_sid, am.region_sid, am.meter_ind_id
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
    
		UPDATE csr.all_meter
		   SET meter_ind_id = r.new_meter_ind_id
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid
		   AND meter_ind_id = r.old_meter_ind_id;
	END LOOP;
  
  security.user_pkg.LogonAdmin;
END;
/


-- Create meter inds for meters that currently don't have a meter ind or ones that do have one, but their consumption ind is different
-- to the meter ind's consumption, and there isn't an existing group they can use (which would be covered by the script above)
-- Takes ~40 seconds to run, might want to put in change script before any ddl
DECLARE
	v_exists          				NUMBER;
	v_ind_type_added  				BOOLEAN;
	v_suggested_label 				VARCHAR2(256);
	v_i               				NUMBER;
	v_new_meter_ind_id				NUMBER;
BEGIN
	FOR r IN (
		SELECT nmt.app_sid, nmt.description, nmt.parent_description, nmt.primary_ind_sid, nmt.cost_ind_sid, nmt.days_ind_sid, 
		       nmt.costdays_ind_sid, mi.meter_ind_id, c.host, nmt.group_key
		  FROM (
			SELECT am.app_sid, NVL(id.description, i.name) description, pi.description parent_description, am.primary_ind_sid, 
			       am.cost_ind_sid, am.days_ind_sid, am.costdays_ind_sid, emi.group_key
			  FROM csr.all_meter am
			  JOIN csr.ind i ON am.app_sid = i.app_sid AND am.primary_ind_sid = i.ind_sid
			  LEFT JOIN csr.v$ind id ON am.app_sid = id.app_sid AND am.primary_ind_sid = id.ind_sid
			  LEFT JOIN csr.v$ind pi ON am.app_sid = pi.app_sid AND i.parent_sid = pi.ind_sid
			  LEFT JOIN csr.meter_ind emi ON am.app_sid = emi.app_sid AND am.meter_ind_id = emi.meter_ind_id
			  LEFT JOIN csr.trash t ON am.app_sid = t.app_sid AND am.region_sid = t.trash_sid
			 WHERE (am.meter_ind_id IS NULL
			    OR (am.meter_ind_id IS NOT NULL AND am.primary_ind_sid != emi.consumption_ind_sid AND t.trash_sid IS NULL)
			 )
			 GROUP BY am.app_sid, primary_ind_sid, NVL(id.description, i.name), pi.description, am.cost_ind_sid, am.days_ind_sid, 
			          am.costdays_ind_sid, emi.group_key
		  ) nmt 
		  JOIN csr.customer c ON nmt.app_sid = c.app_sid
		  LEFT JOIN csr.meter_ind mi 
			ON nmt.app_sid = mi.app_sid 
		   AND DECODE(nmt.primary_ind_sid, mi.consumption_ind_sid, 1) = 1 
		   AND DECODE(nmt.cost_ind_sid, mi.cost_ind_sid, 1) = 1 
		   AND DECODE(nmt.days_ind_sid, mi.days_ind_sid, 1) = 1 
		   AND DECODE(nmt.costdays_ind_sid, mi.costdays_ind_sid, 1) = 1 
		 ORDER BY cost_ind_sid DESC, days_ind_sid DESC, costdays_ind_sid DESC
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
  
		IF r.meter_ind_id IS NOT NULL THEN
			-- meter ind already exists for this combination of indicators - link the meter to that group.
			UPDATE csr.all_meter
			   SET meter_ind_id = r.meter_ind_id
			 WHERE app_sid = r.app_sid
			   AND meter_ind_id IS NULL
			   AND DECODE(primary_ind_sid, r.primary_ind_sid, 1) = 1 
			   AND DECODE(cost_ind_sid, r.cost_ind_sid, 1) = 1 
			   AND DECODE(days_ind_sid, r.days_ind_sid, 1) = 1 
			   AND DECODE(costdays_ind_sid, r.costdays_ind_sid, 1) = 1;
		ELSE
			-- no meter ind exists, we'll have to create a new one, first work out a sensible/unique name
			v_suggested_label := r.description;

			IF TRIM(LOWER(r.description)) != 'consumption' THEN
				v_suggested_label := TRIM(REPLACE(v_suggested_label, 'Consumption', ''));
				v_suggested_label := TRIM(REPLACE(v_suggested_label, 'consumption', ''));
				v_suggested_label := TRIM(REPLACE(v_suggested_label, '- -', '-'));
			END IF;
		  
			SELECT COUNT(*)
			  INTO v_exists
			  FROM csr.meter_ind
			 WHERE app_sid = r.app_sid
			   AND label = v_suggested_label;
			 
			IF v_exists > 0 THEN
				IF r.cost_ind_sid IS NOT NULL OR r.days_ind_sid IS NOT NULL OR r.costdays_ind_sid IS NOT NULL THEN
					v_suggested_label := v_suggested_label||' with ';
					v_ind_type_added := FALSE;
			  
					IF r.cost_ind_sid IS NOT NULL THEN
						v_suggested_label := v_suggested_label||'cost';
						v_ind_type_added := TRUE;
					END IF;          
			  
					IF r.days_ind_sid IS NOT NULL THEN
						IF v_ind_type_added THEN
							v_suggested_label := v_suggested_label||'/days';
						ELSE
							v_suggested_label := v_suggested_label||'days';
						END IF;
						v_ind_type_added := TRUE;
					END IF; 
			  
					IF r.costdays_ind_sid IS NOT NULL THEN
						IF v_ind_type_added THEN
							v_suggested_label := v_suggested_label||'/cost-days';
						ELSE
							v_suggested_label := v_suggested_label||'cost-days';
						END IF;
						v_ind_type_added := TRUE;
					END IF; 
				END IF;
			
				SELECT COUNT(*)
				  INTO v_exists
				  FROM csr.meter_ind
				 WHERE app_sid = r.app_sid
				   AND label = v_suggested_label;
			END IF;
		  
			IF v_exists > 0 THEN
				v_suggested_label := r.parent_description||' - '||v_suggested_label;
		  
				SELECT COUNT(*)
				  INTO v_exists
				  FROM csr.meter_ind
				 WHERE app_sid = r.app_sid
				   AND label = v_suggested_label;
			END IF;

			-- if we haven't got a unique name by now, give up with sensible and
			-- just a sequence to the end of the name we've got (this only happened on one live demo site)
			v_i :=0;
			WHILE v_exists > 0 LOOP        
				v_i := v_i+1;

				SELECT count(*)
				  INTO v_exists
				  FROM csr.meter_ind
				 WHERE app_sid = r.app_sid
				   AND label = v_suggested_label||' ('||v_i||')';

				IF v_exists = 0 THEN
					v_suggested_label := v_suggested_label||' ('||v_i||')';
				END IF;
			END LOOP;
			
			BEGIN
				-- create a new meter ind group
				INSERT INTO csr.meter_ind (app_sid, meter_ind_id, label, consumption_ind_sid, cost_ind_sid, days_ind_sid, costdays_ind_sid, group_key)
					 VALUES (r.app_sid, csr.meter_ind_id_seq.NEXTVAL, v_suggested_label, r.primary_ind_sid, r.cost_ind_sid, r.days_ind_sid, r.costdays_ind_sid, r.group_key)
				  RETURNING meter_ind_id INTO v_new_meter_ind_id;
			EXCEPTION
				WHEN dup_val_on_index THEN
					-- must already have a meter_ind with the same consumption ind, we'll have to stick it in another group
					INSERT INTO csr.meter_ind (app_sid, meter_ind_id, label, consumption_ind_sid, cost_ind_sid, days_ind_sid, costdays_ind_sid, group_key)
					     VALUES (r.app_sid, csr.meter_ind_id_seq.NEXTVAL, v_suggested_label, r.primary_ind_sid, r.cost_ind_sid, r.days_ind_sid, r.costdays_ind_sid, v_suggested_label)
					  RETURNING meter_ind_id INTO v_new_meter_ind_id;
			END;
			
			-- assign that group the the relevant meters
			UPDATE csr.all_meter
			   SET meter_ind_id = v_new_meter_ind_id
			 WHERE app_sid = r.app_sid
			   AND (meter_ind_id IS NULL OR region_sid IN (
				  SELECT region_sid 
				    FROM csr.all_meter am 
				    JOIN csr.meter_ind mi ON am.app_sid = mi.app_sid AND am.meter_ind_id = mi.meter_ind_id 
				   WHERE am.primary_ind_sid != mi.consumption_ind_sid
			  ))
			   AND DECODE(primary_ind_sid, r.primary_ind_sid, 1) = 1 
			   AND DECODE(cost_ind_sid, r.cost_ind_sid, 1) = 1 
			   AND DECODE(days_ind_sid, r.days_ind_sid, 1) = 1 
			   AND DECODE(costdays_ind_sid, r.costdays_ind_sid, 1) = 1;
		END IF;
	END LOOP;   

	security.user_pkg.LogonAdmin;
END;
/

ALTER TABLE CSR.ALL_METER MODIFY (
	METER_IND_ID			NUMBER(10)	NOT NULL
);

-- END OF SCRIPT 1

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_TYPE_INPUT (
	METER_INPUT_ID					NUMBER(10)  NOT NULL,
	AGGREGATOR						VARCHAR(32) NOT NULL,
	IND_SID							NUMBER(10)  NOT NULL
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE CSR.TEMP_METER_INPUT_AGGR_IND (
	REGION_SID						NUMBER(10)  NOT NULL,
	METER_INPUT_ID					NUMBER(10)  NOT NULL,
	AGGREGATOR						VARCHAR(32) NOT NULL,
	METER_TYPE_ID					NUMBER(10),
	MEASURE_SID						NUMBER(10),
	MEASURE_CONVERSION_ID			NUMBER(10)
) ON COMMIT DELETE ROWS;

-- RENAME METER_IND -> METER_TYPE
-- (WE NEED TO RENAME BEFORE RUNNING THE BLOCKS BELOW)


-- Recreate the sequence with padding (can't rename a sequence)
DECLARE
	v_latest_id		NUMBER(10);
BEGIN
	SELECT csr.meter_ind_id_seq.NEXTVAL
	  INTO v_latest_id
	  FROM DUAL;

	EXECUTE IMMEDIATE 
		'CREATE SEQUENCE CSR.METER_TYPE_ID_SEQ START WITH ' || 
		TO_CHAR(v_latest_id + 1000) || 
		' INCREMENT BY 1 NOMINVALUE NOMAXVALUE CACHE 20 NOORDER';
END;
/

DROP SEQUENCE CSR.METER_IND_ID_SEQ;

--
-- CSR

-- Constraints
ALTER TABLE CSR.ALL_METER RENAME CONSTRAINT FK_METER_METER_IND TO FK_METER_METER_TYPE;
ALTER TABLE CSR.EST_METER_TYPE_MAPPING RENAME CONSTRAINT EST_TYPE_METER_IND TO EST_TYPE_METER_TYPE;
ALTER TABLE CSR.METER_IND RENAME CONSTRAINT FK_IND_METER_IND_COSTDAYS TO FK_IND_METER_TYPE_COSTDAYS;
ALTER TABLE CSR.METER_IND RENAME CONSTRAINT FK_IND_METER_IND_DAYS TO FK_IND_METER_TYPE_DAYS;
ALTER TABLE CSR.METER_IND RENAME CONSTRAINT PK_METER_IND TO PK_METER_TYPE;
ALTER TABLE CSR.URJANET_SERVICE_TYPE RENAME CONSTRAINT FK_URJ_SERVICE_TYPE_METER_IND TO FK_URJ_SERVICE_TYPE_METER_TYPE;

-- Columns
ALTER TABLE CSR.ALL_METER RENAME COLUMN METER_IND_ID TO METER_TYPE_ID;
ALTER TABLE CSR.EST_METER_TYPE_MAPPING RENAME COLUMN METER_IND_ID TO METER_TYPE_ID;
ALTER TABLE CSR.METER_IND RENAME COLUMN METER_IND_ID TO METER_TYPE_ID;
ALTER TABLE CSR.URJANET_SERVICE_TYPE RENAME COLUMN METER_IND_ID TO METER_TYPE_ID;

-- Tables
ALTER TABLE CSR.METER_IND RENAME TO METER_TYPE;
ALTER TABLE CSR.METER_IND_CHANGE RENAME TO METER_TYPE_CHANGE;

-- Indexes
ALTER INDEX CSR.IX_ALL_METER_METER_IND_ID RENAME TO IX_ALL_METER_METER_TYPE_ID;
ALTER INDEX CSR.IX_EST_ENERGYTYP_METER_IND RENAME TO IX_EST_ENERGYTYP_METER_TYPE;
ALTER INDEX CSR.IX_TYPE_METER_IND RENAME TO IX_TYPE_METER_TYPE;
ALTER INDEX CSR.IX_METER_IND_COSTDAYS_IND_ RENAME TO IX_METER_TYPE_COSTDAYS_IND_;
ALTER INDEX CSR.IX_METER_IND_DAYS_IND_SID RENAME TO IX_METER_TYPE_DAYS_IND_SID;
ALTER INDEX CSR.IX_METER_IND_DEMAND_IND_SI RENAME TO IX_METER_TYPE_DEMAND_IND_SI;
ALTER INDEX CSR.PK_METER_IND RENAME TO PK_METER_TYPE;
ALTER INDEX CSR.IX_URJANET_SERVI_METER_IND_ID RENAME TO IX_URJANET_SERVI_METER_TYPE_ID;

--
-- CSRIMP

-- Constraints
ALTER TABLE CSRIMP.MAP_METER_IND RENAME CONSTRAINT FK_MAP_METER_IND_IS TO FK_MAP_METER_TYPE_IS;
ALTER TABLE CSRIMP.MAP_METER_IND RENAME CONSTRAINT PK_MAP_METER_IND TO PK_MAP_METER_TYPE;
ALTER TABLE CSRIMP.MAP_METER_IND RENAME CONSTRAINT UK_MAP_METER_IND TO UK_MAP_METER_TYPE;
ALTER TABLE CSRIMP.METER_IND RENAME CONSTRAINT FK_METER_IND_IS TO FK_METER_TYPE_IS;
ALTER TABLE CSRIMP.METER_IND RENAME CONSTRAINT PK_METER_IND TO PK_METER_TYPE;

-- Columns
ALTER TABLE CSRIMP.MAP_METER_IND RENAME COLUMN NEW_METER_IND_ID TO NEW_METER_TYPE_ID;
ALTER TABLE CSRIMP.MAP_METER_IND RENAME COLUMN OLD_METER_IND_ID TO OLD_METER_TYPE_ID;
ALTER TABLE CSRIMP.METER_IND RENAME COLUMN METER_IND_ID TO METER_TYPE_ID;

-- Tables
ALTER TABLE CSRIMP.MAP_METER_IND RENAME TO MAP_METER_TYPE;
ALTER TABLE CSRIMP.METER_IND RENAME TO METER_TYPE;

-- Indexes
ALTER INDEX CSRIMP.PK_MAP_METER_IND RENAME TO PK_MAP_METER_TYPE;
ALTER INDEX CSRIMP.UK_MAP_METER_IND RENAME TO UK_MAP_METER_TYPE;
ALTER INDEX CSRIMP.PK_METER_IND RENAME TO PK_METER_TYPE;

-- END RENAME METER_IND -> METER_TYPE

-- Create tables

CREATE TABLE CSR.METER_TYPE_INPUT(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    METER_INPUT_ID    NUMBER(10, 0)    NOT NULL,
    AGGREGATOR        VARCHAR2(32)     NOT NULL,
    IND_SID           NUMBER(10, 0),
    MEASURE_SID       NUMBER(10, 0),
    CONSTRAINT PK_METER_TYPE_INPUT PRIMARY KEY (APP_SID, meter_type_ID, METER_INPUT_ID, AGGREGATOR),
    CONSTRAINT CONS_METER_TYPE_INPUT_MEASURE UNIQUE (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID)
);

CREATE TABLE CSR.METER_RECOMPUTE_BATCH_JOB(
    APP_SID         NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    REGION_SID      NUMBER(10, 0)    NOT NULL,
    BATCH_JOB_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_METER_RECOMPUTE_BATCH_JOB PRIMARY KEY (APP_SID, REGION_SID, BATCH_JOB_ID)
);

CREATE TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB(
    APP_SID           NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    METER_TYPE_ID     NUMBER(10, 0)    NOT NULL,
    METER_INPUT_ID    NUMBER(10, 0)    NOT NULL,
    AGGREGATOR        VARCHAR2(32)     NOT NULL,
    BATCH_JOB_ID      NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_METER_TYPE_CHNG_BATCH_JOB PRIMARY KEY (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, BATCH_JOB_ID)
);

-- Alter tables

ALTER TABLE CSR.ALL_METER ADD (
	CONSTRAINT CONS_ALL_METER_TYPE  UNIQUE (APP_SID, REGION_SID, meter_type_ID)
);

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD (
	METER_TYPE_ID             NUMBER(10, 0)
);

ALTER TABLE CSR.METER_INPUT_AGGREGATOR ADD (
	IS_MANDATORY      NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_METER_INPUT_AGG_MAND_1_0 CHECK (IS_MANDATORY IN(0,1))
);

--
-- Update meter_input_aggr_ind with meter_type_id

BEGIN
	FOR r IN (
		SELECT app_sid, region_sid, meter_type_id
		  FROM csr.all_meter
	) LOOP
		UPDATE csr.meter_input_aggr_ind
		   SET meter_type_id = r.meter_type_id
		 WHERE app_sid = r.app_sid
		   AND region_sid = r.region_sid;
	END LOOP;
END;
/

ALTER TABLE CSR.METER_INPUT_AGGR_IND MODIFY (
	METER_TYPE_ID             NUMBER(10, 0)	NOT NULL
);

--
-- Populate meter_type_input table and update meter_input_aggr_ind 
DECLARE
	v_consumption_input_id		NUMBER(10);
	v_cost_input_id				NUMBER(10);
BEGIN
	FOR r IN (
		SELECT mi.app_sid, mi.meter_type_id, mi.consumption_ind_sid, mi.cost_ind_sid, 
			cons.measure_sid consumption_measure_sid, cost.measure_sid cost_measure_sid
		  FROM csr.meter_type mi
		  JOIN csr.ind cons ON cons.app_sid = mi.app_sid AND cons.ind_sid = mi.consumption_ind_sid
		  LEFT JOIN csr.ind cost ON cost.app_sid = mi.app_sid AND cost.ind_sid = mi.cost_ind_sid
		 ORDER BY mi.app_sid
	) LOOP
		SELECT meter_input_id
		  INTO v_consumption_input_id
		  FROM csr.meter_input
		 WHERE app_sid = r.app_sid
		   AND lookup_key = 'CONSUMPTION';

		SELECT meter_input_id
		  INTO v_cost_input_id
		  FROM csr.meter_input
		 WHERE app_sid = r.app_sid
		   AND lookup_key = 'COST';

		INSERT INTO csr.meter_type_input (app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
		VALUES (r.app_sid, r.meter_type_id, v_consumption_input_id, 'SUM', r.consumption_ind_sid, r.consumption_measure_sid);

		UPDATE csr.meter_input_aggr_ind
		   SET measure_sid = r.consumption_measure_sid
		 WHERE app_sid = r.app_sid
		   AND meter_input_id = v_consumption_input_id
		   AND aggregator = 'SUM'
		   AND meter_type_id = r.meter_type_id;

		IF r.cost_ind_sid IS NOT NULL THEN
			INSERT INTO csr.meter_type_input (app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
			VALUES (r.app_sid, r.meter_type_id, v_cost_input_id, 'SUM', r.cost_ind_sid, r.cost_measure_sid);

			UPDATE csr.meter_input_aggr_ind
			   SET measure_sid = r.cost_measure_sid
			 WHERE app_sid = r.app_sid
			   AND meter_input_id = v_cost_input_id
			   AND aggregator = 'SUM'
			   AND meter_type_id = r.meter_type_id;
		END IF;

	END LOOP;
END;
/

--
-- Add constraints

ALTER TABLE CSR.METER_TYPE ADD CONSTRAINT FK_CUSTOMER_METER_TYPE 
    FOREIGN KEY (APP_SID)
    REFERENCES CSR.CUSTOMER(APP_SID)
;

ALTER TABLE CSR.METER_TYPE_INPUT ADD CONSTRAINT FK_IND_METER_TYPE_INPUT 
    FOREIGN KEY (APP_SID, IND_SID, MEASURE_SID)
    REFERENCES CSR.IND(APP_SID, IND_SID, MEASURE_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE CSR.METER_TYPE_INPUT ADD CONSTRAINT FK_METTYP_METTYPINP 
    FOREIGN KEY (APP_SID, METER_TYPE_ID)
    REFERENCES CSR.METER_TYPE(APP_SID, METER_TYPE_ID)
;

ALTER TABLE CSR.METER_TYPE_INPUT ADD CONSTRAINT FK_METINPAGG_METTYPINP 
    FOREIGN KEY (APP_SID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_INPUT_AGGREGATOR(APP_SID, METER_INPUT_ID, AGGREGATOR)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_METTYPINP_METINPAGGIND 
    FOREIGN KEY (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID)
    REFERENCES CSR.METER_TYPE_INPUT(APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID)  DEFERRABLE INITIALLY DEFERRED
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND DROP CONSTRAINT FK_MESCONV_METINPAGGRIND;
ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_MESCONV_METINPAGGRIND 
    FOREIGN KEY (APP_SID, MEASURE_CONVERSION_ID, MEASURE_SID)
    REFERENCES CSR.MEASURE_CONVERSION(APP_SID, MEASURE_CONVERSION_ID, MEASURE_SID)
;

ALTER TABLE CSR.METER_INPUT_AGGR_IND ADD CONSTRAINT FK_AMETERTYPE_METINPAGGIND 
    FOREIGN KEY (APP_SID, REGION_SID, METER_TYPE_ID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID, METER_TYPE_ID)
;

ALTER TABLE CSR.METER_RECOMPUTE_BATCH_JOB ADD CONSTRAINT FK_ALLMET_METRECOMPBATJOB 
    FOREIGN KEY (APP_SID, REGION_SID)
    REFERENCES CSR.ALL_METER(APP_SID, REGION_SID)
;

ALTER TABLE CSR.METER_TYPE_CHANGE_BATCH_JOB ADD CONSTRAINT FK_METTYPINP_METTYPCNGBATJOB 
    FOREIGN KEY (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR)
    REFERENCES CSR.METER_TYPE_INPUT(APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR)
;

-- FK Indexes
CREATE INDEX CSR.IX_CUSTOMER_METER_TYPE ON CSR.METER_TYPE (APP_SID);
CREATE INDEX CSR.IX_IND_METER_TYPE_INPUT ON CSR.METER_TYPE_INPUT (APP_SID, IND_SID, MEASURE_SID);
CREATE INDEX CSR.IX_METTYP_METTYPINP ON CSR.METER_TYPE_INPUT (APP_SID, METER_TYPE_ID);
CREATE INDEX CSR.IX_METINPAGG_METTYPINP ON CSR.METER_TYPE_INPUT (APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METTYPINP_METINPAGGIND ON CSR.METER_INPUT_AGGR_IND (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID);
CREATE INDEX CSR.IX_AMETERTYPE_METINPAGGIND ON CSR.METER_INPUT_AGGR_IND (APP_SID, REGION_SID, METER_TYPE_ID);
CREATE INDEX CSR.IX_ALLMET_METRECOMPBATJOB ON CSR.METER_RECOMPUTE_BATCH_JOB (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_METTYPINP_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR);


-- rename pk on all meter to have a proper name
BEGIN
	FOR r IN (
		SELECT constraint_name
		  FROM all_constraints
		 WHERE owner = 'CSR'
		   AND table_name = 'ALL_METER'
		   AND constraint_type = 'P'
	) LOOP	
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ALL_METER RENAME CONSTRAINT '||r.constraint_name||' TO PK_ALL_METER';
	END LOOP;
END;
/

--
-- Rename/drop old columns dropping constraints first
ALTER TABLE csr.all_meter MODIFY primary_ind_sid NULL;

BEGIN
	FOR r IN (
		SELECT constraint_name
		  FROM all_cons_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'ALL_METER'
		   AND column_name IN (
				'PRIMARY_IND_SID',
				'PRIMARY_MEASURE_CONVERSION_ID',
				'COST_IND_SID',
				'COST_MEASURE_CONVERSION_ID',
				'DAYS_IND_SID',
				'COSTDAYS_IND_SID'
		   )
	) LOOP	
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.ALL_METER DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/


ALTER TABLE CSR.ALL_METER RENAME COLUMN PRIMARY_IND_SID TO XXX_PRIMARY_IND_SID;
ALTER TABLE CSR.ALL_METER RENAME COLUMN PRIMARY_MEASURE_CONVERSION_ID TO XXX_PRIMARY_MEASURE_CONV_ID;
ALTER TABLE CSR.ALL_METER RENAME COLUMN COST_IND_SID TO XXX_COST_IND_SID;
ALTER TABLE CSR.ALL_METER RENAME COLUMN COST_MEASURE_CONVERSION_ID TO XXX_COST_MEASURE_CONV_ID;
ALTER TABLE CSR.ALL_METER RENAME COLUMN DAYS_IND_SID TO XXX_DAYS_IND_SID;
ALTER TABLE CSR.ALL_METER RENAME COLUMN COSTDAYS_IND_SID TO XXX_COSTDAYS_IND_SID;

ALTER TABLE CSR.ALL_METER DROP (
	DEMAND_MEASURE_CONVERSION_ID
) CASCADE CONSTRAINTS;

ALTER TABLE CSR.METER_TYPE DROP (
	DEMAND_IND_SID
) CASCADE CONSTRAINTS;


ALTER TABLE csr.meter_type MODIFY consumption_ind_sid NULL;
BEGIN
	FOR r IN (
		SELECT constraint_name
		  FROM all_cons_columns
		 WHERE owner = 'CSR'
		   AND table_name = 'METER_TYPE'
		   AND column_name IN (
				'CONSUMPTION_IND_SID',
				'COST_IND_SID'
		   )
	) LOOP	
		EXECUTE IMMEDIATE 'ALTER TABLE CSR.METER_TYPE DROP CONSTRAINT '||r.constraint_name;
	END LOOP;
END;
/


ALTER TABLE CSR.METER_TYPE RENAME COLUMN CONSUMPTION_IND_SID TO XXX_CONSUMPTION_IND_SID;
ALTER TABLE CSR.METER_TYPE RENAME COLUMN COST_IND_SID TO XXX_COST_IND_SID;

ALTER TABLE CSR.METER_TYPE DROP COLUMN REASON;

ALTER TABLE CSR.METER_INPUT_AGGR_IND DROP (
	IND_SID
) CASCADE CONSTRAINTS;


-- CSRIMP changes

CREATE TABLE CSRIMP.METER_TYPE_INPUT (
    CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    METER_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    METER_INPUT_ID    NUMBER(10, 0)    NOT NULL,
    AGGREGATOR        VARCHAR2(32)     NOT NULL,
    IND_SID           NUMBER(10, 0),
    MEASURE_SID       NUMBER(10, 0),
    CONSTRAINT PK_METER_TYPE_INPUT PRIMARY KEY (CSRIMP_SESSION_ID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR),
    CONSTRAINT CONS_METER_TYPE_INPUT_MEASURE UNIQUE (CSRIMP_SESSION_ID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID)
);

ALTER TABLE CSRIMP.ALL_METER ADD (
	METER_TYPE_ID					NUMBER(10, 0)	NOT NULL
);

ALTER TABLE CSRIMP.ALL_METER DROP (
	PRIMARY_IND_SID,
	PRIMARY_MEASURE_CONVERSION_ID,
	COST_IND_SID,
	COST_MEASURE_CONVERSION_ID,
	DAYS_IND_SID,
	COSTDAYS_IND_SID
) CASCADE CONSTRAINTS;

ALTER TABLE CSRIMP.METER_TYPE ADD (
	REASON			VARCHAR2(256)	NOT NULL
);

ALTER TABLE CSRIMP.METER_TYPE DROP (
	CONSUMPTION_IND_SID,
	COST_IND_SID
) CASCADE CONSTRAINTS;

ALTER TABLE CSRIMP.METER_TYPE DROP COLUMN REASON;

ALTER TABLE CSRIMP.METER_INPUT_AGGR_IND ADD (
	METER_TYPE_ID             NUMBER(10, 0)	NOT NULL
);

ALTER TABLE CSRIMP.METER_INPUT_AGGREGATOR ADD (
	IS_MANDATORY      NUMBER(1, 0)     DEFAULT 0 NOT NULL,
	CONSTRAINT CHK_METER_INPUT_AGG_MAND_1_0 CHECK (IS_MANDATORY IN(0,1))
);

ALTER TABLE CSRIMP.METER_INPUT_AGGR_IND DROP (
	IND_SID
) CASCADE CONSTRAINTS;

ALTER TABLE CSRIMP.METER_TYPE DROP (
	DEMAND_IND_SID
) CASCADE CONSTRAINTS;

DROP INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE;
CREATE UNIQUE INDEX CSRIMP.UK_CUSTOMER_AGGREGATE_TYPE ON CSRIMP.CHAIN_CUSTOMER_AGGREGATE_TYPE (
		CSRIMP_SESSION_ID, CARD_GROUP_ID, CMS_AGGREGATE_TYPE_ID, INITIATIVE_METRIC_ID, IND_SID, FILTER_PAGE_IND_INTERVAL_ID, METER_AGGREGATE_TYPE_ID);


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- Buld a view that looks like the old all_meter table but derived from the new structures
CREATE OR REPLACE VIEW CSR.V$LEGACY_AGGREGATOR AS
	SELECT app_sid, meter_input_id, aggregator, aggr_proc, is_mandatory
	  FROM (
		SELECT app_sid, meter_input_id, aggregator, aggr_proc, is_mandatory,
			ROW_NUMBER() OVER (
				PARTITION BY meter_input_id 
				ORDER BY CASE aggregator 
					WHEN 'SUM' THEN 1 
					WHEN 'AVERAGE' THEN 2 
					WHEN 'MAX' THEN 3 
					WHEN 'MIN' THEN 4 
					ELSE 100 
				END
			) rn
		  FROM csr.meter_input_aggregator
	) WHERE rn = 1
;

-- DROP VIEW CSR.V$LEGACY_METER_IND
CREATE OR REPLACE VIEW CSR.V$LEGACY_METER_TYPE AS
	SELECT 
		mi.app_sid,
		mi.meter_type_id,
		mi.label,
		iip.ind_sid consumption_ind_sid,
		ciip.ind_sid cost_ind_sid,
		mi.group_key,
		mi.days_ind_sid,
		mi.costdays_ind_sid
	 FROM meter_type mi
	-- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = mi.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = mi.app_sid AND iip.meter_type_id = mi.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = mi.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = mi.app_sid AND ciip.meter_type_id = mi.meter_type_id AND ciip.meter_input_id = ciag.meter_input_id
;

CREATE OR REPLACE VIEW CSR.V$LEGACY_METER AS
	SELECT 
		am.app_sid,
		am.region_sid,
		am.note,
		iip.ind_sid primary_ind_sid,
		iai.measure_conversion_id primary_measure_conversion_id,
		am.active,
		am.meter_source_type_id,
		am.reference,
		am.crc_meter,
		ciip.ind_sid cost_ind_sid,
		ciai.measure_conversion_id cost_measure_conversion_id,
		am.export_live_data_after_dtm,
		mi.days_ind_sid,
		am.days_measure_conversion_id,
		mi.costdays_ind_sid,
		am.costdays_measure_conversion_id,
		am.approved_by_sid,
		am.approved_dtm,
		am.is_core,
		am.meter_type_id,
		am.lower_threshold_percentage,
		am.upper_threshold_percentage,
		am.metering_version,
		am.urjanet_meter_id
	 FROM all_meter am
	 JOIN meter_type mi ON mi.app_sid = am.app_sid AND mi.meter_type_id = am.meter_type_id
	 -- Consumption mandatory
	 JOIN csr.meter_input ip ON ip.app_sid = am.app_sid AND ip.lookup_key = 'CONSUMPTION'
	 JOIN csr.v$legacy_aggregator iag ON iag.app_sid = ip.app_sid AND iag.meter_input_id = ip.meter_input_id
	 JOIN csr.meter_type_input iip ON iip.app_sid = am.app_sid AND iip.meter_type_id = am.meter_type_id AND iip.meter_input_id = iag.meter_input_id
	 JOIN meter_input_aggr_ind iai ON iai.app_sid = am.app_sid AND iai.region_sid = am.region_sid AND iai.meter_input_id = ip.meter_input_id
	 -- Cost optional
	 LEFT JOIN csr.meter_input cip ON cip.app_sid = am.app_sid AND cip.lookup_key = 'COST'
	 LEFT JOIN csr.v$legacy_aggregator ciag ON ciag.app_sid = cip.app_sid AND ciag.meter_input_id = cip.meter_input_id
	 LEFT JOIN csr.meter_type_input ciip ON ciip.app_sid = am.app_sid AND ciip.meter_type_id = am.meter_type_id AND ciip.meter_input_id = cip.meter_input_id
	 LEFT JOIN meter_input_aggr_ind ciai ON ciai.app_sid = am.app_sid AND ciai.region_sid = am.region_sid AND ciai.meter_input_id = cip.meter_input_id
;

DROP VIEW CSR.METER;

CREATE OR REPLACE VIEW CSR.V$METER AS
  SELECT app_sid,region_sid, meter_type_id, note, primary_ind_sid, primary_measure_conversion_id, meter_source_type_id, reference, crc_meter,
	cost_ind_sid, cost_measure_conversion_id, days_ind_sid, days_measure_conversion_id, costdays_ind_sid, costdays_measure_conversion_id,
	approved_by_sid, approved_dtm, is_core, urjanet_meter_id
    FROM csr.v$legacy_meter
   WHERE active = 1;

CREATE OR REPLACE VIEW csr.v$meter_reading AS
	SELECT mr.app_sid, mr.meter_reading_id, mr.region_sid, mr.start_dtm, mr.end_dtm, mr.val_number, mr.baseline_val,
		mr.entered_by_user_sid, mr.entered_dtm, mr.note, mr.reference, mr.cost, mr.meter_document_id, mr.created_invoice_id,
		mr.approved_dtm, mr.approved_by_sid, mr.is_estimate,
		mr.flow_item_id, mr.pm_reading_id,
		NVL(pi.format_mask,pm.format_mask) as format_mask
	  FROM csr.v$legacy_meter am
		JOIN csr.meter_reading mr ON am.app_sid = mr.app_sid
				AND am.region_sid = mr.region_sid
				AND am.meter_source_type_id = mr.meter_source_type_id
		LEFT JOIN csr.v$ind pi ON am.primary_ind_sid = pi.ind_sid AND am.app_sid = pi.app_sid
		LEFT JOIN csr.measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
	 WHERE mr.active = 1 AND req_approval = 0
;

CREATE OR REPLACE VIEW csr.v$property_meter AS
	SELECT a.app_sid, a.region_sid, a.reference, r.description, r.parent_sid, a.note,
		NVL(mi.label, pi.description) group_label, mi.group_key,
		a.primary_ind_sid, pi.description primary_description, 
		NVL(pmc.description, pm.description) primary_measure, pm.measure_sid primary_measure_sid, a.primary_measure_conversion_id,
		a.cost_ind_sid, ci.description cost_description, NVL(cmc.description, cm.description) cost_measure, a.cost_measure_conversion_id,		
		ms.meter_source_type_id, ms.name source_type_name, ms.description source_type_description,
		ms.manual_data_entry, ms.supplier_data_mandatory, ms.arbitrary_period, ms.reference_mandatory, ms.add_invoice_data,
		ms.realtime_metering, ms.show_in_meter_list, ms.descending, ms.allow_reset, a.meter_type_id, r.active, r.region_type
	  FROM csr.v$legacy_meter a
		JOIN meter_source_type ms ON a.meter_source_type_id = ms.meter_source_type_id AND a.app_sid = ms.app_sid			
		JOIN v$region r ON a.region_sid = r.region_sid AND a.app_sid = r.app_sid
		LEFT JOIN meter_type mi ON a.meter_type_id = mi.meter_type_id
		LEFT JOIN v$ind pi ON a.primary_ind_sid = pi.ind_sid AND a.app_sid = pi.app_sid
		LEFT JOIN measure pm ON pi.measure_sid = pm.measure_sid AND pi.app_sid = pm.app_sid
		LEFT JOIN measure_conversion pmc ON a.primary_measure_conversion_id = pmc.measure_conversion_id AND a.app_sid = pmc.app_sid
		LEFT JOIN v$ind ci ON a.cost_ind_sid = ci.ind_sid AND a.app_sid = ci.app_sid
		LEFT JOIN measure cm ON ci.measure_sid = cm.measure_sid AND ci.app_sid = cm.app_sid
		LEFT JOIN measure_conversion cmc ON a.cost_measure_conversion_id = cmc.measure_conversion_id AND a.app_sid = cmc.app_sid
;


-- *** Grants ***
grant select, insert, update, delete on csrimp.meter_type_input to web_user;
grant select, insert, update on csr.meter_type_input to csrimp;
grant select on csr.meter_type_id_seq to csrimp;


-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
BEGIN
	security.user_pkg.logonadmin;
	UPDATE csr.plugin
	   SET control_lookup_keys = REPLACE(control_lookup_keys, 'METER_IND', 'METER_TYPE')
	;
END;
/

BEGIN
	insert into csr.batch_job_type (batch_job_type_id, description, sp, one_at_a_time)
	values (23, 'Meter recompute', 'csr.meter_pkg.ProcessRecomputeBatchJob', 0);
	insert into csr.batch_job_type (batch_job_type_id, description, sp, one_at_a_time)
	values (24, 'Meter type change', 'csr.meter_pkg.ProcessMeterTypeChangeBatchJob', 0);
END;
/

-- RLS

-- Data
BEGIN
	security.user_pkg.logonadmin;
	
	-- set consumption to be mandatory
UPDATE csr.meter_input_aggregator
	   SET is_mandatory = 1
	 WHERE meter_input_id = 1;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_pkg
@../meter_report_pkg
@../space_pkg
@../schema_pkg
@../energy_star_attr_pkg
@../batch_job_pkg

@../csr_app_body
@../indicator_body
@../meter_body
@../meter_report_body
@../space_body
@../property_body
@../region_body
@../energy_star_attr_body
@../energy_star_job_data_body
@../energy_star_job_body
@../energy_star_body
@../meter_monitor_body
@../schema_body
@../utility_body
@../utility_report_body
@../issue_body
@../meter_alarm_body
@../meter_patch_body

@../csrimp/imp_body

@update_tail
