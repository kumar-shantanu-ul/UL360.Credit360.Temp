-- Please update version.sql too -- this keeps clean builds in sync
define version=1436

@update_header

-- restructure for DQ
alter table ct.CALCULATION_SOURCE rename to PS_CALCULATION_SOURCE;

alter table ct.PS_CALCULATION_SOURCE rename constraint PK_CALCULATION_SOURCE to PK_PS_CALCULATION_SOURCE;

alter table ct.PS_LEVEL_CONTRIBUTIONS rename CONSTRAINT CONT_SOURCE_PSLC  to PS_CONT_SOURCE_PSLC ;
alter table ct.PS_LEVEL_CONTRIBUTIONS rename constraint CALCULATION_SOURCE_PSLC  to PS_CALCULATION_SOURCE_PSLC ;

alter table ct.BT_EMISSIONS drop constraint CALCULATION_SOURCE_BT_EM;
alter table ct.EC_EMISSIONS drop constraint CALCULATION_SOURCE_EC_EM;

UPDATE ct.PS_EMISSIONS SET calculation_source_id = 4 WHERE calculation_source_id = 5;
UPDATE ct.PS_LEVEL_CONTRIBUTIONS SET calculation_source_id = 4 WHERE calculation_source_id = 5;
UPDATE ct.PS_LEVEL_CONTRIBUTIONS SET contribution_source_id = 4 WHERE contribution_source_id = 5;

UPDATE ct.PS_CALCULATION_SOURCE SET description = 'Turnover' WHERE calculation_source_id = 1;
UPDATE ct.PS_CALCULATION_SOURCE SET description = 'Extrapolated Product' WHERE calculation_source_id = 2;
UPDATE ct.PS_CALCULATION_SOURCE SET description = 'Product' WHERE calculation_source_id = 3;
UPDATE ct.PS_CALCULATION_SOURCE SET description = 'Apportionment' WHERE calculation_source_id = 4;
DELETE FROM ct.PS_CALCULATION_SOURCE WHERE calculation_source_id = 5;

-- BT DQ table
CREATE TABLE CT.BT_CALCULATION_SOURCE (
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_BT_CALCULATION_SOURCE PRIMARY KEY (CALCULATION_SOURCE_ID)
);

INSERT INTO ct.bt_calculation_source (calculation_source_id, description) VALUES (1, 'FTE Based');
INSERT INTO ct.bt_calculation_source (calculation_source_id, description) VALUES (2, 'Profile');
INSERT INTO ct.bt_calculation_source (calculation_source_id, description) VALUES (3, 'Extrapolated Upload');
INSERT INTO ct.bt_calculation_source (calculation_source_id, description) VALUES (4, 'Upload');


ALTER TABLE CT.BT_EMISSIONS ADD CONSTRAINT BT_CALCULATION_SOURCE_BT_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.BT_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

-- EX DQ table
CREATE TABLE CT.EC_CALCULATION_SOURCE (
    CALCULATION_SOURCE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    CONSTRAINT PK_EC_CALCULATION_SOURCE PRIMARY KEY (CALCULATION_SOURCE_ID)
);
	
INSERT INTO ct.ec_calculation_source (calculation_source_id, description) VALUES (1, 'FTE Based');
INSERT INTO ct.ec_calculation_source (calculation_source_id, description) VALUES (2, 'Profile');
INSERT INTO ct.ec_calculation_source (calculation_source_id, description) VALUES (3, 'Extrapolated Survey');
INSERT INTO ct.ec_calculation_source (calculation_source_id, description) VALUES (4, 'Survey');

ALTER TABLE CT.EC_EMISSIONS ADD CONSTRAINT EC_CALCULATION_SOURCE_EC_EM 
    FOREIGN KEY (CALCULATION_SOURCE_ID) REFERENCES CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID);

-- add new PS options  
 ALTER TABLE CT.PS_OPTIONS
ADD (AUTO_MATCH_THRESH NUMBER(5,2) DEFAULT 0 NOT NULL);

-- has a product been automatched
ALTER TABLE CT.PS_ITEM
ADD (MATCH_AUTO_ACCEPTED NUMBER(1) DEFAULT 0 NOT NULL CHECK (MATCH_AUTO_ACCEPTED IN (1,0)));

-- change extrap type for EC
ALTER TABLE CT.EC_OPTIONS DROP CONSTRAINT EXTRAP_TYPE_EC_OPT ;
  
ALTER TABLE CT.EC_OPTIONS
RENAME COLUMN EXTRAPOLATION_TYPE_ID TO EXTRAPOLATE;
  
ALTER TABLE CT.EC_OPTIONS ADD (
  CONSTRAINT CC_EC_OPT_EXTRAPOLATE
 CHECK (EXTRAPOLATE IN (1,0)));


-- PS restructuring - rolls these two table into one and replace with views
DROP TABLE CT.PS_EMISSIONS CASCADE CONSTRAINTS;
DROP TABLE CT.PS_LEVEL_CONTRIBUTIONS CASCADE CONSTRAINTS;

CREATE TABLE CT.PS_EMISSIONS_ALL
(
  APP_SID                NUMBER(10)             DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
  BREAKDOWN_ID           NUMBER(10)             NOT NULL,
  REGION_ID              NUMBER(10)             NOT NULL,
  EIO_ID                 NUMBER(10)             NOT NULL,
  CALCULATION_SOURCE_ID  NUMBER(10)             NOT NULL,
  CONTRIBUTION_SOURCE_ID  NUMBER(10)             NOT NULL,
  KG_CO2                 NUMBER(30,10)          NOT NULL
);

CREATE UNIQUE INDEX CT.PK_PS_EM ON CT.PS_EMISSIONS_ALL
(APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID);

ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT CC_PS_EM_KG_CO2
 CHECK (KG_CO2 >= 0));
 
ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT PK_PS_EM
 PRIMARY KEY
 (APP_SID, BREAKDOWN_ID, REGION_ID, EIO_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID));
 
ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT B_R_PS_EM 
 FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) 
 REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID));

ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT EIO_PS_EM 
 FOREIGN KEY (EIO_ID) 
 REFERENCES CT.EIO (EIO_ID));

ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT CALCULATION_SOURCE_PS_EM 
 FOREIGN KEY (CALCULATION_SOURCE_ID) 
 REFERENCES CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID));
 
ALTER TABLE CT.PS_EMISSIONS_ALL ADD (
  CONSTRAINT CONTRIBUTION_SOURCE_PS_EM 
 FOREIGN KEY (CONTRIBUTION_SOURCE_ID) 
 REFERENCES CT.PS_CALCULATION_SOURCE (CALCULATION_SOURCE_ID));
 	
-- now create PS views
CREATE OR REPLACE VIEW ct.v$ps_emissions
(
	app_sid,               
	breakdown_id,          
	region_id,             
	eio_id,                
	calculation_source_id, 
	kg_co2                
)
AS
SELECT 
	app_sid,               
	breakdown_id,          
	region_id,             
	eio_id,                
	calculation_source_id, 
	SUM(kg_co2) kg_co2
FROM 
	ct.ps_emissions_all
	GROUP BY app_sid, breakdown_id, region_id, eio_id, calculation_source_id;
	
CREATE OR REPLACE VIEW ct.v$ps_level_contributions
(
	app_sid,                             
	calculation_source_id, 
	contribution_source_id,
	kg_co2                
)
AS
SELECT 
	app_sid,                             
	calculation_source_id, 
	contribution_source_id,
	SUM(kg_co2) kg_co2
FROM 
	ct.ps_emissions_all
	GROUP BY app_sid, calculation_source_id, contribution_source_id;

-- EC emissions restructuring
DROP TABLE CT.EC_EMISSIONS CASCADE CONSTRAINTS;

CREATE TABLE CT.EC_EMISSIONS_ALL
(
  APP_SID                NUMBER(10)             DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
  BREAKDOWN_ID           NUMBER(10)             NOT NULL,
  REGION_ID              NUMBER(10)             NOT NULL,
  CALCULATION_SOURCE_ID  NUMBER(10)             NOT NULL,
  CONTRIBUTION_SOURCE_ID NUMBER(10)             NOT NULL,
  CAR_KG_CO2             NUMBER(30,10)          NOT NULL,
  BUS_KG_CO2             NUMBER(30,10)          NOT NULL,
  TRAIN_KG_CO2           NUMBER(30,10)          NOT NULL,
  MOTORBIKE_KG_CO2       NUMBER(30,10)          NOT NULL,
  BIKE_KG_CO2            NUMBER(30,10)          NOT NULL,
  WALK_KG_CO2            NUMBER(30,10)          NOT NULL
);


CREATE UNIQUE INDEX CT.PK_EC_EM ON CT.EC_EMISSIONS_ALL
(APP_SID, BREAKDOWN_ID, REGION_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID);


ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_WALK_KG_CO2
 CHECK (WALK_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_TRAIN_KG_CO2
 CHECK (TRAIN_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_MOTORBIKE_KG_CO2
 CHECK (MOTORBIKE_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_CAR_KG_CO2
 CHECK (CAR_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_BUS_KG_CO2
 CHECK (BUS_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT CC_EC_EM_BIKE_KG_CO2
 CHECK (BIKE_KG_CO2 >= 0));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT PK_EC_EM
 PRIMARY KEY
 (APP_SID, BREAKDOWN_ID, REGION_ID, CALCULATION_SOURCE_ID, CONTRIBUTION_SOURCE_ID)
);

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT EC_CONTRIBUTION_SOURCE_EC_EM 
 FOREIGN KEY (CONTRIBUTION_SOURCE_ID) 
 REFERENCES CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID));
 
ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT EC_CALCULATION_SOURCE_EC_EM 
 FOREIGN KEY (CALCULATION_SOURCE_ID) 
 REFERENCES CT.EC_CALCULATION_SOURCE (CALCULATION_SOURCE_ID));

ALTER TABLE CT.EC_EMISSIONS_ALL ADD (
  CONSTRAINT B_R_EC_EM 
 FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) 
 REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID));
 
 -- this is a bit odd - but we fall back to the region elec factor for elec - so "no co2 factor" means can be null in the power table
 ALTER TABLE CT.HT_CONSUMPTION_TYPE_POWER_UNIT
MODIFY(CO2_FACTOR  NULL);

UPDATE CT.HT_CONSUMPTION_TYPE_POWER_UNIT
SET CO2_FACTOR = null 
WHERE HT_CONSUMPTION_TYPE_ID = 1
AND HT_CONSUMPTION_CATEGORY_ID = 3; 
-- electricity


-- add time UOM table - this is compounding the issues with units not linking to CSR - but discussing approach and this is consistent until we switch all
CREATE TABLE CT.TIME_UNIT
(
  TIME_UNIT_ID        	NUMBER(10)             	NOT NULL,
  DESCRIPTION           VARCHAR2(100 BYTE)      NOT NULL,
  SYMBOL                VARCHAR2(40 BYTE)       NOT NULL,
  CONVERSION_TO_SECS	NUMBER(20,10)           NOT NULL
);

CREATE UNIQUE INDEX CT.PK_TIME_UNIT ON CT.TIME_UNIT
(TIME_UNIT_ID);

ALTER TABLE CT.TIME_UNIT ADD (
  CONSTRAINT PK_TIME_UNIT
 PRIMARY KEY
 (TIME_UNIT_ID)
);

ALTER TABLE CT.TIME_UNIT ADD (
  CONSTRAINT CC_TIME_UNIT_CS
 CHECK (CONVERSION_TO_SECS >= 0));

INSERT INTO CT.TIME_UNIT (TIME_UNIT_ID, DESCRIPTION, SYMBOL, CONVERSION_TO_SECS) VALUES (1, 'Seconds', 's', 1);
INSERT INTO CT.TIME_UNIT (TIME_UNIT_ID, DESCRIPTION, SYMBOL, CONVERSION_TO_SECS) VALUES (2, 'Minutes', 'min(s)', 60);
INSERT INTO CT.TIME_UNIT (TIME_UNIT_ID, DESCRIPTION, SYMBOL, CONVERSION_TO_SECS) VALUES (3, 'Hours', 'hr(s)', 3600);
INSERT INTO CT.TIME_UNIT (TIME_UNIT_ID, DESCRIPTION, SYMBOL, CONVERSION_TO_SECS) VALUES (4, 'Days', 'day(s)', 3600*60);

-- add time unit to bt trip
ALTER TABLE CT.BT_AIR_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_AIR_TRIP ADD (TIME_UNIT_ID  NUMBER(10));
ALTER TABLE CT.BT_AIR_TRIP ADD (CONSTRAINT TU_BT_AIR_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));
 
ALTER TABLE CT.BT_BUS_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_BUS_TRIP ADD (TIME_UNIT_ID  NUMBER(10)); 
ALTER TABLE CT.BT_BUS_TRIP ADD (CONSTRAINT TU_BT_BUS_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));
 
ALTER TABLE CT.BT_CAB_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_CAB_TRIP ADD (TIME_UNIT_ID  NUMBER(10)); 
ALTER TABLE CT.BT_CAB_TRIP ADD (CONSTRAINT TU_BT_CAB_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));
 
ALTER TABLE CT.BT_CAR_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_CAR_TRIP ADD (TIME_UNIT_ID  NUMBER(10));
ALTER TABLE CT.BT_CAR_TRIP ADD (CONSTRAINT TU_BT_CAR_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));

ALTER TABLE CT.BT_MOTORBIKE_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_MOTORBIKE_TRIP  ADD (TIME_UNIT_ID  NUMBER(10)); 
ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD (CONSTRAINT TU_BT_MB_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));
 
ALTER TABLE CT.BT_TRAIN_TRIP RENAME COLUMN TIME_IN_MINS TO TIME_AMOUNT;
ALTER TABLE CT.BT_TRAIN_TRIP  ADD (TIME_UNIT_ID  NUMBER(10)); 
ALTER TABLE CT.BT_TRAIN_TRIP ADD (CONSTRAINT TU_BT_TR_TRIP FOREIGN KEY (TIME_UNIT_ID) REFERENCES CT.TIME_UNIT (TIME_UNIT_ID));


-- RLS
CREATE OR REPLACE FUNCTION ct.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- This is:
	--
	-- Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR not logged on (i.e. needs to be fixed);
	-- OR logged on and data is for the current application
	--
	RETURN 'app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'') or sys_context(''SECURITY'', ''APP'') is null';
END;
/

CREATE OR REPLACE FUNCTION ct.nullableAppSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- This is:
	--
	--    Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR not logged on (i.e. needs to be fixed);
	-- OR logged on and data is for the current application
	-- OR app_sid is null and nullable
	--
	RETURN 'app_sid is null or app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'') or sys_context(''SECURITY'', ''APP'') is null';
END;
/


BEGIN
 	FOR r IN (
		SELECT c.owner, c.table_name, c.nullable, (SUBSTR(c.table_name, 1, 26) || '_POL') policy_name
		  FROM all_tables t
		  JOIN all_tab_columns c ON t.owner = c.owner AND t.table_name = c.table_name
		 WHERE t.owner = 'CT' AND (t.dropped = 'NO' OR t.dropped IS NULL) AND c.column_name = 'APP_SID'
           AND c.table_name NOT IN (
                SELECT object_name
        		  FROM all_policies 
        		 WHERE function IN ('APPSIDCHECK', 'NULLABLEAPPSIDCHECK')
        		   AND object_owner = 'CT'
           )
 	)
 	LOOP
		dbms_output.put_line('Writing policy '||r.policy_name);
		dbms_rls.add_policy(
			object_schema   => r.owner,
			object_name     => r.table_name,
			policy_name     => r.policy_name, 
			function_schema => r.owner,
			policy_function => (CASE WHEN r.nullable ='N' THEN 'appSidCheck' ELSE 'nullableAppSidCheck' END),
			statement_types => 'select, insert, update, delete',
			update_check	=> true,
			policy_type     => dbms_rls.static);
	END LOOP;
	
END;
/

-- base data was l per 100km !
UPDATE ct.ec_car_model
SET efficiency_ltr_per_km = efficiency_ltr_per_km/100;

-- redo ps_item view
CREATE OR REPLACE FORCE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, kg_co2,
	spend_in_company_currency, spend_in_dollars, company_currency_id
)
AS
SELECT
    app_sid, 
	company_sid, 
	supplier_id, 
	breakdown_id, 
	region_id, 
	item_id, 
	description,
	spend, 
	currency_id, 
	purchase_date, 
	created_by_sid, 
	created_dtm, 
	modified_by_sid,
	last_modified_dtm, 
	row_number, 
	worksheet_id,
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two,
	kg_co2,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date),2) spend_in_company_currency,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date), 2) spend_in_dollars,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ct.ps_item;
 
-- needed as passes back factors
CREATE OR REPLACE VIEW ct.v$ht_consumption (
    app_sid, company_sid, ht_consumption_type_id, ht_consumption_category_id, mass_unit_id, power_unit_id, volume_unit_id, amount, co2_factor
)
AS
SELECT hc.app_sid, hc.company_sid, hc.ht_consumption_type_id, hc.ht_consumption_category_id, hc.mass_unit_id, hc.power_unit_id, hc.volume_unit_id, hc.amount, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_mass_unit u 
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.mass_unit_id = u.mass_unit_id
UNION
SELECT hc.*, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_power_unit u
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.power_unit_id = u.power_unit_id 
UNION
SELECT hc.*, co2_factor
  FROM ht_consumption hc 
  JOIN ht_consumption_type_vol_unit u
    ON hc.ht_consumption_type_id = u.ht_consumption_type_id 
   AND hc.ht_consumption_category_id = u.ht_consumption_category_id 
   AND hc.volume_unit_id = u.volume_unit_id ;
   
-- PS emissions views
CREATE OR REPLACE VIEW ct.v$ps_emissions
(app_sid, breakdown_id, region_id, eio_id, calculation_source_id, kg_co2)
AS
	 SELECT 
			p.app_sid,               
			breakdown_id,          
			region_id,             
			eio_id,                
			calculation_source_id, 
			SUM(kg_co2) kg_co2
	  FROM ct.ps_emissions_all p
	  JOIN ct.ps_options o ON p.app_sid = o.app_sid
	 WHERE p.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)	
	 GROUP BY p.app_sid, breakdown_id, region_id, eio_id, calculation_source_id;
	
CREATE OR REPLACE VIEW ct.v$ps_level_contributions
(app_sid, calculation_source_id, contribution_source_id, kg_co2)
AS 
	SELECT
			p.app_sid,
			calculation_source_id,
			contribution_source_id,
			SUM(kg_co2) kg_co2
	  FROM ct.ps_emissions_all p
	  JOIN ct.ps_options o ON p.app_sid = o.app_sid
	 WHERE p.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)	
	 GROUP BY p.app_sid, calculation_source_id, contribution_source_id;

  -- EC emissions views
CREATE OR REPLACE VIEW ct.v$ec_emissions
(app_sid, breakdown_id, region_id, calculation_source_id, car_kg_co2, bus_kg_co2, train_kg_co2, motorbike_kg_co2, bike_kg_co2, walk_kg_co2)
AS
	SELECT 
		e.app_sid,               
		e.breakdown_id,          
		region_id,                          
		calculation_source_id, 
		SUM(car_kg_co2) car_kg_co2, 
		SUM(bus_kg_co2) bus_kg_co2, 
		SUM(train_kg_co2) train_kg_co2, 
		SUM(motorbike_kg_co2) motorbike_kg_co2, 
		SUM(bike_kg_co2) bike_kg_co2, 
		SUM(walk_kg_co2) walk_kg_co2
	FROM ct.ec_emissions_all e
	JOIN ct.ec_options o ON e.app_sid = o.app_sid
   WHERE e.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)
   GROUP BY e.app_sid, e.breakdown_id, region_id, calculation_source_id;
	
CREATE OR REPLACE VIEW ct.v$ec_level_contributions
(app_sid, calculation_source_id, contribution_source_id, car_kg_co2, bus_kg_co2, train_kg_co2, motorbike_kg_co2, bike_kg_co2, walk_kg_co2)
AS 
	SELECT
		e.app_sid,
		calculation_source_id,
		contribution_source_id,
		SUM(car_kg_co2) car_kg_co2, 
		SUM(bus_kg_co2) bus_kg_co2, 
		SUM(train_kg_co2) train_kg_co2, 
		SUM(motorbike_kg_co2) motorbike_kg_co2, 
		SUM(bike_kg_co2) bike_kg_co2, 
		SUM(walk_kg_co2) walk_kg_co2
	FROM ct.ec_emissions_all e
	JOIN ct.ec_options o ON e.app_sid = o.app_sid
   WHERE e.breakdown_id IN (SELECT breakdown_id FROM ct.breakdown b WHERE b.breakdown_type_id = o.breakdown_type_id)
   GROUP BY e.app_sid, calculation_source_id, contribution_source_id;

CREATE OR REPLACE FORCE VIEW ct.v$ps_item (
    app_sid, company_sid, supplier_id, breakdown_id, region_id, item_id, description,
	spend, currency_id, purchase_date, created_by_sid, created_dtm, modified_by_sid,
	last_modified_dtm, row_number, worksheet_id, 
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, match_auto_accepted, kg_co2,
	spend_in_company_currency, spend_in_dollars, company_currency_id
)
AS
SELECT
    app_sid, 
	company_sid, 
	supplier_id, 
	breakdown_id, 
	region_id, 
	item_id, 
	description,
	spend, 
	currency_id, 
	purchase_date, 
	created_by_sid, 
	created_dtm, 
	modified_by_sid,
	last_modified_dtm, 
	row_number, 
	worksheet_id,
	auto_eio_id, auto_eio_id_score, auto_eio_id_two, auto_eio_id_score_two, match_auto_accepted,
	kg_co2,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date) * util_pkg.GetConversionFromDollar(company_pkg.GetCompanyCurrency(), purchase_date),2) spend_in_company_currency,
	ROUND(spend * util_pkg.GetConversionToDollar(currency_id, purchase_date), 2) spend_in_dollars,
	company_pkg.GetCompanyCurrency() company_currency_id
 FROM ct.ps_item;
   
@../ct/ct_pkg
@../ct/admin_pkg
@../ct/admin_body
@../ct/breakdown_body
@../ct/hotspot_pkg
@../ct/hotspot_body
@../ct/company_pkg
@../ct/company_body
@../ct/consumption_pkg
@../ct/consumption_body

@../ct/hotspot_pkg
@../ct/hotspot_body
@../ct/emp_commute_pkg
@../ct/emp_commute_body
@../ct/business_travel_pkg
@../ct/business_travel_body
@../ct/products_services_pkg
@../ct/products_services_body

@../ct/value_chain_report_pkg
@../ct/value_chain_report_body



@update_tail
	