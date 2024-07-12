-- Please update version.sql too -- this keeps clean builds in sync
define version=1716
@update_header

CREATE SEQUENCE CSR.PROPERTY_PHOTO_ID_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.PROPERTY_PHOTO(
    APP_SID                NUMBER(10, 0)    DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    PROPERTY_PHOTO_ID      NUMBER(10, 0)    NOT NULL,
    PROPERTY_REGION_SID    NUMBER(10, 0)    NOT NULL,
    SPACE_REGION_SID       NUMBER(10, 0),
    FILENAME               VARCHAR2(256)    NOT NULL,
    MIME_TYPE              VARCHAR2(255)    NOT NULL,
    DATA                   BLOB             NOT NULL,
    CONSTRAINT PK_PROPERTY_PHOTO PRIMARY KEY (APP_SID, PROPERTY_PHOTO_ID)
)
;

ALTER TABLE CSR.PROPERTY_PHOTO ADD CONSTRAINT FK_PROP_PHOTO_PROP_SID 
    FOREIGN KEY (APP_SID, PROPERTY_REGION_SID)
    REFERENCES CSR.PROPERTY(APP_SID, REGION_SID)
;

ALTER TABLE CSR.PROPERTY_PHOTO ADD CONSTRAINT FK_PROP_PHOTO_SPACE_SID 
    FOREIGN KEY (APP_SID, SPACE_REGION_SID)
    REFERENCES CSR.SPACE(APP_SID, REGION_SID)
;


declare
    policy_already_exists exception;
    pragma exception_init(policy_already_exists, -28101);

    type t_tabs is table of varchar2(30);
    v_list t_tabs;
    v_null_list t_tabs;
    v_found number;
begin   
    v_list := t_tabs(
        'PROPERTY_PHOTO'
    );
    for i in 1 .. v_list.count loop
        declare
            v_name varchar2(30);
            v_i pls_integer default 1;
        begin
            loop
                begin               
                    v_name := SUBSTR(v_list(i), 1, 23)||'_POLICY';
                    
                    dbms_output.put_line('doing '||v_name);
                    dbms_rls.add_policy(
                        object_schema   => 'CSR',
                        object_name     => v_list(i),
                        policy_name     => v_name,
                        function_schema => 'CSR',
                        policy_function => 'appSidCheck',
                        statement_types => 'select, insert, update, delete',
                        update_check    => true,
                        policy_type     => dbms_rls.context_sensitive );
                    exit;
                exception
                    when policy_already_exists then
                        exit; -- don't add twice
                end;
            end loop;
        end;
    end loop;
end;
/

declare
 v_is_mandatory number;
begin
 select count(*)
   into v_is_mandatory 
   from all_tab_columns
   where owner='CSR' and table_name='PROPERTY'
   and column_name='FLOW_ITEM_ID'
   and nullable = 'N';
  
 if v_is_mandatory = 1 then
  execute immediate 'alter table csr.property modify flow_item_id null';
 end if;
end;
/

declare
 v_is_mandatory number;
begin
 select count(*)
   into v_is_mandatory 
   from all_tab_columns
   where owner='CSR' and table_name='PROPERTY'
   and column_name='STREET_ADDR_2'
   and nullable = 'N';
  
 if v_is_mandatory = 1 then
  execute immediate 'alter table csr.property modify street_addr_2 null';
 end if;
end;
/


ALTER TABLE CSR.PROPERTY ADD (
	MGMT_COMPANY_CONTACT_ID NUMBER(10, 0) NULL
);


ALTER TABLE CSR.PROPERTY ADD CONSTRAINT FK_MGMT_CO_CONTACT_PROPERTY
    FOREIGN KEY (APP_SID, MGMT_COMPANY_ID, MGMT_COMPANY_CONTACT_ID)
    REFERENCES CSR.MGMT_COMPANY_CONTACT(APP_SID, MGMT_COMPANY_ID, MGMT_COMPANY_CONTACT_ID);

CREATE OR REPLACE VIEW csr.v$property AS
    SELECT r.app_sid, r.region_sid, r.description, r.parent_sid, r.lookup_key, p.street_addr_1, p.street_addr_2, p.city, p.state, p.postcode, c.country country_code,
        c.name country_name, c.currency country_currency,
        pt.property_type_id, pt.label property_type_label,
        pst.property_sub_type_id, pst.label property_sub_type_label,
        p.flow_item_id, fi.current_state_id, fs.label current_state_label, fs.lookup_key current_state_lookup_key, fs.state_colour current_state_colour,
        r.active, r.acquisition_dtm, r.disposal_dtm, geo_longitude lng, geo_latitude lat, fund_id,
        mgmt_company_id, mgmt_company_other, mgmt_company_contact_id, p.company_sid, p.pm_building_id
      FROM property p
        JOIN v$region r ON p.region_sid = r.region_sid AND p.app_sid = r.app_sid
        LEFT JOIN postcode.country c ON r.geo_country = c.country 
        LEFT JOIN property_type pt ON p.property_type_id = pt.property_type_id AND p.app_sid = pt.app_sid
        LEFT JOIN property_sub_type pst ON p.property_sub_type_id = pst.property_sub_type_id AND p.app_sid = pst.app_sid
        LEFT JOIN flow_item fi ON p.flow_item_id = fi.flow_item_id AND p.app_sid = fi.app_sid
        LEFT JOIN flow_state fs ON fi.current_state_id = fs.flow_state_id AND fi.app_sid = fs.app_sid;

begin
	begin
		insert into cms.col_type (col_type, description) values (30, 'Changed by');
		insert into cms.col_type (col_type, description) values (31, 'Constrained enumeration');
	exception
		when dup_val_on_index then
			null;
	end;
end;
/

BEGIN
	-- Drop and create fund_form_plugin as some dev's will have local differences
	FOR r IN (
		SELECT * FROM all_tables
		 WHERE owner='CSR' and table_name = 'FUND_FORM_PLUGIN'
	) LOOP
		EXECUTE IMMEDIATE 'DROP TABLE CSR.FUND_FORM_PLUGIN';
	END LOOP;
END;
/

CREATE TABLE csr.fund_form_plugin (
	app_sid		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	plugin_id	NUMBER(10) NOT NULL,
	pos			NUMBER(10) NOT NULL,
	xml_path	VARCHAR(255) NOT NULL,
	key_name	VARCHAR(255) NOT NULL,
	CONSTRAINT	FK_FUND_FORM_PLUGIN_PLUGIN FOREIGN KEY(plugin_id) REFERENCES csr.plugin(plugin_id),
	CONSTRAINT	PK_FUND_FORM_PLUGIN PRIMARY KEY(app_sid, plugin_id, pos)
);

CREATE OR REPLACE VIEW csr.v$lease AS
	SELECT l.lease_id, l.start_dtm, l.end_dtm, l.next_break_dtm, l.current_rent, 
		   l.normalised_rent, l.next_rent_review, l.tenant_id, l.currency_code,
		   t.name tenant_name
	  FROM lease l
		LEFT JOIN tenant t ON t.tenant_id = l.tenant_id;

CREATE OR REPLACE VIEW csr.v$space AS
    SELECT s.region_sid, r.description, r.parent_sid, s.space_type_id, st.label space_type_label, s.current_lease_id, l.tenant_name current_tenant_name
      FROM space s
        JOIN v$region r on s.region_sid = r.region_sid
        JOIN space_type st ON s.space_type_Id = st.space_type_id
		LEFT JOIN v$lease l ON l.lease_id = s.current_lease_id;
		
ALTER TABLE csr.lease MODIFY (normalised_rent NULL);

INSERT INTO csr.plugin_type (plugin_type_id, description) VALUES (2, 'Fund form');

ALTER TABLE csr.fund ADD (
	MGR_CONTACT_NAME           VARCHAR2(255),
    MGR_CONTACT_EMAIL          VARCHAR2(255),
    MGR_CONTACT_PHONE          VARCHAR2(255)
);

ALTER TABLE csr.fund DROP CONSTRAINT FK_FUND_MGR_CONTACT_FUND;

ALTER TABLE csr.fund DROP COLUMN FUND_MANAGER_CONTACT_ID;

-- OK to drop as this table has no data on live
DROP TABLE csr.FUND_MGR_CONTACT;


@..\..\..\aspen2\cms\db\tab_pkg
@..\..\..\aspen2\cms\db\tab_body
@..\property_pkg
@..\space_pkg
@..\csr_data_pkg

@..\property_body
@..\space_body
@..\region_body
@..\region_metric_body
@..\flow_body


@update_tail