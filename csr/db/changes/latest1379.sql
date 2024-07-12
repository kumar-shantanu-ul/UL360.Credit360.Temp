-- Please update version.sql too -- this keeps clean builds in sync
define version=1379
@update_header

CREATE TABLE CT.PS_ITEM_EIO (
    APP_SID NUMBER(10) NOT NULL,
    COMPANY_SID NUMBER(10) NOT NULL,
    ITEM_ID NUMBER(10) NOT NULL,
    EIO_ID NUMBER(10) NOT NULL,
    PCT NUMBER(3) NOT NULL,
    CONSTRAINT PK_PS_ITEM_EIO PRIMARY KEY (APP_SID, COMPANY_SID, ITEM_ID, EIO_ID)
);

ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT CC_PS_ITEM_EIO_PCT 
    CHECK (PCT>=0 AND PCT<=100);
	
ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT PS_ITEM_PS_ITEM_EIO 
    FOREIGN KEY (APP_SID, COMPANY_SID, ITEM_ID) REFERENCES CT.PS_ITEM (APP_SID,COMPANY_SID,ITEM_ID);

ALTER TABLE CT.PS_ITEM_EIO ADD CONSTRAINT EIO_PS_ITEM_EIO 
    FOREIGN KEY (EIO_ID) REFERENCES CT.EIO (EIO_ID);
	
BEGIN
	security.user_pkg.LogonAdmin;

	-- Copy existing eio's from ps_item to ps_item_eio
	FOR r IN (
		SELECT app_sid, company_sid, item_id, eio_id
		  FROM ct.ps_item
		 WHERE eio_id IS NOT NULL
	) LOOP
		INSERT INTO ct.ps_item_eio (app_sid, company_sid, item_id, eio_id, pct)
		     VALUES (r.app_sid, r.company_sid, r.item_id, r.eio_id, 100);
	END LOOP;
END;
/

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CT',
		object_name     => 'PS_ITEM_EIO',
		policy_name     => 'PS_ITEM_EIO_POL',
		function_schema => 'CT',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static );
END;
/

CREATE OR REPLACE FORCE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, kg_co2,
	spend_in_company_currency, spend_in_dollars, company_currency_id
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
	row_number, 
	worksheet_id,
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two,
	kg_co2,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date),2) spend_in_company_currency,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date), 2) spend_in_dollars,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ct.ps_item;


@..\ct\products_services_pkg
@..\ct\value_chain_report_pkg

@..\ct\products_services_body
@..\ct\value_chain_report_body
@..\ct\reports_body
@..\ct\supplier_body
@..\ct\excel_body
@..\ct\breakdown_body

ALTER TABLE CT.PS_ITEM DROP CONSTRAINT EIO_PS_ITEM;	
ALTER TABLE CT.PS_ITEM DROP COLUMN EIO_ID;

@update_tail