define version=3335
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



ALTER TABLE chain.integration_request ADD (
	data_id					VARCHAR2(64)	NULL
);










UPDATE chain.integration_request
SET data_id = substr(request_url, INSTR(request_url,'/sites/', 1, 1) + LENGTH('/sites/'))
WHERE request_url like '%/sites/%';
UPDATE chain.integration_request
SET data_id = substr(request_url, INSTR(request_url,'/business-partners/', 1, 1) + LENGTH('/business-partners/'))
WHERE request_url like '%/business-partners/%';
DELETE FROM chain.integration_request
WHERE request_url IN (
  SELECT request_url FROM (
  SELECT ROWNUM n, request.request_url
    FROM chain.integration_request request
    JOIN chain.integration_request compare ON request.app_sid = compare.app_sid AND request.data_type = compare.data_type AND request.tenant_id = compare.tenant_id 
   WHERE substr(request.request_url, INSTR(request.request_url,request.tenant_id, 1, 1)) = substr(compare.request_url, INSTR(compare.request_url,compare.tenant_id, 1, 1))
     AND request.last_updated_dtm != compare.last_updated_dtm
   ORDER BY request.last_updated_dtm
  ) req
  WHERE n > 1
);
ALTER TABLE chain.integration_request MODIFY data_id NOT NULL;
ALTER TABLE chain.integration_request
DROP CONSTRAINT PK_INTEGRATION_REQUEST DROP INDEX;
ALTER TABLE chain.integration_request
ADD CONSTRAINT PK_INTEGRATION_REQUEST PRIMARY KEY (app_sid, data_type, data_id, tenant_id);






@..\chain\integration_pkg


@..\enable_body
@..\chain\integration_body
@..\supplier_body
@..\chain\company_body
@..\chain\company_filter_body
@..\quick_survey_body
@..\user_cover_body



@update_tail
