-- Please update version.sql too -- this keeps clean builds in sync
define version=4
@update_header


--DROP TABLE GT_PRODUCT_CLASS CASCADE CONSTRAINTS;
--DROP TABLE GT_TAG_PRODUCT_CLASS CASCADE CONSTRAINTS;
--DROP TABLE GT_USER_REPORT_PRODUCT_TYPES CASCADE CONSTRAINTS;
--DROP TABLE GT_USER_REPORT_PRODUCT_RANGES CASCADE CONSTRAINTS;

-- 
-- TABLE: GT_PRODUCT_CLASS 
--

CREATE TABLE GT_PRODUCT_CLASS(
    GT_PRODUCT_CLASS_ID      NUMBER(10, 0)    NOT NULL,
    GT_PRODUCT_CLASS_NAME    VARCHAR2(50),
    GT_PRODUCT_CLASS_DESC    VARCHAR2(256),
	UNITS                    VARCHAR2(20)     NOT NULL,
	UNITS_DESC               VARCHAR2(50)     NOT NULL,
    CONSTRAINT PK_GT_PRODUCT_CLASS PRIMARY KEY (GT_PRODUCT_CLASS_ID)
)
;


-- 
-- TABLE: GT_TAG_PRODUCT_CLASS 
--

CREATE TABLE GT_TAG_PRODUCT_CLASS(
    TAG_ID                 NUMBER(10, 0)    NOT NULL,
    GT_PRODUCT_CLASS_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GT_TAG_PRODUCT_CLASS PRIMARY KEY (TAG_ID, GT_PRODUCT_CLASS_ID)
)
;

-- 
-- TABLE: GT_TAG_PRODUCT_CLASS 
--

ALTER TABLE GT_TAG_PRODUCT_CLASS ADD CONSTRAINT RefGT_PRODUCT_CLASS753 
    FOREIGN KEY (GT_PRODUCT_CLASS_ID)
    REFERENCES GT_PRODUCT_CLASS(GT_PRODUCT_CLASS_ID)
;

ALTER TABLE GT_TAG_PRODUCT_CLASS ADD CONSTRAINT RefTAG754 
    FOREIGN KEY (TAG_ID)
    REFERENCES TAG(TAG_ID)
;


-- 
-- TABLE: GT_USER_REPORT_PRODUCT_TYPES 
--

CREATE TABLE GT_USER_REPORT_PRODUCT_TYPES(
    GT_PRODUCT_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID          NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GT_USER_REPORT_PT PRIMARY KEY (GT_PRODUCT_TYPE_ID, CSR_USER_SID)
)
;


-- 
-- TABLE: GT_USER_REPORT_PRODUCT_TYPES 
--

ALTER TABLE GT_USER_REPORT_PRODUCT_TYPES ADD CONSTRAINT RefUSER_REPORT_SETTINGS744 
    FOREIGN KEY (CSR_USER_SID)
    REFERENCES USER_REPORT_SETTINGS(CSR_USER_SID)
;

ALTER TABLE GT_USER_REPORT_PRODUCT_TYPES ADD CONSTRAINT RefGT_PRODUCT_TYPE745 
    FOREIGN KEY (GT_PRODUCT_TYPE_ID)
    REFERENCES GT_PRODUCT_TYPE(GT_PRODUCT_TYPE_ID)
;



-- 
-- TABLE: GT_USER_REPORT_PRODUCT_RANGES 
--

CREATE TABLE GT_USER_REPORT_PRODUCT_RANGES(
    GT_PRODUCT_RANGE_ID    NUMBER(10, 0)    NOT NULL,
    CSR_USER_SID           NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_GT_USER_REPORT_PR PRIMARY KEY (GT_PRODUCT_RANGE_ID, CSR_USER_SID)
)
;

-- 
-- TABLE: GT_USER_REPORT_PRODUCT_RANGES 
--

ALTER TABLE GT_USER_REPORT_PRODUCT_RANGES ADD CONSTRAINT RefUSER_REPORT_SETTINGS749 
    FOREIGN KEY (CSR_USER_SID)
    REFERENCES USER_REPORT_SETTINGS(CSR_USER_SID)
;

ALTER TABLE GT_USER_REPORT_PRODUCT_RANGES ADD CONSTRAINT RefGT_PRODUCT_RANGE750 
    FOREIGN KEY (GT_PRODUCT_RANGE_ID)
    REFERENCES GT_PRODUCT_RANGE(GT_PRODUCT_RANGE_ID)
;



BEGIN
	-- set up attributes (tag attributes determine the behaviour of the UI)
	INSERT INTO TAG_ATTRIBUTE VALUES(0, 'No Questionnaires', 'A tag that the associated product forbids to fill questionnaires. e.g. "sub-products"'); 
	INSERT INTO TAG_ATTRIBUTE VALUES(1, 'No Volumes', 'A tag that the associated product forbids to fill volumes. e.g. "sub-products"'); 
	 
	-- tag group label for GT		 
	INSERT INTO TAG_ATTRIBUTE VALUES(2, 'lbl_Green Tick Assessment', 'A tag that is associated with green tick assessment. e.g. "needsGreenTick"'); 
	INSERT INTO TAG_ATTRIBUTE VALUES(4, 'no_prodcate_ParentPackaging', 'A tag that is not associated with "gift packaging" product category.'); 
	INSERT INTO TAG_ATTRIBUTE VALUES(5, 'prodcate_withoutPackaging', 'A tag that is associated with "without packaging" product category.');
	INSERT INTO TAG_ATTRIBUTE VALUES(6, 'group_or_Product Class', 'A tag that is associated with this attribute is part of a group with OR relationship.');
	INSERT INTO TAG_ATTRIBUTE VALUES(7, 'child_needsGreenTick', 'A tag that is associated with this attribute is a child of needsGreenTick tag');
	
	-- product class modification
	-- add three product classes
	INSERT INTO GT_PRODUCT_CLASS VALUES (1,'Formulated', 'A formulated product','ml','Volume');
	INSERT INTO GT_PRODUCT_CLASS VALUES (2,'Manufactured', 'A manufactured product','g','Weight');
	INSERT INTO GT_PRODUCT_CLASS VALUES (3,'Gift Packaging', 'A gift packaging','g','Weight');	
	-- add prefix of 'SUB' to sub-products
	INSERT INTO product_code_stem VALUES (3,'SUB');

END;
/

-- add foreign column to GT_PRODUCT_TYPE (as nullable, because we're assuming the table contains data)
ALTER TABLE GT_PRODUCT_TYPE ADD (GT_PRODUCT_CLASS_ID NUMBER(10,0) NULL);

-- add foreign key constrain
ALTER TABLE GT_PRODUCT_TYPE ADD CONSTRAINT RefGT_PRODUCT_CLASS729 
	FOREIGN KEY (GT_PRODUCT_CLASS_ID)
	REFERENCES GT_PRODUCT_CLASS(GT_PRODUCT_CLASS_ID)
;

BEGIN
	-- set previous rows to "formulated"
	UPDATE gt_product_type SET GT_PRODUCT_CLASS_ID = 1; -- formulated
END;
/

-- change foreign column for not accepting nulls  
ALTER TABLE GT_PRODUCT_TYPE MODIFY (GT_PRODUCT_CLASS_ID NUMBER(10,0) NOT NULL);


DECLARE
	v_act					security_pkg.T_ACT_ID;
	v_app_sid				security_pkg.T_SID_ID;
	v_tag_group_sid			security_pkg.T_SID_ID;
	v_tag_id				security_pkg.T_SID_ID;
	v_tag_id_formulated		security_pkg.T_SID_ID;
	v_tag_id_manufactured	security_pkg.T_SID_ID;
	v_tag_id_gift			security_pkg.T_SID_ID;
	v_tag_id_subprod		security_pkg.T_SID_ID;
	v_tag_id_nopack			security_pkg.T_SID_ID;
BEGIN
	
	FOR r IN (SELECT app_sid, host FROM csr.customer WHERE host IN 
		(
			'bs.credit360.com',
			'bootstest.credit360.com',
			'bootssupplier.credit360.com',
			'bsstage.credit360.com'
		)
	)
	LOOP
		user_pkg.logonadmin(r.host);
		SELECT sys_context('SECURITY','APP') INTO v_app_sid FROM dual;  
		SELECT sys_context('SECURITY','ACT') INTO v_act FROM dual;

		-- get tag group sid out of group name
		SELECT tag_group_sid INTO v_tag_group_sid 
		  FROM tag_group 
		 WHERE name = 'sale_type'
		 AND app_sid = v_app_sid;
	
		-- insert a new sales type tag ("tag_pkg.AddNewTagToGroup" - inserts rows into tag, tag_group_member tables) 
		tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Sub Product', 'Sub Product', 4, 1, v_tag_id_subprod);
		
		-- associate sub-product with attributes: 'No Questionnaires', 'No Volumes', 'no_prodcate_isaWrapperPackaging', 'prodcate_withoutPackaging'
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_subprod,0);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_subprod,1);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_subprod,4);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_subprod,5);
  	  
		-- get tag group sid out of group name
		SELECT tag_group_sid INTO v_tag_group_sid 
		  FROM tag_group 
		 WHERE name = 'product_category'
		   AND app_sid = v_app_sid;
  
		tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'ParentPackaging', 'Parent Packaging', 11, 1, v_tag_id_gift);
		tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'withoutPackaging', 'Product does not include packaging', 12, 0, v_tag_id_nopack);
		tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Manufactured', 'Manufactured', 13, 1, v_tag_id_manufactured);
		tag_pkg.AddNewTagToGroup(v_act, v_tag_group_sid, 'Formulated', 'Formulated', 14, 1, v_tag_id_formulated);
    
		--maps tags to product class
		INSERT INTO GT_TAG_PRODUCT_CLASS VALUES(v_tag_id_formulated,1);
		INSERT INTO GT_TAG_PRODUCT_CLASS VALUES(v_tag_id_manufactured,2);
		INSERT INTO GT_TAG_PRODUCT_CLASS VALUES(v_tag_id_gift,3);
		
		
		--Update current products to "Formulated" class
		INSERT INTO product_tag
			 SELECT product_id, v_tag_id_formulated, null, null 
			   FROM all_product 
			  WHERE app_sid = v_app_sid;
 
		
		--label the tags as green tick assessment
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_gift,2);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_nopack,2);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_manufactured,2);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_formulated,2);
		
		SELECT t.tag_id INTO v_tag_id 
		  FROM tag t, tag_group_member tgm, tag_group tg 
		 WHERE tag = 'needsGreenTick' 
		   AND t.tag_id = tgm.tag_id
		   AND tgm.tag_group_sid = tg.tag_group_sid
		   AND app_sid = sys_context('SECURITY','APP') ;
		
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id,2);
		
		-- group tags values ("OR" relationship) under "Product Class"
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_formulated,6);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_manufactured,6);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_gift,6);

		-- set needsGreenTick childs
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_formulated,7);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_manufactured,7);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_gift,7);
		INSERT INTO TAG_TAG_ATTRIBUTE VALUES(v_tag_id_nopack,7);
	
		-- A 'no packaging' product doesn't include packaging questionnaire 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_nopack, 9, 0);
		
		-- A gift product doesn't include formulation or design questionnaires 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_gift, 10, 0);
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_gift, 13, 0);
		
		-- A formulated product doesn't include product design questionnaire 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_formulated, 10, 1);
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_formulated, 13, 0);
		
		-- A manufactured product doesn't include formulation questionnaire 
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_manufactured, 10, 0);
		INSERT INTO questionnaire_tag (tag_id, questionnaire_id, mapped) values (v_tag_id_manufactured, 13, 1);
	
		INSERT INTO product_code_stem_tag VALUES (3,v_tag_id_subprod);
		
		COMMIT;
	END LOOP;
END;
/	


@update_tail