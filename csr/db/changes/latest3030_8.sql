-- Please update version.sql too -- this keeps clean builds in sync
define version=3030
define minor_version=8
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

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- THIS TAKES ABOUT 1 MINUTE TO RUN ON WEMBLEY
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
BEGIN
	security.user_pkg.logonadmin;
	FOR a IN (
		-- Quickly find likely apps (matching the log message globally is slow because it's a CLOB)
		SELECT DISTINCT app_sid 
		  FROM csr.issue 
		 WHERE issue_meter_raw_data_id IS NOT NULL
	) LOOP
		-- Update the issue labels (strip out the date times)
		FOR i IN (
			SELECT issue_id, 
				TRIM(REGEXP_REPLACE(label, 
					'^(.*RAW DATA PROCESSOR.*)\(' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					' - ' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					'\).*$', '\1')) clean_label
			 FROM csr.issue
			WHERE app_sid = a.app_sid
			   AND issue_meter_raw_data_id IS NOT NULL
			   AND REGEXP_LIKE (label,
				'^.*RAW DATA PROCESSOR.*\(' ||
				'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
				' - ' ||
				'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
				'\).*$')
		) LOOP
			 UPDATE csr.issue
			    SET label = i.clean_label
			  WHERE app_sid = a.app_sid
			    AND issue_id = i.issue_id;
		END LOOP;

		-- Parameterise the issue log entries
		FOR i IN (
			SELECT x.issue_id, x.issue_log_id, x.param_message,
				TO_CHAR(TO_TIMESTAMP_TZ(CAST (x.start_dtm AS VARCHAR2(64)), 'DD-MON-YY HH24.MI.SS.FF5 TZH:TZM'), 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM') iso_start_dtm,
				TO_CHAR(TO_TIMESTAMP_TZ(CAST (x.end_dtm AS VARCHAR2(64)), 'DD-MON-YY HH24.MI.SS.FF5 TZH:TZM'), 'YYYY-MM-DD"T"HH24:MI:SS.FF3TZH:TZM') iso_end_dtm
			  FROM (
				SELECT l.issue_id, l.issue_log_id, l.message,
					REGEXP_REPLACE(l.message, 
						'^(.*RAW DATA PROCESSOR.*)\(' ||
						'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
						' - ' ||
						'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
						'\)(.*)$', '\1({0:ISO} - {1:ISO})\2') param_message,
					REGEXP_REPLACE(l.message, 
						'^.*RAW DATA PROCESSOR.*\(' ||
						'([0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9])' ||
						' - .+\).*$', '\1') start_dtm,
					REGEXP_REPLACE(l.message, 
						'^.*RAW DATA PROCESSOR.*\(.+ - ' ||
						'([0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9])' ||
						'\).*$', '\1') end_dtm
				  FROM csr.issue_log l
				  JOIN csr.issue i ON i.issue_id = l.issue_id AND i.issue_meter_raw_data_id IS NOT NULL
				 WHERE l.app_sid = a.app_sid
				   AND l.message LIKE '%RAW DATA PROCESSOR%' -- This really speeds up the query, presumably something to do with the fact the message is in a CLOB
				   AND REGEXP_LIKE (l.message,
					'^.*RAW DATA PROCESSOR.*\(' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					' - ' ||
					'[0-3][0-9]-[A-Z][A-Z][A-Z]-[0-1][0-9] [0-2][0-9]\.[0-5][0-9]\.[0-5][0-9]\.[0-9]+ [+|-][0-2][0-9]:[0-5][0-9]' ||
					'\).*$'
				)
			) x
		) LOOP
			-- Switch out the message and fill in the params
			UPDATE csr.issue_log
			   SET message = i.param_message,
			       param_1 = i.iso_start_dtm,
			       param_2 = i.iso_end_dtm
			 WHERE app_sid = a.app_sid
			   AND issue_id = i.issue_id
			   AND issue_log_id = i.issue_log_id;
		END LOOP;
	END LOOP;
END;
/


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../meter_monitor_pkg
@../meter_monitor_body

@update_tail
