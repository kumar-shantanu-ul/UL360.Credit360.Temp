-- Run run_tests_with_coverage.sql first, then use this to generate a breakdown of the line coverage
-- The last row of output gives the grand total

COLUMN SCHEMA FORMAT A12 TRUNC

SELECT NVL(s.owner, 'Grand total:') schema,
       s.name,
       s.type,
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
	AND s.owner NOT IN ('ANONYMOUS', 'APEX_030200', 'APEX_PUBLIC_USER',
		'CTXSYS', 'DBSNMP', 'DIP', 'EXFSYS', 'FLOWS_%', 'FLOWS_FILES', 'LBACSYS',
		'MDDATA', 'MDSYS', 'MGMT_VIEW', 'OLAPSYS', 'ORACLE_OCM', 'ORDDATA',
		'ORDPLUGINS', 'ORDSYS', 'OUTLN', 'OWBSYS', 'SI_INFORMTN_SCHEMA',
		'SPATIAL_CSW_ADMIN_USR', 'SPATIAL_WFS_ADMIN_USR', 'SYS', 'SYSMAN',
		'SYSTEM', 'WKPROXY', 'WKSYS', 'WK_TEST', 'WMSYS', 'XDB', 'XS$NULL')
	AND s.type NOT IN ('TYPE', 'PACKAGE') -- only want the bodies of these
 GROUP BY GROUPING SETS ((), (s.owner, s.name, s.type))
 ORDER BY CASE WHEN s.owner IS NULL THEN 1 ELSE 0 END, pct DESC, s.owner, s.name, s.type;

