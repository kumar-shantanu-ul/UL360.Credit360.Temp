-- Please update version.sql too -- this keeps clean builds in sync
define version=688
@update_header

-- can't add FK constraint according to ER/Studio due to some circularity somewhere.
-- I notice that CUSTOMER.REGION_ROOT_SID has no FK constraint either -- presumably
-- for the same reason.
ALTER TABLE csr.CUSTOMER ADD (
    SUPPLIER_REGION_ROOT_SID         NUMBER(10, 0)
);

@..\supplier_body

@update_tail
