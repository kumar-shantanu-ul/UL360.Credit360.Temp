-- Please update version.sql too -- this keeps clean builds in sync
define version=3034
define minor_version=4
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.compliance_item_status (
	compliance_item_status_id			NUMBER(10) NOT NULL,
	description							VARCHAR2(255) NOT NULL,
	pos									NUMBER(10) NOT NULL,
	CONSTRAINT pk_compliance_item_status PRIMARY KEY (compliance_item_status_id)
);

INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (1, 'Draft', 1);
INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (2, 'Published', 2);
INSERT INTO csr.compliance_item_status (compliance_item_status_id, description, pos) VALUES (3, 'Retired', 3);

CREATE TABLE csr.compliance_item_source (
	compliance_item_source_id			NUMBER(10) NOT NULL,
	description							VARCHAR2(255) NOT NULL,
	CONSTRAINT pk_compliance_item_source PRIMARY KEY (compliance_item_source_id)
);
INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (0, 'User entered');
INSERT INTO csr.compliance_item_source (compliance_item_source_id, description) VALUES (1, 'Enhesa');

CREATE TABLE csr.compliance_item_change_type (
	compliance_item_change_type_id	NUMBER(10,0)	NOT NULL,
	description						VARCHAR2(100)	NOT NULL,
	source							NUMBER(10,0)	NOT NULL,
	change_type_index				NUMBER(10,0)	NOT NULL,
	CONSTRAINT pk_compliance_item_change_type PRIMARY KEY (compliance_item_change_type_id)
);

CREATE SEQUENCE CSR.COMPLIANCE_ITEM_HISTORY_SEQ
    START WITH 1
    INCREMENT BY 1
    NOMINVALUE
    NOMAXVALUE
    CACHE 20
    NOORDER
;

CREATE TABLE CSR.COMPLIANCE_ITEM_HISTORY (
    app_sid                         NUMBER(10, 0)  	DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
    compliance_item_history_id      NUMBER(10, 0)   NOT NULL,
    compliance_item_id              NUMBER(10, 0)   NOT NULL,
    change_type                     NUMBER(10, 0),
    major_version	                NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	is_major_change					NUMBER(1, 0),
    description                     CLOB,
    change_dtm                      DATE			 DEFAULT SYSDATE NOT NULL,
	CONSTRAINT PK_COMPLIANCE_ITEM_HISTORY PRIMARY KEY (APP_SID, COMPLIANCE_ITEM_HISTORY_ID),
	CONSTRAINT fk_compliance_item_his_ci_ct 
		FOREIGN KEY (change_type)
		REFERENCES csr.compliance_item_change_type (compliance_item_change_type_id)
);

CREATE TABLE csrimp.compliance_item_history (
    csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    compliance_item_history_id      NUMBER(10, 0)   NOT NULL,
    compliance_item_id              NUMBER(10, 0)   NOT NULL,
    change_type                     NUMBER(10, 0),
    major_version	                NUMBER(10, 0)	NOT NULL,
	minor_version					NUMBER(10, 0)	NOT NULL,
	is_major_change					NUMBER(1, 0),
    description                     CLOB,
    change_dtm                      DATE            NOT NULL,
	CONSTRAINT pk_compliance_item_history PRIMARY KEY (csrimp_session_id, compliance_item_history_id),
    CONSTRAINT fk_compliance_item_history_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item_history (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_history_id	NUMBER(10) NOT NULL,
	new_compliance_item_history_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item_history PRIMARY KEY (csrimp_session_id, old_compliance_item_history_id),
	CONSTRAINT uk_map_compliance_item_history UNIQUE (csrimp_session_id, new_compliance_item_history_id),
    CONSTRAINT fk_map_compliance_item_history FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

-- Alter tables
ALTER TABLE CSR.compliance_item_history ADD CONSTRAINT fk_cih_ci
    FOREIGN KEY (app_sid, compliance_item_id)
    REFERENCES csr.compliance_item(app_sid, compliance_item_id)
;
ALTER TABLE csr.compliance_item DROP CONSTRAINT ck_compliance_item_source;
ALTER TABLE csr.compliance_item ADD (
	compliance_item_status_id			NUMBER(10) DEFAULT 1 NOT NULL,
	major_version             			NUMBER(10) DEFAULT 1 NOT NULL,
    minor_version             			NUMBER(10) DEFAULT 0 NOT NULL,
	CONSTRAINT fk_compliance_item_ci_status
			FOREIGN KEY (compliance_item_status_id)
			REFERENCES csr.compliance_item_status (compliance_item_status_id),
	CONSTRAINT fk_compliance_item_ci_source 
		FOREIGN KEY (source)
		REFERENCES csr.compliance_item_source (compliance_item_source_id)
);

create index csr.ix_compliance_it_status on csr.compliance_item (compliance_item_status_id);
create index csr.ix_compliance_it_source on csr.compliance_item (source);

ALTER TABLE csrimp.compliance_item ADD (
	compliance_item_status_id			NUMBER(10) NOT NULL,
	major_version						NUMBER(10) NOT NULL,
	minor_version						NUMBER(10) NOT NULL
);


create index csr.ix_compliance_it_his_ct on csr.compliance_item_history (change_type);

create index csr.ix_compliance_it_compliance_it on csr.compliance_item_history (app_sid, compliance_item_id);


-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	BEGIN
		INSERT INTO csr.capability (name, allow_by_default) VALUES ('Manage compliance items', 0);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;
END;
/

ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
	DEFERRABLE INITIALLY DEFERRED
;
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID 
    FOREIGN KEY (APP_SID, GROUP_BY_COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
	DEFERRABLE INITIALLY DEFERRED
;

DECLARE
	v_old_filter_type_id		NUMBER;
BEGIN
	security.user_pkg.LogonAdmin;

	UPDATE chain.card_group
	   SET name = 'Compliance Library Filter',
	       description = 'Allows filtering of global compliance items',
	       helper_pkg = 'csr.compliance_library_report_pkg',
	       list_page_url = '/csr/site/compliance/Library.acds?savedFilterSid='
	 WHERE card_group_id = 48;
	 
	DELETE FROM chain.aggregate_type
	      WHERE card_group_id = 49;
	
	UPDATE chain.aggregate_type
	   SET description = 'Number of items'
	 WHERE card_group_id = 48
	   AND aggregate_type_id = 1;
	
	DELETE FROM chain.card_group_column_type
	      WHERE card_group_id = 49;

	UPDATE chain.card_group_column_type
	   SET description = 'Compliance item region'
	 WHERE card_group_id = 48
	   AND column_id = 1;
	 
	-- Tidy up child tables first
	DELETE FROM chain.filter_item_config
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.filter_page_column
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.filter_cache
	      WHERE card_group_id = 49;
	
	-- I've temporarily made the FK constraints deferred, so this should work
	UPDATE chain.saved_filter
	   SET card_group_id = 48
	 WHERE card_group_id = 49;
	
	UPDATE chain.compound_filter
	   SET card_group_id = 48
	 WHERE card_group_id = 49;
	
	DELETE FROM chain.card_group_card
	      WHERE card_group_id = 49;
	
	DELETE FROM chain.card_group
	      WHERE card_group_id = 49;

	UPDATE chain.card
	   SET description = 'Compliance Library Filter',
	       class_type = 'Credit360.Compliance.Cards.ComplianceLibraryFilter',
	       js_include = '/csr/site/compliance/filters/ComplianceLibraryFilter.js',
	       js_class_type = 'Credit360.Compliance.Filters.ComplianceLibraryFilter'
	 WHERE js_class_type = 'Credit360.Compliance.Requirement.Filters.ComplianceRequirementFilter';

	DELETE FROM chain.card_progression_action WHERE card_id = (
		SELECT card_id 
		  FROM chain.card
	     WHERE js_class_type = 'Credit360.Compliance.Regulation.Filters.ComplianceRegulatonFilter'
	);
	 
	DELETE FROM chain.card
	      WHERE js_class_type = 'Credit360.Compliance.Regulation.Filters.ComplianceRegulatonFilter';
		  
	UPDATE chain.filter_type
	   SET description = 'Compliance Library Filter',
	       helper_pkg = 'csr.compliance_library_report_pkg'
	 WHERE helper_pkg = 'csr.comp_requirement_report_pkg';

	SELECT filter_type_id
	  INTO v_old_filter_type_id
	  FROM chain.filter_type
	 WHERE helper_pkg = 'csr.comp_regulation_report_pkg';
	 
	UPDATE chain.filter
	   SET filter_type_id = (
		SELECT filter_type_id
		  FROM chain.filter_type
		 WHERE helper_pkg = 'csr.compliance_library_report_pkg'
		)
	 WHERE filter_type_id = v_old_filter_type_id;
	 
	DELETE FROM chain.filter_type
	      WHERE filter_type_id = v_old_filter_type_id;
END;
/

ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_CMP_ID 
    FOREIGN KEY (APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;
ALTER TABLE chain.saved_filter DROP CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID;
ALTER TABLE chain.saved_filter ADD CONSTRAINT FK_SAVED_FILTER_GRP_BY_CMP_ID 
    FOREIGN KEY (APP_SID, GROUP_BY_COMPOUND_FILTER_ID, CARD_GROUP_ID)
    REFERENCES CHAIN.COMPOUND_FILTER(APP_SID, COMPOUND_FILTER_ID, CARD_GROUP_ID)
;

DECLARE
	v_act_id						security.security_pkg.T_ACT_ID;
	v_menu_sid						security.security_pkg.T_SID_ID;
BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT c.app_sid, c.host, m.sid_id compliance_menu_sid
		  FROM security.menu m
		  JOIN security.securable_object so ON m.sid_id = so.sid_id
		  JOIN csr.customer c ON so.application_sid_id = c.app_sid
		 WHERE m.action = '/csr/site/compliance/myCompliance.acds'
		   AND so.name = 'csr_compliance'
	) LOOP
		security.user_pkg.LogonAdmin(r.host);
		
		v_act_id := security.security_pkg.GetAct;
		
		UPDATE security.menu
		   SET action = '/csr/site/compliance/LegalRegister.acds'
		 WHERE sid_id = r.compliance_menu_sid;
		
		FOR m IN (
			SELECT m.sid_id
			  FROM security.menu m
			  JOIN security.securable_object so ON m.sid_id = so.sid_id
			 WHERE so.parent_sid_id = r.compliance_menu_sid
			   AND so.application_sid_id = r.app_sid
			   AND so.name IN ('csr_compliance_mycompliance', 'csr_compliance_regulations', 'csr_compliance_requirements')
		) LOOP
			security.securableobject_pkg.DeleteSO(v_act_id, m.sid_id);
		END LOOP;
		 
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_legal_register', 'Legal register', '/csr/site/compliance/LegalRegister.acds', 1, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_calendar', 'Compliance calendar', '/csr/site/compliance/ComplianceCalendar.acds', 2, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_library', 'Compliance library', '/csr/site/compliance/Library.acds', 3, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_create_regulation', 'New regulation', '/csr/site/compliance/CreateItem.acds?type=regulation', 4, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
		BEGIN
			security.menu_pkg.CreateMenu(v_act_id, r.compliance_menu_sid, 'csr_compliance_create_requirement', 'New requirement', '/csr/site/compliance/CreateItem.acds?type=requirement', 5, null, v_menu_sid);
		EXCEPTION
			WHEN security.security_pkg.DUPLICATE_OBJECT_NAME THEN
				NULL;
		END;
	END LOOP;
	
	security.user_pkg.LogonAdmin;
END;
/


INSERT ALL
-- CR360 standard
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (1, 'No change',0, 1 )
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (2, 'New development', 0, 2)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (3, 'Explicit regulatory change', 0,3)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (4, 'Repealing change', 0, 4)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (5, 'Implicit regulatory change', 0, 5)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (6, 'Editorial change that does not impact meaning', 0, 6)	
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (7, 'Improved guidance / analysis', 0, 7)
-- ENHESA
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (8, 'No change',1, 1 )
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (9, 'New development', 1, 2)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (10, 'Explicit regulatory change', 1, 3)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (11, 'Repealing change', 1, 4)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (12, 'Implicit regulatory change', 1, 5)
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (13, 'Editorial change that does not impact meaning', 1, 6)	
   INTO CSR.COMPLIANCE_ITEM_CHANGE_TYPE (compliance_item_change_type_id, description, source, change_type_index) VALUES (14, 'Improved guidance / analysis', 1, 7)
SELECT 1 FROM DUAL;

-- ** New package grants **
create or replace package csr.compliance_library_report_pkg as
	procedure dummy;
end;
/
create or replace package body csr.compliance_library_report_pkg as
	procedure dummy
	as
	begin
		null;
	end;
end;
/

GRANT EXECUTE ON csr.compliance_library_report_pkg TO web_user;
GRANT EXECUTE ON csr.compliance_library_report_pkg TO chain;
GRANT INSERT ON csr.compliance_item_history TO csrimp;

-- *** Conditional Packages ***

-- *** Packages ***
DROP PACKAGE csr.comp_regulation_report_pkg;
DROP PACKAGE csr.comp_requirement_report_pkg;

@../compliance_pkg
@../compliance_library_report_pkg
@../chain/filter_pkg
@../schema_pkg

@../compliance_library_report_body
@../compliance_body
@../schema_body
@../csrimp/imp_body
@../enable_body

@update_tail
