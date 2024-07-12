-- Please update version.sql too -- this keeps clean builds in sync
define version=84
@update_header
	
-- add WSR tables for FORMULATED

-- 
-- TABLE: GT_WATER_STRESS_REGION 
--

CREATE TABLE GT_WATER_STRESS_REGION(
    GT_WATER_STRESS_REGION_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                  VARCHAR2(200)    NOT NULL,
	SCORE   					 NUMBER(10, 2)    NOT NULL,
    POS						     NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK365 PRIMARY KEY (GT_WATER_STRESS_REGION_ID)
)
;

-- 
-- TABLE: GT_FA_WSR 
--

CREATE TABLE GT_FA_WSR(
    PRODUCT_ID                   NUMBER(10, 0)    NOT NULL,
    REVISION_ID                  NUMBER(10, 0)    NOT NULL,
    GT_WATER_STRESS_REGION_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK367 PRIMARY KEY (PRODUCT_ID, REVISION_ID, GT_WATER_STRESS_REGION_ID)
)
;

-- 
-- TABLE: GT_FA_WSR 
--

ALTER TABLE GT_FA_WSR ADD CONSTRAINT RefGT_WATER_STRESS_REGION961 
    FOREIGN KEY (GT_WATER_STRESS_REGION_ID)
    REFERENCES GT_WATER_STRESS_REGION(GT_WATER_STRESS_REGION_ID)
;

ALTER TABLE GT_FA_WSR ADD CONSTRAINT RefGT_FORMULATION_ANSWERS962 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FORMULATION_ANSWERS(PRODUCT_ID, REVISION_ID)
;


-- INSERT BASE DATA

INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (1, 1,'California', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (2, 2,'Southern Amazon (Peru, Bolivia, S Brazil)', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (3, 3,'Southern Russian states, Ukraine, Turkey', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (4, 4,'Middle East and Morocco, Algeria, Tunisia, Egypt, Libya', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (5, 5,'Sub Saharan Africa (Somalia, Ethiopia,Niger, Chad, Mali)', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (6, 6,'Northern India', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (7, 7,'China', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (8, 8,'Australia', 0.2);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (9, 9,'None of These', 0);
INSERT INTO gt_water_stress_region (gt_water_stress_region_id, pos, description, score) VALUES (10, 10, 'Unknown', 0.2);

-- set all existing to 'None of These'
INSERT INTO gt_fa_wsr (product_id, revision_id, gt_water_stress_region_id) 
    SELECT product_id, revision_id, 9 FROM gt_formulation_answers;

@update_tail