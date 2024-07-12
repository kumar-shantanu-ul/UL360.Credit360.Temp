define version=99
@update_header


CREATE SEQUENCE GT_FD_ANSWER_SCHEME_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE SEQUENCE GT_FD_INGREDIENT_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

-- TABLE: GT_FD_ANSWER_SCHEME 
--

CREATE TABLE GT_FD_ANSWER_SCHEME(
    GT_FD_ANSWER_SCHEME_ID    NUMBER(10, 0)    NOT NULL,
    GT_FD_SCHEME_ID           NUMBER(10, 0)    NOT NULL,
    PRODUCT_ID                NUMBER(10, 0)    NOT NULL,
    REVISION_ID               NUMBER(10, 0)    NOT NULL,
    PERCENT_OF_PRODUCT        NUMBER(10, 2),
    WHOLE_PRODUCT             NUMBER(1, 0),
    CONSTRAINT PK384 PRIMARY KEY (GT_FD_ANSWER_SCHEME_ID, GT_FD_SCHEME_ID, PRODUCT_ID, REVISION_ID)
)
;



-- 
-- TABLE: GT_FD_ENDANGERED_SP 
--

CREATE TABLE GT_FD_ENDANGERED_SP(
    PRODUCT_ID                  NUMBER(10, 0)    NOT NULL,
    REVISION_ID                 NUMBER(10, 0)    NOT NULL,
    GT_ENDANGERED_SPECIES_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK391 PRIMARY KEY (PRODUCT_ID, REVISION_ID, GT_ENDANGERED_SPECIES_ID)
)
;



-- 
-- TABLE: GT_FD_INGRED_GROUP 
--

CREATE TABLE GT_FD_INGRED_GROUP(
    GT_FD_INGRED_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                VARCHAR2(255)    NOT NULL,
    CONSTRAINT PK380_1 PRIMARY KEY (GT_FD_INGRED_GROUP_ID)
)
;



-- 
-- TABLE: GT_FD_INGRED_PROV_TYPE 
--

CREATE TABLE GT_FD_INGRED_PROV_TYPE(
    GT_FD_INGRED_PROV_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                  VARCHAR2(255)    NOT NULL,
    NATURAL                      NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    SCORE                        NUMBER(4, 2)     NOT NULL,
    CONSTRAINT PK273_1_2 PRIMARY KEY (GT_FD_INGRED_PROV_TYPE_ID)
)
;

CREATE TABLE GT_INGRED_ACCRED_TYPE(
    GT_INGRED_ACCRED_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                  VARCHAR2(255)    NOT NULL,
    SCORE                        NUMBER(4, 2)     NOT NULL,
    NEEDS_NOTE                   NUMBER(1, 0)     DEFAULT 0 NOT NULL,
    CONSTRAINT GT_INGRED_ACCRED_TYPE_PK PRIMARY KEY (GT_INGRED_ACCRED_TYPE_ID)
)
;



-- 
-- TABLE: GT_FD_INGRED_TYPE 
--

CREATE TABLE GT_FD_INGRED_TYPE(
    GT_FD_INGRED_TYPE_ID      NUMBER(10, 0)    NOT NULL,
    GT_FD_INGRED_GROUP_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION                VARCHAR2(255)    NOT NULL,
	ENV_IMPACT_SCORE 			NUMBER(4, 2) NOT NULL,
	WATER_IMPACT_SCORE 			NUMBER(4, 2) NOT NULL,
	PESTICIDE_SCORE 			NUMBER(4, 2) NOT NULL,
	DEFAULT_GT_SA_SCORE			NUMBER(10, 0) NOT NULL,
    CONSTRAINT PK380 PRIMARY KEY (GT_FD_INGRED_TYPE_ID)
)
;



-- 
-- TABLE: GT_FD_INGREDIENT 
--

CREATE TABLE GT_FD_INGREDIENT(
    PRODUCT_ID                   NUMBER(10, 0)    NOT NULL,
    REVISION_ID                  NUMBER(10, 0)    NOT NULL,
    GT_FD_INGREDIENT_ID          NUMBER(10, 0)    NOT NULL,
    GT_FD_INGRED_TYPE_ID         NUMBER(10, 0),
    PCT_OF_PRODUCT               NUMBER(10, 2),
    SEASONAL                     NUMBER(1, 0),
    GT_FD_INGRED_PROV_TYPE_ID    NUMBER(10, 0),
    GT_INGRED_ACCRED_TYPE_ID     NUMBER(10, 0),
    ACCRED_SCHEME_NAME           VARCHAR2(255),
    GT_WATER_STRESS_REGION_ID    NUMBER(10, 0),
    CONSTRAINT PK377 PRIMARY KEY (PRODUCT_ID, REVISION_ID, GT_FD_INGREDIENT_ID)
)
;



-- 
-- TABLE: GT_FD_PALM_IND 
--

CREATE TABLE GT_FD_PALM_IND(
    PRODUCT_ID           NUMBER(10, 0)    NOT NULL,
    REVISION_ID          NUMBER(10, 0)    NOT NULL,
    GT_PALM_INGRED_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK390 PRIMARY KEY (PRODUCT_ID, REVISION_ID, GT_PALM_INGRED_ID)
)
;



-- 
-- TABLE: GT_FD_PORTION_TYPE 
--

CREATE TABLE GT_FD_PORTION_TYPE(
    GT_FD_PORTION_TYPE_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION              VARCHAR2(255)    NOT NULL,
	SCORE					 NUMBER(10, 2)		NOT NULL,
    CONSTRAINT PK385 PRIMARY KEY (GT_FD_PORTION_TYPE_ID)
)
;



-- 
-- TABLE: GT_FD_SCHEME 
--

CREATE TABLE GT_FD_SCHEME(
    GT_FD_SCHEME_ID    NUMBER(10, 0)    NOT NULL,
    DESCRIPTION        VARCHAR2(255)    NOT NULL,
	SCORE 			   NUMBER(10, 2)	NOT NULL,
    CONSTRAINT PK383 PRIMARY KEY (GT_FD_SCHEME_ID)
)
;



-- 
-- TABLE: GT_FOOD_ANC_MAT 
--

CREATE TABLE GT_FOOD_ANC_MAT(
    GT_ANCILLARY_MATERIAL_ID    NUMBER(10, 0)    NOT NULL,
    PRODUCT_ID                  NUMBER(10, 0)    NOT NULL,
    REVISION_ID                 NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK212_2 PRIMARY KEY (GT_ANCILLARY_MATERIAL_ID, PRODUCT_ID, REVISION_ID)
)
;



-- 
-- TABLE: GT_FOOD_ANSWERS 
--

CREATE TABLE GT_FOOD_ANSWERS(
    PRODUCT_ID               NUMBER(10, 0)    NOT NULL,
    REVISION_ID              NUMBER(10, 0)    NOT NULL,
    PCT_ADDED_WATER          NUMBER(10, 2),
    PCT_HIGH_RISK            NUMBER(10, 2),
    GT_FD_PORTION_TYPE_ID    NUMBER(10, 0),
    CONSTRAINT PK375 PRIMARY KEY (PRODUCT_ID, REVISION_ID)
)
;
-- TABLE: GT_FD_ANSWER_SCHEME 
--

ALTER TABLE GT_FD_ANSWER_SCHEME ADD CONSTRAINT RefGT_FOOD_ANSWERS997 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FOOD_ANSWERS(PRODUCT_ID, REVISION_ID)
;

ALTER TABLE GT_FD_ANSWER_SCHEME ADD CONSTRAINT RefGT_FD_SCHEME998 
    FOREIGN KEY (GT_FD_SCHEME_ID)
    REFERENCES GT_FD_SCHEME(GT_FD_SCHEME_ID)
;


-- 
-- TABLE: GT_FD_ENDANGERED_SP 
--

ALTER TABLE GT_FD_ENDANGERED_SP ADD CONSTRAINT RefGT_ENDANGERED_SPECIES999 
    FOREIGN KEY (GT_ENDANGERED_SPECIES_ID)
    REFERENCES GT_ENDANGERED_SPECIES(GT_ENDANGERED_SPECIES_ID)
;

ALTER TABLE GT_FD_ENDANGERED_SP ADD CONSTRAINT RefGT_FOOD_ANSWERS1000 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FOOD_ANSWERS(PRODUCT_ID, REVISION_ID)
;


-- 
-- TABLE: GT_FD_INGRED_TYPE 
--

ALTER TABLE GT_FD_INGRED_TYPE ADD CONSTRAINT RefGT_FD_INGRED_GROUP1001 
    FOREIGN KEY (GT_FD_INGRED_GROUP_ID)
    REFERENCES GT_FD_INGRED_GROUP(GT_FD_INGRED_GROUP_ID)
;


-- 
-- TABLE: GT_FD_INGREDIENT 
--

ALTER TABLE GT_FD_INGREDIENT ADD CONSTRAINT RefGT_WATER_STRESS_REGION1002 
    FOREIGN KEY (GT_WATER_STRESS_REGION_ID)
    REFERENCES GT_WATER_STRESS_REGION(GT_WATER_STRESS_REGION_ID)
;

ALTER TABLE GT_FD_INGREDIENT ADD CONSTRAINT RefGT_INGRED_ACCRED_TYPE1003 
    FOREIGN KEY (GT_INGRED_ACCRED_TYPE_ID)
    REFERENCES GT_INGRED_ACCRED_TYPE(GT_INGRED_ACCRED_TYPE_ID)
;

ALTER TABLE GT_FD_INGREDIENT ADD CONSTRAINT RefGT_FD_INGRED_PROV_TYPE1004 
    FOREIGN KEY (GT_FD_INGRED_PROV_TYPE_ID)
    REFERENCES GT_FD_INGRED_PROV_TYPE(GT_FD_INGRED_PROV_TYPE_ID)
;

ALTER TABLE GT_FD_INGREDIENT ADD CONSTRAINT RefGT_FD_INGRED_TYPE1005 
    FOREIGN KEY (GT_FD_INGRED_TYPE_ID)
    REFERENCES GT_FD_INGRED_TYPE(GT_FD_INGRED_TYPE_ID)
;

ALTER TABLE GT_FD_INGREDIENT ADD CONSTRAINT RefGT_FOOD_ANSWERS1006 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FOOD_ANSWERS(PRODUCT_ID, REVISION_ID)
;


-- 
-- TABLE: GT_FD_PALM_IND 
--

ALTER TABLE GT_FD_PALM_IND ADD CONSTRAINT RefGT_PALM_INGRED1007 
    FOREIGN KEY (GT_PALM_INGRED_ID)
    REFERENCES GT_PALM_INGRED(GT_PALM_INGRED_ID)
;

ALTER TABLE GT_FD_PALM_IND ADD CONSTRAINT RefGT_FOOD_ANSWERS1008 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FOOD_ANSWERS(PRODUCT_ID, REVISION_ID)
;


-- 
-- TABLE: GT_FOOD_ANC_MAT 
--

ALTER TABLE GT_FOOD_ANC_MAT ADD CONSTRAINT RefGT_FOOD_ANSWERS1009 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES GT_FOOD_ANSWERS(PRODUCT_ID, REVISION_ID)
;

ALTER TABLE GT_FOOD_ANC_MAT ADD CONSTRAINT RefGT_ANCILLARY_MATERIAL1010 
    FOREIGN KEY (GT_ANCILLARY_MATERIAL_ID)
    REFERENCES GT_ANCILLARY_MATERIAL(GT_ANCILLARY_MATERIAL_ID)
;


-- 
-- TABLE: GT_FOOD_ANSWERS 
--

ALTER TABLE GT_FOOD_ANSWERS ADD CONSTRAINT RefGT_FD_PORTION_TYPE1011 
    FOREIGN KEY (GT_FD_PORTION_TYPE_ID)
    REFERENCES GT_FD_PORTION_TYPE(GT_FD_PORTION_TYPE_ID)
;

ALTER TABLE GT_FOOD_ANSWERS ADD CONSTRAINT RefPRODUCT_REVISION1012 
    FOREIGN KEY (PRODUCT_ID, REVISION_ID)
    REFERENCES PRODUCT_REVISION(PRODUCT_ID, REVISION_ID)
;

@update_tail