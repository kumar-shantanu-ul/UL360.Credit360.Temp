-- Please update version.sql too -- this keeps clean builds in sync
define version=2935
define minor_version=22
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.est_error_description
(
	error_no						NUMBER(10,0),
	url_pattern						VARCHAR2(1024),
	msg_pattern						VARCHAR2(1024),
	help_text						VARCHAR2(4000),
	applies_to_space				NUMBER(1,0),
	applies_to_meter				NUMBER(1,0),
	applies_to_push					NUMBER(1,0),
	CONSTRAINT ck_eed_applies_to_space CHECK (applies_to_space IN (0,1)),
	CONSTRAINT ck_eed_applies_to_meter CHECK (applies_to_meter IN (0,1)),
	CONSTRAINT ck_eed_applies_to_push CHECK (applies_to_push IN (0,1))
);

-- Purge inactive errors (the table is huge, so this is quickest, no fks)
CREATE TABLE CSR.EST_ERROR_2 AS
SELECT * 
  FROM csr.est_error
 WHERE active = 1
    OR ADD_MONTHS(error_dtm, 1) >= SYSDATE;


-- Alter tables

-- Switch to new est_error table
ALTER TABLE CSR.EST_ERROR RENAME TO EST_ERROR_XXX;
ALTER TABLE CSR.EST_ERROR_2 RENAME TO EST_ERROR;

CREATE INDEX CSR.IX_EST_ERROR ON CSR.EST_ERROR (APP_SID, REGION_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID, ERROR_CODE, ERROR_MESSAGE, REQUEST_URL);
CREATE INDEX CSR.IX_EST_ERROR_ACTIVE_DTM ON CSR.EST_ERROR (ERROR_DTM, ACTIVE);

DROP INDEX CSR.IX_EST_ERROR_REGION;
DROP INDEX CSR.IX_EST_ERROR_ACCOUNT;
DROP INDEX CSR.IX_EST_ERROR_CUSTOMER;
DROP INDEX CSR.IX_EST_ERROR_BUILDING;
DROP INDEX CSR.IX_EST_ERROR_SPACE;
DROP INDEX CSR.IX_EST_ERROR_METER;
DROP INDEX CSR.IX_EST_ERROR_SPACE_METER;
ALTER TABLE CSR.EST_ERROR_XXX DROP CONSTRAINT PK_EST_ERROR;
ALTER TABLE CSR.EST_ERROR_XXX DROP CONSTRAINT FK_CUSTOMER_EST_ERROR;


CREATE INDEX CSR.IX_EST_ERROR_REGION ON CSR.EST_ERROR (APP_SID, REGION_SID);
CREATE INDEX CSR.IX_EST_ERROR_ACCOUNT ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID);
CREATE INDEX CSR.IX_EST_ERROR_CUSTOMER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID);
CREATE INDEX CSR.IX_EST_ERROR_BUILDING ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID);
CREATE INDEX CSR.IX_EST_ERROR_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_METER_ID);
CREATE INDEX CSR.IX_EST_ERROR_SPACE_METER ON CSR.EST_ERROR (APP_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID);

ALTER TABLE CSR.EST_ERROR ADD (
	CONSTRAINT CHK_EST_ERROR_ACTIVE_1_0 CHECK (ACTIVE IN(0,1)),
    CONSTRAINT PK_EST_ERROR PRIMARY KEY (APP_SID, EST_ERROR_ID),
	CONSTRAINT FK_CUSTOMER_EST_ERROR FOREIGN KEY (APP_SID)
		REFERENCES CSR.CUSTOMER(APP_SID)
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
CREATE OR REPLACE VIEW csr.v$est_error_description
AS
	SELECT est_error_id, help_text
	  FROM (
		SELECT est_error_id, 
			   help_text,
			   ROW_NUMBER() OVER(PARTITION BY e.est_error_id ORDER BY e.error_code) ix 
		  FROM csr.est_error e
		  LEFT JOIN csr.property p ON p.region_sid = e.region_sid
		  LEFT JOIN csr.est_space s ON s.pm_space_id = e.pm_space_id
		  LEFT JOIN csr.est_meter m ON m.pm_meter_id = e.pm_meter_id
		  LEFT JOIN csr.est_building b ON b.pm_building_id = e.pm_building_id
		  LEFT JOIN csr.property sp ON sp.region_sid = s.region_sid
		  LEFT JOIN csr.property mp ON mp.region_sid = m.region_sid
		  LEFT JOIN csr.property bp ON bp.region_sid = b.region_sid
		  LEFT JOIN csr.est_error_description ed 
			ON e.error_code = ed.error_no
		   AND (e.request_url IS NULL OR 
				ed.msg_pattern IS NULL OR 
				REGEXP_LIKE(e.request_url, ed.url_pattern, 'i'))
		   AND (ed.msg_pattern IS NULL OR 
				REGEXP_LIKE(e.error_message, ed.msg_pattern, 'i'))
		   AND ((ed.applies_to_space = 1 AND e.pm_space_id IS NOT NULL) OR 
				(ed.applies_to_meter = 1 AND e.pm_meter_id IS NOT NULL) OR 
				(ed.applies_to_push = 1 AND (
					p.energy_star_push = 1 OR 
					sp.energy_star_push = 1 OR
					mp.energy_star_push = 1 OR 
					bp.energy_star_push = 1)
				)
			)
	 )
	 WHERE ix = 1;

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^404 - meter does not exist', 'The meter has been edited in cr360, but the meter has been deleted in Energy Star. Please restore the meter in Energy Star or delete it in cr360.', 0, 1, 1);

	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^404 - meter consumption data does not exist', 'The reading has been edited in cr360, but the reading has been deleted in Energy Star. Please restore the reading in Energy Star or delete it in cr360.', 0, 1, 1);

	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, 'consumptiondata'	, '^404 - $', 'The meter or its readings have been edited in cr360, but the meter or its readings have been deleted in Energy Star. Please restore the meter or readings in Energy Star or delete them in cr360.', 0, 1, 1);

	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, 'meter', '^404 - $', 'The meter has been edited in cr360, but the meter has been deleted in Energy Star. Please restore the meter in Energy Star or delete it in cr360.', 0, 1, 1);

	INSERT INTO csr.est_error_description(error_no, url_pattern, msg_pattern, help_text, applies_to_space, applies_to_meter, applies_to_push)
		 VALUES (404, NULL, '^error retrieving rest response', 'Energy Star is currently unavailable.', 0, 1, 1);
END;
/

-- De-dupe a shed-load of est_error rows
BEGIN
	DELETE FROM csr.est_error err
	 WHERE err.est_error_id NOT IN (
	  SELECT MAX(est_error_id)
	    FROM csr.est_error
	   GROUP BY region_sid, est_account_sid, pm_customer_id, pm_building_id, pm_space_id, pm_meter_id, error_code, error_message, request_url
	 );
END;
/

DECLARE
    job BINARY_INTEGER;
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
       job_name             => 'csr.PurgeInactiveEnergyStarErrors',
       job_type             => 'PLSQL_BLOCK',
       job_action           => 'csr.energy_star_pkg.PurgeInactiveErrors;',
       job_class            => 'low_priority_job',
       start_date           => to_timestamp_tz('2008/01/01 05:00 +00:00','YYYY/MM/DD HH24:MI TZH:TZM'),
       repeat_interval      => 'FREQ=DAILY',
       enabled              => TRUE,
       auto_drop            => FALSE,
       comments             => 'Deletes inactive energy star errors that are older than a month');
END;
/

COMMIT;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../energy_star_pkg
@../energy_star_body
@../energy_star_job_data_body

@update_tail
