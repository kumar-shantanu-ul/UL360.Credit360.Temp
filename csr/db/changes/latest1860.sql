-- Please update version.sql too -- this keeps clean builds in sync
define version=1860
@update_header

DECLARE
  v_condition  all_constraints.search_condition%TYPE;
BEGIN
  v_condition:= 'PERMISSION IN (0, 1, 2)';
  
  FOR r IN (SELECT owner, table_name, constraint_name, search_condition
              FROM all_constraints
             WHERE (table_name = 'CMS_TAB_COLUMN_ROLE_PERMISSION' AND OWNER = 'CSRIMP' AND constraint_type = 'C')
                OR (table_name = 'TAB_COLUMN_ROLE_PERMISSION' AND OWNER = 'CMS' AND constraint_type = 'C')
  )
  LOOP
    IF r.search_condition = v_condition THEN
      EXECUTE IMMEDIATE ('ALTER TABLE ' || r.owner || '.' || r.table_name || ' DROP CONSTRAINT ' || r.constraint_name);
    END IF;
  END LOOP;

  COMMIT;
END;
/

@update_tail