define version=3169
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE CSR.ENHESA_ERROR_LOG(
	APP_SID				NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	ERROR_LOG_ID		NUMBER(10) NOT NULL,
	ERROR_DTM			DATE NOT NULL,
	ERROR_MESSAGE		VARCHAR2(255) NOT NULL,
	STACK_TRACE			CLOB,
	CONSTRAINT PK_ENHESA_ERROR_LOG_ID PRIMARY KEY (APP_SID, ERROR_LOG_ID)
);
CREATE SEQUENCE CSR.ENHESA_ERROR_LOG_ID_SEQ;
CREATE TABLE CSRIMP.MAP_ENHESA_ERROR_LOG (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ERROR_LOG_ID				NUMBER(10) NOT NULL,
	NEW_ERROR_LOG_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ENHESA_ERROR_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ERROR_LOG_ID),
	CONSTRAINT UK_MAP_ENHESA_ERROR_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_ERROR_LOG_ID),
    CONSTRAINT FK_MAP_ENHESA_ERROR_LOG FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
CREATE TABLE CSRIMP.ENHESA_ERROR_LOG(
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	ERROR_LOG_ID		NUMBER(10) NOT NULL,
	ERROR_DTM			DATE NOT NULL,
	ERROR_MESSAGE		VARCHAR2(255) NOT NULL,
	STACK_TRACE			CLOB,
	CONSTRAINT PK_ENHESA_ERROR_LOG_ID PRIMARY KEY (CSRIMP_SESSION_ID, ERROR_LOG_ID)
);
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


ALTER TABLE CHAIN.BSCI_OPTIONS
ADD (
	PRODUCER_LINKED					NUMBER(1) DEFAULT 1 NOT NULL,
	CONSTRAINT CHK_BSCI_OPTIONS_PROD_LINKED CHECK (PRODUCER_LINKED IN (0,1))
);
ALTER TABLE CSRIMP.CHAIN_BSCI_OPTIONS
ADD PRODUCER_LINKED					NUMBER(1);
ALTER TABLE csr.issue_scheduled_task ADD region_sid NUMBER(10);
ALTER TABLE csr.issue_scheduled_task ADD CONSTRAINT fk_issue_scheduled_task_region 
	FOREIGN KEY (app_sid, region_sid) 
	REFERENCES csr.region (app_sid, region_sid)
;
CREATE INDEX csr.ix_issue_scheduled_task_region ON csr.issue_scheduled_task (app_sid, region_sid); 
ALTER TABLE csrimp.issue_scheduled_task ADD region_sid NUMBER(10);
ALTER TABLE CSR.ENHESA_OPTIONS ADD (
	PACKAGES_IMPORTED	NUMBER(10) DEFAULT 0 NOT NULL,
	PACKAGES_TOTAL		NUMBER(10) DEFAULT 0 NOT NULL,
	ITEMS_IMPORTED		NUMBER(10) DEFAULT 0 NOT NULL,
	ITEMS_TOTAL			NUMBER(10) DEFAULT 0 NOT NULL,
	LINKS_CREATED		NUMBER(10) DEFAULT 0 NOT NULL,
	LINKS_TOTAL			NUMBER(10) DEFAULT 0 NOT NULL
);
ALTER TABLE CSRIMP.ENHESA_OPTIONS ADD (
	PACKAGES_IMPORTED	NUMBER(10) DEFAULT 0 NOT NULL,
	PACKAGES_TOTAL		NUMBER(10) DEFAULT 0 NOT NULL,
	ITEMS_IMPORTED		NUMBER(10) DEFAULT 0 NOT NULL,
	ITEMS_TOTAL			NUMBER(10) DEFAULT 0 NOT NULL,
	LINKS_CREATED		NUMBER(10) DEFAULT 0 NOT NULL,
	LINKS_TOTAL			NUMBER(10) DEFAULT 0 NOT NULL
);
ALTER TABLE csrimp.enhesa_options
MODIFY (
	packages_imported DEFAULT NULL,
	packages_total DEFAULT NULL,
	items_imported DEFAULT NULL,
	items_total DEFAULT NULL,
	links_created DEFAULT NULL,
	links_total DEFAULT NULL
);
ALTER TABLE csr.compliance_alert ADD CONSTRAINT fk_compliance_alert_csr_user
	FOREIGN KEY (app_sid, csr_user_sid)
	REFERENCES csr.csr_user(app_sid, csr_user_sid)
;
CREATE INDEX csr.ix_comp_imp_alert_csr_user ON csr.compliance_alert (app_sid, csr_user_sid);
INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ALERT', 'COMPLIANCE');
INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP', 'COMPLIANCE');
INSERT INTO csr.schema_table (owner, table_name, module_name)
VALUES ('CSR', 'COMPLIANCE_ENHESA_MAP_ITEM', 'COMPLIANCE');


GRANT SELECT, INSERT, UPDATE ON csr.enhesa_error_log TO csrimp;
GRANT SELECT ON csr.enhesa_error_log_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.enhesa_error_log TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.map_enhesa_error_log TO tool_user;








EXEC security.user_pkg.logonadmin('');
BEGIN
	FOR task in (
		SELECT ist.issue_scheduled_task_id, COALESCE(cir.region_sid, cp.region_sid) region_sid, ist.app_sid
		  FROM csr.issue_scheduled_task ist
		  LEFT JOIN csr.comp_item_region_sched_issue cirsi
			ON cirsi.issue_scheduled_task_id = ist.issue_scheduled_task_id AND cirsi.app_sid = ist.app_sid
		  LEFT JOIN csr.compliance_item_region cir
			ON cirsi.flow_item_id = cir.flow_item_id AND cirsi.app_sid = cir.app_sid
		  LEFT JOIN csr.comp_permit_sched_issue cpsi
			ON cpsi.issue_scheduled_task_id = ist.issue_scheduled_task_id AND cpsi.app_sid = ist.app_sid
		  LEFT JOIN csr.compliance_permit cp
			ON cpsi.flow_item_id = cp.flow_item_id AND cpsi.app_sid = cp.app_sid
		 WHERE ist.region_sid IS NULL AND COALESCE(cir.region_sid, cp.region_sid) IS NOT NULL
	)
	LOOP
		UPDATE csr.issue_scheduled_task 
		   SET region_sid = task.region_sid
		 WHERE issue_scheduled_task_id = task.issue_scheduled_task_id
		   AND app_sid = task.app_sid;
	END LOOP;
END;
/
BEGIN
	FOR task_issue in (
		SELECT i.issue_id, COALESCE(cir.region_sid, cp.region_sid) region_sid, i.app_sid
		  FROM csr.issue i
		  LEFT JOIN csr.issue_compliance_region icr
		  ON i.issue_compliance_region_id = icr.issue_compliance_region_id AND i.app_sid = icr.app_sid
		  LEFT JOIN csr.compliance_item_region cir ON icr.flow_item_id = cir.flow_item_id AND icr.app_sid = cir.app_sid
		  LEFT JOIN csr.compliance_permit cp ON i.permit_id = cp.compliance_permit_id AND i.app_sid = cp.app_sid 
		 WHERE i.region_sid IS NULL AND COALESCE(cir.region_sid, cp.region_sid) IS NOT NULL
	)
	LOOP
		UPDATE csr.issue 
		   SET region_sid =  task_issue.region_sid
		 WHERE issue_id = task_issue.issue_id
		   AND app_sid = task_issue.app_sid;
	END LOOP;
END;
/
INSERT INTO csr.module (module_id, module_name, enable_sp, description)
VALUES (103, 'API Values', 'EnableValuesApi', 'Enables the Values Api.');
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




create or replace package csr.indicator_api_pkg as end;
/
grant execute on csr.indicator_api_pkg to web_user;
create or replace package csr.measure_api_pkg as end;
/
grant execute on csr.measure_api_pkg to web_user;


@..\indicator_api_pkg
@..\chain\bsci_pkg
@..\measure_pkg
@..\issue_pkg
@..\enable_pkg
@..\compliance_pkg
@..\schema_pkg
@..\measure_api_pkg
@..\quick_survey_pkg
@..\chain\company_filter_pkg
@..\chain\product_report_pkg
@..\chain\product_supplier_report_pkg
@..\schema_pkg 


@..\indicator_api_body
@..\chain\bsci_body
@..\csrimp\imp_body
@..\schema_body
@..\measure_body
@..\campaign_body
@..\issue_body
@..\permit_body
@..\compliance_body
@..\compliance_register_report_body
@..\permit_report_body
@..\enable_body
@..\measure_api_body
@..\quick_survey_body
@..\audit_body
@..\audit_report_body
@..\chain\activity_report_body
@..\chain\business_rel_report_body
@..\chain\company_filter_body
@..\chain\certification_report_body
@..\chain\product_report_body
@..\chain\product_supplier_report_body



@update_tail
