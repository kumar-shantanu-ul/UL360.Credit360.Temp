-- Please update version.sql too -- this keeps clean builds in sync
define version=2904
define minor_version=8
@update_header

@@latest2904_8_packages

-- *** DDL ***
-- Create tables

CREATE TABLE aspen2.culture (
	CULTURE_ID		NUMBER(10, 0) NOT NULL,
	IETF			VARCHAR2(255) NOT NULL,
    DESCRIPTION		VARCHAR2(255) NOT NULL,
	UPDATED_DTM		DATE DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_CUL PRIMARY KEY (CULTURE_ID),
    CONSTRAINT UK_CUL UNIQUE (IETF)
);

-- Alter tables

ALTER TABLE csr.scheduled_stored_proc MODIFY (NEXT_RUN_DTM DEFAULT (null) NULL);

CREATE OR REPLACE PACKAGE csr.user_report_pkg
IS
END user_report_pkg;
/
CREATE OR REPLACE PACKAGE BODY csr.user_report_pkg
IS
END user_report_pkg;
/

-- *** Grants ***

grant select on aspen2.timezones_win_to_cldr to csr;
grant select on aspen2.culture to csr;
grant execute on csr.user_report_pkg to chain;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please add the path to the create_views file which will contain your view changes.  I will use this version when making the major scripts.
--C:\cvs\csr\db\create_views.sql
CREATE OR REPLACE VIEW csr.v$csr_user AS
	SELECT cu.app_sid, cu.csr_user_sid, cu.email, cu.full_name, cu.user_name, cu.send_alerts,
		   cu.guid, cu.friendly_name, cu.info_xml, cu.show_portal_help, cu.donations_browse_filter_id, cu.donations_reports_filter_id,
		   cu.hidden, cu.phone_number, cu.job_title, ut.account_enabled active, ut.last_logon, cu.created_dtm, ut.expiration_dtm, 
		   ut.language, ut.culture, ut.timezone, so.parent_sid_id, cu.last_modified_dtm, cu.last_logon_type_Id, cu.line_manager_sid, cu.primary_region_sid,
		   cu.enable_aria
      FROM csr_user cu, security.securable_object so, security.user_table ut, customer c
     WHERE cu.app_sid = c.app_sid
       AND cu.csr_user_sid = so.sid_id
       AND so.parent_sid_id != c.trash_sid
       AND ut.sid_id = so.sid_id
       AND cu.hidden = 0;

-- *** Data changes ***
-- RLS

-- Data
DECLARE
	v_card_id	NUMBER(10);
	v_cms_card_id	NUMBER(10);		
    v_builtin_admin_act		security.security_pkg.T_ACT_ID;
BEGIN
	-- We'll login as builtin/administrator for this bit...
	security.user_pkg.LogonAuthenticated(security.security_pkg.SID_BUILTIN_ADMINISTRATOR, 100000, v_builtin_admin_act);
	security.security_pkg.SetACT(v_builtin_admin_act);

	BEGIN
		INSERT INTO chain.card_group
		(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES
		(47, 'User Data Filter', 'Allows filtering of user data', 'csr.user_report_pkg', '/csr/site/users/list/list.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card_group
			   SET name = 'User Data Filter', 
				   description = 'Allows filtering of user data',
				   helper_pkg = 'csr.user_report_pkg',
				   list_page_url = '/csr/site/users/list/list.acds?savedFilterSid='
			 WHERE card_group_id = 47;
	END;	
	
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
			 VALUES (47, 1, 'Number of users');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN NULL;
	END;

	chain.temp_card_pkg.RegisterCard(
		'User Data Filter', 
		'Credit360.Schema.Cards.UserDataFilter',
		'/csr/site/users/list/filters/UserDataFilter.js', 
		'Credit360.Users.Filters.UserDataFilter',
		NULL
	);

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 1, 1, 'Role region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 2, 1, 'Associated region');

	INSERT INTO chain.card_group_column_type (card_group_id, column_id, column_type, description)
		 VALUES (47, 3, 1, 'Start point region');
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'User Data Filter',
			'csr.user_report_pkg',
			chain.temp_card_pkg.GetCardId('Credit360.Users.Filters.UserDataFilter')
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE chain.filter_type
			   SET description = 'User Data Filter',
			       helper_pkg = 'csr.user_report_pkg'
			 WHERE card_id = chain.temp_card_pkg.GetCardId('Credit360.Users.Filters.UserDataFilter');
	END;
	
	
	chain.temp_card_pkg.RegisterCard(
		'CMS Data Adaptor', 
		'NPSL.Cms.Cards.CmsAdaptor',
		'/fp/cms/filters/CmsAdaptor.js', 
		'NPSL.Cms.Filters.CmsFilterAdaptor',
		NULL
	);
	
	BEGIN
		INSERT INTO chain.filter_type (
			filter_type_id,
			description,
			helper_pkg,
			card_id
		) VALUES (
			chain.filter_type_id_seq.NEXTVAL,
			'Cms Adaptor Filter',
			'cms.filter_pkg',
			chain.temp_card_pkg.GetCardId('NPSL.Cms.Filters.CmsFilterAdaptor')
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			UPDATE chain.filter_type
			   SET description = 'Cms Adaptor Filter',
			       helper_pkg = 'cms.filter_pkg'
			 WHERE card_id = chain.temp_card_pkg.GetCardId('NPSL.Cms.Filters.CmsFilterAdaptor');
	END;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Credit360.Users.Filters.UserDataFilter';
	
	SELECT card_id
	  INTO v_cms_card_id
	  FROM chain.card
	 WHERE js_class_type = 'NPSL.Cms.Filters.CmsFilterAdaptor';
	
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM csr.customer
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 47, v_card_id, 0);
			 
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		     VALUES (r.app_sid, 47, v_cms_card_id, 1);
	END LOOP;
	
	security.user_pkg.logonadmin('');	
END;
/

INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (1,'af-ZA', 'Afrikaans (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (2,'sq-AL', 'Albanian (Albania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (3,'gsw-FR', 'Alsatian (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (4,'am-ET', 'Amharic (Ethiopia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (5,'ar-DZ', 'Arabic (Algeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (6,'ar-BH', 'Arabic (Bahrain)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (7,'ar-EG', 'Arabic (Egypt)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (8,'ar-IQ', 'Arabic (Iraq)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (9,'ar-JO', 'Arabic (Jordan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (10,'ar-KW', 'Arabic (Kuwait)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (11,'ar-LB', 'Arabic (Lebanon)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (12,'ar-LY', 'Arabic (Libya)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (13,'ar-MA', 'Arabic (Morocco)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (14,'ar-OM', 'Arabic (Oman)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (15,'ar-QA', 'Arabic (Qatar)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (16,'ar-SA', 'Arabic (Saudi Arabia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (17,'ar-SY', 'Arabic (Syria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (18,'ar-TN', 'Arabic (Tunisia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (19,'ar-AE', 'Arabic (U.A.E.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (20,'ar-YE', 'Arabic (Yemen)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (21,'hy-AM', 'Armenian (Armenia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (22,'as-IN', 'Assamese (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (23,'az-Cyrl-AZ', 'Azeri (Cyrillic, Azerbaijan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (24,'az-Latn-AZ', 'Azeri (Latin, Azerbaijan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (25,'ba-RU', 'Bashkir (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (26,'eu-ES', 'Basque (Basque)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (27,'be-BY', 'Belarusian (Belarus)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (28,'bn-BD', 'Bengali (Bangladesh)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (29,'bn-IN', 'Bengali (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (30,'bs-Cyrl-BA', 'Bosnian (Cyrillic, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (31,'bs-Latn-BA', 'Bosnian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (32,'br-FR', 'Breton (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (33,'bg-BG', 'Bulgarian (Bulgaria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (34,'ca-ES', 'Catalan (Catalan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (35,'zh-CN', 'Chinese (Simplified, PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (36,'zh-SG', 'Chinese (Simplified, Singapore)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (37,'zh-HK', 'Chinese (Traditional, Hong Kong S.A.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (38,'zh-MO', 'Chinese (Traditional, Macao S.A.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (39,'zh-TW', 'Chinese (Traditional, Taiwan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (40,'co-FR', 'Corsican (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (41,'hr-HR', 'Croatian (Croatia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (42,'hr-BA', 'Croatian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (43,'cs-CZ', 'Czech (Czech Republic)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (44,'da-DK', 'Danish (Denmark)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (45,'prs-AF', 'Dari (Afghanistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (46,'dv-MV', 'Divehi (Maldives)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (47,'nl-BE', 'Dutch (Belgium)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (48,'nl-NL', 'Dutch (Netherlands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (49,'en-AU', 'English (Australia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (50,'en-BZ', 'English (Belize)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (51,'en-CA', 'English (Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (52,'en-029', 'English (Caribbean)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (53,'en-IN', 'English (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (54,'en-IE', 'English (Ireland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (55,'en-JM', 'English (Jamaica)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (56,'en-MY', 'English (Malaysia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (57,'en-NZ', 'English (New Zealand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (58,'en-PH', 'English (Republic of the Philippines)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (59,'en-SG', 'English (Singapore)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (60,'en-ZA', 'English (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (61,'en-TT', 'English (Trinidad and Tobago)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (62,'en-GB', 'English (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (63,'en-US', 'English (United States)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (64,'en-ZW', 'English (Zimbabwe)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (65,'et-EE', 'Estonian (Estonia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (66,'fo-FO', 'Faroese (Faroe Islands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (67,'fil-PH', 'Filipino (Philippines)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (68,'fi-FI', 'Finnish (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (69,'fr-BE', 'French (Belgium)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (70,'fr-CA', 'French (Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (71,'fr-FR', 'French (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (72,'fr-LU', 'French (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (73,'fr-MC', 'French (Monaco)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (74,'fr-CH', 'French (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (75,'fy-NL', 'Frisian (Netherlands)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (76,'gl-ES', 'Galician (Galician)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (77,'ka-GE', 'Georgian (Georgia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (78,'de-AT', 'German (Austria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (79,'de-DE', 'German (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (80,'de-LI', 'German (Liechtenstein)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (81,'de-LU', 'German (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (82,'de-CH', 'German (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (83,'el-GR', 'Greek (Greece)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (84,'kl-GL', 'Greenlandic (Greenland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (85,'gu-IN', 'Gujarati (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (86,'ha-Latn-NG', 'Hausa (Latin, Nigeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (87,'he-IL', 'Hebrew (Israel)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (88,'hi-IN', 'Hindi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (89,'hu-HU', 'Hungarian (Hungary)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (90,'is-IS', 'Icelandic (Iceland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (91,'ig-NG', 'Igbo (Nigeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (92,'id-ID', 'Indonesian (Indonesia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (93,'iu-Latn-CA', 'Inuktitut (Latin, Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (94,'iu-Cans-CA', 'Inuktitut (Syllabics, Canada)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (95,'ga-IE', 'Irish (Ireland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (96,'xh-ZA', 'isiXhosa (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (97,'zu-ZA', 'isiZulu (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (98,'it-IT', 'Italian (Italy)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (99,'it-CH', 'Italian (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (100,'ja-JP', 'Japanese (Japan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (101,'kn-IN', 'Kannada (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (102,'kk-KZ', 'Kazakh (Kazakhstan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (103,'km-KH', 'Khmer (Cambodia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (104,'qut-GT', 'K''iche (Guatemala)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (105,'rw-RW', 'Kinyarwanda (Rwanda)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (106,'sw-KE', 'Kiswahili (Kenya)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (107,'kok-IN', 'Konkani (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (108,'ko-KR', 'Korean (Korea)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (109,'ky-KG', 'Kyrgyz (Kyrgyzstan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (110,'lo-LA', 'Lao (Lao P.D.R.)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (111,'lv-LV', 'Latvian (Latvia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (112,'lt-LT', 'Lithuanian (Lithuania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (113,'dsb-DE', 'Lower Sorbian (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (114,'lb-LU', 'Luxembourgish (Luxembourg)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (115,'mk-MK', 'Macedonian (Former Yugoslav Republic of Macedonia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (116,'ms-BN', 'Malay (Brunei Darussalam)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (117,'ms-MY', 'Malay (Malaysia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (118,'ml-IN', 'Malayalam (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (119,'mt-MT', 'Maltese (Malta)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (120,'mi-NZ', 'Maori (New Zealand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (121,'arn-CL', 'Mapudungun (Chile)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (122,'mr-IN', 'Marathi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (123,'moh-CA', 'Mohawk (Mohawk)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (124,'mn-MN', 'Mongolian (Cyrillic, Mongolia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (125,'mn-Mong-CN', 'Mongolian (Traditional Mongolian, PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (126,'ne-NP', 'Nepali (Nepal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (127,'nb-NO', 'Norwegian, Bokmål (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (128,'nn-NO', 'Norwegian, Nynorsk (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (129,'oc-FR', 'Occitan (France)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (130,'or-IN', 'Oriya (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (131,'ps-AF', 'Pashto (Afghanistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (132,'fa-IR', 'Persian');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (133,'pl-PL', 'Polish (Poland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (134,'pt-BR', 'Portuguese (Brazil)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (135,'pt-PT', 'Portuguese (Portugal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (136,'pa-IN', 'Punjabi (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (137,'quz-BO', 'Quechua (Bolivia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (138,'quz-EC', 'Quechua (Ecuador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (139,'quz-PE', 'Quechua (Peru)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (140,'ro-RO', 'Romanian (Romania)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (141,'rm-CH', 'Romansh (Switzerland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (142,'ru-RU', 'Russian (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (143,'sah-RU', 'Sakha (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (144,'smn-FI', 'Sami, Inari (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (145,'smj-NO', 'Sami, Lule (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (146,'smj-SE', 'Sami, Lule (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (147,'se-FI', 'Sami, Northern (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (148,'se-NO', 'Sami, Northern (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (149,'se-SE', 'Sami, Northern (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (150,'sms-FI', 'Sami, Skolt (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (151,'sma-NO', 'Sami, Southern (Norway)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (152,'sma-SE', 'Sami, Southern (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (153,'sa-IN', 'Sanskrit (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (154,'gd-GB', 'Scottish Gaelic (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (155,'sr-Cyrl-BA', 'Serbian (Cyrillic, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (156,'sr-Cyrl-ME', 'Serbian (Cyrillic, Montenegro)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (157,'sr-Cyrl-CS', 'Serbian (Cyrillic, Serbia and Montenegro (Former))');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (158,'sr-Cyrl-RS', 'Serbian (Cyrillic, Serbia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (159,'sr-Latn-BA', 'Serbian (Latin, Bosnia and Herzegovina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (160,'sr-Latn-ME', 'Serbian (Latin, Montenegro)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (161,'sr-Latn-CS', 'Serbian (Latin, Serbia and Montenegro (Former))');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (162,'sr-Latn-RS', 'Serbian (Latin, Serbia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (163,'nso-ZA', 'Sesotho sa Leboa (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (164,'tn-ZA', 'Setswana (South Africa)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (165,'si-LK', 'Sinhala (Sri Lanka)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (166,'sk-SK', 'Slovak (Slovakia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (167,'sl-SI', 'Slovenian (Slovenia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (168,'es-AR', 'Spanish (Argentina)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (169,'es-VE', 'Spanish (Bolivarian Republic of Venezuela)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (170,'es-BO', 'Spanish (Bolivia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (171,'es-CL', 'Spanish (Chile)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (172,'es-CO', 'Spanish (Colombia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (173,'es-CR', 'Spanish (Costa Rica)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (174,'es-DO', 'Spanish (Dominican Republic)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (175,'es-EC', 'Spanish (Ecuador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (176,'es-SV', 'Spanish (El Salvador)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (177,'es-GT', 'Spanish (Guatemala)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (178,'es-HN', 'Spanish (Honduras)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (179,'es-MX', 'Spanish (Mexico)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (180,'es-NI', 'Spanish (Nicaragua)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (181,'es-PA', 'Spanish (Panama)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (182,'es-PY', 'Spanish (Paraguay)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (183,'es-PE', 'Spanish (Peru)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (184,'es-PR', 'Spanish (Puerto Rico)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (185,'es-ES', 'Spanish (Spain)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (186,'es-US', 'Spanish (United States)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (187,'es-UY', 'Spanish (Uruguay)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (188,'sv-FI', 'Swedish (Finland)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (189,'sv-SE', 'Swedish (Sweden)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (190,'syr-SY', 'Syriac (Syria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (191,'tg-Cyrl-TJ', 'Tajik (Cyrillic, Tajikistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (192,'tzm-Latn-DZ', 'Tamazight (Latin, Algeria)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (193,'ta-IN', 'Tamil (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (194,'tt-RU', 'Tatar (Russia)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (195,'te-IN', 'Telugu (India)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (196,'th-TH', 'Thai (Thailand)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (197,'bo-CN', 'Tibetan (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (198,'tr-TR', 'Turkish (Turkey)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (199,'tk-TM', 'Turkmen (Turkmenistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (200,'uk-UA', 'Ukrainian (Ukraine)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (201,'hsb-DE', 'Upper Sorbian (Germany)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (202,'ur-PK', 'Urdu (Islamic Republic of Pakistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (203,'ug-CN', 'Uyghur (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (204,'uz-Cyrl-UZ', 'Uzbek (Cyrillic, Uzbekistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (205,'uz-Latn-UZ', 'Uzbek (Latin, Uzbekistan)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (206,'vi-VN', 'Vietnamese (Vietnam)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (207,'cy-GB', 'Welsh (United Kingdom)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (208,'wo-SN', 'Wolof (Senegal)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (209,'ii-CN', 'Yi (PRC)');
INSERT INTO aspen2.culture (culture_id, Ietf, Description)
VALUES (210,'yo-NG', 'Yoruba (Nigeria)');
	
-- ** New package grants **

-- *** Packages ***

@../../../aspen2/cms/db/filter_pkg
@../chain/filter_pkg
@../ssp_pkg
@../csr_user_pkg
@../user_report_pkg

@../../../aspen2/cms/db/filter_body
@../chain/filter_body
@../ssp_body
@../csr_user_body
@../csr_app_body
@../role_body
@../user_report_body

DROP PACKAGE chain.temp_card_pkg;

@update_tail
