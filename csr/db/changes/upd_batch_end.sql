PROMPT >> Updating csrimp schema
COLUMN script_path new_value script_path noprint;
SELECT CASE WHEN NOT EXISTS(
			SELECT * 
			  FROM all_tables 
			 WHERE owner = 'CSR' 
			   AND table_name = 'SCHEMA_TABLE')
		   THEN 'null_script.sql'
		   ELSE '..\utils\makeDynamicTables' 
	   END script_path
  FROM DUAL;
@&script_path

PROMPT >> Adding missing RLS
@..\addAppSidRLS
PROMPT >> Adding missing csrimp RLS
@..\csrimp\addSessionIdRLS
PROMPT >> Change script applied, recompiling packages...
@..\..\..\aspen2\tools\recompile_packages
exit
