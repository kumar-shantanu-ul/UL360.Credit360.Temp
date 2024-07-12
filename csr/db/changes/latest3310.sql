define version=3310
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;



ALTER TABLE campaigns.campaign_region_response ADD response_uuid VARCHAR2(64);
CREATE UNIQUE INDEX campaigns.ix_campaign_response_uuid ON campaigns.campaign_region_response (lower(response_uuid));
















@..\customer_pkg
@..\campaigns\campaign_pkg


@..\delegation_body
@..\compliance_body
@..\audit_body
@..\customer_body
@..\batch_job_body
@..\stored_calc_datasource_body
@..\campaigns\campaign_body
@..\region_set_body
@..\region_tree_body



@update_tail
