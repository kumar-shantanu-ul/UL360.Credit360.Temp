Rem
Rem $Header: proftab.sql 07-oct-99.11:04:02 jmuller Exp $
Rem
Rem proftab.sql
Rem
Rem  Copyright (c) Oracle Corporation 1998, 1999. All Rights Reserved.
Rem
Rem    NAME
Rem      proftab.sql
Rem
Rem    DESCRIPTION
Rem      Create tables for the PL/SQL profiler
Rem
Rem    NOTES
Rem      The following tables are required to collect data:
Rem        plsql_profiler_runs  - information on profiler runs
Rem        plsql_profiler_units - information on each lu profiled
Rem        plsql_profiler_data  - profiler data for each lu profiled
Rem
Rem      The plsql_profiler_runnumber sequence is used for generating unique
Rem      run numbers.
Rem
Rem      The tables and sequence can be created in the schema for each user
Rem      who wants to gather profiler data. Alternately these tables can be
Rem      created in a central schema. In the latter case the user creating
Rem      these objects is responsible for granting appropriate privileges
Rem      (insert,update on the tables and select on the sequence) to all 
Rem      users who want to store data in the tables. Appropriate synonyms 
Rem      must also be created so the tables are visible from other user 
Rem      schemas.
Rem
Rem      The other tables are used for rolling up to line level; the views are
Rem      used to roll up across multiple runs. These are not required to 
Rem      collect data, but help with analysis of the gathered data. 
Rem
Rem      THIS SCRIPT DELETES ALL EXISTING DATA!
Rem
Rem    MODIFIED   (MM/DD/YY)
Rem    jmuller     10/07/99 - Fix bug 708690: TAB -> blank
Rem    astocks     04/19/99 - Add owner,related_run field to runtab
Rem    astocks     10/21/98 - Add another spare field
Rem    ciyer       09/15/98 - Create tables for profiler
Rem    ciyer       09/15/98 - Created
Rem

BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE plsql_profiler_data CASCADE CONSTRAINTS';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-00942: table or view does not exist
		IF sqlcode <> -00942 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE plsql_profiler_units CASCADE CONSTRAINTS';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-00942: table or view does not exist
		IF sqlcode <> -00942 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP TABLE plsql_profiler_runs CASCADE CONSTRAINTS';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-00942: table or view does not exist
		IF sqlcode <> -00942 THEN
			RAISE;
		END IF;
END;
/

BEGIN
	EXECUTE IMMEDIATE 'DROP SEQUENCE plsql_profiler_runnumber';
EXCEPTION
	WHEN OTHERS THEN
		-- ORA-02289: sequence does not exist
		IF sqlcode <> -02289 THEN
			RAISE;
		END IF;
END;
/

create table plsql_profiler_runs
(
  runid           number primary key,  -- unique run identifier,
                                       -- from plsql_profiler_runnumber
  related_run     number,              -- runid of related run (for client/
                                       --     server correlation)
  run_owner       varchar2(32),        -- user who started run
  run_date        date,                -- start time of run
  run_comment     varchar2(2047),      -- user provided comment for this run
  run_total_time  number,              -- elapsed time for this run
  run_system_info varchar2(2047),      -- currently unused
  run_comment1    varchar2(2047),      -- additional comment
  spare1          varchar2(256)        -- unused
);

comment on table plsql_profiler_runs is
        'Run-specific information for the PL/SQL profiler';

create table plsql_profiler_units
(
  runid              number references plsql_profiler_runs,
  unit_number        number,           -- internally generated library unit #
  unit_type          varchar2(32),     -- library unit type
  unit_owner         varchar2(32),     -- library unit owner name
  unit_name          varchar2(32),     -- library unit name
  -- timestamp on library unit, can be used to detect changes to
  -- unit between runs
  unit_timestamp     date,
  total_time         number DEFAULT 0 NOT NULL,
  spare1             number,           -- unused
  spare2             number,           -- unused
  --  
  primary key (runid, unit_number)
);

comment on table plsql_profiler_units is 
        'Information about each library unit in a run';

create table plsql_profiler_data
(
  runid           number,           -- unique (generated) run identifier
  unit_number     number,           -- internally generated library unit #
  line#           number not null,  -- line number in unit
  total_occur     number,           -- number of times line was executed
  total_time      number,           -- total time spent executing line
  min_time        number,           -- minimum execution time for this line
  max_time        number,           -- maximum execution time for this line
  spare1          number,           -- unused
  spare2          number,           -- unused
  spare3          number,           -- unused
  spare4          number,           -- unused
  --
  primary key (runid, unit_number, line#),
  foreign key (runid, unit_number) references plsql_profiler_units
);

comment on table plsql_profiler_data is 
        'Accumulated data from all profiler runs';

create sequence plsql_profiler_runnumber start with 1 nocache;

BEGIN
	DBMS_OUTPUT.PUT_LINE('Starting to run tests with profiling');
	DBMS_PROFILER.START_PROFILER(run_comment1 => 'run_tests_with_coverage');
END;
/

@all_tests

BEGIN
	DBMS_PROFILER.STOP_PROFILER;
	DBMS_OUTPUT.PUT_LINE('Done');
END;
/

set tab off

SELECT CAST(NVL2(s.owner, s.owner||'.'||s.name||' ('||s.type||')', 'Grand total:') as char(45)) object,
       COUNT(*) total_lines,
       SUM(CASE WHEN NVL(d.total_occur, 0) > 0 THEN 1 ELSE 0 END) lines_covered,
       TO_CHAR(100 * SUM(CASE WHEN NVL(d.total_occur, 0) > 0 THEN 1 ELSE 0 END) / COUNT(*), '990.00') pct
  FROM all_source s
  LEFT JOIN plsql_profiler_units u ON s.owner = u.unit_owner AND s.name = u.unit_name AND s.type = u.unit_type
  LEFT JOIN plsql_profiler_data d ON u.runid = d.runid AND u.unit_number = d.unit_number AND s.line = d.line#
 WHERE
	(
		u.runid IS NULL
		OR u.runid =
			(
				 SELECT MAX(runid)
				   FROM plsql_profiler_runs
				  WHERE run_comment1 = 'run_tests_with_coverage'
			)
	)
	AND s.owner IN ('CSR','CHAIN','CMS','SECURITY','ASPEN2','SURVEYS','FILESHARING')
	AND s.type NOT IN ('TYPE','PACKAGE') -- only want bodies
 GROUP BY GROUPING SETS ((), (s.owner, s.name, s.type))
 ORDER BY CASE WHEN s.owner IS NULL THEN 1 ELSE 0 END, pct DESC, s.owner, s.name, s.type;

set tab on
