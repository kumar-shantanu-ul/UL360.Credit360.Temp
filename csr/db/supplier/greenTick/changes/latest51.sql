-- Please update version.sql too -- this keeps clean builds in sync
define version=51

@update_header

	DROP TABLE GT_PDA_BATTERY CASCADE CONSTRAINTS;
	
	-- recreate battery table
	-- 
	-- TABLE: GT_PDA_BATTERY 
	--

	CREATE TABLE GT_PDA_BATTERY(
		GT_PDA_BATTERY_ID     NUMBER(10, 0)    NOT NULL,
		PRODUCT_ID            NUMBER(10, 0)    NOT NULL,
		REVISION_ID           NUMBER(10, 0)    NOT NULL,
		COUNT                 NUMBER(10, 0)    NOT NULL,
		GT_BATTERY_USE_ID     NUMBER(10, 0)    NOT NULL,
		USE_DESC              VARCHAR2(255),
		GT_BATTERY_CODE_ID    NUMBER(10, 0)    NOT NULL,
		CONSTRAINT PK264 PRIMARY KEY (GT_PDA_BATTERY_ID, PRODUCT_ID, REVISION_ID)
	)
	;
	
	ALTER TABLE GT_PDA_BATTERY ADD CONSTRAINT RefGT_PDESIGN_ANSWERS826 
		FOREIGN KEY (PRODUCT_ID, REVISION_ID)
		REFERENCES GT_PDESIGN_ANSWERS(PRODUCT_ID, REVISION_ID)
	;

	ALTER TABLE GT_PDA_BATTERY ADD CONSTRAINT RefGT_BATTERY827 
		FOREIGN KEY (GT_BATTERY_CODE_ID)
		REFERENCES GT_BATTERY(GT_BATTERY_CODE_ID)
	;
	
	ALTER TABLE GT_PDA_BATTERY ADD CONSTRAINT RefGT_BATTERY_USE880 
		FOREIGN KEY (GT_BATTERY_USE_ID)
		REFERENCES GT_BATTERY_USE(GT_BATTERY_USE_ID)
	;

	
	-- 
	-- TABLE: GT_PDA_MAIN_POWER 
	--

	CREATE TABLE GT_PDA_MAIN_POWER(
		GT_PDA_MAIN_POWER_ID    NUMBER(10, 0)    NOT NULL,
		STANDBY                 NUMBER(1, 0)     NOT NULL,
		WATTAGE                 NUMBER(10, 2)    NOT NULL,
		PRODUCT_ID              NUMBER(10, 0)    NOT NULL,
		REVISION_ID             NUMBER(10, 0)    NOT NULL,
		CONSTRAINT PK335 PRIMARY KEY (GT_PDA_MAIN_POWER_ID, PRODUCT_ID, REVISION_ID)
	)
	;
	
	-- 
	-- TABLE: GT_PDA_MAIN_POWER 
	--

	ALTER TABLE GT_PDA_MAIN_POWER ADD CONSTRAINT RefGT_PDESIGN_ANSWERS885 
		FOREIGN KEY (PRODUCT_ID, REVISION_ID)
		REFERENCES GT_PDESIGN_ANSWERS(PRODUCT_ID, REVISION_ID)
	;
	
	-- create new sequences
	CREATE SEQUENCE SUPPLIER.GT_PDA_MAIN_POWER_ID_SEQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;
  
  CREATE SEQUENCE SUPPLIER.GT_PDA_BATTERY_ID_SEQ
  START WITH 1
  MAXVALUE 999999999999999999999999999
  MINVALUE 1
  NOCYCLE
  CACHE 20
  NOORDER;

	
@update_tail