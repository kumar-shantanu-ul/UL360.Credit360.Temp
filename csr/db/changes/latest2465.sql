-- Please update version.sql too -- this keeps clean builds in sync
define version=2465
@update_header

--REFACTOR: add product validation status table
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'CHK_VALIDATION_STATUS'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

ALTER TABLE CHAIN.PRODUCT_REVISION RENAME COLUMN VALIDATION_STATUS TO XX_VALIDATION_STATUS;
ALTER TABLE CHAIN.PRODUCT_REVISION ADD VALIDATION_STATUS_ID NUMBER(10, 0) DEFAULT 1;

CREATE TABLE CHAIN.VALIDATION_STATUS(
	VALIDATION_STATUS_ID	NUMBER(10, 0)	NOT NULL,
	DESCRIPTION				VARCHAR(255)	NOT NULL,
	CONSTRAINT PK_VALIDATION_STATUS PRIMARY KEY (VALIDATION_STATUS_ID),
	CONSTRAINT UK_VALIDATION_STATUS UNIQUE (DESCRIPTION)
);

BEGIN
	INSERT INTO CHAIN.VALIDATION_STATUS VALUES(1, 'Initial');
	INSERT INTO CHAIN.VALIDATION_STATUS VALUES(2, 'Not yet validated');
	INSERT INTO CHAIN.VALIDATION_STATUS VALUES(3, 'Validation needs review');
	INSERT INTO CHAIN.VALIDATION_STATUS VALUES(4, 'Validation in progress');
	INSERT INTO CHAIN.VALIDATION_STATUS VALUES(5, 'Validated');
	
	UPDATE chain.product_revision pr
	   SET validation_status_id =(
		SELECT validation_status_id
		  FROM chain.validation_status pvs
		 WHERE pvs.description = pr.xx_validation_status
	 );
END;
/

ALTER TABLE CHAIN.PRODUCT_REVISION MODIFY VALIDATION_STATUS_ID NUMBER(10, 0) DEFAULT 1 NOT NULL;
ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_REVISION_VALIDATION
	FOREIGN KEY (VALIDATION_STATUS_ID)
	REFERENCES CHAIN.VALIDATION_STATUS(VALIDATION_STATUS_ID);
	
ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT CHK_VALIDATION_PUBLISHED
	CHECK((PUBLISHED = 0 AND VALIDATION_STATUS_ID = 1) OR PUBLISHED = 1);

ALTER TABLE CHAIN.PRODUCT_REVISION DROP COLUMN XX_VALIDATION_STATUS;
ALTER TABLE CSRIMP.CHAIN_PRODUCT_REVISION DROP COLUMN VALIDATION_STATUS;
ALTER TABLE CSRIMP.CHAIN_PRODUCT_REVISION ADD VALIDATION_STATUS_ID NUMBER(10, 0);

ALTER TABLE CHAIN.PRODUCT_REVISION RENAME COLUMN PSEUDO_ROOT_COMPONENT_ID TO SUPPLIER_ROOT_COMPONENT_ID;
ALTER TABLE CSRIMP.CHAIN_PRODUCT_REVISION RENAME COLUMN PSEUDO_ROOT_COMPONENT_ID TO SUPPLIER_ROOT_COMPONENT_ID;


--Views
CREATE OR REPLACE VIEW CHAIN.v$product_last_revision AS
SELECT x.app_sid, x.product_id, x.supplier_root_component_id, x.active, x.code2, x.code3, x.need_review, x.notes, x.published, 
	x.last_published_dtm, x.last_published_by_user_sid, x.validated_root_component_id, x.validation_status_id, x.validation_status_description, x.previous_end_dtm, x.previous_rev_number, x.revision_start_dtm, x.revision_end_dtm, x.revision_num
  FROM (
		SELECT app_sid, product_id, supplier_root_component_id, active, code2, code3, need_review, notes, published, last_published_dtm, 
		last_published_by_user_sid, validated_root_component_id, pr.validation_status_id, vs.description validation_status_description, previous_end_dtm, previous_rev_number, revision_start_dtm, 
		revision_end_dtm, revision_num, 
		ROW_NUMBER() OVER (PARTITION BY app_sid, product_id ORDER BY revision_num DESC) rn
		  FROM product_revision pr
		  JOIN validation_status vs ON pr.validation_status_id = vs.validation_status_id
	 )x
 WHERE x.rn = 1;
 
CREATE OR REPLACE VIEW CHAIN.v$product AS
 SELECT cmp.app_sid, p.product_id, p.supplier_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
   p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
   cmp.description, cmp.component_code, cmp.deleted,
   cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
   p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, p.validation_status_description,
   p.revision_num, p.revision_start_dtm
   FROM v$product_last_revision p
   JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status_id, 5 /* 'Validated' */, p.validated_root_component_id, p.supplier_root_component_id) = cmp.component_id
  WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;
 

CREATE OR REPLACE VIEW CHAIN.v$purchased_component AS
	SELECT cmp.app_sid, cmp.component_id, 
			cmp.description, cmp.component_code, cmp.component_notes, cmp.deleted,
			cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
			pc.component_supplier_type_id, pc.acceptance_status_id,
			pc.supplier_company_sid, supp.name supplier_name, supp.country_code supplier_country_code, supp_c.name supplier_country_name, 
			pc.company_sid purchaser_company_sid, pur.name purchaser_name, pur.country_code purchaser_country_code, pur_c.name purchaser_country_name, 
			pc.uninvited_supplier_sid, unv.name uninvited_name, unv.country_code uninvited_country_code, NULL uninvited_country_name, 
			pc.supplier_product_id, NVL2(pc.supplier_product_id, 1, 0) mapped, mapped_by_user_sid, mapped_dtm,
			p.description supplier_product_description, p.code1 supplier_product_code1, p.code2 supplier_product_code2, p.code3 supplier_product_code3, 
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, p.validation_status_id, p.validation_status_description,
			p.supplier_root_component_id
	  FROM purchased_component pc
	  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
	  LEFT JOIN (
		SELECT app_sid, component_id --, parent_component_id, level
		FROM chain.component
		START WITH component_id IN (
			SELECT supplier_root_component_id
			FROM CHAIN.v$product_last_revision
		)
		CONNECT BY PRIOR component_id = parent_component_id AND PRIOR app_sid = app_sid
	  ) ct on pc.app_sid = ct.app_sid and pc.component_id = ct.component_id
	  LEFT JOIN v$product p ON pc.app_sid = p.app_sid AND pc.supplier_product_id = p.product_id
	  LEFT JOIN company supp ON pc.app_sid = supp.app_sid AND pc.supplier_company_sid = supp.company_sid AND supp.deleted = 0
	  LEFT JOIN v$country supp_c ON supp.country_code = supp_c.country_code
	  LEFT JOIN company pur ON pc.app_sid = pur.app_sid AND pc.company_sid = pur.company_sid AND pur.deleted = 0
	  LEFT JOIN v$country pur_c ON pur.country_code = pur_c.country_code
	  LEFT JOIN uninvited_supplier unv ON pc.app_sid = unv.app_sid AND pc.uninvited_supplier_sid = unv.uninvited_supplier_sid AND pc.company_sid = unv.company_sid
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND (cmp.parent_component_id IS NULL OR ct.component_id IS NOT NULL)
;

CREATE OR REPLACE VIEW CHAIN.v$product_all_revisions AS
 SELECT cmp.app_sid, p.product_id, p.supplier_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
   p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
   cmp.description, cmp.component_code, cmp.deleted,
   cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
   p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status_id, vs.description validation_status_description,
   p.revision_num, p.revision_start_dtm, p.revision_end_dtm
   FROM product_revision p
   JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status_id, 5 /* 'VALIDATED' */, p.validated_root_component_id, p.supplier_root_component_id) = cmp.component_id
   JOIN validation_status vs ON p.validation_status_id = vs.validation_status_id
  WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
;

@../chain/chain_pkg 
@../chain/chain_link_pkg;
@../chain/product_pkg 
@../chain/company_user_pkg

@../schema_body 
@../csrimp/imp_body 
@../chain/chain_link_body;
@../chain/component_body 
@../chain/product_body 
@../chain/purchased_component_body 
@../chain/component_body 
@../chain/company_body 
@../chain/company_user_body 
@../chain/invitation_body 
@../chain/validated_purch_component_body 

@update_tail



