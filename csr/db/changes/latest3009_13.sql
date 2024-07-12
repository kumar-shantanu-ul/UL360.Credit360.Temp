-- Please update version.sql too -- this keeps clean builds in sync
define version=3009
define minor_version=13
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
DECLARE 
	-- Clean up dodgy meter data caused by batch servers using BST
	PROCEDURE FixMeterDates(site IN VARCHAR2)
	AS
		issue_meter_raw_data		CONSTANT NUMBER(10) := 8;
	BEGIN
		security.user_pkg.LogonAdmin(site);

		-- Reinterpret as UTC+00
		UPDATE csr.meter_source_data SET 
			start_dtm = CAST(start_dtm AS TIMESTAMP),
			end_dtm = CAST(end_dtm AS TIMESTAMP);

		UPDATE csr.meter_orphan_data SET 
			start_dtm = CAST(start_dtm AS TIMESTAMP),
			end_dtm = CAST(end_dtm AS TIMESTAMP);

		-- Raw meter issues that refer to UTC+01 timestamps are probably bogus overlaps
		UPDATE csr.issue 
		   SET deleted = 1 
		 WHERE issue_id IN (
			SELECT issue_id 
			  FROM csr.v$issue 
		     WHERE source_label = 'Meter raw data'
			   AND issue_type_id = issue_meter_raw_data
			   AND is_resolved = 0 
			   AND is_closed = 0
			   AND is_rejected = 0
			   AND REGEXP_LIKE(label, '^RAW DATA PROCESSOR: Incoming source period overlaps.*\+01:00')
		);
	EXCEPTION 
		WHEN OTHERS THEN NULL;
	END;
BEGIN
	FixMeterDates('adobe.credit360.com');
	FixMeterDates('jmfamily.credit360.com');
	FixMeterDates('yum.credit360.com'); 
	security.user_pkg.LogonAdmin(NULL);
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
