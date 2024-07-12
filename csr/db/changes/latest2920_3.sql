-- Please update version.sql too -- this keeps clean builds in sync
define version=2920
define minor_version=3
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.meter_tab (
	app_sid			NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	plugin_id		NUMBER(10, 0) NOT NULL,
	plugin_type_id	NUMBER(10, 0) NOT NULL,
	pos				NUMBER(10, 0) NOT NULL,
	tab_label		VARCHAR2(50),
	CONSTRAINT pk_meter_tab PRIMARY KEY (app_sid, plugin_id),
	CONSTRAINT chk_meter_tab_plugin_type CHECK (plugin_type_id = 16),
	CONSTRAINT fk_meter_tab_plugin FOREIGN KEY (plugin_id, plugin_type_id) 
		REFERENCES csr.plugin(plugin_id, plugin_type_id),
	CONSTRAINT fk_meter_tab_customer FOREIGN KEY (app_sid) 
		REFERENCES csr.customer (app_sid)
);

CREATE TABLE csr.meter_tab_group (
	app_sid						NUMBER (10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	plugin_id					NUMBER (10) NOT NULL,
	group_sid					NUMBER (10),
	role_sid					NUMBER (10),
	CONSTRAINT pk_meter_tab_group PRIMARY KEY (app_sid, plugin_id, group_sid),
	CONSTRAINT chk_meter_tab_group_grp_role CHECK ((group_sid IS NULL AND role_sid IS NOT NULL) OR (group_sid IS NOT NULL AND role_sid IS NULL)),
	CONSTRAINT fk_meter_tab_group_meter_tab FOREIGN KEY (app_sid, plugin_id) 
		REFERENCES csr.meter_tab (app_sid, plugin_id),
	CONSTRAINT fk_meter_tab_group_role FOREIGN KEY (app_sid, role_sid) 
		REFERENCES csr.role (app_sid, role_sid)
);

CREATE TABLE csrimp.meter_tab (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	plugin_id						NUMBER(10) NOT NULL,
	plugin_type_id					NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	tab_label						VARCHAR2(50),
	CONSTRAINT pk_meter_tab PRIMARY KEY (csrimp_session_id, plugin_id),
	CONSTRAINT chk_meter_tab_plugin_type CHECK (plugin_type_id = 16),
    CONSTRAINT fk_meter_tab_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.meter_tab_group (	
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	plugin_id						NUMBER (10) NOT NULL,
	group_sid						NUMBER (10),
	role_sid						NUMBER (10),
	CONSTRAINT pk_meter_tab_group PRIMARY KEY (csrimp_session_id, plugin_id, group_sid),
	CONSTRAINT chk_meter_tab_group_grp_role CHECK ((group_sid IS NULL AND role_sid IS NOT NULL) OR (group_sid IS NOT NULL AND role_sid IS NULL)),
    CONSTRAINT fk_meter_tab_group_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE SEQUENCE csr.meter_header_element_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE TABLE csr.meter_header_element (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	meter_header_element_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	meter_header_core_element_id	NUMBER(10),
	CONSTRAINT pk_meter_header_element PRIMARY KEY (app_sid, meter_header_element_id),
	CONSTRAINT fk_meter_header_el_reg_metric FOREIGN KEY (app_sid, ind_sid)
		REFERENCES csr.region_metric (app_sid, ind_sid),
	CONSTRAINT fk_meter_header_el_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT chk_meter_header_element
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NULL) OR 
				(ind_sid IS NULL AND tag_group_id IS NOT NULL AND meter_header_core_element_id IS NULL) OR
				(ind_sid IS NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NOT NULL))
);

CREATE TABLE csrimp.meter_header_element (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	meter_header_element_id			NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	ind_sid							NUMBER(10),
	tag_group_id					NUMBER(10),
	meter_header_core_element_id	NUMBER(10),
	CONSTRAINT pk_meter_header_element PRIMARY KEY (csrimp_session_id, meter_header_element_id),
	CONSTRAINT chk_meter_header_element
		CHECK ((ind_sid IS NOT NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NULL) OR 
				(ind_sid IS NULL AND tag_group_id IS NOT NULL AND meter_header_core_element_id IS NULL) OR
				(ind_sid IS NULL AND tag_group_id IS NULL AND meter_header_core_element_id IS NOT NULL)),
	CONSTRAINT fk_meter_header_element_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_header_element (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_header_element_id		NUMBER(10)	NOT NULL,
	new_meter_header_element_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_meter_header_element primary key (csrimp_session_id, old_meter_header_element_id) USING INDEX,
	CONSTRAINT uk_map_meter_header_element unique (csrimp_session_id, new_meter_header_element_id) USING INDEX,
    CONSTRAINT fk_map_meter_header_element_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE SEQUENCE csr.meter_photo_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE TABLE csr.meter_photo (
	app_sid							NUMBER(10, 0) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	meter_photo_id					NUMBER(10, 0) NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	filename						VARCHAR2(256) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	CONSTRAINT pk_meter_photo PRIMARY KEY (app_sid, meter_photo_id),
	CONSTRAINT fk_meter_photo_meter FOREIGN KEY (app_sid, region_sid)
		REFERENCES csr.all_meter (app_sid, region_sid)
);

CREATE TABLE csrimp.meter_photo (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	meter_photo_id					NUMBER(10, 0) NOT NULL,
	region_sid						NUMBER(10, 0) NOT NULL,
	filename						VARCHAR2(256) NOT NULL,
	mime_type						VARCHAR2(255) NOT NULL,
	data							BLOB NOT NULL,
	CONSTRAINT pk_meter_photo PRIMARY KEY (csrimp_session_id, meter_photo_id),
	CONSTRAINT fk_meter_photo_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_photo (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_photo_id		NUMBER(10)	NOT NULL,
	new_meter_photo_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_meter_photo primary key (csrimp_session_id, old_meter_photo_id) USING INDEX,
	CONSTRAINT uk_map_meter_photo unique (csrimp_session_id, new_meter_photo_id) USING INDEX,
    CONSTRAINT fk_map_meter_photo_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

create index csr.ix_meter_tab_plugin_id_plu on csr.meter_tab (plugin_id, plugin_type_id);
create index csr.ix_meter_tab_gro_role_sid on csr.meter_tab_group (app_sid, role_sid);
create index csr.ix_meter_header_ind_sid on csr.meter_header_element (app_sid, ind_sid);
create index csr.ix_meter_header_tag_group_id on csr.meter_header_element (app_sid, tag_group_id); 
create index csr.ix_meter_photo_meter_region on csr.meter_photo (app_sid, region_sid);  

CREATE UNIQUE INDEX csr.uk_meter_header_element ON csr.meter_header_element(app_sid, ind_sid, tag_group_id, meter_header_core_element_id);

-- Alter tables
ALTER TABLE csr.metering_options ADD (
	meter_page_url					VARCHAR2(255) DEFAULT '/csr/site/meter/meter.acds' NOT NULL
);

ALTER TABLE csrimp.metering_options ADD (
	meter_page_url					VARCHAR2(255)
);
UPDATE csrimp.metering_options SET meter_page_url = '/csr/site/meter/meter.acds';
ALTER TABLE csrimp.metering_options MODIFY meter_page_url NOT NULL;

-- *** Grants ***
grant select,insert,update,delete on csrimp.meter_tab to web_user;
grant select,insert,update,delete on csrimp.meter_tab_group to web_user;
grant insert on csr.meter_tab to csrimp;
grant insert on csr.meter_tab_group to csrimp;

grant select,insert,update,delete on csrimp.meter_header_element to web_user;
grant insert on csr.meter_header_element to csrimp;
grant select on csr.meter_header_element_id_seq to csrimp;

grant select,insert,update,delete on csrimp.meter_photo to web_user;
grant insert on csr.meter_photo to csrimp;
grant select on csr.meter_photo_id_seq to csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN	
	INSERT INTO csr.plugin_type (plugin_type_id, description) 
		 VALUES (16, 'Meter tab');
END;
/

BEGIN
	INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) 
	VALUES (13, 'Enable configurable meter page', 'Enables the meter "washing machine" page, a configurable page that replaces the existing meter page.', 'EnableMeterWashingMachine', NULL);
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.host
		  FROM csr.customer c
		  JOIN csr.customer_region_type crt ON c.app_sid = crt.app_sid
		 WHERE crt.region_type = 1
		 GROUP BY c.host
	) LOOP		
		security.user_pkg.LogonAdmin(r.host);
		
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 1, 1, 1); -- serial number
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 1, 2, 3); -- meter source
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 2, 1, 4); -- space
		INSERT INTO csr.meter_header_element (meter_header_element_id, pos, col, meter_header_core_element_id)
		     VALUES (csr.meter_header_element_id_seq.NEXTVAL, 2, 2, 2); -- meter type
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@../csr_data_pkg
@../meter_pkg
@../util_script_pkg
@../schema_pkg

@../meter_body
@../csr_app_body
@../plugin_body
@../role_body
@../tag_body
@../indicator_body
@../region_metric_body
@../property_body
@../region_body
@../meter_patch_body
@../meter_alarm_body
@../util_script_body
@../enable_body
@../schema_body
@../csrimp/imp_body

@update_tail
