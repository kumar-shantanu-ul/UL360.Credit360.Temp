SET SERVEROUTPUT ON;

PROMPT > please enter host e.g. bs.credit360.com:
exec user_pkg.logonadmin('&&1'); 

SET DEFINE OFF;

BEGIN
	INSERT INTO SUPPLIER.questionnaire (questionnaire_id, class_name, friendly_name, description, package_name) values 
	(11	,'gtTransport',		'Transport',		'Transport',		'gt_transport_pkg');

EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN  
		null; -- just in case clean is run multiple times
END;
/
	
-- GT_TRANSPORT_TYPE
BEGIN
	INSERT INTO SUPPLIER.gt_transport_type (gt_transport_type_id, description, pos) VALUES (1 , 'Rail', 1);
	INSERT INTO SUPPLIER.gt_transport_type (gt_transport_type_id, description, pos) VALUES (2 , 'Road', 2);
	INSERT INTO SUPPLIER.gt_transport_type (gt_transport_type_id, description, pos) VALUES (3 , 'Sea', 3);
	INSERT INTO SUPPLIER.gt_transport_type (gt_transport_type_id, description, pos) VALUES (4 , 'Air', 4);
END;
/
-- gt_region
BEGIN
	INSERT INTO SUPPLIER.gt_region (gt_region_id, description, pos) VALUES (1 , 'BM Manufactured', 1);
	INSERT INTO SUPPLIER.gt_region (gt_region_id, description, pos) VALUES (2 , 'Delivery from UK Supplier', 2);
	INSERT INTO SUPPLIER.gt_region (gt_region_id, description, pos) VALUES (3 , 'European (BCMK / C)',3);
	INSERT INTO SUPPLIER.gt_region (gt_region_id, description, pos) VALUES (4 , 'Rest of World / Unknown',4);
END;
/
-- gt_trans_region_scoring
BEGIN
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (1 , 1, 1);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (1 , 2, 1);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (1 , 3, 1);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (1 , 4, 1);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (2 , 1, 2);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (2 , 2, 2);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (2 , 3, 2);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (2 , 4, 7);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (3 , 1, 3);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (3 , 2, 4);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (3 , 3, 3);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (3 , 4, 8);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (4 , 1, 4);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (4 , 2, 4);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (4 , 3, 4);
	INSERT INTO SUPPLIER.gt_trans_region_scoring (gt_region_id, gt_transport_type_id, gt_score) VALUES (4 , 4, 9);
END;
/

-- gt_country_region
BEGIN
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('AFR',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('ASI',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('ASL',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('CRB',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('EQG',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('EU',3);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('FE',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('GBI',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('MAD',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('ME',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('NA',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('OCN',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('ROG',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('SA',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) values ('USP',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AFG',4);
	
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AL',3);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GBA',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('DZ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ASAM',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AND',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AUS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('A',3);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BFPO',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BRN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BD',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BDS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BEL',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('B',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BH',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BM',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BOL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BOS',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RB',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BVI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BRU',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BG',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CAM',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CDN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CAR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CHD',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RCH',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('TJ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CO',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CON',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CB',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CR',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CRE',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CRO',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('C',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CY',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ZRE',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('DK',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('DOM',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EC',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ET',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ES',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ENG',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EST',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ETE',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('FI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('FJI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SF',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('F',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('FG',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GAB',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WAG',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('G',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GHA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GBZ',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GR',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WG',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GUA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GBG',3);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GU',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GUY',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('HO',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('HK',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('H',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IS',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IND',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IQ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IRL',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GBM',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('IL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('I',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('JA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('J',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('GBJ',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('HKJ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EAK',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('KWT',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('LAT',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('FL',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('LIT',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('L',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MAC',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MWI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MAL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('M',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MAU',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MEX',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MOL',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MC',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MON',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('MOC',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('BUR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SWA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NE',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NL',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NZ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NIC',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NIG',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WAN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NK',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('YWN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('NI',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('N',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('OMAN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PAK',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PNG',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PAR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PE',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RP',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PL',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('P',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('PR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('QTR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RSN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RO',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RS',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('AS',4);

	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SC',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SRB',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SYL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WAL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SGP',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SR',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SLO',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SI',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SOMA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ZA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SK',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ADN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SP',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('STH',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WL',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WY',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SUD',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SO',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SD',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SW',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('CH',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('SYR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('RC',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EAT',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('T',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('TT',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('TN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('TR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EAU',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UKR',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UAE',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UK',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('USA',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UR',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UZB',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('V',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('YV',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('VN',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('VI',4);
	--INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('WA',2);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('YU',3);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('Z',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('EAZ',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('ZW',4);
	INSERT INTO SUPPLIER.gt_country_region (country_code, gt_region_id) VALUES ('UN',4);

	
END;
/
commit;
exit;