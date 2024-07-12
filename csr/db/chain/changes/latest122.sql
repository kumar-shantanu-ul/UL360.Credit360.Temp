define version=122
@update_header

ALTER TABLE chain.CUSTOMER_FILTER_TYPE DROP CONSTRAINT FK_CUS_OPT_CUS_FIL_TYPE;
ALTER TABLE chain.CUSTOMER_FILTER_TYPE DROP CONSTRAINT FK_FIL_TYPE_CUS_FIL_TYPE;
ALTER TABLE chain.FILTER DROP CONSTRAINT FK_CUS_FIL_TYPE_FIL_TYPE;

DROP TABLE chain.CUSTOMER_FILTER_TYPE;

DELETE FROM chain.FILTER_TYPE;

ALTER TABLE chain.FILTER_TYPE DROP COLUMN JS_INCLUDE;
ALTER TABLE chain.FILTER_TYPE DROP COLUMN JS_CLASS_TYPE;

ALTER TABLE chain.FILTER_TYPE ADD CARD_ID NUMBER(10,0) NOT NULL;

CREATE UNIQUE INDEX chain.UC_FILTER_TYPE_CARD_ID ON chain.FILTER_TYPE(CARD_ID);

DELETE FROM chain.FILTER;

ALTER TABLE chain.FILTER ADD CONSTRAINT FK_FLT_FLT_TYP 
    FOREIGN KEY (FILTER_TYPE_ID)
    REFERENCES chain.FILTER_TYPE(FILTER_TYPE_ID)
;

ALTER TABLE chain.FILTER_TYPE ADD CONSTRAINT FK_FLT_TYPE_CARD 
    FOREIGN KEY (CARD_ID)
    REFERENCES chain.CARD(CARD_ID)
;

CREATE OR REPLACE VIEW chain.v$filter_type AS
	SELECT f.filter_type_id, f.helper_pkg, c.js_include, c.js_class_type, f.description
	  FROM filter_type f
	  JOIN card c ON f.card_id = c.card_id;


@latest122_packages

BEGIN
	user_pkg.logonadmin;
	
	chain.card_pkg.RegisterCard(
		'Chain Core Company Filter', 
		'Credit360.Chain.Cards.Filters.CompanyCore',
		'/csr/site/chain/cards/filters/companyCore.js', 
		'Chain.Cards.Filters.CompanyCore'
	);
	
	chain.card_pkg.RegisterCardGroup(23, 'Basic Company Filter', 'Allows filtering companies using configurable cards');
	
	chain.filter_pkg.CreateFilterType (
		in_description => 'Chain Core Filter',
		in_helper_pkg => 'chain.company_filter_pkg',
		in_js_class_type => 'Chain.Cards.Filters.CompanyCore'
	);
END;
/

BEGIN
	INSERT INTO csr.alert_type (alert_type_id, description, send_trigger, sent_from) VALUES (5010,
	'Chain questionnaire invitation',
	'A chain invitation to an existing user is created.',
	'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).');
EXCEPTION
	WHEN dup_val_on_index THEN
		UPDATE csr.alert_type SET
			description = 'Chain questionnaire invitation',
			send_trigger = 'A chain invitation to an existing user is created.',
			sent_from = 'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).'
		WHERE alert_type_id = 5010;
END;
/

INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'TO_NAME', 'To full name', 'The name of the user the alert is being sent to', 1);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 3);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'TO_COMPANY', 'To company', 'The company of the user the alert is being sent to', 4);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'FROM_NAME', 'From full name', 'The name of the user the alert is being sent from', 5);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'FROM_FRIENDLY_NAME', 'From friendly name', 'The friendly name of the user the alert is being sent from', 6);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'FROM_EMAIL', 'From e-mail', 'The e-mail address of the user the alert is being sent from', 7);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'FROM_JOBTITLE', 'From jobtitle', 'The job title of the user the alert is being sent from', 8);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'FROM_COMPANY', 'From company', 'The company of the user the alert is being sent from', 9);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'SUBJECT', 'Subject', 'The subject', 10);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'QUESTIONNAIRE_NAME', 'Questionnaire name', 'The questionnaire name', 11);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'QUESTIONNAIRE_DESCRIPTION', 'Questionnaire description', 'The questionnaire description', 12);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'LINK', 'Link', 'A hyperlink to the questionnaire', 13);
INSERT INTO csr.alert_type_param (alert_type_id, repeats, field_name, description, help_text, display_pos)
VALUES (5010, 0, 'EXPIRATION', 'Expiration', 'The date the invitation expires', 14);


@..\report_pkg
@..\filter_pkg
@..\dashboard_pkg
@..\report_body
@..\filter_body
@..\company_filter_body
@..\dashboard_body
@..\rls

grant execute on chain.report_pkg to web_user;

@update_tail
