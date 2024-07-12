-- Please update version.sql too -- this keeps clean builds in sync
define version=1874
@update_header

CREATE SEQUENCE csr.cms_field_change_alert_id_seq
	START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER;


CREATE TABLE csr.cms_field_change_alert (
    app_sid						NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	cms_field_change_alert_id	NUMBER(10, 0) NOT NULL,
	item_id						NUMBER(10, 0) NOT NULL,
	customer_alert_type_id		NUMBER(10, 0) NOT NULL,
	user_sid					NUMBER(10, 0) NOT NULL,
	version_number				NUMBER(10, 0),
	sent_dtm					DATE,
	CONSTRAINT pk_cms_field_change_alert PRIMARY KEY (cms_field_change_alert_id),
	CONSTRAINT uk_cms_field_change_alert UNIQUE (item_id, customer_alert_type_id, user_sid, version_number, sent_dtm),
	CONSTRAINT fk_cms_fld_chg_alt_csr_usr FOREIGN KEY (app_sid, user_sid) REFERENCES csr.csr_user (app_sid, csr_user_sid),
	CONSTRAINT fk_cms_fld_chg_alt_cs_alt_typ FOREIGN KEY (app_sid, customer_alert_type_id) REFERENCES csr.customer_alert_type (app_sid, customer_alert_type_id)
);

ALTER TABLE csr.cms_alert_type ADD (
	lookup_key					VARCHAR2(255)
);

ALTER TABLE csr.cms_alert_type ADD (
	include_in_alert_setup		NUMBER(1) DEFAULT 0 NOT NULL
);

ALTER TABLE csr.cms_alert_type ADD CONSTRAINT chk_include_in_alert_setup
	CHECK (include_in_alert_setup IN (1, 0));
	
CREATE UNIQUE INDEX csr.uk_cms_alert_type ON csr.cms_alert_type (app_sid, NVL(lookup_key, tab_sid||'_'||customer_alert_type_id));
	
ALTER TABLE csrimp.cms_alert_type ADD (include_in_alert_setup NUMBER(1));
UPDATE csrimp.cms_alert_type SET include_in_alert_setup=0;
ALTER TABLE csrimp.cms_alert_type MODIFY include_in_alert_setup NOT NULL;
	
ALTER TABLE csrimp.cms_alert_type ADD (
	lookup_key					VARCHAR2(255),
	CONSTRAINT chk_include_in_alert_setup CHECK (include_in_alert_setup IN (1, 0))
);

BEGIN
	-- Fix inconsistancy between clean build and change scripts - in case any clients / environments
	-- were created against the clean build when it was in an inconsistent state.
	FOR r IN (SELECT * FROM dual WHERE NOT EXISTS(
		SELECT * FROM all_cons_columns WHERE owner='CSR' AND constraint_name='PK_CMS_ALERT_TYPE' AND column_name='CUSTOMER_ALERT_TYPE_ID'
	)) LOOP
		EXECUTE IMMEDIATE 'ALTER TABLE csr.cms_alert_type DROP PRIMARY KEY';
		EXECUTE IMMEDIATE 'ALTER TABLE csr.cms_alert_type ADD CONSTRAINT PK_CMS_ALERT_TYPE PRIMARY KEY (APP_SID, TAB_SID, CUSTOMER_ALERT_TYPE_ID)';
	END LOOP;
END;
/


-- RLS
DECLARE
	FEATURE_NOT_ENABLED EXCEPTION;
	PRAGMA EXCEPTION_INIT(FEATURE_NOT_ENABLED, -439);
	POLICY_ALREADY_EXISTS EXCEPTION;
	PRAGMA EXCEPTION_INIT(POLICY_ALREADY_EXISTS, -28101);
	TYPE T_TABS IS TABLE OF VARCHAR2(30);
	v_list T_TABS;
BEGIN
	v_list := t_tabs(
	   'CMS_FIELD_CHANGE_ALERT'
	);
	FOR I IN 1 .. v_list.count
	LOOP
		BEGIN
			DBMS_RLS.ADD_POLICY(
				object_schema   => 'CSR',
				object_name     => v_list(i),
				policy_name     => SUBSTR(v_list(i), 1, 23)||'_POLICY',
				function_schema => 'CSR',
				policy_function => 'appSidCheck',
				statement_types => 'select, insert, update, delete',
				update_check    => true,
				policy_type     => dbms_rls.context_sensitive );
				DBMS_OUTPUT.PUT_LINE('Policy added to '||v_list(i));
		EXCEPTION
			WHEN POLICY_ALREADY_EXISTS THEN
				DBMS_OUTPUT.PUT_LINE('Policy exists for '||v_list(i));
			WHEN FEATURE_NOT_ENABLED THEN
				DBMS_OUTPUT.PUT_LINE('RLS policies not applied for '||v_list(i)||' as feature not enabled');
		END;
	END LOOP;
END;
/

ALTER TABLE cms.tab_column ADD (
	 ENUMERATED_COLPOS_FIELD VARCHAR2(30)
);


ALTER TABLE csrimp.cms_tab_column ADD (
	 ENUMERATED_COLPOS_FIELD VARCHAR2(30)
);

-- Put these back if they've been lost somehow
grant execute on csrimp.imp_pkg to web_user;
grant select,insert,update,delete on csrimp.flow_transition_alert_user to web_user;
grant select,insert,update,delete on csrimp.flow_transition_alert_cms_col to web_user;

@../flow_pkg
@../alert_pkg
@../../../aspen2/cms/db/tab_pkg

@../flow_body
@../alert_body
@../../../aspen2/cms/db/tab_body
@../csr_data_body
@../issue_body
@../csrimp/imp_body
@../schema_body
@../role_body

@update_tail