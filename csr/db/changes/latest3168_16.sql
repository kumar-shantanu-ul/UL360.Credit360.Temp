-- Please update version.sql too -- this keeps clean builds in sync
define version=3168
define minor_version=16
@update_header

-- *** DDL ***
-- Create tables

CREATE TABLE csr.compliance_alert(
	compliance_alert_id		NUMBER(10, 0)	NOT NULL,
	app_sid					NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	csr_user_sid			NUMBER(10)		NOT NULL,
	sent_dtm				DATE			NOT NULL,
	CONSTRAINT pk_compliance_imp_alert PRIMARY KEY (app_sid, compliance_alert_id)
)
;

CREATE SEQUENCE csr.compliance_alert_id_seq;

CREATE TABLE csr.compliance_enhesa_map (
	app_sid NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	enhesa_country CHAR(3) NOT NULL,
	enhesa_region CHAR(3) NOT NULL,
	alert_sent DATE NULL,
	CONSTRAINT pk_compliance_enhesa_map
		PRIMARY KEY (app_sid, enhesa_country, enhesa_region)
);

CREATE TABLE csr.compliance_enhesa_map_item (
	app_sid NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	enhesa_country CHAR(3) NOT NULL,
	enhesa_region CHAR(3) NOT NULL,
	region_sid NUMBER(10, 0) NOT NULL,
	CONSTRAINT pk_compliance_enhesa_map_item
		PRIMARY KEY (app_sid, enhesa_country, enhesa_region, region_sid),
	CONSTRAINT fk_compliance_ehesa_mp_it_par
		FOREIGN KEY (app_sid, enhesa_country, enhesa_region)
		REFERENCES csr.compliance_enhesa_map (app_sid, enhesa_country, enhesa_region),
	CONSTRAINT fk_compliance_enhesa_mp_it_r
		FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.region (app_sid, region_sid)
);

CREATE INDEX csr.compliance_enhesa_map_item_re ON csr.compliance_enhesa_map_item (app_sid, region_sid);

ALTER TABLE csr.compliance_item_rollout ADD (
	source_region CHAR(3) NULL,
	source_country CHAR(3) NULL
);

ALTER TABLE csrimp.compliance_item_rollout ADD (
	source_region CHAR(3) NULL,
	source_country CHAR(3) NULL
);

-- Alter tables

ALTER TABLE csr.compliance_alert ADD CONSTRAINT fk_compliance_alert_csr_user
	FOREIGN KEY (app_sid, csr_user_sid)
	REFERENCES csr.csr_user(app_sid, csr_user_sid)
;

CREATE INDEX csr.ix_comp_imp_alert_csr_user ON csr.compliance_alert (app_sid, csr_user_sid);

--csrimp
INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ALERT', 'COMPLIANCE');

INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP', 'COMPLIANCE');

INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP_ITEM', 'COMPLIANCE');

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data

DECLARE 
	v_imp_alert_id				NUMBER(2) := 78;
	v_roll_out_alert_id			NUMBER(2) := 79;
	v_alert_group				NUMBER(2) := 15;
	v_frame_id					NUMBER(2);
	v_customer_alert_type_id	NUMBER(10);
	v_alert_frame_exists	 	NUMBER;
BEGIN

	security.user_pkg.logonadmin('');
	--Add group
	INSERT INTO csr.std_alert_type_group (std_alert_type_group_id, description) 
	VALUES (15, 'Compliance');

	--Add alerts
	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
	VALUES (
			v_imp_alert_id, 
			'Enhesa import failure',
			'The Enhesa import has failed.',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
			v_alert_group);

	INSERT INTO csr.std_alert_type (std_alert_type_id, description, send_trigger, sent_from, std_alert_type_group_id)
	VALUES (
			v_roll_out_alert_id, 
			'Compliance items rollout failure',
			'Compliance items rollout has failed.',
			'The configured system e-mail address (this defaults to support@credit360.com, but can be changed from the site setup page).',
			v_alert_group);

	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'ERROR_MESSAGE', 'Error message', 'Error generated for the import failure', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_imp_alert_id, 0, 'IMPORT_LINK', 'Link to Enhesa settings', 'Link to Enhesa settings page', 6);
	
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'TO_NAME', 'To full name', 'The full name of the user the alert is being sent to', 1);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'TO_FRIENDLY_NAME', 'To friendly name', 'The friendly name of the user the alert is being sent to', 2);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'TO_USER_NAME', 'To user name', 'The user name of the user the alert is being sent to', 3);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'TO_EMAIL', 'To e-mail', 'The e-mail address of the user the alert is being sent to', 4);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'UNMAPPED_REGIONS', 'Unmapped Enhesa region items', 'Enhesa region items that with no mapping to regions in cr360', 5);
	INSERT INTO csr.std_alert_type_param (std_alert_type_id, repeats, field_name, description, help_text, display_pos)
	VALUES (v_roll_out_alert_id, 0, 'MAPPING_LINK', 'Link to Enhesa mapping page', 'Link to Enhesa mapping page', 6);
	
	--Add default template
	SELECT MAX(default_alert_frame_id) 
	  INTO v_frame_id
	  FROM csr.default_alert_frame;

	INSERT INTO csr.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (v_imp_alert_id, v_frame_id, 'inactive');

	INSERT INTO csr.default_alert_template (std_alert_type_id, default_alert_frame_id, send_type)
	VALUES (v_roll_out_alert_id, v_frame_id, 'inactive');
	
	--Enable alerts to sites with compliance
	-- XXX: DO NOT COPY THIS, THERE IS A BUG WITH THE ALERT_FRAME CREATION, SEE UPDATED util_script_body INSTEAD
	FOR r IN(
		SELECT c.host, c.app_sid FROM csr.customer c
		  JOIN csr.compliance_options co ON co.app_sid = c.app_sid
		 WHERE requirement_flow_sid IS NOT NULL
			OR regulation_flow_sid IS NOT NULL
	)
	LOOP
		security.user_pkg.logonadmin(r.host);
		FOR alert IN (
			SELECT std_alert_type_id 
			  FROM csr.std_alert_type
			 WHERE std_alert_type_group_id = v_alert_group
		)
		LOOP 
			SELECT csr.customer_alert_type_id_seq.nextval
			  INTO v_customer_alert_type_id
			  FROM dual;
				
			INSERT INTO csr.customer_alert_type (customer_alert_type_id, std_alert_type_id)
			VALUES (v_customer_alert_type_id, alert.std_alert_type_id);

			SELECT COUNT(alert_frame_id) INTO v_alert_frame_exists
			  FROM csr.alert_frame
			 WHERE app_sid = r.app_sid
			   AND alert_frame_id = (
					SELECT default_alert_frame_id
					  FROM csr.default_alert_template
					 WHERE std_alert_type_id = alert.std_alert_type_id
				 );
			 
			IF v_alert_frame_exists = 0 THEN
				INSERT INTO csr.alert_frame (app_sid, alert_frame_id, name)
					 SELECT r.app_sid, default_alert_frame_id, 'Default'
					   FROM csr.default_alert_template
					  WHERE std_alert_type_id = alert.std_alert_type_id;
			END IF;
			
			INSERT INTO csr.alert_template (app_sid, customer_alert_type_id, alert_frame_id, send_type)
			SELECT r.app_sid, v_customer_alert_type_id, default_alert_frame_id, 'inactive' send_type
			  FROM csr.default_alert_template
			 WHERE std_alert_type_id = alert.std_alert_type_id;
			
			FOR l IN (
			SELECT lang
			  FROM aspen2.translation_set
			 WHERE application_sid = r.app_sid
			)
			LOOP
				INSERT INTO csr.alert_template_body (app_sid, customer_alert_type_id, lang, subject, body_html, item_html)
					 SELECT r.app_sid, v_customer_alert_type_id, l.lang, subject, body_html, item_html
					   FROM csr.default_alert_template_body
					  WHERE std_alert_type_id = alert.std_alert_type_id;
			END LOOP;
		END LOOP;
	END LOOP;

	security.user_pkg.logonadmin('');
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../schema_pkg 
@../compliance_pkg

@../compliance_body
@../schema_body
@../csrimp/imp_body
@../enable_body

@update_tail
