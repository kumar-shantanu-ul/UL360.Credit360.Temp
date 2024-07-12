-- Please update version.sql too -- this keeps clean builds in sync
define version=2954
define minor_version=13
@update_header

-- *** DDL ***
-- Create tables
-- Tabs.
CREATE TABLE csr.init_tab_element_layout (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	element_id			NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	tag_group_id		NUMBER(10),
	xml_field_id		VARCHAR2(255),
	pos					NUMBER(10) NOT NULL,
	CONSTRAINT pk_initiative_tab_el_layout PRIMARY KEY (app_sid, element_id),
	CONSTRAINT chk_init_tab_layt_types CHECK ((xml_field_id IS NULL AND tag_group_id IS NULL) OR (xml_field_id IS NOT NULL AND tag_group_id IS NULL) OR (xml_field_id IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_initiative_tab_layout_cust FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid),
	CONSTRAINT fk_init_tab_layt_tag_grp FOREIGN KEY (app_sid, tag_group_id) REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT fk_init_tab_layt_plugin FOREIGN KEY (plugin_id) REFERENCES csr.plugin (plugin_id)
);

CREATE UNIQUE INDEX csr.idx_init_tab_layout_tag_grp_id ON csr.init_tab_element_layout (
	app_sid, NVL(TO_CHAR(tag_group_id), element_id)
);

CREATE UNIQUE INDEX csr.idx_init_tab_layout_xml_fld_id ON csr.init_tab_element_layout (
	app_sid, NVL(TO_CHAR(xml_field_id), element_id)
);

CREATE SEQUENCE csr.initiative_tab_element_id_seq 
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE TABLE csr.init_create_page_el_layout (
	app_sid				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	element_id			VARCHAR2(255) NOT NULL,
	tag_group_id		NUMBER(10),
	xml_field_id		VARCHAR2(255),
	section_id			VARCHAR2(255) NOT NULL,
	pos					NUMBER(10) NOT NULL,
	CONSTRAINT pk_initiative_el_layout PRIMARY KEY (app_sid, element_id),
	CONSTRAINT chk_init_el_layt_types CHECK ((xml_field_id IS NULL AND tag_group_id IS NULL) OR (xml_field_id IS NOT NULL AND tag_group_id IS NULL) OR (xml_field_id IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_initiative_el_layout_cust FOREIGN KEY (app_sid) REFERENCES csr.customer (app_sid),
	CONSTRAINT fk_init_el_layt_tag_grp FOREIGN KEY (app_sid, tag_group_id) REFERENCES csr.tag_group (app_sid, tag_group_id)
);

CREATE UNIQUE INDEX csr.idx_init_el_layout_tag_grp_id ON csr.init_create_page_el_layout (
	app_sid, NVL(TO_CHAR(tag_group_id), element_id)
);

CREATE SEQUENCE csr.init_create_page_el_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 5
    NOORDER
;

CREATE SEQUENCE csr.init_header_element_id_seq
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    NOCACHE
    NOORDER
;

CREATE TABLE csr.initiative_header_element (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	initiative_header_element_id	NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	initiative_metric_id			NUMBER(10),
	tag_group_id					NUMBER(10),
	init_header_core_element_id		NUMBER(10),
	CONSTRAINT pk_initiative_header_element PRIMARY KEY (app_sid, initiative_header_element_id),
	CONSTRAINT fk_init_header_el_init_metric FOREIGN KEY (app_sid, initiative_metric_id)
		REFERENCES csr.initiative_metric (app_sid, initiative_metric_id),
	CONSTRAINT fk_init_header_el_tag_grp FOREIGN KEY (app_sid, tag_group_id)
		REFERENCES csr.tag_group (app_sid, tag_group_id),
	CONSTRAINT chk_initiative_header_element
		CHECK ((initiative_metric_id IS NOT NULL AND tag_group_id IS NULL AND init_header_core_element_id IS NULL) OR 
				(initiative_metric_id IS NULL AND tag_group_id IS NOT NULL AND init_header_core_element_id IS NULL) OR
				(initiative_metric_id IS NULL AND tag_group_id IS NULL AND init_header_core_element_id IS NOT NULL))
);

CREATE TABLE csrimp.initiative_header_element (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	initiative_header_element_id	NUMBER(10) NOT NULL,
	pos								NUMBER(10) NOT NULL,
	col								NUMBER(10) NOT NULL,
	initiative_metric_id			NUMBER(10),
	tag_group_id					NUMBER(10),
	init_header_core_element_id		NUMBER(10),
	CONSTRAINT pk_initiative_header_element PRIMARY KEY (csrimp_session_id, initiative_header_element_id),
	CONSTRAINT chk_initiative_header_element
		CHECK ((initiative_metric_id IS NOT NULL AND tag_group_id IS NULL AND init_header_core_element_id IS NULL) OR 
				(initiative_metric_id IS NULL AND tag_group_id IS NOT NULL AND init_header_core_element_id IS NULL) OR
				(initiative_metric_id IS NULL AND tag_group_id IS NULL AND init_header_core_element_id IS NOT NULL)),
	CONSTRAINT fk_initiative_header_el_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_initiative_header_element (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_init_header_element_id		NUMBER(10)	NOT NULL,
	new_init_header_element_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_init_header_element primary key (csrimp_session_id, old_init_header_element_id) USING INDEX,
	CONSTRAINT uk_map_init_header_element unique (csrimp_session_id, new_init_header_element_id) USING INDEX,
    CONSTRAINT fk_map_init_header_element_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.init_tab_element_layout (
	csrimp_session_id	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	element_id			NUMBER(10) NOT NULL,
	plugin_id			NUMBER(10) NOT NULL,
	tag_group_id		NUMBER(10),
	xml_field_id		VARCHAR2(255),
	pos					NUMBER(10) NOT NULL,
	CONSTRAINT pk_initiative_tab_el_layout PRIMARY KEY (csrimp_session_id, element_id),
	CONSTRAINT chk_init_tab_layt_types CHECK ((xml_field_id IS NULL AND tag_group_id IS NULL) OR (xml_field_id IS NOT NULL AND tag_group_id IS NULL) OR (xml_field_id IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_init_tab_element_is FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.idx_init_tab_layout_tag_grp_id ON csrimp.init_tab_element_layout (
	csrimp_session_id, NVL(TO_CHAR(tag_group_id), element_id)
);

CREATE UNIQUE INDEX csrimp.idx_init_tab_layout_xml_fld_id ON csrimp.init_tab_element_layout (
	csrimp_session_id, NVL(TO_CHAR(xml_field_id), element_id)
);


CREATE TABLE csrimp.init_create_page_el_layout (
	csrimp_session_id	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','CSRIMP_SESSION_ID') NOT NULL,
	element_id			VARCHAR2(255) NOT NULL,
	tag_group_id		NUMBER(10),
	xml_field_id		VARCHAR2(255),
	section_id			VARCHAR2(255) NOT NULL,
	pos					NUMBER(10) NOT NULL,
	CONSTRAINT pk_initiative_el_layout PRIMARY KEY (csrimp_session_id, element_id),
	CONSTRAINT chk_init_el_layt_types CHECK ((xml_field_id IS NULL AND tag_group_id IS NULL) OR (xml_field_id IS NOT NULL AND tag_group_id IS NULL) OR (xml_field_id IS NULL AND tag_group_id IS NOT NULL)),
	CONSTRAINT fk_init_create_element_is FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE UNIQUE INDEX csrimp.idx_init_el_layout_tag_grp_id ON csrimp.init_create_page_el_layout (
	csrimp_session_id, NVL(TO_CHAR(tag_group_id), element_id)
);

CREATE TABLE csrimp.map_init_tab_element_layout (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_element_id					NUMBER(10)	NOT NULL,
	new_element_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_init_tab_element primary key (csrimp_session_id, old_element_id) USING INDEX,
	CONSTRAINT uk_map_init_tab_element unique (csrimp_session_id, new_element_id) USING INDEX,
    CONSTRAINT fk_map_init_tab_element_is FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_init_create_page_el_layout (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_element_id					NUMBER(10)	NOT NULL,
	new_element_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_init_cr_pag_element primary key (csrimp_session_id, old_element_id) USING INDEX,
	CONSTRAINT uk_map_init_cr_pag_element unique (csrimp_session_id, new_element_id) USING INDEX,
    CONSTRAINT fk_map_init_cr_pag_element_is FOREIGN KEY(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

create index csr.ix_initiative_ev_initiative_si on csr.initiative_event (app_sid, initiative_sid);
create index csr.ix_initiative_he_initiative_me on csr.initiative_header_element (app_sid, initiative_metric_id);
create index csr.ix_initiative_he_tag_group_id on csr.initiative_header_element (app_sid, tag_group_id);
create index csr.ix_init_create_p_tag_group_id on csr.init_create_page_el_layout (app_sid, tag_group_id);
create index csr.ix_init_tab_elem_plugin_id on csr.init_tab_element_layout (plugin_id);
create index csr.ix_init_tab_elem_tag_group_id on csr.init_tab_element_layout (app_sid, tag_group_id);

-- Alter tables

-- *** Grants ***
grant select, insert, update on csr.init_tab_element_layout to csrimp;
grant select, insert, update on csr.init_create_page_el_layout to csrimp;
grant select, insert, update on csr.initiative_header_element to csrimp;
grant select on csr.initiative_tab_element_id_seq to csrimp;
grant select on csr.init_create_page_el_id_seq to csrimp;
grant select on csr.init_header_element_id_seq to csrimp;
grant select, insert, update, delete on csrimp.init_tab_element_layout to web_user;
grant select, insert, update, delete on csrimp.init_create_page_el_layout to web_user;
grant select, insert, update, delete on csrimp.initiative_header_element to web_user;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
-- For installed customers -- to correct issues from latest2743.
BEGIN
	DBMS_SCHEDULER.DROP_JOB (job_name => 'sys.AUTOMATEDEXPORT');
EXCEPTION
	WHEN OTHERS THEN
    NULL;
END;
/

-- Added to basedata but missing from rev. 305143.
BEGIN
	INSERT INTO CSR.AUDIT_TYPE ( AUDIT_TYPE_GROUP_ID, AUDIT_TYPE_ID, LABEL ) VALUES (1, 23, 'Initiatives');
EXCEPTION
	WHEN DUP_VAL_ON_INDEX THEN
		NULL;
END;
/

BEGIN
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Audit Log',  '/csr/site/initiatives/detail/controls/AuditLogPanel.js', 'Credit360.Initiatives.AuditLogPanel', 
			         'Credit360.Plugins.PluginDto', NULL, NULL, NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Summary',  '/csr/site/initiatives/detail/controls/SummaryPanel.js', 'Credit360.Initiatives.SummaryPanel', 
			         'Credit360.Plugins.PluginDto', NULL, NULL, NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Documents',  '/csr/site/initiatives/detail/controls/DocumentsPanel.js', 'Credit360.Initiatives.DocumentsPanel', 
			         'Credit360.Plugins.PluginDto', NULL, NULL, NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Calendar',  '/csr/site/initiatives/detail/controls/CalendarPanel.js', 'Credit360.Initiatives.CalendarPanel', 
			         'Credit360.Plugins.PluginDto', NULL, NULL, NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Actions',  '/csr/site/initiatives/detail/controls/IssuesPanel.js', 'Credit360.Initiatives.IssuesPanel', 
			         'Credit360.Plugins.PluginDto', NULL, NULL, NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details - What',  
					 '/csr/site/initiatives/detail/controls/WhatPanel.js', 'Credit360.Initiatives.Plugins.WhatPanel', 
			         'Credit360.Plugins.PluginDto', 'Contains core details about the initiative, including the name, reference, project type and description.', 
					 '/csr/shared/plugins/screenshots/initiative_tab_what.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details - Where',  
					 '/csr/site/initiatives/detail/controls/WherePanel.js', 'Credit360.Initiatives.Plugins.WherePanel', 
			         'Credit360.Plugins.PluginDto', 'Contains location information about the initiative, i.e. the regions the initiative will apply to.', 
					 '/csr/shared/plugins/screenshots/initiative_tab_where.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details - When',  
					 '/csr/site/initiatives/detail/controls/WhenPanel.js', 'Credit360.Initiatives.Plugins.WhenPanel', 
			         'Credit360.Plugins.PluginDto', 'Contains timing information about when the initiative will run.', 
					 '/csr/shared/plugins/screenshots/initiative_tab_when.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details - Why',  
					 '/csr/site/initiatives/detail/controls/WhyPanel.js', 'Credit360.Initiatives.Plugins.WhyPanel', 
			         'Credit360.Plugins.PluginDto', 'Contains metrics about the initiative.', 
					 '/csr/shared/plugins/screenshots/initiative_tab_why.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details - Who',  
					 '/csr/site/initiatives/detail/controls/WhoPanel.js', 'Credit360.Initiatives.Plugins.WhoPanel', 
			         'Credit360.Plugins.PluginDto', 'Contains details of who is involved with the initiative.', 
					 '/csr/shared/plugins/screenshots/initiative_tab_who.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
	
	BEGIN
		INSERT INTO csr.plugin (app_sid, plugin_id, plugin_type_id, description, js_include, js_class, cs_class, 
		                    details, preview_image_path, tab_sid, form_path)
			 VALUES (NULL, csr.plugin_id_seq.nextval, 8, 'Initiative details',  
					 '/csr/site/initiatives/detail/controls/InitiativeDetailsPanel.js', 'Credit360.Initiatives.Plugins.InitiativeDetailsPanel', 
			         'Credit360.Plugins.PluginDto', 'Contains all the details of the initiative in one tab (use this instead of the individual what, where, when, why, who tabs).', 
					 '/csr/shared/plugins/screenshots/initiative_tab_initiative_details.png', NULL, NULL);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

DECLARE
	v_details_plugin_id				NUMBER;
	v_docs_plugin_id				NUMBER;
	v_actions_plugin_id				NUMBER;
	v_audit_plugin_id				NUMBER;
	v_registered_users_sid			NUMBER;
	v_count							NUMBER;
	v_act_id						VARCHAR2(36);
	v_admins_sid					NUMBER(10);
	v_menu_sid						NUMBER(10);
	v_www_csr_site					NUMBER(10);
	v_www_sid						NUMBER(10);
	v_wwwroot_sid					NUMBER(10);
BEGIN	
	security.user_pkg.LogonAdmin;
	
	-- Move people on old standard create page to the new one
	UPDATE csr.initiatives_options
	   SET my_initiatives_options = REPLACE(my_initiatives_options, '/csr/site/initiatives/createFull.acds', '/csr/site/initiatives/create.acds')
	 WHERE my_initiatives_options LIKE '%/csr/site/initiatives/createFull.acds%';
	 
	UPDATE security.menu
	   SET action = '/csr/site/initiatives/create.acds'
	 WHERE action = '/csr/site/initiatives/createFull.acds';
	 
	--  Setup default plugins on sites that aren't using initiatives tabs yet (or just have one plugin if they've enabled the audit log)
	SELECT plugin_id
	  INTO v_details_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Initiatives.Plugins.InitiativeDetailsPanel';
	 
	SELECT plugin_id
	  INTO v_docs_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Initiatives.DocumentsPanel';
	 
	SELECT plugin_id
	  INTO v_actions_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Initiatives.IssuesPanel';
	 
	SELECT plugin_id
	  INTO v_audit_plugin_id
	  FROM csr.plugin
	 WHERE js_class = 'Credit360.Initiatives.AuditLogPanel';
	
	FOR r IN (
		SELECT c.host, c.app_sid
		  FROM csr.customer c
		  JOIN csr.initiatives_options io ON c.app_sid = io.app_sid
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		v_registered_users_sid := security.securableobject_pkg.GetSidFromPath(security.security_pkg.GetAct, r.app_sid, 'Groups/RegisteredUsers');
		
		FOR p IN (
			SELECT ip.project_sid 
			  FROM csr.initiative_project ip 
			  LEFT JOIN csr.initiative_project_tab ipt on ip.project_sid = ipt.project_sid 
			 WHERE ip.app_sid = r.app_sid
			 GROUP BY ip.project_sid 
			HAVING COUNT(*) <= 1
		) LOOP
			UPDATE csr.initiative_project_tab
			   SET pos = 5
			 WHERE project_sid = p.project_sid;
			 
			BEGIN
				INSERT INTO csr.initiative_project_tab (app_sid, project_sid, plugin_id, plugin_type_id, pos, tab_label)
				     VALUES (r.app_sid, p.project_sid, v_details_plugin_id, 8, 1, 'Details');
					 
				INSERT INTO csr.initiative_project_tab_group (app_sid, project_sid, plugin_id, group_sid, is_read_only)
				     VALUES (r.app_sid, p.project_sid, v_details_plugin_id, v_registered_users_sid, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
			BEGIN
				INSERT INTO csr.initiative_project_tab (app_sid, project_sid, plugin_id, plugin_type_id, pos, tab_label)
				     VALUES (r.app_sid, p.project_sid, v_docs_plugin_id, 8, 2, 'Documents');
					 
				INSERT INTO csr.initiative_project_tab_group (app_sid, project_sid, plugin_id, group_sid, is_read_only)
				     VALUES (r.app_sid, p.project_sid, v_docs_plugin_id, v_registered_users_sid, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
			BEGIN
				INSERT INTO csr.initiative_project_tab (app_sid, project_sid, plugin_id, plugin_type_id, pos, tab_label)
				     VALUES (r.app_sid, p.project_sid, v_actions_plugin_id, 8, 3, 'Actions');
					 
				INSERT INTO csr.initiative_project_tab_group (app_sid, project_sid, plugin_id, group_sid, is_read_only)
				     VALUES (r.app_sid, p.project_sid, v_actions_plugin_id, v_registered_users_sid, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
			BEGIN
				INSERT INTO csr.initiative_project_tab (app_sid, project_sid, plugin_id, plugin_type_id, pos, tab_label)
				     VALUES (r.app_sid, p.project_sid, v_audit_plugin_id, 8, 4, 'Audit log');
					 
				INSERT INTO csr.initiative_project_tab_group (app_sid, project_sid, plugin_id, group_sid, is_read_only)
				     VALUES (r.app_sid, p.project_sid, v_audit_plugin_id, v_registered_users_sid, 0);
			EXCEPTION
				WHEN dup_val_on_index THEN
					NULL;
			END;
		END LOOP;
		
		-- Setup default header
		SELECT COUNT(*)
		  INTO v_count
		  FROM csr.initiative_header_element
		 WHERE app_sid = r.app_sid;
		 
		IF v_count = 0 THEN
			-- timeline
			INSERT INTO csr.initiative_header_element (app_sid, initiative_header_element_id, pos, col, init_header_core_element_id)
			    VALUES (r.app_sid, csr.init_header_element_id_seq.nextval, 0, 0, 9);
				
			-- project. If they only have one project type, don't add to header
			SELECT COUNT(*)
			  INTO v_count
			  FROM csr.initiative_project
			 WHERE app_sid = r.app_sid;
			
			IF v_count > 1 THEN
				INSERT INTO csr.initiative_header_element (app_sid, initiative_header_element_id, pos, col, init_header_core_element_id)
					 VALUES (r.app_sid, csr.init_header_element_id_seq.nextval, 1, 1, 3);
			END IF;
				
			-- flow status
			INSERT INTO csr.initiative_header_element (app_sid, initiative_header_element_id, pos, col, init_header_core_element_id)
			    VALUES (r.app_sid, csr.init_header_element_id_seq.nextval, 1, 2, 11);
		
		END IF;			
				
		v_act_id := security.security_pkg.GetAct;
		
		BEGIN
			v_admins_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'Groups/Administrators');
			BEGIN
				security.menu_pkg.CreateMenu(v_act_id, security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'),
					'csr_site_initiatives_admin_menu', 'Initiatives admin', '/csr/site/initiatives/admin/menu.acds', 20, null, v_menu_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_menu_sid := security.securableobject_pkg.GetSidFromPath(
						v_act_id, 
						security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'menu/admin'), 
						'csr_site_initiatives_admin_menu'
					);
			END;
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_menu_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
			security.acl_pkg.PropogateACEs(v_act_id, v_menu_sid);
			/*** ADD WEB RESOURCE ***/
			v_wwwroot_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, r.app_sid, 'wwwroot');
			v_www_csr_site := security.securableobject_pkg.GetSidFromPath(v_act_id, v_wwwroot_sid, 'csr/site/initiatives');
			BEGIN
				security.web_pkg.CreateResource(v_act_id, v_wwwroot_sid, v_www_csr_site, 'admin', v_www_sid);
			EXCEPTION
				WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
					v_www_sid := security.securableobject_pkg.GetSidFromPath(v_act_id, v_www_csr_site, 'admin');
			END;
			
			security.acl_pkg.AddACE(v_act_id, security.acl_pkg.GetDACLIDForSID(v_www_sid), -1,
					security.security_pkg.ACE_TYPE_ALLOW,
					security.security_pkg.ACE_FLAG_DEFAULT,
					v_admins_sid,
					security.security_pkg.PERMISSION_STANDARD_ALL);
		EXCEPTION
			WHEN others THEN
				NULL; -- don't mind if they don't have the normal menu structures/group etc.
		END;	
	END LOOP;
		  
	security.user_pkg.LogonAdmin;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE aspen2.application
	   SET default_url = '/csr/site/property/properties/list.acds'
	 WHERE default_url = '/csr/site/property/properties/MyProperties.acds';
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../initiative_pkg
@../schema_pkg

@../initiative_body
@../initiative_project_body
@../enable_body
@../schema_body
@../csr_app_body
@../csrimp/imp_body

@update_tail
