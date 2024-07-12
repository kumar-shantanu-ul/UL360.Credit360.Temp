CREATE OR REPLACE PACKAGE BODY CHAIN.validated_purch_component_pkg
IS

PROCEDURE SaveComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	in_description			IN  component.description%TYPE,
	in_component_code		IN  component.component_code%TYPE,
	in_component_notes		IN  component.component_notes%TYPE,
	in_rel_pc_id			IN  validated_purchased_component.mapped_purchased_component_id%TYPE,
	in_tag_sids				IN  security_pkg.T_SID_IDS,
	out_cur					OUT security_pkg.T_OUTPUT_CUR	
)
AS
	v_component_id			component.component_id%TYPE;
BEGIN
	v_component_id := component_pkg.SaveComponent(in_component_id, chain_pkg.VALIDATED_PURCHASED_COMPONENT, in_description, in_component_code, in_component_notes, in_tag_sids);
	
	BEGIN
		INSERT INTO validated_purchased_component(component_id, mapped_purchased_component_id)
		VALUES (v_component_id, in_rel_pc_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE validated_purchased_component
			   SET mapped_purchased_component_id = in_rel_pc_id
			 WHERE component_id = v_component_id
			   AND app_sid = security_pkg.GetApp;
	END;
	
	GetComponent(v_component_id, out_cur);

END;

PROCEDURE GetComponent ( 
	in_component_id			IN  component.component_id%TYPE,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR	
)
AS
	v_amount_unit_id	amount_unit.amount_unit_id%TYPE;
	v_amount_unit		amount_unit.description%TYPE;
	v_purch_mismatch_ids			T_NUMERIC_TABLE;
BEGIN
	IF NOT capability_pkg.CheckCapability(component_pkg.GetCompanySid(in_component_id), chain_pkg.COMPONENTS, security_pkg.PERMISSION_READ)  THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied on components for company with sid '||component_pkg.GetCompanySid(in_component_id));
	END IF;
	
	component_pkg.GetDefaultAmountUnit(v_amount_unit_id, v_amount_unit);
	v_purch_mismatch_ids := chain_link_pkg.FindProdWithUnitMismatch;

	OPEN out_cur FOR
		SELECT c.component_id, c.description, c.component_code, c.component_notes, pc.company_sid, 
				c.created_by_sid, c.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id, 
				-- supplier data
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid, 
				pcs.supplier_name, unv.name uninvited_name, pcs.supplier_country_code, pcs.supplier_country_name, 
				v_amount_unit_id amount_unit_id, v_amount_unit amount_unit,
				p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
				p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, NVL2(mm.item, 1, 0) purchase_unit_mismatch,
				vpc.mapped_purchased_component_id
		  FROM component c
		  JOIN validated_purchased_component vpc ON c.app_sid = vpc.app_sid AND c.component_id = vpc.component_id
		  JOIN purchased_component pc ON vpc.app_sid = pc.app_sid AND vpc.mapped_purchased_component_id = pc.component_id
		  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
		  JOIN v$purchased_component_supplier pcs ON pc.app_sid = pcs.app_sid AND pc.component_id = pcs.component_id
		  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
		  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
		  LEFT JOIN TABLE(v_purch_mismatch_ids) mm ON pc.component_id = mm.item
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND c.component_id = in_component_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		   AND cmp.deleted = chain_pkg.NOT_DELETED;
END;

PROCEDURE GetComponents (
	in_top_component_id		IN  component.component_id%TYPE,
	in_type_id				IN  chain_pkg.T_COMPONENT_TYPE,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_show_supplier_names		NUMBER := 0;
BEGIN
	component_pkg.RecordTreeSnapshot(in_top_component_id);
	
	IF ((component_pkg.CanSeeComponentAsChainTrnsprnt(in_top_component_id)) OR (component_pkg.GetCompanySid(in_top_component_id) = SYS_CONTEXT('SECURITY', 'CHAIN_COMPANY'))) THEN
		v_show_supplier_names := 1;
	END IF;	
	
	OPEN out_cur FOR
		SELECT  c.component_id, cmp.description, cmp.component_code, cmp.component_notes, pc.company_sid,
				cmp.created_by_sid, cmp.created_dtm, pc.component_supplier_type_id,
				pc.acceptance_status_id, pc.supplier_product_id,
				pcs.supplier_company_sid, pcs.uninvited_supplier_sid,
				DECODE(v_show_supplier_names, 1, pcs.supplier_name, 0, NULL) supplier_name,
				DECODE(v_show_supplier_names, 1, unv.name, 0, NULL) uninvited_name,
				pcs.supplier_country_code, pcs.supplier_country_name,
				NVL(ct.amount_child_per_parent,0) amount_child_per_parent,
				NVL(ct.amount_unit_id,1) amount_unit_id,
				au.description amount_unit,
				p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm,
				vpc.mapped_purchased_component_id, p.supplier_root_component_id
		  FROM component c
		  JOIN validated_purchased_component vpc ON c.app_sid = vpc.app_sid AND c.component_id = vpc.component_id
		  JOIN purchased_component pc ON vpc.app_sid = pc.app_sid AND vpc.mapped_purchased_component_id = pc.component_id
		  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
		  JOIN v$purchased_component_supplier pcs ON pc.app_sid = pcs.app_sid AND pc.component_id = pcs.component_id
		  JOIN TT_COMPONENT_TREE ct ON c.component_id = ct.child_component_id
		  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
		  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
		  LEFT JOIN chain.amount_unit au ON c.app_sid = au.app_sid AND NVL(ct.amount_unit_id,1) = au.amount_unit_id
		 WHERE c.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND in_type_id = chain_pkg.VALIDATED_PURCHASED_COMPONENT
		   AND ct.top_component_id = in_top_component_id
		   AND c.deleted = chain_pkg.NOT_DELETED
		   AND cmp.deleted = chain_pkg.NOT_DELETED
		 ORDER BY ct.position;
END;

PROCEDURE DeleteComponent (
	in_component_id			IN  component.component_id%TYPE
) 
AS
BEGIN
	component_pkg.DeleteComponent(in_component_id);
END;

END validated_purch_component_pkg;
/
