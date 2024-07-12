-- Please update version.sql too -- this keeps clean builds in sync
define version=1160
@update_header 

-- schema changes
ALTER TABLE CT.EC_CAR_MODEL
RENAME COLUMN EFFICIENCY_KM_LITRE TO EFFICIENCY_LTR_PER_KM;

DELETE FROM ct.EC_CAR_MODEL;

-- NEEDED TO DISTINGUISH CAR MODELS
ALTER TABLE CT.EC_CAR_MODEL
 ADD (FUEL_TYPE_ID  NUMBER(10) NOT NULL);
 
ALTER TABLE CT.EC_CAR_MODEL
 ADD (TRANSMISSION  VARCHAR2(40 BYTE));
 
 -- ADD FUEL TYPE TABLE
CREATE TABLE ct.EC_FUEL_TYPE (
    FUEL_TYPE_ID NUMBER(10) NOT NULL,
    DESCRIPTION VARCHAR2(100) NOT NULL,
    KG_CO2_PER_LITRE NUMBER(30,20) NOT NULL,
    CONSTRAINT PK_FUEL_TYPE PRIMARY KEY (FUEL_TYPE_ID)
);

ALTER TABLE ct.EC_FUEL_TYPE ADD CONSTRAINT CC_FUEL_TYPE_KG_CO2_PER_LITRE 
    CHECK (KG_CO2_PER_LITRE > 0);

ALTER TABLE ct.EC_CAR_MODEL ADD CONSTRAINT FUEL_TYPE_EC_CAR_MOD 
    FOREIGN KEY (FUEL_TYPE_ID) REFERENCES ct.EC_FUEL_TYPE (FUEL_TYPE_ID);
	
	
PROMPT COMMON
--------------------------------------
	PROMPT travel modes 
	BEGIN
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (1, 'Car');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (2, 'Bus');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (3, 'Train');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (4, 'Motorbike');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (5, 'Bike');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (6, 'Walk');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (7, 'Air');
	 END;
	/  

	PROMPT volumes 
	BEGIN
	   INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (1, 'Litre', 'l' ,1);
	   INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (2, 'US Gallon', 'Gallon (US)', 0.264172053);
	   INSERT INTO ct.volume_unit (volume_unit_id, description, symbol, conversion_to_litres) VALUES (3, 'Imperial gallon', 'Gallon (imp)', 0.219969157);
	END;
	/

PROMPT BUSINESS TRAVEL
-----------------------------------------------------------------------------
	PROMPT bt fuel
	BEGIN
	   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (1, 'Petrol');
	   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (2, 'Diesel');
	   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (3, 'PetrolDieselAverage');
	   INSERT INTO ct.bt_fuel (bt_fuel_id, description) VALUES (4, 'LPG');
	END;
	/
   
BEGIN
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (0,
'Rest of World (Estimated)',
NULL,
NULL);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (1,
'Andorra',
'ad',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (2,
'United Arab Emirates',
'ae',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (3,
'Antigua and Barbuda',
'ag',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (4,
'Albania',
'al',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (5,
'Armenia',
'am',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (6,
'Angola',
'ao',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (7,
'Antarctica',
'aq',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (8,
'American Samoa',
'as',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (9,
'Austria',
'at',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (10,
'Aruba',
'aw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (11,
'Aland Islands',
'ax',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (12,
'Bosnia and Herzegovina',
'ba',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (13,
'Barbados',
'bb',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (14,
'Belgium',
'be',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (15,
'Burkina Faso',
'bf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (16,
'Bahrain',
'bh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (17,
'Benin',
'bj',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (18,
'Brunei Darussalam',
'bn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (19,
'Bolivia',
'bo',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (20,
'Brazil',
'br',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (21,
'Bouvet Island',
'bv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (22,
'Belarus',
'by',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (23,
'Belize',
'bz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (24,
'Cocos (Keeling) Islands',
'cc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (25,
'Congo, The Democratic Republic of the',
'cd',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (26,
'Congo',
'cg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (27,
'Switzerland',
'ch',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (28,
'Cote d'||UNISTR('\0027')||'Ivoire',
'ci',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (29,
'Chile',
'cl',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (30,
'China',
'cn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (31,
'Costa Rica',
'cr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (32,
'Cuba',
'cu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (33,
'Christmas Island',
'cx',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (34,
'Cyprus',
'cy',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (35,
'Germany',
'de',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (36,
'Denmark',
'dk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (37,
'Dominica',
'dm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (38,
'Algeria',
'dz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (39,
'Estonia',
'ee',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (40,
'Egypt',
'eg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (41,
'Western Sahara',
'eh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (42,
'Spain',
'es',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (43,
'Europe',
'eu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (44,
'Finland',
'fi',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (45,
'Micronesia, Federated States of',
'fm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (46,
'Faroe Islands',
'fo',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (47,
'France',
'fr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (48,
'Gabon',
'ga',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (49,
'United Kingdom',
'gb',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (50,
'Grenada',
'gd',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (51,
'Guernsey',
'gg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (52,
'Ghana',
'gh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (53,
'Greenland',
'gl',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (54,
'Gambia',
'gm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (55,
'Guinea',
'gn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (56,
'Guadeloupe',
'gp',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (57,
'Greece',
'gr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (58,
'South Georgia and the South Sandwich Islands',
'gs',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (59,
'Guam',
'gu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (60,
'Guinea-Bissau',
'gw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (61,
'Guyana',
'gy',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (62,
'Heard Island and McDonald Islands',
'hm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (63,
'Honduras',
'hn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (64,
'Croatia',
'hr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (65,
'Hungary',
'hu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (66,
'Ireland',
'ie',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (67,
'Israel',
'il',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (68,
'Isle of Man',
'im',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (69,
'British Indian Ocean Territory',
'io',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (70,
'Iceland',
'is',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (71,
'Italy',
'it',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (72,
'Jersey',
'je',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (73,
'Jamaica',
'jm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (74,
'Japan',
'jp',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (75,
'Kenya',
'ke',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (76,
'Kyrgyzstan',
'kg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (77,
'Kiribati',
'ki',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (78,
'Saint Kitts and Nevis',
'kn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (79,
'Korea, Democratic People'||UNISTR('\0027')||'s Republic of',
'kp',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (80,
'Korea, Republic of',
'kr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (81,
'Kazakhstan',
'kz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (82,
'Lao People'||UNISTR('\0027')||'s Democratic Republic',
'la',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (83,
'Lebanon',
'lb',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (84,
'Liechtenstein',
'li',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (85,
'Liberia',
'lr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (86,
'Lesotho',
'ls',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (87,
'Lithuania',
'lt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (88,
'Luxembourg',
'lu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (89,
'Libyan Arab Jamahiriya',
'ly',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (90,
'Moldova, Republic of',
'md',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (91,
'Montenegro',
'me',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (92,
'Madagascar',
'mg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (93,
'Macedonia',
'mk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (94,
'Mali',
'ml',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (95,
'Mongolia',
'mn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (96,
'Macao',
'mo',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (97,
'Martinique',
'mq',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (98,
'Mauritania',
'mr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (99,
'Montserrat',
'ms',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (100,
'Malta',
'mt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (101,
'Mauritius',
'mu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (102,
'Malawi',
'mw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (103,
'Malaysia',
'my',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (104,
'Mozambique',
'mz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (105,
'Namibia',
'na',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (106,
'Niger',
'ne',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (107,
'Nigeria',
'ng',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (108,
'Nicaragua',
'ni',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (109,
'Netherlands',
'nl',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (110,
'Norway',
'no',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (111,
'Nepal',
'np',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (112,
'Nauru',
'nr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (113,
'Oman',
'om',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (114,
'Panama',
'pa',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (115,
'Peru',
'pe',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (116,
'French Polynesia',
'pf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (117,
'Papua New Guinea',
'pg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (118,
'Pakistan',
'pk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (119,
'Poland',
'pl',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (120,
'Pitcairn',
'pn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (121,
'Puerto Rico',
'pr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (122,
'Palestinian Territory',
'ps',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (123,
'Palau',
'pw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (124,
'Qatar',
'qa',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (125,
'Reunion',
're',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (126,
'Romania',
'ro',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (127,
'Rwanda',
'rw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (128,
'Saudi Arabia',
'sa',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (129,
'Solomon Islands',
'sb',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (130,
'Sudan',
'sd',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (131,
'Sweden',
'se',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (132,
'Singapore',
'sg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (133,
'Saint Helena',
'sh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (134,
'Svalbard and Jan Mayen',
'sj',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (135,
'Slovakia',
'sk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (136,
'San Marino',
'sm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (137,
'Senegal',
'sn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (138,
'Suriname',
'sr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (139,
'Sao Tome and Principe',
'st',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (140,
'El Salvador',
'sv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (141,
'Swaziland',
'sz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (142,
'Turks and Caicos Islands',
'tc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (143,
'French Southern Territories',
'tf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (144,
'Thailand',
'th',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (145,
'Tokelau',
'tk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (146,
'Turkmenistan',
'tm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (147,
'Tunisia',
'tn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (148,
'Tonga',
'to',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (149,
'Turkey',
'tr',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (150,
'Tuvalu',
'tv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (151,
'Taiwan',
'tw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (152,
'Ukraine',
'ua',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (153,
'Uganda',
'ug',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (154,
'United States Minor Outlying Islands',
'um',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (155,
'United States',
'us',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (156,
'Uruguay',
'uy',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (157,
'Uzbekistan',
'uz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (158,
'Saint Vincent and the Grenadines',
'vc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (159,
'Venezuela',
've',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (160,
'Virgin Islands, British',
'vg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (161,
'Vanuatu',
'vu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (162,
'Wallis and Futuna',
'wf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (163,
'Yemen',
'ye',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (164,
'South Africa',
'za',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (165,
'Zimbabwe',
'zw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (166,
'Virgin Islands, U.S.',
'vi',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (167,
'Afghanistan',
'af',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (168,
'Anguilla',
'ai',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (169,
'Netherlands Antilles',
'an',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (170,
'Argentina',
'ar',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (171,
'Australia',
'au',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (172,
'Azerbaijan',
'az',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (173,
'Bangladesh',
'bd',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (174,
'Bulgaria',
'bg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (175,
'Burundi',
'bi',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (176,
'Bermuda',
'bm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (177,
'Bahamas',
'bs',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (178,
'Bhutan',
'bt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (179,
'Botswana',
'bw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (180,
'Canada',
'ca',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (181,
'Central African Republic',
'cf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (182,
'Cook Islands',
'ck',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (183,
'Cameroon',
'cm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (184,
'Colombia',
'co',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (185,
'Cape Verde',
'cv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (186,
'Czech Republic',
'cz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (187,
'Djibouti',
'dj',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (188,
'Dominican Republic',
'do',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (189,
'Ecuador',
'ec',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (190,
'Eritrea',
'er',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (191,
'Ethiopia',
'et',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (192,
'Fiji',
'fj',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (193,
'Falkland Islands (Malvinas)',
'fk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (194,
'Georgia',
'ge',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (195,
'French Guiana',
'gf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (196,
'Gibraltar',
'gi',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (197,
'Equatorial Guinea',
'gq',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (198,
'Guatemala',
'gt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (199,
'Hong Kong',
'hk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (200,
'Haiti',
'ht',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (201,
'Indonesia',
'id',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (202,
'India',
'in',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (203,
'Iraq',
'iq',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (204,
'Iran, Islamic Republic of',
'ir',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (205,
'Jordan',
'jo',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (206,
'Cambodia',
'kh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (207,
'Comoros',
'km',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (208,
'Kuwait',
'kw',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (209,
'Cayman Islands',
'ky',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (210,
'Saint Lucia',
'lc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (211,
'Sri Lanka',
'lk',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (212,
'Latvia',
'lv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (213,
'Morocco',
'ma',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (214,
'Monaco',
'mc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (215,
'Marshall Islands',
'mh',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (216,
'Myanmar',
'mm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (217,
'Northern Mariana Islands',
'mp',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (218,
'Maldives',
'mv',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (219,
'Mexico',
'mx',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (220,
'New Caledonia',
'nc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (221,
'Norfolk Island',
'nf',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (222,
'Niue',
'nu',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (223,
'New Zealand',
'nz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (224,
'Philippines',
'ph',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (225,
'Saint Pierre and Miquelon',
'pm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (226,
'Portugal',
'pt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (227,
'Paraguay',
'py',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (228,
'Serbia',
'rs',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (229,
'Russian Federation',
'ru',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (230,
'Seychelles',
'sc',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (231,
'Slovenia',
'si',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (232,
'Sierra Leone',
'sl',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (233,
'Somalia',
'so',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (234,
'Syrian Arab Republic',
'sy',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (235,
'Chad',
'td',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (236,
'Togo',
'tg',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (237,
'Tajikistan',
'tj',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (238,
'Trinidad and Tobago',
'tt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (239,
'Tanzania, United Republic of',
'tz',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (240,
'Holy See (Vatican City State)',
'va',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (241,
'Vietnam',
'vn',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (242,
'Samoa',
'ws',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (243,
'Mayotte',
'yt',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (244,
'Zambia',
'zm',
0);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (245,
'United Kingdom - North East',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (246,
'United Kingdom - North West',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (247,
'United Kingdom - Yorkshire and the Humber',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (248,
'United Kingdom - East Midlands',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (249,
'United Kingdom - East of England',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (250,
'United Kingdom - London',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (251,
'United Kingdom - South East',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (252,
'United Kingdom - South West',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (253,
'United Kingdom - England',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (254,
'United Kingdom - Wales',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (255,
'United Kingdom - Scotland',
NULL,
49);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (256,
'Australia - NSW',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (257,
'Australia - VIC',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (258,
'Australia - QLD',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (259,
'Australia - SA',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (260,
'Australia - WA',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (261,
'Australia - TAS',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (262,
'Australia - ACT',
NULL,
171);
INSERT INTO "CT"."REGION" (
REGION_ID, DESCRIPTION, COUNTRY, PARENT_ID) VALUES (263,
'Australia - NT',
NULL,
171);
EXCEPTION
WHEN DUP_VAL_ON_INDEX THEN NULL;
END;
/
   
	PROMPT bt update the region factors
	BEGIN
		DELETE FROM ct.BT_REGION_FACTORS;
		INSERT INTO ct.BT_REGION_FACTORS
		(
			region_id,
			temp_emission_factor,
			car_pct,
			car_avg_dist_km,
			car_avg_speed_km,
			car_occupancy_rate,
			bus_pct,
			bus_avg_dist_km,
			bus_avg_speed_km,
			train_pct,
			train_avg_dist_km,
			train_avg_speed_km,
			motorbike_pct,
			motorbike_avg_dist_km,
			motorbike_avg_speed_km,
			bike_pct,
			bike_avg_dist_km,
			bike_avg_speed_km,
			walk_pct,
			walk_avg_dist_km,
			walk_avg_speed_km,
			air_pct,
			air_avg_dist_km,
			air_avg_speed_km,
			air_radiative_forcing,
			avg_num_trips_yr
		) VALUES (
			0, 
			920.70, 
			-- car
			66.2119654884092, 30.6184431804587, 45.9055138217822, 1.2,
			-- bus
			4.30157858315628, 7.79820075759278, 20.8045066666667,
			-- train
			4.57077732695799, 79.1498071748709, 68.2396342857143,
			-- motorbike
			0, 0, 47.6376446732673,
			-- bike
			1.72934848388814, 7.04824721941331, 18.00,
			-- walk
			7.18633011758843, 1.84620349211769, 5,
			--air
			16.000, 1313.22, 855.427456, 1.9,
			-- av num business trips
			30	
		);
	END;
	/
	
BEGIN
	BEGIN
	   -- travel modes - COMMON
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (1, 'Car');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (2, 'Bus');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (3, 'Train');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (4, 'Motorbike');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (5, 'Bike');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (6, 'Walk');
	   INSERT INTO ct.travel_mode (travel_mode_id, description) VALUES (7, 'Air');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

	PROMPT bt travel modes 
	BEGIN
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'UK domestic air travel - average',7,0.20124,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - economy class',7,0.10946,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - business class',7,0.16419,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Short haul air travel - average',7,0.11486,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - economy class',7,0.09594,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - premium economy class',7,0.15351,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel- Business class',7,0.27823,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - First class',7,0.38378,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Long haul air travel - average',7,0.13143,4.74076423022039);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average air travel',7,0.13,3.56964);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small petrol car',1,0.1983,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol car',1,0.24927,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol car',1,0.35773,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol car',1,0.24234,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small diesel car',1,0.17137,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium diesel car',1,0.21291,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large diesel car',1,0.28267,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average diesel car',1,0.22428,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small car - unknown fuel',1,0.17,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium car - unknown fuel',1,0.2,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large car - unknown fuel',1,0.27,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average car - unknown fuel',1,0.2,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol hybrid car',1,0.13984,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol hybrid car',1,0.2481,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol hybrid car',1,0.1617,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium LPG car',1,0.21373,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large LPG car',1,0.30626,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average LPG car',1,0.24142,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium CNG car',1,0.19636,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large CNG car',1,0.28116,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average CNG car',1,0.22173,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Regular taxi',1,0.233268571428571,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'London cab',1,0.28267,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class I)',1,0.23963,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class II)',1,0.25521,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Petrol van (Class III)',1,0.31079,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol van ',1,0.25646,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class I)',1,0.18579,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class II)',1,0.27402,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Diesel van (Class III)',1,0.32302,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average diesel van ',1,0.30193,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average LPG van ',1,0.29599,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average CNG van ',1,0.27602,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average van - unknown fuel',1,0.25,3.17107975265578);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'London local bus',2,0.10005,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average local bus',2,0.13552,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Coach ',2,0.03471,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Small petrol motorbike',4,0.10482,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Medium petrol motorbike',4,0.12717,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Large petrol motorbike',4,0.16742,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Average petrol motorbike',4,0.14238,6.42143649912795);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'International rail ',3,0.01715,1.74409386396068);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Domestic rail',3,0.06715,1.74409386396068);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Light rail and tram ',3,0.07659,1.74409386396068);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Metro',3,0.08154,1.74409386396068);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Bicycle',5,0,0);
		INSERT INTO ct.bt_travel_mode (bt_travel_mode_id, description, travel_mode_id, ef_per_km, eio_kg_co2_per_gbp) VALUES (ct.bt_travel_mode_id_seq.nextval,'Walk',6,0,0);
	END;
	/	
	
	PROMPT bt data sources 
	DECLARE
		v_id    NUMBER;
	BEGIN

	   
	   -- average travel pattern
	   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'avg_business_travel_region_0', 'Average business travel patterns (sources {0}, {1})') RETURNING data_source_id INTO v_id;
	   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, '1', 'http://www.dft.gov.uk/statistics/series/national-travel-survey/');
	   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 1, '2', 'http://assets.dft.gov.uk/statistics/series/national-travel-survey/commuting.xls');
	   
	   -- travel per person 
	   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'avg_num_business_trips_region_0', 'Average number of business trips per year per person ({0})') RETURNING data_source_id INTO v_id;
	   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://assets.dft.gov.uk/statistics/series/national-travel-survey/commuting.pdf');

		-- radiative forcing 
	   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'radiative_forcing_region_0', 'Radiative forcing factor ({0})') RETURNING data_source_id INTO v_id;
	   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://www.epa.gov/climateleaders/documents/resources/commute_travel_product.pdf');

	   -- car occupancy
	   INSERT INTO ct.data_source (data_source_id, key, source_description) VALUES (ct.data_source_id_seq.nextval, 'car_occupancy_rate_region_0', 'Car occupancy rate ({0})') RETURNING data_source_id INTO v_id;
	   INSERT INTO ct.data_source_url (data_source_id, url_pos_id, text, url) VALUES(v_id, 0, 'source', 'http://www.defra.gov.uk/publications/files/pb13773-ghg-conversion-factors-2012.pdf');

	END;
	/

PROMPT EMPLOYEE COMMUTING
------------------------------------------------------------------------------
	
	
	PROMPT EC fuel type
	BEGIN
		INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (1,'Petrol', 2.72309600614439);
		INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (2, 'Diesel', 3.17561631336406);
		INSERT INTO ct.EC_FUEL_TYPE (FUEL_TYPE_ID, DESCRIPTION, KG_CO2_PER_LITRE) VALUES (3, 'Biodiesel', 0.5);
		
		DELETE FROM ct.ec_car_type;
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small petrol car',0.1983);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol car',0.24927);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol car',0.35773);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol car',0.24234,1);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small diesel car',0.17137);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium diesel car',0.21291);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large diesel car',0.28267);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average diesel car',0.22428);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol hybrid car',0.13984);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol hybrid car',0.2481);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol hybrid car',0.1617);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium LPG car',0.21373);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large LPG car',0.30626);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average LPG car',0.24142);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium CNG car',0.19636);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large CNG car',0.28116);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average CNG car',0.22173);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class I)',0.23963);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class II)',0.25521);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Petrol van (Class III)',0.31079);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class I)',0.18579);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class II)',0.27402);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Diesel van (Class III)',0.32302);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average diesel van ',0.30193);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average LPG van ',0.29599);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average CNG van ',0.27602);
		INSERT INTO ct.ec_car_type (car_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol van ',0.25646);

		DELETE FROM ct.ec_bus_type;
		INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'London local bus',0.10005);
		INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average local bus',0.13552,1);
		INSERT INTO ct.ec_bus_type (bus_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Coach ',0.03471);

		DELETE FROM ct.ec_motorbike_type;
		INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Small petrol motorbike',0.10482);
		INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Medium petrol motorbike',0.12717);
		INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Large petrol motorbike',0.16742);
		INSERT INTO ct.ec_motorbike_type(motorbike_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Average petrol motorbike',0.14238, 1);

		DELETE FROM ct.ec_train_type;
		INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution, is_default) VALUES (ct.ec_transport_id_seq.nextval,'Domestic rail',0.06715, 1);
		INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'International rail ',0.01715);
		INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Light rail and tram ',0.07659);
		INSERT INTO ct.ec_train_type (train_type_id, description, kg_co2_per_km_contribution) VALUES (ct.ec_transport_id_seq.nextval,'Metro',0.08154);
	END;
	/
		
	PROMPT car manufacturer 
	BEGIN
		DELETE FROM ct.ec_car_manufacturer;
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer, is_dont_know) VALUES (ct.ec_manufacturer_id_seq.nextval,'DON''T KNOW', 1);
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ABARTH');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ALFA ROMEO');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ASTON MARTIN LAGONDA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'AUDI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'BENTLEY MOTORS');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'BMW');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CHEVROLET');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CHRYSLER JEEP');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'CITROEN');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FERRARI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FIAT');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'FORD');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'HONDA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'HYUNDAI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'INFINITI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'JAGUAR CARS');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'KIA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LAMBORGHINI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LAND ROVER');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LEXUS');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LOTUS');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'LTI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MASERATI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MAZDA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MERCEDES-BENZ');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MG MOTORS UK');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MINI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MITSUBISHI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'MORGAN MOTOR COMPANY');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'NISSAN');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PERODUA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PEUGEOT');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PORSCHE');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'PROTON');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'RENAULT');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'ROLLS-ROYCE');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SAAB');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SEAT');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SKODA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SMART');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SSANGYONG');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SUBARU');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'SUZUKI');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'TOYOTA');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VAUXHALL');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLKSWAGEN');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLKSWAGEN C.V.');
		INSERT INTO ct.ec_car_manufacturer (manufacturer_id, manufacturer) VALUES (ct.ec_manufacturer_id_seq.nextval,'VOLVO');
	END;
	/

CREATE OR REPLACE FUNCTION ct.GetRegionIdFromName (
    in_description                   IN ct.region.description%TYPE
) RETURN ct.region.region_id%TYPE
AS
	v_region_id		ct.region.region_id%TYPE;
BEGIN
	SELECT region_id INTO v_region_id FROM ct.region WHERE LOWER(description) = LOWER(in_description); 
	RETURN v_region_id;
END;
/

PROMPT Ec regions 
BEGIN
	DELETE FROM ct.ec_region_factors;
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United States'),22,0.894*100,0.025*100,0.025*100,0.015*100,0.015*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom'),29,0.7*100,0.08*100,0.08*100,0.01*100,0.03*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - North East'),29,0.74*100,0.1*100,0.02*100,0*100,0.02*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - North West'),29,0.77*100,0.06*100,0.03*100,0*100,0.02*100,0.1*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Yorkshire and the Humber'),29,0.73*100,0.08*100,0.02*100,0.01*100,0.03*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - East Midlands'),29,0.77*100,0.06*100,0.01*100,0.01*100,0.03*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - East of England'),29,0.73*100,0.03*100,0.09*100,0.01*100,0.04*100,0.09*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - London'),29,0.37*100,0.15*100,0.33*100,0.01*100,0.04*100,0.09*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - South East'),29,0.74*100,0.03*100,0.07*100,0.01*100,0.04*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - South West'),29,0.77*100,0.03*100,0.02*100,0.01*100,0.04*100,0.13*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - England'),29,0.7*100,0.07*100,0.08*100,0.01*100,0.03*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Wales'),29,0.89*100,0.05*100,0.02*100,0*100,0.02*100,0.11*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('United Kingdom - Scotland'),29,0.72*100,0.11*100,0.04*100,0*100,0.01*100,0.12*100,15.13379,8.25954,37.70134,15.13379,5.29366,1.471501);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia'),30,0.81*100,0.06*100,0.07*100,0.09*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - NSW'),30,0.76*100,0.07*100,0.1*100,0*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - VIC'),30,0.84*100,0.04*100,0.07*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - QLD'),30,0.85*100,0.05*100,0.04*100,0*100,0.03*100,0.03*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - SA'),30,0.88*100,0.05*100,0.02*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - WA'),30,0.87*100,0.06*100,0.02*100,0*100,0.025*100,0.025*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - TAS'),30,0.88*100,0.04*100,0*100,0*100,0.04*100,0.04*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - ACT'),30,0.87*100,0.06*100,0*100,0*100,0.035*100,0.035*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (ct.GetRegionIdFromName('Australia - NT'),30,0.76*100,0.06*100,0*100,0*100,0.09*100,0.09*100,20.7605,16.3831,38.6,20.7605,10,1.57715);
	INSERT INTO ct.ec_region_factors (region_id,holidays,car_avg_pct_use,bus_avg_pct_use,train_avg_pct_use,motorbike_avg_pct_use,bike_avg_pct_use,walk_avg_pct_use,car_avg_journey_km,bus_avg_journey_km, train_avg_journey_km,motorbike_avg_journey_km ,bike_avg_journey_km,walk_avg_journey_km) VALUES (0,15,0.774727272727273*100,0.0620454545454546*100,0.0525*100,0.00840909090909091*100,0.0315909090909091*100,0.0754545454545455*100,17.6913854545455,11.9520672727273,38.1098218181818,17.6913854545455,7.43290545454546,1.51952327272727);

END;
/

DROP FUNCTION ct.GetRegionIdFromName;

@..\ct\admin_pkg
@..\ct\admin_body
	
@update_tail
