-- Please update version.sql too -- this keeps clean builds in sync
define version=87
@update_header
	
-- TABLE: GT_TRANS_ITEM 
--

	CREATE TABLE GT_TRANS_ITEM(
		GT_TRANS_ITEM_ID             NUMBER(10, 0)    NOT NULL,
		weight_grams        NUMBER(10, 2)    DEFAULT 0 NOT NULL,
		PCT_RECYCLED                 NUMBER(6, 3)     DEFAULT 0 NOT NULL,
		PRODUCT_ID                   NUMBER(10, 0)    NOT NULL,
		REVISION_ID                  NUMBER(10, 0)    NOT NULL,
		GT_TRANS_MATERIAL_TYPE_ID    NUMBER(10, 0)    NOT NULL,
		CONSTRAINT CHK_weight_grams_1 CHECK (weight_grams > 0),
		CONSTRAINT PK194_1 PRIMARY KEY (GT_TRANS_ITEM_ID, PRODUCT_ID, REVISION_ID)
	)
	;



	-- 
	-- TABLE: GT_TRANS_MATERIAL_TYPE 
	--

	CREATE TABLE GT_TRANS_MATERIAL_TYPE(
		GT_TRANS_MATERIAL_TYPE_ID    NUMBER(10, 0)     NOT NULL,
		DESCRIPTION                  VARCHAR2(1024)    NOT NULL,
		RECYCLED_PCT_THESHOLD        NUMBER(6, 3)      NOT NULL,
		ENV_IMPACT_SCORE             NUMBER(10, 2)     NOT NULL,
		POS                          NUMBER(10, 0)     NOT NULL,
		CONSTRAINT PK195_1_1 PRIMARY KEY (GT_TRANS_MATERIAL_TYPE_ID)
	)
	;

	-- TABLE: GT_TRANS_ITEM 
--

	ALTER TABLE GT_TRANS_ITEM ADD CONSTRAINT RefGT_TRANS_MATERIAL_TYPE961 
		FOREIGN KEY (GT_TRANS_MATERIAL_TYPE_ID)
		REFERENCES GT_TRANS_MATERIAL_TYPE(GT_TRANS_MATERIAL_TYPE_ID)
	;

	ALTER TABLE GT_TRANS_ITEM ADD CONSTRAINT RefPRODUCT_REVISION962 
		FOREIGN KEY (PRODUCT_ID, REVISION_ID)
		REFERENCES PRODUCT_REVISION(PRODUCT_ID, REVISION_ID)
	;
	
CREATE SEQUENCE gt_trans_item_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;
	
	BEGIN
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (1,'Aluminium',20,1, 5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (2,'Bio / compostable',20,2, 2.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (3,'Ceramics, type 1 glass, black glass',20,3, 0);  -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (4,'Composite (tetra pak)',20,4, 3);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (5,'Degradeable',20,5, 3.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (6,'Glass',50,6, 1);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (7,'HDPE',25,7, 2.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (8,'LDPE',20,8, 3);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (9,'Mixed materials',20,9, 4);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (10,'Mixed materials (laminates)',20,10, 0); -- this doesnt seem to be wanted by andrew (judging by LIST 3A GT ... dec 3.xls
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (11,'Other (ceramics)',20,11, 2);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (12,'Other (Type 1 / Black glass)',20,12, 2.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (13,'Other plastics',20,13, 3);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (14,'Paper / card - non FSC',50,14, 1.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (15,'PE Blend',20,17, 3);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (16,'PET',25,18, 4);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (17,'PP',20,19, 3.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (18,'PS',20,20, 4);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (19,'PVC',20,21, 4);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (20,'Steel',20,22, 2.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (21,'Paper / card - FSC mixed',50,15, 1.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (22,'Paper / card - FSC pure',50,16, 1.5);
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (23,'Wood',20,23, 1.5); --only the env_impact score is  definitely right for these last two - have put in 20% recycled threshold
		INSERT INTO gt_trans_material_type (gt_trans_material_type_id, description, recycled_pct_theshold, pos, env_impact_score) VALUES (24,'ABS / SAN',20,24, 1.5);			
	END;
	/
	
	BEGIN
		FOR r IN (SELECT product_id, revision_id, NVL(pack_consum_pct, 0) pack_consum_pct, total_trans_pack_weight FROM gt_packaging_answers)
		LOOP
		
			IF(r.total_trans_pack_weight IS NOT NULL) AND (r.total_trans_pack_weight>0) THEN 
		
				INSERT INTO gt_trans_item (gt_trans_item_id, product_id, revision_id, pct_recycled, weight_grams, gt_trans_material_type_id) 
					VALUES (gt_trans_item_id_seq.NEXTVAL, r.product_id, r.revision_id, r.pack_consum_pct, r.total_trans_pack_weight, 14);
				
			END IF;
			
		END LOOP;
	END;
	/
	
	UPDATE gt_trans_item SET pct_recycled = 0 WHERE pct_recycled = -1;
	


	ALTER TABLE gt_profile ADD trans_pack_ei NUMBER(10, 2);
	ALTER TABLE gt_profile ADD recycled_pct NUMBER(10, 2);
	ALTER TABLE gt_profile ADD sum_trans_weight NUMBER(10, 2);
	
	--TO DO - check manually on live before dropping
	ALTER TABLE gt_packaging_answers DROP COLUMN pack_consum_pct;
	ALTER TABLE gt_packaging_answers DROP COLUMN pack_consum_mat;
	ALTER TABLE gt_packaging_answers DROP COLUMN total_trans_pack_weight;
	ALTER TABLE gt_packaging_answers DROP COLUMN pack_consum_rcyld;
		
		




@update_tail