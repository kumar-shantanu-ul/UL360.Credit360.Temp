-- Please update version.sql too -- this keeps clean builds in sync
define version=2305
@update_header

ALTER TABLE chain.customer_options ADD SUPPLIER_FILTER_EXPORT_URL			VARCHAR2(2000)	NULL;



@../chain/helper_body


@update_tail