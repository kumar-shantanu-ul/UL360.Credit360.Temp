define version=3061
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

CREATE TABLE chain.pend_company_suggested_match (
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	pending_company_sid 		NUMBER(10) NOT NULL,
	matched_company_sid			NUMBER(10) NOT NULL,
	dedupe_rule_set_id			NUMBER(10) NULL,
	CONSTRAINT pk_pend_company_suggestd_match PRIMARY KEY (app_sid, pending_company_sid, matched_company_sid)
);
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT chk_pend_company_matched_ne 
	CHECK (pending_company_sid != matched_company_sid);
		
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_company_sugg_match
	FOREIGN KEY (app_sid, pending_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_matched_company
	FOREIGN KEY (app_sid, matched_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.pend_company_suggested_match ADD CONSTRAINT fk_pend_rule_set_id
	FOREIGN KEY (app_sid, dedupe_rule_set_id) REFERENCES chain.dedupe_rule_set (app_sid, dedupe_rule_set_id);
CREATE TABLE chain.pending_company_tag(
	app_sid 					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	pending_company_sid			NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_pending_company_tag PRIMARY KEY (app_sid, pending_company_sid, tag_id)
);
		
ALTER TABLE chain.pending_company_tag ADD CONSTRAINT fk_pend_company_tag_comp
	FOREIGN KEY (app_sid, pending_company_sid) REFERENCES chain.company (app_sid, company_sid);
CREATE TABLE csrimp.chain_pend_cmpny_suggstd_match (
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	pending_company_sid			NUMBER(10) NOT NULL,
	matched_company_sid			NUMBER(10) NOT NULL,
	dedupe_rule_set_id			NUMBER(10) NULL,
	CONSTRAINT pk_pend_cmpny_suggstd_match PRIMARY KEY (csrimp_session_id, pending_company_sid, matched_company_sid),
	CONSTRAINT fk_pend_cmpny_suggstd_match_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
ALTER TABLE csrimp.chain_pend_cmpny_suggstd_match ADD CONSTRAINT chk_pend_company_matched_ne 
	CHECK (pending_company_sid != matched_company_sid);
CREATE TABLE csrimp.chain_pending_company_tag(
	csrimp_session_id			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	pending_company_sid 		NUMBER(10) NOT NULL,
	tag_id						NUMBER(10) NOT NULL,
	CONSTRAINT pk_chain_pending_company_tag PRIMARY KEY (csrimp_session_id, pending_company_sid, tag_id),
	CONSTRAINT fk_chain_pending_cmpny_tag_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
	
CREATE TABLE chain.saved_filter_column (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	column_name						VARCHAR2(255) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	width							NUMBER(10),
	CONSTRAINT pk_saved_filter_column PRIMARY KEY (app_sid, saved_filter_sid, column_name),
	CONSTRAINT fk_saved_fltr_col_saved_fltr FOREIGN KEY (app_sid, saved_filter_sid)
		REFERENCES chain.saved_filter (app_sid, saved_filter_sid)
);
CREATE TABLE csrimp.chain_saved_filter_column (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	saved_filter_sid				NUMBER(10) NOT NULL,
	column_name						VARCHAR2(255) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	width							NUMBER(10),
	CONSTRAINT pk_chain_saved_filter_column PRIMARY KEY (csrimp_session_id, saved_filter_sid, column_name),
	CONSTRAINT fk_chain_saved_fltr_col_is FOREIGN KEY
		(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);
CREATE TABLE csr.compliance_permit_history (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	prev_permit_id					NUMBER(10,0) NOT NULL,
	next_permit_id					NUMBER(10,0) NOT NULL,
	CONSTRAINT pk_compliance_permit_history PRIMARY KEY (app_sid, prev_permit_id, next_permit_id)
);


ALTER TABLE chain.dedupe_staging_link ADD is_owned_by_system NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_staging_link MODIFY staging_tab_sid NULL;
ALTER TABLE chain.dedupe_staging_link MODIFY staging_id_col_sid NULL;
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT chk_is_owned_by_system_st CHECK (is_owned_by_system IN (0,1));
ALTER TABLE chain.dedupe_staging_link ADD CONSTRAINT chk_system_tab_col 
	CHECK ((is_owned_by_system = 0 AND staging_tab_sid IS NOT NULL AND staging_id_col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND staging_tab_sid IS NULL AND staging_id_col_sid IS NULL));
CREATE UNIQUE INDEX chain.uk_staging_system_owned ON chain.dedupe_staging_link (CASE WHEN is_owned_by_system = 1 THEN app_sid END);
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD is_owned_by_system NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_stagin_link MODIFY staging_tab_sid NULL;
ALTER TABLE csrimp.chain_dedupe_stagin_link MODIFY staging_id_col_sid NULL;
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD CONSTRAINT chk_is_owned_by_system_st CHECK (is_owned_by_system IN (0,1));
ALTER TABLE csrimp.chain_dedupe_stagin_link ADD CONSTRAINT chk_system_tab_col 
	CHECK ((is_owned_by_system = 0 AND staging_tab_sid IS NOT NULL AND staging_id_col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND staging_tab_sid IS NULL AND staging_id_col_sid IS NULL));
ALTER TABLE chain.dedupe_mapping ADD is_owned_by_system NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.dedupe_mapping MODIFY tab_sid NULL;
ALTER TABLE chain.dedupe_mapping MODIFY col_sid NULL;
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_is_owned_by_system_map CHECK (is_owned_by_system IN (0,1));
ALTER TABLE chain.dedupe_mapping ADD CONSTRAINT chk_system_mapping_tab_col 
	CHECK ((is_owned_by_system = 0 AND tab_sid IS NOT NULL AND col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND tab_sid IS NULL AND col_sid IS NULL));
ALTER TABLE chain.dedupe_mapping DROP CONSTRAINT uc_dedupe_mapping_tab_col;
CREATE UNIQUE INDEX chain.uk_dedupe_mapping ON chain.dedupe_mapping (app_sid, dedupe_staging_link_id, tab_sid, CASE WHEN is_owned_by_system = 0 THEN col_sid ELSE dedupe_mapping_id END);
ALTER TABLE csrimp.chain_dedupe_mapping ADD is_owned_by_system NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_dedupe_mapping MODIFY tab_sid NULL;
ALTER TABLE csrimp.chain_dedupe_mapping MODIFY col_sid NULL;
ALTER TABLE csrimp.chain_dedupe_mapping ADD CONSTRAINT chk_is_owned_by_system_map CHECK (is_owned_by_system IN (0,1));
ALTER TABLE csrimp.chain_dedupe_mapping ADD CONSTRAINT chk_system_mapping_tab_col 
	CHECK ((is_owned_by_system = 0 AND tab_sid IS NOT NULL AND col_sid IS NOT NULL) 
		OR (is_owned_by_system = 1 AND tab_sid IS NULL AND col_sid IS NULL));
ALTER TABLE chain.company ADD requested_by_company_sid	NUMBER(10);
ALTER TABLE chain.company ADD requested_by_user_sid		NUMBER(10);
ALTER TABLE chain.company ADD pending					NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.company ADD CONSTRAINT chk_pending CHECK (pending IN (0,1));
ALTER TABLE chain.company ADD CONSTRAINT fk_company_request_by_company
	FOREIGN KEY (app_sid, requested_by_company_sid) REFERENCES chain.company (app_sid, company_sid);
	
CREATE INDEX chain.ix_requested_by_company_sid ON chain.company (app_sid, requested_by_company_sid);
	
CREATE INDEX chain.ix_requested_by_user_sid ON chain.company (app_sid, requested_by_user_sid);
ALTER TABLE csrimp.chain_company ADD requested_by_company_sid	NUMBER(10);
ALTER TABLE csrimp.chain_company ADD requested_by_user_sid		NUMBER(10);
ALTER TABLE csrimp.chain_company ADD pending					NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_company ADD CONSTRAINT chk_pending CHECK (pending IN (0,1));
ALTER TABLE chain.customer_options ADD enable_dedupe_onboarding NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE chain.customer_options ADD CONSTRAINT chk_enable_dedupe_onboarding CHECK (enable_dedupe_onboarding IN (0,1));
ALTER TABLE csrimp.chain_customer_options ADD enable_dedupe_onboarding NUMBER(1) NOT NULL;
ALTER TABLE csrimp.chain_customer_options ADD CONSTRAINT chk_enable_dedupe_onboarding CHECK (enable_dedupe_onboarding IN (0,1));
create index chain.ix_pending_compa_tag_id on chain.pending_company_tag (app_sid, tag_id);
create index chain.ix_pend_company__dedupe_rule_s on chain.pend_company_suggested_match (app_sid, dedupe_rule_set_id);
create index chain.ix_pend_company__matched_compa on chain.pend_company_suggested_match (app_sid, matched_company_sid);
DECLARE
	v_count NUMBER(10);
BEGIN
		
	SELECT COUNT(*)
	  INTO v_count
	  FROM ALL_TAB_COLUMNS
	 WHERE table_name = 'SCORE_THRESHOLD'
	   AND COLUMN_NAME = 'LOOKUP_KEY';
	   
	IF v_count = 0 THEN
		EXECUTE IMMEDIATE 'ALTER TABLE csr.score_threshold ADD lookup_key VARCHAR2(255)';
		EXECUTE IMMEDIATE 'ALTER TABLE csrimp.score_threshold ADD lookup_key VARCHAR2(255)';
		
		EXECUTE IMMEDIATE 'CREATE UNIQUE INDEX CSR.UK_SCORE_THRESH_LOOKUP_KEY ON CSR.SCORE_THRESHOLD(APP_SID, SCORE_TYPE_ID, NVL(UPPER(LOOKUP_KEY),TO_CHAR(SCORE_THRESHOLD_ID)))';
	END IF;
END;
/
ALTER TABLE csr.internal_audit_locked_tag DROP CONSTRAINT pk_ia_locked_tag;
ALTER TABLE csr.internal_audit_locked_tag ADD CONSTRAINT uk_ia_locked_tag UNIQUE (app_sid, internal_audit_sid, tag_group_id, tag_id);
ALTER TABLE csr.compliance_options ADD (
	condition_flow_sid	NUMBER(10,0) NULL
);
ALTER TABLE csrimp.compliance_options ADD (
	condition_flow_sid	NUMBER(10,0) NULL
);
ALTER TABLE csr.compliance_options ADD CONSTRAINT fk_co_con_flow 
	FOREIGN KEY (app_sid, condition_flow_sid) 
	REFERENCES csr.flow (app_sid, flow_sid);
CREATE INDEX csr.ix_compliance_op_condition_f ON csr.compliance_options (app_sid, condition_flow_sid);
DROP INDEX CHAIN.COMPANY_PRODUCT_LOOKUP;
CREATE UNIQUE INDEX CHAIN.COMPANY_PRODUCT_LOOKUP
ON CHAIN.COMPANY_PRODUCT (APP_SID, LOWER(NVL(LOOKUP_KEY, 'NOLOOKUPKEY_' || PRODUCT_ID)));
ALTER TABLE chain.saved_filter ADD (
	order_by						VARCHAR2(255),
	order_direction					VARCHAR2(4),
	results_per_page				NUMBER(10)
);
ALTER TABLE csrimp.chain_saved_filter ADD (
	order_by						VARCHAR2(255),
	order_direction					VARCHAR2(4),
	results_per_page				NUMBER(10)
);
ALTER TABLE csr.batch_job_type
ADD timeout_mins NUMBER(4);
ALTER TABLE CSR.BATCH_JOB_TYPE_APP_CFG
ADD timeout_mins NUMBER(4);
ALTER TABLE csr.batch_job_type
RENAME COLUMN notify_after_attempts TO max_retries;
ALTER TABLE csr.batch_job
ADD timed_out NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.batch_job
ADD CONSTRAINT ck_batch_job_timed_out CHECK (timed_out IN (0, 1));
ALTER TABLE csr.batch_job
ADD ignore_timeout NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.batch_job
ADD CONSTRAINT ck_batch_job_ignore_timeout CHECK (ignore_timeout IN (0, 1));
ALTER TABLE csr.compliance_item
ADD compliance_item_type NUMBER(10);
UPDATE csr.compliance_item ci
  SET ci.compliance_item_type = (
	  SELECT NVL2(creq.compliance_item_id, 0, NVL2(creg.compliance_item_id, 1, NVL2(cc.compliance_item_id, 2, 0))) compliance_type
	    FROM csr.compliance_item ci2
	    LEFT JOIN csr.compliance_regulation creg on ci2.compliance_item_id = creg.compliance_item_id
	    LEFT JOIN csr.compliance_requirement creq on ci2.compliance_item_id = creq.compliance_item_id
	    LEFT JOIN csr.compliance_permit_condition cc on ci2.compliance_item_id = cc.compliance_item_id
	   WHERE ci.compliance_item_id = ci2.compliance_item_Id
);
ALTER TABLE csr.compliance_item
MODIFY compliance_item_type NOT NULL;
ALTER TABLE csrimp.compliance_item
ADD compliance_item_Type NUMBER(10) NOT NULL;
DROP INDEX csr.uk_compliance_item_ref;
CREATE UNIQUE INDEX csr.uk_compliance_item_ref ON csr.compliance_item (
	app_sid, DECODE(compliance_item_type, 2, TO_CHAR("COMPLIANCE_ITEM_ID"), DECODE("SOURCE", 0, NVL("REFERENCE_CODE", TO_CHAR("COMPLIANCE_ITEM_ID")), TO_CHAR("COMPLIANCE_ITEM_ID")))
);
ALTER TABLE chain.product_supplier_tab
	ADD (
			purchaser_company_col_sid	NUMBER(10, 0),
			supplier_company_col_sid	NUMBER(10, 0),
			product_col_sid				NUMBER(10, 0),
			user_company_col_sid		NUMBER(10, 0)
		);
ALTER TABLE csr.automated_import_instance
ADD debug_log_file BLOB;
ALTER TABLE csr.automated_import_instance
ADD session_log_file BLOB;
ALTER TABLE csr.automated_export_instance
ADD debug_log_file BLOB;
ALTER TABLE csr.automated_export_instance
ADD session_log_file BLOB;


grant select on chain.pend_company_suggested_match to csr;
grant select, insert, update on chain.pend_company_suggested_match to csrimp;
grant select, insert, update, delete on csrimp.chain_pend_cmpny_suggstd_match to tool_user;
grant select on chain.pending_company_tag to csr;
grant select, insert, update on chain.pending_company_tag to csrimp;
grant select, insert, update, delete on csrimp.chain_pending_company_tag to tool_user;
grant select, insert, update, delete on csrimp.chain_saved_filter_column to tool_user;
grant select, insert, update on chain.saved_filter_column to csrimp;
grant select on chain.saved_filter_column to csr;


	
ALTER TABLE chain.pending_company_tag ADD CONSTRAINT fk_pend_company_tag_tag
	FOREIGN KEY (app_sid, tag_id) REFERENCES csr.tag (app_sid, tag_id);
ALTER TABLE chain.company ADD CONSTRAINT fk_company_requested_by_user
	FOREIGN KEY (app_sid, requested_by_user_sid) REFERENCES csr.csr_user (app_sid, csr_user_sid);


BEGIN
	security.user_pkg.logonadmin(NULL);
	
	INSERT INTO chain.dedupe_staging_link (app_sid, dedupe_staging_link_id, import_source_id, 
		description, position, is_owned_by_system)
	SELECT app_sid, chain.dedupe_staging_link_id_seq.nextval, import_source_id,
		'System managed staging', 1, 1
	  FROM chain.import_source
	 WHERE is_owned_by_system = 1;
END;
/




UPDATE csr.batch_job_type
   SET sp = NULL, plugin_name = 'batch-exporter'
 WHERE batch_job_type_id = 59;
 
BEGIN
	UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE™ Platform by UL EHS Sustainability</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;">our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
END;
/
DELETE FROM csr.branding_availability
 WHERE client_folder_name = 'sabmillerbvd';
DELETE FROM csr.branding
 WHERE client_folder_name = 'sabmillerbvd';
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (41, 8, 'Number of actions closed on time');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (41, 9, 'Number of actions closed overdue');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/
BEGIN
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (42, 8, 'Number of actions closed on time');
	INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description) VALUES (42, 9, 'Number of actions closed overdue');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE™ Platform by UL EHS Sustainability</div>'||
		'<table border="0">'||
		'<tbody>'||
		'<tr>'||
		'<td style="font-family:Verdana,Arial;color:#333333;font-size:10pt;line-height:1.25em;padding-right:10px;">'||
		'<mergefield name="BODY" />'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;"> our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
END;
/
INSERT INTO csr.flow_alert_class (flow_alert_class, label, helper_pkg) VALUES ('condition', 'Condition', 'csr.permit_pkg');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (26, 'condition', 'Not created');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (27, 'condition', 'Active');
INSERT INTO csr.flow_state_nature (FLOW_STATE_NATURE_ID, FLOW_ALERT_CLASS, LABEL) VALUES (28, 'condition', 'Inactive');
DECLARE
	v_chain_users_group_sid		security.security_pkg.T_SID_ID;
	v_act_id 					security.security_pkg.T_ACT_ID;
BEGIN
	security.user_pkg.LogOnAdmin;
	FOR r IN (
		SELECT c.app_sid, c.host, cu.csr_user_sid
		  FROM csr.csr_user cu
		  JOIN csr.customer c ON cu.app_sid = c.app_sid
		 WHERE user_name = 'Invitation Respondent'
	) LOOP
		security.user_pkg.LogOnAdmin(r.host);
		v_act_id := security.security_pkg.GetAct;
		BEGIN
			v_chain_users_group_sid := security.securableobject_pkg.GetSIDFromPath(v_act_id, r.app_sid, 'Groups/Chain Users');
			security.group_pkg.AddMember(v_act_id, r.csr_user_sid, v_chain_users_group_sid);
		EXCEPTION
			WHEN security.security_pkg.OBJECT_NOT_FOUND THEN
				NULL;
		END;
		security.user_pkg.LogOff(v_act_id);
	END LOOP;
END;
/
BEGIN
	UPDATE csr.batch_job_type
	   SET timeout_mins = 120; -- 2 hours
	
	-- Metering and automated imports
	UPDATE csr.batch_job_type
	   SET timeout_mins = 360 -- 6 hours	
	 WHERE batch_job_type_id IN (10, 13, 19, 23, 24, 50, 53, 55, 56, 57);
END;
/
BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (31, 'Modify batch job timeout', 'Changes the timeout for a batchjob type for the current app.','SetBatchJobTimeoutOverride',NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) 
	VALUES (31, 'Batch job type id', 'Batch job type id', 0, NULL);
	INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) 
	VALUES (31, 'Timeout mins', 'Minutes the job can run for before it times out.', 1, NULL);
END;
/
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (32, 'Show / Hide Delegation Plan', 'Sets the active flag on delegation plans to hide or show them in the UI.','ShowHideDelegPlan', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (32, 'Delegation plan sid', 'The sid of the delegation plan you want to show/hide', 0, 'DELEG_SID');
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (32, 'Hide/Show (0 hide, 1 show)', 'The setting to use', 1, '0');
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (csr.plugin_id_seq.nextval, 21, 'Permit applications tab', '/csr/site/compliance/controls/PermitApplicationTab.js', 'Credit360.Compliance.Controls.PermitApplicationTab', 'Credit360.Compliance.Plugins.PermitApplicationTab', 'Shows all of the applications for a permit.');
DECLARE
	v_plugin_id						NUMBER;
BEGIN 
	security.user_pkg.logonadmin();
	
	SELECT plugin_id
	  INTO v_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Compliance.Controls.PermitApplicationTab';
	
	FOR r IN (
		SELECT co.app_sid, c.host
		  FROM csr.compliance_options co 
		  JOIN csr.customer c ON co.app_sid = c.app_sid
		 WHERE permit_flow_sid IS NOT NULL
	) LOOP
		BEGIN
			security.user_pkg.logonadmin(r.host);
		
			INSERT INTO csr.compliance_permit_tab (plugin_type_id, plugin_id, pos, tab_label)
				VALUES (21, v_plugin_id, 2, 'Applications');
				
			-- default access
			INSERT INTO csr.compliance_permit_tab_group (plugin_id, group_sid)
				 VALUES (
					v_plugin_id, 
					security.securableobject_pkg.GetSidFromPath(
						security.security_pkg.GetAct, 
						r.app_sid, 
						'groups/RegisteredUsers'
					)
				);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				UPDATE csr.compliance_permit_tab
				   SET tab_label = 'Applications',
					   pos = 2
				 WHERE plugin_id = v_plugin_id;
		END;
	END LOOP;
	
	security.user_pkg.logonadmin();
END;
/
INSERT INTO csr.plugin (plugin_id, plugin_type_id, description, js_include, js_class, cs_class, details)
VALUES (
	csr.plugin_id_seq.NEXTVAL, 21, 
	'Permit conditions tab', 
	'/csr/site/compliance/controls/PermitConditionsTab.js', 
	'Credit360.Compliance.Controls.PermitConditionsTab', 
	'Credit360.Compliance.Plugins.PermitConditionsTab', 
	'Shows permit conditions.'
);
INSERT INTO CSR.USER_SETTING (CATEGORY, SETTING, DATA_TYPE, DESCRIPTION) VALUES ('CREDIT360.COMPLIANCE.PERMIT', 'activeTab', 'STRING', 'Stores the last active plugin tab');
DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	v_desc := 'Product Supplier Filter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierFilter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierFilter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierFilter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action NOT IN ('default');
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
	
	v_desc := 'Product Supplier Company Filter Adapter';
	v_class := 'Credit360.Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter';
	v_js_path := '/csr/site/chain/cards/filters/productSupplierCompanyFilterAdapter.js';
	v_js_class := 'Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter';
	v_css_path := '';
	
	BEGIN
		INSERT INTO chain.card (card_id, description, class_type, js_include, js_class_type, css_include)
		VALUES (chain.card_id_seq.NEXTVAL, v_desc, v_class, v_js_path, v_js_class, v_css_path)
		RETURNING card_id INTO v_card_id;
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE chain.card
			   SET description = v_desc, class_type = v_class, js_include = v_js_path, css_include = v_css_path
			 WHERE js_class_type = v_js_class
			RETURNING card_id INTO v_card_id;
	END;
	
	DELETE FROM chain.card_progression_action
	 WHERE card_id = v_card_id
	   AND action <> 'default';
	
	v_actions := chain.T_STRING_LIST('default');
	
	FOR i IN v_actions.FIRST .. v_actions.LAST
	LOOP
		BEGIN
			INSERT INTO chain.card_progression_action (card_id, action)
			VALUES (v_card_id, v_actions(i));
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/
DECLARE
	v_card_id	NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, 'Product Supplier Filter', 'Allows filtering of product suppliers', 'chain.product_supplier_report_pkg', NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Filter', 'chain.product_supplier_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	-- setup filter card for all sites with products
	FOR r IN (
		SELECT DISTINCT app_sid
		  FROM chain.customer_options
		 WHERE enable_product_compliance = 1
	) LOOP
		INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
		VALUES (r.app_sid, 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, v_card_id, 0);
	END LOOP;
	
	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.Cards.Filters.ProductSupplierCompanyFilterAdapter';
	
	BEGIN
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		VALUES (chain.filter_type_id_seq.NEXTVAL, 'Product Supplier Company Filter Adapter', 'chain.product_supplier_report_pkg', v_card_id);
	EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT DISTINCT app_sid, NVL(MAX(position) + 1, 1) pos
		  FROM chain.card_group_card
		 WHERE card_group_id = 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/
		 GROUP BY app_sid
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position, required_permission_set, required_capability_id)
			VALUES (r.app_sid, 60 /*chain.filter_pkg.FILTER_TYPE_PROD_SUPPLIER*/, v_card_id, r.pos, NULL, NULL);
			EXCEPTION
		WHEN dup_val_on_index THEN
			NULL;
		END;
	END LOOP;
END;
/
UPDATE csr.plugin
   SET js_class = 'Controls.IssuesPanel'
 WHERE js_class = 'Credit360.Property.Plugins.IssuesPanel';
BEGIN
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_ID', 'Product Id', 0, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_TYPE_ID', 'Product Type Id', 0, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_TYPE', 'Product Type', 1, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'COMPANY', 'Company', 1, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'IS_ACTIVE', 'Active', 0, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'PRODUCT_NAME', 'Product Name', 1, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'COMPANY_SID', 'Company Sid', 0, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'SKU', 'SKU', 0, NULL);
	INSERT INTO chain.saved_filter_alert_param (CARD_GROUP_ID, FIELD_NAME, DESCRIPTION, TRANSLATABLE, LINK_TEXT)
	VALUES (56, 'LOOKUP_KEY', 'Lookup Key', 0, NULL);
END;
/


begin
	for r in (select * from all_objects where owner='CHAIN' and object_name='TEST_DEDUPE_MULTISOURCE_PKG' and object_type='PACKAGE') loop
		execute immediate 'drop package chain.test_dedupe_multisource_pkg';
	end loop;
end;
/
CREATE OR REPLACE PACKAGE chain.product_supplier_report_pkg AS END;
/
GRANT EXECUTE ON chain.product_supplier_report_pkg TO web_user;
GRANT EXECUTE ON chain.business_relationship_pkg TO csr;




@..\chain\product_type_pkg
@..\permit_pkg
@..\compliance_pkg
@..\section_pkg
@..\audit_report_pkg
@..\non_compliance_report_pkg
@..\meter_report_pkg
@..\chain\dedupe_admin_pkg
@..\chain\company_pkg
@..\chain\company_dedupe_pkg
@..\chain\helper_pkg
@..\schema_pkg
@..\csrimp\imp_pkg
@ ..\quick_survey_pkg
@..\compliance_setup_pkg
@..\chain\company_product_pkg
@..\chain\filter_pkg
@..\chain\invitation_pkg
@..\supplier\greentick\product_info_pkg
@..\batch_job_pkg
@..\util_script_pkg
@..\measure_pkg
@..\tag_pkg
@..\chain\plugin_pkg
@..\chain\product_supplier_report_pkg
@..\chain\product_report_pkg
@..\automated_import_pkg
@..\automated_export_pkg


@..\chain\product_type_body
@..\permit_body
@..\compliance_body
@..\enable_body
@..\compliance_setup_body
@..\audit_body
@..\section_body
@..\audit_report_body
@..\non_compliance_report_body
@..\Sheet_body
@..\meter_report_body
@..\supplier\company_body
@..\chain\dedupe_admin_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\chain\helper_body
@..\chain\setup_body
@..\supplier_body
@..\schema_body
@..\csrimp\imp_body
@ ..\schema_body
@ ..\csrimp\imp_body
@ ..\quick_survey_body
@..\templated_report_body
@..\region_body
@..\chain\company_product_body
@..\chain\filter_body
@..\chain\chain_body
@..\compliance_register_report_body
@..\permit_report_body
@..\quick_survey_body
@..\issue_body
@..\chain\invitation_body
@..\chain\dev_body
@..\supplier\greentick\product_info_body
@..\batch_job_body
@..\util_script_body
@..\templated_report_schedule_body
@..\csr_data_body
@..\compliance_library_report_body
@..\imp_body
@..\region_picker_body
@..\measure_body
@..\tag_body
@..\chain\plugin_body
@..\chain\product_supplier_report_body
@..\chain\product_report_body
@..\csr_app_body
@..\automated_import_body
@..\automated_export_body
@..\meter_monitor_body



@update_tail
