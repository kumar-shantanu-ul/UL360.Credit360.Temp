SET DEFINE OFF
SET DEFINE &

DECLARE
	v_has_minor		number;
BEGIN
	IF NVL('&ignore_version','0') != '1' THEN
		SELECT COUNT(*)
		  INTO v_has_minor
		  FROM all_tab_columns
		 WHERE table_name = 'VERSION'
		   AND owner = 'CSR'
		   AND column_name = 'MINOR_VERSION';

		IF v_has_minor > 0 THEN
			EXECUTE IMMEDIATE 'UPDATE csr.version SET db_version = :1, minor_version = :2' USING &version, &minor_version;
		ELSE
			UPDATE csr.version 
			   SET db_version    = &version;
		END IF;
	END IF;

	COMMIT;
END;
/

PROMPT >> Updating csrimp schema
COLUMN script_path new_value script_path noprint;
SELECT CASE WHEN '&batch_apply' = '1' OR NOT EXISTS(
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
column script_path new_value script_path noprint;
select decode('&batch_apply', '1', 'null_script.sql', '..\addAppSidRLS') script_path from dual;
PROMPT Running &script_path
@&script_path
column script_path new_value script_path noprint;
select decode('&batch_apply', '1', 'null_script.sql', '..\csrimp\addSessionIdRLS') script_path from dual;
PROMPT Running &script_path
@&script_path

PROMPT >> Checking for high risk invalidated packages...
COLUMN high_risk_packages FORMAT a75
SELECT owner||'.'||object_name||' ('||object_type||')' high_risk_packages
  FROM dba_objects
 WHERE status != 'VALID' 
   AND object_type in ('PACKAGE BODY') 
   AND (owner = 'CSR' AND object_name IN ('REGION_PKG', 'INDICATOR_PKG', 'SHEET_PKG', 'STORED_CALC_DATASOURCE_PKG', 'SECTION_PKG', 'DELEGATION_PKG', 'ALERT_PKG', 'FLOW_PKG'))
 ORDER BY owner, object_name;

PROMPT >> The high risk packages are frequently used by long running jobs (batch job/scrag/scheduled tasks) 
PROMPT >> which are likely to cause blocking sessions when recompiling. Consider stopping the jobs before 
PROMPT >> the release; releasing out of hours; and monitoring blocking sessions during the recompile.
PROMPT
PROMPT >> Getting invalid object count...
SELECT COUNT(*) invalid_object_count
  FROM dba_objects
 WHERE object_type in ('PACKAGE', 'PACKAGE BODY', 'FUNCTION', 'PROCEDURE', 'VIEW', 'TRIGGER') AND
       status != 'VALID';
	   
PROMPT >> A high invalid object count means the recompile will take longer. It does not necessarily mean
PROMPT >> that the recompile will be blocked by another session. Be sure to check that any blockers
PROMPT >> listed using the select below are not your recompile command before running murderBlockers.
PROMPT
PROMPT >> Change script applied, recompiling packages...
PROMPT >> If this does not complete within ~15s (might be longer if the invalid object count above was high)
PROMPT >> then it is likely to be being blocked by another session.  This session can be found 
PROMPT >> using the following SQL:
PROMPT >> 
PROMPT >> select s2.sid,s2.serial#,s2.username,s2.status,s2.osuser,s2.machine,
PROMPT >>        s2.program, s1.sid blocked_sid,s1.serial# blocked_serial,
PROMPT >>        s1.username blocked_username,s1.status blocked_status,
PROMPT >>        s1.osuser blocked_osuser,s1.machine blocked_machine,
PROMPT >>        s1.program blocked_program
PROMPT >>   from v$session s1, v$session s2
PROMPT >>  where s1.blocking_session is not null
PROMPT >>    and s1.blocking_session = s2.sid; 
PROMPT >> 
PROMPT >> Or get a summary using this script:
PROMPT >> @..\utils\blockedSessionsSummary
PROMPT >> 
PROMPT >> Murder the blockers using:
PROMPT >> @..\utils\murderBlockers
   
column script_path new_value script_path noprint;
select decode('&batch_apply', '1', 'null_script.sql', '..\..\..\aspen2\tools\recompile_packages') script_path from dual;
PROMPT Running &script_path
@&script_path

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
