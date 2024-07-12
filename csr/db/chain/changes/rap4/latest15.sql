define rap4_version=15
@update_header

ALTER TABLE PRODUCT ADD (
	PRODUCT_BUILDER_COMPONENT_ID    NUMBER(10, 0)
);

UPDATE PRODUCT SET PRODUCT_BUILDER_COMPONENT_ID = ROOT_COMPONENT_ID;

ALTER TABLE PRODUCT MODIFY PRODUCT_BUILDER_COMPONENT_ID NOT NULL;

ALTER TABLE PRODUCT ADD CONSTRAINT RefCOMPONENT539 
    FOREIGN KEY (APP_SID, PRODUCT_BUILDER_COMPONENT_ID)
    REFERENCES COMPONENT(APP_SID, COMPONENT_ID)
;

CREATE OR REPLACE VIEW v$company_product AS
	SELECT product_id, p.app_sid, p.company_sid, c.name company_name, p.created_by_sid, cu.full_name created_by, p.created_dtm, p.description, p.active, 
			code_label1, code1, code_label2, code2, code_label3, code3, need_review, p.deleted, 
			p.root_component_id, p.product_builder_component_id
		  FROM product p, product_code_type pct, v$company c, csr.csr_user cu
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND p.company_sid = pct.company_sid
		   AND p.app_sid = pct.app_sid
		   AND p.company_sid = c.company_sid
		   AND p.app_sid = c.app_sid
		   AND p.created_by_sid = cu.csr_user_sid
		   AND p.app_sid = cu.app_sid
;

CREATE OR REPLACE VIEW v$product AS
	SELECT product_id, app_sid, company_sid, company_name, created_by_sid, created_by, created_dtm, description, active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, root_component_id, product_builder_component_id
	  FROM v$company_product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

@..\..\product_pkg
@..\..\product_body

@update_tail

