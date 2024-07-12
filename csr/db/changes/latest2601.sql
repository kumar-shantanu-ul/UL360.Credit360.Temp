--Please update version.sql too -- this keeps clean builds in sync
define version=2601
@update_header

ALTER TABLE CSR.EST_ERROR ADD(
	ACTIVE             NUMBER(1, 0)      DEFAULT 1 NOT NULL,
    CHECK (ACTIVE IN(0,1))
);

CREATE OR REPLACE VIEW CSR.V$EST_ERROR AS
	SELECT APP_SID, EST_ERROR_ID, REGION_SID, EST_ACCOUNT_SID, PM_CUSTOMER_ID, PM_BUILDING_ID, PM_SPACE_ID, PM_METER_ID,
		ERROR_LEVEL, ERROR_DTM, ERROR_CODE, ERROR_MESSAGE, REQUEST_URL, REQUEST_HEADER, REQUEST_BODY, RESPONSE
	  FROM CSR.EST_ERROR
	 WHERE ACTIVE = 1
	;
	
-- Mark errors occurring before the last 
-- job of any building or meter as inactive	
BEGIN
	security.user_pkg.logonadmin;
	
	UPDATE csr.est_error u
	   SET u.active = 0
	 WHERE u.est_error_id IN (
	 	SELECT e.est_error_id
	 	  FROM csr.est_error e, csr.est_building b
	 	 WHERE e.app_sid = b.app_sid
	 	   AND e.est_account_sid = b.est_account_sid
	   	   AND e.pm_customer_id = b.pm_customer_id
	   	   AND e.pm_building_id = b.pm_building_id
	   	   AND e.pm_meter_id IS NULL
	   	   AND e.error_dtm < b.last_job_dtm
	 );
	 
	UPDATE csr.est_error u
	   SET u.active = 0
	 WHERE u.est_error_id IN (
	 	SELECT e.est_error_id
	 	  FROM csr.est_error e, csr.est_meter m
	 	 WHERE e.app_sid = m.app_sid
	 	   AND e.est_account_sid = m.est_account_sid
	   	   AND e.pm_customer_id = m.pm_customer_id
	   	   AND e.pm_building_id = m.pm_building_id
	   	   AND e.pm_meter_id = m.pm_meter_id
	   	   AND e.error_dtm < m.last_job_dtm
	 );
END;
/

@../property_pkg	
@../energy_star_pkg

@../property_body
@../energy_star_body

@../energy_star_attr_body
@../energy_star_job_body

	
@update_tail
