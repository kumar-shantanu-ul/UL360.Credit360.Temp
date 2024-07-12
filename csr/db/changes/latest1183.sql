-- Please update version.sql too -- this keeps clean builds in sync
define version=1183
@update_header

-- CT devs: do this first...
-- DELETE FROM ct.ps_item;

ALTER TABLE ct.ps_item DROP CONSTRAINT pk_ps_item;

ALTER TABLE ct.ps_item RENAME COLUMN supplier_company_sid TO supplier_id;

ALTER TABLE ct.ps_item ADD CONSTRAINT pk_ps_item primary key (app_sid, company_sid, item_id);

ALTER TABLE ct.ps_item DROP CONSTRAINT company_ps_item_supp;

ALTER TABLE ct.ps_item ADD CONSTRAINT supplier_ps_item 
    FOREIGN KEY (app_sid, supplier_id) REFERENCES ct.supplier (app_sid, supplier_id);

@..\ct\products_services_pkg
@..\ct\products_services_body

@update_tail
