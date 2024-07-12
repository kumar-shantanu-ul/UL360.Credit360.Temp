COLUMN script_name NEW_VALUE v_script_name
SELECT decode(version,'11.2.0.3.0','batch_trigger_old.sql','batch_trigger.sql') script_name
FROM v$instance;
set define on
@@&v_script_name
