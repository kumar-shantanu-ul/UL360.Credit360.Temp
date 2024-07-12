define version=121
@update_header


DROP TABLE chain.COMPANY_FILTER;
DROP TABLE chain.FILTER;
DROP TABLE chain.COMPOUND_FILTER;

CREATE TABLE chain.COMPOUND_FILTER(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    COMPOUND_FILTER_SID    NUMBER(10, 0)    NOT NULL,
    NAME                   VARCHAR2(255),
    OPERATOR_TYPE          VARCHAR2(8)      DEFAULT 'and' NOT NULL,
    CREATED_DTM            DATE             DEFAULT SYSDATE NOT NULL,
    CREATED_BY_USER_SID    NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'SID') NOT NULL,
    CONSTRAINT CHK_COMP_FIL_OP_TYPE CHECK (OPERATOR_TYPE IN ('and','or')),
    CONSTRAINT PK_COMPOUND_FILTER PRIMARY KEY (APP_SID, COMPOUND_FILTER_SID)
)
;

CREATE TABLE chain.FILTER(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_ID              NUMBER(10, 0)    NOT NULL,
    FILTER_TYPE_ID         NUMBER(10, 0)    NOT NULL,
    COMPOUND_FILTER_SID    NUMBER(10, 0)    NOT NULL,
    CONSTRAINT PK_FILTER_ID PRIMARY KEY (APP_SID, FILTER_ID)
)
;

CREATE TABLE chain.COMPANY_FILTER(
    APP_SID      NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
    FILTER_ID    NUMBER(10, 0)    NOT NULL,
    FIELD        VARCHAR2(255)    NOT NULL,
    STR_VALUE    VARCHAR2(255),
    CONSTRAINT PK_COMPANY_FILTER PRIMARY KEY (APP_SID, FILTER_ID)
)
;

ALTER TABLE chain.FILTER_TYPE ADD (
    DESCRIPTION                   VARCHAR2(255)
);

ALTER TABLE chain.CUSTOMER_FILTER_TYPE ADD (
    POSITION                       NUMBER(10)
);

ALTER TABLE chain.FILTER MODIFY (APP_SID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP'));

ALTER TABLE chain.COMPOUND_FILTER MODIFY (OPERATOR_TYPE          VARCHAR2(8)      DEFAULT 'and');

ALTER TABLE chain.FILTER ADD CONSTRAINT FK_COMP_FIL_FIL 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_SID)
    REFERENCES chain.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_SID)
;

ALTER TABLE chain.FILTER ADD CONSTRAINT FK_CUS_FIL_TYPE_FIL_TYPE 
    FOREIGN KEY (APP_SID, FILTER_TYPE_ID)
    REFERENCES chain.CUSTOMER_FILTER_TYPE(APP_SID, FILTER_TYPE_ID)
;

ALTER TABLE chain.COMPANY_FILTER ADD CONSTRAINT FK_CUS_OPT_COMP_FIL 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID);

ALTER TABLE chain.COMPANY_FILTER ADD CONSTRAINT FK_FILTER_COMP_FILTER 
    FOREIGN KEY (APP_SID, FILTER_ID)
    REFERENCES chain.FILTER(APP_SID, FILTER_ID) ON DELETE CASCADE
;

ALTER TABLE chain.COMPOUND_FILTER ADD CONSTRAINT FK_CMP_FIL_APP_SID 
    FOREIGN KEY (APP_SID)
    REFERENCES chain.CUSTOMER_OPTIONS(APP_SID)
;

ALTER TABLE chain.COMPOUND_FILTER ADD CONSTRAINT FK_CMP_FIL_USER_SID 
    FOREIGN KEY (APP_SID, CREATED_BY_USER_SID)
    REFERENCES chain.CHAIN_USER(APP_SID, USER_SID)
;

INSERT INTO chain.filter_type (filter_type_id, helper_pkg, js_include, js_class_type, description)
VALUES (filter_type_id_seq.NEXTVAL, 'chain.company_filter_pkg', '/csr/site/chain/filters/chain.js', 'Chain.Filters.ChainCore', 'Chain Core Filter');

CREATE OR REPLACE VIEW chain.v$filter_type AS
	SELECT f.filter_type_id, f.helper_pkg, f.js_include, f.js_class_type, f.description
	  FROM filter_type f
	  JOIN customer_filter_type cft ON f.filter_type_id = cft.filter_type_id
	 WHERE cft.app_sid = SYS_CONTEXT('SECURITY', 'APP');

-- This is going to be slow if you have a lot of chain sites / companies
declare
	v_act_id security_pkg.T_ACT_ID;
	v_app_sid security_pkg.T_SID_ID;
	v_company_sid security_pkg.T_SID_ID;
	v_filters_sid security_pkg.T_SID_ID;
	v_chain_users_sid security_pkg.T_SID_ID;
begin
	for r in (
		select c.host from chain.customer_options co, csr.customer c where c.app_sid = co.app_sid
	) loop
		user_pkg.LogonAdmin(r.host);
		v_act_id := security_pkg.GetAct;
		v_app_sid := security_pkg.GetApp;
		v_chain_users_sid := securableobject_pkg.GetSidFromPath(v_act_id, v_app_sid, 'Groups/Chain Users');

		v_company_sid := securableobject_pkg.GetSIDFromPath(security_pkg.GetAct, security_pkg.GetApp, 'Chain/Companies');

		for r in (select sid_id from security.securable_object where parent_sid_id = v_company_sid) loop
			BEGIN
				v_filters_sid := securableobject_pkg.GetSIDFromPath(v_act_id, r.sid_id, 'Filters');
			EXCEPTION 
				WHEN security_pkg.OBJECT_NOT_FOUND THEN
					securableobject_pkg.CreateSO(v_act_id, r.sid_id, security_pkg.SO_CONTAINER, 'Filters', v_filters_sid);
					acl_pkg.AddACE(
						v_act_id, 
						acl_pkg.GetDACLIDForSID(v_filters_sid), 
						security_pkg.ACL_INDEX_LAST, 
						security_pkg.ACE_TYPE_ALLOW,
						security_pkg.ACE_FLAG_DEFAULT,
						v_chain_users_sid, 
						security_pkg.PERMISSION_STANDARD_ALL
					);
			END;
		end loop;
	end loop;
end;
/

BEGIN
	FOR r IN (
		SELECT host 
		  FROM chain.v$chain_host 
	) LOOP
		user_pkg.LogonAdmin(r.host);
		
		DECLARE
			v_class_id		security_pkg.T_CLASS_ID;
		BEGIN
			class_pkg.CreateClass(security_pkg.getACT, null, 'ChainCompoundFilter', 'chain.filter_pkg', null, v_class_id);
		EXCEPTION
			WHEN security_pkg.DUPLICATE_OBJECT_NAME THEN NULL;
		END;
	END LOOP;
END;
/

@..\filter_pkg
@..\company_filter_pkg
@..\company_pkg
@..\filter_body
@..\company_filter_body
@..\company_body
@..\rls

grant execute on chain.filter_pkg to web_user;
grant execute on chain.filter_pkg to security;
grant execute on chain.company_filter_pkg to web_user;

@update_tail
