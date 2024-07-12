-- Please update version.sql too -- this keeps clean builds in sync
define version=3333
define minor_version=2
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.integration_request ADD (
	data_id					VARCHAR2(64)	NULL
);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data
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
DROP CONSTRAINT PK_INTEGRATION_REQUEST;

ALTER TABLE chain.integration_request
ADD CONSTRAINT PK_INTEGRATION_REQUEST PRIMARY KEY (app_sid, data_type, data_id, tenant_id);

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/integration_pkg
@../chain/integration_body

@update_tail
