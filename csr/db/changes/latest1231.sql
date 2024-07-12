-- Please update version.sql too -- this keeps clean builds in sync
define version=1231
@update_header

ALTER TABLE CT.PS_ITEM
ADD (AUTO_EIO_ID NUMBER(10));

ALTER TABLE CT.PS_ITEM
ADD (AUTO_EIO_ID_SCORE NUMBER(20, 10));

ALTER TABLE CT.PS_ITEM
ADD (AUTO_EIO_ID_TWO NUMBER(10));

ALTER TABLE CT.PS_ITEM
ADD (AUTO_EIO_ID_SCORE_TWO NUMBER(20, 10));

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_AUTO_EIO_ID_SCORE 
    CHECK (AUTO_EIO_ID_SCORE >= 0);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT CC_PS_ITEM_AUTO_EIO_ID_SCORE_2 
    CHECK (AUTO_EIO_ID_SCORE_TWO >= 0);
	
ALTER TABLE CT.PS_ITEM ADD CONSTRAINT EIO_PS_ITEM_AUTO 
    FOREIGN KEY (AUTO_EIO_ID) REFERENCES CT.EIO (EIO_ID);

ALTER TABLE CT.PS_ITEM ADD CONSTRAINT EIO_PS_ITEM_AUTO2 
    FOREIGN KEY (AUTO_EIO_ID_TWO) REFERENCES CT.EIO (EIO_ID);	

CREATE OR REPLACE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	eio_id, auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, kg_co2,
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
	row_number, 
	worksheet_id,
	eio_id, auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two,
	kg_co2,
	spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date) spend_in_company_currency,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ps_item;
 
 @../ct/products_services_pkg
@../ct/products_services_body
@../ct/emp_commute_body
@../ct/business_travel_body


@update_tail
