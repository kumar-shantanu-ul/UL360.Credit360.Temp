define version=34
@update_header

CREATE OR REPLACE VIEW v$all_product AS
SELECT product_id, p.app_sid, p.company_sid, c.name company_name, p.created_by_sid, cu.full_name created_by, p.created_dtm, p.description, p.active, 
        code_label1, code1, code_label2, code2, code_label3, code3, need_review, p.deleted
      FROM all_product p, product_code_type pct, v$company c, csr.csr_user cu
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
        code_label1, code1, code_label2, code2, code_label3, code3, need_review
	  FROM v$all_product
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND deleted = 0
;

@..\product_pkg
@..\product_body

@update_tail
