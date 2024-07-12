/* Unit type */
BEGIN
    INSERT INTO supplier.unit_type (unit_type_id, name) VALUES (1, 'mass');
END;
/

/* Unit */
BEGIN
    INSERT INTO supplier.unit (unit_id, unit_type_id, name, symbol) VALUES (1, 1, 'grams', 'g');
    INSERT INTO supplier.unit (unit_id, unit_type_id, name, symbol) VALUES (2, 1, 'kilos', 'kg');
END;
/

/* Group status */
BEGIN
    INSERT INTO supplier.group_status (group_status_id, description) values (1, 'Data being entered');
    INSERT INTO supplier.group_status (group_status_id, description) values (2, 'Submitted for approval');
    INSERT INTO supplier.group_status (group_status_id, description) values (3, 'Approved');
    INSERT INTO supplier.group_status (group_status_id, description) values (4, 'Data being reviewed');
END;
/

/* alert types -- for csr */
DECLARE
	ALERT_GROUP_SUPPLYCHAIN	NUMBER(10) := 8;
BEGIN
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(1000, 'Supplier user assigned to product', 
			'A user is assigned to a product.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			ALERT_GROUP_SUPPLYCHAIN
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN	
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(1001, 'Supplier product activation state changed', 
			'The activation state of a product is changed.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			ALERT_GROUP_SUPPLYCHAIN
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;

	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(1002, 'Supplier product approval status changed', 
			'A product''s approval status is changed.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			ALERT_GROUP_SUPPLYCHAIN
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) VALUES(1003, 'Supplier work reminder',
			'A work reminder is sent from the user list page.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			ALERT_GROUP_SUPPLYCHAIN
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/


/* Questionnaire status */
BEGIN
    INSERT INTO supplier.questionnaire_status (questionnaire_status_id, status) VALUES (1, 'Open');
    INSERT INTO supplier.questionnaire_status (questionnaire_status_id, status) VALUES (2, 'Closed');
END;
/

/* Company status */
BEGIN
	INSERT INTO supplier.COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(1, 'Data being entered');
	INSERT INTO supplier.COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(2, 'Submitted for approval');
	INSERT INTO supplier.COMPANY_STATUS (COMPANY_STATUS_ID, DESCRIPTION) VALUES(3, 'Approved');
END;
/

/* Audit types */
BEGIN
    -- wrap these in case we're running clean twice (i.e. this affects data in CSR)
    BEGIN
        INSERT INTO csr.audit_type_group (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES(2, 'Supplier module product');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
	
    BEGIN
        INSERT INTO csr.audit_type_group (AUDIT_TYPE_GROUP_ID, DESCRIPTION) VALUES(3, 'Supplier module questionnaire');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
END;
/

BEGIN
	-- wrap these in case we're running clean twice (i.e. this affects data in CSR)
    BEGIN
		-- 50 onwards
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (50, 'Product created', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (51, 'Product details updated', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (52, 'Product supplier changed', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (53, 'Product data approver changed', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (54, 'Product data provider changed', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (55, 'Product deleted', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (56, 'Product tag changed', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (57, 'Product volume changed', 2);
        -- 60 onwards
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (60, 'Supplier created', 1);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (61, 'Supplier details updated', 1);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (62, 'Assigned user to company', 1);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (63, 'Unassigned user from company', 1);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (64, 'Supplier deleted', 1);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (65, 'Supplier tag changed', 1);
        -- 70 onwards
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (70, 'Product status change', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (71, 'Questionaire saved', 3);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (72, 'Questionaire status change', 3);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (73, 'Questionaire linked', 2);
        INSERT INTO csr.AUDIT_TYPE (AUDIT_TYPE_ID, LABEL, audit_type_group_ID) VALUES (74, 'Questionaire unlinked', 2);
		
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 200, 'Business relationship changes');
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 201, 'Product type changes');
		INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (2, 202, 'Company product changes');
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            NULL;
    END;
END;
/

/* countries */
/* TODO: consider using the POSTCODE.COUNTRY table? This list is odd - i.e. no the standard ISO list. ASK JAMES */
BEGIN
    INSERT INTO supplier.country (country_code, country) values ('AFG','Afghanistan');
    INSERT INTO supplier.country (country_code, country) values ('AL','Albania');
    INSERT INTO supplier.country (country_code, country) values ('GBA','Alderney');
    INSERT INTO supplier.country (country_code, country) values ('DZ','Algeria');
    INSERT INTO supplier.country (country_code, country) values ('ASAM','American Samoa');
    INSERT INTO supplier.country (country_code, country) values ('AND','Andorra');
    INSERT INTO supplier.country (country_code, country) values ('AN','Angola');
    INSERT INTO supplier.country (country_code, country) values ('RA','Argentina');
    INSERT INTO supplier.country (country_code, country) values ('AUS','Australia');
    INSERT INTO supplier.country (country_code, country) values ('A','Austria');
    INSERT INTO supplier.country (country_code, country) values ('BFPO','B.F.P.O');
    INSERT INTO supplier.country (country_code, country) values ('BS','Bahamas');
    INSERT INTO supplier.country (country_code, country) values ('BRN','Bahrain');
    INSERT INTO supplier.country (country_code, country) values ('BD','Bangladesh');
    INSERT INTO supplier.country (country_code, country) values ('BDS','Barbados');
    INSERT INTO supplier.country (country_code, country) values ('BEL','Belarus');
    INSERT INTO supplier.country (country_code, country) values ('B','Belgium');
    INSERT INTO supplier.country (country_code, country) values ('BH','Belize');
    INSERT INTO supplier.country (country_code, country) values ('BM','Bermuda');
    INSERT INTO supplier.country (country_code, country) values ('BOL','Bolivia');
    INSERT INTO supplier.country (country_code, country) values ('BOS','Bosnia and Herzegovina');
    INSERT INTO supplier.country (country_code, country) values ('RB','Botswana');
    INSERT INTO supplier.country (country_code, country) values ('BR','Brazil');
    INSERT INTO supplier.country (country_code, country) values ('BVI','British Virgin Islands');
    INSERT INTO supplier.country (country_code, country) values ('BRU','Brunei');
    INSERT INTO supplier.country (country_code, country) values ('BG','Bulgaria');
    INSERT INTO supplier.country (country_code, country) values ('CAM','Cameroon');
    INSERT INTO supplier.country (country_code, country) values ('CDN','Canada');
    INSERT INTO supplier.country (country_code, country) values ('CAR','Central African Republic');
    INSERT INTO supplier.country (country_code, country) values ('CHD','Chad');
    INSERT INTO supplier.country (country_code, country) values ('RCH','Chile');
    INSERT INTO supplier.country (country_code, country) values ('TJ','China');
    INSERT INTO supplier.country (country_code, country) values ('CO','Colombia');
    INSERT INTO supplier.country (country_code, country) values ('CON','Congo');
    INSERT INTO supplier.country (country_code, country) values ('CB','Congo Brazzaville');
    INSERT INTO supplier.country (country_code, country) values ('CR','Costa Rica');
    INSERT INTO supplier.country (country_code, country) values ('CRE','Crete');
    INSERT INTO supplier.country (country_code, country) values ('CRO','Croatia');
    INSERT INTO supplier.country (country_code, country) values ('C','Cuba');
    INSERT INTO supplier.country (country_code, country) values ('CY','Cyprus');
    INSERT INTO supplier.country (country_code, country) values ('CS','Czech Republic');
    INSERT INTO supplier.country (country_code, country) values ('ZRE','Democratic Republic of Congo');
    INSERT INTO supplier.country (country_code, country) values ('DK','Denmark');
    INSERT INTO supplier.country (country_code, country) values ('DOM','Dominican Republic');
    INSERT INTO supplier.country (country_code, country) values ('EC','Ecuador');
    INSERT INTO supplier.country (country_code, country) values ('ET','Egypt');
    INSERT INTO supplier.country (country_code, country) values ('ES','El Salvador');
    INSERT INTO supplier.country (country_code, country) values ('ENG','England');
    INSERT INTO supplier.country (country_code, country) values ('EST','Estonia');
    INSERT INTO supplier.country (country_code, country) values ('ETE','Ethiopia');
    INSERT INTO supplier.country (country_code, country) values ('FI','Falkland Islands');
    INSERT INTO supplier.country (country_code, country) values ('FJI','Fiji Islands');
    INSERT INTO supplier.country (country_code, country) values ('SF','Finland');
    INSERT INTO supplier.country (country_code, country) values ('F','France');
    INSERT INTO supplier.country (country_code, country) values ('FG','French Guiana');
    INSERT INTO supplier.country (country_code, country) values ('GAB','Gabon');
    INSERT INTO supplier.country (country_code, country) values ('WAG','Gambia');
    INSERT INTO supplier.country (country_code, country) values ('G','Germany');
    INSERT INTO supplier.country (country_code, country) values ('GHA','Ghana');
    INSERT INTO supplier.country (country_code, country) values ('GBZ','Gibraltar');
    INSERT INTO supplier.country (country_code, country) values ('GR','Greece');
    INSERT INTO supplier.country (country_code, country) values ('WG','Grenada');
    INSERT INTO supplier.country (country_code, country) values ('GUA','Guatemala');
    INSERT INTO supplier.country (country_code, country) values ('GBG','Guernsey');
    INSERT INTO supplier.country (country_code, country) values ('GU','Guinea');
    INSERT INTO supplier.country (country_code, country) values ('GUY','Guyana');
    INSERT INTO supplier.country (country_code, country) values ('HO','Hondurus');
    INSERT INTO supplier.country (country_code, country) values ('HK','Hong Kong');
    INSERT INTO supplier.country (country_code, country) values ('H','Hungary');
    INSERT INTO supplier.country (country_code, country) values ('IS','Iceland');
    INSERT INTO supplier.country (country_code, country) values ('IND','India');
    INSERT INTO supplier.country (country_code, country) values ('IN','Indonesia');
    INSERT INTO supplier.country (country_code, country) values ('IR','Iran');
    INSERT INTO supplier.country (country_code, country) values ('IQ','Iraq');
    INSERT INTO supplier.country (country_code, country) values ('IRL','Ireland');
    INSERT INTO supplier.country (country_code, country) values ('GBM','Isle of Man');
    INSERT INTO supplier.country (country_code, country) values ('IL','Israel');
    INSERT INTO supplier.country (country_code, country) values ('I','Italy');
    INSERT INTO supplier.country (country_code, country) values ('CI','Ivory Coast');
    INSERT INTO supplier.country (country_code, country) values ('JA','Jamaica');
    INSERT INTO supplier.country (country_code, country) values ('J','Japan');
    INSERT INTO supplier.country (country_code, country) values ('GBJ','Jersey');
    INSERT INTO supplier.country (country_code, country) values ('HKJ','Jordan');
    INSERT INTO supplier.country (country_code, country) values ('EAK','Kenya');
    INSERT INTO supplier.country (country_code, country) values ('KWT','Kuwait');
    INSERT INTO supplier.country (country_code, country) values ('LAT','Latvia');
    INSERT INTO supplier.country (country_code, country) values ('RL','Lebanon');
    INSERT INTO supplier.country (country_code, country) values ('FL','Liechtenstein');
    INSERT INTO supplier.country (country_code, country) values ('LIT','Lithuania');
    INSERT INTO supplier.country (country_code, country) values ('L','Luxembourg');
    INSERT INTO supplier.country (country_code, country) values ('MAC','Macedonia');
    INSERT INTO supplier.country (country_code, country) values ('MWI','Malawi');
    INSERT INTO supplier.country (country_code, country) values ('MAL','Malaysia');
    INSERT INTO supplier.country (country_code, country) values ('M','Malta');
    INSERT INTO supplier.country (country_code, country) values ('MAU','Mauritania');
    INSERT INTO supplier.country (country_code, country) values ('MS','Mauritius');
    INSERT INTO supplier.country (country_code, country) values ('MEX','Mexico');
    INSERT INTO supplier.country (country_code, country) values ('MOL','Moldova');
    INSERT INTO supplier.country (country_code, country) values ('MC','Monaco');
    INSERT INTO supplier.country (country_code, country) values ('MON','Mongolia');
    INSERT INTO supplier.country (country_code, country) values ('MA','Morocco');
    INSERT INTO supplier.country (country_code, country) values ('MOC','Mozambique');
    INSERT INTO supplier.country (country_code, country) values ('BUR','Myanmar');
    INSERT INTO supplier.country (country_code, country) values ('SWA','Namibia');
    INSERT INTO supplier.country (country_code, country) values ('NE','Nepal');
    INSERT INTO supplier.country (country_code, country) values ('NL','Netherlands');
    INSERT INTO supplier.country (country_code, country) values ('NZ','New Zealand');
    INSERT INTO supplier.country (country_code, country) values ('NIC','Nicaragua');
    INSERT INTO supplier.country (country_code, country) values ('NIG','Niger');
    INSERT INTO supplier.country (country_code, country) values ('WAN','Nigeria');
    INSERT INTO supplier.country (country_code, country) values ('NK','North Korea');
    INSERT INTO supplier.country (country_code, country) values ('YWN','North yemen');
    INSERT INTO supplier.country (country_code, country) values ('NI','Northern Ireland');
    INSERT INTO supplier.country (country_code, country) values ('N','Norway');
    INSERT INTO supplier.country (country_code, country) values ('OMAN','Oman');
    INSERT INTO supplier.country (country_code, country) values ('PAK','Pakistan');
    INSERT INTO supplier.country (country_code, country) values ('PA','Panama');
    INSERT INTO supplier.country (country_code, country) values ('PNG','Papua New Guinea');
    INSERT INTO supplier.country (country_code, country) values ('PAR','Paraguay');
    INSERT INTO supplier.country (country_code, country) values ('PE','Peru');
    INSERT INTO supplier.country (country_code, country) values ('RP','Philippines');
    INSERT INTO supplier.country (country_code, country) values ('PL','Poland');
    INSERT INTO supplier.country (country_code, country) values ('P','Portugal');
    INSERT INTO supplier.country (country_code, country) values ('PR','Puerto Rico');
    INSERT INTO supplier.country (country_code, country) values ('QTR','Qatar');
    INSERT INTO supplier.country (country_code, country) values ('RSN','Republic of Suriname');
    INSERT INTO supplier.country (country_code, country) values ('RO','Romania');
    INSERT INTO supplier.country (country_code, country) values ('RS','Russia');
    INSERT INTO supplier.country (country_code, country) values ('AS','Saudi Arabia');
    INSERT INTO supplier.country (country_code, country) values ('SC','Scotland');
    INSERT INTO supplier.country (country_code, country) values ('SRB','Serbia');
    INSERT INTO supplier.country (country_code, country) values ('SYL','Seychelles');
    INSERT INTO supplier.country (country_code, country) values ('WAL','Sierra Leone');
    INSERT INTO supplier.country (country_code, country) values ('SGP','Singapore');
    INSERT INTO supplier.country (country_code, country) values ('SR','Slovak Republic');
    INSERT INTO supplier.country (country_code, country) values ('SLO','Slovenia');
    INSERT INTO supplier.country (country_code, country) values ('SI','Soloman Islands');
    INSERT INTO supplier.country (country_code, country) values ('SOMA','Somalia');
    INSERT INTO supplier.country (country_code, country) values ('ZA','South Africa');
    INSERT INTO supplier.country (country_code, country) values ('SK','South Korea');
    INSERT INTO supplier.country (country_code, country) values ('ADN','South Yemen');
    INSERT INTO supplier.country (country_code, country) values ('SP','Spain');
    INSERT INTO supplier.country (country_code, country) values ('CL','Sri Lanka');
    INSERT INTO supplier.country (country_code, country) values ('STH','St Helena');
    INSERT INTO supplier.country (country_code, country) values ('WL','St Lucia');
    INSERT INTO supplier.country (country_code, country) values ('WY','St Vincent');
    INSERT INTO supplier.country (country_code, country) values ('SUD','Sudan');
    INSERT INTO supplier.country (country_code, country) values ('SO','Sultanate of Oman');
    INSERT INTO supplier.country (country_code, country) values ('SD','Swaziland');
    INSERT INTO supplier.country (country_code, country) values ('SW','Sweden');
    INSERT INTO supplier.country (country_code, country) values ('CH','Switzerland');
    INSERT INTO supplier.country (country_code, country) values ('SYR','Syria');
    INSERT INTO supplier.country (country_code, country) values ('RC','Taiwan');
    INSERT INTO supplier.country (country_code, country) values ('EAT','Tanzania');
    INSERT INTO supplier.country (country_code, country) values ('T','Thailand');
    INSERT INTO supplier.country (country_code, country) values ('TT','Trinidad and Tobago');
    INSERT INTO supplier.country (country_code, country) values ('TN','Tunisia');
    INSERT INTO supplier.country (country_code, country) values ('TR','Turkey');
    INSERT INTO supplier.country (country_code, country) values ('EAU','Uganda');
    INSERT INTO supplier.country (country_code, country) values ('UKR','Ukraine');
    INSERT INTO supplier.country (country_code, country) values ('UAE','United Arab Emirates');
    INSERT INTO supplier.country (country_code, country) values ('UK','United Kingdom');
    INSERT INTO supplier.country (country_code, country) values ('USA','United States of America');
    INSERT INTO supplier.country (country_code, country) values ('UR','Uruguay');
    INSERT INTO supplier.country (country_code, country) values ('UZB','Uzbekistan');
    INSERT INTO supplier.country (country_code, country) values ('V','Vatican');
    INSERT INTO supplier.country (country_code, country) values ('YV','Venezuela');
    INSERT INTO supplier.country (country_code, country) values ('VN','Vietnam');
    INSERT INTO supplier.country (country_code, country) values ('VI','Virgin Islands');
    INSERT INTO supplier.country (country_code, country) values ('WA','Wales');
    INSERT INTO supplier.country (country_code, country) values ('YU','Yugoslavia');
    INSERT INTO supplier.country (country_code, country) values ('Z','Zambia');
    INSERT INTO supplier.country (country_code, country) values ('EAZ','Zanzibar');
    INSERT INTO supplier.country (country_code, country) values ('ZW','Zimbabwe');
    INSERT INTO supplier.country (country_code, country, means_verified) values ('UN','Unknown', 0); 
	-- needed as Recycled now has country
END;
/
      
BEGIN   
    INSERT INTO supplier.currency (currency_code, label) VALUES ('USD', 'US Dollars');
    INSERT INTO supplier.currency (currency_code, label) VALUES ('EUR', 'Euros');
    INSERT INTO supplier.currency (currency_code, label) VALUES ('GBP', 'Pounds Sterling');
END;
/

	
BEGIN
	INSERT INTO supplier.workflow_type (workflow_type_id, description) VALUES (1 , 'Standard Workflow');
	INSERT INTO supplier.workflow_type (workflow_type_id, description) VALUES (2 , 'Open Workflow');
	INSERT INTO supplier.workflow_type (workflow_type_id, description) VALUES (3 , 'Invite Supplier Workflow');
END;
/

BEGIN
	INSERT INTO supplier.PERIOD (PERIOD_ID, NAME, FROM_DTM, TO_DTM) VALUES (1, 'Calendar Year 2011', To_Date('01/01/2011', 'dd/mm/yyyy'), To_Date('01/01/2012', 'dd/mm/yyyy'));
END;
/
