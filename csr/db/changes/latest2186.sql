-- Please update version.sql too -- this keeps clean builds in sync
define version=2186
@update_header

CREATE OR REPLACE VIEW CHAIN.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp_c.name supplier_country_name, 
			pc.purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur_c.name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id, NVL2(pc.supplier_product_id, 1, 0) mapped, mapped_by_user_sid, mapped_dtm,
			p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, p.validation_status
	  FROM purchased_component pc
	  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
	  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
	  LEFT JOIN company supp ON pc.app_sid = supp.app_sid AND pc.supplier_company_sid = supp.company_sid AND supp.deleted = 0
	  LEFT JOIN v$country supp_c ON supp.country_code = supp_c.country_code
	  LEFT JOIN company pur ON pc.app_sid = pur.app_sid AND pc.purchaser_company_sid = pur.company_sid AND pur.deleted = 0
	  LEFT JOIN v$country pur_c ON pur.country_code = pur_c.country_code
	  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

@update_tail
