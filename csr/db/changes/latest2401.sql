-- Please update version.sql too -- this keeps clean builds in sync
define version=2401
@update_header

ALTER TABLE CHAIN.PRODUCT_METRIC RENAME TO XX_PRODUCT_METRIC;


/* Product revision */
ALTER TABLE CHAIN.PRODUCT RENAME TO PRODUCT_REVISION;

ALTER TABLE CHAIN.PRODUCT_REVISION ADD REVISION_NUM			NUMBER(10,0);
ALTER TABLE CHAIN.PRODUCT_REVISION ADD REVISION_START_DTM	DATE;
ALTER TABLE CHAIN.PRODUCT_REVISION ADD REVISION_END_DTM		DATE;
ALTER TABLE CHAIN.PRODUCT_REVISION ADD REVISION_CREATED_BY_SID	NUMBER(10, 0);
ALTER TABLE CHAIN.PRODUCT_REVISION ADD PREVIOUS_REV_NUMBER	NUMBER(10, 0);
ALTER TABLE CHAIN.PRODUCT_REVISION ADD PREVIOUS_END_DTM		DATE;

-- default values
BEGIN
	UPDATE chain.product_revision pr
	   SET revision_start_dtm = TO_DATE('01-JAN-2000', 'dd-MON-yyyy'),
		revision_num = 1,
		revision_created_by_sid = (
			SELECT c.created_by_sid
			  FROM chain.component c
			 WHERE c.app_sid = pr.app_sid
			   AND c.component_id = pseudo_root_component_id
		);
END;
/

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT CHK_END_DTM 
	CHECK (REVISION_END_DTM IS NULL OR (REVISION_END_DTM >= REVISION_START_DTM));

-- enforce sequential revisions to have continuous, not overlapping periods
ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT CHK_PREVIOUS_END_EQ_START 
	CHECK ((PREVIOUS_END_DTM IS NULL AND REVISION_NUM = 1) OR (PREVIOUS_END_DTM IS NOT NULL AND PREVIOUS_END_DTM = REVISION_START_DTM));

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT CHK_PREV_REV_NUM CHECK 
	((PREVIOUS_REV_NUMBER IS NULL AND REVISION_NUM = 1)  OR (PREVIOUS_REV_NUMBER IS NOT NULL AND REVISION_NUM = PREVIOUS_REV_NUMBER + 1));

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT UK_PRODUCT_REV_END_DTM 
	UNIQUE (APP_SID, PRODUCT_ID, REVISION_END_DTM, REVISION_NUM);

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_REV_PREV_END_DTM 
	FOREIGN KEY (APP_SID, PRODUCT_ID, PREVIOUS_END_DTM, PREVIOUS_REV_NUMBER)
	REFERENCES CHAIN.PRODUCT_REVISION (APP_SID, PRODUCT_ID, REVISION_END_DTM, REVISION_NUM);

ALTER TABLE CHAIN.PRODUCT_REVISION MODIFY REVISION_START_DTM DEFAULT SYSDATE NOT NULL;
ALTER TABLE CHAIN.PRODUCT_REVISION MODIFY REVISION_NUM NOT NULL;
ALTER TABLE CHAIN.PRODUCT_REVISION MODIFY REVISION_CREATED_BY_SID DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL;

--Drop dependencies to renamed product revision table
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'REFPRODUCT516', 
			'REFPRODUCT590'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

--drop rfa dependencies to renamed product PK so we can drop the PK later in this script
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='RFA' 
		   AND constraint_name IN (
			'REFPRODUCT_ISSUE_PRODUCT', 
			'REFPRODUCT219'
		)
	) 
	LOOP
		dbms_output.put_line('alter table RFA.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table RFA.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

ALTER TABLE CHAIN.PRODUCT_REVISION DROP CONSTRAINT PK_PRODUCT DROP INDEX;

begin
	for r in (select * from all_constraints where owner='CHAIN' and constraint_name in ('CONS_PSEUDO_ROOT_COMPONENT_ID', 'CONS_VAL_ROOT_COMPONENT_ID')) loop
		execute immediate 'ALTER TABLE CHAIN.PRODUCT_REVISION DROP CONSTRAINT '||r.constraint_name||' DROP INDEX';
	end loop;
end;
/

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT PK_PRODUCT_REVISION PRIMARY KEY (APP_SID, PRODUCT_ID, REVISION_NUM);
ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT UC_PRODUCT_REVISION_PSEUDO UNIQUE (APP_SID, PSEUDO_ROOT_COMPONENT_ID);
ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT UC_PRODUCT_REVISION_VALIDATED UNIQUE (VALIDATED_ROOT_COMPONENT_ID);

--Drop fk_product_component_pseudo fk_product_component_validated as we already have FKs RefCOMPONENT515, RefCOMPONENT516 
--from product to component table. Drop al 4 of them and rebuild them under a more descriptive name
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'FK_PRODUCT_COMPONENT_PSEUDO', 
			'FK_PRODUCT_COMPONENT_VALIDATED',
			'REFCOMPONENT515',
			'REFCOMPONENT516'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/
--drop redundant columns
ALTER TABLE CHAIN.PRODUCT_REVISION DROP COLUMN COMPANY_SID;
ALTER TABLE CHAIN.PRODUCT_REVISION DROP COLUMN COMPONENT_TYPE_ID;

/* FKs PRODUCT_REVISION */

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_PSEUD_ROOT_CMP_COMP
	FOREIGN KEY (APP_SID, PSEUDO_ROOT_COMPONENT_ID) 
	REFERENCES CHAIN.COMPONENT(APP_SID,COMPONENT_ID)
;

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_VALID_ROOT_CMP_COMP
	FOREIGN KEY (APP_SID, VALIDATED_ROOT_COMPONENT_ID)
	REFERENCES CHAIN.COMPONENT(APP_SID,COMPONENT_ID)
;

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_CREATED_BY_SID_USER
	FOREIGN KEY (APP_SID, REVISION_CREATED_BY_SID)
	REFERENCES CSR.CSR_USER (APP_SID, CSR_USER_SID);

/* PURCHASED_COMPONENT */
ALTER TABLE CHAIN.PURCHASED_COMPONENT ADD PREVIOUS_PURCH_COMPONENT_ID   NUMBER(10, 0);

ALTER TABLE CHAIN.PURCHASED_COMPONENT ADD CONSTRAINT FK_PURCH_CMP_PREV_PURCH_CMP
	FOREIGN KEY (APP_SID, PREVIOUS_PURCH_COMPONENT_ID) 
	REFERENCES CHAIN.PURCHASED_COMPONENT(APP_SID, COMPONENT_ID)
;


/* Product */
CREATE TABLE CHAIN.PRODUCT(
	APP_SID 				NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	PRODUCT_ID				NUMBER(10, 0)    NOT NULL,
	CONSTRAINT PK_PRODUCT	PRIMARY KEY (APP_SID, PRODUCT_ID)
)
;

BEGIN
	INSERT INTO CHAIN.PRODUCT (APP_SID, PRODUCT_ID)
	SELECT DISTINCT APP_SID, PRODUCT_ID
	  FROM CHAIN.PRODUCT_REVISION;
END;
/

/* Use sequence for product id */
DROP SEQUENCE CHAIN.PRODUCT_ID_SEQ;
CREATE SEQUENCE CHAIN.PRODUCT_ID_SEQ
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER
;

DECLARE v_max_product_id NUMBER;
BEGIN
	  
	SELECT NVL(MAX(product_id), 1)
	  INTO v_max_product_id
	  FROM chain.product;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE CHAIN.PRODUCT_ID_SEQ INCREMENT BY ' || v_max_product_id;
	
	SELECT chain.product_id_seq.NEXTVAL
	  INTO v_max_product_id
	  FROM dual;
	
	EXECUTE IMMEDIATE 'ALTER SEQUENCE CHAIN.PRODUCT_ID_SEQ INCREMENT BY 1';
END;
/

ALTER TABLE CHAIN.PRODUCT_REVISION ADD CONSTRAINT FK_PRODUCT_REVISION_PRODUCT
	FOREIGN KEY (APP_SID, PRODUCT_ID) 
	REFERENCES CHAIN.PRODUCT(APP_SID,PRODUCT_ID)
;


ALTER TABLE CHAIN.PURCHASED_COMPONENT ADD CONSTRAINT FK_PURCHASED_CMP_PRODUCT
	FOREIGN KEY (APP_SID, SUPPLIER_PRODUCT_ID) 
	REFERENCES CHAIN.PRODUCT(APP_SID,PRODUCT_ID)
;

--drop PURCHASER_COMPANY_SID (not used) from PURCHASED_COMPONENT
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'FK_PURCH_COMP_SUPP_REL_1'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint '||r.constraint_name);
	END LOOP;
END;
/

--constraint exists on live
BEGIN
	FOR R IN (
		SELECT table_name,constraint_name 
		  FROM all_constraints 
		 WHERE owner='CHAIN' 
		   AND constraint_name IN (
			'CHK_SUPPLIER_TYPE CHECK'
		)
	) 
	LOOP
		dbms_output.put_line('alter table chain.'||r.table_name||' drop constraint "'||r.constraint_name||'"');
		EXECUTE IMMEDIATE ('alter table chain.'||r.table_name||' drop constraint "'||r.constraint_name||'"');
	END LOOP;
END;
/

ALTER TABLE CHAIN.PURCHASED_COMPONENT DROP COLUMN PURCHASER_COMPANY_SID;

ALTER TABLE CHAIN.PURCHASED_COMPONENT ADD CONSTRAINT "CHK_SUPPLIER_TYPE" CHECK ((
	COMPONENT_SUPPLIER_TYPE_ID = 0
) OR (
		COMPONENT_SUPPLIER_TYPE_ID = 1 
 	AND SUPPLIER_COMPANY_SID IS NOT NULL
) OR (
		COMPONENT_SUPPLIER_TYPE_ID = 3
	AND UNINVITED_SUPPLIER_SID IS NOT NULL
));


/* rls */
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN 
	v_list := t_tabs(  
		'PRODUCT'
	);
	FOR I IN 1 .. v_list.count 
	LOOP
		BEGIN     
			DBMS_RLS.ADD_POLICY(
					object_schema   => 'CHAIN',
					object_name     => v_list(i),
					policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
					function_schema => 'CSR',
					policy_function => 'appSidCheck',
					statement_types => 'select, insert, update, delete',
					update_check  => true,
					policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));        
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

-- FK appears in create_schema but was never included in a latest script
DECLARE
  V_COUNT_CONS INTEGER;
BEGIN
  SELECT COUNT(*)
    INTO V_COUNT_CONS
    FROM USER_CONSTRAINTS
    WHERE CONSTRAINT_NAME = 'RefCOMPONENT1220'
	  AND OWNER = 'CHAIN'
	  AND TABLE_NAME = 'QUESTIONNAIRE';

  IF V_COUNT_CONS > 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE CHAIN.QUESTIONNAIRE ADD CONSTRAINT RefCOMPONENT1220 
						   FOREIGN KEY (APP_SID, COMPONENT_ID)
						REFERENCES CHAIN.COMPONENT(APP_SID, COMPONENT_ID)';
  END IF;
END;
/

ALTER TABLE chain.purchase RENAME COLUMN product_id TO component_id;

--indexes on FKs
create index chain.ix_questionnaire_component_id on chain.questionnaire (app_sid, component_id);

/* Views */
CREATE OR REPLACE VIEW CHAIN.v$product_last_revision AS
 SELECT x.app_sid, x.product_id, x.pseudo_root_component_id, x.active, x.code2, x.code3, x.need_review, x.notes, x.published, 
	x.last_published_dtm, x.last_published_by_user_sid, x.validated_root_component_id, x.validation_status, x.previous_end_dtm, x.previous_rev_number, x.revision_start_dtm, x.revision_end_dtm, x.revision_num
	FROM (
		SELECT app_sid, product_id, pseudo_root_component_id, active, code2, code3, need_review, notes, published, last_published_dtm, 
		last_published_by_user_sid, validated_root_component_id, validation_status, previous_end_dtm, previous_rev_number, revision_start_dtm, 
		revision_end_dtm, revision_num, 
		ROW_NUMBER() OVER (PARTITION BY app_sid, product_id ORDER BY revision_num DESC) rn
		  FROM product_revision
	 )x
	WHERE x.rn = 1;
	
CREATE OR REPLACE VIEW CHAIN.v$product AS
 SELECT cmp.app_sid, p.product_id, p.pseudo_root_component_id, p.validated_root_component_id, cmp.component_id root_component_id,
   p.active, cmp.component_code code1, p.code2, p.code3, p.notes, p.need_review,
   cmp.description, cmp.component_code, cmp.deleted,
   cmp.company_sid, cmp.created_by_sid, cmp.created_dtm,
   p.published, p.last_published_dtm, p.last_published_by_user_sid, p.validation_status,
   p.revision_num, p.revision_start_dtm
   FROM v$product_last_revision p
   JOIN component cmp ON p.app_sid = cmp.app_sid AND DECODE(p.validation_status, 'Validated', p.validated_root_component_id, p.pseudo_root_component_id) = cmp.component_id
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
			p.published supplier_product_published, p.last_published_dtm supplier_product_published_dtm, pc.purchases_locked, p.validation_status,
			p.pseudo_root_component_id
	  FROM purchased_component pc
	  JOIN component cmp ON pc.app_sid = cmp.app_sid AND pc.component_id = cmp.component_id
	  LEFT JOIN (
		SELECT app_sid, component_id --, parent_component_id, level
		FROM chain.component
		START WITH component_id IN (
			SELECT pseudo_root_component_id
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

CREATE OR REPLACE VIEW CHAIN.v$purchased_component_supplier AS
	--
	--SUPPLIER_NOT_SET (basic data, nulled supplier data)
	--
	SELECT app_sid, component_id, component_supplier_type_id, 
			NULL supplier_company_sid, NULL uninvited_supplier_sid, 
			NULL supplier_name, NULL supplier_country_code, NULL supplier_country_name
	  FROM purchased_component
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND component_supplier_type_id = 0 -- SUPPLIER_NOT_SET
	--
	 UNION
	--
	--EXISTING_SUPPLIER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 1 -- EXISTING_SUPPLIER
	   AND pc.supplier_company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--EXISTING_PURCHASER
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			pc.company_sid supplier_company_sid, NULL uninvited_supplier_sid, 
			c.name supplier_name, c.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, company c, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = c.app_sid
	   AND pc.component_supplier_type_id = 2 -- EXISTING_PURCHASER
	   AND pc.company_sid = c.company_sid
	   AND c.country_code = coun.country_code
	--
	 UNION
	--
	--UNINVITED_SUPPLIER (basic data, uninvited supplier data bound)
	--
	SELECT pc.app_sid, pc.component_id, pc.component_supplier_type_id, 
			NULL supplier_company_sid, us.uninvited_supplier_sid, 
			us.name supplier_name, us.country_code supplier_country_code, coun.name supplier_country_name
	  FROM purchased_component pc, uninvited_supplier us, v$country coun
	 WHERE pc.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND pc.app_sid = us.app_sid
	   AND pc.component_supplier_type_id = 3 -- UNINVITED_SUPPLIER
	   AND pc.uninvited_supplier_sid = us.uninvited_supplier_sid
	   AND us.country_code = coun.country_code
;

--Fixing an issue where the new validated purchased components were created with type id 3 instead of 5
BEGIN	   
	INSERT INTO CHAIN.component_type_containment (app_sid, container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT ctc.app_sid, ctc.container_component_type_id, 5, 0, 0
	  FROM CHAIN.component_type_containment ctc
	 WHERE ctc.child_component_type_id = 3
	   AND EXISTS (
		SELECT 5
		  FROM chain.component_type ct
		 WHERE ct.app_sid = ctc.app_sid
		   AND ct.component_type_id = 5
		);
	
	INSERT INTO chain.component_type_containment (app_sid, container_component_type_id, child_component_type_id, allow_add_existing, allow_add_new)
	SELECT app_sid, 5, child_component_type_id, allow_add_existing, allow_add_new
	  FROM chain.component_type_containment ctc
	 WHERE container_component_type_id = 3
	   AND EXISTS (
		SELECT 5
		  FROM chain.component_type ct
		 WHERE ct.app_sid = ctc.app_sid
		   AND ct.component_type_id = 5
		);

	UPDATE chain.component c
	   SET component_type_id = 5
	 WHERE component_type_id = 3
	   AND component_id = (
		SELECT component_id
		  FROM chain.validated_purchased_component v
		 WHERE v.app_sid = c.app_sid
		   AND v.component_id = c.component_id
	   );
END;
/


@../chain/invitation_pkg;
@../chain/product_pkg;
@../chain/purchased_component_pkg;
@../chain/chain_link_pkg;

@../chain/product_body;
@../chain/component_body;
@../chain/company_body;
@../chain/company_user_body;
@../chain/uninvited_body;
@../chain/invitation_body;
@../chain/validated_purch_component_body;
@../chain/purchased_component_body;
@../chain/chain_link_body;
@../quick_survey_body

@update_tail
