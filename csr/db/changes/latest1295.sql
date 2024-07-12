-- Please update version.sql too -- this keeps clean builds in sync
define version=1295
@update_header

-- This is to fix differences between the change scripts and the create schema,
-- so they need to be conditional so that it works for both people that have just used latests
-- and people that have used the create_schema
declare
	v_nullable varchar2(1);
begin
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='CAR_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY CAR_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='BUS_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY BUS_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='TRAIN_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY TRAIN_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='MOTORBIKE_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY MOTORBIKE_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='BIKE_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY BIKE_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='WALK_PCT_USE';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY WALK_PCT_USE NUMBER(20,17) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='MOTORBIKE_AVG_DIST';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY MOTORBIKE_AVG_DIST NUMBER(20,10) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_PROFILE' and column_name='TRAIN_AVG_DIST';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_PROFILE MODIFY TRAIN_AVG_DIST NUMBER(20,10) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_CAR_ENTRY' and column_name='PCT';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_CAR_ENTRY MODIFY PCT NUMBER(3) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_TRAIN_ENTRY' and column_name='PCT';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_TRAIN_ENTRY MODIFY PCT NUMBER(3) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_MOTORBIKE_ENTRY' and column_name='PCT';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_MOTORBIKE_ENTRY MODIFY PCT NUMBER(3) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='EC_BUS_ENTRY' and column_name='PCT';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.EC_BUS_ENTRY MODIFY PCT NUMBER(3) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='CURRENCY_PERIOD' and column_name='PURCHSE_PWR_PARITY_FACT';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.CURRENCY_PERIOD MODIFY PURCHSE_PWR_PARITY_FACT NUMBER(30,20) NOT NULL';
	end if;
	
	select nullable
	  into v_nullable
	  from all_tab_columns
	 where owner='CT' and table_name='HOTSPOT_RESULT' and column_name='BUSINESS_TRAVEL_EMISSIONS';
	if v_nullable = 'Y' then
		execute immediate 'ALTER TABLE CT.HOTSPOT_RESULT MODIFY BUSINESS_TRAVEL_EMISSIONS NUMBER(30,10) NOT NULL';
	end if;
end;
/

declare
	v_exists number;
begin

	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_AIR_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP DROP CONSTRAINT BD_GROUP_BT_AIR_TRIP';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT PK_BT_AIR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT COMPANY_BT_AIR_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_AIR_TRIP ADD CONSTRAINT B_R_BT_AIR_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_BUS_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP DROP CONSTRAINT BD_GROUP_BT_BUS_TRIP';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT PK_BT_BUS_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT COMPANY_BT_BUS_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_BUS_TRIP ADD CONSTRAINT B_R_BT_BUS_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_CAB_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP DROP CONSTRAINT BD_GROUP_BT_CAB_TRIP';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT PK_BT_CAB_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT COMPANY_BT_CAB_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_CAB_TRIP ADD CONSTRAINT B_R_BT_CAB_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;
				
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_CAR_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP DROP CONSTRAINT BD_GROUP_BT_CAR_TRIP';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT PK_BT_CAR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT COMPANY_BT_CAR_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_CAR_TRIP ADD CONSTRAINT B_R_BT_CAR_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;
		
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_MOTORBIKE_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP DROP CONSTRAINT BD_GROUP_BT_MB_TRIP';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT PK_BT_MB_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT COMPANY_BT_MB_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_MOTORBIKE_TRIP ADD CONSTRAINT B_R_BT_MB_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;
	
	select count(*)
	  into v_exists
	  from all_tab_columns
	 where owner='CT' and table_name='BT_TRAIN_TRIP' and column_name='BREAKDOWN_GROUP_ID';
	if v_exists = 1 then
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP DROP PRIMARY KEY';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP DROP CONSTRAINT BD_GROUP_BT_TR_TRIP';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP DROP COLUMN BREAKDOWN_GROUP_ID';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD BREAKDOWN_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD REGION_ID NUMBER(10) NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD TRIP_ID NUMBER NOT NULL';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT PK_BT_TR_TRIP PRIMARY KEY (APP_SID, COMPANY_SID, BREAKDOWN_ID, REGION_ID, TRIP_ID)';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT COMPANY_BT_TR_TRIP FOREIGN KEY (APP_SID, COMPANY_SID) REFERENCES CT.COMPANY (APP_SID,COMPANY_SID)';
		execute immediate 'ALTER TABLE CT.BT_TRAIN_TRIP ADD CONSTRAINT B_R_BT_TR_TRIP FOREIGN KEY (APP_SID, BREAKDOWN_ID, REGION_ID) REFERENCES CT.BREAKDOWN_REGION (APP_SID,BREAKDOWN_ID,REGION_ID)';
	end if;	
	
end;
/
	

@..\ct\breakdown_body
@..\ct\breakdown_group_body
@..\ct\breakdown_type_body
	
@update_tail
