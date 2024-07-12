-- Please update version.sql too -- this keeps clean builds in sync
define version=3061
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE chain.company_request_action(
	app_sid 					NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	company_sid 				NUMBER(10)		NOT NULL,
	matched_company_sid			NUMBER(10),
	action						NUMBER(10)		NOT NULL,
	is_processed				NUMBER(1)		DEFAULT 0 NOT NULL,
	batch_job_id				NUMBER(10),
	error_message				VARCHAR2(4000),
	error_detail				VARCHAR2(4000),
	CONSTRAINT pk_company_request_action PRIMARY KEY (app_sid, company_sid)
);

CREATE TABLE csrimp.chain_company_request_action(
	csrimp_session_id			NUMBER(10) 		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	company_sid 				NUMBER(10)		NOT NULL,
	matched_company_sid			NUMBER(10),
	action						NUMBER(10)		NOT NULL,
	is_processed				NUMBER(1)		NOT NULL,
	batch_job_id				NUMBER(10),
	error_message				VARCHAR2(4000),
	error_detail				VARCHAR2(4000),
	CONSTRAINT pk_chain_company_request_act PRIMARY KEY (csrimp_session_id, company_sid)
);

-- Alter tables
ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_company_request_action
	CHECK (action IN (1, 2, 3));
	
ALTER TABLE chain.company_request_action ADD CONSTRAINT chk_action_matched
	CHECK ((action = 3 AND matched_company_sid IS NOT NULL) OR matched_company_sid IS NULL);

ALTER TABLE chain.company_request_action ADD CONSTRAINT fk_req_act_cmpny_sid
	FOREIGN KEY (app_sid, company_sid) REFERENCES chain.company (app_sid, company_sid);
	
ALTER TABLE chain.company_request_action ADD CONSTRAINT fk_req_act_mtchd_cmpny_sid
	FOREIGN KEY (app_sid, matched_company_sid) REFERENCES chain.company (app_sid, company_sid);

ALTER TABLE csrimp.chain_company_request_action ADD CONSTRAINT chk_company_request_action
	CHECK (action IN (1, 2, 3));

ALTER TABLE csrimp.chain_company_request_action ADD CONSTRAINT fk_chain_cmpny_rqst_action_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON chain.company_request_action TO csrimp;
GRANT SELECT ON chain.company_request_action TO csr;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_company_request_action TO tool_user;

CREATE INDEX chain.ix_company_reque_matched_compa on chain.company_request_action (app_sid, matched_company_sid);

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.
-- C:\cvs\csr\db\chain\create_views.sql
CREATE OR REPLACE VIEW chain.v$company_request AS
	SELECT c.app_sid, c.company_sid, c.name, c.address_1, c.address_2, c.address_3, c.address_4,
		   c.state, c.city, c.postcode, c.country_code, c.phone, c.fax, c.website, c.email,
		   c.requested_by_user_sid, c.requested_by_company_sid
	  FROM company c
	 WHERE c.pending = 1
	    OR EXISTS (
			SELECT 1
			  FROM company_request_action
			 WHERE company_sid = c.company_sid
		   );

-- (csr/db/chain/create_views.sql) Exclude pending companies from v$company view. Removed join to customer_options
CREATE OR REPLACE VIEW chain.v$company AS
   	SELECT c.app_sid, c.company_sid, c.created_dtm, c.name, c.active, c.activated_dtm, c.deactivated_dtm,
   		   c.address_1, c.address_2, c.address_3, c.address_4, c.state, c.city, c.postcode, c.country_code,
   		   c.phone, c.fax, c.website, c.email, c.deleted, c.details_confirmed, c.stub_registration_guid, 
   		   c.allow_stub_registration, c.approve_stub_registration, c.mapping_approval_required, 
   		   c.user_level_messaging, c.sector_id,
   		   cou.name country_name, s.description sector_description, c.can_see_all_companies, c.company_type_id,
   		   ct.lookup_key company_type_lookup, ct.singular company_type_description, c.supp_rel_code_label, c.supp_rel_code_label_mand,
   		   c.parent_sid, p.name parent_name, p.country_code parent_country_code, pcou.name parent_country_name,
   		   c.country_is_hidden, cs.region_sid
   	  FROM company c
   	  LEFT JOIN postcode.country cou ON c.country_code = cou.country
   	  LEFT JOIN sector s ON c.sector_id = s.sector_id AND c.app_sid = s.app_sid
   	  LEFT JOIN company_type ct ON c.company_type_id = ct.company_type_id
   	  LEFT JOIN company p ON c.parent_sid = p.company_sid AND c.app_sid = p.app_sid
   	  LEFT JOIN postcode.country pcou ON p.country_code = pcou.country
   	  LEFT JOIN csr.supplier cs ON cs.company_sid = c.company_sid AND cs.app_sid = c.app_sid
   	 WHERE c.deleted = 0
   	   AND c.pending = 0;
		   
-- *** Data changes ***
-- RLS

-- Data
BEGIN
	INSERT INTO csr.batch_job_type (batch_job_type_id, description, sp, plugin_name, in_order, file_data_sp)
		 VALUES (61, 'Pending companies batch job', NULL, 'process-pending-company-records', 0, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
END;
/

DECLARE
	v_card_id			chain.card.card_id%TYPE;
	v_desc				chain.card.description%TYPE;
	v_class				chain.card.class_type%TYPE;
	v_js_path			chain.card.js_include%TYPE;
	v_js_class			chain.card.js_class_type%TYPE;
	v_css_path			chain.card.css_include%TYPE;
	v_actions			chain.T_STRING_LIST;
BEGIN
	v_desc := 'Company Request Filter';
	v_class := 'Credit360.Chain.Cards.Filters.CompanyRequestFilter';
	v_js_path := '/csr/site/chain/companyRequest/filters/CompanyRequestFilter.js';
	v_js_class := 'Chain.companyRequest.filters.CompanyRequestFilter';
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
END;
/

DECLARE
	v_card_id						NUMBER(10);
	v_audit_filter_card_id			NUMBER(10);
	v_sid							NUMBER(10);
BEGIN
	BEGIN
		INSERT INTO chain.card_group(card_group_id, name, description, helper_pkg, list_page_url)
		VALUES(61 /*chain.filter_pkg.FILTER_TYPE_COMPANY_REQUEST*/, 'Company Request Filter', 'Allows filtering of add company requests.', 'chain.company_request_report_pkg', '/csr/site/chain/companyRequest/companyRequestList.acds?savedFilterSid=');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

	SELECT card_id
	  INTO v_card_id
	  FROM chain.card
	 WHERE js_class_type = 'Chain.companyRequest.filters.CompanyRequestFilter';
	
	BEGIN	
		INSERT INTO chain.filter_type (filter_type_id,description,helper_pkg,card_id) 
		    VALUES (chain.filter_type_id_seq.NEXTVAL, 'Company Request Filter', 'chain.company_request_report_pkg', v_card_id);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	FOR r IN (
		SELECT app_sid FROM chain.customer_options
	) LOOP
		BEGIN
			INSERT INTO chain.card_group_card (app_sid, card_group_id, card_id, position)
					VALUES (r.app_sid, 61 /*chain.filter_pkg.FILTER_TYPE_COMPANY_REQUEST*/, v_card_id, 0);
		EXCEPTION
			WHEN DUP_VAL_ON_INDEX THEN
				NULL;
		END;
	END LOOP;
END;
/

BEGIN
	BEGIN
		INSERT INTO chain.aggregate_type (card_group_id, aggregate_type_id, description)
		VALUES (61 /*chain.filter_pkg.FILTER_TYPE_COMPANY_REQUEST*/, 1 /*chain.company_request_report_pkg.AGG_TYPE_COUNT*/, 'Number of records');
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../batch_job_pkg
@../chain/chain_pkg
@../chain/company_pkg
@../chain/filter_pkg
@../chain/company_request_report_pkg
@../chain/company_dedupe_pkg
@../schema_pkg

@../batch_job_body
@../chain/company_body
@../chain/setup_body
@../chain/company_request_report_body
@../schema_body
@../csrimp/imp_body
@../chain/company_filter_body
@../chain/company_user_body
@../chain/product_body
@../audit_body
@../chain/business_relationship_body
@../chain/chain_link_body
@../chain/dashboard_body
@../chain/dedupe_preprocess_body
@../chain/dev_body
@../chain/flow_form_body
@../chain/questionnaire_body
@../chain/type_capability_body
@../quick_survey_body
@../supplier_body
@../chain/company_dedupe_body

@update_tail
