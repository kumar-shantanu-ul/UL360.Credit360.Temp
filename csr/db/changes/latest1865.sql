-- Please update version.sql too -- this keeps clean builds in sync
define version=1865
@update_header


CREATE OR REPLACE FORCE VIEW "CHAIN"."V$PURCHASED_COMPONENT" ("APP_SID", "COMPONENT_ID", "DESCRIPTION", "COMPONENT_CODE", "COMPONENT_NOTES", "DELETED", "COMPANY_SID", "CREATED_BY_SID", "CREATED_DTM", "COMPONENT_SUPPLIER_TYPE_ID", "ACCEPTANCE_STATUS_ID", "SUPPLIER_COMPANY_SID", "SUPPLIER_NAME", "SUPPLIER_COUNTRY_CODE", "SUPPLIER_COUNTRY_NAME", "PURCHASER_COMPANY_SID", "PURCHASER_NAME", "PURCHASER_COUNTRY_CODE", "PURCHASER_COUNTRY_NAME", "UNINVITED_SUPPLIER_SID", "UNINVITED_NAME", "UNINVITED_COUNTRY_CODE", "UNINVITED_COUNTRY_NAME", "SUPPLIER_PRODUCT_ID", "MAPPED", "MAPPED_BY_USER_SID", "MAPPED_DTM", "SUPPLIER_PRODUCT_DESCRIPTION", "SUPPLIER_PRODUCT_CODE1", "SUPPLIER_PRODUCT_CODE2", "SUPPLIER_PRODUCT_CODE3", "SUPPLIER_PRODUCT_PUBLISHED", "SUPPLIER_PRODUCT_PUBLISHED_DTM", "PURCHASES_LOCKED")
AS
  SELECT cmp.app_sid,
    cmp.component_id,
    cmp.description,
    cmp.component_code,
    cmp.component_notes,
    cmp.deleted,
    pc.company_sid,
    cmp.created_by_sid,
    cmp.created_dtm,
    pc.component_supplier_type_id,
    pc.acceptance_status_id,
    pc.supplier_company_sid,
    supp.name supplier_name,
    supp.country_code supplier_country_code,
    supp.country_name supplier_country_name,
    pc.purchaser_company_sid,
    pur.name purchaser_name,
    pur.country_code purchaser_country_code,
    pur.country_name purchaser_country_name,
    pc.uninvited_supplier_sid,
    unv.name uninvited_name,
    unv.country_code uninvited_country_code,
    NULL uninvited_country_name,
    pc.supplier_product_id,
    NVL2(pc.supplier_product_id, 1, 0) mapped,
    mapped_by_user_sid,
    mapped_dtm,
    p.description supplier_product_description,
    p.code1 supplier_product_code1,
    p.code2 supplier_product_code2,
    p.code3 supplier_product_code3,
    p.published supplier_product_published,
    p.last_published_dtm supplier_product_published_dtm,
    pc.purchases_locked
  FROM purchased_component pc,
    component cmp,
    v$company supp,
    v$company pur,
    uninvited_supplier unv,
    v$product p
  WHERE pc.app_sid              = SYS_CONTEXT('SECURITY', 'APP')
  AND pc.app_sid                = cmp.app_sid
  AND pc.component_id           = cmp.component_id
  AND pc.supplier_product_id    = p.product_id (+)
  AND pc.app_sid                = p.app_sid (+)
  AND pc.supplier_company_sid   = supp.company_sid(+)
  AND pc.purchaser_company_sid  = pur.company_sid(+)
  AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid(+) 
  AND pc.company_sid            = unv.company_sid(+) ;

@../chain/product_pkg
@../chain/product_body

@update_tail