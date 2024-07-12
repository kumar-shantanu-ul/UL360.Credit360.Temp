-- Please update version.sql too -- this keeps clean builds in sync
define version=3366
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
DECLARE
  user_count	NUMBER;
  table_count	NUMBER;
  col_count		NUMBER;
  v_plsql       VARCHAR(4000);
BEGIN
  SELECT count(*) INTO user_count FROM dba_users WHERE UPPER(username) = 'SURVEYS';
  IF user_count = 0 THEN
    BEGIN
      dbms_output.put_line('SURVEYS user does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
  
  SELECT count(*) INTO table_count FROM dba_tables WHERE UPPER(owner) = 'SURVEYS' AND UPPER(table_name) = 'RESPONSE';
  IF table_count = 0 THEN
    BEGIN
      dbms_output.put_line('SURVEYS.RESPONSE table does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
  
  SELECT count(*) INTO col_count FROM dba_tab_columns WHERE UPPER(owner) = 'SURVEYS' AND UPPER(table_name) = 'RESPONSE' AND UPPER(column_name) = 'RESPONSE_UUID';
  IF col_count = 0 THEN
	BEGIN
      dbms_output.put_line('SURVEYS.RESPONSE.RESPONSE_UUID column does not exist on this database.  Script terminated as it is not needed to be run.');
      RETURN;
    END;
  END IF;
	
  v_plsql := ' 
    DECLARE
      updated_count NUMBER := 0;
      total_count NUMBER := 0;
      batch_count NUMBER := 0;
    BEGIN
      FOR i IN (
        SELECT sr.response_id, sr.response_uuid, sr.app_sid FROM surveys.response sr
         INNER JOIN campaigns.campaign_region_response crr ON sr.app_sid = crr.app_sid AND sr.response_id = crr.response_id
         WHERE crr.response_uuid is NULL
      ) LOOP
        UPDATE campaigns.campaign_region_response SET response_uuid = i.response_uuid 
         WHERE response_id = i.response_id AND response_uuid is null AND app_sid = i.app_sid;
        IF SQL%FOUND THEN
          updated_count := updated_count + 1;
          batch_count := batch_count + 1;
        END IF;
        IF batch_count = 1000 THEN
          COMMIT;
          batch_count := 0;
        END IF;
        total_count := total_count + 1;
      END LOOP; 
      dbms_output.put_line(''campaigns.campaign_region_response GUIDs created: '' || updated_count || '' out of '' || total_count || '' rows'');
      COMMIT;
    END;';
  EXECUTE IMMEDIATE v_plsql;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
