-- Please update version.sql too -- this keeps clean builds in sync
define version=512
@update_header

/* TODO: alter precision on factors in ER/Studio etc */

delete from factor;
delete from std_factor;

UPDATE ind SET factor_type_id = NULL;
UPDATE ind SET gas_type_id = NULL;
UPDATE measure SET std_measure_conversion_id = NULL;
UPDATE region SET egrid_ref = NULL;
delete from gas_type;
delete from egrid;
delete from std_factor_set;
delete from factor_type;
delete from std_measure_conversion;
delete from std_measure;

Insert into gas_type (GAS_TYPE_ID,NAME) values (1,'CO2');
Insert into gas_type (GAS_TYPE_ID,NAME) values (2,'CO2e');
Insert into gas_type (GAS_TYPE_ID,NAME) values (3,'CH4');
Insert into gas_type (GAS_TYPE_ID,NAME) values (4,'N2O');

Insert into egrid (EGRID_REF,NAME) values ('AKGD','ASCC Alaska Grid');
Insert into egrid (EGRID_REF,NAME) values ('AKMS','ASCC Alaska Miscellaneous');
Insert into egrid (EGRID_REF,NAME) values ('CALI','WSCC California');
Insert into egrid (EGRID_REF,NAME) values ('ECMI','ECAR Michigan');
Insert into egrid (EGRID_REF,NAME) values ('ECOV','ECAR Ohio Valley');
Insert into egrid (EGRID_REF,NAME) values ('ERCT','ERCOT All');
Insert into egrid (EGRID_REF,NAME) values ('FRCC','FRCC All');
Insert into egrid (EGRID_REF,NAME) values ('HIMS','HICC Hawaii Miscellaneous');
Insert into egrid (EGRID_REF,NAME) values ('HIOA','HICC Oahu');
Insert into egrid (EGRID_REF,NAME) values ('MAAC','MAAC All');
Insert into egrid (EGRID_REF,NAME) values ('MANN','MAIN North');
Insert into egrid (EGRID_REF,NAME) values ('MANS','MAIN South');
Insert into egrid (EGRID_REF,NAME) values ('MAPP','MAPP All');
Insert into egrid (EGRID_REF,NAME) values ('NEWE','NPCC New England');
Insert into egrid (EGRID_REF,NAME) values ('NWGB','WSCC Great Basin');
Insert into egrid (EGRID_REF,NAME) values ('NWPN','WSCC Pacific Northwest');
Insert into egrid (EGRID_REF,NAME) values ('NYCW','NPCC NYC/Westchester');
Insert into egrid (EGRID_REF,NAME) values ('NYLI','NPCC Long Island');
Insert into egrid (EGRID_REF,NAME) values ('NYUP','NPCC Upstate New  York');
Insert into egrid (EGRID_REF,NAME) values ('ROCK','WSCC Rockies');
Insert into egrid (EGRID_REF,NAME) values ('SPNO','SPP North');
Insert into egrid (EGRID_REF,NAME) values ('SPSO','SPP South');
Insert into egrid (EGRID_REF,NAME) values ('SRMV','SERC Mississippi Valley');
Insert into egrid (EGRID_REF,NAME) values ('SRSO','SERC South');
Insert into egrid (EGRID_REF,NAME) values ('SRTV','SERC Tennessee Valley');
Insert into egrid (EGRID_REF,NAME) values ('SRVC','SERC Virginia/Carolina');
Insert into egrid (EGRID_REF,NAME) values ('WSSW','WSCC Southwest');

Insert into std_factor_set (STD_FACTOR_SET_ID,NAME) values (1,'DEFRA');
Insert into std_factor_set (STD_FACTOR_SET_ID,NAME) values (2,'eGrid');

Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (1,'1','constant',0,'#,##0','sum',null,0,0,0,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (2,'kg','kg',0,'#,##0','sum',null,0,0,1,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (3,'metre','metre',0,'#,##0','sum',null,0,1,0,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (4,'Joule','Joule',0,'#,##0','sum',null,0,2,1,-2,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (5,'m^3','m^3',0,'#,##0','sum',null,0,3,0,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (6,'m.kg','m.kg',0,'#,##0','sum',null,0,1,1,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (7,'£','£',0,'#,##0','sum',null,0,0,0,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (8,'kg/m^3','kg/m^3',0,'#,##0','sum',null,0,-3,1,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (9,'kg/J','kg/J',0,'#,##0','sum',null,0,-2,0,2,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (10,'kg/m','kg/m',0,'#,##0','sum',null,0,-1,1,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (11,'kg/£','kg/£',0,'#,##0','sum',null,0,0,1,0,0,0,0,0);
Insert into std_measure (STD_MEASURE_ID,NAME,DESCRIPTION,SCALE,FORMAT_MASK,REGIONAL_AGGREGATION,CUSTOM_FIELD,PCT_OWNERSHIP_APPLIES,M,KG,S,A,K,MOL,CD) values (12,'m^2','m^2',0,'#,##0','sum',null,0,2,0,0,0,0,0,0);

Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (1,1,'constant',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (2,1,'kg/t',1000,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (3,2,'kg',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (4,2,'t',0.001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (5,3,'m',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (6,3,'km',0.001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (7,3,'mile',0.000621371192,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (8,4,'kWh',0.00000027777777778,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (9,5,'m^3',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (10,5,'litre',1000,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (11,4,'therm (UK)',0.0000000094781712,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (12,3,'vkm',0.001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (13,6,'t.km',0.000001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (14,5,'1000000 litre',0.001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (15,7,'£',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (16,8,'kg/m^3',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (17,9,'kg/kWh',3600000,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (18,10,'kg/m',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (19,10,'kg/km',1000,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (20,10,'kg/mile',1609.344,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (21,11,'kg/£',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (22,2,'lb',2.20462262,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (23,5,'Imperial gallon',219.969157,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (24,5,'US gallon',264.172052,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (25,5,'cubic feet',35.3146667,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (26,5,'Ccf',0.353146667,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (27,12,'m^2',1,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (28,12,'ft^2',10.7639104,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (29,4,'MWh',0.0000000002777777777,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (30,4,'GJ',0.000000001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (31,4,'BTU',0.00094781712,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (32,4,'million BTU',0.00000000094781712,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (33,8,'kg/l',0.001,1,0);
Insert into std_measure_conversion (STD_MEASURE_CONVERSION_ID,STD_MEASURE_ID,DESCRIPTION,A,B,C) values (34,9,'kg/therm',105505585.257348,1,0);

@update_tail