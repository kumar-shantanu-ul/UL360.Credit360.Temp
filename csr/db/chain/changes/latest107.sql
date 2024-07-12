define version=107
@update_header

ALTER TABLE chain.product ADD Notes VARCHAR2(255);

ALTER TABLE chain.component ADD component_notes varchar2(255);

PROMPT >> Creating v$component
CREATE OR REPLACE VIEW chain.v$component AS
	SELECT cmp.app_sid, cmp.component_id, ctb.component_type_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			ctb.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM component cmp, component_bind ctb
	 WHERE cmp.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND cmp.app_sid = ctb.app_sid
	   AND cmp.component_id = ctb.component_id
;

PROMPT >> Creating v$product
CREATE OR REPLACE VIEW chain.v$product AS
	SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, 
			p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
			cmp.description, cmp.component_code, cmp.deleted,
			p.company_sid, cmp.created_by_sid, cmp.created_dtm
	  FROM product p, component cmp
	 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND p.app_sid = cmp.app_sid
	   AND p.product_id = cmp.component_id
;

PROMPT >> Creating v$purchased_component
CREATE OR REPLACE VIEW chain.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			pc.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp.country_name supplier_country_name, 
			pc.purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur.country_name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id
	  FROM purchased_component pc, component cmp, v$company supp, v$company pur, uninvited_supplier unv
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = cmp.app_sid
	   AND pc.component_id = cmp.component_id
	   AND pc.supplier_company_sid = supp.company_sid(+)
	   AND pc.purchaser_company_sid = pur.company_sid(+)
	   AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid(+)
;


@..\component_pkg
@..\product_pkg
@..\purchased_component_pkg

@..\component_body
@..\product_body
@..\purchased_component_body

@update_tail