-- Please update version.sql too -- this keeps clean builds in sync
define version=63
@update_header

ALTER TABLE SUPPLIER.CUSTOMER_OPTIONS
ADD (SEARCH_PRODUCT_URL VARCHAR2(1024 BYTE));

update SUPPLIER.CUSTOMER_OPTIONS set SEARCH_PRODUCT_URL = '/bootssupplier/site/admin/searchProduct.acds'
where app_sid = (select app_sid from csr.customer where host = 'bootssupplier.credit360.com');

update SUPPLIER.CUSTOMER_OPTIONS set SEARCH_PRODUCT_URL = '/bootssupplier/site/admin/searchProduct.acds'
where app_sid = (select app_sid from csr.customer where host = 'bootstest.credit360.com');

update SUPPLIER.CUSTOMER_OPTIONS set SEARCH_PRODUCT_URL = '/bootssupplier/site/admin/searchProduct.acds'
where app_sid = (select app_sid from csr.customer where host = 'bs.credit360.com');

update SUPPLIER.CUSTOMER_OPTIONS set SEARCH_PRODUCT_URL = '/bootssupplier/site/admin/searchProduct.acds'
where app_sid = (select app_sid from csr.customer where host = 'bsstage.credit360.com');

@update_tail
