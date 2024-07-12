-- Please update version.sql too -- this keeps clean builds in sync
define version=1047
@update_header

BEGIN
	-- Drop existing check constraints as they are unnamed, and some are incorrect
	FOR r IN (
         SELECT owner, constraint_name, table_name, search_condition
           FROM all_constraints
          WHERE owner = 'CT' 
            AND table_name ='EC_QUESTIONNAIRE_ANSWERS' 
			AND constraint_type='C'
    )
    LOOP
		IF r.search_condition NOT LIKE '%IS NOT NULL%' THEN
			EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
		END IF;
    END LOOP;
END;
/

BEGIN
	-- Drop existing check constraints as they are unnamed, and some are incorrect
	FOR r IN (
         SELECT owner, constraint_name, table_name, search_condition
           FROM all_constraints
          WHERE owner = 'CT' 
            AND table_name ='EC_REGION' 
			AND constraint_type='C'
    )
    LOOP
		IF r.search_condition NOT LIKE '%IS NOT NULL%' THEN
			EXECUTE IMMEDIATE 'ALTER TABLE '||r.owner||'.'||r.table_name||' DROP CONSTRAINT '||r.constraint_name;
		END IF;
    END LOOP;
END;
/
	
-- recreate correct dropped constraints with names
ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_BIKE_DAYS_PER_WK 
    CHECK (BIKE_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_BUS_DAYS_PER_WK 
    CHECK (BUS_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_CAR_DAYS_PER_WK 
    CHECK (CAR_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_FULL_TIME_EMPLOYEE 
    CHECK (FULL_TIME_EMPLOYEE  IN (1,0));

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_HOME_DAYS_PER_WK 
    CHECK (HOME_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_MOTORBIKE_DAYS_PER_WK 
    CHECK (MOTORBIKE_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_TRAIN_DAYS_PER_WK 
    CHECK (TRAIN_DAYS_PER_WK <= 7);

ALTER TABLE CT.EC_QUESTIONNAIRE_ANSWERS ADD CONSTRAINT CC_EQA_WALK_DAYS_PER_WK 
    CHECK (WALK_DAYS_PER_WK <= 7);
	
ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_BIKE_AVG_PCT_USE 
    CHECK ((BIKE_AVG_PCT_USE <= 100) AND (BIKE_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_BUS_AVG_PCT_USE 
    CHECK ((BUS_AVG_PCT_USE <= 100) AND (BUS_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_CAR_AVG_PCT_USE 
    CHECK ((CAR_AVG_PCT_USE <= 100) AND (CAR_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_MOTORBIKE_AVG_PCT_USE 
    CHECK ((MOTORBIKE_AVG_PCT_USE <= 100) AND (MOTORBIKE_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_TRAIN_AVG_PCT_USE 
    CHECK ((TRAIN_AVG_PCT_USE <= 100) AND (TRAIN_AVG_PCT_USE >= 0));

ALTER TABLE CT.EC_REGION ADD CONSTRAINT CC_ER_WALK_AVG_PCT_USE 
    CHECK ((WALK_AVG_PCT_USE <= 100) AND (WALK_AVG_PCT_USE >= 0));


-- Create new tables
CREATE TABLE CT.EC_ESTIMATION (
	APP_SID NUMBER(10) CONSTRAINT NN_EC_EST_APP_SID NOT NULL,
    COMPANY_SID NUMBER(10) CONSTRAINT NN_EC_EST_COMPANY_SID NOT NULL,
    CAR_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_CAR_PCT_USE NOT NULL,
    BUS_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_BUS_PCT_USE NOT NULL,
    TRAIN_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_TRAIN_PCT_USE NOT NULL,
    MOTORBIKE_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_MOTORBIKE_PCT_USE NOT NULL,
    BIKE_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_BIKE_PCT_USE NOT NULL,
    WALK_PCT_USE NUMBER(20,10) CONSTRAINT NN_EC_EST_WALK_PCT_USE NOT NULL,
    CAR_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_CAR_JOURNEY_KM NOT NULL,
    BUS_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_BUS_JOURNEY_KM NOT NULL,
    TRAIN_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_TRAIN_JOURNEY_KM NOT NULL,
    MOTORBIKE_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_MOTORBIKE_JOURNEY_KM NOT NULL,
    BIKE_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_BIKE_JOURNEY_KM NOT NULL,
    WALK_JOURNEY_KM NUMBER(20,10) CONSTRAINT NN_EC_EST_WALK_JOURNEY_KM NOT NULL,
    CONSTRAINT PK_EC_EST PRIMARY KEY (APP_SID, COMPANY_SID)
);

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_BIKE_PCT_USE 
    CHECK ((BIKE_PCT_USE <= 100) AND (BIKE_PCT_USE >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_BUS_PCT_USE 
    CHECK ((BUS_PCT_USE <= 100) AND (BUS_PCT_USE >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_CAR_PCT_USE 
    CHECK ((CAR_PCT_USE <= 100) AND (CAR_PCT_USE >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_MOTORBIKE_PCT_USE 
    CHECK ((MOTORBIKE_PCT_USE <= 100) AND (MOTORBIKE_PCT_USE >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_TRAIN_PCT_USE 
    CHECK ((TRAIN_PCT_USE <= 100) AND (TRAIN_PCT_USE >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT CC_EC_EST_WALK_PCT_USE 
    CHECK ((WALK_PCT_USE <= 100) AND (WALK_PCT_USE >= 0));
	
CREATE TABLE CT.EC_CAR (
	APP_SID NUMBER(10) CONSTRAINT NN_EC_CAR_APP_SID NOT NULL,
	COMPANY_SID NUMBER(10) CONSTRAINT NN_EC_CAR_COMPANY_SID NOT NULL,
	CAR_TYPE_ID NUMBER(10) CONSTRAINT NN_EC_CAR_CAR_TYPE_ID NOT NULL,
	PCT NUMBER(10) CONSTRAINT NN_EC_CAR_PCT NOT NULL,
	CONSTRAINT PK_EC_CAR PRIMARY KEY (APP_SID, COMPANY_SID, CAR_TYPE_ID)
);

ALTER TABLE CT.EC_CAR ADD CONSTRAINT CC_EC_CAR_PCT 
	CHECK ((PCT <= 100) AND (PCT >= 0));

CREATE TABLE CT.EC_BUS (
	APP_SID NUMBER(10) CONSTRAINT NN_EC_BUS_APP_SID NOT NULL,
	COMPANY_SID NUMBER(10) CONSTRAINT NN_EC_BUS_COMPANY_SID NOT NULL,
	BUS_TYPE_ID NUMBER(10) CONSTRAINT NN_EC_BUS_BUS_TYPE_ID NOT NULL,
	PCT NUMBER(10) CONSTRAINT NN_EC_BUS_PCT NOT NULL,
	CONSTRAINT PK_EC_BUS PRIMARY KEY (APP_SID, COMPANY_SID, BUS_TYPE_ID)
);

ALTER TABLE CT.EC_BUS ADD CONSTRAINT CC_EC_BUS_PCT 
	CHECK ((PCT <= 100) AND (PCT >= 0));

CREATE TABLE CT.EC_TRAIN (
	APP_SID NUMBER(10) CONSTRAINT NN_EC_TRAIN_APP_SID NOT NULL,
	COMPANY_SID NUMBER(10) CONSTRAINT NN_EC_TRAIN_COMPANY_SID NOT NULL,
	TRAIN_TYPE_ID NUMBER(10) CONSTRAINT NN_EC_TRAIN_TRAIN_TYPE_ID NOT NULL,
	PCT NUMBER(10) CONSTRAINT NN_EC_TRAIN_PCT NOT NULL,
	CONSTRAINT PK_EC_TRAIN PRIMARY KEY (APP_SID, COMPANY_SID, TRAIN_TYPE_ID)
);

ALTER TABLE CT.EC_TRAIN ADD CONSTRAINT CC_EC_TRAIN_PCT 
	CHECK ((PCT <= 100) AND (PCT >= 0));

CREATE TABLE CT.EC_MOTORBIKE (
    APP_SID NUMBER(10) CONSTRAINT NN_EC_MB_APP_SID NOT NULL,
    COMPANY_SID NUMBER(10) CONSTRAINT NN_EC_MB_COMPANY_SID NOT NULL,
    MOTORBIKE_TYPE_ID NUMBER(10) CONSTRAINT NN_EC_MB_MOTORBIKE_TYPE_ID NOT NULL,
    PCT NUMBER(10) CONSTRAINT NN_EC_MB_PCT NOT NULL,
    CONSTRAINT PK_EC_MB PRIMARY KEY (APP_SID, COMPANY_SID, MOTORBIKE_TYPE_ID)
);

ALTER TABLE CT.EC_MOTORBIKE ADD CONSTRAINT CC_EC_MB_PCT 
    CHECK ((PCT <= 100) AND (PCT >= 0));

ALTER TABLE CT.EC_ESTIMATION ADD CONSTRAINT COMPANY_EC_EST 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_CAR ADD CONSTRAINT CAR_TYPE_EC_CAR 
	FOREIGN KEY (CAR_TYPE_ID) REFERENCES CT.CAR_TYPE (CAR_TYPE_ID);

ALTER TABLE CT.EC_CAR ADD CONSTRAINT EC_ESTIMATION_EC_CAR 
	FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.EC_ESTIMATION (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_BUS ADD CONSTRAINT EC_ESTIMATION_EC_BUS 
	FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.EC_ESTIMATION (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_BUS ADD CONSTRAINT BUS_TYPE_EC_BUS 
	FOREIGN KEY (BUS_TYPE_ID) REFERENCES CT.BUS_TYPE (BUS_TYPE_ID);

ALTER TABLE CT.EC_TRAIN ADD CONSTRAINT EC_ESTIMATION_EC_TRAIN 
	FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.EC_ESTIMATION (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_TRAIN ADD CONSTRAINT TRAIN_TYPE_EC_TRAIN 
	FOREIGN KEY (TRAIN_TYPE_ID) REFERENCES CT.TRAIN_TYPE (TRAIN_TYPE_ID);

ALTER TABLE CT.EC_MOTORBIKE ADD CONSTRAINT EC_EST_EC_MB 
    FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.EC_ESTIMATION (APP_SID,COMPANY_SID);

ALTER TABLE CT.EC_MOTORBIKE ADD CONSTRAINT MOTORBIKE_TYPE_EC_MB 
    FOREIGN KEY (MOTORBIKE_TYPE_ID) REFERENCES CT.MOTORBIKE_TYPE (MOTORBIKE_TYPE_ID);
	

--Create temporary packages needed to create capability - just relevant snapshotted parts have been put there
-- Also has chain_pkg with new CT_EMPLOYEE_COMMUTE const definition
@@latest1047_packages

BEGIN
	-- logon as builtin admin, no app
	security.user_pkg.logonadmin;
	chain.temp_capability_pkg.RegisterCapability(chain.chain_pkg.CT_COMPANIES, chain.chain_pkg.CT_EMPLOYEE_COMMUTE, chain.chain_pkg.SPECIFIC_PERMISSION);
	chain.temp_capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_EMPLOYEE_COMMUTE, chain.chain_pkg.ADMIN_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	chain.temp_capability_pkg.GrantCapability(chain.chain_pkg.CT_COMPANY, chain.chain_pkg.CT_EMPLOYEE_COMMUTE, chain.chain_pkg.USER_GROUP, security.security_pkg.PERMISSION_READ + security.security_pkg.PERMISSION_WRITE);
	
	FOR r IN (SELECT host FROM chain.v$chain_host) LOOP
		security.user_pkg.LogonAdmin(r.host);
		FOR r IN (
			SELECT company_sid
			  FROM chain.company
			 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
		) LOOP
			chain.temp_capability_pkg.RefreshCompanyCapabilities(r.company_sid);
		END LOOP;
		
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/

DROP PACKAGE chain.temp_capability_pkg;

BEGIN
	security.user_pkg.logonadmin;
	chain.temp_card_pkg.RegisterCard(
		'Employee Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/commutingBreakdown.js',
		'CarbonTrust.Cards.CommutingBreakdown'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Car Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/carCommuting.js',
		'CarbonTrust.Cards.CarCommuting'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Bus Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/busCommuting.js',
		'CarbonTrust.Cards.BusCommuting'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Train Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/trainCommuting.js',
		'CarbonTrust.Cards.TrainCommuting'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Motorbike Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/motorbikeCommuting.js',
		'CarbonTrust.Cards.MotorbikeCommuting'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Bike Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/bikeCommuting.js',
		'CarbonTrust.Cards.BikeCommuting'
	);
	
	chain.temp_card_pkg.RegisterCard(
		'Walk Commuting Breakdown - used by CarbonTrust tool',
		'Credit360.CarbonTrust.Cards.EmployeeCommutingWizard',
		'/csr/site/ct/cards/walkCommuting.js',
		'CarbonTrust.Cards.WalkCommuting'
	);
	
	FOR r IN (SELECT host FROM chain.v$chain_host) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		chain.temp_card_pkg.RegisterCardGroup(29, 'Employee Commuting Wizard', 'Carbon Trust Employee Commuting Wizard');
		chain.temp_card_pkg.SetGroupCards('Employee Commuting Wizard', chain.T_STRING_LIST(
			'CarbonTrust.Cards.CommutingBreakdown',
			'CarbonTrust.Cards.CarCommuting',
			'CarbonTrust.Cards.BusCommuting',
			'CarbonTrust.Cards.TrainCommuting',
			'CarbonTrust.Cards.MotorbikeCommuting',
			'CarbonTrust.Cards.BikeCommuting',
			'CarbonTrust.Cards.WalkCommuting'
		));
		
	END LOOP;
	
	security.user_pkg.logonadmin;
	
END;
/

DROP PACKAGE chain.temp_card_pkg;

@..\ct\emp_commute_pkg
@..\ct\emp_commute_body

@update_tail
