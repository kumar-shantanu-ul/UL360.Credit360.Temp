define version=3498
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
BEGIN
	FOR r IN (
		SELECT table_name
		  FROM all_tables
		 WHERE owner='CSRIMP' AND table_name!='CSRIMP_SESSION'
		)
	LOOP
		EXECUTE IMMEDIATE 'TRUNCATE TABLE csrimp.'||r.table_name;
	END LOOP;
	DELETE FROM csrimp.csrimp_session;
	commit;
END;
/

-- clean out debug log
TRUNCATE TABLE security.debug_log;

CREATE SEQUENCE CSR.SHEET_CREATED_ALERT_ID_SEQ;
CREATE TABLE CSR.SHEET_CREATED_ALERT(
    APP_SID                        NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    SHEET_CREATED_ALERT_ID         NUMBER(10, 0)    NOT NULL,
    NOTIFY_USER_SID                NUMBER(10, 0)    NOT NULL,
    RAISED_BY_USER_SID             NUMBER(10, 0)    NOT NULL,
    SHEET_ID                       NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_SHEET_CREATED_ALERT PRIMARY KEY (APP_SID, SHEET_CREATED_ALERT_ID)
)
;


DELETE FROM csr.new_planned_deleg_alert
 WHERE new_planned_deleg_alert_id IN (
	SELECT new_planned_deleg_alert_id FROM csr.new_planned_deleg_alert al
	  LEFT JOIN csr.customer c ON c.app_sid = al.app_sid
	 WHERE host is null
);
DELETE FROM csr.new_planned_deleg_alert
 WHERE new_planned_deleg_alert_id IN (
	SELECT new_planned_deleg_alert_id FROM csr.new_planned_deleg_alert al
	  LEFT JOIN csr.sheet s ON s.sheet_id = al.sheet_id
	 WHERE s.sheet_id is null
);
ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_NOTIFY_USER
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_RAISED_USER
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.NEW_PLANNED_DELEG_ALERT ADD CONSTRAINT FK_NEW_PLANNED_DELEG_ALRT_SHEET
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;
ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_NOTIFY_USER
    FOREIGN KEY (APP_SID, NOTIFY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_RAISED_USER
    FOREIGN KEY (APP_SID, RAISED_BY_USER_SID)
    REFERENCES CSR.CSR_USER(APP_SID, CSR_USER_SID)
;
ALTER TABLE CSR.SHEET_CREATED_ALERT ADD CONSTRAINT FK_SHEET_CREATED_ALRT_SHEET
    FOREIGN KEY (APP_SID, SHEET_ID)
    REFERENCES CSR.SHEET(APP_SID, SHEET_ID)
;
create index csr.ix_new_planned_deleg_alrt_notify_user on csr.new_planned_deleg_alert(app_sid, notify_user_sid);
create index csr.ix_new_planned_deleg_alrt_raised_user on csr.new_planned_deleg_alert(app_sid, raised_by_user_sid);
create index csr.ix_new_planned_deleg_alert_sheet on csr.new_planned_deleg_alert(app_sid, sheet_id);
create index csr.ix_sheet_created_alrt_notify_user on csr.sheet_created_alert(app_sid, notify_user_sid);
create index csr.ix_sheet_created_alrt_raised_user on csr.sheet_created_alert(app_sid, raised_by_user_sid);
create index csr.ix_sheet_created_alert_sheet on csr.sheet_created_alert(app_sid, sheet_id);
ALTER TABLE csr.temp_deleg_plan_overlap ADD (
	overlapping_region_sid	NUMBER(10, 0)
);
UPDATE csr.temp_deleg_plan_overlap SET overlapping_region_sid = applied_to_region_sid;
ALTER TABLE csr.temp_deleg_plan_overlap MODIFY (
	overlapping_region_sid NOT NULL,
	applied_to_region_sid  NULL
);
ALTER TABLE aspen2.application ADD (
   maxmind_enabled NUMBER(1) DEFAULT 1 NOT NULL
   CONSTRAINT CK_MAXMIND_ENABLED CHECK (maxmind_enabled IN (0,1))
);
ALTER TABLE csrimp.aspen2_application ADD (
  maxmind_enabled NUMBER(1) DEFAULT 1 NOT NULL
  CONSTRAINT CK_MAXMIND_ENABLED CHECK (maxmind_enabled IN (0,1))
);
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (128, 'MaxMind Geo Location', 'EnableMaxMind', 'Enables MaxMind Geo location.');
INSERT INTO csr.module_param (module_id, param_name, pos, param_hint)
VALUES (128, 'Enable/Disable', 0, '0=disable, 1=enable');










UPDATE csr.auto_imp_core_data_settings
   SET all_or_nothing = 0
 WHERE all_or_nothing != 0;
UPDATE csr.auto_imp_core_data_settings
   SET requires_validation_step = 0
 WHERE requires_validation_step != 0;
DECLARE
	v_id NUMBER(10);
BEGIN
	-- Rename old alert type
	UPDATE csr.std_alert_type
	   SET description = 'Delegation plan - new forms created (legacy)', 
		   send_trigger = 'This alert is sent when delegation forms are created from a delegation plan, either by applying the delegation plan or by adding new regions to a delegation plan that has been applied dynamically. "Delegation plans - new forms created (legacy)" notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.'
	 WHERE std_alert_type_id = 68;
	
    -- Add new alert type 	
	INSERT INTO CSR.STD_ALERT_TYPE (STD_ALERT_TYPE_ID, DESCRIPTION, SEND_TRIGGER, SENT_FROM, STD_ALERT_TYPE_GROUP_ID)
	VALUES (
			80,
			'Delegation - new forms created',
			'This alert is sent to all users involved in the delegation for each form when they are created. "Delegation - new forms created" notifications are grouped together and sent out in a single e-mail. At most one e-mail will be sent per day.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			2 -- csr.data_pkg.ALERT_GROUP_DELEGTIONS
	);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATOR_FULL_NAME', 'Delegator full name', 'The full name of the user who made the delegation', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATOR_EMAIL', 'Delegator e-mail', 'The e-mail address of the user who made the delegation', 6);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEGATION_NAME', 'Delegation name', 'The name of the delegation', 7);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SUBMISSION_DTM_FMT', 'Submission date', 'The due date of the sheet', 8);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SHEET_URL', 'Sheet link', 'A hyperlink to the sheet', 9);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'DELEG_ASSIGNED_TO', 'Assigned to', 'The name of the user the delegation is assigned to', 10);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (80, 1, 'SHEET_PERIOD_FMT', 'Sheet period', 'The period that the sheet covers', 11);
	-- Create default alert template
	SELECT default_alert_frame_id
	  INTO v_id
	  FROM csr.default_alert_frame
	 WHERE name = 'Default';
	  
	INSERT INTO CSR.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (80, v_id, 'inactive');
	INSERT INTO CSR.default_alert_template_body (std_alert_type_id, lang, subject, body_html, item_html) VALUES (80, 'en',
		'<template>New delegation forms to complete</template>',
		'<template><p>Hello <mergefield name="TO_FRIENDLY_NAME" />,</p><p>Delegation forms are now ready for you to complete and submit.</p><p><mergefield name="ITEMS" /></p><p>Many thanks for your co-operation.</p></template>',
		'<template><mergefield name="DELEGATION_NAME"/>(<mergefield name="SHEET_PERIOD_FMT"/>)- due <mergefield name="SUBMISSION_DTM_FMT"/><br/><mergefield name="SHEET_URL"/></template>'
	);
	-- Enable for all customers using default alert template
	INSERT INTO csr.customer_alert_type (app_sid, customer_alert_type_id, std_alert_type_id)
	SELECT app_sid, csr.customer_alert_type_id_seq.nextval, 80 -- csr.csr_data_pkg.ALERT_SHEET_CREATED
	  FROM csr.customer_alert_type 
	 WHERE std_alert_type_id = 20; -- csr.csr_data_pkg.ALERT_GENERIC_MAILOUT
END;
/
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
UPDATE postcode.country
   SET is_standard = 1
 WHERE country = 'ac';
BEGIN
    -- corrections
    UPDATE postcode.country
       SET iso3 = LOWER(iso3);
    DELETE FROM postcode.country
     WHERE country IN ('bu','cp','cs','dd','dg','dy','fq','fx','hv','jt','nt','nh','nq','pc','pu','pz','rh','su','ta','tp','vd','wk','yd','yu','zr');
    UPDATE postcode.country
       SET name = 'Africa', iso3 = 'afr'
     WHERE country = 'ac';
    UPDATE postcode.country
       SET name = 'Anguilla', iso3 = 'aia'
     WHERE country = 'ai';
    UPDATE postcode.country
       SET name = 'Middle East', iso3 = 'mde'
     WHERE country = 'mi';
    UPDATE postcode.country
       SET name = 'Slovakia', iso3 = 'svk'
     WHERE country = 'sk';
	--non standard countries
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('aa', 'Asia', 'asi', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ab', 'Africa', 'afr', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ap', 'Asia/Pacific Region', 'apc', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ay', 'Asia Oceania', 'aso', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ea', 'Non-OECD Europe and Eurasia', 'eua', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ep', 'European Union', 'euu', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('eu', 'Europe', 'eur', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('hc', 'China (including Hong Kong)', 'chk', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('lm', 'Latin America', 'lta', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('mi', 'Middle East', 'mde', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('nm', 'North America', 'nra', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('oa', 'Other Asia', 'oas', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('of', 'Other Africa', 'oaf', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
    BEGIN
        INSERT INTO postcode.country (country, name, iso3, is_standard)
        VALUES ('ol', 'Other Latin America', 'ola', 0);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN NULL;
    END;
END;
/
BEGIN
    -- corrections
    DELETE FROM postcode.country
     WHERE country IN ('ct');
    UPDATE postcode.country
       SET name = ''||UNISTR('\00C5')||'land Islands'
     WHERE country = 'ax';
    UPDATE postcode.country
       SET name = 'Saint Barth'||UNISTR('\00E9')||'lemy'
     WHERE country = 'bl';
    UPDATE postcode.country
       SET name = 'C'||UNISTR('\00F4')||'te d''Ivoire'
     WHERE country = 'ci';
    UPDATE postcode.country
       SET name = 'Cura'||UNISTR('\00E7')||'ao'
     WHERE country = 'cw';
    UPDATE postcode.country
       SET name = 'R'||UNISTR('\00E9')||'union'
     WHERE country = 're';
    UPDATE postcode.country
       SET name = 'T'||UNISTR('\00FC')||'rkiye'
     WHERE country = 'tr';
END;
/






@..\customer_pkg
@..\csr_data_pkg
@..\delegation_pkg
@..\sheet_pkg
@..\region_pkg
@..\batch_job_pkg
@..\enable_pkg
@..\..\..\aspen2\db\tr_pkg


@..\delegation_body
@..\issue_report_body
@..\customer_body
@..\schema_body
@..\factor_body
@..\factor_set_group_body
@..\csr_app_body
@..\csr_user_body
@..\deleg_plan_body
@..\sheet_body
@..\util_script_body
@..\region_body
@..\indicator_body
@..\automated_export_body
@..\automated_import_body
@..\batch_job_body
@..\csrimp\imp_body
@..\enable_body
@..\..\..\aspen2\db\aspenapp_body
@..\..\..\aspen2\db\tr_body



@update_tail
