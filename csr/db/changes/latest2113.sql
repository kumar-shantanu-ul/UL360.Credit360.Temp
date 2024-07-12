define version=2113
@update_header

DECLARE
  --old names of the constraints (need to be changed)
  fk1_old_name    ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
  fk2_old_name    ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
  
  --new name of the contraints
  fk1_new_name    ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
  fk2_new_name    ALL_CONSTRAINTS.CONSTRAINT_NAME%TYPE;
  
  v_query         VARCHAR2(4000);
  
BEGIN
  fk1_new_name := 'FK_MMAS_AM';
  fk2_new_name := 'FK_MASJ_AM';
  
  BEGIN
    --get the FK name from METER_METER_ALARM_STATISTIC table, we have to query it because it is different in the local-live systems
    SELECT constraint_name  
    INTO fk1_old_name
    FROM all_constraints
    WHERE owner = 'CSR' AND table_name = 'METER_METER_ALARM_STATISTIC' AND constraint_name LIKE 'REFALL_METER%';
    EXCEPTION WHEN no_data_found THEN
      NULL;
  END;
  
  IF fk1_old_name IS NOT NULL THEN
    --drop old constraint
    v_query := 'ALTER TABLE csr.METER_METER_ALARM_STATISTIC DROP CONSTRAINT '||fk1_old_name;
    EXECUTE IMMEDIATE v_query;
  END IF;
  
  IF fk1_old_name IS NOT NULL THEN
    --create new constraint
    v_query := 'ALTER TABLE csr.METER_METER_ALARM_STATISTIC ADD CONSTRAINT '||fk1_new_name||' FOREIGN KEY (APP_SID, REGION_SID) REFERENCES csr.ALL_METER(APP_SID, REGION_SID) INITIALLY DEFERRED DEFERRABLE';
    EXECUTE IMMEDIATE v_query;
  END IF;
  
  BEGIN
    --select FK name from METER_ALARM_STATISTIC_JOB table
    SELECT constraint_name 
    INTO fk2_old_name 
    FROM all_constraints
    WHERE owner = 'CSR' AND table_name = 'METER_ALARM_STATISTIC_JOB' AND constraint_name LIKE 'REFALL_METER%';
    EXCEPTION WHEN no_data_found THEN
      NULL;
  END;
  
  IF fk2_old_name IS NOT NULL THEN
    --drop old constraint
    v_query := 'ALTER TABLE csr.METER_ALARM_STATISTIC_JOB DROP CONSTRAINT '||fk2_old_name;
    EXECUTE IMMEDIATE v_query;
  end if;
  
  if fk2_old_name is not null then
    v_query := 'ALTER TABLE csr.METER_ALARM_STATISTIC_JOB ADD CONSTRAINT '||fk2_new_name||' FOREIGN KEY (APP_SID, REGION_SID) REFERENCES csr.ALL_METER(APP_SID, REGION_SID) INITIALLY DEFERRED DEFERRABLE';
    EXECUTE IMMEDIATE v_query;
  END IF;
    
    
END;
/

@update_tail