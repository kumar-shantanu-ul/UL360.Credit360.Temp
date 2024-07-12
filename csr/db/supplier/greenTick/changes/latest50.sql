-- Please update version.sql too -- this keeps clean builds in sync
define version=50

@update_header

	
	ALTER TABLE SUPPLIER.GT_BATTERY
		ADD (GT_BATTERY_TYPE_ID  NUMBER(10)                   NULL);

	UPDATE gt_battery SET GT_BATTERY_TYPE_ID = 1;
	
	ALTER TABLE SUPPLIER.GT_BATTERY
	MODIFY(GT_BATTERY_TYPE_ID  NOT NULL);
		
	-- 
	-- TABLE: GT_BATTERY_TYPE 
	--
	CREATE TABLE GT_BATTERY_TYPE(
		GT_BATTERY_TYPE_ID    NUMBER(10, 0)    NOT NULL,
		DESCRIPTION           VARCHAR2(255)    NOT NULL,
		waste_score    NUMBER(10, 2)    NOT NULL,
		env_score    NUMBER(10, 2)    NOT NULL,
		energy_home_score    NUMBER(10, 2)    NOT NULL,
		rechargable    NUMBER(1, 0)    NOT NULL,
		CONSTRAINT PK331 PRIMARY KEY (GT_BATTERY_TYPE_ID)
	)
	;

	
	-- set up battery type
	INSERT INTO gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, rechargable) VALUES (1, 'Primary Battery', -1, -1, 1, 0);
	INSERT INTO gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, rechargable) VALUES (2, 'Rechargeable Battery', 1, 1, 2, 1);
	INSERT INTO gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, rechargable) VALUES (3, 'Fixed Battery - primary', 5, 5, 1, 0);
	INSERT INTO gt_battery_type (gt_battery_type_id, description, waste_score, env_score, energy_home_score, rechargable) VALUES (4, 'Fixed Battery - rechargeable', 4, 1, 2, 1);
	

	ALTER TABLE GT_BATTERY ADD CONSTRAINT RefGT_BATTERY_TYPE878 
		FOREIGN KEY (GT_BATTERY_TYPE_ID)
		REFERENCES GT_BATTERY_TYPE(GT_BATTERY_TYPE_ID)
	;	

	-- add colls to gt_pda_battery
	ALTER TABLE SUPPLIER.GT_PDA_BATTERY
	 ADD (GT_BATTERY_USE_ID  NUMBER(10)                 NULL);

	ALTER TABLE SUPPLIER.GT_PDA_BATTERY
	 ADD (USE_DESC  VARCHAR2(255));

	UPDATE GT_PDA_BATTERY SET GT_BATTERY_USE_ID = 1;
	
	ALTER TABLE SUPPLIER.GT_PDA_BATTERY
	MODIFY(GT_BATTERY_USE_ID  NOT NULL);	 
	
	 
	-- 
	-- TABLE: GT_BATTERY_USE 
	--
	CREATE TABLE GT_BATTERY_USE(
		GT_BATTERY_USE_ID    NUMBER(10, 0)    NOT NULL,
		DESCRIPTION          VARCHAR2(255)    NOT NULL,
		WASTE_SCORE          NUMBER(10, 2)    NOT NULL,
		CONSTRAINT PK333 PRIMARY KEY (GT_BATTERY_USE_ID)
	)
	;
	
	INSERT INTO gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (1, 'Occasional use', 1);
	INSERT INTO gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (2, '<1 battery / month', 1);
	INSERT INTO gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (3, '2-5 batteries /month', 2);
	INSERT INTO gt_battery_use (gt_battery_use_id, description, waste_score) VALUES (4, '5+ batteries / month', 3);

	
	ALTER TABLE GT_PDA_BATTERY ADD CONSTRAINT RefGT_BATTERY_USE880 
		FOREIGN KEY (GT_BATTERY_USE_ID)
		REFERENCES GT_BATTERY_USE(GT_BATTERY_USE_ID)
	;
	
	----
	
@update_tail