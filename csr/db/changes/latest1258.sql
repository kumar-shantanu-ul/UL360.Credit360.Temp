-- Please update version.sql too -- this keeps clean builds in sync
define version=1258
@update_header

-- column order was wrong
CREATE OR REPLACE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	eio_id, auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, kg_co2,
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
	eio_id, auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two,
	kg_co2,
	spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date) spend_in_company_currency,
	spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) spend_in_dollars,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ct.ps_item;

@..\ct\ct_pkg
@..\ct\products_services_pkg
@..\ct\products_services_body

 
@update_tail