VARIABLE version NUMBER
BEGIN :version := 32; END; -- CHANGE THIS TO MATCH VERSION NUMBER
/

WHENEVER SQLERROR EXIT SQL.SQLCODE
DECLARE
	v_version	version.db_version%TYPE;
BEGIN
	SELECT db_version INTO v_version FROM supplier.version;
	IF v_version >= :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' HAS ALREADY BEEN APPLIED =======');
	END IF;
	IF v_version + 1 <> :version THEN
		RAISE_APPLICATION_ERROR(-20001, '========= UPDATE '||:version||' CANNOT BE APPLIED TO A DATABASE OF VERSION '||v_version||' =======');
	END IF;
END;
/

ALTER TABLE SUPPLIER.CUSTOMER_OPTIONS
 ADD (QUEST_PRODUCT_URL VARCHAR2(1024));
 
 ALTER TABLE SUPPLIER.CUSTOMER_OPTIONS
 ADD (QUEST_SUPPLIER_URL VARCHAR2(1024));
 
 ALTER TABLE SUPPLIER.CUSTOMER_OPTIONS
 ADD (USER_WORK_FILTER           NUMBER(1, 0)       DEFAULT 1 NOT NULL);
 
/
DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_csr_root_sid	security_pkg.T_SID_ID;
	v_tag_group_sid	security_pkg.T_SID_ID;
	v_tag_id		tag.tag_id%TYPE;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_csr_root_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/nn.credit360.com/csr');
	-- group
	tag_pkg.CreateTagGroup(v_act, v_csr_root_sid, 'supplier_category', 0, 1, 'X', 'X', v_tag_group_sid);
	-- categories
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'company_website', '&lt;h2&gt;Additional Supplier Details&lt;/h2&gt;Company Website', 0, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'primary_contact_name', 'Primary contact name', 1, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'primary_contact_tel', 'Primary contact telephone', 2, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'primary_contact_email', 'Primary contact email', 3, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'direct_supplier', 'Direct Supplier', 4, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'direct_supplier_bespoke', 'For direct suppliers, please check the box if any of the products from this supplier are wholly or substantially bespoke to Novonordisk (heavily customised or carry Novonordisk branding)', 5, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'indirect_supplier', 'Indirect supplier', 6, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'indirect_supplier_bespoke', 'For indirect suppliers, please check the box if any of the products from this supplier are bespoke to Novonordisk (wholly or substantially bespoke to Novonordisk, manufactured to our specifications, heavily customised, or carrying Novonordisk branding)', 7, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'engineering_supplier', 'Engineering supplier', 8, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'engineering_supplier_bespoke', 'For engineering suppliers, please check the box if any of the products from this supplier are made to Novonordisk specifications (such that customisation might account for over 50% of any product''s commercial value)', 9, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'expected_spend', '&lt;h2&gt;Commercial Details&lt;/h2&gt;Annual or expected annual spend with supplier (DKK)', 10, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'expected_revinue', 'Estimated supplier revenue in last 12 months (DKK)', 11, 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'one_off_supplier', 'Please check the box if this supplier is going to be used only once', 12, 1, v_tag_id);
END;
/

INSERT INTO supplier.questionnaire (questionnaire_id, active, class_name, friendly_name) VALUES (6, 1, 'nnsupplier', 'Supplier Risk Management');
INSERT INTO supplier.questionnaire (questionnaire_id, active, class_name, friendly_name) VALUES (7, 1, 'nnproduct', 'Product Risk Management');
/

DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_csr_root_sid	security_pkg.T_SID_ID;
	v_tag_group_sid	security_pkg.T_SID_ID;
	v_tag_id		tag.tag_id%TYPE;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
	v_csr_root_sid := securableobject_pkg.GetSidFromPath(v_act, 0, '//aspen/applications/nn.credit360.com/csr');
	-- Product categories
	tag_pkg.CreateTagGroup(v_act, v_csr_root_sid, 'product_category', 0, 1, 'X', 'X', v_tag_group_sid);
	-- done automatically
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'doQuestionnaire', 'Please check the box if a product questionnaire is required for this product.', 0, 1, v_tag_id);
	INSERT INTO questionnaire_tag (tag_id, questionnaire_id) values (v_tag_id, 6);
	
	-- Sale types
	tag_pkg.CreateTagGroup(v_act, v_csr_root_sid, 'sale_type', 0, 1, 'X', 'X', v_tag_group_sid);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'NNProduct', 'Normal Product', 0 , 1, v_tag_id);
	
	-- Merchant types
	tag_pkg.CreateTagGroup(v_act, v_csr_root_sid, 'merchant_type', 0, 1, 'X', 'X', v_tag_group_sid);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Type 1', 'Temp Type 1', 0 , 1, v_tag_id);
	tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Type 2', 'Temp Type 2', 1 , 1, v_tag_id);
END;
/

INSERT INTO customer_options (csr_root_sid) SELECT csr_root_sid FROM csr.customer WHERE host = 'bootssupplier.credit360.com';
INSERT INTO customer_options (csr_root_sid) SELECT csr_root_sid FROM csr.customer WHERE host = 'bootstest.credit360.com';
INSERT INTO customer_options (csr_root_sid) SELECT csr_root_sid FROM csr.customer WHERE host = 'bs.credit360.com';
INSERT INTO customer_options (csr_root_sid) SELECT csr_root_sid FROM csr.customer WHERE host = 'bsstage.credit360.com';

INSERT INTO customer_options
(csr_root_sid, 
edit_product_url, 
edit_supplier_url, 
supplier_cat_form_class, 
quest_product_url, 
quest_supplier_url, 
user_work_filter) 
SELECT csr_root_sid ,
'/novonordisk/site/supplier/admin/editProduct.acds',
'/novonordisk/site/supplier/admin/editSupplier.acds',
'NovoNordisckSupplierCategoryForm',                                                
'/csr/site/supplier/questionnaire/questionnaire.acds?class=nnproduct',             
'/csr/site/supplier/questionnaire/questionnaire.acds?class=nnsupplier',
0
FROM csr.customer WHERE host = 'nn.credit360.com';

-- Update version
UPDATE supplier.version SET db_version = :version;
COMMIT;

PROMPT
PROMPT ================== UPDATED OK ========================
EXIT
