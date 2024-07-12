-- Please update version.sql too -- this keeps clean builds in sync
define version=3496
define minor_version=8
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

-- postcode\CountryToSqlMapper\Output\postcode_country.sql
DECLARE
PROCEDURE MergeCountry(
	in_country_code	postcode.country.country%TYPE,
	in_country_name	postcode.country.name%TYPE,
	in_iso3			postcode.country.iso3%TYPE
) AS
BEGIN
	DBMS_OUTPUT.PUT_LINE('Processing country: ' || in_country_code || ', ' || in_country_name || ', ' || in_iso3);

	MERGE INTO postcode.country dest
	USING (
		SELECT  in_country_code AS country_code,
				in_country_name AS country_name,
				in_iso3 AS iso3
		  FROM DUAL
		  ) src
	ON (LOWER(TRIM(dest.country)) = LOWER(src.country_code))
	WHEN MATCHED THEN
		UPDATE SET dest.name = src.country_name, dest.iso3 = src.iso3
	WHEN NOT MATCHED THEN
		INSERT (country, name, iso3)
		VALUES (src.country_code, src.country_name, src.iso3);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			DBMS_OUTPUT.PUT_LINE('Error: Country Name "' || in_country_name || '" already exists.');
END;

BEGIN
	MergeCountry('ac','Ascension Island','ASC');
	MergeCountry('ad','Andorra','AND');
	MergeCountry('ae','United Arab Emirates (the)','ARE');
	MergeCountry('af','Afghanistan','AFG');
	MergeCountry('ag','Antigua and Barbuda','ATG');
	MergeCountry('ai','Anguilla','AIA');
	MergeCountry('ai','French Afars and Issas','AFI');
	MergeCountry('al','Albania','ALB');
	MergeCountry('am','Armenia','ARM');
	MergeCountry('an','Netherlands Antilles','ANT');
	MergeCountry('ao','Angola','AGO');
	MergeCountry('aq','Antarctica','ATA');
	MergeCountry('ar','Argentina','ARG');
	MergeCountry('as','American Samoa','ASM');
	MergeCountry('at','Austria','AUT');
	MergeCountry('au','Australia','AUS');
	MergeCountry('aw','Aruba','ABW');
	MergeCountry('ax',N'Åland Islands','ALA');
	MergeCountry('az','Azerbaijan','AZE');
	MergeCountry('ba','Bosnia and Herzegovina','BIH');
	MergeCountry('bb','Barbados','BRB');
	MergeCountry('bd','Bangladesh','BGD');
	MergeCountry('be','Belgium','BEL');
	MergeCountry('bf','Burkina Faso','BFA');
	MergeCountry('bg','Bulgaria','BGR');
	MergeCountry('bh','Bahrain','BHR');
	MergeCountry('bi','Burundi','BDI');
	MergeCountry('bj','Benin','BEN');
	MergeCountry('bl',N'Saint Barthélemy','BLM');
	MergeCountry('bm','Bermuda','BMU');
	MergeCountry('bn','Brunei Darussalam','BRN');
	MergeCountry('bo','Bolivia (Plurinational State of)','BOL');
	MergeCountry('bq','British Antarctic Territory','ATB');
	MergeCountry('bq','Bonaire, Sint Eustatius and Saba','BES');
	MergeCountry('br','Brazil','BRA');
	MergeCountry('bs','Bahamas (the)','BHS');
	MergeCountry('bt','Bhutan','BTN');
	MergeCountry('bu','Burma','BUR');
	MergeCountry('bv','Bouvet Island','BVT');
	MergeCountry('bw','Botswana','BWA');
	MergeCountry('by','Byelorussian SSR','BYS');
	MergeCountry('by','Belarus','BLR');
	MergeCountry('bz','Belize','BLZ');
	MergeCountry('ca','Canada','CAN');
	MergeCountry('cc','Cocos (Keeling) Islands (the)','CCK');
	MergeCountry('cd','Congo (the Democratic Republic of the)','COD');
	MergeCountry('cf','Central African Republic (the)','CAF');
	MergeCountry('cg','Congo (the)','COG');
	MergeCountry('ch','Switzerland','CHE');
	MergeCountry('ci',N'Côte d''Ivoire','CIV');
	MergeCountry('ck','Cook Islands (the)','COK');
	MergeCountry('cl','Chile','CHL');
	MergeCountry('cm','Cameroon','CMR');
	MergeCountry('cn','China','CHN');
	MergeCountry('co','Colombia','COL');
	MergeCountry('cp','Clipperton Island','CPT');
	MergeCountry('cr','Costa Rica','CRI');
	MergeCountry('cs','Serbia and Montenegro','SCG');
	MergeCountry('cs','Czechoslovakia','CSK');
	MergeCountry('ct','Canton and Enderbury Islands','CTE');
	MergeCountry('cu','Cuba','CUB');
	MergeCountry('cv','Cabo Verde','CPV');
	MergeCountry('cw',N'Curaçao','CUW');
	MergeCountry('cx','Christmas Island','CXR');
	MergeCountry('cy','Cyprus','CYP');
	MergeCountry('cz','Czechia','CZE');
	MergeCountry('dd','German Democratic Republic','DDR');
	MergeCountry('de','Germany','DEU');
	MergeCountry('dg','Diego Garcia','DGA');
	MergeCountry('dj','Djibouti','DJI');
	MergeCountry('dk','Denmark','DNK');
	MergeCountry('dm','Dominica','DMA');
	MergeCountry('do','Dominican Republic (the)','DOM');
	MergeCountry('dy','Dahomey','DHY');
	MergeCountry('dz','Algeria','DZA');
	MergeCountry('ec','Ecuador','ECU');
	MergeCountry('ee','Estonia','EST');
	MergeCountry('eg','Egypt','EGY');
	MergeCountry('eh','Western Sahara*','ESH');
	MergeCountry('er','Eritrea','ERI');
	MergeCountry('es','Spain','ESP');
	MergeCountry('et','Ethiopia','ETH');
	MergeCountry('fi','Finland','FIN');
	MergeCountry('fj','Fiji','FJI');
	MergeCountry('fk','Falkland Islands (the) [Malvinas]','FLK');
	MergeCountry('fm','Micronesia (Federated States of)','FSM');
	MergeCountry('fo','Faroe Islands (the)','FRO');
	MergeCountry('fq','French Southern and Antarctic Territories','ATF');
	MergeCountry('fr','France','FRA');
	MergeCountry('fx','France, Metropolitan','FXX');
	MergeCountry('ga','Gabon','GAB');
	MergeCountry('gb','United Kingdom of Great Britain and Northern Ireland (the)','GBR');
	MergeCountry('gd','Grenada','GRD');
	MergeCountry('ge','Gilbert and Ellice Islands','GEL');
	MergeCountry('ge','Georgia','GEO');
	MergeCountry('gf','French Guiana','GUF');
	MergeCountry('gg','Guernsey','GGY');
	MergeCountry('gh','Ghana','GHA');
	MergeCountry('gi','Gibraltar','GIB');
	MergeCountry('gl','Greenland','GRL');
	MergeCountry('gm','Gambia (the)','GMB');
	MergeCountry('gn','Guinea','GIN');
	MergeCountry('gp','Guadeloupe','GLP');
	MergeCountry('gq','Equatorial Guinea','GNQ');
	MergeCountry('gr','Greece','GRC');
	MergeCountry('gs','South Georgia and the South Sandwich Islands','SGS');
	MergeCountry('gt','Guatemala','GTM');
	MergeCountry('gu','Guam','GUM');
	MergeCountry('gw','Guinea-Bissau','GNB');
	MergeCountry('gy','Guyana','GUY');
	MergeCountry('hk','Hong Kong','HKG');
	MergeCountry('hm','Heard Island and McDonald Islands','HMD');
	MergeCountry('hn','Honduras','HND');
	MergeCountry('hr','Croatia','HRV');
	MergeCountry('ht','Haiti','HTI');
	MergeCountry('hu','Hungary','HUN');
	MergeCountry('hv','Upper Volta','HVO');
	MergeCountry('id','Indonesia','IDN');
	MergeCountry('ie','Ireland','IRL');
	MergeCountry('il','Israel','ISR');
	MergeCountry('im','Isle of Man','IMN');
	MergeCountry('in','India','IND');
	MergeCountry('io','British Indian Ocean Territory (the)','IOT');
	MergeCountry('iq','Iraq','IRQ');
	MergeCountry('ir','Iran (Islamic Republic of)','IRN');
	MergeCountry('is','Iceland','ISL');
	MergeCountry('it','Italy','ITA');
	MergeCountry('je','Jersey','JEY');
	MergeCountry('jm','Jamaica','JAM');
	MergeCountry('jo','Jordan','JOR');
	MergeCountry('jp','Japan','JPN');
	MergeCountry('jt','Johnston Island','JTN');
	MergeCountry('ke','Kenya','KEN');
	MergeCountry('kg','Kyrgyzstan','KGZ');
	MergeCountry('kh','Cambodia','KHM');
	MergeCountry('ki','Kiribati','KIR');
	MergeCountry('km','Comoros (the)','COM');
	MergeCountry('kn','Saint Kitts and Nevis','KNA');
	MergeCountry('kp','Korea (the Democratic People''s Republic of)','PRK');
	MergeCountry('kr','Korea (the Republic of)','KOR');
	MergeCountry('kw','Kuwait','KWT');
	MergeCountry('ky','Cayman Islands (the)','CYM');
	MergeCountry('kz','Kazakhstan','KAZ');
	MergeCountry('la','Lao People''s Democratic Republic (the)','LAO');
	MergeCountry('lb','Lebanon','LBN');
	MergeCountry('lc','Saint Lucia','LCA');
	MergeCountry('li','Liechtenstein','LIE');
	MergeCountry('lk','Sri Lanka','LKA');
	MergeCountry('lr','Liberia','LBR');
	MergeCountry('ls','Lesotho','LSO');
	MergeCountry('lt','Lithuania','LTU');
	MergeCountry('lu','Luxembourg','LUX');
	MergeCountry('lv','Latvia','LVA');
	MergeCountry('ly','Libya','LBY');
	MergeCountry('ma','Morocco','MAR');
	MergeCountry('mc','Monaco','MCO');
	MergeCountry('md','Moldova (the Republic of)','MDA');
	MergeCountry('me','Montenegro','MNE');
	MergeCountry('mf','Saint Martin (French part)','MAF');
	MergeCountry('mg','Madagascar','MDG');
	MergeCountry('mh','Marshall Islands (the)','MHL');
	MergeCountry('mi','Midway Islands','MID');
	MergeCountry('mk','North Macedonia','MKD');
	MergeCountry('ml','Mali','MLI');
	MergeCountry('mm','Myanmar','MMR');
	MergeCountry('mn','Mongolia','MNG');
	MergeCountry('mo','Macao','MAC');
	MergeCountry('mp','Northern Mariana Islands (the)','MNP');
	MergeCountry('mq','Martinique','MTQ');
	MergeCountry('mr','Mauritania','MRT');
	MergeCountry('ms','Montserrat','MSR');
	MergeCountry('mt','Malta','MLT');
	MergeCountry('mu','Mauritius','MUS');
	MergeCountry('mv','Maldives','MDV');
	MergeCountry('mw','Malawi','MWI');
	MergeCountry('mx','Mexico','MEX');
	MergeCountry('my','Malaysia','MYS');
	MergeCountry('mz','Mozambique','MOZ');
	MergeCountry('na','Namibia','NAM');
	MergeCountry('nc','New Caledonia','NCL');
	MergeCountry('ne','Niger (the)','NER');
	MergeCountry('nf','Norfolk Island','NFK');
	MergeCountry('ng','Nigeria','NGA');
	MergeCountry('nh','New Hebrides','NHB');
	MergeCountry('ni','Nicaragua','NIC');
	MergeCountry('nl','Netherlands (Kingdom of the)','NLD');
	MergeCountry('no','Norway','NOR');
	MergeCountry('np','Nepal','NPL');
	MergeCountry('nq','Dronning Maud Land','ATN');
	MergeCountry('nr','Nauru','NRU');
	MergeCountry('nt','Neutral Zone','NTZ');
	MergeCountry('nu','Niue','NIU');
	MergeCountry('nz','New Zealand','NZL');
	MergeCountry('om','Oman','OMN');
	MergeCountry('pa','Panama','PAN');
	MergeCountry('pc','Pacific Islands (Trust Territory)','PCI');
	MergeCountry('pe','Peru','PER');
	MergeCountry('pf','French Polynesia','PYF');
	MergeCountry('pg','Papua New Guinea','PNG');
	MergeCountry('ph','Philippines (the)','PHL');
	MergeCountry('pk','Pakistan','PAK');
	MergeCountry('pl','Poland','POL');
	MergeCountry('pm','Saint Pierre and Miquelon','SPM');
	MergeCountry('pn','Pitcairn','PCN');
	MergeCountry('pr','Puerto Rico','PRI');
	MergeCountry('ps','Palestine, State of','PSE');
	MergeCountry('pt','Portugal','PRT');
	MergeCountry('pu','United States Miscellaneous Pacific Islands','PUS');
	MergeCountry('pw','Palau','PLW');
	MergeCountry('py','Paraguay','PRY');
	MergeCountry('pz','Panama Canal Zone','PCZ');
	MergeCountry('qa','Qatar','QAT');
	MergeCountry('re',N'Réunion','REU');
	MergeCountry('rh','Southern Rhodesia','RHO');
	MergeCountry('ro','Romania','ROU');
	MergeCountry('rs','Serbia','SRB');
	MergeCountry('ru','Russian Federation (the)','RUS');
	MergeCountry('rw','Rwanda','RWA');
	MergeCountry('sa','Saudi Arabia','SAU');
	MergeCountry('sb','Solomon Islands','SLB');
	MergeCountry('sc','Seychelles','SYC');
	MergeCountry('sd','Sudan (the)','SDN');
	MergeCountry('se','Sweden','SWE');
	MergeCountry('sg','Singapore','SGP');
	MergeCountry('sh','Saint Helena, Ascension and Tristan da Cunha','SHN');
	MergeCountry('si','Slovenia','SVN');
	MergeCountry('sj','Svalbard and Jan Mayen','SJM');
	MergeCountry('sk','Slovakia','SVK');
	MergeCountry('sk','Sikkim','SKM');
	MergeCountry('sl','Sierra Leone','SLE');
	MergeCountry('sm','San Marino','SMR');
	MergeCountry('sn','Senegal','SEN');
	MergeCountry('so','Somalia','SOM');
	MergeCountry('sr','Suriname','SUR');
	MergeCountry('ss','South Sudan','SSD');
	MergeCountry('st','Sao Tome and Principe','STP');
	MergeCountry('su','USSR','SUN');
	MergeCountry('sv','El Salvador','SLV');
	MergeCountry('sx','Sint Maarten (Dutch part)','SXM');
	MergeCountry('sy','Syrian Arab Republic (the)','SYR');
	MergeCountry('sz','Eswatini','SWZ');
	MergeCountry('ta','Tristan da Cunha','TAA');
	MergeCountry('tc','Turks and Caicos Islands (the)','TCA');
	MergeCountry('td','Chad','TCD');
	MergeCountry('tf','French Southern Territories (the)','ATF');
	MergeCountry('tg','Togo','TGO');
	MergeCountry('th','Thailand','THA');
	MergeCountry('tj','Tajikistan','TJK');
	MergeCountry('tk','Tokelau','TKL');
	MergeCountry('tl','Timor-Leste','TLS');
	MergeCountry('tm','Turkmenistan','TKM');
	MergeCountry('tn','Tunisia','TUN');
	MergeCountry('to','Tonga','TON');
	MergeCountry('tp','East Timor','TMP');
	MergeCountry('tr',N'Türkiye','TUR');
	MergeCountry('tt','Trinidad and Tobago','TTO');
	MergeCountry('tv','Tuvalu','TUV');
	MergeCountry('tw','Taiwan (Province of China)','TWN');
	MergeCountry('tz','Tanzania, the United Republic of','TZA');
	MergeCountry('ua','Ukraine','UKR');
	MergeCountry('ug','Uganda','UGA');
	MergeCountry('um','United States Minor Outlying Islands (the)','UMI');
	MergeCountry('us','United States of America (the)','USA');
	MergeCountry('uy','Uruguay','URY');
	MergeCountry('uz','Uzbekistan','UZB');
	MergeCountry('va','Holy See (the)','VAT');
	MergeCountry('vc','Saint Vincent and the Grenadines','VCT');
	MergeCountry('vd','Viet-Nam, Democratic Republic of','VDR');
	MergeCountry('ve','Venezuela (Bolivarian Republic of)','VEN');
	MergeCountry('vg','Virgin Islands (British)','VGB');
	MergeCountry('vi','Virgin Islands (U.S.)','VIR');
	MergeCountry('vn','Viet Nam','VNM');
	MergeCountry('vu','Vanuatu','VUT');
	MergeCountry('wf','Wallis and Futuna','WLF');
	MergeCountry('wk','Wake Island','WAK');
	MergeCountry('ws','Samoa','WSM');
	MergeCountry('yd','Yemen, Democratic','YMD');
	MergeCountry('ye','Yemen','YEM');
	MergeCountry('yt','Mayotte','MYT');
	MergeCountry('yu','Yugoslavia','YUG');
	MergeCountry('za','South Africa','ZAF');
	MergeCountry('zm','Zambia','ZMB');
	MergeCountry('zr','Zaire','ZAR');
	MergeCountry('zw','Zimbabwe','ZWE');
END;
/
-- ac should never have been set to continental Africa; it's only been used on test sites.
UPDATE postcode.country
   SET is_standard = 1
 WHERE country = 'ac';

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
