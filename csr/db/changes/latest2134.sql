-- Please update version.sql too -- this keeps clean builds in sync
define version=2134

@update_header
BEGIN
	FOR r IN (
		SELECT min_fund_id, fund_id FROM (
			SELECT MIN(fund_id) OVER (PARTITION BY APP_SID, COMPANY_SID, UPPER(TRIM(NAME))) min_fund_id,
				ROW_NUMBER() OVER (PARTITION BY APP_SID, COMPANY_SID, UPPER(TRIM(NAME)) ORDER BY fund_id) rn, fund_id
			  FROM csr.fund
		) WHERE rn > 1
	)
	LOOP
		UPDATE csr.property SET fund_id = r.min_fund_id WHERE fund_id = r.fund_id;
		DELETE FROM csr.fund WHERE fund_id = r.fund_id;
	END LOOP;
END;
/

CREATE UNIQUE INDEX CSR.UK_FUND_NAME ON CSR.FUND(APP_SID, COMPANY_SID, UPPER(TRIM(NAME)));

@..\property_body

@update_tail