BEGIN
	INSERT INTO donations.customer_filter_flag
		(app_sid, recipient_region_group, browse_region_group, report_region_group)
		(SELECT app_sid, 0, 0, 0 FROM csr.customer);
END;
/

BEGIN
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'GBP', unistr('\20A4'), 'British Pound'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'CZK', 'Kc', 'Czech Republic Korun'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'EUR', unistr('\20AC'), 'Euro'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'RUB', NULL, 'Russian Rubles'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'NOK', 'kr', 'Norwegian Kroner'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'AUD', '$', 'Australian Dollar'); 
INSERT INTO donations.CURRENCY ( CURRENCY_CODE, SYMBOL, LABEL ) VALUES ( 'USD', '$', 'US Dollar'); 
END;
/

BEGIN
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (80,'Donation',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (81,'Budget',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (82,'Scheme',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (83,'Status',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (84,'Category',1);
	INSERT INTO CSR.AUDIT_TYPE (AUDIT_TYPE_ID,LABEL,AUDIT_TYPE_GROUP_ID) values (85,'Recipient',1);
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

/* alert types -- for csr */
DECLARE
	ALERT_GROUP_CMS	NUMBER(10) := 13;
BEGIN
	BEGIN
		INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id) 
		VALUES(40, 'Funding Commitment Reminder', 
			'Reminder date on Funding Commitment Setup.',
			'The configured system e-mail address (this defaults to no-reply@cr360.com, but can be changed from the site setup page).',
			ALERT_GROUP_CMS
		);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
END;
/

BEGIN
INSERT INTO CSR.CAPABILITY (NAME, ALLOW_BY_DEFAULT) VALUES ('Configure Community Involvement module', 0);
END;
/

COMMIT;

