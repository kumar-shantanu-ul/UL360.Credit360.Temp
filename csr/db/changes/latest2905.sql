define version=2905
define minor_version=0
define is_combined=1
@update_header

-- Drop trigger first
DROP TRIGGER CSR.METER_IND_TRIGGER;

-- Store the any region_sid that are going to change cost/days inds, so that we can recompute them after
EXEC security.user_pkg.LogonAdmin;
-- NOTE: If you get here because of an error because UPD does not exist and you are patching:
-- This CREATE TABLE statement can be commented out if the customer does not use the metering
-- module and you are sure they don't need meteres recomputed after this script has run.

/* Removed this table because
 * 1. The assumption that a UPD user exists for all databases is invalid, and this will fail for
 *    on-prem installs.
 * 2. This table is only referenced here and in latest3103.sql where it is dropped, with no indication how
 *    it might be used to recompute.

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
*/

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
ALTER INDEX CSR.IX_TYPE_METER_IND RENAME TO IX_TYPE_METER_TYPE;
ALTER INDEX CSR.IX_METER_IND_COSTDAYS_IND_ RENAME TO IX_METER_TYPE_COSTDAYS_IND_;
ALTER INDEX CSR.IX_METER_IND_DAYS_IND_SID RENAME TO IX_METER_TYPE_DAYS_IND_SID;

-- Missing from schema. Create with old name and just rename.
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_indexes
	 WHERE index_name = 'IX_METER_IND_DEMAND_IND_SI';

	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE 'CREATE INDEX CSR.IX_METER_IND_DEMAND_IND_SI ON CSR.METER_IND (APP_SID, DEMAND_IND_SID)';
	END IF;
END;
/

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

@@latest2904_8_packages

CREATE TABLE aspen2.culture (
	CULTURE_ID		NUMBER(10, 0) NOT NULL,
	IETF			VARCHAR2(255) NOT NULL,
    DESCRIPTION		VARCHAR2(255) NOT NULL,
	UPDATED_DTM		DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_CUL PRIMARY KEY (CULTURE_ID),
    CONSTRAINT UK_CUL UNIQUE (IETF)
);

CREATE TABLE csr.internal_audit_type_carry_fwd (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	from_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	to_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_iatcf				PRIMARY KEY (app_sid, from_internal_audit_type_id, to_internal_audit_type_id),
	CONSTRAINT fk_iatcf_from_iat	FOREIGN KEY (app_sid, from_internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id),
	CONSTRAINT fk_iatcf_to_iat		FOREIGN KEY (app_sid, to_internal_audit_type_id) REFERENCES csr.internal_audit_type (app_sid, internal_audit_type_id)
);
CREATE TABLE csrimp.internal_audit_type_carry_fwd (
	csrimp_session_id				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID'),
	from_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	to_internal_audit_type_id		NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_iatcf				PRIMARY KEY (csrimp_session_id, from_internal_audit_type_id, to_internal_audit_type_id),
    CONSTRAINT fk_iatcf_is			FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE SEQUENCE csr.audit_non_compliance_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;
CREATE TABLE csrimp.map_audit_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	new_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_audit_non_compliance primary key (csrimp_session_id, old_audit_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_audit_non_compliance unique (csrimp_session_id, new_audit_non_compliance_id) USING INDEX,
    CONSTRAINT fk_map_audit_non_compliance_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

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

-- We need to drop this constraint as some of the the ind_sids for consumption might 
-- change where the meter is in the trash and also the cost ind_sid is legitimately 
-- changing for some meters. The column this constraint references will be dropped 
-- later in this script anyway and isn't used at any point after this block of code 
-- is run and isn't referenced again in the mean time.
ALTER TABLE CSR.METER_INPUT_AGGR_IND DROP CONSTRAINT FK_IND_METERINPAGGRIND;

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
		   SET measure_sid = r.consumption_measure_sid,
		       measure_conversion_id = NULL
		 WHERE app_sid = r.app_sid
		   AND meter_input_id = v_consumption_input_id
		   AND aggregator = 'SUM'
		   AND meter_type_id = r.meter_type_id
		   AND measure_sid != r.consumption_measure_sid;

		UPDATE csr.meter_input_aggr_ind
		   SET measure_sid = NULL,
		       measure_conversion_id = NULL
		 WHERE app_sid = r.app_sid
		   AND meter_input_id = v_consumption_input_id
		   AND aggregator = 'SUM'
		   AND meter_type_id = r.meter_type_id
		   AND ind_sid IS NULL;

		IF r.cost_ind_sid IS NOT NULL THEN

			INSERT INTO csr.meter_type_input (app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
			VALUES (r.app_sid, r.meter_type_id, v_cost_input_id, 'SUM', r.cost_ind_sid, r.cost_measure_sid);

			UPDATE csr.meter_input_aggr_ind
			   SET measure_sid = r.cost_measure_sid,
			       measure_conversion_id = NULL
			 WHERE app_sid = r.app_sid
			   AND meter_input_id = v_cost_input_id
			   AND aggregator = 'SUM'
			   AND meter_type_id = r.meter_type_id
			   AND measure_sid != r.cost_measure_sid;

			UPDATE csr.meter_input_aggr_ind
			   SET measure_sid = NULL,
			       measure_conversion_id = NULL
			 WHERE app_sid = r.app_sid
			   AND meter_input_id = v_cost_input_id
			   AND aggregator = 'SUM'
			   AND meter_type_id = r.meter_type_id
			   AND ind_sid IS NULL;
		END IF;
	END LOOP;

	-- Make the ind_sid and measure_sid consistent for a given meter_type in meter_input_aggr_ind
	FOR r IN (
		SELECT app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid
		  FROM csr.meter_input_aggr_ind
		 WHERE ind_sid IS NOT NULL
		 GROUP BY app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid
	) LOOP
		UPDATE csr.meter_input_aggr_ind 
		   SET ind_sid = r.ind_sid, 
		       measure_sid = r.measure_sid
		 WHERE app_sid = r.app_sid
		   AND meter_input_id = r.meter_input_id
		   AND aggregator = r.aggregator
		   AND meter_type_id = r.meter_type_id
		   AND ind_sid IS NULL;
	END LOOP;

	-- Add arbitrary inputs
	FOR r IN (
		SELECT DISTINCT app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid
		  FROM csr.meter_input_aggr_ind
		 WHERE meter_input_id >= 100
		   AND (app_sid, meter_type_id, meter_input_id, aggregator, measure_sid) NOT IN (
		 	SELECT app_sid, meter_type_id, meter_input_id, aggregator, measure_sid
		 	  FROM csr.meter_type_input
		 )
	) LOOP
		BEGIN
			INSERT INTO csr.meter_type_input (app_sid, meter_type_id, meter_input_id, aggregator, ind_sid, measure_sid)
			VALUES (r.app_sid, r.meter_type_id, r.meter_input_id, r.aggregator, r.ind_sid, r.measure_sid);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
END;
	END LOOP;

	-- Remove remaining dodgy rows as they are due to misconfigured cost on all_meter
	DELETE FROM csr.meter_input_aggr_ind
	 WHERE (app_sid, meter_type_id, meter_input_id, aggregator, NVL(measure_sid, -1)) NOT IN (
	 	SELECT app_sid, meter_type_id, meter_input_id, aggregator, NVL(measure_sid, -1) 
	 	  FROM csr.meter_type_input
	 );
END;
/
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
CREATE INDEX CSR.IX_CUSTOMER_METER_TYPE ON CSR.METER_TYPE (APP_SID);
CREATE INDEX CSR.IX_IND_METER_TYPE_INPUT ON CSR.METER_TYPE_INPUT (APP_SID, IND_SID, MEASURE_SID);
CREATE INDEX CSR.IX_METTYP_METTYPINP ON CSR.METER_TYPE_INPUT (APP_SID, METER_TYPE_ID);
CREATE INDEX CSR.IX_METINPAGG_METTYPINP ON CSR.METER_TYPE_INPUT (APP_SID, METER_INPUT_ID, AGGREGATOR);
CREATE INDEX CSR.IX_METTYPINP_METINPAGGIND ON CSR.METER_INPUT_AGGR_IND (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR, MEASURE_SID);
CREATE INDEX CSR.IX_AMETERTYPE_METINPAGGIND ON CSR.METER_INPUT_AGGR_IND (APP_SID, REGION_SID, METER_TYPE_ID);
CREATE INDEX CSR.IX_ALLMET_METRECOMPBATJOB ON CSR.METER_RECOMPUTE_BATCH_JOB (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_METTYPINP_METTYPCNGBATJOB ON CSR.METER_TYPE_CHANGE_BATCH_JOB (APP_SID, METER_TYPE_ID, METER_INPUT_ID, AGGREGATOR);
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
TRUNCATE TABLE CSRIMP.ALL_METER;
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
TRUNCATE TABLE CSRIMP.METER_TYPE;
ALTER TABLE CSRIMP.METER_TYPE ADD (
	REASON			VARCHAR2(256)	NOT NULL
);
ALTER TABLE CSRIMP.METER_TYPE DROP (
	CONSUMPTION_IND_SID,
	COST_IND_SID
) CASCADE CONSTRAINTS;
ALTER TABLE CSRIMP.METER_TYPE DROP COLUMN REASON;

TRUNCATE TABLE CSRIMP.METER_INPUT_AGGR_IND;
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
BEGIN
for r in (
  select * from all_constraints where owner='CSR' and table_name like 'ENHESA_%' and constraint_name like 'FK_%' ) loop
    execute immediate 'alter table csr.'||r.table_name||' drop constraint '||r.constraint_name;
end loop;
for r in (
  select * from all_constraints where owner='CSR' and table_name like 'ENHESA_%' and constraint_name like 'PK_%' ) loop
    execute immediate 'alter table csr.'||r.table_name||' drop constraint '||r.constraint_name;
end loop;
for r in (
  select * from all_constraints where owner='CSR' and table_name like 'ENHESA_%') loop
    execute immediate 'alter table csr.'||r.table_name||' drop constraint '||r.constraint_name;
end loop;	
END;
/
begin
for r in (
  select * from all_tab_columns where owner='CSR' and table_name like 'ENHESA_%' and column_name = 'PROTOCOL' ) loop
    execute immediate 'alter table csr.'||r.table_name||' drop column '||r.column_name;
end loop;
end;
/
begin
for r in (
  select * from all_tab_columns where owner='CSR' and table_name like 'ENHESA_%' and column_name = 'VERSION' ) loop
    execute immediate 'alter table csr.'||r.table_name||' modify('||r.column_name||' number(12, 2))';
end loop;
end;
/
drop table csr.enhesa_protocol;
ALTER TABLE CSR.ENHESA_REG_TEXT ADD VERSION_RESEARCH_DTM DATE;
ALTER TABLE csr.approval_dashboard
ADD source_scenario_run_sid NUMBER(10);
ALTER TABLE csr.approval_dashboard ADD CONSTRAINT FK_app_dash_source_scen_run
    FOREIGN KEY (app_sid, source_scenario_run_sid)
    REFERENCES csr.scenario_run(app_sid, scenario_run_sid);
ALTER TABLE csr.scheduled_stored_proc MODIFY (NEXT_RUN_DTM DEFAULT (null) NULL);
CREATE OR REPLACE PACKAGE csr.user_report_pkg
IS
END user_report_pkg;
/
CREATE OR REPLACE PACKAGE BODY csr.user_report_pkg
IS
END user_report_pkg;
/
ALTER TABLE csr.automated_export_instance
ADD is_preview number(1) default 0 NOT NULL;
ALTER TABLE csr.internal_audit_type_group ADD (
	applies_to_regions		NUMBER(1, 0),
	applies_to_users		NUMBER(1, 0),
	use_user_primary_region	NUMBER(1, 0)
);
UPDATE csr.internal_audit_type_group
   SET applies_to_regions = NVL(applies_to_regions, 1),
	   applies_to_users = NVL(applies_to_users, 0),
	   use_user_primary_region = NVL(use_user_primary_region, 0);
ALTER TABLE csr.internal_audit_type_group MODIFY (
	applies_to_regions		DEFAULT 1 NOT NULL,
	applies_to_users		DEFAULT 0 NOT NULL,
	use_user_primary_region DEFAULT 0 NOT NULL
);
ALTER TABLE csr.internal_audit_type_group ADD (
	CONSTRAINT ck_iatg_appl_to_regions CHECK (applies_to_regions IN (0,1)),
	CONSTRAINT ck_iatg_appl_to_users CHECK (applies_to_users IN (0,1)),
	CONSTRAINT ck_iatg_must_appl_to_sthng CHECK (applies_to_regions = 1 OR applies_to_users = 1),
	CONSTRAINT ck_iatg_use_usr_pri_reg CHECK (use_user_primary_region = 0 OR (use_user_primary_region = 1 AND applies_to_regions = 0 AND applies_to_users = 1))
);
ALTER TABLE csr.internal_audit_type_group ADD (
	audit_singular_label	VARCHAR2(100),
	audit_plural_label		VARCHAR2(100),
	auditee_user_label		VARCHAR2(100),
	auditor_user_label		VARCHAR2(100)
);
ALTER TABLE csr.internal_audit_type_group RENAME COLUMN group_coordinator_noun TO auditor_name_label;
UPDATE csr.internal_audit_type_group
   SET audit_singular_label = NVL(audit_singular_label, label),
	   audit_plural_label = NVL(audit_plural_label, label);
ALTER TABLE csr.internal_audit MODIFY (
	region_sid				NULL
);
ALTER TABLE csr.internal_audit ADD (
	auditee_user_sid		NUMBER(10, 0),
	CONSTRAINT ck_ia_must_appl_to_sthng CHECK (region_sid IS NOT NULL OR auditee_user_sid IS NOT NULL)
);
ALTER TABLE csr.csr_user ADD (
	primary_region_sid		NUMBER(10, 0),
	CONSTRAINT fk_primary_region_sid FOREIGN KEY (app_sid, primary_region_sid) REFERENCES csr.region(app_sid, region_sid)
);
ALTER TABLE csr.customer ADD (
	audits_on_users NUMBER(1)
);
UPDATE csr.customer SET audits_on_users = 0 WHERE audits_on_users IS NULL;
ALTER TABLE csr.customer MODIFY (
	audits_on_users DEFAULT 0 NOT NULL
);
ALTER TABLE csr.customer ADD (
	CONSTRAINT ck_audits_on_users CHECK (audits_on_users IN (0, 1))
);
ALTER TABLE chain.filter_page_column ADD (
	group_key			VARCHAR2(255)
);
DROP INDEX chain.uk_filter_table_column;
CREATE UNIQUE INDEX chain.uk_filter_table_column ON chain.filter_page_column(app_sid, card_group_id, column_name, company_tab_id, LOWER(group_key));
TRUNCATE TABLE csrimp.internal_audit_type_group;
ALTER TABLE csrimp.internal_audit_type_group ADD (
	applies_to_regions		NUMBER(1, 0),
	applies_to_users		NUMBER(1, 0),
	use_user_primary_region	NUMBER(1, 0),
	audit_singular_label	VARCHAR2(100),
	audit_plural_label		VARCHAR2(100),
	auditee_user_label		VARCHAR2(100),
	auditor_user_label		VARCHAR2(100)
);
ALTER TABLE csrimp.internal_audit_type_group RENAME COLUMN group_coordinator_noun TO auditor_name_label;
ALTER TABLE csrimp.internal_audit MODIFY (
	region_sid				NULL
);
ALTER TABLE csrimp.internal_audit ADD (
	auditee_user_sid		NUMBER(10, 0)
);
ALTER TABLE csrimp.csr_user ADD (
	primary_region_sid		NUMBER(10, 0)
);
ALTER TABLE csrimp.customer ADD (
	audits_on_users			NUMBER(1)
);
ALTER TABLE csrimp.chain_filter_page_column ADD (
	group_key			VARCHAR2(255)
);
DROP INDEX csrimp.uk_filter_table_column;
CREATE UNIQUE INDEX csrimp.uk_filter_table_column ON csrimp.chain_filter_page_column(csrimp_session_id, card_group_id, column_name, company_tab_id, LOWER(group_key));
ALTER TABLE csr.audit_non_compliance ADD (
	audit_non_compliance_id				NUMBER(10, 0),
	repeat_of_audit_nc_id				NUMBER(10, 0)
);
UPDATE csr.audit_non_compliance SET audit_non_compliance_id = csr.audit_non_compliance_id_seq.NEXTVAL;
ALTER TABLE csr.audit_non_compliance MODIFY (
	audit_non_compliance_id				NOT NULL
);
ALTER TABLE csr.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
CREATE UNIQUE INDEX csr.ix_audit_non_compliance ON csr.audit_non_compliance (app_sid, internal_audit_sid, non_compliance_id);
ALTER TABLE csr.audit_non_compliance ADD (
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(app_sid, audit_non_compliance_id),
	CONSTRAINT fk_anc_repeat_anc		FOREIGN KEY (app_sid, repeat_of_audit_nc_id)
		REFERENCES csr.audit_non_compliance (app_sid, audit_non_compliance_id)
);
TRUNCATE TABLE csrimp.audit_non_compliance;
ALTER TABLE csrimp.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csrimp.audit_non_compliance ADD (
	audit_non_compliance_id				NUMBER(10, 0) NOT NULL,
	repeat_of_audit_nc_id				NUMBER(10, 0),
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(csrimp_session_id, audit_non_compliance_id)
);
ALTER TABLE csr.non_compliance_type ADD (
	match_repeats_by_carry_fwd			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	match_repeats_by_default_ncs		NUMBER(1, 0) DEFAULT 0 NOT NULL,
	match_repeats_by_surveys			NUMBER(1, 0) DEFAULT 0 NOT NULL,
	find_repeats_in_unit				VARCHAR2(10) DEFAULT 'none' NOT NULL,
	find_repeats_in_qty					NUMBER(10, 0),
	carry_fwd_repeat_type				VARCHAR2(10) DEFAULT 'normal' NOT NULL,
	CONSTRAINT ck_nct_mtch_rpt_by_crry_fwd CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_mtch_rpt_by_dflt_ncs CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_mtch_rpt_by_surveys CHECK (match_repeats_by_carry_fwd IN (0, 1)),
	CONSTRAINT ck_nct_find_rpt_in CHECK ((find_repeats_in_unit IN ('all', 'none') AND find_repeats_in_qty IS NULL) OR
										 (find_repeats_in_unit IN ('audits', 'months', 'years') AND find_repeats_in_qty > 0)),
	CONSTRAINT ck_nct_crry_fwd_rpt_type CHECK (carry_fwd_repeat_type IN ('normal', 'as_created', 'never'))
);
ALTER TABLE csrimp.non_compliance_type ADD (
	match_repeats_by_carry_fwd			NUMBER(1, 0),
	match_repeats_by_default_ncs		NUMBER(1, 0),
	match_repeats_by_surveys			NUMBER(1, 0),
	find_repeats_in_unit				VARCHAR2(10),
	find_repeats_in_qty					NUMBER(10, 0),
	carry_fwd_repeat_type				VARCHAR2(10)
);


grant select, insert, update, delete on csrimp.meter_type_input to web_user;
grant select, insert, update on csr.meter_type_input to csrimp;
grant select on csr.meter_type_id_seq to csrimp;
grant select on aspen2.timezones_win_to_cldr to csr;
grant select on aspen2.culture to csr;
grant execute on csr.user_report_pkg to chain;
grant select,insert,update,delete on csrimp.internal_audit_type_carry_fwd to web_user;
grant insert on csr.internal_audit_type_carry_fwd to csrimp;
grant select on csr.audit_non_compliance_id_seq to csrimp;

-- Was added to create schema late. Add add them here too (conditionally) for installed customers!
DECLARE
	v_cnt	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_cnt
	  FROM all_tab_columns
	 WHERE owner = 'CSR'
	   AND table_name = 'ALL_METER'
	   AND column_name = 'LOWER_THRESHOLD_PERCENTAGE';

	-- Assume if one isn't there then they both aren't
	IF v_cnt = 0 THEN
		EXECUTE IMMEDIATE '
			ALTER TABLE csr.ALL_METER
			ADD (
			  lower_threshold_percentage NUMBER(10,2),
			  upper_threshold_percentage NUMBER(10,2)
			)';
	END IF;
END;
/


CREATE OR REPLACE VIEW csr.V$MY_USER AS
  SELECT ut.account_enabled, CASE WHEN cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID') THEN 1 ELSE 0 END is_direct_report,
		 cu.app_sid, cu.csr_user_sid, cu.email, cu.guid, cu.full_name, cu.user_name,
		 cu.friendly_name, cu.info_xml, cu.send_alerts, cu.show_portal_help, cu.donations_reports_filter_id,
		 cu.donations_browse_filter_id, cu.hidden, cu.phone_number, cu.job_title, cu.show_save_chart_warning,
		 cu.enable_aria, cu.created_dtm, cu.line_manager_sid, cu.last_modified_dtm, cu.last_logon_type_id, cu.avatar,
		 cu.avatar_last_modified_dtm, cu.avatar_sha1, cu.avatar_mime_type, cu.primary_region_sid
    FROM csr.csr_user cu
    JOIN security.user_table ut ON cu.csr_user_sid = ut.sid_id
   START WITH cu.line_manager_sid = SYS_CONTEXT('SECURITY','SID')
  CONNECT BY PRIOR cu.csr_user_sid = cu.line_manager_sid;
  
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
CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC AS
    SELECT t.app_sid, t.topic_id, t.country_code, ecn.name country, stn.status_id, stn.name status, 
        t.report_dtm, t.adoption_dtm, t.importance, t.archived, t.version topic_version, t.url, t.region_sid,
        tt.version text_version, tt.version_pub_dtm text_version_pub_dtm, tt.title, tt.abstract, tt.analysis, tt.affected_ops,
        tt.reg_citation, tt.biz_impact, t.flow_item_id, fs.label flow_state_label, fs.state_colour, fs.lookup_key state_lookup_key
      FROM csr.enhesa_topic t
      JOIN csr.enhesa_topic_text tt ON t.topic_id = tt.topic_id AND tt.lang = 'en'
      JOIN csr.enhesa_status_name stn ON t.status_id = stn.status_id AND stn.lang = 'en'
      JOIN csr.enhesa_country_name ecn ON t.country_code = ecn.country_code AND ecn.lang = 'en'
      JOIN csr.flow_item fi ON t.flow_item_id = fi.flow_item_id AND t.app_sid = fi.app_sid
      JOIN csr.flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid
    ;
CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REGION AS  
    SELECT tr.topic_id, tr.country_code, cn.name country, tr.region_code, crn.name region
      FROM csr.enhesa_topic_region tr 
      JOIN csr.enhesa_country_name cn ON tr.country_code = cn.country_code AND cn.lang = 'en'
      JOIN csr.enhesa_country_region_name crn ON tr.country_code = crn.country_code AND tr.region_code = crn.region_code AND crn.lang = 'en'
    ; 
CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_KEYWORD AS
    SELECT tk.topic_id, tk.keyword_id, kt.main, kt.category
      FROM csr.enhesa_topic_keyword tk 
      JOIN csr.enhesa_keyword_text kt ON tk.keyword_id = kt.keyword_id AND kt.lang = 'en'
    ; 
CREATE OR REPLACE VIEW csr.V$ENHESA_TOPIC_REG AS
    SELECT tr.topic_id, tr.reg_id, r.parent_reg_id, r.reg_ref, rt.title, r.ref_dtm, r.link, r.archived, r.version reg_version,
        r.reg_level, rt.version reg_text_version, rt.version_pub_dtm reg_text_version_pub_dtm
      FROM csr.enhesa_topic_reg tr
      JOIN csr.enhesa_reg r ON tr.reg_id = r.reg_id
      JOIN csr.enhesa_reg_text rt ON r.reg_id = rt.reg_id AND rt.lang = 'en'
    ;
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;
	   
CREATE OR REPLACE VIEW csr.v$audit AS
	SELECT ia.internal_audit_sid, ia.region_sid, r.description region_description, ia.audit_dtm, ia.label,
		   NVL2(ia.internal_audit_ref, atg.internal_audit_ref_prefix || ia.internal_audit_ref, null) custom_audit_id,
		   atg.internal_audit_ref_prefix, ia.internal_audit_ref, ia.ovw_validity_dtm,
		   ia.auditor_user_sid, NVL(cu.full_name, au.full_name) auditor_full_name, sr.submitted_dtm survey_completed,
		   NVL(nc.cnt, 0) open_non_compliances, ia.survey_sid, ia.auditor_name, ia.auditor_organisation,
		   r.region_type, rt.class_name region_type_class_name,
		   ia.auditee_user_sid, u.full_name auditee_full_name, u.email auditee_email,
		   SUBSTR(ia.notes, 1, 50) short_notes, ia.notes full_notes,
		   iat.internal_audit_type_id audit_type_id, iat.label audit_type_label, iat.interactive audit_type_interactive,
		   qs.label survey_label, ia.app_sid, ia.internal_audit_type_id, iat.auditor_role_sid,
		   iat.audit_contact_role_sid, ia.audit_closure_type_id, act.label closure_label, act.icon_image_filename,
		   ia.created_by_user_sid, ia.survey_response_id, ia.created_dtm, NVL(cu.email, au.email) auditor_email,
		   iat.filename template_filename, iat.assign_issues_to_role, iat.add_nc_per_question, cvru.user_giving_cover_sid cover_auditor_sid,
		   fi.flow_sid, f.label flow_label, ia.flow_item_id, fi.current_state_id, fs.label flow_state_label, fs.is_final flow_state_is_final,
		   iat.summary_survey_sid, sqs.label summary_survey_label, ia.summary_response_id, act.is_failure,
		   ia.auditor_company_sid, ac.name auditor_company_name, iat.tab_sid, iat.form_path, ia.comparison_response_id, iat.nc_audit_child_region,
		   atg.label ia_type_group_label, atg.lookup_key ia_type_group_lookup_key, atg.internal_audit_type_group_id, 
		   atg.audit_singular_label, atg.audit_plural_label, atg.auditee_user_label, atg.auditor_user_label, atg.auditor_name_label,
		   sr.overall_score survey_overall_score, sr.overall_max_score survey_overall_max_score,
		   sst.score_type_id survey_score_type_id, sr.score_threshold_id survey_score_thrsh_id, sst.label survey_score_label, sst.format_mask survey_score_format_mask,
		   ia.nc_score, iat.nc_score_type_id, NVL(ia.ovw_nc_score_thrsh_id, ia.nc_score_thrsh_id) nc_score_thrsh_id, ncst.max_score nc_max_score, ncst.label nc_score_label,
		   ncst.format_mask nc_score_format_mask,
		   CASE (atct.re_audit_due_after_type)
				WHEN 'd' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + atct.re_audit_due_after)
				WHEN 'w' THEN nvl(ia.ovw_validity_dtm, ia.audit_dtm + (atct.re_audit_due_after*7))
				WHEN 'm' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after))
				WHEN 'y' THEN nvl(ia.ovw_validity_dtm, ADD_MONTHS(ia.audit_dtm, atct.re_audit_due_after*12))
				ELSE ia.ovw_validity_dtm END next_audit_due_dtm
	  FROM csr.internal_audit ia
	  LEFT JOIN (
			SELECT auc.app_sid, auc.internal_audit_sid, auc.user_giving_cover_sid,
				   ROW_NUMBER() OVER (PARTITION BY auc.internal_audit_sid ORDER BY LEVEL DESC, uc.start_dtm DESC,  uc.user_cover_id DESC) rn,
				   CONNECT_BY_ROOT auc.user_being_covered_sid user_being_covered_sid
			  FROM csr.audit_user_cover auc
			  JOIN csr.user_cover uc ON auc.app_sid = uc.app_sid AND auc.user_cover_id = uc.user_cover_id
			 CONNECT BY NOCYCLE PRIOR auc.app_sid = auc.app_sid AND PRIOR auc.user_being_covered_sid = auc.user_giving_cover_sid
		) cvru
	    ON ia.internal_audit_sid = cvru.internal_audit_sid
	   AND ia.app_sid = cvru.app_sid AND ia.auditor_user_sid = cvru.user_being_covered_sid
	   AND cvru.rn = 1
	  LEFT JOIN csr.csr_user u ON ia.auditee_user_sid = u.csr_user_sid AND ia.app_sid = u.app_sid
	  JOIN csr.csr_user au ON ia.auditor_user_sid = au.csr_user_sid AND ia.app_sid = au.app_sid
	  LEFT JOIN csr.csr_user cu ON cvru.user_giving_cover_sid = cu.csr_user_sid AND cvru.app_sid = cu.app_sid
	  LEFT JOIN csr.internal_audit_type iat ON ia.app_sid = iat.app_sid AND ia.internal_audit_type_id = iat.internal_audit_type_id
	  LEFT JOIN csr.internal_audit_type_group atg ON atg.app_sid = iat.app_sid AND atg.internal_audit_type_group_id = iat.internal_audit_type_group_id
	  LEFT JOIN csr.v$quick_survey qs ON ia.survey_sid = qs.survey_sid AND ia.app_sid = qs.app_sid
	  LEFT JOIN csr.v$quick_survey sqs ON iat.summary_survey_sid = sqs.survey_sid AND iat.app_sid = sqs.app_sid
	  LEFT JOIN (
			SELECT anc.app_sid, anc.internal_audit_sid, COUNT(DISTINCT anc.non_compliance_id) cnt
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nnc ON anc.non_compliance_id = nnc.non_compliance_id AND anc.app_sid = nnc.app_sid
			  LEFT JOIN csr.issue_non_compliance inc ON nnc.non_compliance_id = inc.non_compliance_id AND nnc.app_sid = inc.app_sid
			  LEFT JOIN csr.issue i ON inc.issue_non_compliance_id = i.issue_non_compliance_id AND inc.app_sid = i.app_sid
			 WHERE ((nnc.is_closed IS NULL 
			   AND i.resolved_dtm IS NULL
			   AND i.rejected_dtm IS NULL
			   AND i.deleted = 0)
			    OR nnc.is_closed = 0)
			 GROUP BY anc.app_sid, anc.internal_audit_sid
			) nc ON ia.internal_audit_sid = nc.internal_audit_sid AND ia.app_sid = nc.app_sid
	  LEFT JOIN csr.v$quick_survey_response sr ON ia.survey_response_id = sr.survey_response_id AND ia.app_sid = sr.app_sid
	  LEFT JOIN csr.v$region r ON ia.app_sid = r.app_sid AND ia.region_sid = r.region_sid
	  LEFT JOIN csr.region_type rt ON r.region_type = rt.region_type
	  LEFT JOIN csr.audit_closure_type act ON ia.audit_closure_type_id = act.audit_closure_type_id AND ia.app_sid = act.app_sid
	  LEFT JOIN csr.audit_type_closure_type atct ON ia.audit_closure_type_id = atct.audit_closure_type_id AND ia.internal_audit_type_id = atct.internal_audit_type_id AND ia.app_sid = atct.app_sid
	  LEFT JOIN csr.flow_item fi
	    ON ia.app_sid = fi.app_sid AND ia.flow_item_id = fi.flow_item_id
	  LEFT JOIN csr.flow_state fs
	    ON fs.app_sid = fi.app_sid AND fs.flow_state_id = fi.current_state_id
	  LEFT JOIN csr.flow f
	    ON f.app_sid = fi.app_sid AND f.flow_sid = fi.flow_sid
	  LEFT JOIN chain.company ac
	    ON ia.auditor_company_sid = ac.company_sid AND ia.app_sid = ac.app_sid
	  LEFT JOIN score_type ncst ON ncst.app_sid = iat.app_sid AND ncst.score_type_id = iat.nc_score_type_id
	  LEFT JOIN score_type sst ON sst.app_sid = qs.app_sid AND sst.score_type_id = qs.score_type_id
	 WHERE ia.deleted = 0;
CREATE OR REPLACE VIEW csr.v$issue AS
SELECT i.app_sid, NVL2(i.issue_ref, ist.internal_issue_ref_prefix || i.issue_ref, null) custom_issue_id, i.issue_id, i.label, i.description, i.source_label, i.is_visible, i.source_url, i.region_sid, re.description region_name, i.parent_id,
	   i.issue_escalated, i.owner_role_sid, i.owner_user_sid, cuown.user_name owner_user_name, cuown.full_name owner_full_name, cuown.email owner_email, i.first_issue_log_id, i.last_issue_log_id, NVL(lil.logged_dtm, i.raised_dtm) last_modified_dtm,
	   i.is_public, i.is_pending_assignment, i.rag_status_id, itrs.label rag_status_label, itrs.colour rag_status_colour, raised_by_user_sid, raised_dtm, curai.user_name raised_user_name, curai.full_name raised_full_name, curai.email raised_email,
	   resolved_by_user_sid, resolved_dtm, cures.user_name resolved_user_name, cures.full_name resolved_full_name, cures.email resolved_email,
	   closed_by_user_sid, closed_dtm, cuclo.user_name closed_user_name, cuclo.full_name closed_full_name, cuclo.email closed_email,
	   rejected_by_user_sid, rejected_dtm, curej.user_name rejected_user_name, curej.full_name rejected_full_name, curej.email rejected_email,
	   assigned_to_user_sid, cuass.user_name assigned_to_user_name, cuass.full_name assigned_to_full_name, cuass.email assigned_to_email,
	   assigned_to_role_sid, r.name assigned_to_role_name, c.correspondent_id, c.full_name correspondent_full_name, c.email correspondent_email, c.phone correspondent_phone, c.more_info_1 correspondent_more_info_1,
	   sysdate now_dtm, due_dtm, forecast_dtm, ist.issue_type_Id, ist.label issue_type_label, ist.require_priority, ist.allow_children, ist.can_set_public, ist.show_forecast_dtm, ist.require_var_expl, ist.enable_reject_action, ist.require_due_dtm_comment,
	   i.issue_priority_id, ip.due_date_offset, ip.description priority_description,
	   CASE WHEN i.issue_priority_id IS NULL OR i.due_dtm = i.raised_dtm + ip.due_date_offset THEN 0 ELSE 1 END priority_overridden, i.first_priority_set_dtm,
	   issue_pending_val_id, i.issue_sheet_value_id, issue_survey_answer_id, issue_non_compliance_Id, issue_action_id, issue_meter_id, issue_meter_alarm_id, issue_meter_raw_data_id, issue_meter_data_source_id, issue_meter_missing_data_id, issue_supplier_id,
	   CASE WHEN closed_by_user_sid IS NULL AND resolved_by_user_sid IS NULL AND rejected_by_user_sid IS NULL AND SYSDATE > NVL(forecast_dtm, due_dtm) THEN 1 ELSE 0
	   END is_overdue,
	   CASE WHEN rrm.user_sid = SYS_CONTEXT('SECURITY', 'SID') OR i.owner_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0
	   END is_owner,
	   CASE WHEN assigned_to_user_sid = SYS_CONTEXT('SECURITY', 'SID') THEN 1 ELSE 0 --OR #### HOW + WHERE CAN I GET THE ROLES THE USER IS PART OF??
	   END is_assigned_to_you,
	   CASE WHEN i.resolved_dtm IS NULL THEN 0 ELSE 1
	   END is_resolved,
	   CASE WHEN i.closed_dtm IS NULL THEN 0 ELSE 1
	   END is_closed,
	   CASE WHEN i.rejected_dtm IS NULL THEN 0 ELSE 1
	   END is_rejected,
	   CASE
		WHEN i.closed_dtm IS NOT NULL THEN 'Closed'
		WHEN i.resolved_dtm IS NOT NULL THEN 'Resolved'
		WHEN i.rejected_dtm IS NOT NULL THEN 'Rejected'
		ELSE 'Ongoing'
	   END status, CASE WHEN ist.auto_close_after_resolve_days IS NULL THEN NULL ELSE i.allow_auto_close END allow_auto_close,
	   ist.restrict_users_to_region, ist.deletable_by_administrator, ist.deletable_by_owner, ist.deletable_by_raiser, ist.send_alert_on_issue_raised,
	   ind.ind_sid, ind.description ind_name, isv.start_dtm, isv.end_dtm, ist.owner_can_be_changed, ist.show_one_issue_popup, ist.lookup_key, ist.allow_owner_resolve_and_close,
	   CASE WHEN ist.get_assignables_sp IS NULL THEN 0 ELSE 1 END get_assignables_overridden
  FROM issue i, issue_type ist, csr_user curai, csr_user cures, csr_user cuclo, csr_user curej, csr_user cuass, csr_user cuown,  role r, correspondent c, issue_priority ip,
	   (SELECT * FROM region_role_member WHERE user_sid = SYS_CONTEXT('SECURITY', 'SID')) rrm, v$region re, issue_log lil, v$issue_type_rag_status itrs,
	   v$ind ind, issue_sheet_value isv
 WHERE i.app_sid = curai.app_sid AND i.raised_by_user_sid = curai.csr_user_sid
   AND i.app_sid = ist.app_sid AND i.issue_type_Id = ist.issue_type_id
   AND i.app_sid = cures.app_sid(+) AND i.resolved_by_user_sid = cures.csr_user_sid(+)
   AND i.app_sid = cuclo.app_sid(+) AND i.closed_by_user_sid = cuclo.csr_user_sid(+)
   AND i.app_sid = curej.app_sid(+) AND i.rejected_by_user_sid = curej.csr_user_sid(+)
   AND i.app_sid = cuass.app_sid(+) AND i.assigned_to_user_sid = cuass.csr_user_sid(+)
   AND i.app_sid = cuown.app_sid(+) AND i.owner_user_sid = cuown.csr_user_sid(+)
   AND i.app_sid = r.app_sid(+) AND i.assigned_to_role_sid = r.role_sid(+)
   AND i.app_sid = re.app_sid(+) AND i.region_sid = re.region_sid(+)
   AND i.app_sid = c.app_sid(+) AND i.correspondent_id = c.correspondent_id(+)
   AND i.app_sid = ip.app_sid(+) AND i.issue_priority_id = ip.issue_priority_id(+)
   AND i.app_sid = rrm.app_sid(+) AND i.region_sid = rrm.region_sid(+) AND i.owner_role_sid = rrm.role_sid(+)
   AND i.app_sid = lil.app_sid(+) AND i.last_issue_log_id = lil.issue_log_id(+)
   AND i.app_sid = itrs.app_sid(+) AND i.rag_status_id = itrs.rag_status_id(+) AND i.issue_type_id = itrs.issue_type_id(+)
   AND i.app_sid = isv.app_sid(+) AND i.issue_sheet_value_id = isv.issue_sheet_value_id(+)
   AND isv.app_sid = ind.app_sid(+) AND isv.ind_sid = ind.ind_sid(+)
   AND i.deleted = 0;




BEGIN
	security.user_pkg.logonadmin;
	
	-- set consumption to be mandatory
UPDATE csr.meter_input_aggregator
	   SET is_mandatory = 1
	 WHERE meter_input_id = 1;
END;
/
DELETE 
  FROM CSR.ENHESA_HEADING
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_HEADING
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, HEADING_CODE ) 
		  FROM CSR.ENHESA_HEADING 
		  ) 
	);
DELETE 
  FROM CSR.ENHESA_HEADING_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_HEADING_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, HEADING_CODE, LANG) 
		  FROM CSR.ENHESA_HEADING_TEXT 
		  ) 
	);	
DELETE 
  FROM CSR.ENHESA_RQMT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_RQMT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, QN_CODE) 
		  FROM CSR.ENHESA_RQMT 
		  ) 
	);	
DELETE 
  FROM CSR.ENHESA_RQMT_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_RQMT_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, QN_CODE, LANG ) 
		  FROM CSR.ENHESA_RQMT_TEXT 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_RQMT_DOMAIN
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_RQMT_DOMAIN
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, QN_CODE, DOMAIN ) 
		  FROM CSR.ENHESA_RQMT_DOMAIN 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_RQMT_REG_CITATION
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_RQMT_REG_CITATION
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, QN_CODE, REG_ID ) 
		  FROM CSR.ENHESA_RQMT_REG_CITATION 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_RQMT_SUP_DOC
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_RQMT_SUP_DOC
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, QN_CODE, ITEM_ID ) 
		  FROM CSR.ENHESA_RQMT_SUP_DOC 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_SUP_DOC
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_SUP_DOC
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, ITEM_ID ) 
		  FROM CSR.ENHESA_SUP_DOC 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_SUP_DOC_ITEM_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_SUP_DOC_ITEM_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, ITEM_ID, LANG ) 
		  FROM CSR.ENHESA_SUP_DOC_ITEM_TEXT 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_INTRO
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_INTRO
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, INTRO_ID ) 
		  FROM CSR.ENHESA_INTRO 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_INTRO_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_INTRO_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, INTRO_ID, LANG ) 
		  FROM CSR.ENHESA_INTRO_TEXT 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_SCRNGQN
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_SCRNGQN
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, SCRNGQN_ID ) 
		  FROM CSR.ENHESA_SCRNGQN 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_SCRNGQN_HEADING
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_SCRNGQN_HEADING
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, SCRNGQN_ID, HEADING_CODE ) 
		  FROM CSR.ENHESA_SCRNGQN_HEADING 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_SCRNGQN_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_SCRNGQN_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, SCRNGQN_ID, LANG ) 
		  FROM CSR.ENHESA_SCRNGQN_TEXT 
		  ) 
	);	
	
DELETE 
  FROM CSR.ENHESA_KEYWORD
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_KEYWORD
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, KEYWORD_ID ) 
		  FROM CSR.ENHESA_KEYWORD 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_KEYWORD_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_KEYWORD_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, KEYWORD_ID, LANG ) 
		  FROM CSR.ENHESA_KEYWORD_TEXT 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_REG
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_REG
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, REG_ID ) 
		  FROM CSR.ENHESA_REG 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_REG_HEADING
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_REG_HEADING
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, REG_ID, HEADING_CODE ) 
		  FROM CSR.ENHESA_REG_HEADING 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_REG_REGION
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_REG_REGION
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, REG_ID, COUNTRY_CODE, REGION_CODE ) 
		  FROM CSR.ENHESA_REG_REGION 
		  ) 
	);
DELETE 
  FROM CSR.ENHESA_REG_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_REG_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, REG_ID, LANG ) 
		  FROM CSR.ENHESA_REG_TEXT 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID ) 
		  FROM CSR.ENHESA_TOPIC 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_REGION
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_REGION
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, COUNTRY_CODE, REGION_CODE ) 
		  FROM CSR.ENHESA_TOPIC_REGION 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_HEADING
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_HEADING
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, HEADING_CODE ) 
		  FROM CSR.ENHESA_TOPIC_HEADING 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_REG
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_REG
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, REG_ID ) 
		  FROM CSR.ENHESA_TOPIC_REG 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_KEYWORD
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_KEYWORD
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, KEYWORD_ID ) 
		  FROM CSR.ENHESA_TOPIC_KEYWORD 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_AUTH
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_AUTH
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, ENHESA_TOPIC_AUTH_ID ) 
		  FROM CSR.ENHESA_TOPIC_AUTH 
		  ) 
	);
DELETE 
  FROM CSR.ENHESA_TOPIC_AUTH_ORG_TITLE
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_AUTH_ORG_TITLE
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, ENHESA_TOPIC_AUTH_ID, LANG ) 
		  FROM CSR.ENHESA_TOPIC_AUTH_ORG_TITLE 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_TEXT
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_TEXT
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, LANG ) 
		  FROM CSR.ENHESA_TOPIC_TEXT 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_ISSUE
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_ISSUE
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, ISSUE_ID ) 
		  FROM CSR.ENHESA_TOPIC_ISSUE 
		  ) 
	);
	
DELETE 
  FROM CSR.ENHESA_TOPIC_SCHED_TASK
 WHERE ROWID NOT IN (
	SELECT ROWID 
	  FROM CSR.ENHESA_TOPIC_SCHED_TASK
	 WHERE ROWID IN ( 
		SELECT MAX(ROWID) over ( PARTITION BY APP_SID, TOPIC_ID, ISSUE_SCHEDULED_TASK_ID ) 
		  FROM CSR.ENHESA_TOPIC_SCHED_TASK 
		  ) 
	);
	
ALTER TABLE CSR.ENHESA_LANG ADD CONSTRAINT PK_ENHESA_LANG PRIMARY KEY (LANG); 
ALTER TABLE CSR.ENHESA_LANG ADD CONSTRAINT CHK_ENHESA_LANG_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_LANG_NAME ADD CONSTRAINT PK_ENHESA_LANG_NAME PRIMARY KEY (LANG, NAME_LANG);
ALTER TABLE	CSR.ENHESA_LANG_NAME ADD CONSTRAINT FK_ENH_LANG_NAME_LANG_1 FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_LANG_NAME ADD CONSTRAINT CHK_ENHESA_LANG_NAME_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_COUNTRY ADD CONSTRAINT PK_ENHESA_COUNTRY PRIMARY KEY (COUNTRY_CODE);
ALTER TABLE	CSR.ENHESA_COUNTRY_NAME ADD CONSTRAINT PK_ENHESA_COUNTRY_NAME PRIMARY KEY (COUNTRY_CODE);
ALTER TABLE	CSR.ENHESA_COUNTRY_NAME ADD CONSTRAINT FK_ENH_COUNTRY_NM_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_COUNTRY_NAME ADD CONSTRAINT FK_ENH_COUNTRY_NM_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_COUNTRY_NAME ADD CONSTRAINT CHK_ENHESA_COUNTRY_NAME_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION ADD CONSTRAINT PK_ENHESA_COUNTRY_REGION PRIMARY KEY (COUNTRY_CODE, REGION_CODE);
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION ADD CONSTRAINT FK_ENH_COUNTRY_RG_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION_NAME ADD CONSTRAINT PK_ENHESA_COUNTRY_REGION_NAME PRIMARY KEY (COUNTRY_CODE, REGION_CODE, LANG);
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION_NAME ADD CONSTRAINT FK_ENH_COU_REG_NM_ENH_COU_REG FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION_NAME ADD CONSTRAINT FK_ENH_COU_REG_NM_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_COUNTRY_REGION_NAME ADD CONSTRAINT CHK_ENHESA_CNTRY_REG_NAME_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_STATUS ADD CONSTRAINT PK_ENHESA_STATUS PRIMARY KEY (STATUS_ID);
ALTER TABLE	CSR.ENHESA_STATUS_NAME ADD CONSTRAINT PK_ENHESA_STATUS_NAME PRIMARY KEY (STATUS_ID, LANG);
ALTER TABLE	CSR.ENHESA_STATUS_NAME ADD CONSTRAINT FK_ENHESA_STATUS_NAME_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_STATUS_NAME ADD CONSTRAINT CHK_ENHESA_STATUS_NAME_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_HEADING ADD CONSTRAINT PK_ENHESA_HEADING PRIMARY KEY (APP_SID, HEADING_CODE);
ALTER TABLE	CSR.ENHESA_HEADING_TEXT ADD CONSTRAINT PK_ENHESA_HEADING_TEXT PRIMARY KEY (APP_SID, HEADING_CODE, LANG);
ALTER TABLE	CSR.ENHESA_HEADING_TEXT ADD CONSTRAINT FK_ENHESA_HEAD_TXT_HEADING FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_HEADING_TEXT ADD CONSTRAINT FK_ENHESA_HEAD_TXT_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_HEADING_TEXT ADD CONSTRAINT CHK_ENHESA_HEADING_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_RQMT ADD CONSTRAINT PK_ENHESA_RQMT PRIMARY KEY (APP_SID, QN_CODE);
ALTER TABLE	CSR.ENHESA_RQMT ADD CONSTRAINT FK_ENHESA_RQMT_HEAD FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT ADD CONSTRAINT FK_ENHESA_RQMT_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT ADD CONSTRAINT FK_ENHESA_RQMT_REGION FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT ADD CONSTRAINT CHK_ENHESA_RQMT_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_RQMT_TEXT ADD CONSTRAINT PK_ENHESA_RQMT_TEXT PRIMARY KEY (APP_SID, QN_CODE, LANG);
ALTER TABLE	CSR.ENHESA_RQMT_TEXT ADD CONSTRAINT FK_ENHESA_RQMT_TEXT_RQMT FOREIGN KEY (APP_SID, QN_CODE) REFERENCES CSR.ENHESA_RQMT (APP_SID, QN_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT_TEXT ADD CONSTRAINT FK_ENHESA_RQMT_TEXT_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT_TEXT ADD CONSTRAINT CHK_ENHESA_RQMT_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_RQMT_DOMAIN ADD CONSTRAINT PK_ENHESA_RQMT_DOMAIN PRIMARY KEY (APP_SID, QN_CODE, DOMAIN);
ALTER TABLE	CSR.ENHESA_RQMT_DOMAIN ADD CONSTRAINT FK_ENHESA_RQMT_DOMAIN_RQMT FOREIGN KEY (APP_SID, QN_CODE) REFERENCES CSR.ENHESA_RQMT (APP_SID, QN_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT_REG_CITATION ADD CONSTRAINT PK_ENHESA_RQMT_REG_CIT PRIMARY KEY (APP_SID, QN_CODE, REG_ID);
ALTER TABLE	CSR.ENHESA_RQMT_REG_CITATION ADD CONSTRAINT FK_ENHESA_RQMT_REG_CIT_RQMT FOREIGN KEY (APP_SID, QN_CODE) REFERENCES CSR.ENHESA_RQMT (APP_SID, QN_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_RQMT_SUP_DOC ADD CONSTRAINT PK_ENHESA_RQMT_SUP_DOC PRIMARY KEY (APP_SID, QN_CODE, ITEM_ID);
ALTER TABLE	CSR.ENHESA_RQMT_SUP_DOC ADD CONSTRAINT FK_ENHESA_RQMT_SUP_DOC_RQMT FOREIGN KEY (APP_SID, QN_CODE) REFERENCES CSR.ENHESA_RQMT (APP_SID, QN_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SUP_DOC ADD CONSTRAINT PK_ENHESA_SUP_DOC PRIMARY KEY (APP_SID, ITEM_ID);
ALTER TABLE	CSR.ENHESA_SUP_DOC ADD CONSTRAINT FK_ENHESA_SUP_DOC_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SUP_DOC ADD CONSTRAINT FK_ENHESA_SUP_DOC_REGION FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SUP_DOC ADD CONSTRAINT CHK_ENHESA_SUP_DOC_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_SUP_DOC_ITEM_TEXT ADD CONSTRAINT PK_ENHESA_SUP_DOC_ITM_TEXT PRIMARY KEY (APP_SID, ITEM_ID, LANG);
ALTER TABLE	CSR.ENHESA_SUP_DOC_ITEM_TEXT ADD CONSTRAINT FK_ENHESA_SUP_DOC_ITM_TXT_DOC FOREIGN KEY (APP_SID, ITEM_ID) REFERENCES CSR.ENHESA_SUP_DOC (APP_SID, ITEM_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SUP_DOC_ITEM_TEXT ADD CONSTRAINT FK_ENHESA_SUP_DOC_ITM_TXT_LNG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SUP_DOC_ITEM_TEXT ADD CONSTRAINT CHK_ENHESA_SUP_DOC_ITM_TXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_INTRO ADD CONSTRAINT PK_ENHESA_INTRO PRIMARY KEY (APP_SID, INTRO_ID);
ALTER TABLE	CSR.ENHESA_INTRO ADD CONSTRAINT FK_ENHESA_INTRO_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_INTRO ADD CONSTRAINT FK_ENHESA_INTRO_REGION FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_INTRO ADD CONSTRAINT FK_ENHESA_INTRO_HEAD FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_INTRO ADD CONSTRAINT CHK_ENHESA_INTRO_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_INTRO_TEXT ADD CONSTRAINT PK_ENHESA_INTRO_TEXT PRIMARY KEY (APP_SID, INTRO_ID, LANG);
ALTER TABLE	CSR.ENHESA_INTRO_TEXT ADD CONSTRAINT FK_ENHESA_INTRO_TEXT_INTRO FOREIGN KEY (APP_SID, INTRO_ID) REFERENCES CSR.ENHESA_INTRO (APP_SID, INTRO_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_INTRO_TEXT ADD CONSTRAINT FK_ENHESA_INTRO_TEXT_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_INTRO_TEXT ADD CONSTRAINT CHK_ENHESA_INTRO_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_SCRNGQN ADD CONSTRAINT PK_ENHESA_SCRNGQN PRIMARY KEY (APP_SID, SCRNGQN_ID);
ALTER TABLE	CSR.ENHESA_SCRNGQN ADD CONSTRAINT FK_ENHESA_SCRNGQN_HEAD FOREIGN KEY (APP_SID, BASE_HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SCRNGQN ADD CONSTRAINT CHK_ENHESA_SCRNGQN_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_SCRNGQN_HEADING ADD CONSTRAINT PK_ENHESA_SCRNGQN_HEAD PRIMARY KEY (APP_SID, SCRNGQN_ID, HEADING_CODE);
ALTER TABLE	CSR.ENHESA_SCRNGQN_HEADING ADD CONSTRAINT FK_ENHESA_SCRNGQN_HEAD_SCQN FOREIGN KEY (APP_SID, SCRNGQN_ID) REFERENCES CSR.ENHESA_SCRNGQN (APP_SID, SCRNGQN_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SCRNGQN_HEADING ADD CONSTRAINT FK_ENHESA_SCRNGQN_HEAD_HEAD FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SCRNGQN_TEXT ADD CONSTRAINT PK_ENHESA_SCRNGQN_TEXT PRIMARY KEY (APP_SID, SCRNGQN_ID, LANG);
ALTER TABLE	CSR.ENHESA_SCRNGQN_TEXT ADD CONSTRAINT FK_ENHESA_SCRNGQN_TEXT_SCRNGQN FOREIGN KEY (APP_SID, SCRNGQN_ID) REFERENCES CSR.ENHESA_SCRNGQN (APP_SID, SCRNGQN_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SCRNGQN_TEXT ADD CONSTRAINT FK_ENHESA_SCRNGQN_TEXT_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_SCRNGQN_TEXT ADD CONSTRAINT CHK_ENHESA_SCRNGQN_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_KEYWORD ADD CONSTRAINT PK_ENHESA_KEYWORD PRIMARY KEY (APP_SID, KEYWORD_ID);
ALTER TABLE	CSR.ENHESA_KEYWORD_TEXT ADD CONSTRAINT PK_ENHESA_KEYWORD_TEXT PRIMARY KEY (APP_SID, KEYWORD_ID, LANG);
ALTER TABLE	CSR.ENHESA_KEYWORD_TEXT ADD CONSTRAINT FK_ENHESA_KEYWD_TEXT_KEYWD FOREIGN KEY (APP_SID, KEYWORD_ID) REFERENCES CSR.ENHESA_KEYWORD (APP_SID, KEYWORD_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_KEYWORD_TEXT ADD CONSTRAINT FK_ENHESA_KEYWORD_TEXT_LANG FOREIGN KEY (LANG) REFERENCES CSR.ENHESA_LANG (LANG) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_KEYWORD_TEXT ADD CONSTRAINT CHK_ENHESA_KEYWORD_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_REG ADD CONSTRAINT PK_ENHESA_REG PRIMARY KEY (APP_SID, REG_ID);
ALTER TABLE	CSR.ENHESA_REG ADD CONSTRAINT FK_ENHESA_REG_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG ADD CONSTRAINT CHK_ENH_REG_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_REG_HEADING ADD CONSTRAINT PK_ENHESA_REG_HEADING PRIMARY KEY (APP_SID, REG_ID, HEADING_CODE);
ALTER TABLE	CSR.ENHESA_REG_HEADING ADD CONSTRAINT FK_ENH_REG_HEAD_REG FOREIGN KEY (APP_SID, REG_ID) REFERENCES CSR.ENHESA_REG (APP_SID, REG_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG_HEADING ADD CONSTRAINT FK_ENH_REG_HEAD_HEAD FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG_REGION ADD CONSTRAINT PK_ENHESA_REG_REGION PRIMARY KEY (APP_SID, REG_ID, COUNTRY_CODE, REGION_CODE);
ALTER TABLE	CSR.ENHESA_REG_REGION ADD CONSTRAINT FK_ENH_REG_REGION_REG FOREIGN KEY (APP_SID, REG_ID) REFERENCES CSR.ENHESA_REG (APP_SID, REG_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG_REGION ADD CONSTRAINT FK_ENH_REG_REGION_REGION FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG_TEXT ADD CONSTRAINT PK_ENHESA_REG_TEXT PRIMARY KEY (APP_SID, REG_ID, LANG);
ALTER TABLE	CSR.ENHESA_REG_TEXT ADD CONSTRAINT FK_ENHESA_REG_TEXT_REG FOREIGN KEY (APP_SID, REG_ID) REFERENCES CSR.ENHESA_REG (APP_SID, REG_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_REG_TEXT ADD CONSTRAINT CHK_ENHESA_REG_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_TOPIC ADD CONSTRAINT PK_ENHESA_TOPIC PRIMARY KEY (APP_SID, TOPIC_ID);
ALTER TABLE	CSR.ENHESA_TOPIC ADD CONSTRAINT UK_ENHESA_TOPIC UNIQUE (APP_SID, TOPIC_ID, COUNTRY_CODE);
ALTER TABLE	CSR.ENHESA_TOPIC ADD CONSTRAINT FK_ENHESA_TOPIC_STATUS FOREIGN KEY (STATUS_ID) REFERENCES CSR.ENHESA_STATUS (STATUS_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC ADD CONSTRAINT FK_ENHESA_TOPIC_COUNTRY FOREIGN KEY (COUNTRY_CODE) REFERENCES CSR.ENHESA_COUNTRY (COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC ADD CONSTRAINT CHK_ENH_TOP_ARCHIVED CHECK (ARCHIVED IN (0,1));
ALTER TABLE	CSR.ENHESA_TOPIC_REGION ADD CONSTRAINT PK_ENHESA_TOPIC_REGION PRIMARY KEY (APP_SID, TOPIC_ID, COUNTRY_CODE, REGION_CODE);
ALTER TABLE	CSR.ENHESA_TOPIC_REGION ADD CONSTRAINT FK_ENHESA_TOP_RG_TOP FOREIGN KEY (APP_SID, TOPIC_ID, COUNTRY_CODE) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID, COUNTRY_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_REGION ADD CONSTRAINT FK_ENHESA_TOP_RG_COU_RG FOREIGN KEY (COUNTRY_CODE, REGION_CODE) REFERENCES CSR.ENHESA_COUNTRY_REGION (COUNTRY_CODE, REGION_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_HEADING ADD CONSTRAINT PK_ENHESA_TOPIC_HEADING PRIMARY KEY (APP_SID, TOPIC_ID, HEADING_CODE);
ALTER TABLE	CSR.ENHESA_TOPIC_HEADING ADD CONSTRAINT FK_ENHESA_TOP_HEAD_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_HEADING ADD CONSTRAINT FK_ENHESA_TOP_HEAD_HEAD FOREIGN KEY (APP_SID, HEADING_CODE) REFERENCES CSR.ENHESA_HEADING (APP_SID, HEADING_CODE) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_REG ADD CONSTRAINT PK_ENHESA_TOPIC_REG PRIMARY KEY (APP_SID, TOPIC_ID, REG_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_REG ADD CONSTRAINT FK_ENHESA_TOP_REG_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_REG ADD CONSTRAINT FK_ENHESA_TOP_REG_REG FOREIGN KEY (APP_SID, REG_ID) REFERENCES CSR.ENHESA_REG (APP_SID, REG_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_KEYWORD ADD CONSTRAINT PK_ENHESA_TOPIC_KEYWD PRIMARY KEY (APP_SID, TOPIC_ID, KEYWORD_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_KEYWORD ADD CONSTRAINT FK_ENHESA_TOP_KEYWD_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_KEYWORD ADD CONSTRAINT FK_ENHESA_TOP_KEYWD_KEYWD FOREIGN KEY (APP_SID, KEYWORD_ID) REFERENCES CSR.ENHESA_KEYWORD (APP_SID, KEYWORD_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH ADD CONSTRAINT PK_ENHESA_TOPIC_AUTH PRIMARY KEY (APP_SID, ENHESA_TOPIC_AUTH_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH ADD CONSTRAINT UK_ENHESA_TOPIC_AUTH UNIQUE (APP_SID, TOPIC_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH ADD CONSTRAINT FK_ENHESA_TOP_AUTH_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH_ORG_TITLE ADD CONSTRAINT PK_ENHESA_TOPIC_AUTH_ORG_TITLE PRIMARY KEY (APP_SID, ENHESA_TOPIC_AUTH_ID, LANG);
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH_ORG_TITLE ADD CONSTRAINT FK_ENH_TOP_AUTH_ORG_TIT_AUTH FOREIGN KEY (APP_SID, ENHESA_TOPIC_AUTH_ID) REFERENCES CSR.ENHESA_TOPIC_AUTH (APP_SID, ENHESA_TOPIC_AUTH_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_AUTH_ORG_TITLE ADD CONSTRAINT CHK_EN_TP_AUTH_ORG_TITLE_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_TOPIC_TEXT ADD CONSTRAINT PK_ENHESA_TOPIC_TEXT PRIMARY KEY (APP_SID, TOPIC_ID, LANG);
ALTER TABLE	CSR.ENHESA_TOPIC_TEXT ADD CONSTRAINT FK_ENHESA_TOP_TEXT_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_TEXT ADD CONSTRAINT CHK_ENHESA_TOPIC_TEXT_UC CHECK (LANG = UPPER(LANG));
ALTER TABLE	CSR.ENHESA_TOPIC_ISSUE ADD CONSTRAINT PK_ENHESA_TOPIC_ISSUE PRIMARY KEY (APP_SID, TOPIC_ID, ISSUE_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_ISSUE ADD CONSTRAINT FK_ENHESA_TOP_ISS_TOP FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
ALTER TABLE	CSR.ENHESA_TOPIC_SCHED_TASK ADD CONSTRAINT PK_ENHESA_TOPIC_SCD_TSK PRIMARY KEY (APP_SID, TOPIC_ID, ISSUE_SCHEDULED_TASK_ID);
ALTER TABLE	CSR.ENHESA_TOPIC_SCHED_TASK ADD CONSTRAINT FK_ENHESA_TOPIC_SCD_TSK_T FOREIGN KEY (APP_SID, TOPIC_ID) REFERENCES CSR.ENHESA_TOPIC (APP_SID, TOPIC_ID) ON DELETE CASCADE;
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (28174,10,'kg/(short ton.mile)',1,1,0);
INSERT INTO csr.std_measure_conversion (std_measure_conversion_id,std_measure_id,description,a,b,c) VALUES (28175,10,'g/(short ton.mile)',1,1,0);
UPDATE csr.std_factor SET std_measure_conversion_id = 28174 WHERE std_measure_conversion_id = 1237 AND std_factor_set_id = 51;
UPDATE csr.std_factor SET std_measure_conversion_id = 28175 WHERE std_measure_conversion_id = 1293 AND std_factor_set_id = 51;

DECLARE
	v_card_id	NUMBER(10);
	v_cms_card_id	NUMBER(10);		
    v_builtin_admin_act		security.security_pkg.T_ACT_ID;
BEGIN
	-- We'll login as builtin/administrator for this bit...
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security.security_pkg.SetACT(v_builtin_admin_act);
	BEGIN
		INSERT INTO chain.card_group
		(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES
		(47, 'User Data Filter', 'Allows filtering of user data', 'csr.user_report_pkg', '/csr/site/users/list/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card_group
			   SET name = 'User Data Filter', 
				   description = 'Allows filtering of user data',
				   helper_pkg = 'csr.user_report_pkg',
				   list_page_url = '/csr/site/users/list/list.acds?savedFilterSid='
			 WHERE card_group_id = 47;
	END;	
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
			 VALUES (47, 1, 'Number of users');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;
	chain.temp_card_pkg.RegisterCard(
		'User Data Filter', 
		'Credit360.Schema.Cards.UserDataFilter',
		'/csr/site/users/list/filters/UserDataFilter.js', 
		'Credit360.Users.Filters.UserDataFilter',
		NULL
	);
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 1, 1, 'Role region');
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 2, 1, 'Associated region');
	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 3, 1, 'Start point region');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'User Data Filter',
			'csr.user_report_pkg',
			chain.temp_card_pkg.GetCardId('Credit360.Users.Filters.UserDataFilter')
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE chain.filter_type
			   SET description = 'User Data Filter',
			       helper_pkg = 'csr.user_report_pkg'
			 WHERE card_id = chain.temp_card_pkg.GetCardId('Credit360.Users.Filters.UserDataFilter');
	END;
	
	
	chain.temp_card_pkg.RegisterCard(
		'CMS Data Adaptor', 
		'NPSL.Cms.Cards.CmsAdaptor',
		'/fp/cms/filters/CmsAdaptor.js', 
		'NPSL.Cms.Filters.CmsFilterAdaptor',
		NULL
	);
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Cms Adaptor Filter',
			'cms.filter_pkg',
			chain.temp_card_pkg.GetCardId('NPSL.Cms.Filters.CmsFilterAdaptor')
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE chain.filter_type
			   SET description = 'Cms Adaptor Filter',
			       helper_pkg = 'cms.filter_pkg'
			 WHERE card_id = chain.temp_card_pkg.GetCardId('NPSL.Cms.Filters.CmsFilterAdaptor');
	END;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Users.Filters.UserDataFilter';
	
	SELECT card_id
	  INTO v_cms_card_id
	  FROM chain.card
	 WHERE js_class_type = 'NPSL.Cms.Filters.CmsFilterAdaptor';
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 47, v_card_id, 0);
			 
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 47, v_cms_card_id, 1);
	END LOOP;
	
	security.user_pkg.logonadmin('');	
END;
/
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (1,'af-ZA', 'Afrikaans (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (2,'sq-AL', 'Albanian (Albania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (3,'gsw-FR', 'Alsatian (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (4,'am-ET', 'Amharic (Ethiopia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (5,'ar-DZ', 'Arabic (Algeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (6,'ar-BH', 'Arabic (Bahrain)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (7,'ar-EG', 'Arabic (Egypt)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (8,'ar-IQ', 'Arabic (Iraq)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (9,'ar-JO', 'Arabic (Jordan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (10,'ar-KW', 'Arabic (Kuwait)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (11,'ar-LB', 'Arabic (Lebanon)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (12,'ar-LY', 'Arabic (Libya)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (13,'ar-MA', 'Arabic (Morocco)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (14,'ar-OM', 'Arabic (Oman)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (15,'ar-QA', 'Arabic (Qatar)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (16,'ar-SA', 'Arabic (Saudi Arabia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (17,'ar-SY', 'Arabic (Syria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (18,'ar-TN', 'Arabic (Tunisia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (19,'ar-AE', 'Arabic (U.A.E.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (20,'ar-YE', 'Arabic (Yemen)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (21,'hy-AM', 'Armenian (Armenia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (22,'as-IN', 'Assamese (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (23,'az-Cyrl-AZ', 'Azeri (Cyrillic, Azerbaijan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (24,'az-Latn-AZ', 'Azeri (Latin, Azerbaijan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (25,'ba-RU', 'Bashkir (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (26,'eu-ES', 'Basque (Basque)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (27,'be-BY', 'Belarusian (Belarus)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (28,'bn-BD', 'Bengali (Bangladesh)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (29,'bn-IN', 'Bengali (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (30,'bs-Cyrl-BA', 'Bosnian (Cyrillic, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (31,'bs-Latn-BA', 'Bosnian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (32,'br-FR', 'Breton (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (33,'bg-BG', 'Bulgarian (Bulgaria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (34,'ca-ES', 'Catalan (Catalan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (35,'zh-CN', 'Chinese (Simplified, PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (36,'zh-SG', 'Chinese (Simplified, Singapore)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (37,'zh-HK', 'Chinese (Traditional, Hong Kong S.A.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (38,'zh-MO', 'Chinese (Traditional, Macao S.A.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (39,'zh-TW', 'Chinese (Traditional, Taiwan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (40,'co-FR', 'Corsican (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (41,'hr-HR', 'Croatian (Croatia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (42,'hr-BA', 'Croatian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (43,'cs-CZ', 'Czech (Czech Republic)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (44,'da-DK', 'Danish (Denmark)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (45,'prs-AF', 'Dari (Afghanistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (46,'dv-MV', 'Divehi (Maldives)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (47,'nl-BE', 'Dutch (Belgium)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (48,'nl-NL', 'Dutch (Netherlands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (49,'en-AU', 'English (Australia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (50,'en-BZ', 'English (Belize)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (51,'en-CA', 'English (Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (52,'en-029', 'English (Caribbean)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (53,'en-IN', 'English (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (54,'en-IE', 'English (Ireland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (55,'en-JM', 'English (Jamaica)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (56,'en-MY', 'English (Malaysia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (57,'en-NZ', 'English (New Zealand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (58,'en-PH', 'English (Republic of the Philippines)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (59,'en-SG', 'English (Singapore)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (60,'en-ZA', 'English (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (61,'en-TT', 'English (Trinidad and Tobago)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (62,'en-GB', 'English (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (63,'en-US', 'English (United States)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (64,'en-ZW', 'English (Zimbabwe)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (65,'et-EE', 'Estonian (Estonia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (66,'fo-FO', 'Faroese (Faroe Islands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (67,'fil-PH', 'Filipino (Philippines)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (68,'fi-FI', 'Finnish (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (69,'fr-BE', 'French (Belgium)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (70,'fr-CA', 'French (Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (71,'fr-FR', 'French (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (72,'fr-LU', 'French (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (73,'fr-MC', 'French (Monaco)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (74,'fr-CH', 'French (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (75,'fy-NL', 'Frisian (Netherlands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (76,'gl-ES', 'Galician (Galician)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (77,'ka-GE', 'Georgian (Georgia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (78,'de-AT', 'German (Austria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (79,'de-DE', 'German (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (80,'de-LI', 'German (Liechtenstein)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (81,'de-LU', 'German (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (82,'de-CH', 'German (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (83,'el-GR', 'Greek (Greece)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (84,'kl-GL', 'Greenlandic (Greenland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (85,'gu-IN', 'Gujarati (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (86,'ha-Latn-NG', 'Hausa (Latin, Nigeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (87,'he-IL', 'Hebrew (Israel)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (88,'hi-IN', 'Hindi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (89,'hu-HU', 'Hungarian (Hungary)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (90,'is-IS', 'Icelandic (Iceland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (91,'ig-NG', 'Igbo (Nigeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (92,'id-ID', 'Indonesian (Indonesia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (93,'iu-Latn-CA', 'Inuktitut (Latin, Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (94,'iu-Cans-CA', 'Inuktitut (Syllabics, Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (95,'ga-IE', 'Irish (Ireland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (96,'xh-ZA', 'isiXhosa (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (97,'zu-ZA', 'isiZulu (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (98,'it-IT', 'Italian (Italy)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (99,'it-CH', 'Italian (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (100,'ja-JP', 'Japanese (Japan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (101,'kn-IN', 'Kannada (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (102,'kk-KZ', 'Kazakh (Kazakhstan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (103,'km-KH', 'Khmer (Cambodia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (104,'qut-GT', 'K''iche (Guatemala)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (105,'rw-RW', 'Kinyarwanda (Rwanda)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (106,'sw-KE', 'Kiswahili (Kenya)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (107,'kok-IN', 'Konkani (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (108,'ko-KR', 'Korean (Korea)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (109,'ky-KG', 'Kyrgyz (Kyrgyzstan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (110,'lo-LA', 'Lao (Lao P.D.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (111,'lv-LV', 'Latvian (Latvia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (112,'lt-LT', 'Lithuanian (Lithuania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (113,'dsb-DE', 'Lower Sorbian (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (114,'lb-LU', 'Luxembourgish (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (115,'mk-MK', 'Macedonian (Former Yugoslav Republic of Macedonia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (116,'ms-BN', 'Malay (Brunei Darussalam)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (117,'ms-MY', 'Malay (Malaysia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (118,'ml-IN', 'Malayalam (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (119,'mt-MT', 'Maltese (Malta)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (120,'mi-NZ', 'Maori (New Zealand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (121,'arn-CL', 'Mapudungun (Chile)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (122,'mr-IN', 'Marathi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (123,'moh-CA', 'Mohawk (Mohawk)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (124,'mn-MN', 'Mongolian (Cyrillic, Mongolia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (125,'mn-Mong-CN', 'Mongolian (Traditional Mongolian, PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (126,'ne-NP', 'Nepali (Nepal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (127,'nb-NO', 'Norwegian, Bokmål (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (128,'nn-NO', 'Norwegian, Nynorsk (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (129,'oc-FR', 'Occitan (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (130,'or-IN', 'Oriya (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (131,'ps-AF', 'Pashto (Afghanistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (132,'fa-IR', 'Persian');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (133,'pl-PL', 'Polish (Poland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (134,'pt-BR', 'Portuguese (Brazil)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (135,'pt-PT', 'Portuguese (Portugal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (136,'pa-IN', 'Punjabi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (137,'quz-BO', 'Quechua (Bolivia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (138,'quz-EC', 'Quechua (Ecuador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (139,'quz-PE', 'Quechua (Peru)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (140,'ro-RO', 'Romanian (Romania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (141,'rm-CH', 'Romansh (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (142,'ru-RU', 'Russian (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (143,'sah-RU', 'Sakha (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (144,'smn-FI', 'Sami, Inari (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (145,'smj-NO', 'Sami, Lule (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (146,'smj-SE', 'Sami, Lule (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (147,'se-FI', 'Sami, Northern (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (148,'se-NO', 'Sami, Northern (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (149,'se-SE', 'Sami, Northern (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (150,'sms-FI', 'Sami, Skolt (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (151,'sma-NO', 'Sami, Southern (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (152,'sma-SE', 'Sami, Southern (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (153,'sa-IN', 'Sanskrit (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (154,'gd-GB', 'Scottish Gaelic (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (155,'sr-Cyrl-BA', 'Serbian (Cyrillic, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (156,'sr-Cyrl-ME', 'Serbian (Cyrillic, Montenegro)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (157,'sr-Cyrl-CS', 'Serbian (Cyrillic, Serbia and Montenegro (Former))');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (158,'sr-Cyrl-RS', 'Serbian (Cyrillic, Serbia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (159,'sr-Latn-BA', 'Serbian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (160,'sr-Latn-ME', 'Serbian (Latin, Montenegro)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (161,'sr-Latn-CS', 'Serbian (Latin, Serbia and Montenegro (Former))');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (162,'sr-Latn-RS', 'Serbian (Latin, Serbia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (163,'nso-ZA', 'Sesotho sa Leboa (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (164,'tn-ZA', 'Setswana (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (165,'si-LK', 'Sinhala (Sri Lanka)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (166,'sk-SK', 'Slovak (Slovakia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (167,'sl-SI', 'Slovenian (Slovenia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (168,'es-AR', 'Spanish (Argentina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (169,'es-VE', 'Spanish (Bolivarian Republic of Venezuela)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (170,'es-BO', 'Spanish (Bolivia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (171,'es-CL', 'Spanish (Chile)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (172,'es-CO', 'Spanish (Colombia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (173,'es-CR', 'Spanish (Costa Rica)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (174,'es-DO', 'Spanish (Dominican Republic)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (175,'es-EC', 'Spanish (Ecuador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (176,'es-SV', 'Spanish (El Salvador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (177,'es-GT', 'Spanish (Guatemala)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (178,'es-HN', 'Spanish (Honduras)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (179,'es-MX', 'Spanish (Mexico)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (180,'es-NI', 'Spanish (Nicaragua)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (181,'es-PA', 'Spanish (Panama)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (182,'es-PY', 'Spanish (Paraguay)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (183,'es-PE', 'Spanish (Peru)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (184,'es-PR', 'Spanish (Puerto Rico)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (185,'es-ES', 'Spanish (Spain)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (186,'es-US', 'Spanish (United States)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (187,'es-UY', 'Spanish (Uruguay)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (188,'sv-FI', 'Swedish (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (189,'sv-SE', 'Swedish (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (190,'syr-SY', 'Syriac (Syria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (191,'tg-Cyrl-TJ', 'Tajik (Cyrillic, Tajikistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (192,'tzm-Latn-DZ', 'Tamazight (Latin, Algeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (193,'ta-IN', 'Tamil (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (194,'tt-RU', 'Tatar (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (195,'te-IN', 'Telugu (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (196,'th-TH', 'Thai (Thailand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (197,'bo-CN', 'Tibetan (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (198,'tr-TR', 'Turkish (Turkey)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (199,'tk-TM', 'Turkmen (Turkmenistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (200,'uk-UA', 'Ukrainian (Ukraine)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (201,'hsb-DE', 'Upper Sorbian (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (202,'ur-PK', 'Urdu (Islamic Republic of Pakistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (203,'ug-CN', 'Uyghur (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (204,'uz-Cyrl-UZ', 'Uzbek (Cyrillic, Uzbekistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (205,'uz-Latn-UZ', 'Uzbek (Latin, Uzbekistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (206,'vi-VN', 'Vietnamese (Vietnam)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (207,'cy-GB', 'Welsh (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (208,'wo-SN', 'Wolof (Senegal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (209,'ii-CN', 'Yi (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (210,'yo-NG', 'Yoruba (Nigeria)');
	
ALTER TABLE csr.audit_non_compliance DROP CONSTRAINT fk_anc_repeat_anc;
ALTER TABLE csr.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csr.audit_non_compliance MODIFY (
	audit_non_compliance_id				NULL
);
ALTER TABLE csrimp.audit_non_compliance DROP PRIMARY KEY DROP INDEX;
ALTER TABLE csrimp.audit_non_compliance MODIFY (
	audit_non_compliance_id				NULL
);
ALTER TABLE csrimp.audit_non_compliance ADD (
	CONSTRAINT pk_audit_non_compliance	PRIMARY KEY(csrimp_session_id, internal_audit_sid, non_compliance_id)
);

BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated import instances', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can run additional automated export instances', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	INSERT INTO csr.capability (NAME, ALLOW_BY_DEFAULT) VALUES ('Can preview automated exports', 0);
EXCEPTION 
	WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
BEGIN
	FOR r IN (
		SELECT host
		  FROM csr.customer
		 WHERE app_sid IN (
			SELECT app_sid
			  FROM csr.automated_export_class
			UNION
			SELECT app_sid 
			  FROM csr.automated_import_class
		)
	)
	LOOP
		security.user_pkg.logonAdmin(r.host);
		csr.csr_data_pkg.enablecapability('Manually import automated import instances');
		csr.csr_data_pkg.enablecapability('Can run additional automated import instances');
		csr.csr_data_pkg.enablecapability('Can run additional automated export instances');
		csr.csr_data_pkg.enablecapability('Can preview automated exports');
	END LOOP;
	
	IF SYS_CONTEXT('SECURITY', 'ACT') IS NOT NULL THEN
		security.user_pkg.logoff(SYS_CONTEXT('SECURITY', 'ACT'));
	END IF;
END;
/
INSERT INTO csr.auto_exp_exporter_plugin
(plugin_id, label, exporter_assembly, outputter_assembly)
VALUES
(16, 'Barloworld Hyperion Excel', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.BarloworldExcelOutputter');
INSERT INTO csr.auto_exp_exporter_plugin
(plugin_id, label, exporter_assembly, outputter_assembly)
VALUES
(17, 'Barloworld Hyperion DSV', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.DataViewExporter', 'Credit360.AutomatedExportImport.Export.Exporters.PeriodicData.BarloworldDsvOutputter');

@latest2904_5_packages

DECLARE
	report_sid    security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.logonadmin;
	-- check for customers with reports menu item
	FOR r IN (
		SELECT c.host
		  FROM security.securable_object so
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE sid_id IN (
					SELECT sid_id 
					  FROM security.menu 
					WHERE LOWER(action) LIKE '%csr/site/auditlog/reports.acds%')
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		
		BEGIN
			-- check for corresponding SO
			report_sid := security.securableobject_pkg.GetSIDFromPath(SYS_CONTEXT('SECURITY','ACT'), SYS_CONTEXT('SECURITY','APP'), 'SqlReports/csr.csr_data_pkg.GenerateAuditReport');
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				dbms_output.put_line('fixing '|| r.host);
				csr.temp_sqlreport_pkg.EnableReport('csr.csr_data_pkg.GenerateAuditReport');
		END;
	END LOOP;
	
	security.user_pkg.logoff(security.security_pkg.getACT);
END;
/
INSERT INTO CSR.CAPABILITY (NAME,ALLOW_BY_DEFAULT) VALUES ('Edit user primary region',0);
INSERT INTO csr.flow_capability(flow_capability_id, flow_alert_class, description, perm_type, default_permission_set)
	VALUES (20, 'audit', 'Auditee', 0, 1);
	
INSERT INTO csr.module (module_id, module_name, enable_sp, description, license_warning)
	VALUES (63, 'Audits on users', 'EnableAuditsOnUsers', 'Enables audits on users.', 1);
INSERT INTO csr.internal_audit_type_carry_fwd (app_sid, from_internal_audit_type_id, to_internal_audit_type_id)
	 SELECT app_sid, internal_audit_type_id, internal_audit_type_id
	   FROM csr.internal_audit_type;
CREATE OR REPLACE PACKAGE csr.latest_xxx_pkg AS
NCT_RPT_MATCH_UNIT_NONE			CONSTANT VARCHAR2(10) := 'none';
NCT_RPT_MATCH_UNIT_ALL			CONSTANT VARCHAR2(10) := 'all';
NCT_RPT_MATCH_UNIT_AUDITS		CONSTANT VARCHAR2(10) := 'audits';
NCT_RPT_MATCH_UNIT_MONTHS		CONSTANT VARCHAR2(10) := 'months';
NCT_RPT_MATCH_UNIT_YEARS		CONSTANT VARCHAR2(10) := 'years';
NCT_CARRY_FWD_RPT_TYPE_NORMAL	CONSTANT VARCHAR2(10) := 'normal';
NCT_CARRY_FWD_RPT_TYPE_AS_CRTD	CONSTANT VARCHAR2(10) := 'as_created';
NCT_CARRY_FWD_RPT_TYPE_NEVER	CONSTANT VARCHAR2(10) := 'never';
PROCEDURE GetRepeatAuditNC(
	in_audit_non_compliance_id	IN	audit_non_compliance.audit_non_compliance_id%TYPE,
	out_audit_non_compliance_id	OUT	audit_non_compliance.audit_non_compliance_id%TYPE
);
END;
/
CREATE OR REPLACE PACKAGE BODY csr.latest_xxx_pkg AS
PROCEDURE GetRepeatAuditNC(
	in_audit_non_compliance_id	IN	audit_non_compliance.audit_non_compliance_id%TYPE,
	out_audit_non_compliance_id	OUT	audit_non_compliance.audit_non_compliance_id%TYPE
)
AS
	v_audit_non_compliance_id		audit_non_compliance.audit_non_compliance_id%TYPE := in_audit_non_compliance_id;
	v_carried_from_audit_nc_id		audit_non_compliance.audit_non_compliance_id%TYPE;
	v_audit_dtm						internal_audit.audit_dtm%TYPE;
	v_region_sid					security_pkg.T_SID_ID;
	v_non_compliance_id				non_compliance.non_compliance_id%TYPE;
	v_from_non_comp_default_id		non_compliance.from_non_comp_default_id%TYPE;
	v_question_id					non_compliance.question_id%TYPE;
	v_expr_action_id				non_compliance_expr_action.qs_expr_non_compl_action_id%TYPE;
	CURSOR v_cfg_cur IS
		SELECT match_repeats_by_carry_fwd, match_repeats_by_default_ncs, match_repeats_by_surveys,
				find_repeats_in_unit, find_repeats_in_qty, carry_fwd_repeat_type
			FROM non_compliance_type nct
			JOIN non_compliance nc ON nc.non_compliance_type_id = nct.non_compliance_type_id
			JOIN audit_non_compliance anc ON anc.non_compliance_id = nc.non_compliance_id
			WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;
	v_cfg v_cfg_cur%ROWTYPE;
BEGIN
	-- get the config from the non-compliance
	OPEN v_cfg_cur;
	FETCH v_cfg_cur INTO v_cfg;
	IF v_cfg_cur%NOTFOUND OR v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_NONE THEN
		out_audit_non_compliance_id := NULL;
		RETURN;
	END IF;
	-- find the original audit NC, if it's still there
	BEGIN
		SELECT cianc.audit_non_compliance_id
		  INTO v_carried_from_audit_nc_id
		  FROM audit_non_compliance anc
		  JOIN audit_non_compliance cianc ON cianc.non_compliance_id = anc.non_compliance_id
		  JOIN non_compliance nc ON nc.non_compliance_id = cianc.non_compliance_id
								AND nc.created_in_audit_sid = cianc.internal_audit_sid
		 WHERE anc.audit_non_compliance_id = in_audit_non_compliance_id;
	EXCEPTION
		WHEN no_data_found THEN
			v_carried_from_audit_nc_id := in_audit_non_compliance_id;
	END;
	-- if this is a carried-forward audit, find out what to do.
	IF v_audit_non_compliance_id != v_carried_from_audit_nc_id THEN
		IF v_cfg.carry_fwd_repeat_type = 'as_created' THEN
			v_audit_non_compliance_id := v_carried_from_audit_nc_id;
		ELSIF v_cfg.carry_fwd_repeat_type = 'never' THEN
			out_audit_non_compliance_id := NULL;
			RETURN;
		END IF;
	END IF;
	BEGIN
		-- get the things we could match against
		SELECT ia.audit_dtm, NVL(nc.region_sid, ia.region_sid),
			   nc.non_compliance_id, nc.from_non_comp_default_id, nc.question_id, 
			   ncea.qs_expr_non_compl_action_id
		  INTO v_audit_dtm, v_region_sid,
			   v_non_compliance_id, v_from_non_comp_default_id, v_question_id,
			   v_expr_action_id
	      FROM audit_non_compliance anc
		  JOIN internal_audit ia ON ia.internal_audit_sid = anc.internal_audit_sid
		  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
		  LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id
		 WHERE anc.audit_non_compliance_id = v_audit_non_compliance_id;
		
		WITH eligible_audits AS (
			SELECT internal_audit_sid, audit_dtm, region_sid
			  FROM (
				SELECT internal_audit_sid, audit_dtm, region_sid,
					   CASE WHEN v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS THEN
							ROW_NUMBER() OVER (PARTITION BY region_sid ORDER BY audit_dtm DESC, internal_audit_sid DESC) 
					   END audit_number
				  FROM internal_audit ia
				 WHERE ia.audit_dtm < v_audit_dtm
				   AND ia.deleted = 0
			  ) ia WHERE (
					v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_ALL OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_AUDITS AND ia.audit_number <= v_cfg.find_repeats_in_qty) OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_MONTHS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -1 * v_cfg.find_repeats_in_qty)) OR
					(v_cfg.find_repeats_in_unit = NCT_RPT_MATCH_UNIT_YEARS AND ia.audit_dtm >= ADD_MONTHS(v_audit_dtm, -12 * v_cfg.find_repeats_in_qty))
			   )
		)
		SELECT audit_non_compliance_id
		  INTO out_audit_non_compliance_id
		  FROM (
			SELECT audit_non_compliance_id, ROWNUM rn
			  FROM (
				SELECT anc.audit_non_compliance_id
				  FROM audit_non_compliance anc
				  JOIN eligible_audits ia ON ia.internal_audit_sid = anc.internal_audit_sid
				  JOIN non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id
				  LEFT JOIN non_compliance_expr_action ncea ON nc.non_compliance_id = ncea.non_compliance_id AND nc.app_sid = ncea.app_sid
				 WHERE NVL(nc.region_sid, ia.region_sid) = v_region_sid
				   AND (
						(v_cfg.match_repeats_by_carry_fwd = 1 AND nc.non_compliance_id = v_non_compliance_id) OR
						(v_cfg.match_repeats_by_default_ncs = 1 AND nc.from_non_comp_default_id = v_from_non_comp_default_id) OR
						(v_cfg.match_repeats_by_surveys = 1 AND (nc.question_id = v_question_id OR ncea.qs_expr_non_compl_action_id = v_expr_action_id))
				   )
				 ORDER BY ia.audit_dtm DESC, ia.internal_audit_sid DESC
			  )
		  ) WHERE rn = 1;
	EXCEPTION
		WHEN no_data_found THEN
			out_audit_non_compliance_id := NULL;
	END;
END;
END;
/
DECLARE
	v_repeat_of_audit_nc_id		NUMBER(10, 0);
BEGIN
	-- we only care about repeats because of repeat score so we only
	-- look at customers who have scores for repeats
	FOR s IN (
		SELECT c.app_sid, c.host, nct.non_compliance_type_id
		  FROM csr.customer c
		  JOIN csr.non_compliance_type nct ON nct.app_sid = c.app_sid
		 WHERE nct.repeat_score IS NOT NULL
		   AND c.app_sid NOT IN (34625403, 27888577)
	) LOOP
		security.user_pkg.logonadmin(s.host);
		-- these are the closest settings to what's already live.
		UPDATE csr.non_compliance_type
		   SET match_repeats_by_default_ncs = 1,
			   match_repeats_by_surveys = 1,
			   find_repeats_in_unit = 'all',
			   carry_fwd_repeat_type = 'as_created'
		 WHERE non_compliance_type_id = s.non_compliance_type_id;
		FOR r IN (
			SELECT anc.audit_non_compliance_id
			  FROM csr.audit_non_compliance anc
			  JOIN csr.non_compliance nc ON nc.non_compliance_id = anc.non_compliance_id AND nc.app_sid = anc.app_sid
			 WHERE anc.app_sid = s.app_sid
			   AND nc.non_compliance_type_id = s.non_compliance_type_id
		) LOOP
			csr.latest_xxx_pkg.GetRepeatAuditNC(
				r.audit_non_compliance_id,
				v_repeat_of_audit_nc_id
			);
			
			UPDATE csr.audit_non_compliance
			   SET repeat_of_audit_nc_id = v_repeat_of_audit_nc_id
			 WHERE audit_non_compliance_id = r.audit_non_compliance_id;
		END LOOP;
	END LOOP;
	
	security.user_pkg.logonadmin;
END;
/
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'csr.APPROVALDASHINSTANCECREATOR',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '   
          BEGIN
          security.user_pkg.logonadmin();
          csr.approval_dashboard_pkg.ScheduledInstanceCreator();
          commit;
          END;
    ',
	job_class       => 'low_priority_job',
	start_date      => to_timestamp_tz('2016/03/01 00:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
	repeat_interval => 'FREQ=DAILY',
	enabled         => TRUE,
	auto_drop       => FALSE,
	comments        => 'Schedule for automated export import framework. Check for new imports and exports to queue in batch jobs.');
END;
/

DROP PACKAGE chain.temp_card_pkg;
DROP PACKAGE csr.temp_sqlreport_pkg;

@..\meter_pkg
@..\meter_report_pkg
@..\space_pkg
@..\schema_pkg
@..\energy_star_attr_pkg
@..\batch_job_pkg
@..\enhesa_pkg
@..\approval_dashboard_pkg
@..\role_pkg
@..\..\..\aspen2\cms\db\filter_pkg
@..\chain\filter_pkg
@..\ssp_pkg
@..\csr_user_pkg
@..\user_report_pkg
@..\automated_export_pkg
@..\automated_import_pkg
@..\quick_survey_pkg;
@..\audit_pkg
@..\audit_report_pkg
@..\csr_data_pkg
@..\enable_pkg
@..\non_compliance_report_pkg
@..\issue_pkg
@..\stored_calc_datasource_pkg
@..\chain\business_relationship_pkg
@..\chain\type_capability_pkg

@..\utility_report_body
@..\csr_app_body
@..\indicator_body
@..\meter_body
@..\meter_report_body
@..\space_body
@..\property_body
@..\region_body
@..\energy_star_attr_body
@..\energy_star_job_data_body
@..\energy_star_job_body
@..\energy_star_body
@..\meter_monitor_body
@..\schema_body
@..\utility_body
@..\issue_body
@..\meter_alarm_body
@..\meter_patch_body
@..\csrimp\imp_body
@..\enhesa_body
	  
@..\meter_aggr_body
@..\approval_dashboard_body
@..\doc_body
@..\role_body
@..\..\..\aspen2\cms\db\filter_body
@..\chain\filter_body
@..\ssp_body
@..\csr_user_body
@..\user_report_body
@..\automated_export_body
@..\automated_import_body
@..\enable_body
@..\quick_survey_body;
@..\non_compliance_report_body;
@..\audit_body
@..\audit_report_body
@..\csr_data_body
@..\customer_body
@..\flow_body
@..\chain\company_user_body
@..\issue_report_body
@..\stored_calc_datasource_body
@..\portal_dashboard_body
@..\scenario_body
@..\chain\business_relationship_body
@..\chain\type_capability_body

@update_tail
