-- Please update version.sql too -- this keeps clean builds in sync
define version=106
@update_header 

set define off
Update supplier.gt_fd_ingred_prov_type set Description = 'Pole & Line' where description = 'Fishing - Pole and Line';
Update supplier.gt_fd_ingred_prov_type set Description = 'Nets' where description = 'Fishing - Nets (eg Purse Seining)';
Update supplier.gt_fd_ingred_prov_type set Description = 'Long Line' where description = 'Fishing - Long Line';

CREATE TABLE SUPPLIER.GT_PRODUCT_USER (
  app_sid       NUMBER(10,0) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
  product_id     NUMBER(10,0) NOT NULL,
  user_sid       NUMBER(10,0) NOT NULL,
  company_sid	 NUMBER(10,0),
  started		 NUMBER(1, 0) DEFAULT 1 NOT NULL,
  CONSTRAINT PK_GT_PRODUCT_USER PRIMARY KEY(product_id, user_sid)
);

CREATE INDEX SUPPLIER.IX_product_id ON SUPPLIER.GT_PRODUCT_USER(product_id)
;

CREATE INDEX SUPPLIER.IX_user_sid ON SUPPLIER.GT_PRODUCT_USER(user_sid)
;

ALTER TABLE SUPPLIER.GT_PRODUCT_USER ADD CONSTRAINT FK_GT_PROD_USER_ALL_PROD
    FOREIGN KEY (product_id)
    REFERENCES SUPPLIER.ALL_PRODUCT(product_id)
;

ALTER TABLE SUPPLIER.GT_PRODUCT_USER ADD CONSTRAINT FK_GT_PROD_USER_CSR_USER
	FOREIGN KEY (user_sid, app_sid)
    REFERENCES CSR.CSR_USER(csr_user_sid, app_sid)
;

ALTER TABLE SUPPLIER.GT_PRODUCT_USER ADD CONSTRAINT FK_GT_PROD_USER_ALL_COMP
	FOREIGN KEY (company_sid)
    REFERENCES SUPPLIER.ALL_COMPANY(company_sid)
; 

@../../product_pkg
@../../product_body

@update_tail