-- Please update version.sql too -- this keeps clean builds in sync
define version=2194
@update_header

-- Execute the main script conditionally
COLUMN script_name NEW_VALUE v_script_name
SELECT DECODE(cnt, 0, 'latest2194_ddl', 'latest2194_nothing') script_name
  FROM (
	SELECT COUNT(*) cnt
	  FROM all_tables
	 WHERE owner = 'CSR'
	   AND table_name = 'METER_READING_OLD'
);

@&v_script_name;

@update_tail
