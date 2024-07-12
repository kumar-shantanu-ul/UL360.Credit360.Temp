-- Please update version.sql too -- this keeps clean builds in sync
define version=1492
@update_header

--functional unique index. Validates purchase_order when is not null, else purchase_id
CREATE UNIQUE INDEX CHAIN.IDX_PROD_PURCH_COMP_PO
   ON chain.purchase (APP_SID, PRODUCT_ID, PURCHASER_COMPANY_SID, NVL(PURCHASE_ORDER,  TO_CHAR(PURCHASE_ID) ) );

@update_tail