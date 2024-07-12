-- Please update version.sql too -- this keeps clean builds in sync
define version=1200
@update_header

CREATE GLOBAL TEMPORARY TABLE CT.TT_SUPPLIER_SEARCH
(
	SUPPLIER_ID NUMBER(10) NOT NULL,
	PURCHASES NUMBER(20,10) NOT NULL
) ON COMMIT DELETE ROWS;

ALTER TABLE CHAIN.FILE_UPLOAD ADD LAST_MODIFIED_BY_SID NUMBER(10, 0);

ALTER TABLE CHAIN.FILE_UPLOAD ADD CONSTRAINT FU_CU_LAST_MODIFIED_BY_SID
    FOREIGN KEY (APP_SID, LAST_MODIFIED_BY_SID)
    REFERENCES CHAIN.CHAIN_USER(APP_SID, USER_SID);
	
grant select, references on chain.worksheet_file_upload to CT;

-- Create temp package are used by new view below (they get rebuilt at end)
CREATE OR REPLACE PACKAGE ct.util_pkg AS
	FUNCTION GetConversionToDollar (
		in_currency_id					IN  currency_period.currency_id%TYPE,
		in_date							IN  DATE
	) RETURN currency_period.conversion_to_dollar%TYPE;

	FUNCTION GetConversionFromDollar (
		in_currency_id					IN  currency_period.currency_id%TYPE,
		in_date							IN  DATE
	) RETURN currency_period.conversion_to_dollar%TYPE;
END util_pkg;
/

CREATE OR REPLACE PACKAGE BODY ct.util_pkg AS
	FUNCTION GetConversionToDollar (
		in_currency_id					IN  currency_period.currency_id%TYPE,
		in_date							IN  DATE
	) RETURN currency_period.conversion_to_dollar%TYPE
	AS
		v_conversion_to_dollar			currency_period.conversion_to_dollar%TYPE;
	BEGIN
		SELECT conversion_to_dollar
		  INTO v_conversion_to_dollar
		  FROM currency_period
		 WHERE currency_id = in_currency_id
		   AND period_id = (
			SELECT period_id
			  FROM (
				  SELECT period_id 
					FROM period 
				ORDER BY ABS(TO_DATE(description, 'YYYY') - in_date))
			 WHERE rownum = 1
		);
		
		RETURN v_conversion_to_dollar;
	END;

	FUNCTION GetConversionFromDollar (
		in_currency_id					IN  currency_period.currency_id%TYPE,
		in_date							IN  DATE
	) RETURN currency_period.conversion_to_dollar%TYPE
	AS
	BEGIN
		RETURN 1/GetConversionToDollar(in_currency_id, in_date);
	END;
END util_pkg;
/

CREATE OR REPLACE PACKAGE ct.company_pkg AS
	FUNCTION GetCompanyCurrency RETURN company.currency_id%TYPE;
END company_pkg;
/

CREATE OR REPLACE PACKAGE BODY ct.company_pkg AS
	FUNCTION GetCompanyCurrency RETURN company.currency_id%TYPE
	AS
		v_company_currency_id		company.currency_id%TYPE;
	BEGIN
		SELECT currency_id
		  INTO v_company_currency_id
		  FROM company
		 WHERE app_sid = security_pkg.getApp
		   AND company_sid = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY');
		   
		RETURN v_company_currency_id;
	END;
END company_pkg;
/

CREATE OR REPLACE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_id, worksheet_id, 
	eio_id, kg_co2,
	spend_in_company_currency,	company_currency_id
)
AS
SELECT
    app_sid, 
	company_sid, 
	supplier_id, 
	breakdown_id, 
	region_id, 
	item_id, 
	description,
	spend, 
	currency_id, 
	purchase_date, 
	created_by_sid, 
	created_dtm, 
	modified_by_sid,
	last_modified_dtm, 
	row_id, 
	worksheet_id,
	eio_id, 
	kg_co2,
	spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date) spend_in_company_currency,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ps_item;

@..\ct\excel_pkg
@..\ct\supplier_pkg
@..\ct\products_services_pkg
@..\ct\company_pkg
@..\ct\util_pkg

@..\chain\upload_body
@..\ct\excel_body
@..\ct\supplier_body
@..\ct\products_services_body
@..\ct\company_body
@..\ct\util_body
	
@update_tail