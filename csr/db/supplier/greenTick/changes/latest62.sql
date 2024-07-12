
-- Please update version.sql too -- this keeps clean builds in sync
define version=62
@update_header


-- 
-- TABLE: GT_ENDANGERED_PROD_CLASS_MAP 
--
CREATE TABLE GT_ENDANGERED_PROD_CLASS_MAP(
    GT_PRODUCT_CLASS_ID         NUMBER(10, 0)    NOT NULL,
    GT_ENDANGERED_SPECIES_ID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK343 PRIMARY KEY (GT_PRODUCT_CLASS_ID, GT_ENDANGERED_SPECIES_ID)
)
;

-- 
-- TABLE: GT_ENDANGERED_PROD_CLASS_MAP 
--

ALTER TABLE GT_ENDANGERED_PROD_CLASS_MAP ADD CONSTRAINT RefGT_ENDANGERED_SPECIES899 
    FOREIGN KEY (GT_ENDANGERED_SPECIES_ID)
    REFERENCES GT_ENDANGERED_SPECIES(GT_ENDANGERED_SPECIES_ID)
;

ALTER TABLE GT_ENDANGERED_PROD_CLASS_MAP ADD CONSTRAINT RefGT_PRODUCT_CLASS900 
    FOREIGN KEY (GT_PRODUCT_CLASS_ID)
    REFERENCES GT_PRODUCT_CLASS(GT_PRODUCT_CLASS_ID)
;


INSERT INTO GT_ENDANGERED_PROD_CLASS_MAP (GT_PRODUCT_CLASS_ID, GT_ENDANGERED_SPECIES_ID)
	SELECT GT_PRODUCT_CLASS_ID, GT_ENDANGERED_SPECIES_ID 
	  FROM GT_ENDANGERED_SPECIES, GT_PRODUCT_CLASS 
	 WHERE GT_PRODUCT_CLASS_ID IN (1,2);
	

@update_tail