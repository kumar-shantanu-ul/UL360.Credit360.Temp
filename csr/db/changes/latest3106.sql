-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

begin
	for r in (select username from all_users where username='GEMIMA') loop
		execute immediate 'drop user gemima cascade';
	end loop;
	for r in (select * from all_objects where (owner, object_name) in (
		('CSR', 'CUSTOMER_AIU'),
		('CSR', 'XX_T'),
		('CSR', 'XX_FIXLAYOUTXMLCELL'),
		('CHAIN', 'TMP_UPGRADE'),
		('ACTIONS', 'FT$I$4097'),
		('ACTIONS', 'FT$U$4097'),
		('ACTIONS', 'FT$D$4097'),
		('ASPEN2', 'EDIT_PKG'),
		('CSR', 'WHISTLER_PKG'),
		('MAERSK', 'FB_32429_PKG'))
		and object_type != 'PACKAGE BODY'
	) loop
		execute immediate 'drop ' ||r.object_type||' "'||r.owner||'"."'||r.object_name||'"';
	end loop;
end;
/

begin
	for r in (select owner,table_name from all_tables where table_name like 'M$%') loop
		execute immediate 'drop table "'||r.owner||'"."'||r.table_name||'"';
	end loop;
	for r in (select owner,object_name from all_objects where object_name = 'M$IMP_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package "'||r.owner||'"."'||r.object_name||'"';
	end loop;
end;
/


drop table csrimp.CT_BREAKDOWN;
drop table csrimp.CT_BREAKDOWN_GROUP;
drop table csrimp.CT_BREAKDOWN_REGION;
drop table csrimp.CT_BREAKDOWN_REGION_EIO;
drop table csrimp.CT_BREAKDOWN_TYPE;
drop table csrimp.CT_BREAKDOW_REGION_GROUP;
drop table csrimp.CT_BT_AIR_TRIP;
drop table csrimp.CT_BT_BUS_TRIP;
drop table csrimp.CT_BT_CAB_TRIP;
drop table csrimp.CT_BT_CAR_TRIP;
drop table csrimp.CT_BT_EMISSIONS;
drop table csrimp.CT_BT_MOTORBIKE_TRIP;
drop table csrimp.CT_BT_OPTIONS;
drop table csrimp.CT_BT_PROFILE;
drop table csrimp.CT_BT_TRAIN_TRIP;
drop table csrimp.CT_COMPANY;
drop table csrimp.CT_COMPANY_CONSUMPT_TYPE;
drop table csrimp.CT_CUSTOMER_OPTIONS;
drop table csrimp.CT_EC_BUS_ENTRY;
drop table csrimp.CT_EC_CAR_ENTRY;
drop table csrimp.CT_EC_EMISSIONS_ALL;
drop table csrimp.CT_EC_MOTORBIKE_ENTRY;
drop table csrimp.CT_EC_OPTIONS;
drop table csrimp.CT_EC_PROFILE;
drop table csrimp.CT_EC_QUESTIONNAIRE;
drop table csrimp.CT_EC_QUESTIONNA_ANSWERS;
drop table csrimp.CT_EC_TRAIN_ENTRY;
drop table csrimp.CT_HOTSPOT_RESULT;
drop table csrimp.CT_HT_CONSUMPTION;
drop table csrimp.CT_HT_CONSUMPTION_REGION;
drop table csrimp.CT_HT_CONS_SOURCE_BREAKD;
drop table csrimp.CT_PS_EMISSIONS_ALL;
drop table csrimp.CT_PS_ITEM;
drop table csrimp.CT_PS_ITEM_EIO;
drop table csrimp.CT_PS_OPTIONS;
drop table csrimp.CT_PS_SPEND_BREAKDOWN;
drop table csrimp.CT_PS_SUPPLIER_EIO_FREQ;
drop table csrimp.CT_SUPPLIER;
drop table csrimp.CT_SUPPLIER_CONTACT;
drop table csrimp.CT_UP_OPTIONS;
drop table csrimp.CT_WORKS_VALUE_MAP_BREAK;
drop table csrimp.CT_WORKS_VALUE_MAP_CURRE;
drop table csrimp.CT_WORKS_VALUE_MAP_DISTA;
drop table csrimp.CT_WORKS_VALUE_MAP_REGIO;
drop table csrimp.CT_WORKS_VALUE_MAP_SUPPL;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../schema_pkg
@../schema_body
@../csrimp/imp_pkg
@../csrimp/imp_body

@update_tail
