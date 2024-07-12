-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

BEGIN
  --dbms_output.put_line('start');
  security.user_pkg.logonadmin;
  FOR r IN (
    SELECT dv.dataview_sid sid_id, dv.name dv_name, so.name so_name, dv.app_sid 
        FROM csr.dataview dv
        JOIN SECURITY.SECURABLE_OBJECT so ON so.SID_ID = dv.DATAVIEW_SID
      WHERE REPLACE(dv.name, '/', '\') != so.name  
  )
  LOOP
    --dbms_output.put_line('Updating SO ' || r.sid_id || ' to name '||r.dv_name);
    BEGIN
    UPDATE security.securable_object so
      SET NAME = r.dv_name
    WHERE sid_id = r.sid_id;
    EXCEPTION
    WHEN dup_val_on_index THEN 
      BEGIN
        UPDATE security.securable_object so
          SET NAME = r.dv_name || ' (copy)'
        WHERE sid_id = r.sid_id;
        EXCEPTION
        WHEN dup_val_on_index THEN 
          BEGIN
            UPDATE security.securable_object so
              SET NAME = r.dv_name || ' (copy) - ' || r.app_sid
            WHERE sid_id = r.sid_id;
            EXCEPTION
            WHEN dup_val_on_index THEN 
              dbms_output.put_line('App ' || r.app_sid || ' - Duplicate name on SO ' || r.sid_id || ' - ' || r.dv_name);
          END;
      END;
    END;
  END LOOP;
  --dbms_output.put_line('done');
END;
/



-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
