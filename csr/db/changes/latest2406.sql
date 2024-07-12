-- Please update version.sql too -- this keeps clean builds in sync
define version=2406
@update_header

declare 
	procedure create_factor(
		v_STD_FACTOR_ID				in	CSR.STD_FACTOR.STD_FACTOR_ID%TYPE,
		v_STD_FACTOR_SET_ID			in	CSR.STD_FACTOR.STD_FACTOR_SET_ID%TYPE,
		v_FACTOR_TYPE_ID			in	CSR.STD_FACTOR.FACTOR_TYPE_ID%TYPE,
		v_GAS_TYPE_ID				in	CSR.STD_FACTOR.GAS_TYPE_ID%TYPE,
		v_GEO_COUNTRY				in	CSR.STD_FACTOR.GEO_COUNTRY%TYPE,
		v_GEO_REGION				in	CSR.STD_FACTOR.GEO_REGION%TYPE,
		v_EGRID_REF					in	CSR.STD_FACTOR.EGRID_REF%TYPE,
		v_STD_MEASURE_CONVERSION_ID	in	CSR.STD_FACTOR.STD_MEASURE_CONVERSION_ID%TYPE,
		v_START_DTM					in	CSR.STD_FACTOR.START_DTM%TYPE,
		v_END_DTM					in	CSR.STD_FACTOR.END_DTM%TYPE,
		v_VALUE						in	CSR.STD_FACTOR.VALUE%TYPE,
		v_NOTE						in	CSR.STD_FACTOR.NOTE%TYPE)
	as
	begin
		insert into csr.std_factor (
				STD_FACTOR_ID,STD_FACTOR_SET_ID,FACTOR_TYPE_ID,GAS_TYPE_ID,GEO_COUNTRY,GEO_REGION,
				EGRID_REF,STD_MEASURE_CONVERSION_ID,START_DTM,END_DTM,VALUE,NOTE) 
			values (
				v_STD_FACTOR_ID,v_STD_FACTOR_SET_ID,v_FACTOR_TYPE_ID,v_GAS_TYPE_ID,v_GEO_COUNTRY,v_GEO_REGION,
				v_EGRID_REF,v_STD_MEASURE_CONVERSION_ID,v_START_DTM,v_END_DTM,v_VALUE,v_NOTE); 
	end;
begin
	create_factor(184371185,49,14038,3,null,null,null,37,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371186,49,14038,1,null,null,null,37,date'2014-01-01',null,0.14519,'DEFRA 2014 online tool');
	create_factor(184371187,49,14038,2,null,null,null,37,date'2014-01-01',null,0.14701,'DEFRA 2014 online tool');
	create_factor(184371188,49,14038,4,null,null,null,37,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371189,49,14024,3,null,null,null,37,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371190,49,14024,1,null,null,null,37,date'2014-01-01',null,0.28944,'DEFRA 2014 online tool');
	create_factor(184371191,49,14024,2,null,null,null,37,date'2014-01-01',null,0.29014,'DEFRA 2014 online tool');
	create_factor(184371192,49,14024,4,null,null,null,37,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371193,49,14029,3,null,null,null,37,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371194,49,14029,1,null,null,null,37,date'2014-01-01',null,0.20018,'DEFRA 2014 online tool');
	create_factor(184371195,49,14029,2,null,null,null,37,date'2014-01-01',null,0.20088,'DEFRA 2014 online tool');
	create_factor(184371196,49,14029,4,null,null,null,37,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371197,49,14036,3,null,null,null,37,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371198,49,14036,1,null,null,null,37,date'2014-01-01',null,0.15991,'DEFRA 2014 online tool');
	create_factor(184371199,49,14036,2,null,null,null,37,date'2014-01-01',null,0.16061,'DEFRA 2014 online tool');
	create_factor(184371200,49,14036,4,null,null,null,37,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371201,49,13998,3,null,null,null,19,date'2014-01-01',null,0.00012,'DEFRA 2014 online tool');
	create_factor(184371202,49,13998,1,null,null,null,19,date'2014-01-01',null,0.14274,'DEFRA 2014 online tool');
	create_factor(184371203,49,13998,2,null,null,null,19,date'2014-01-01',null,0.14356,'DEFRA 2014 online tool');
	create_factor(184371204,49,13998,4,null,null,null,19,date'2014-01-01',null,0.0007,'DEFRA 2014 online tool');
	create_factor(184371205,49,14001,3,null,null,null,19,date'2014-01-01',null,0.00011,'DEFRA 2014 online tool');
	create_factor(184371206,49,14001,1,null,null,null,19,date'2014-01-01',null,0.15904,'DEFRA 2014 online tool');
	create_factor(184371207,49,14001,2,null,null,null,19,date'2014-01-01',null,0.16006,'DEFRA 2014 online tool');
	create_factor(184371208,49,14001,4,null,null,null,19,date'2014-01-01',null,0.00091,'DEFRA 2014 online tool');
	create_factor(184371209,49,14004,3,null,null,null,19,date'2014-01-01',null,0.0001,'DEFRA 2014 online tool');
	create_factor(184371210,49,14004,1,null,null,null,19,date'2014-01-01',null,0.17481,'DEFRA 2014 online tool');
	create_factor(184371211,49,14004,2,null,null,null,19,date'2014-01-01',null,0.17591,'DEFRA 2014 online tool');
	create_factor(184371212,49,14004,4,null,null,null,19,date'2014-01-01',null,0.001,'DEFRA 2014 online tool');
	create_factor(184371213,49,14007,3,null,null,null,19,date'2014-01-01',null,0.0001,'DEFRA 2014 online tool');
	create_factor(184371214,49,14007,1,null,null,null,19,date'2014-01-01',null,0.1881,'DEFRA 2014 online tool');
	create_factor(184371215,49,14007,2,null,null,null,19,date'2014-01-01',null,0.18928,'DEFRA 2014 online tool');
	create_factor(184371216,49,14007,4,null,null,null,19,date'2014-01-01',null,0.00108,'DEFRA 2014 online tool');
	create_factor(184371217,49,14010,3,null,null,null,19,date'2014-01-01',null,0.00008,'DEFRA 2014 online tool');
	create_factor(184371218,49,14010,1,null,null,null,19,date'2014-01-01',null,0.21468,'DEFRA 2014 online tool');
	create_factor(184371219,49,14010,2,null,null,null,19,date'2014-01-01',null,0.2161,'DEFRA 2014 online tool');
	create_factor(184371220,49,14010,4,null,null,null,19,date'2014-01-01',null,0.00134,'DEFRA 2014 online tool');
	create_factor(184371221,49,14013,3,null,null,null,19,date'2014-01-01',null,0.00008,'DEFRA 2014 online tool');
	create_factor(184371222,49,14013,1,null,null,null,19,date'2014-01-01',null,0.29879,'DEFRA 2014 online tool');
	create_factor(184371223,49,14013,2,null,null,null,19,date'2014-01-01',null,0.30021,'DEFRA 2014 online tool');
	create_factor(184371224,49,14013,4,null,null,null,19,date'2014-01-01',null,0.00134,'DEFRA 2014 online tool');
	create_factor(184371225,49,13997,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371226,49,13997,1,null,null,null,19,date'2014-01-01',null,0.1433,'DEFRA 2014 online tool');
	create_factor(184371227,49,13997,2,null,null,null,19,date'2014-01-01',null,0.144,'DEFRA 2014 online tool');
	create_factor(184371228,49,13997,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371229,49,14000,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371230,49,14000,1,null,null,null,19,date'2014-01-01',null,0.16248,'DEFRA 2014 online tool');
	create_factor(184371231,49,14000,2,null,null,null,19,date'2014-01-01',null,0.16318,'DEFRA 2014 online tool');
	create_factor(184371232,49,14000,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371233,49,14003,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371234,49,14003,1,null,null,null,19,date'2014-01-01',null,0.19029,'DEFRA 2014 online tool');
	create_factor(184371235,49,14003,2,null,null,null,19,date'2014-01-01',null,0.19099,'DEFRA 2014 online tool');
	create_factor(184371236,49,14003,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371237,49,14006,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371238,49,14006,1,null,null,null,19,date'2014-01-01',null,0.21626,'DEFRA 2014 online tool');
	create_factor(184371239,49,14006,2,null,null,null,19,date'2014-01-01',null,0.21696,'DEFRA 2014 online tool');
	create_factor(184371240,49,14006,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371241,49,14009,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371242,49,14009,1,null,null,null,19,date'2014-01-01',null,0.24972,'DEFRA 2014 online tool');
	create_factor(184371243,49,14009,2,null,null,null,19,date'2014-01-01',null,0.25042,'DEFRA 2014 online tool');
	create_factor(184371244,49,14009,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371245,49,14012,3,null,null,null,19,date'2014-01-01',null,0.00014,'DEFRA 2014 online tool');
	create_factor(184371246,49,14012,1,null,null,null,19,date'2014-01-01',null,0.33906,'DEFRA 2014 online tool');
	create_factor(184371247,49,14012,2,null,null,null,19,date'2014-01-01',null,0.33976,'DEFRA 2014 online tool');
	create_factor(184371248,49,14012,4,null,null,null,19,date'2014-01-01',null,0.00056,'DEFRA 2014 online tool');
	create_factor(184371249,49,13996,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371250,49,13996,1,null,null,null,19,date'2014-01-01',null,0.10867,'DEFRA 2014 online tool');
	create_factor(184371251,49,13996,2,null,null,null,19,date'2014-01-01',null,0.11049,'DEFRA 2014 online tool');
	create_factor(184371252,49,13996,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371253,49,13999,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371254,49,13999,1,null,null,null,19,date'2014-01-01',null,0.13943,'DEFRA 2014 online tool');
	create_factor(184371255,49,13999,2,null,null,null,19,date'2014-01-01',null,0.14125,'DEFRA 2014 online tool');
	create_factor(184371256,49,13999,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371257,49,14002,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371258,49,14002,1,null,null,null,19,date'2014-01-01',null,0.15519,'DEFRA 2014 online tool');
	create_factor(184371259,49,14002,2,null,null,null,19,date'2014-01-01',null,0.15701,'DEFRA 2014 online tool');
	create_factor(184371260,49,14002,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371261,49,14005,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371262,49,14005,1,null,null,null,19,date'2014-01-01',null,0.1721,'DEFRA 2014 online tool');
	create_factor(184371263,49,14005,2,null,null,null,19,date'2014-01-01',null,0.17392,'DEFRA 2014 online tool');
	create_factor(184371264,49,14005,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371265,49,14008,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371266,49,14008,1,null,null,null,19,date'2014-01-01',null,0.19518,'DEFRA 2014 online tool');
	create_factor(184371267,49,14008,2,null,null,null,19,date'2014-01-01',null,0.197,'DEFRA 2014 online tool');
	create_factor(184371268,49,14008,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371269,49,14011,3,null,null,null,19,date'2014-01-01',null,0.00005,'DEFRA 2014 online tool');
	create_factor(184371270,49,14011,1,null,null,null,19,date'2014-01-01',null,0.23831,'DEFRA 2014 online tool');
	create_factor(184371271,49,14011,2,null,null,null,19,date'2014-01-01',null,0.24013,'DEFRA 2014 online tool');
	create_factor(184371272,49,14011,4,null,null,null,19,date'2014-01-01',null,0.00177,'DEFRA 2014 online tool');
	create_factor(184371273,49,14038,2,null,null,null,37,date'2013-01-01',date'2014-01-01',0.14048,'DEFRA 2014 online tool');
	create_factor(184371274,49,14038,1,null,null,null,37,date'2013-01-01',date'2014-01-01',0.13866,'DEFRA 2014 online tool');
	create_factor(184371275,49,14038,3,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371276,49,14038,4,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371277,49,14024,2,null,null,null,37,date'2013-01-01',date'2014-01-01',0.29678,'DEFRA 2014 online tool');
	create_factor(184371278,49,14024,1,null,null,null,37,date'2013-01-01',date'2014-01-01',0.29608,'DEFRA 2014 online tool');
	create_factor(184371279,49,14024,3,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371280,49,14024,4,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371281,49,14029,2,null,null,null,37,date'2013-01-01',date'2014-01-01',0.2049,'DEFRA 2014 online tool');
	create_factor(184371282,49,14029,1,null,null,null,37,date'2013-01-01',date'2014-01-01',0.2042,'DEFRA 2014 online tool');
	create_factor(184371283,49,14029,3,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371284,49,14029,4,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371285,49,14036,2,null,null,null,37,date'2013-01-01',date'2014-01-01',0.16192,'DEFRA 2014 online tool');
	create_factor(184371286,49,14036,1,null,null,null,37,date'2013-01-01',date'2014-01-01',0.16122,'DEFRA 2014 online tool');
	create_factor(184371287,49,14036,3,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371288,49,14036,4,null,null,null,37,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371289,49,13998,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.143,'DEFRA 2014 online tool');
	create_factor(184371290,49,13998,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.14218,'DEFRA 2014 online tool');
	create_factor(184371291,49,13998,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00013,'DEFRA 2014 online tool');
	create_factor(184371292,49,13998,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00069,'DEFRA 2014 online tool');
	create_factor(184371293,49,14001,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.15981,'DEFRA 2014 online tool');
	create_factor(184371294,49,14001,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.15882,'DEFRA 2014 online tool');
	create_factor(184371295,49,14001,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00011,'DEFRA 2014 online tool');
	create_factor(184371296,49,14001,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00088,'DEFRA 2014 online tool');
	create_factor(184371297,49,14004,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.17867,'DEFRA 2014 online tool');
	create_factor(184371298,49,14004,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.17759,'DEFRA 2014 online tool');
	create_factor(184371299,49,14004,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00011,'DEFRA 2014 online tool');
	create_factor(184371300,49,14004,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00097,'DEFRA 2014 online tool');
	create_factor(184371301,49,14007,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.19315,'DEFRA 2014 online tool');
	create_factor(184371302,49,14007,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.19199,'DEFRA 2014 online tool');
	create_factor(184371303,49,14007,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.0001,'DEFRA 2014 online tool');
	create_factor(184371304,49,14007,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00106,'DEFRA 2014 online tool');
	create_factor(184371305,49,14010,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.22158,'DEFRA 2014 online tool');
	create_factor(184371306,49,14010,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.2202,'DEFRA 2014 online tool');
	create_factor(184371307,49,14010,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00008,'DEFRA 2014 online tool');
	create_factor(184371308,49,14010,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.0013,'DEFRA 2014 online tool');
	create_factor(184371309,49,14013,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.30489,'DEFRA 2014 online tool');
	create_factor(184371310,49,14013,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.30351,'DEFRA 2014 online tool');
	create_factor(184371311,49,14013,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00008,'DEFRA 2014 online tool');
	create_factor(184371312,49,14013,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.0013,'DEFRA 2014 online tool');
	create_factor(184371313,49,13997,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.14357,'DEFRA 2014 online tool');
	create_factor(184371314,49,13997,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.14287,'DEFRA 2014 online tool');
	create_factor(184371315,49,13997,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371316,49,13997,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371317,49,14000,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.16341,'DEFRA 2014 online tool');
	create_factor(184371318,49,14000,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.16271,'DEFRA 2014 online tool');
	create_factor(184371319,49,14000,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371320,49,14000,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371321,49,14003,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.1948,'DEFRA 2014 online tool');
	create_factor(184371322,49,14003,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.1941,'DEFRA 2014 online tool');
	create_factor(184371323,49,14003,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371324,49,14003,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371325,49,14006,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.22486,'DEFRA 2014 online tool');
	create_factor(184371326,49,14006,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.22416,'DEFRA 2014 online tool');
	create_factor(184371327,49,14006,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371328,49,14006,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371329,49,14009,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.26075,'DEFRA 2014 online tool');
	create_factor(184371330,49,14009,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.26005,'DEFRA 2014 online tool');
	create_factor(184371331,49,14009,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371332,49,14009,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371333,49,14012,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.34564,'DEFRA 2014 online tool');
	create_factor(184371334,49,14012,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.34494,'DEFRA 2014 online tool');
	create_factor(184371335,49,14012,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371336,49,14012,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00056,'DEFRA 2014 online tool');
	create_factor(184371337,49,13996,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.10505,'DEFRA 2014 online tool');
	create_factor(184371338,49,13996,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.10323,'DEFRA 2014 online tool');
	create_factor(184371339,49,13996,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371340,49,13996,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371341,49,13999,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.13742,'DEFRA 2014 online tool');
	create_factor(184371342,49,13999,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.1356,'DEFRA 2014 online tool');
	create_factor(184371343,49,13999,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371344,49,13999,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371345,49,14002,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.15548,'DEFRA 2014 online tool');
	create_factor(184371346,49,14002,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.15366,'DEFRA 2014 online tool');
	create_factor(184371347,49,14002,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371348,49,14002,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371349,49,14005,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.17224,'DEFRA 2014 online tool');
	create_factor(184371350,49,14005,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.17042,'DEFRA 2014 online tool');
	create_factor(184371351,49,14005,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371352,49,14005,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371353,49,14008,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.19536,'DEFRA 2014 online tool');
	create_factor(184371354,49,14008,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.19354,'DEFRA 2014 online tool');
	create_factor(184371355,49,14008,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371356,49,14008,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371357,49,14011,2,null,null,null,19,date'2013-01-01',date'2014-01-01',0.23601,'DEFRA 2014 online tool');
	create_factor(184371358,49,14011,1,null,null,null,19,date'2013-01-01',date'2014-01-01',0.23419,'DEFRA 2014 online tool');
	create_factor(184371359,49,14011,3,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371360,49,14011,4,null,null,null,19,date'2013-01-01',date'2014-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371361,49,14038,3,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371362,49,14038,1,null,null,null,37,date'1990-01-01',date'2013-01-01',0.14115,'DEFRA 2014 online tool');
	create_factor(184371363,49,14038,2,null,null,null,37,date'1990-01-01',date'2013-01-01',0.14297,'DEFRA 2014 online tool');
	create_factor(184371364,49,14038,4,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371365,49,14024,3,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371366,49,14024,1,null,null,null,37,date'1990-01-01',date'2013-01-01',0.29714,'DEFRA 2014 online tool');
	create_factor(184371367,49,14024,2,null,null,null,37,date'1990-01-01',date'2013-01-01',0.29794,'DEFRA 2014 online tool');
	create_factor(184371368,49,14024,4,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371369,49,14029,3,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371370,49,14029,1,null,null,null,37,date'1990-01-01',date'2013-01-01',0.20685,'DEFRA 2014 online tool');
	create_factor(184371371,49,14029,2,null,null,null,37,date'1990-01-01',date'2013-01-01',0.20765,'DEFRA 2014 online tool');
	create_factor(184371372,49,14029,4,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371373,49,14036,3,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371374,49,14036,1,null,null,null,37,date'1990-01-01',date'2013-01-01',0.16442,'DEFRA 2014 online tool');
	create_factor(184371375,49,14036,2,null,null,null,37,date'1990-01-01',date'2013-01-01',0.16522,'DEFRA 2014 online tool');
	create_factor(184371376,49,14036,4,null,null,null,37,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371377,49,13998,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.14776,'DEFRA 2014 online tool');
	create_factor(184371378,49,13998,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.14685,'DEFRA 2014 online tool');
	create_factor(184371379,49,13998,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00014,'DEFRA 2014 online tool');
	create_factor(184371380,49,13998,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00077,'DEFRA 2014 online tool');
	create_factor(184371381,49,14001,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.16243,'DEFRA 2014 online tool');
	create_factor(184371382,49,14001,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.16136,'DEFRA 2014 online tool');
	create_factor(184371383,49,14001,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00013,'DEFRA 2014 online tool');
	create_factor(184371384,49,14001,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00094,'DEFRA 2014 online tool');
	create_factor(184371385,49,14004,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.1828,'DEFRA 2014 online tool');
	create_factor(184371386,49,14004,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.18167,'DEFRA 2014 online tool');
	create_factor(184371387,49,14004,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00012,'DEFRA 2014 online tool');
	create_factor(184371388,49,14004,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00101,'DEFRA 2014 online tool');
	create_factor(184371389,49,14007,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.19882,'DEFRA 2014 online tool');
	create_factor(184371390,49,14007,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.19763,'DEFRA 2014 online tool');
	create_factor(184371391,49,14007,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00011,'DEFRA 2014 online tool');
	create_factor(184371392,49,14007,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00108,'DEFRA 2014 online tool');
	create_factor(184371393,49,14010,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.23029,'DEFRA 2014 online tool');
	create_factor(184371394,49,14010,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.22889,'DEFRA 2014 online tool');
	create_factor(184371395,49,14010,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00009,'DEFRA 2014 online tool');
	create_factor(184371396,49,14010,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00131,'DEFRA 2014 online tool');
	create_factor(184371397,49,14013,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.31326,'DEFRA 2014 online tool');
	create_factor(184371398,49,14013,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.31186,'DEFRA 2014 online tool');
	create_factor(184371399,49,14013,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00009,'DEFRA 2014 online tool');
	create_factor(184371400,49,14013,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00131,'DEFRA 2014 online tool');
	create_factor(184371401,49,13997,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.14868,'DEFRA 2014 online tool');
	create_factor(184371402,49,13997,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.14788,'DEFRA 2014 online tool');
	create_factor(184371403,49,13997,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371404,49,13997,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371405,49,14000,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.16615,'DEFRA 2014 online tool');
	create_factor(184371406,49,14000,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.16535,'DEFRA 2014 online tool');
	create_factor(184371407,49,14000,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371408,49,14000,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371409,49,14003,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.19739,'DEFRA 2014 online tool');
	create_factor(184371410,49,14003,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.19659,'DEFRA 2014 online tool');
	create_factor(184371411,49,14003,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371412,49,14003,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371413,49,14006,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.2264,'DEFRA 2014 online tool');
	create_factor(184371414,49,14006,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.2256,'DEFRA 2014 online tool');
	create_factor(184371415,49,14006,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371416,49,14006,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371417,49,14009,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.26482,'DEFRA 2014 online tool');
	create_factor(184371418,49,14009,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.26402,'DEFRA 2014 online tool');
	create_factor(184371419,49,14009,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371420,49,14009,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371421,49,14012,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.35044,'DEFRA 2014 online tool');
	create_factor(184371422,49,14012,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.34964,'DEFRA 2014 online tool');
	create_factor(184371423,49,14012,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00015,'DEFRA 2014 online tool');
	create_factor(184371424,49,14012,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00065,'DEFRA 2014 online tool');
	create_factor(184371425,49,13996,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.1056,'DEFRA 2014 online tool');
	create_factor(184371426,49,13996,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.10378,'DEFRA 2014 online tool');
	create_factor(184371427,49,13996,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371428,49,13996,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371429,49,13999,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.14069,'DEFRA 2014 online tool');
	create_factor(184371430,49,13999,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.13887,'DEFRA 2014 online tool');
	create_factor(184371431,49,13999,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371432,49,13999,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371433,49,14002,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.15963,'DEFRA 2014 online tool');
	create_factor(184371434,49,14002,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.15781,'DEFRA 2014 online tool');
	create_factor(184371435,49,14002,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371436,49,14002,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371437,49,14005,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.1761,'DEFRA 2014 online tool');
	create_factor(184371438,49,14005,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.17428,'DEFRA 2014 online tool');
	create_factor(184371439,49,14005,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371440,49,14005,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371441,49,14008,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.20264,'DEFRA 2014 online tool');
	create_factor(184371442,49,14008,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.20082,'DEFRA 2014 online tool');
	create_factor(184371443,49,14008,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371444,49,14008,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');
	create_factor(184371445,49,14011,2,null,null,null,19,date'1990-01-01',date'2013-01-01',0.24122,'DEFRA 2014 online tool');
	create_factor(184371446,49,14011,1,null,null,null,19,date'1990-01-01',date'2013-01-01',0.2394,'DEFRA 2014 online tool');
	create_factor(184371447,49,14011,3,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00005,'DEFRA 2014 online tool');
	create_factor(184371448,49,14011,4,null,null,null,19,date'1990-01-01',date'2013-01-01',0.00177,'DEFRA 2014 online tool');

end;
/

@update_tail
