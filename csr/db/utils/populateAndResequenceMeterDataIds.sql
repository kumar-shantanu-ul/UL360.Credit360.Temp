-- Preamble

--disable
UPDATE csr.metering_options
   SET raw_feed_data_jobs_enabled = 0;

DECLARE
	v_count NUMBER := -1;
BEGIN
	WHILE v_count <> 0 LOOP

		SELECT COUNT(*)
		  INTO v_count
		  FROM csr.batch_job
		WHERE batch_job_type_id = 13
		   AND running_on IS NOT NULL;
	
		dbms_output.put_line('Jobs remaining: ' || v_count);
		IF v_count <> 0 THEN
			sys.dbms_lock.sleep(10);
		END IF;
	END LOOP;
END;
/

-- Stage1
-- rename existing col
ALTER TABLE CSR.METER_LIVE_DATA RENAME COLUMN meter_data_id_old TO meter_data_id_old_1;

ALTER TABLE CSR.METER_LIVE_DATA RENAME COLUMN meter_data_id TO meter_data_id_old;
ALTER TABLE CSR.METER_LIVE_DATA DROP CONSTRAINT UK_METER_DATA_ID;
-- old col will need to allow nulls
ALTER TABLE CSR.METER_LIVE_DATA MODIFY meter_data_id_old NULL;

-- reset existing sequence based on current number of records
DECLARE
	v_count		NUMBER;
BEGIN
	-- get current value + 1
	SELECT CSR.METER_DATA_ID_SEQ.NEXTVAL 
	  INTO v_count
	  FROM dual;
	dbms_output.put_line('seq currently at '||v_count);
	IF v_count > 1 THEN
		-- increment back to 1
		EXECUTE IMMEDIATE 'ALTER SEQUENCE CSR.METER_DATA_ID_SEQ INCREMENT BY '||(-v_count+1);
		-- and select it
		SELECT CSR.METER_DATA_ID_SEQ.NEXTVAL 
		  INTO v_count
		  FROM dual;
	END IF;

	-- get desired setting
	SELECT COUNT(*)
	  INTO v_count
	  FROM csr.meter_live_data;

	-- increment to desired setting - 1
	EXECUTE IMMEDIATE 'ALTER SEQUENCE CSR.METER_DATA_ID_SEQ INCREMENT BY '||(v_count-1);
	-- and select it
	SELECT CSR.METER_DATA_ID_SEQ.NEXTVAL 
	  INTO v_count
	  FROM dual;

	-- ensure next select inc's by 1.
	EXECUTE IMMEDIATE 'ALTER SEQUENCE CSR.METER_DATA_ID_SEQ INCREMENT BY 1';
	dbms_output.put_line('seq now at '||v_count);
END;
/

-- add new column (empty)
ALTER TABLE CSR.METER_LIVE_DATA ADD ( meter_data_id NUMBER(10) );


-- Stage2
CREATE SEQUENCE CSR.METER_DATA_ID_RESEQ;

-- Re-id the records in no particular order
UPDATE csr.meter_live_data
   SET meter_data_id = CSR.METER_DATA_ID_RESEQ.NEXTVAL
 WHERE meter_data_id IS NULL;


-- Stage3
-- Only continue here if all the id's have been populated

ALTER TABLE CSR.METER_LIVE_DATA MODIFY meter_data_id NOT NULL;
-- Add a unique constraint for the meter_data_id
ALTER TABLE CSR.METER_LIVE_DATA ADD (
	CONSTRAINT UK_METER_DATA_ID UNIQUE (APP_SID, METER_DATA_ID)
);

-- No longer need the temporary resequencer
DROP SEQUENCE CSR.METER_DATA_ID_RESEQ;

ALTER TABLE CSR.METER_LIVE_DATA DROP COLUMN meter_data_id_old_1;
ALTER TABLE CSR.METER_LIVE_DATA DROP COLUMN meter_data_id_old;


--reenable
UPDATE csr.metering_options
   SET raw_feed_data_jobs_enabled = 1;


-- recompile in case anything got invalidated.
@..\..\..\aspen2\tools\recompile_packages
