-- Please update version.sql too -- this keeps clean builds in sync
define version=3044
define minor_version=30
@update_header

-- *** DDL ***
-- Create tables
CREATE TABLE csr.comp_item_region_sched_issue (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_item_reg_sched_issue PRIMARY KEY (app_sid, flow_item_id, issue_scheduled_task_id),
	CONSTRAINT fk_cmp_itm_sched_iss_cmp_itm FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.compliance_item_region (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_itm_schd_iss_iss_sched FOREIGN KEY (app_sid, issue_scheduled_task_id)
		REFERENCES csr.issue_scheduled_task (app_sid, issue_scheduled_task_id)
);

CREATE TABLE csrimp.comp_item_region_sched_issue (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	issue_scheduled_task_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_comp_item_reg_sched_issue PRIMARY KEY (csrimp_session_id, flow_item_id, issue_scheduled_task_id),
	CONSTRAINT fk_cmp_itm_rg_sched_issue_is FOREIGN KEY (csrimp_session_id) 
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_scheduled_task (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_scheduled_task_id 	NUMBER(10) NOT NULL,
	new_issue_scheduled_task_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_scheduled_task PRIMARY KEY (csrimp_session_id, old_issue_scheduled_task_id) USING INDEX,
	CONSTRAINT uk_map_issue_scheduled_task UNIQUE (csrimp_session_id, new_issue_scheduled_task_id) USING INDEX,
	CONSTRAINT fk_map_issue_scheduled_task_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE SEQUENCE csr.comp_item_region_log_id_seq;

CREATE TABLE csr.compliance_item_region_log (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	compliance_item_region_log_id	NUMBER(10) NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	log_dtm							DATE DEFAULT SYSDATE NOT NULL,
	user_sid						NUMBER(10) DEFAULT NVL(SYS_CONTEXT('SECURITY','SID'),3) NOT NULL,
	description						VARCHAR2(4000) NOT NULL,
	comment_text					CLOB,
	CONSTRAINT pk_compliance_item_region_log PRIMARY KEY (app_sid, compliance_item_region_log_id),
	CONSTRAINT fk_cmp_itm_reg_log_cmp_itm_reg FOREIGN KEY (app_sid, flow_item_id)
		REFERENCES csr.compliance_item_region (app_sid, flow_item_id),
	CONSTRAINT fk_cmp_itm_reg_log_user FOREIGN KEY (app_sid, user_sid)
		REFERENCES csr.csr_user (app_sid, csr_user_sid)
);

create index csr.ix_compliance_it_flow_item_id on csr.compliance_item_region_log (app_sid, flow_item_id);
create index csr.ix_compliance_it_user_sid on csr.compliance_item_region_log (app_sid, user_sid);

CREATE TABLE csrimp.compliance_item_region_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	compliance_item_region_log_id	NUMBER(10) NOT NULL,
	flow_item_id					NUMBER(10) NOT NULL,
	log_dtm							DATE NOT NULL,
	user_sid						NUMBER(10) NOT NULL,
	description						VARCHAR2(4000) NOT NULL,
	comment_text					CLOB,
	CONSTRAINT pk_compliance_item_region_log PRIMARY KEY (csrimp_session_id, compliance_item_region_log_id),
	CONSTRAINT fk_cmp_itm_reg_log_user_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item_region_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_region_log_id 	NUMBER(10) NOT NULL,
	new_comp_item_region_log_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_comp_item_region_log PRIMARY KEY (csrimp_session_id, old_comp_item_region_log_id) USING INDEX,
	CONSTRAINT uk_map_comp_item_region_log UNIQUE (csrimp_session_id, new_comp_item_region_log_id) USING INDEX,
	CONSTRAINT fk_map_comp_item_region_log_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
	
-- Alter tables
ALTER TABLE csr.issue_scheduled_task ADD (
	issue_type_id					NUMBER(10),
	CONSTRAINT fk_iss_sched_tsk_iss_type FOREIGN KEY (app_sid, issue_type_id) 
		REFERENCES csr.issue_type (app_sid, issue_type_id)
);

ALTER TABLE csrimp.issue_scheduled_task ADD (
	issue_type_id					NUMBER(10)
);

ALTER TABLE csr.issue_scheduled_task ADD (
	scheduled_on_due_date			NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_scheduled_on_due_date_1_0 CHECK (scheduled_on_due_date IN (1, 0))
);

ALTER TABLE csrimp.issue_scheduled_task ADD (
	scheduled_on_due_date			NUMBER(1) NOT NULL,
	CONSTRAINT chk_scheduled_on_due_date_1_0 CHECK (scheduled_on_due_date IN (1, 0))
);

ALTER TABLE csr.temp_compliance_log_ids RENAME COLUMN flow_state_log_id TO compliance_item_region_log_id;

create index csr.ix_comp_item_reg_issue_schedul on csr.comp_item_region_sched_issue (app_sid, issue_scheduled_task_id);
create index csr.ix_issue_schedul_issue_type_id on csr.issue_scheduled_task (app_sid, issue_type_id);

DROP TABLE csr.enhesa_topic_sched_task;
DROP TABLE csr.enhesa_topic_issue;

BEGIN
	security.user_pkg.LogonAdmin;

	FOR r IN (
		SELECT app_sid, issue_id
		  FROM csr.issue
		 WHERE issue_type_id = 19
	) LOOP
		UPDATE csr.issue_log
		   SET issue_id = NULL
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;

		UPDATE csr.issue_action_log
		   SET issue_id = NULL
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_involvement
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_str_val
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_opt_sel 
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		 
		DELETE FROM csr.issue_custom_field_date_val
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		
		DELETE FROM csr.issue_alert
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
		
		DELETE FROM csr.issue
		 WHERE issue_id = r.issue_id
		   AND app_sid = r.app_sid;
	END LOOP;
	
	DELETE FROM csr.issue_type
	 WHERE issue_type_id = 19;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	INSERT INTO csr.compliance_item_region_log (app_sid, compliance_item_region_log_id, 
					flow_item_id, log_dtm, user_sid, description, comment_text)
	 SELECT fsl.app_sid, csr.comp_item_region_log_id_seq.NEXTVAL,
	        fsl.flow_item_id, fsl.set_dtm, set_by_user_sid, 'Entered state: '||fs.label, fsl.comment_text
	   FROM csr.flow_state_log fsl
	   JOIN csr.compliance_item_region cir ON fsl.app_sid = cir.app_sid AND fsl.flow_item_id = cir.flow_item_id
	   JOIN csr.flow_state fs ON fsl.app_sid = fs.app_sid AND fsl.flow_state_id = fs.flow_state_id;
END;
/

-- *** Grants ***
GRANT SELECT, INSERT, UPDATE ON csr.comp_item_region_sched_issue TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.comp_item_region_sched_issue TO tool_user;

GRANT SELECT, INSERT, UPDATE ON csr.compliance_item_region_log TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.compliance_item_region_log TO tool_user;

GRANT SELECT ON csr.comp_item_region_log_id_seq TO csrimp;
GRANT SELECT ON csr.compliance_item_seq TO csrimp;
GRANT SELECT ON csr.compliance_item_history_seq TO csrimp;

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data
BEGIN
	security.user_pkg.LogonAdmin;
	
	UPDATE csr.issue_type
	   SET helper_pkg = 'csr.compliance_pkg'
	 WHERE issue_type_id = 21
	   AND label = 'Compliance';
END;
/

BEGIN
	UPDATE csr.module_param
	   SET param_hint = 'Create regulation workflow? (Y/N)'
	 WHERE module_id = 79
	   AND param_name = 'in_enable_regulation_flow';

	UPDATE csr.module_param
	   SET param_hint = 'Create requirement workflow? (Y/N)'
	 WHERE module_id = 79
	   AND param_name = 'in_enable_requirement_flow';
	   
	UPDATE csr.module
	   SET module_name = 'Compliance - base'
	 WHERE module_id = 79;
END;
/

BEGIN
	security.user_pkg.LogonAdmin;
	
	FOR r IN (
		SELECT sid_id
		  FROM security.menu
		 WHERE LOWER(action) = '/csr/site/enhesa/topiclist.acds'
	) LOOP
		security.securableobject_pkg.DeleteSO(security.security_pkg.GetAct, r.sid_id);
	END LOOP;
	
	FOR r IN (
		SELECT plugin_id
		  FROM csr.plugin
		 WHERE js_class = 'Controls.EnhesaTopicsTab'
	) LOOP
		DELETE FROM csr.property_tab_group
		 WHERE plugin_id = r.plugin_id;
		
		DELETE FROM csr.prop_type_prop_tab
		 WHERE plugin_id = r.plugin_id;
		   
		DELETE FROM csr.property_tab
		 WHERE plugin_id = r.plugin_id;
		 
		DELETE FROM csr.plugin
		 WHERE plugin_id = r.plugin_id;
	END LOOP;
END;
/

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
DROP PACKAGE csr.enhesa_pkg;

@@../issue_pkg
@@../compliance_pkg
@@../schema_pkg
@@../csr_data_pkg

@@../issue_body
@@../issue_report_body
@@../compliance_body
@@../enable_body
@@../schema_body
@@../csrimp/imp_body
@@../csr_app_body

@update_tail
