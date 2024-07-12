-- Please update version.sql too -- this keeps clean builds in sync
define version=3188
define minor_version=10
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables
ALTER TABLE chain.company ADD signature VARCHAR2(1024);
ALTER TABLE csr.region MODIFY lookup_key VARCHAR2(1024);

@@latestUS15250_packages

BEGIN
	security.user_pkg.LogonAdmin;

	-- fix some bad data...
	UPDATE chain.company_type
	   SET default_region_layout = NULL
	 WHERE UPPER(default_region_layout) = 'NULL';

	-- Process differs from what the actual package will be doing, 
	-- still the eventual result will be the same

	-- 35 secs on .sup 
	-- signature will temporarily hold the normalised name
	UPDATE chain.company c
	   SET signature = chain.latestUS15250_package.NormaliseCompanyName(c.name);

	-- 2 mins on .sup
	UPDATE security.securable_object so
	   SET so.name = (
	   	SELECT c.signature || ' (' || c.company_sid || ')'  --signature holds the normalised name
		  FROM chain.company c
		 WHERE c.app_sid = so.application_sid_id
		   AND c.company_sid = so.sid_id
	)
 	 WHERE (so.application_sid_id, so.sid_id) IN (
	 	SELECT c.app_sid, c.company_sid
	   	  FROM chain.company c
	  	 WHERE c.deleted = 0
	);

	-- 1 min on .sup
	UPDATE chain.company c
	   SET c.signature = (
		SELECT chain.latestUS15250_package.GenerateCompanySignature(
			in_normalised_name		=> c.signature,
			in_country				=> c.country_code,
			in_company_type_id		=> c.company_type_id,
			in_city					=> city,	
			in_state				=> c.state,
			in_sector_id			=> c.sector_id,
			in_layout				=> NVL(ct.default_region_layout, '{COUNTRY}/{SECTOR}'),
			in_parent_sid			=> c.parent_sid
			)
		  FROM chain.company_type ct
		 WHERE ct.app_sid = c.app_sid
		   AND ct.company_type_id = c.company_type_id
	   );

	-- Handle dupicate signatures
	FOR r IN (
		SELECT app_sid, signature
		  FROM chain.company
		 WHERE deleted = 0
		   AND pending = 0
		 GROUP BY app_sid, signature
		 HAVING COUNT(*) > 1
	)
	LOOP
		UPDATE chain.company
		   SET signature = signature || '|sid:' || company_sid||'|DUPE-VAL'
		 WHERE app_sid = r.app_sid
		   AND signature = r.signature;
	END LOOP;
END;
/

DROP PACKAGE chain.latestUS15250_package;

ALTER TABLE chain.company MODIFY signature NOT NULL;
CREATE UNIQUE INDEX CHAIN.UK_COMPANY_SIGNATURE ON CHAIN.COMPANY (APP_SID, DECODE(PENDING + DELETED, 0, LOWER(SIGNATURE), COMPANY_SID));


ALTER TABLE csrimp.chain_company ADD signature VARCHAR2(1024) NOT NULL;
ALTER TABLE csrimp.region MODIFY lookup_key VARCHAR2(1024);
-- *** Grants ***

GRANT UPDATE ON security.securable_object TO chain;
GRANT EXECUTE ON chain.helper_pkg TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../chain/helper_pkg
@../chain/company_type_pkg
@../chain/company_pkg
@../chain/test_chain_utils_pkg

@../schema_body
@../supplier_body
@../chain/helper_body
@../chain/dev_body
@../chain/company_dedupe_body
@../chain/company_type_body
@../chain/company_body
@../chain/invitation_body
@../chain/uninvited_body
@../chain/test_chain_utils_body
@../ct/supplier_body
@../csrimp/imp_body

@update_tail
