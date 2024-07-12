-- Please update version.sql too -- this keeps clean builds in sync
define version=1641 -- comment out client scripts
@update_header

ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY DROP CONSTRAINT CHK_CTC_INHERITABLE;
ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY DROP CONSTRAINT FK_CTC_CTR_INHERITED;
ALTER TABLE CHAIN.COMPANY_TYPE_CAPABILITY DROP COLUMN INHERITED_FROM_COMPANY_TYPE_ID;

CREATE TABLE CHAIN.IMPLEMENTATION(
    APP_SID          NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    NAME             VARCHAR2(100)    NOT NULL,
    LINK_PKG         VARCHAR2(100),
    EXECUTE_ORDER    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT CHK_IMPLEMENTATION_UPPER_NAME CHECK (NAME = UPPER(TRIM(NAME))),
    CONSTRAINT CHK_IMPLEMENTATION_LOWER_LINK CHECK (LINK_PKG = LOWER(TRIM(LINK_PKG)))
);

CREATE UNIQUE INDEX CHAIN.UC_IMPL_EXECUTE_ORDER ON CHAIN.IMPLEMENTATION(APP_SID, EXECUTE_ORDER);

ALTER TABLE CHAIN.IMPLEMENTATION ADD CONSTRAINT FK_CO_IMPLEMENTATION 
    FOREIGN KEY (APP_SID)
    REFERENCES CHAIN.CUSTOMER_OPTIONS(APP_SID)
;

INSERT INTO CHAIN.IMPLEMENTATION (APP_SID, NAME, LINK_PKG, EXECUTE_ORDER)
SELECT APP_SID, UPPER(CHAIN_IMPLEMENTATION), LOWER(COMPANY_HELPER_SP), 1
  FROM CHAIN.CUSTOMER_OPTIONS
 WHERE CHAIN_IMPLEMENTATION IS NOT NULL;
 
INSERT INTO CHAIN.IMPLEMENTATION (APP_SID, NAME, EXECUTE_ORDER)
SELECT APP_SID, UPPER(NAME), 2
  FROM CHAIN.IMPLEMENTATION 
 WHERE link_pkg = 'csr.supplier_pkg';
 
UPDATE CHAIN.IMPLEMENTATION
   SET NAME = 'CSR_SUPPLIER'
 WHERE link_pkg = 'csr.supplier_pkg';

CREATE SEQUENCE CHAIN.LINK_LOOKUP_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE GLOBAL TEMPORARY TABLE CHAIN.TT_SID_LINK_LOOKUP
(
	ID							NUMBER(10) NOT NULL,
	SID							NUMBER(10) NOT NULL
)
ON COMMIT DELETE ROWS;

GRANT SELECT ON CHAIN.TT_SID_LINK_LOOKUP TO PUBLIC;

ALTER TABLE CHAIN.CUSTOMER_OPTIONS RENAME COLUMN CHAIN_IMPLEMENTATION TO XXX_CHAIN_IMPLEMENTATION;
ALTER TABLE CHAIN.CUSTOMER_OPTIONS RENAME COLUMN COMPANY_HELPER_SP TO XXX_COMPANY_HELPER_SP;

BEGIN
	dbms_rls.add_policy(
		object_schema   => 'CHAIN',
		object_name     => 'IMPLEMENTATION',
		policy_name     => 'IMPLEMENTATION_POL', 
		function_schema => 'CHAIN',
		policy_function => 'appSidCheck',
		statement_types => 'select, insert, update, delete',
		update_check	=> true,
		policy_type     => dbms_rls.static
	);
END;
/

DECLARE
	v_card_id         chain.card.card_id%TYPE;
	v_desc            chain.card.description%TYPE;
	v_class           chain.card.class_type%TYPE;
	v_js_path         chain.card.js_include%TYPE;
	v_js_class        chain.card.js_class_type%TYPE;
	v_css_path        chain.card.css_include%TYPE;
	v_actions         chain.T_STRING_LIST;
BEGIN
	-- Chain.Cards.CSRQuestionnaireInvitationConfirmation
	v_desc := 'Confirms questionnaire intvitation details with a potential new user - flavoured for csr';
	v_class := 'Credit360.Chain.Cards.CSRQuestionnaireInvitationConfirmation';
	v_js_path := '/csr/site/chain/cards/CSRQuestionnaireInvitationConfirmation.js';
	v_js_class := 'Chain.Cards.CSRQuestionnaireInvitationConfirmation';
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
	   AND action NOT IN ('default','login','register','reject');
		   v_actions := chain.T_STRING_LIST('default','login','register','reject');
	
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

BEGIN
	UPDATE chain.default_message_definition 
	   SET message_template = 'An admin must check your registered company details for {toCompany}.' 
	 WHERE message_definition_id in (
		SELECT message_definition_id FROM chain.message_definition_lookup WHERE primary_lookup_id = 100
	);
	
	UPDATE chain.default_message_definition 
	   SET message_template = 'You must check your {toUser:OPEN}personal details{toUser:CLOSE}.' 
	 WHERE message_definition_id in (
		SELECT message_definition_id FROM chain.message_definition_lookup WHERE primary_lookup_id = 101
	);
END;
/

CREATE OR REPLACE VIEW CHAIN.v$chain_host AS
	SELECT c.app_sid, c.host, i.name
	  FROM csr.customer c, chain.customer_options co, chain.implementation i
	 WHERE c.app_sid = co.app_sid
	   AND c.app_sid = i.app_sid
;

GRANT SELECT, REFERENCES ON CSR.WORKSHEET TO CHAIN;
grant execute on chain.setup_pkg to csr;

@..\chain\helper_pkg.sql
@..\chain\setup_pkg.sql
@..\chain\company_type_pkg.sql
@..\chain\chain_link_pkg.sql
@..\supplier_pkg.sql

@..\chain\card_body.sql
@..\chain\chain_link_body.sql
@..\chain\company_body.sql
@..\chain\company_type_body.sql
@..\chain\dashboard_body.sql
@..\chain\helper_body.sql
@..\chain\message_body.sql
@..\chain\setup_body.sql
@..\chain\type_capability_body.sql
@..\supplier_body.sql

/* comment these out when checked in 
@..\..\..\clients\chaindemo\db\link_pkg.sql
@..\..\..\clients\maersk\db\maersk_link_pkg.sql
@..\..\..\clients\marksandspencer\db\link_pkg.sql
@..\..\..\clients\otto_chain\db\link_pkg.sql

@..\..\..\clients\chaindemo\db\link_body.sql
@..\..\..\clients\maersk\db\chain_setup_body.sql
@..\..\..\clients\maersk\db\maersk_link_body.sql
@..\..\..\clients\marksandspencer\db\link_body.sql
@..\..\..\clients\otto_chain\db\link_body.sql
--*/



@update_tail
