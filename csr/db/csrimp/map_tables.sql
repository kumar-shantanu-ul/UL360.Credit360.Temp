CREATE TABLE csrimp.map_sid (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sid							NUMBER(10)	NOT NULL,
	new_sid							NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_sid primary key (csrimp_session_id, old_sid) USING INDEX,
	CONSTRAINT uk_map_sid unique (csrimp_session_id, new_sid) USING INDEX,
    CONSTRAINT FK_MAP_SID_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_acl (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_acl_id						NUMBER(10)	NOT NULL,
	new_acl_id						NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_acl primary key (csrimp_session_id, old_acl_id) USING INDEX,
	CONSTRAINT uk_map_acl unique (csrimp_session_id, new_acl_id) USING INDEX,
    CONSTRAINT FK_MAP_ACL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_ip_rule (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_ip_rule_id			NUMBER(10)	NOT NULL,
	new_ip_rule_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_ip_rule primary key (csrimp_session_id, old_ip_rule_id) USING INDEX,
	CONSTRAINT uk_map_ip_rule unique (csrimp_session_id, new_ip_rule_id) USING INDEX,
    CONSTRAINT FK_MAP_IP_RULE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_form_allocation (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_form_allocation_id			NUMBER(10)	NOT NULL,
	new_form_allocation_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_form_allocation primary key (csrimp_session_id, old_form_allocation_id) USING INDEX,
	CONSTRAINT uk_map_form_allocation unique (csrimp_session_id, new_form_allocation_id) USING INDEX,
    CONSTRAINT FK_MAP_FORM_ALLOCATION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_measure_conversion (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_measure_conversion_id		NUMBER(10)	NOT NULL,
	new_measure_conversion_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_measure_conversion primary key (csrimp_session_id, old_measure_conversion_id) USING INDEX,
	CONSTRAINT uk_map_measure_conversion unique (csrimp_session_id, new_measure_conversion_id) USING INDEX,
    CONSTRAINT FK_MAP_MEASURE_CONVERSION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_accuracy_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_accuracy_type_id			NUMBER(10)	NOT NULL,
	new_accuracy_type_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_accuracy_type primary key (csrimp_session_id, old_accuracy_type_id) USING INDEX,
	CONSTRAINT uk_map_accuracy_type unique (csrimp_session_id, new_accuracy_type_id) USING INDEX,
    CONSTRAINT FK_MAP_ACCURACY_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_accuracy_type_option (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_accuracy_type_option_id		NUMBER(10)	NOT NULL,
	new_accuracy_type_option_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_accuracy_type_option primary key (csrimp_session_id, old_accuracy_type_option_id) USING INDEX,
	CONSTRAINT uk_map_accuracy_type_option unique (csrimp_session_id, new_accuracy_type_option_id) USING INDEX,
    CONSTRAINT FK_MAP_ACCURACY_TYPE_OPT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tag_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tag_group_id				NUMBER(10)	NOT NULL,
	new_tag_group_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tag_group primary key (csrimp_session_id, old_tag_group_id) USING INDEX,
	CONSTRAINT uk_map_tag_group unique (csrimp_session_id, new_tag_group_id) USING INDEX,
    CONSTRAINT FK_MAP_TAG_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tag (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tag_id						NUMBER(10)	NOT NULL,
	new_tag_id						NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tag primary key (csrimp_session_id, old_tag_id) USING INDEX,
	CONSTRAINT uk_map_tag unique (csrimp_session_id, new_tag_id) USING INDEX,
    CONSTRAINT FK_MAP_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_baseline_config (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_baseline_config_id			NUMBER(10)	NOT NULL,
	new_baseline_config_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_baseline_config primary key (csrimp_session_id, old_baseline_config_id) USING INDEX,
	CONSTRAINT uk_map_baseline_config unique (csrimp_session_id, new_baseline_config_id) USING INDEX,
    CONSTRAINT FK_MAP_BASELINE_CONFIG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_baseline_config_period (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_baseline_config_period_id			NUMBER(10)	NOT NULL,
	new_baseline_config_period_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_baseline_period_config primary key (csrimp_session_id, old_baseline_config_period_id) USING INDEX,
	CONSTRAINT uk_map_baseline_period_config unique (csrimp_session_id, new_baseline_config_period_id) USING INDEX,
    CONSTRAINT FK_MAP_BASELINE_PERIOD_CONFIG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_alert_frame (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_alert_frame_id				NUMBER(10)	NOT NULL,
	new_alert_frame_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_alert_frame primary key (csrimp_session_id, old_alert_frame_id) USING INDEX,
	CONSTRAINT uk_map_alert_frame unique (csrimp_session_id, new_alert_frame_id) USING INDEX,
    CONSTRAINT FK_MAP_ALERT_FRAME_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_customer_alert_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_customer_alert_type_id				NUMBER(10)	NOT NULL,
	new_customer_alert_type_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_customer_alert_type primary key (csrimp_session_id, old_customer_alert_type_id) USING INDEX,
	CONSTRAINT uk_map_customer_alert_type unique (csrimp_session_id, new_customer_alert_type_id) USING INDEX,
    CONSTRAINT FK_MAP_CUST_ALERT_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_pending_ind (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_pending_ind_id				NUMBER(10)	NOT NULL,
	new_pending_ind_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_pending_ind primary key (csrimp_session_id, old_pending_ind_id) USING INDEX,
	CONSTRAINT uk_map_pending_ind unique (csrimp_session_id, new_pending_ind_id) USING INDEX,
    CONSTRAINT FK_MAP_PENDING_IND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_pending_region (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_pending_region_id			NUMBER(10)	NOT NULL,
	new_pending_region_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_pending_region primary key (csrimp_session_id, old_pending_region_id) USING INDEX,
	CONSTRAINT uk_map_pending_region unique (csrimp_session_id, new_pending_region_id) USING INDEX,
    CONSTRAINT FK_MAP_PENDING_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_pending_period (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_pending_period_id			NUMBER(10)	NOT NULL,
	new_pending_period_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_pending_period primary key (csrimp_session_id, old_pending_period_id) USING INDEX,
	CONSTRAINT uk_map_pending_period unique (csrimp_session_id, new_pending_period_id) USING INDEX,
    CONSTRAINT FK_MAP_PENDING_PERIOD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_pending_val (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_pending_val_id				NUMBER(10)	NOT NULL,
	new_pending_val_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_pending_val primary key (csrimp_session_id, old_pending_val_id) USING INDEX,
	CONSTRAINT uk_map_pending_val unique (csrimp_session_id, new_pending_val_id) USING INDEX,
    CONSTRAINT FK_MAP_PENDING_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_approval_step_sheet (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_approval_step_id			NUMBER(10)	NOT NULL,
	old_sheet_key					varchar2(255) NOT NULL,
	new_approval_step_id			NUMBER(10)	NOT NULL,
	new_sheet_key					varchar2(255) NOT NULL,
	CONSTRAINT pk_map_approval_step_sheet primary key (csrimp_session_id, old_approval_step_id, old_sheet_key) USING INDEX,
	CONSTRAINT uk_map_approval_step_sheet unique (csrimp_session_id, new_approval_step_id, new_sheet_key) USING INDEX,
    CONSTRAINT FK_MAP_APPROVAL_STEP_SHEET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_attachment (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_attachment_id				NUMBER(10)	NOT NULL,
	new_attachment_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_attachment primary key (csrimp_session_id, old_attachment_id) USING INDEX,
	CONSTRAINT uk_map_attachment unique (csrimp_session_id, new_attachment_id) USING INDEX,
    CONSTRAINT FK_MAP_ATTACHMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_alert_id			NUMBER(10)	NOT NULL,
	new_section_alert_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_alert primary key (csrimp_session_id, old_section_alert_id) USING INDEX,
	CONSTRAINT uk_map_section_alert unique (csrimp_session_id, new_section_alert_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_comment (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_comment_id			NUMBER(10)	NOT NULL,
	new_section_comment_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_comment primary key (csrimp_session_id, old_section_comment_id) USING INDEX,
	CONSTRAINT uk_map_section_comment unique (csrimp_session_id, new_section_comment_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_COMMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_trans_comment (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_t_comment_id			NUMBER(10)	NOT NULL,
	new_section_t_comment_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_t_comment primary key (csrimp_session_id, old_section_t_comment_id) USING INDEX,
	CONSTRAINT uk_map_section_t_comment unique (csrimp_session_id, new_section_t_comment_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_T_COMMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SECTION_CART_FOLDER (
	CSRIMP_SESSION_ID 		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	NEW_SECTION_CART_FOLDER_ID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_SECTION_CART_FOLDER  PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SECTION_CART_FOLDER_ID),
	CONSTRAINT FK_MAP_SECTION_CART_FOLDER_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_cart (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_cart_id				NUMBER(10)	NOT NULL,
	new_section_cart_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_cart primary key (csrimp_session_id, old_section_cart_id) USING INDEX,
	CONSTRAINT uk_map_section_cart unique (csrimp_session_id, new_section_cart_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_CART_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_section_tag (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_section_tag_id				NUMBER(10)	NOT NULL,
	new_section_tag_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_section_tag primary key (csrimp_session_id, old_section_tag_id) USING INDEX,
	CONSTRAINT uk_map_section_tag unique (csrimp_session_id, new_section_tag_id) USING INDEX,
    CONSTRAINT FK_MAP_SECTION_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_route (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_route_id					NUMBER(10)	NOT NULL,
	new_route_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_route primary key (csrimp_session_id, old_route_id) USING INDEX,
	CONSTRAINT uk_map_route unique (csrimp_session_id, new_route_id) USING INDEX,
    CONSTRAINT FK_MAP_ROUTE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_route_step (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_route_step_id					NUMBER(10)	NOT NULL,
	new_route_step_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_route_step primary key (csrimp_session_id, old_route_step_id) USING INDEX,
	CONSTRAINT uk_map_route_step unique (csrimp_session_id, new_route_step_id) USING INDEX,
    CONSTRAINT FK_MAP_ROUTE_STEP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_sheet (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sheet_id					NUMBER(10)	NOT NULL,
	new_sheet_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_sheet primary key (csrimp_session_id, old_sheet_id) USING INDEX,
	CONSTRAINT uk_map_sheet unique (csrimp_session_id, new_sheet_id) USING INDEX,
    CONSTRAINT FK_MAP_SHEET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_sheet_value (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sheet_value_id				NUMBER(10)	NOT NULL,
	new_sheet_value_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_sheet_value primary key (csrimp_session_id, old_sheet_value_id) USING INDEX,
	CONSTRAINT uk_map_sheet_value unique (csrimp_session_id, new_sheet_value_id) USING INDEX,
    CONSTRAINT FK_MAP_SHEET_VALUE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_sheet_history (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sheet_history_id			NUMBER(10)	NOT NULL,
	new_sheet_history_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_sheet_history primary key (csrimp_session_id, old_sheet_history_id) USING INDEX,
	CONSTRAINT uk_map_sheet_history unique (csrimp_session_id, new_sheet_history_id) USING INDEX,
    CONSTRAINT FK_MAP_SHEET_HISTORY_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_sheet_value_change (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sheet_value_change_id		NUMBER(10)	NOT NULL,
	new_sheet_value_change_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_sheet_value_change primary key (csrimp_session_id, old_sheet_value_change_id) USING INDEX,
	CONSTRAINT uk_map_sheet_value_change unique (csrimp_session_id, new_sheet_value_change_id) USING INDEX,
    CONSTRAINT FK_MAP_SHEET_VALUE_CHANGE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE csrimp.map_imp_conflict (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_imp_conflict_id				NUMBER(10)	NOT NULL,
	new_imp_conflict_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_imp_conflict primary key (csrimp_session_id, old_imp_conflict_id) USING INDEX,
	CONSTRAINT uk_map_imp_conflict unique (csrimp_session_id, new_imp_conflict_id) USING INDEX,
    CONSTRAINT FK_MAP_IMP_CONFLICT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_imp_ind (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_imp_ind_id					NUMBER(10)	NOT NULL,
	new_imp_ind_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_imp_ind primary key (csrimp_session_id, old_imp_ind_id) USING INDEX,
	CONSTRAINT uk_map_imp_ind unique (csrimp_session_id, new_imp_ind_id) USING INDEX,
    CONSTRAINT FK_MAP_IMP_IND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_imp_region (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_imp_region_id				NUMBER(10)	NOT NULL,
	new_imp_region_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_imp_region primary key (csrimp_session_id, old_imp_region_id) USING INDEX,
	CONSTRAINT uk_map_imp_region unique (csrimp_session_id, new_imp_region_id) USING INDEX,
    CONSTRAINT FK_MAP_IMP_REGION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_imp_measure (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_imp_measure_id				NUMBER(10)	NOT NULL,
	new_imp_measure_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_imp_measure primary key (csrimp_session_id, old_imp_measure_id) USING INDEX,
	CONSTRAINT uk_map_imp_measure unique (csrimp_session_id, new_imp_measure_id) USING INDEX,
    CONSTRAINT FK_MAP_IMP_MEASURE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_imp_val (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_imp_val_id					NUMBER(10)	NOT NULL,
	new_imp_val_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_imp_val primary key (csrimp_session_id, old_imp_val_id) USING INDEX,
	CONSTRAINT uk_map_imp_val unique (csrimp_session_id, new_imp_val_id) USING INDEX,
    CONSTRAINT FK_MAP_IMP_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_val (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_val_id						NUMBER(20)	NOT NULL,
	new_val_id						NUMBER(20)	NOT NULL,
	CONSTRAINT pk_map_val primary key (csrimp_session_id, old_val_id) USING INDEX,
	CONSTRAINT uk_map_val unique (csrimp_session_id, new_val_id) USING INDEX,
    CONSTRAINT FK_MAP_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- ind validation rules
CREATE TABLE csrimp.map_ind_validation_rule (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_ind_validation_rule_id					NUMBER(10)	NOT NULL,
	new_ind_validation_rule_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_ind_validation_rule primary key (csrimp_session_id, old_ind_validation_rule_id) USING INDEX,
	CONSTRAINT uk_map_ind_validation_rule unique (csrimp_session_id, new_ind_validation_rule_id) USING INDEX,
    CONSTRAINT FK_MAP_IND_VALIDTN_RULE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- delegation conditionmaps
CREATE TABLE csrimp.map_delegation_ind_cond (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_delegation_ind_cond_id					NUMBER(10)	NOT NULL,
	new_delegation_ind_cond_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_delegation_ind_cond primary key (csrimp_session_id, old_delegation_ind_cond_id) USING INDEX,
	CONSTRAINT uk_map_delegation_ind_cond unique (csrimp_session_id, new_delegation_ind_cond_id) USING INDEX,
    CONSTRAINT FK_DELEGATION_IND_COND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- plan maps
CREATE TABLE csrimp.map_deleg_plan_col (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_plan_col_id					NUMBER(10)	NOT NULL,
	new_deleg_plan_col_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_deleg_plan_col primary key (csrimp_session_id, old_deleg_plan_col_id) USING INDEX,
	CONSTRAINT uk_map_deleg_plan_col unique (csrimp_session_id, new_deleg_plan_col_id) USING INDEX,
    CONSTRAINT FK_MAP_DELEG_PLAN_COL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_deleg_plan_col_deleg (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_plan_col_deleg_id					NUMBER(10)	NOT NULL,
	new_deleg_plan_col_deleg_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_dlg_plan_col_dlg primary key (csrimp_session_id, old_deleg_plan_col_deleg_id) USING INDEX,
	CONSTRAINT uk_map_dlg_plan_col_dlg unique (csrimp_session_id, new_deleg_plan_col_deleg_id) USING INDEX,
    CONSTRAINT FK_DELEG_PLAN_COL_DELEG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- form_expr map
CREATE TABLE csrimp.map_form_expr (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_form_expr_id					NUMBER(10)	NOT NULL,
	new_form_expr_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_form_expr primary key (csrimp_session_id, old_form_expr_id) USING INDEX,
	CONSTRAINT uk_map_form_expr unique (csrimp_session_id, new_form_expr_id) USING INDEX,
    CONSTRAINT FK_MAP_FORM_EXPR_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

-- factor map
CREATE TABLE csrimp.map_factor (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_factor_id					NUMBER(10)	NOT NULL,
	new_factor_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_factor primary key (csrimp_session_id, old_factor_id) USING INDEX,
	CONSTRAINT uk_map_factor unique (csrimp_session_id, new_factor_id) USING INDEX,
    CONSTRAINT FK_MAP_FACTOR_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


-- deleg_ind_group map
CREATE TABLE csrimp.map_deleg_ind_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_ind_group_id					NUMBER(10)	NOT NULL,
	new_deleg_ind_group_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_deleg_ind_group primary key (csrimp_session_id, old_deleg_ind_group_id) USING INDEX,
	CONSTRAINT uk_map_deleg_ind_group unique (csrimp_session_id, new_deleg_ind_group_id) USING INDEX,
    CONSTRAINT FK_MAP_DELEG_IND_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);


CREATE TABLE csrimp.map_var_expl_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_var_expl_group_id					NUMBER(10)	NOT NULL,
	new_var_expl_group_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_var_expl_group primary key (csrimp_session_id, old_var_expl_group_id) USING INDEX,
	CONSTRAINT uk_map_var_expl_group unique (csrimp_session_id, new_var_expl_group_id) USING INDEX,
    CONSTRAINT FK_MAP_VAR_EXPL_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_var_expl (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_var_expl_id							NUMBER(10)	NOT NULL,
	new_var_expl_id							NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_var_expl primary key (csrimp_session_id, old_var_expl_id) USING INDEX,
	CONSTRAINT uk_map_var_expl unique (csrimp_session_id, new_var_expl_id) USING INDEX,
    CONSTRAINT FK_MAP_VAR_EXPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_aggregate_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_cms_aggregate_type_id			NUMBER(10) NOT NULL,
	new_cms_aggregate_type_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_aggregate_type primary key (csrimp_session_id, old_cms_aggregate_type_id) USING INDEX,
	CONSTRAINT uk_map_cms_aggregate_type unique (csrimp_session_id, new_cms_aggregate_type_id) USING INDEX,
    CONSTRAINT fk_map_cms_aggregate_type_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_schema (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_oracle_schema		varchar2(30) NOT NULL,
	new_oracle_schema		varchar2(30) NOT NULL,
	CONSTRAINT pk_map_cms_schema primary key (csrimp_session_id,old_oracle_schema) USING INDEX,
	CONSTRAINT uk_map_cms_schema unique (csrimp_session_id, new_oracle_schema) USING INDEX,
    CONSTRAINT FK_MAP_CMS_SCHEMA_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_tab_column (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_column_id			NUMBER(10) NOT NULL,
	new_column_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_tab_column primary key (csrimp_session_id, old_column_id) USING INDEX,
	CONSTRAINT uk_map_cms_tab_column unique (csrimp_session_id, new_column_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_TAB_COLUMN_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_tab_column_link (
	CSRIMP_SESSION_ID		NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_column_link_id		NUMBER(10) NOT NULL,
	new_column_link_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_tab_column_link primary key (csrimp_session_id, old_column_link_id) USING INDEX,
	CONSTRAINT uk_map_cms_tab_column_link unique (csrimp_session_id, new_column_link_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_TAB_COLUMN_LINK_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_uk_cons (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_uk_cons_id			NUMBER(10) NOT NULL,
	new_uk_cons_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_uk_cons primary key (csrimp_session_id, old_uk_cons_id) USING INDEX,
	CONSTRAINT uk_map_cms_uk_cons unique (csrimp_session_id, new_uk_cons_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_UK_CONS_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_fk_cons (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_fk_cons_id			NUMBER(10) NOT NULL,
	new_fk_cons_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_fk_cons primary key (csrimp_session_id, old_fk_cons_id) USING INDEX,
	CONSTRAINT uk_map_cms_fk_cons unique (csrimp_session_id, new_fk_cons_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_FK_CONS_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_ck_cons (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_ck_cons_id			NUMBER(10) NOT NULL,
	new_ck_cons_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_ck_cons primary key (csrimp_session_id, old_ck_cons_id) USING INDEX,
	CONSTRAINT uk_map_cms_ck_cons unique (csrimp_session_id, new_ck_cons_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_CK_CONS_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_display_template (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_display_template_id			NUMBER(10) NOT NULL,
	new_display_template_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_display_template primary key (csrimp_session_id, old_display_template_id) USING INDEX,
	CONSTRAINT uk_map_cms_display_template unique (csrimp_session_id, new_display_template_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_DISPLAY_TPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_doc_template (
	CSRIMP_SESSION_ID		NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_id		NUMBER(10)	NOT NULL,
	new_doc_template_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template PRIMARY KEY (csrimp_session_id, old_doc_template_id) USING INDEX,
	CONSTRAINT uk_map_doc_template UNIQUE (csrimp_session_id, new_doc_template_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_doc_template_file (
	csrimp_session_id			NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_template_file_id	NUMBER(10)	NOT NULL,
	new_doc_template_file_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_template_file PRIMARY KEY (csrimp_session_id, old_doc_template_file_id) USING INDEX,
	CONSTRAINT uk_map_doc_template_file UNIQUE (csrimp_session_id, new_doc_template_file_id) USING INDEX,
    CONSTRAINT fk_map_doc_template_file_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_image (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_image_id			NUMBER(10) NOT NULL,
	new_image_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_image primary key (csrimp_session_id, old_image_id) USING INDEX,
	CONSTRAINT uk_map_cms_image unique (csrimp_session_id, new_image_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_IMAGE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_tag (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tag_id			NUMBER(10) NOT NULL,
	new_tag_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_tag primary key (csrimp_session_id, old_tag_id) USING INDEX,
	CONSTRAINT uk_map_cms_tag unique (csrimp_session_id, new_tag_id) USING INDEX,
    CONSTRAINT FK_MAP_CMS_TAG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_cms_enum_group (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_enum_group_id				NUMBER(10) NOT NULL,
	new_enum_group_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_cms_enum_group primary key (csrimp_session_id, old_enum_group_id) USING INDEX,
	CONSTRAINT uk_map_cms_enum_group unique (csrimp_session_id, new_enum_group_id) USING INDEX,
	CONSTRAINT fk_map_cms_enum_group_is FOREIGN KEY
		(csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_state (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_state_id		NUMBER(10) NOT NULL,
	new_flow_state_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_state primary key (csrimp_session_id, old_flow_state_id) USING INDEX,
	CONSTRAINT uk_map_flow_state unique (csrimp_session_id, new_flow_state_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_STATE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
	
CREATE TABLE csrimp.map_flow_item (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_item_id		NUMBER(10) NOT NULL,
	new_flow_item_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_item primary key (csrimp_session_id, old_flow_item_id) USING INDEX,
	CONSTRAINT uk_map_flow_item unique (csrimp_session_id, new_flow_item_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_ITEM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_state_log (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_state_log_id		NUMBER(10) NOT NULL,
	new_flow_state_log_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_state_log primary key (csrimp_session_id, old_flow_state_log_id) USING INDEX,
	CONSTRAINT uk_map_flow_state_log unique (csrimp_session_id, new_flow_state_log_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_STATE_LOG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_state_transition (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_state_transition_id		NUMBER(10) NOT NULL,
	new_flow_state_transition_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_state_transition primary key (csrimp_session_id, old_flow_state_transition_id) USING INDEX,
	CONSTRAINT uk_map_flow_state_transition unique (csrimp_session_id, new_flow_state_transition_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_STATE_TRANS_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_transition_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_transition_alert_id	NUMBER(10) NOT NULL,
	new_flow_transition_alert_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_transition_alert primary key (csrimp_session_id, old_flow_transition_alert_id) USING INDEX,
	CONSTRAINT uk_map_flow_transition_alert unique (csrimp_session_id, new_flow_transition_alert_id) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_TRANS_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_state_rl_cap (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_state_rl_cap_id		NUMBER(10) NOT NULL,
	new_flow_state_rl_cap_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_state_rl_cap primary key (csrimp_session_id, old_flow_state_rl_cap_id) USING INDEX,
	CONSTRAINT uk_map_flow_state_rl_cap unique (csrimp_session_id, new_flow_state_rl_cap_id) USING INDEX,
    CONSTRAINT FK_FLOW_STATE_RL_CAP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_raw_data_source  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_raw_data_source_id			NUMBER(10) NOT NULL,
	new_raw_data_source_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_raw_data_source primary key (csrimp_session_id, old_raw_data_source_id) USING INDEX,
	CONSTRAINT uk_map_meter_raw_data_source unique (csrimp_session_id, new_raw_data_source_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_RAW_DATA_SRC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_bucket  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_bucket_id			NUMBER(10) NOT NULL,
	new_meter_bucket_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_bucket primary key (csrimp_session_id, old_meter_bucket_id) USING INDEX,
	CONSTRAINT uk_map_meter_bucket unique (csrimp_session_id, new_meter_bucket_id) USING INDEX,
    CONSTRAINT FK_MAP_MTR_BUCKET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_data_id  (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_data_id			NUMBER(10) NOT NULL,
	new_meter_data_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_data_id primary key (csrimp_session_id, old_meter_data_id) USING INDEX,
	CONSTRAINT uk_map_meter_bucket_id unique (csrimp_session_id, new_meter_data_id) USING INDEX,
    CONSTRAINT fk_map_meter_data_id FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_aggregate_type  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_aggregate_type_id		NUMBER(10) NOT NULL,
	new_meter_aggregate_type_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_aggregate_type primary key (csrimp_session_id, old_meter_aggregate_type_id) USING INDEX,
	CONSTRAINT uk_map_meter_aggregate_type unique (csrimp_session_id, new_meter_aggregate_type_id) USING INDEX,
    CONSTRAINT fk_map_meter_aggregate_type FOREIGN KEY
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

CREATE TABLE csrimp.map_utility_supplier  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_utility_supplier_id			NUMBER(10) NOT NULL,
	new_utility_supplier_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_utility_supplier primary key (csrimp_session_id, old_utility_supplier_id) USING INDEX,
	CONSTRAINT uk_map_utility_supplier unique (csrimp_session_id, new_utility_supplier_id) USING INDEX,
    CONSTRAINT FK_MAP_UTILIY_SUPPLIER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_utility_contract  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_utility_contract_id			NUMBER(10) NOT NULL,
	new_utility_contract_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_utility_contract primary key (csrimp_session_id, old_utility_contract_id) USING INDEX,
	CONSTRAINT uk_map_utility_contract unique (csrimp_session_id, new_utility_contract_id) USING INDEX,
    CONSTRAINT FK_MAP_UTILITY_ONCTRACT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_utility_invoice  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_utility_invoice_id			NUMBER(10) NOT NULL,
	new_utility_invoice_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_utility_invoice primary key (csrimp_session_id, old_utility_invoice_id) USING INDEX,
	CONSTRAINT uk_map_utility_invoice unique (csrimp_session_id, new_utility_invoice_id) USING INDEX,
    CONSTRAINT FK_MAP_UTILITY_INVOICE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_alarm  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_alarm_id			NUMBER(10) NOT NULL,
	new_meter_alarm_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_alarm primary key (csrimp_session_id, old_meter_alarm_id) USING INDEX,
	CONSTRAINT uk_map_meter_alarm unique (csrimp_session_id, new_meter_alarm_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_ALARM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_alarm_statistic  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_statistic_id			NUMBER(10) NOT NULL,
	new_statistic_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_alarm_statistic primary key (csrimp_session_id, old_statistic_id) USING INDEX,
	CONSTRAINT uk_map_meter_alarm_statistic unique (csrimp_session_id, new_statistic_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_ALARMA_STAT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_alarm_comparison  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comparison_id			NUMBER(10) NOT NULL,
	new_comparison_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_alarm_comparison primary key (csrimp_session_id, old_comparison_id) USING INDEX,
	CONSTRAINT uk_map_meter_alarm_comparison unique (csrimp_session_id, new_comparison_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_ALARM_COMP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_alarm_test_time  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_test_time_id			NUMBER(10) NOT NULL,
	new_test_time_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_alarm_test_time primary key (csrimp_session_id, old_test_time_id) USING INDEX,
	CONSTRAINT uk_map_meter_alarm_test_time unique (csrimp_session_id, new_test_time_id) USING INDEX,
    CONSTRAINT FK_MAP_MTR_ALRM_TST_TIME_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_core_working_hours  (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_core_working_hours_id	NUMBER(10) NOT NULL,
	new_core_working_hours_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_core_working_hours primary key (csrimp_session_id, old_core_working_hours_id) USING INDEX,
	CONSTRAINT uk_map_core_working_hours unique (csrimp_session_id, new_core_working_hours_id) USING INDEX,
	CONSTRAINT fk_map_core_working_hours FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_alarm_issue_period  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_period_id			NUMBER(10) NOT NULL,
	new_issue_period_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_alrm_iss_period primary key (csrimp_session_id, old_issue_period_id) USING INDEX,
	CONSTRAINT uk_map_meter_alrm_iss_period unique (csrimp_session_id, new_issue_period_id) USING INDEX,
    CONSTRAINT FK_MAP_MTR_ALRM_ISS_PRD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_raw_data  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_raw_data_id			NUMBER(10) NOT NULL,
	new_meter_raw_data_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_raw_data primary key (csrimp_session_id, old_meter_raw_data_id) USING INDEX,
	CONSTRAINT uk_map_meter_raw_data unique (csrimp_session_id, new_meter_raw_data_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_RAW_DATA_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_reading  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_reading_id			NUMBER(10) NOT NULL,
	new_meter_reading_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_reading primary key (csrimp_session_id, old_meter_reading_id) USING INDEX,
	CONSTRAINT uk_map_meter_reading unique (csrimp_session_id, new_meter_reading_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_READING_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_event  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_event_id			NUMBER(10) NOT NULL,
	new_event_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_event primary key (csrimp_session_id, old_event_id) USING INDEX,
	CONSTRAINT uk_map_event unique (csrimp_session_id, new_event_id) USING INDEX,
    CONSTRAINT FK_MAP_EVENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_document  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_meter_document_id			NUMBER(10) NOT NULL,
	new_meter_document_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_meter_document primary key (csrimp_session_id, old_meter_document_id) USING INDEX,
	CONSTRAINT uk_map_meter_document unique (csrimp_session_id, new_meter_document_id) USING INDEX,
    CONSTRAINT FK_MAP_METER_DOCUMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_pending_val (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_pending_val_id			NUMBER(10) NOT NULL,
	new_issue_pending_val_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_pending_val primary key (csrimp_session_id, old_issue_pending_val_id) USING INDEX,
	CONSTRAINT uk_map_issue_pending_val unique (csrimp_session_id, new_issue_pending_val_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_PENDING_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
	
CREATE TABLE csrimp.map_issue_sheet_value (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_sheet_value_id			NUMBER(10) NOT NULL,
	new_issue_sheet_value_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_sheet_value primary key (csrimp_session_id, old_issue_sheet_value_id) USING INDEX,
	CONSTRAINT uk_map_issue_sheet_value unique (csrimp_session_id, new_issue_sheet_value_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_SHEET_VAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_meter  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_meter_id			NUMBER(10) NOT NULL,
	new_issue_meter_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_meter primary key (csrimp_session_id, old_issue_meter_id) USING INDEX,
	CONSTRAINT uk_map_issue_meter unique (csrimp_session_id, new_issue_meter_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_METER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_meter_alarm  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_meter_alarm_id			NUMBER(10) NOT NULL,
	new_issue_meter_alarm_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_meter_alarm primary key (csrimp_session_id, old_issue_meter_alarm_id) USING INDEX,
	CONSTRAINT uk_map_issue_meter_alarm unique (csrimp_session_id, new_issue_meter_alarm_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_METER_ALARM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_meter_data_source  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_meter_data_source_id			NUMBER(10) NOT NULL,
	new_issue_meter_data_source_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_meter_data_source primary key (csrimp_session_id, old_issue_meter_data_source_id) USING INDEX,
	CONSTRAINT uk_map_issue_meter_data_source unique (csrimp_session_id, new_issue_meter_data_source_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_MTR_DAT_SRC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_meter_raw_data  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_meter_raw_data_id			NUMBER(10) NOT NULL,
	new_issue_meter_raw_data_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_meter_raw_data primary key (csrimp_session_id, old_issue_meter_raw_data_id) USING INDEX,
	CONSTRAINT uk_map_issue_meter_raw_data unique (csrimp_session_id, new_issue_meter_raw_data_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_MTR_RAW_DAT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_priority  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_priority_id			NUMBER(10) NOT NULL,
	new_issue_priority_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_priority primary key (csrimp_session_id, old_issue_priority_id) USING INDEX,
	CONSTRAINT uk_map_issue_priority unique (csrimp_session_id, new_issue_priority_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_PRIORITY_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_rag_status (
    CSRIMP_SESSION_ID           NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_rag_status_id           NUMBER(10) NOT NULL,
    new_rag_status_id           NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_rag_status primary key (csrimp_session_id, old_rag_status_id) USING INDEX,
    CONSTRAINT uk_map_rag_status unique (csrimp_session_id, new_rag_status_id) USING INDEX,
    CONSTRAINT FK_MAP_RAG_STATUS_IS FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_id			NUMBER(10) NOT NULL,
	new_issue_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue primary key (csrimp_session_id, old_issue_id) USING INDEX,
	CONSTRAINT uk_map_issue unique (csrimp_session_id, new_issue_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_log  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_log_id			NUMBER(10) NOT NULL,
	new_issue_log_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_log primary key (csrimp_session_id, old_issue_log_id) USING INDEX,
	CONSTRAINT uk_map_issue_log unique (csrimp_session_id, new_issue_log_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_LOG_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_custom_field  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_custom_field_id			NUMBER(10) NOT NULL,
	new_issue_custom_field_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_issue_custom_field primary key (csrimp_session_id, old_issue_custom_field_id) USING INDEX,
	CONSTRAINT uk_map_issue_custom_field unique (csrimp_session_id, new_issue_custom_field_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_CUSTOM_FIELD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_correspondent  (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_correspondent_id			NUMBER(10) NOT NULL,
	new_correspondent_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_correspondent primary key (csrimp_session_id, old_correspondent_id) USING INDEX,
	CONSTRAINT uk_map_correspondent unique (csrimp_session_id, new_correspondent_id) USING INDEX,
    CONSTRAINT FK_MAP_CORRESPONDENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_deleg_plan_col_survey (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_plan_col_survey_id	NUMBER(10)	NOT NULL,
	new_deleg_plan_col_survey_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_deleg_plan_col_survey primary key (csrimp_session_id, old_deleg_plan_col_survey_id) USING INDEX,
	CONSTRAINT uk_map_deleg_plan_col_survey unique (csrimp_session_id, new_deleg_plan_col_survey_id) USING INDEX,
    CONSTRAINT FK_MAP_DLG_PLAN_COL_SRV_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tab (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tab_id						NUMBER(10)	NOT NULL,
	new_tab_id						NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tab primary key (csrimp_session_id, old_tab_id) USING INDEX,
	CONSTRAINT uk_map_tab unique (csrimp_session_id, new_tab_id) USING INDEX,
    CONSTRAINT FK_MAP_TAB_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tab_portlet (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tab_portlet_id				NUMBER(10)	NOT NULL,
	new_tab_portlet_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tab_portlet primary key (csrimp_session_id, old_tab_portlet_id) USING INDEX,
	CONSTRAINT uk_map_tab_portlet unique (csrimp_session_id, new_tab_portlet_id) USING INDEX,
    CONSTRAINT FK_MAP_TAB_PORTLET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_dashboard_instance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_dashboard_instance_id		NUMBER(10)	NOT NULL,
	new_dashboard_instance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_dashboard_instance primary key (csrimp_session_id, old_dashboard_instance_id) USING INDEX,
	CONSTRAINT uk_map_dashboard_instance unique (csrimp_session_id, new_dashboard_instance_id) USING INDEX,
    CONSTRAINT FK_MAP_DASHBOARD_INSTANCE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_non_compl (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_non_compl_id	NUMBER(10)	NOT NULL,
	new_tpl_report_non_compl_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_non_compl primary key (csrimp_session_id, old_tpl_report_non_compl_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_non_compl unique (csrimp_session_id, new_tpl_report_non_compl_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_ind (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_ind_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_ind_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_ind primary key (csrimp_session_id, old_tpl_report_tag_ind_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_ind unique (csrimp_session_id, new_tpl_report_tag_ind_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_IND_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_eval (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_eval_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_eval_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_eval primary key (csrimp_session_id, old_tpl_report_tag_eval_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_eval unique (csrimp_session_id, new_tpl_report_tag_eval_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_EVAL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_dv (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_dv_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_dv_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_dv primary key (csrimp_session_id, old_tpl_report_tag_dv_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_dv unique (csrimp_session_id, new_tpl_report_tag_dv_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_DV_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_qc (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_qc_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_qc_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_qc primary key (csrimp_session_id, old_tpl_report_tag_qc_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_qc unique (csrimp_session_id, new_tpl_report_tag_qc_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_QC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_log_frm (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_log_frm_id	NUMBER(10)	NOT NULL,
	new_tpl_report_tag_log_frm_id	NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_log_frm primary key (csrimp_session_id, old_tpl_report_tag_log_frm_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_log_frm unique (csrimp_session_id, new_tpl_report_tag_log_frm_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_LOG_FRM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_text (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_text_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_text_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_text primary key (csrimp_session_id, old_tpl_report_tag_text_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_text unique (csrimp_session_id, new_tpl_report_tag_text_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_TEXT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_rep_tag_appr_note (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_rep_tag_appr_note_id		NUMBER(10)	NOT NULL,
	new_tpl_rep_tag_appr_note_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_rep_tag_appr_note primary key (csrimp_session_id, old_tpl_rep_tag_appr_note_id) USING INDEX,
	CONSTRAINT uk_map_tpl_rep_tag_appr_note unique (csrimp_session_id, new_tpl_rep_tag_appr_note_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_APPR_N_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_appr_dash_val (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_approval_dashboard_val_id		NUMBER(10)	NOT NULL,
	new_approval_dashboard_val_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_approval_dash_val primary key (csrimp_session_id, old_approval_dashboard_val_id) USING INDEX,
	CONSTRAINT uk_map_approval_dash_val unique (csrimp_session_id, new_approval_dashboard_val_id) USING INDEX,
    CONSTRAINT fk_map_approval_dash_val_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_appr_dash_val_src (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_approval_dash_val_src_id		NUMBER(10)	NOT NULL,
	new_approval_dash_val_src_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_appr_dash_val_src primary key (csrimp_session_id, old_approval_dash_val_src_id) USING INDEX,
	CONSTRAINT uk_map_appr_dash_val_src unique (csrimp_session_id, new_approval_dash_val_src_id) USING INDEX,
    CONSTRAINT fk_map_appr_dash_val_src_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_appr_matr (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_rep_tag_appr_matr_id		NUMBER(10)	NOT NULL,
	new_tpl_rep_tag_appr_matr_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_rep_tag_appr_matr primary key (csrimp_session_id, old_tpl_rep_tag_appr_matr_id) USING INDEX,
	CONSTRAINT uk_map_tpl_rep_tag_appr_matr unique (csrimp_session_id, new_tpl_rep_tag_appr_matr_id) USING INDEX,
    CONSTRAINT FK_MAP_TPL_REP_TAG_APPR_M_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tpl_report_tag_reg_data (
	csrimp_session_id					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	new_tpl_report_tag_reg_data_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_tpl_report_tag_reg_data PRIMARY KEY (csrimp_session_id, old_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT uk_map_tpl_report_tag_reg_data UNIQUE (csrimp_session_id, new_tpl_report_tag_reg_data_id) USING INDEX,
	CONSTRAINT fk_map_tpl_rep_tag_reg_data_is FOREIGN KEY
		(csrimp_session_id) REFERENCES CSRIMP.CSRIMP_SESSION (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_aggregate_ind_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_aggregate_ind_group_id		NUMBER(10)	NOT NULL,
	new_aggregate_ind_group_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_aggregate_ind_group primary key (csrimp_session_id, old_aggregate_ind_group_id) USING INDEX,
	CONSTRAINT uk_map_aggregate_ind_group unique (csrimp_session_id, new_aggregate_ind_group_id) USING INDEX,
    CONSTRAINT FK_MAP_AGGR_IND_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_dashboard_item (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_dashboard_item_id			NUMBER(10)	NOT NULL,
	new_dashboard_item_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_dashboard_item primary key (csrimp_session_id, old_dashboard_item_id) USING INDEX,
	CONSTRAINT uk_map_dashboard_item unique (csrimp_session_id, new_dashboard_item_id) USING INDEX,
    CONSTRAINT FK_MAP_DASHBOARD_ITEM_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_user_cover (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_user_cover_id				NUMBER(10)	NOT NULL,
	new_user_cover_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_user_cover primary key (csrimp_session_id, old_user_cover_id) USING INDEX,
	CONSTRAINT uk_map_user_cover unique (csrimp_session_id, new_user_cover_id) USING INDEX,
    CONSTRAINT FK_MAP_USER_COVER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_doc (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_id						NUMBER(10)	NOT NULL,
	new_doc_id						NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc primary key (csrimp_session_id, old_doc_id) USING INDEX,
	CONSTRAINT uk_map_doc unique (csrimp_session_id, new_doc_id) USING INDEX,
    CONSTRAINT FK_MAP_DOC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_DOC_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DOC_TYPE_ID					NUMBER(10)	NOT NULL,
	NEW_DOC_TYPE_ID					NUMBER(10)	NOT NULL,
    CONSTRAINT FK_MAP_DOC_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_doc_data (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_doc_data_id					NUMBER(10)	NOT NULL,
	new_doc_data_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_doc_data primary key (csrimp_session_id, old_doc_data_id) USING INDEX,
	CONSTRAINT uk_map_doc_data unique (csrimp_session_id, new_doc_data_id) USING INDEX,
    CONSTRAINT FK_MAP_DOC_DATA_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_internal_audit_type_id		NUMBER(10)	NOT NULL,
	new_internal_audit_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_internal_audit_type primary key (csrimp_session_id, old_internal_audit_type_id) USING INDEX,
	CONSTRAINT uk_map_internal_audit_type unique (csrimp_session_id, new_internal_audit_type_id) USING INDEX,
    CONSTRAINT FK_MAP_INTENAL_AUDIT_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_type_report (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_internal_audit_type_rep_id		NUMBER(10)	NOT NULL,
	new_internal_audit_type_rep_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_internal_audit_type_rep primary key (csrimp_session_id, old_internal_audit_type_rep_id) USING INDEX,
	CONSTRAINT uk_map_internal_audit_type_rep unique (csrimp_session_id, new_internal_audit_type_rep_id) USING INDEX,
	CONSTRAINT FK_MAP_INTENAL_AUDIT_TYPE_REP FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_ia_type_report_group (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_ia_type_report_group_id			NUMBER(10)	NOT NULL,
	new_ia_type_report_group_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_ia_type_report_group primary key (csrimp_session_id, old_ia_type_report_group_id) USING INDEX,
	CONSTRAINT uk_map_ia_type_report_group unique (csrimp_session_id, new_ia_type_report_group_id) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_REPORT_GROUP FOREIGN KEY
		(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
		ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_type_group (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_inter_audit_type_group_id		NUMBER(10)	NOT NULL,
	new_inter_audit_type_group_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_inter_audit_type_group primary key (csrimp_session_id, old_inter_audit_type_group_id) USING INDEX,
	CONSTRAINT uk_map_inter_audit_type_group unique (csrimp_session_id, new_inter_audit_type_group_id) USING INDEX,
    CONSTRAINT FK_MAP_INT_AUDIT_TYPE_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_internal_audit_file_data (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_int_audit_file_data_id		NUMBER(10) NOT NULL,
	new_int_audit_file_data_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_internal_audit_file primary key (csrimp_session_id, old_int_audit_file_data_id) USING INDEX,
	CONSTRAINT uk_map_internal_audit_file unique (csrimp_session_id, new_int_audit_file_data_id) USING INDEX,
    CONSTRAINT fk_map_internal_audit_file_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_audit_closure_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_audit_closure_type_id		NUMBER(10)	NOT NULL,
	new_audit_closure_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_audit_closure_type primary key (csrimp_session_id, old_audit_closure_type_id) USING INDEX,
	CONSTRAINT uk_map_audit_closure_type unique (csrimp_session_id, new_audit_closure_type_id) USING INDEX,
    CONSTRAINT FK_MAP_AUDIT_CLOSURE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_model_range (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_range_id					NUMBER(10)	NOT NULL,
	new_range_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_model_range primary key (csrimp_session_id, old_range_id) USING INDEX,
	CONSTRAINT uk_map_model_range unique (csrimp_session_id, new_range_id) USING INDEX,
    CONSTRAINT FK_MAP_MODEL_RANGE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_model_sheet (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_sheet_id					NUMBER(10)	NOT NULL,
	new_sheet_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_model_sheet primary key (csrimp_session_id, old_sheet_id) USING INDEX,
	CONSTRAINT uk_map_model_sheet unique (csrimp_session_id, new_sheet_id) USING INDEX,
    CONSTRAINT FK_MAP_MODEL_SHEET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_compliance_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_compliance_type_id		NUMBER(10)	NOT NULL,
	new_non_compliance_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_non_compliance_type primary key (csrimp_session_id, old_non_compliance_type_id) USING INDEX,
	CONSTRAINT uk_map_non_compliance_type unique (csrimp_session_id, new_non_compliance_type_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMPLIANCE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_compliance_id			NUMBER(10)	NOT NULL,
	new_non_compliance_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_non_compliance primary key (csrimp_session_id, old_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_non_compliance unique (csrimp_session_id, new_non_compliance_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMPLIANCE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_audit_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	new_audit_non_compliance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_audit_non_compliance primary key (csrimp_session_id, old_audit_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_audit_non_compliance unique (csrimp_session_id, new_audit_non_compliance_id) USING INDEX,
    CONSTRAINT fk_map_audit_non_compliance_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_quick_survey_type_id		NUMBER(10)	NOT NULL,
	new_quick_survey_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_type primary key (csrimp_session_id, old_quick_survey_type_id) USING INDEX,
	CONSTRAINT uk_map_qs_type unique (csrimp_session_id, new_quick_survey_type_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_survey_response (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_survey_response_id			NUMBER(10)	NOT NULL,
	new_survey_response_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_survey_response primary key (csrimp_session_id, old_survey_response_id) USING INDEX,
	CONSTRAINT uk_map_qs_survey_response unique (csrimp_session_id, new_survey_response_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_RESPONSE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_question (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_question_id					NUMBER(10)	NOT NULL,
	new_question_id					NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_question primary key (csrimp_session_id, old_question_id) USING INDEX,
	CONSTRAINT uk_map_qs_question unique (csrimp_session_id, new_question_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_QUESTION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_custom_question_type (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_custom_question_type_id		NUMBER(10)	NOT NULL,
	new_custom_question_type_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_cust_quest_type primary key (csrimp_session_id, old_custom_question_type_id) USING INDEX,
	CONSTRAINT uk_map_qs_cust_quest_type unique (csrimp_session_id, new_custom_question_type_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_CUST_QUEST_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_submission (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_submission_id				NUMBER(10)	NOT NULL,
	new_submission_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_submission primary key (csrimp_session_id, old_submission_id) USING INDEX,
	CONSTRAINT uk_map_qs_submission unique (csrimp_session_id, new_submission_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_SUBMISSION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_score_threshold (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_score_threshold_id			NUMBER(10)	NOT NULL,
	new_score_threshold_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_score_threshold primary key (csrimp_session_id, old_score_threshold_id) USING INDEX,
	CONSTRAINT uk_map_score_threshold unique (csrimp_session_id, new_score_threshold_id) USING INDEX,
    CONSTRAINT FK_MAP_SCORE_THRESHOLD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SCORE_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCORE_TYPE_ID			NUMBER(10)	NOT NULL,
	NEW_SCORE_TYPE_ID			NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_SCORE_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SCORE_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCORE_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_SCORE_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_SCORE_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SCORE_TYPE_AGG_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	NEW_SCORE_TYPE_AGG_TYPE_ID			NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_SCORE_TYPE_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SCORE_TYPE_AGG_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCORE_TYPE_AGG_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_SCORE_TYPE_AGG_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_SCORE_TYPE_AGG_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_question_option (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_question_option_id			NUMBER(10)	NOT NULL,
	new_question_option_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_question_option primary key (csrimp_session_id, old_question_option_id) USING INDEX,
	CONSTRAINT uk_map_qs_question_option unique (csrimp_session_id, new_question_option_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_QUEST_OPT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_answer_file (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_qs_answer_file_id			NUMBER(10)	NOT NULL,
	new_qs_answer_file_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_answer_file primary key (csrimp_session_id, old_qs_answer_file_id) USING INDEX,
	CONSTRAINT uk_map_qs_answer_file unique (csrimp_session_id, new_qs_answer_file_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_ANS_FILE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_expr (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_expr_id						NUMBER(10)	NOT NULL,
	new_expr_id						NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_expr primary key (csrimp_session_id, old_expr_id) USING INDEX,
	CONSTRAINT uk_map_qs_expr unique (csrimp_session_id, new_expr_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_EXPR_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_expr_msg_action (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_qs_expr_msg_action_id		NUMBER(10)	NOT NULL,
	new_qs_expr_msg_action_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_expr_msg_action primary key (csrimp_session_id, old_qs_expr_msg_action_id) USING INDEX,
	CONSTRAINT uk_map_qs_expr_msg_action unique (csrimp_session_id, new_qs_expr_msg_action_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_EXPR_MSG_ACTION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_qs_expr_nc_action (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_qs_expr_nc_action_id		NUMBER(10)	NOT NULL,
	new_qs_expr_nc_action_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_qs_expr_nc_action primary key (csrimp_session_id, old_qs_expr_nc_action_id) USING INDEX,
	CONSTRAINT uk_map_qs_expr_nc_action unique (csrimp_session_id, new_qs_expr_nc_action_id) USING INDEX,
    CONSTRAINT FK_MAP_QS_EXPR_NC_ACTION_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_region_set (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_region_set_id				NUMBER(10)	NOT NULL,
	new_region_set_id				NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_region_set primary key (csrimp_session_id, old_region_set_id) USING INDEX,
	CONSTRAINT uk_map_region_set unique (csrimp_session_id, new_region_set_id) USING INDEX,
    CONSTRAINT FK_MAP_REGION_SET_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_postit (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_postit_id			NUMBER(10)	NOT NULL,
	new_postit_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_postit primary key (csrimp_session_id, old_postit_id) USING INDEX,
	CONSTRAINT uk_map_postit unique (csrimp_session_id, new_postit_id) USING INDEX,
    CONSTRAINT FK_MAP_POSTIT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_survey_answer (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_survey_answer_id		NUMBER(10)	NOT NULL,
	new_issue_survey_answer_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_issue_survey_answer primary key (csrimp_session_id, old_issue_survey_answer_id) USING INDEX,
	CONSTRAINT uk_map_issue_survey_answer unique (csrimp_session_id, new_issue_survey_answer_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_SURVEY_ANSWER_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_issue_non_compliance (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_issue_non_compliance_id		NUMBER(10)	NOT NULL,
	new_issue_non_compliance_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_issue_non_compliance primary key (csrimp_session_id, old_issue_non_compliance_id) USING INDEX,
	CONSTRAINT uk_map_issue_non_compliance unique (csrimp_session_id, new_issue_non_compliance_id) USING INDEX,
    CONSTRAINT FK_MAP_ISSUE_NON_COMPL_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_alert (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_alert_id					RAW(16) NOT NULL,
	new_alert_id					RAW(16) NOT NULL,
	CONSTRAINT pk_map_alert primary key (csrimp_session_id, old_alert_id) USING INDEX,
	CONSTRAINT uk_map_alert unique (csrimp_session_id, new_alert_id) USING INDEX,
    CONSTRAINT FK_MAP_ALERT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_comp_default (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_id			NUMBER(10) NOT NULL,
	new_non_comp_default_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default primary key (csrimp_session_id, old_non_comp_default_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default unique (csrimp_session_id, new_non_comp_default_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEFAULT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_comp_default_folder (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_folder_id	NUMBER(10) NOT NULL,
	new_non_comp_default_folder_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default_folder primary key (csrimp_session_id, old_non_comp_default_folder_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default_folder unique (csrimp_session_id, new_non_comp_default_folder_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEFAULT_FLD_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_comp_default_issue (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_comp_default_issue_id	NUMBER(10) NOT NULL,
	new_non_comp_default_issue_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_non_comp_default_issue primary key (csrimp_session_id, old_non_comp_default_issue_id) USING INDEX,
	CONSTRAINT uk_map_non_comp_default_issue unique (csrimp_session_id, new_non_comp_default_issue_id) USING INDEX,
    CONSTRAINT FK_MAP_NON_COMP_DEF_ISSUE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_non_compliance_file (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_non_compliance_file_id			NUMBER(10)	NOT NULL,
	new_non_compliance_file_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_non_compliance_file primary key (csrimp_session_id, old_non_compliance_file_id) USING INDEX,
	CONSTRAINT uk_map_non_compliance_file unique (csrimp_session_id, new_non_compliance_file_id) USING INDEX,
    CONSTRAINT FK_NON_COMP_FILE_ALLOC_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);
CREATE TABLE CSRIMP.MAP_DELEG_DATE_SCHEDULE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_deleg_date_schedule_id		NUMBER(10)	NOT NULL,
	new_deleg_date_schedule_id		NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_deleg_date_schedule primary key (csrimp_session_id, old_deleg_date_schedule_id) USING INDEX,
	CONSTRAINT uk_map_deleg_date_schedule unique (csrimp_session_id, new_deleg_date_schedule_id) USING INDEX,
    CONSTRAINT fk_map_deleg_date_schedule_is FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE csrimp.map_tenant (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_tenant_id   NUMBER(10) NOT NULL,
    new_tenant_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_tenant primary key (csrimp_session_id, old_tenant_id) USING INDEX,
    CONSTRAINT uk_map_tenant unique (csrimp_session_id, new_tenant_id) USING INDEX,
    CONSTRAINT fk_map_tenant_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_space_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_space_type_id   NUMBER(10) NOT NULL,
    new_space_type_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_space_type primary key (csrimp_session_id, old_space_type_id) USING INDEX,
    CONSTRAINT uk_map_space_type unique (csrimp_session_id, new_space_type_id) USING INDEX,
    CONSTRAINT fk_map_space_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_property_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_property_type_id    NUMBER(10) NOT NULL,
    new_property_type_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_property_type primary key (csrimp_session_id, old_property_type_id) USING INDEX,
    CONSTRAINT uk_map_property_type unique (csrimp_session_id, new_property_type_id) USING INDEX,
    CONSTRAINT fk_map_property_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_sub_property_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_sub_property_type_id    NUMBER(10) NOT NULL,
    new_sub_property_type_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_sub_property_type primary key (csrimp_session_id, old_sub_property_type_id) USING INDEX,
    CONSTRAINT uk_map_sub_property_type unique (csrimp_session_id, new_sub_property_type_id) USING INDEX,
    CONSTRAINT fk_map_sub_prop_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_property_photo (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_property_photo_id    NUMBER(10) NOT NULL,
    new_property_photo_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_property_photo primary key (csrimp_session_id, old_property_photo_id) USING INDEX,
    CONSTRAINT uk_map_property_photo unique (csrimp_session_id, new_property_photo_id) USING INDEX,
    CONSTRAINT fk_map_property_photo_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_lease (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_lease_id    NUMBER(10) NOT NULL,
    new_lease_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_lease primary key (csrimp_session_id, old_lease_id) USING INDEX,
    CONSTRAINT uk_map_lease unique (csrimp_session_id, new_lease_id) USING INDEX,
    CONSTRAINT fk_map_lease_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_mgmt_company (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_mgmt_company_id				NUMBER(10) NOT NULL,
    new_mgmt_company_id				NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_mgmt_company primary key (csrimp_session_id, old_mgmt_company_id) USING INDEX,
    CONSTRAINT uk_map_mgmt_company unique (csrimp_session_id, new_mgmt_company_id) USING INDEX,
    CONSTRAINT fk_map_mgmt_company_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_fund (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_fund_id NUMBER(10) NOT NULL,
    new_fund_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_fund primary key (csrimp_session_id, old_fund_id) USING INDEX,
    CONSTRAINT uk_map_fund unique (csrimp_session_id, new_fund_id) USING INDEX,
    CONSTRAINT fk_map_fund_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_mgmt_company_contact (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_mgmt_company_contact_id NUMBER(10) NOT NULL,
    new_mgmt_company_contact_id NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_mgmt_company_contact primary key (csrimp_session_id, old_mgmt_company_contact_id) USING INDEX,
    CONSTRAINT uk_map_mgmt_company_contact unique (csrimp_session_id, new_mgmt_company_contact_id) USING INDEX,
    CONSTRAINT fk_map_mgmt_co_cont_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_meter_type_id    NUMBER(10) NOT NULL,
    new_meter_type_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_meter_type primary key (csrimp_session_id, old_meter_type_id) USING INDEX,
    CONSTRAINT uk_map_meter_type unique (csrimp_session_id, new_meter_type_id) USING INDEX,
    CONSTRAINT fk_map_meter_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_meter_input (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_meter_input_id    NUMBER(10) NOT NULL,
    new_meter_input_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_meter_input primary key (csrimp_session_id, old_meter_input_id) USING INDEX,
    CONSTRAINT uk_map_meter_input unique (csrimp_session_id, new_meter_input_id) USING INDEX,
    CONSTRAINT fk_map_meter_input_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_lease_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_lease_type_id   NUMBER(10) NOT NULL,
    new_lease_type_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_lease_type primary key (csrimp_session_id, old_lease_type_id) USING INDEX,
    CONSTRAINT uk_map_lease_type unique (csrimp_session_id, new_lease_type_id) USING INDEX,
    CONSTRAINT fk_map_lease_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_fund_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_fund_type_id    NUMBER(10) NOT NULL,
    new_fund_type_id    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_fund_type primary key (csrimp_session_id, old_fund_type_id) USING INDEX,
    CONSTRAINT uk_map_fund_type unique (csrimp_session_id, new_fund_type_id) USING INDEX,
    CONSTRAINT fk_map_fund_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_region_metric_val (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_region_metric_val_id	    NUMBER(10) NOT NULL,
    new_region_metric_val_id	    NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_region_metric_val primary key (csrimp_session_id, old_region_metric_val_id) USING INDEX,
    CONSTRAINT uk_map_region_metric_val unique (csrimp_session_id, new_region_metric_val_id) USING INDEX,
    CONSTRAINT fk_map_region_metric_val_id_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_plugin_type (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_plugin_type_id  NUMBER(10) NOT NULL,
    new_plugin_type_id  NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_plugin_type_id PRIMARY KEY (csrimp_session_id, old_plugin_type_id) USING INDEX,
    CONSTRAINT uk_map_plugin_type_id UNIQUE (csrimp_session_id, new_plugin_type_id) USING INDEX,
    CONSTRAINT fk_map_plugin_type_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_plugin (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_plugin_id   NUMBER(10) NOT NULL,
    new_plugin_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_plugin primary key (csrimp_session_id, old_plugin_id) USING INDEX,
    CONSTRAINT uk_map_plugin unique (csrimp_session_id, new_plugin_id) USING INDEX,
    CONSTRAINT fk_map_plugin_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE csrimp.map_plugin_ind (
    CSRIMP_SESSION_ID               NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
    old_plugin_ind_id   NUMBER(10) NOT NULL,
    new_plugin_ind_id   NUMBER(10) NOT NULL,
    CONSTRAINT pk_map_plugin_ind primary key (csrimp_session_id, old_plugin_ind_id) USING INDEX,
    CONSTRAINT uk_map_plugin_ind unique (csrimp_session_id, new_plugin_ind_id) USING INDEX,
    CONSTRAINT fk_map_plugin_ind_is FOREIGN KEY
        (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
        ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SUPPLIER_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUPPLIER_SCORE_ID NUMBER(10) NOT NULL,
	NEW_SUPPLIER_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SUPPLIER_SCORE primary key (csrimp_session_id, OLD_SUPPLIER_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_SUPPLIER_SCORE unique (csrimp_session_id, new_SUPPLIER_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_SUPPLIER_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_WORKSHEET (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_WORKSHEET_ID NUMBER(10) NOT NULL,
	NEW_WORKSHEET_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_WORKSHEET PRIMARY KEY (CSRIMP_SESSION_ID, OLD_WORKSHEET_ID) USING INDEX,
	CONSTRAINT UK_MAP_WORKSHEET UNIQUE (CSRIMP_SESSION_ID, NEW_WORKSHEET_ID) USING INDEX,
	CONSTRAINT FK_MAP_WORKSHEET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_VALUE_MAP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_VALUE_MAP_ID NUMBER(10) NOT NULL,
	NEW_VALUE_MAP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_VALUE_MAP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_VALUE_MAP_ID) USING INDEX,
	CONSTRAINT UK_MAP_VALUE_MAP UNIQUE (CSRIMP_SESSION_ID, NEW_VALUE_MAP_ID) USING INDEX,
	CONSTRAINT FK_MAP_VALUE_MAP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_GROUP_CAPABILI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_GROUP_CAPABILITY_ID NUMBER(10) NOT NULL,
	NEW_GROUP_CAPABILITY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_GROUP_CAPABILI primary key (csrimp_session_id, OLD_GROUP_CAPABILITY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_GROUP_CAPABILI unique (csrimp_session_id, new_GROUP_CAPABILITY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_GROUP_CAPABILI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPANY_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPANY_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPANY_TYPE primary key (csrimp_session_id, OLD_COMPANY_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPANY_TYPE unique (csrimp_session_id, new_COMPANY_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPANY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CAPABILITY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CAPABILITY_ID NUMBER(10) NOT NULL,
	NEW_CAPABILITY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CAPABILITY primary key (csrimp_session_id, OLD_CAPABILITY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CAPABILITY unique (csrimp_session_id, new_CAPABILITY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CAPABILITY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ACTIVITY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ACTIVITY PRIMARY KEY (csrimp_session_id, OLD_ACTIVITY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ACTIVITY UNIQUE (csrimp_session_id, NEW_ACTIVITY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ACTIVITY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ACTIVITY_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_TYPE_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ACTIVITY_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ACTIVITY_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ACTIVITY_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_OUTCOME_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_OUTCOME_TYPE_ID NUMBER(10) NOT NULL,
	NEW_OUTCOME_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_OUTCOME_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_OUTCOME_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_OUTCOME_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_OUTCOME_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_OUTCOME_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ACTIVITY_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_LOG_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ACTIVITY_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ACTIVITY_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ACTIVITY_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_ACTIVITY_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ACTIVITY_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ACTIV_LOG_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_LOG_FILE_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_LOG_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ACTIV_LOG_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ACTIVITY_LOG_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ACTIV_LOG_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_ACTIVITY_LOG_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ACTIV_LOG_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ACTI_TYPE_ACTI (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_TYPE_ACTION_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_TYPE_ACTION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ACTI_TYPE_ACTI PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ACTIVITY_TYPE_ACTION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ACTI_TYPE_ACTI UNIQUE (CSRIMP_SESSION_ID, NEW_ACTIVITY_TYPE_ACTION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ACTI_TYPE_ACTI_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_AC_OUT_TYP_AC (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ACTIVITY_OUTCM_TYP_ACTN_ID NUMBER(10) NOT NULL,
	NEW_ACTIVITY_OUTCM_TYP_ACTN_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_AC_OUT_TYP_AC PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ACTIVITY_OUTCM_TYP_ACTN_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_AC_OUT_TYP_AC UNIQUE (CSRIMP_SESSION_ID, NEW_ACTIVITY_OUTCM_TYP_ACTN_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_AC_OUT_TYP_AC_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PROJECT (
	CSRIMP_SESSION_ID	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PROJECT_ID		NUMBER(10)	NOT NULL,
	NEW_PROJECT_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_PROJECT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PROJECT_ID) USING INDEX,
	CONSTRAINT UK_MAP_PROJECT UNIQUE (CSRIMP_SESSION_ID, NEW_PROJECT_ID) USING INDEX,
	CONSTRAINT FK_MAP_PROJECT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CARD(
	CSRIMP_SESSION_ID 	NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CARD_ID			NUMBER(10, 0)	NOT NULL,
	NEW_CARD_ID			NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CARD  PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CARD_ID),
	CONSTRAINT UK_MAP_CHAIN_CARD  UNIQUE (CSRIMP_SESSION_ID, NEW_CARD_ID),
	CONSTRAINT FK_MAP_CHAIN_CARD_SES FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_chain_product_type (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_product_type_id			NUMBER(10) NOT NULL,
	new_product_type_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_chain_product_type PRIMARY KEY (CSRIMP_SESSION_ID, OLD_product_type_id) USING INDEX,
	CONSTRAINT uk_map_chain_product_type UNIQUE (CSRIMP_SESSION_ID, NEW_product_type_id) USING INDEX,
	CONSTRAINT fk_map_chain_product_type_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_delegation_layout (
	csrimp_session_id 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_delegation_layout_id	NUMBER(10) NOT NULL,
	new_delegation_layout_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_delegation_layout PRIMARY KEY (CSRIMP_SESSION_ID, OLD_delegation_layout_id) USING INDEX,
	CONSTRAINT uk_map_delegation_layout UNIQUE (CSRIMP_SESSION_ID, NEW_delegation_layout_id) USING INDEX,
	CONSTRAINT fk_map_delegation_layout_is 
		FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ALERT_ENTRY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ALERT_ENTRY_ID NUMBER(10) NOT NULL,
	NEW_ALERT_ENTRY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ALERT_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ALERT_ENTRY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ALERT_ENTRY UNIQUE (CSRIMP_SESSION_ID, NEW_ALERT_ENTRY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ALERT_ENTRY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_MESSAGE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_MESSAGE_ID NUMBER(10) NOT NULL,
	NEW_MESSAGE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_MESSAGE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_MESSAGE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_MESSAGE UNIQUE (CSRIMP_SESSION_ID, NEW_MESSAGE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_MESSAGE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_SCHEDULE_ALERT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SCHEDULED_ALERT_ID NUMBER(10) NOT NULL,
	NEW_SCHEDULED_ALERT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_SCHEDULE_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SCHEDULED_ALERT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_SCHEDULE_ALERT UNIQUE (CSRIMP_SESSION_ID, NEW_SCHEDULED_ALERT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_SCHEDULE_ALERT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_AUDIT_REQUEST (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_AUDIT_REQUEST_ID NUMBER(10) NOT NULL,
	NEW_AUDIT_REQUEST_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_AUDIT_REQUEST PRIMARY KEY (CSRIMP_SESSION_ID, OLD_AUDIT_REQUEST_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_AUDIT_REQUEST UNIQUE (CSRIMP_SESSION_ID, NEW_AUDIT_REQUEST_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_AUDIT_REQUEST_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPANY_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPANY_HEADER_ID NUMBER(10) NOT NULL,
	NEW_COMPANY_HEADER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPANY_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPANY_HEADER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPANY_HEADER UNIQUE (CSRIMP_SESSION_ID, NEW_COMPANY_HEADER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPANY_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPANY_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPANY_TAB_ID NUMBER(10) NOT NULL,
	NEW_COMPANY_TAB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPANY_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPANY_TAB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPANY_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_COMPANY_TAB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPANY_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_HEADER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_HEADER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_HEADER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_HEADER UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_HEADER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_HEADER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_TAB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_TAB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT_SUPPLIER_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_SUPPLIER_TAB_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_SUPPLIER_TAB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PROD_SUPP_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_SUPPLIER_TAB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PROD_SUPP_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_SUPPLIER_TAB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PROD_SUPP_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPONENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPONENT_ID NUMBER(10) NOT NULL,
	NEW_COMPONENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPONENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPONENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPONENT UNIQUE (CSRIMP_SESSION_ID, NEW_COMPONENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPONENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPOUN_FILTER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPOUND_FILTER_ID NUMBER(10) NOT NULL,
	NEW_COMPOUND_FILTER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPOUN_FILTER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPOUND_FILTER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPOUN_FILTER UNIQUE (CSRIMP_SESSION_ID, NEW_COMPOUND_FILTER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMPOUN_FILTER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUSTOM_AGG_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	NEW_CUSTOMER_AGGREGATE_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUSTOM_AGG_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUSTOM_AGG_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_CUSTOMER_AGGREGATE_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUSTOM_AGG_TYP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILE_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILE_GROUP_ID NUMBER(10) NOT NULL,
	NEW_FILE_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILE_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILE_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILE_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_FILE_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILE_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILE_GROU_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILE_GROUP_FILE_ID NUMBER(10) NOT NULL,
	NEW_FILE_GROUP_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILE_GROU_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILE_GROUP_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILE_GROU_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_FILE_GROUP_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILE_GROU_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_ID NUMBER(10) NOT NULL,
	NEW_FILTER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILTER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_TYPE_ID NUMBER(10) NOT NULL,
	NEW_FILTER_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILTER_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_FIELD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_FIELD_ID NUMBER(10) NOT NULL,
	NEW_FILTER_FIELD_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_FIELD PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_FIELD_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_FIELD UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_FIELD_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILTER_FIELD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_VALUE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_VALUE_ID NUMBER(10) NOT NULL,
	NEW_FILTER_VALUE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_VALUE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_VALUE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_VALUE UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_VALUE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FILTER_VALUE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_PAGE_CMS_TAB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_CMS_TABLE_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_CMS_TABLE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FLTR_PAGE_CMS_TAB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_CMS_TABLE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FLTR_PAGE_CMS_TAB UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_CMS_TABLE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHN_FLTR_PG_CMS_TAB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FILTER_PAGE_IND (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FILTER_PAGE_IND PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FILTER_PAGE_IND UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PAGE_IND_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_FLTR_PAGE_IND_INTRVL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	NEW_FILTER_PAGE_IND_INTRVL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_FLTR_PG_IND_INTVL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_FLTR_PG_IND_INTVL UNIQUE (CSRIMP_SESSION_ID, NEW_FILTER_PAGE_IND_INTRVL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_FLTR_PG_IND_I_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_QUESTIONN_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_QUESTIONNAIRE_TYPE_ID NUMBER(10) NOT NULL,
	NEW_QUESTIONNAIRE_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_QUESTIONN_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_QUESTIONNAIRE_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_QUESTIONN_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_QUESTIONNAIRE_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_QUESTIONN_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_INVITATION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INVITATION_ID NUMBER(10) NOT NULL,
	NEW_INVITATION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_INVITATION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INVITATION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_INVITATION UNIQUE (CSRIMP_SESSION_ID, NEW_INVITATION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_INVITATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_MESSAG_DEFINIT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_MESSAGE_DEFINITION_ID NUMBER(10) NOT NULL,
	NEW_MESSAGE_DEFINITION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_MESSAG_DEFINIT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_MESSAGE_DEFINITION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_MESSAG_DEFINIT UNIQUE (CSRIMP_SESSION_ID, NEW_MESSAGE_DEFINITION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_MESSAG_DEFINIT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_QUESTIONNAIRE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
	NEW_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_QUESTIONNAIRE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_QUESTIONNAIRE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_QUESTIONNAIRE UNIQUE (CSRIMP_SESSION_ID, NEW_QUESTIONNAIRE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_QUESTIONNAIRE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_RECIPIENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_RECIPIENT_ID NUMBER(10) NOT NULL,
	NEW_RECIPIENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_RECIPIENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_RECIPIENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_RECIPIENT UNIQUE (CSRIMP_SESSION_ID, NEW_RECIPIENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_RECIPIENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_NEWSFLASH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_NEWSFLASH_ID NUMBER(10) NOT NULL,
	NEW_NEWSFLASH_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_NEWSFLASH PRIMARY KEY (CSRIMP_SESSION_ID, OLD_NEWSFLASH_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_NEWSFLASH UNIQUE (CSRIMP_SESSION_ID, NEW_NEWSFLASH_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_NEWSFLASH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PRODUCT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PRODUCT_ID NUMBER(10) NOT NULL,
	NEW_PRODUCT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PRODUCT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PRODUCT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PRODUCT UNIQUE (CSRIMP_SESSION_ID, NEW_PRODUCT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PRODUCT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_PURCHASE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PURCHASE_ID NUMBER(10) NOT NULL,
	NEW_PURCHASE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_PURCHASE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PURCHASE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_PURCHASE UNIQUE (CSRIMP_SESSION_ID, NEW_PURCHASE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_PURCHASE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_QUESTION_SHARE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_QUESTIONNAIRE_SHARE_ID NUMBER(10) NOT NULL,
	NEW_QUESTIONNAIRE_SHARE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_QUESTION_SHARE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_QUESTIONNAIRE_SHARE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_QUESTION_SHARE UNIQUE (CSRIMP_SESSION_ID, NEW_QUESTIONNAIRE_SHARE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_QUESTION_SHARE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_TASK (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_TASK_ID NUMBER(10) NOT NULL,
	NEW_TASK_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_TASK PRIMARY KEY (CSRIMP_SESSION_ID, OLD_TASK_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_TASK UNIQUE (CSRIMP_SESSION_ID, NEW_TASK_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_TASK_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_TASK_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_TASK_TYPE_ID NUMBER(10) NOT NULL,
	NEW_TASK_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_TASK_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_TASK_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_TASK_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_TASK_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_TASK_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_TASK_ENTRY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_TASK_ENTRY_ID NUMBER(10) NOT NULL,
	NEW_TASK_ENTRY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_TASK_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_TASK_ENTRY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_TASK_ENTRY UNIQUE (CSRIMP_SESSION_ID, NEW_TASK_ENTRY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_TASK_ENTRY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_REL_TYPE_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_REL_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSIN_REL_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BUSINESS_REL_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSIN_REL_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_BUSINESS_REL_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSIN_REL_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUSIN_REL_TIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_REL_TIER_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_REL_TIER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSIN_REL_TIER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BUSINESS_REL_TIER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSIN_REL_TIER UNIQUE (CSRIMP_SESSION_ID, NEW_BUSINESS_REL_TIER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSIN_REL_TIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUSINE_RELATIO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_RELATIONSHIP_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_RELATIONSHIP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUSINE_RELATIO PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BUSINESS_RELATIONSHIP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUSINE_RELATIO UNIQUE (CSRIMP_SESSION_ID, NEW_BUSINESS_RELATIONSHIP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUSINE_RELATIO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_BUS_REL_PERIOD (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BUSINESS_REL_PERIOD_ID NUMBER(10) NOT NULL,
	NEW_BUSINESS_REL_PERIOD_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_BUS_REL_PERIOD PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BUSINESS_REL_PERIOD_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_BUS_REL_PERIOD UNIQUE (CSRIMP_SESSION_ID, NEW_BUSINESS_REL_PERIOD_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_BUS_REL_PERIOD_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_REFERENCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_REFERENCE_ID NUMBER(10) NOT NULL,
	NEW_REFERENCE_ID  NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_REFERENCE primary key (csrimp_session_id, OLD_REFERENCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_REFERENCE unique (csrimp_session_id, NEW_REFERENCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_REFERENCE FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

--chem
CREATE TABLE CSRIMP.MAP_CHEM_CAS_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CAS_GROUP_ID NUMBER(10) NOT NULL,
	NEW_CAS_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_CAS_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CAS_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_CAS_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_CAS_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_CAS_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_CLASSIFICATION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CLASSIFICATION_ID NUMBER(10) NOT NULL,
	NEW_CLASSIFICATION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_CLASSIFICATION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CLASSIFICATION_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_CLASSIFICATION UNIQUE (CSRIMP_SESSION_ID, NEW_CLASSIFICATION_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_CLASSIFICATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_MANUFACTURER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_MANUFACTURER_ID NUMBER(10) NOT NULL,
	NEW_MANUFACTURER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_MANUFACTURER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_MANUFACTURER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_MANUFACTURER UNIQUE (CSRIMP_SESSION_ID, NEW_MANUFACTURER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_MANUFACTURER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUBSTANCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBSTANCE_ID NUMBER(10) NOT NULL,
	NEW_SUBSTANCE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUBSTANCE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBSTANCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUBSTANCE UNIQUE (CSRIMP_SESSION_ID, NEW_SUBSTANCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUBSTANCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUB_RGN_PRO_PRO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBST_RGN_PROC_PROCESS_ID NUMBER(10) NOT NULL,
	NEW_SUBST_RGN_PROC_PROCESS_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUB_RGN_PRO_PRO PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBST_RGN_PROC_PROCESS_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUB_RGN_PRO_PRO UNIQUE (CSRIMP_SESSION_ID, NEW_SUBST_RGN_PROC_PROCESS_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUB_RGN_PRO_PRO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_USAGE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_USAGE_ID NUMBER(10) NOT NULL,
	NEW_USAGE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_USAGE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_USAGE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_USAGE UNIQUE (CSRIMP_SESSION_ID, NEW_USAGE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_USAGE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_CHA (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBST_PROC_USE_CHANGE_ID NUMBER(10) NOT NULL,
	NEW_SUBST_PROC_USE_CHANGE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUB_PRO_USE_CHA PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBST_PROC_USE_CHANGE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUB_PRO_USE_CHA UNIQUE (CSRIMP_SESSION_ID, NEW_SUBST_PROC_USE_CHANGE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUB_PRO_USE_CHA_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SU_PR_CA_DE_CHG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBST_PROC_CAS_DEST_CHG_ID NUMBER(10) NOT NULL,
	NEW_SUBST_PROC_CAS_DEST_CHG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SU_PR_CA_DE_CHG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBST_PROC_CAS_DEST_CHG_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SU_PR_CA_DE_CHG UNIQUE (CSRIMP_SESSION_ID, NEW_SUBST_PROC_CAS_DEST_CHG_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SU_PR_CA_DE_CHG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUB_AUDIT_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUB_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	NEW_SUB_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUB_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUB_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUB_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_SUB_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUB_AUDIT_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUBSTANCE_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBSTANCE_FILE_ID NUMBER(10) NOT NULL,
	NEW_SUBSTANCE_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUBSTANCE_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBSTANCE_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUBSTANCE_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_SUBSTANCE_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUBSTANCE_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUBST_PROCE_USE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
	NEW_SUBSTANCE_PROCESS_USE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUBST_PROCE_USE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBSTANCE_PROCESS_USE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUBST_PROCE_USE UNIQUE (CSRIMP_SESSION_ID, NEW_SUBSTANCE_PROCESS_USE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUBST_PROCE_USE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_SUB_PRO_USE_FIL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUBST_PROC_USE_FILE_ID NUMBER(10) NOT NULL,
	NEW_SUBST_PROC_USE_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_SUB_PRO_USE_FIL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUBST_PROC_USE_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_SUB_PRO_USE_FIL UNIQUE (CSRIMP_SESSION_ID, NEW_SUBST_PROC_USE_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_SUB_PRO_USE_FIL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHEM_USAGE_AUDIT_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_USAGE_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	NEW_USAGE_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHEM_USAGE_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_USAGE_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHEM_USAGE_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_USAGE_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHEM_USAGE_AUDIT_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

--FB63025
CREATE TABLE CSRIMP.MAP_CT_BREAKDOWN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BREAKDOWN_ID NUMBER(10) NOT NULL,
	NEW_BREAKDOWN_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_BREAKDOWN PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BREAKDOWN_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_BREAKDOWN UNIQUE (CSRIMP_SESSION_ID, NEW_BREAKDOWN_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_BREAKDOWN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIAN_PERMIT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_PERMIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_PERMIT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_PERMIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPL_PERMI_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_TYPE_ID NUMBER(10) NOT NULL,
	OLD_COMPLIA_PERMIT_SUB_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIA_PERMIT_SUB_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPL_PERMI_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_TYPE_ID, OLD_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPL_PERMI_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_TYPE_ID, NEW_COMPLIA_PERMIT_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPL_PERMI_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIANCE_PERMIT_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIANCE_PERMIT_SCORE PRIMARY KEY (OLD_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIANCE_PERMIT_SCORE UNIQUE (NEW_COMPLIANCE_PERMIT_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLI_PERMIT_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIA_CONDITI_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIA_CONDITI_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIA_CONDITI_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIA_CONDITI_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIA_CONDITION_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPLIAN_CONDITION_TYPE_ID NUMBER(10) NOT NULL,
	OLD_COMP_CONDITION_SUB_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMP_CONDITION_SUB_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMP_CONDITION_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIAN_CONDITION_TYPE_ID, OLD_COMP_CONDITION_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMP_CONDITION_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIAN_CONDITION_TYPE_ID, NEW_COMP_CONDITION_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMP_CONDIT_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE CSRIMP.MAP_COMPLIA_ACTIVIT_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANC_ACTIVITY_TYPE_ID 	NUMBER(10) NOT NULL,
	NEW_COMPLIANC_ACTIVITY_TYPE_ID 	NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIA_ACTIVIT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIA_ACTIVIT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_ACTIVITY_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIA_ACTIVIT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPL_ACTIVITY_SUB_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANC_ACTIVITY_TYPE_ID 	NUMBER(10) NOT NULL,
	NEW_COMPLIANC_ACTIVITY_TYPE_ID 	NUMBER(10) NOT NULL,
	OLD_COMPL_ACTIVITY_SUB_TYPE_ID NUMBER(10) NOT NULL,
	NEW_COMPL_ACTIVITY_SUB_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPL_ACTIVIT_SUB_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_ACTIVITY_TYPE_ID, OLD_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPL_ACTIVIT_SUB_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_ACTIVITY_TYPE_ID, NEW_COMPL_ACTIVITY_SUB_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPL_ACT_SUB_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIAN_APPLICAT_TP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANC_APPLICATIO_TP_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANC_APPLICATIO_TP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_APPLICAT_TP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANC_APPLICATIO_TP_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_APPLICAT_TP UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANC_APPLICATIO_TP_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_APPLICAT_TP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIANCE_PERMIT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIANCE_PERMIT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIANCE_PERMIT UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIANCE_PERMIT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COMPLIAN_PERMIT_APPL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPLIANCE_PERMIT_APPL_ID NUMBER(10) NOT NULL,
	NEW_COMPLIANCE_PERMIT_APPL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COMPLIAN_PERMIT_APPL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPLIANCE_PERMIT_APPL_ID) USING INDEX,
	CONSTRAINT UK_MAP_COMPLIAN_PERMIT_APPL UNIQUE (CSRIMP_SESSION_ID, NEW_COMPLIANCE_PERMIT_APPL_ID) USING INDEX,
	CONSTRAINT FK_MAP_COMPLIAN_PERMIT_APPL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_BREAKDOWN_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
	NEW_BREAKDOWN_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_BREAKDOWN_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BREAKDOWN_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_BREAKDOWN_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_BREAKDOWN_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_BREAKDOWN_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_BREAKDOWN_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
	NEW_BREAKDOWN_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_BREAKDOWN_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BREAKDOWN_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_BREAKDOWN_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_BREAKDOWN_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_BREAKDOWN_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_BT_TRIP_ENTRY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_BT_TRIP_ENTRY_ID NUMBER(10) NOT NULL,
	NEW_BT_TRIP_ENTRY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_BT_TRIP_ENTRY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_BT_TRIP_ENTRY_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_BT_TRIP_ENTRY UNIQUE (CSRIMP_SESSION_ID, NEW_BT_TRIP_ENTRY_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_BT_TRIP_ENTRY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_EC_QUESTIONNAIRE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_EC_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
	NEW_EC_QUESTIONNAIRE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_EC_QUESTIONNAIRE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_EC_QUESTIONNAIRE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_EC_QUESTIONNAIRE UNIQUE (CSRIMP_SESSION_ID, NEW_EC_QUESTIONNAIRE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_EC_QUESTIONNAIRE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_EC_QUESTIONNA_ANS (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_EC_QUESTIONNAIRE_ANS_ID NUMBER(10) NOT NULL,
	NEW_EC_QUESTIONNAIRE_ANS_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_EC_QUESTIONNA_ANS PRIMARY KEY (CSRIMP_SESSION_ID, OLD_EC_QUESTIONNAIRE_ANS_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_EC_QUESTIONNA_ANS UNIQUE (CSRIMP_SESSION_ID, NEW_EC_QUESTIONNAIRE_ANS_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_EC_QUESTIONNA_ANS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_PS_ITEM (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_PS_ITEM_ID NUMBER(10) NOT NULL,
	NEW_PS_ITEM_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_PS_ITEM PRIMARY KEY (CSRIMP_SESSION_ID, OLD_PS_ITEM_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_PS_ITEM UNIQUE (CSRIMP_SESSION_ID, NEW_PS_ITEM_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_PS_ITEM_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_SUPPLIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUPPLIER_ID NUMBER(10) NOT NULL,
	NEW_SUPPLIER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_SUPPLIER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUPPLIER_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_SUPPLIER UNIQUE (CSRIMP_SESSION_ID, NEW_SUPPLIER_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_SUPPLIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CT_SUPPLIER_CONTACT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SUPPLIER_CONTACT_ID NUMBER(10) NOT NULL,
	NEW_SUPPLIER_CONTACT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CT_SUPPLIER_CONTACT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SUPPLIER_CONTACT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CT_SUPPLIER_CONTACT UNIQUE (CSRIMP_SESSION_ID, NEW_SUPPLIER_CONTACT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CT_SUPPLIER_CONTACT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ASPEN2_TRANSLATED (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_TRANSLATED_ID				NUMBER(10) NOT NULL,
	NEW_TRANSLATED_ID				NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ASPEN2_TRANSLATED PRIMARY KEY (CSRIMP_SESSION_ID, OLD_TRANSLATED_ID),
	CONSTRAINT UK_MAP_ASPEN2_TRANSLATED UNIQUE (CSRIMP_SESSION_ID, NEW_TRANSLATED_ID),
    CONSTRAINT FK_MAP_ASPEN2_TRANSLATED_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_MAIL_MESSAGE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_MESSAGE_ID					NUMBER(10)	NOT NULL,
	NEW_MESSAGE_ID					NUMBER(10)	NOT NULL,
	IS_NEW							NUMBER(1) NOT NULL,
	CONSTRAINT PK_MAP_MAIL_MESSAGE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_MESSAGE_ID) USING INDEX,
	CONSTRAINT UK_MAP_MAIL_MESSAGE UNIQUE (CSRIMP_SESSION_ID, NEW_MESSAGE_ID) USING INDEX,
    CONSTRAINT FK_MAP_MAIL_MESSAGE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_FLOW_INVOLVEMENT_TYPE (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	NEW_FLOW_INVOLVEMENT_TYPE_ID	NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_FLOW_INV_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_FLOW_INV_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_FLOW_INVOLVEMENT_TYPE_ID) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_INV_TYPE_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_AUD_TP_FLOW_INV_TP (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	NEW_AUD_TP_FLOW_INV_TP_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_AUD_TP_FLOW_INV_TP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
	CONSTRAINT UK_MAP_AUD_TP_FLOW_INV_TP UNIQUE (CSRIMP_SESSION_ID, NEW_AUD_TP_FLOW_INV_TP_ID) USING INDEX,
    CONSTRAINT FK_MAP_AUD_TP_FLOW_INV_TP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CUSTOMER_FLOW_CAP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CUSTOMER_FLOW_CAP_ID NUMBER(10) NOT NULL,
	NEW_CUSTOMER_FLOW_CAP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CUSTOMER_FLOW_CAP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CUSTOMER_FLOW_CAP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CUSTOMER_FLOW_CAP UNIQUE (CSRIMP_SESSION_ID, NEW_CUSTOMER_FLOW_CAP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CUSTOMER_FLOW_CAP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IA_TYPE_SURVEY_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IA_TYPE_SURVEY_GROUP_ID NUMBER(10) NOT NULL,
	NEW_IA_TYPE_SURVEY_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IA_TYPE_SURVEY_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IA_TYPE_SURVEY_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_IA_TYPE_SURVEY_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_IA_TYPE_SURVEY_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_SURVEY_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IA_TYPE_SURVEY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IA_TYPE_SURVEY_ID NUMBER(10) NOT NULL,
	NEW_IA_TYPE_SURVEY_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IA_TYPE_SURVEY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IA_TYPE_SURVEY_ID) USING INDEX,
	CONSTRAINT UK_MAP_IA_TYPE_SURVEY UNIQUE (CSRIMP_SESSION_ID, NEW_IA_TYPE_SURVEY_ID) USING INDEX,
	CONSTRAINT FK_MAP_IA_TYPE_SURVEY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_SUPPLIER (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_SUPPLIER_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_SUPPLIER_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_SUPPLIER PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_SUPPLIER_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_SUPPLIER UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_SUPPLIER_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_SUPPLIER_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_ACTION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_ACTION_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_ACTION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_ACTION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_ACTION_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_ACTION UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_ACTION_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_ACTION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_COMPLIANCE_REGION (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_COMPLIANCE_REGION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_COMPLIANCE_REGION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_COMPLIANCE_REGION UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_COMPLIANCE_REGION_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_COMPLIANCE_REG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- BEGIN FB76357

CREATE TABLE CSRIMP.MAP_R_REPORT_TYPE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_R_REPORT_TYPE_ID NUMBER(10) NOT NULL,
	NEW_R_REPORT_TYPE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_R_REPORT_TYPE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_R_REPORT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_R_REPORT_TYPE UNIQUE (CSRIMP_SESSION_ID, NEW_R_REPORT_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_R_REPORT_TYPE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_R_REPORT_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_R_REPORT_FILE_ID NUMBER(10) NOT NULL,
	NEW_R_REPORT_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_R_REPORT_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_R_REPORT_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_R_REPORT_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_R_REPORT_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_R_REPORT_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

-- END FB76357

CREATE TABLE csrimp.map_benchmark_dashboard_char (
	csrimp_session_id				NUMBER(10)		DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	new_benchmark_das_char_id		NUMBER(10)		NOT NULL,
	CONSTRAINT PK_MAP_BENCHMARK_DAS_CHAR PRIMARY KEY (csrimp_session_id, old_benchmark_das_char_id) USING INDEX,
	CONSTRAINT UK_MAP_BENCHMARK_DAS_CHAR UNIQUE (csrimp_session_id, new_benchmark_das_char_id) USING INDEX,
	CONSTRAINT FK_MAP_BENCHMARK_DAS_CHAR_IS
		FOREIGN KEY (csrimp_session_id)
		REFERENCES csrimp.csrimp_session (csrimp_session_id)
		ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_GRESB_SUBMISSION_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	NEW_GRESB_SUBMISSION_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_GRESB_SUBMISSION_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_GRESB_SUBMISSION_ID) USING INDEX,
	CONSTRAINT FK_MAP_GRESB_SUBMISSION_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE csrimp.map_region_score_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_region_score_log_id			NUMBER(10)	NOT NULL,
	new_region_score_log_id			NUMBER(10)	NOT NULL,
	CONSTRAINT pk_map_region_score PRIMARY KEY (csrimp_session_id, old_region_score_log_id) USING INDEX,
	CONSTRAINT uk_map_region_score UNIQUE (csrimp_session_id, new_region_score_log_id) USING INDEX,
    CONSTRAINT fk_map_region_score_is FOREIGN KEY
    	(csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_RISK_LEVEL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_RISK_LEVEL_ID NUMBER(10) NOT NULL,
	NEW_RISK_LEVEL_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_RISK_LEVEL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_RISK_LEVEL_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_RISK_LEVEL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_IMPORT_SOURCE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	NEW_IMPORT_SOURCE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_IMPORT_SOURCE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_IMPORT_SOURCE UNIQUE (CSRIMP_SESSION_ID, NEW_IMPORT_SOURCE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_IMPORT_SOURCE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_STAG_LINK (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUP_STAGIN_LINK_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUP_STAGIN_LINK_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_STAG_LINK PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUP_STAGIN_LINK_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_STAG_LINK UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUP_STAGIN_LINK_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_STAG_LINK_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MAPPING (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MAPPING_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MAPPING PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MAPPING UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MAPPING_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MAPPING_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE_SET (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_SET_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_SET_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DD_RULE_SET PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_SET_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DD_RULE_SET UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_SET_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DD_RULE_SET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PREP_RULE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUP_PREPRO_RULE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PREP_RULE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PREP_RULE UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUP_PREPRO_RULE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PREP_RULE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_SUB (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_DEDUPE_SUB_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_SUB PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_SUB UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_DEDUPE_SUB_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_SUB_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_HIGG_CONFIG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_HIGG_CONFIG_ID NUMBER(10) NOT NULL,
	NEW_HIGG_CONFIG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_HIGG_CONFIG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_HIGG_CONFIG_ID) USING INDEX,
	CONSTRAINT UK_MAP_HIGG_CONFIG UNIQUE (CSRIMP_SESSION_ID, NEW_HIGG_CONFIG_ID) USING INDEX,
	CONSTRAINT FK_MAP_HIGG_CONFIG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDU_PROC_RECO (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_PROCESSED_RECORD_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDU_PROC_RECO PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDU_PROC_RECO UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_PROCESSED_RECORD_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDU_PROC_RECO_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_DEDUPE_MATCH (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	NEW_DEDUPE_MATCH_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_DEDUPE_MATCH PRIMARY KEY (CSRIMP_SESSION_ID, OLD_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_DEDUPE_MATCH UNIQUE (CSRIMP_SESSION_ID, NEW_DEDUPE_MATCH_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_DEDUPE_MATCH_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_FLOW_STATE_GROUP (
	CSRIMP_SESSION_ID					NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_FLOW_STATE_GROUP_ID	NUMBER(10)	NOT NULL,
	NEW_FLOW_STATE_GROUP_ID	NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_FLOW_STATE_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_FLOW_STATE_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_FLOW_STATE_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_FLOW_STATE_GROUP_ID) USING INDEX,
    CONSTRAINT FK_MAP_FLOW_STATE_GROUP_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIVE_METRIC (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIVE_METRIC_ID NUMBER(10) NOT NULL,
	NEW_INITIATIVE_METRIC_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIATIVE_METRIC PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIVE_METRIC_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIATIVE_METRIC UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIVE_METRIC_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIATIVE_METRIC_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_AGGR_TAG_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_AGGR_TAG_GROUP_ID NUMBER(10) NOT NULL,
	NEW_AGGR_TAG_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_AGGR_TAG_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_AGGR_TAG_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_AGGR_TAG_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_AGGR_TAG_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_AGGR_TAG_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIVE_COMMENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIVE_COMMENT_ID NUMBER(10) NOT NULL,
	NEW_INITIATIVE_COMMENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIATIVE_COMMENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIVE_COMMENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIATIVE_COMMENT UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIVE_COMMENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIATIVE_COMMENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIVE_EVENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIVE_EVENT_ID NUMBER(10) NOT NULL,
	NEW_INITIATIVE_EVENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIATIVE_EVENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIVE_EVENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIATIVE_EVENT UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIVE_EVENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIATIVE_EVENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIVE_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIVE_GROUP_ID NUMBER(10) NOT NULL,
	NEW_INITIATIVE_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIATIVE_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIVE_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIATIVE_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIVE_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIATIVE_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIV_USER_GROUP (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIVE_USER_GROUP_ID NUMBER(10) NOT NULL,
	NEW_INITIATIVE_USER_GROUP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIATIV_USER_GROUP PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIVE_USER_GROUP_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIATIV_USER_GROUP UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIVE_USER_GROUP_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIATIV_USER_GROUP_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IMPORT_TEMPLATE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMPORT_TEMPLATE_ID NUMBER(10) NOT NULL,
	NEW_IMPORT_TEMPLATE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IMPORT_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMPORT_TEMPLATE_ID) USING INDEX,
	CONSTRAINT UK_MAP_IMPORT_TEMPLATE UNIQUE (CSRIMP_SESSION_ID, NEW_IMPORT_TEMPLATE_ID) USING INDEX,
	CONSTRAINT FK_MAP_IMPORT_TEMPLATE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIA_PERIOD_STATUS (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INITIATIV_PERIOD_STATUS_ID NUMBER(10) NOT NULL,
	NEW_INITIATIV_PERIOD_STATUS_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_INITIA_PERIOD_STATUS PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INITIATIV_PERIOD_STATUS_ID) USING INDEX,
	CONSTRAINT UK_MAP_INITIA_PERIOD_STATUS UNIQUE (CSRIMP_SESSION_ID, NEW_INITIATIV_PERIOD_STATUS_ID) USING INDEX,
	CONSTRAINT FK_MAP_INITIA_PERIOD_STATUS_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_USER_MSG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_USER_MSG_ID NUMBER(10) NOT NULL,
	NEW_USER_MSG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_USER_MSG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_USER_MSG_ID) USING INDEX,
	CONSTRAINT UK_MAP_USER_MSG UNIQUE (CSRIMP_SESSION_ID, NEW_USER_MSG_ID) USING INDEX,
	CONSTRAINT FK_MAP_USER_MSG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_INITIATIVE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_INITIATIVE_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_INITIATIVE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_INITIATIVE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_INITIATIVE_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_INITIATIVE UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_INITIATIVE_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_INITIATIVE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSUE_SCHEDULED_TASK (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_SCHEDULED_TASK_ID 	NUMBER(10) NOT NULL,
	NEW_ISSUE_SCHEDULED_TASK_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_SCHEDULED_TASK PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_SCHEDULED_TASK_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_SCHEDULED_TASK UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_SCHEDULED_TASK_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_SCHEDULED_TASK_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INITIATIVE_HEADER_ELEMENT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_INIT_HEADER_ELEMENT_ID		NUMBER(10)	NOT NULL,
	NEW_INIT_HEADER_ELEMENT_ID		NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_INIT_HEADER_ELEMENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_INIT_HEADER_ELEMENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_INIT_HEADER_ELEMENT UNIQUE (CSRIMP_SESSION_ID, NEW_INIT_HEADER_ELEMENT_ID) USING INDEX,
    CONSTRAINT FK_MAP_INIT_HEADER_ELEMENT_IS FOREIGN KEY
    	(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID)
    	ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INIT_TAB_ELEMENT_LAYOUT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ELEMENT_ID					NUMBER(10)	NOT NULL,
	NEW_ELEMENT_ID					NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_INIT_TAB_ELEMENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ELEMENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_INIT_TAB_ELEMENT UNIQUE (CSRIMP_SESSION_ID, NEW_ELEMENT_ID) USING INDEX,
    CONSTRAINT FK_MAP_INIT_TAB_ELEMENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_INIT_CREATE_PAGE_EL_LAYOUT (
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ELEMENT_ID					NUMBER(10)	NOT NULL,
	NEW_ELEMENT_ID					NUMBER(10)	NOT NULL,
	CONSTRAINT PK_MAP_INIT_CR_PAG_ELEMENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ELEMENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_INIT_CR_PAG_ELEMENT UNIQUE (CSRIMP_SESSION_ID, NEW_ELEMENT_ID) USING INDEX,
    CONSTRAINT FK_MAP_INIT_CR_PAG_ELEMENT_IS FOREIGN KEY(CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_id			NUMBER(10) NOT NULL,
	new_compliance_item_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item PRIMARY KEY (csrimp_session_id, old_compliance_item_id),
	CONSTRAINT uk_map_compliance_item UNIQUE (csrimp_session_id, new_compliance_item_id),
    CONSTRAINT fk_map_compliance_item FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_comp_item_version_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_version_log_id			NUMBER(10) NOT NULL,
	new_comp_item_version_log_id			NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_comp_item_version_log PRIMARY KEY (csrimp_session_id, old_comp_item_version_log_id),
	CONSTRAINT uk_map_comp_item_version_log UNIQUE (csrimp_session_id, new_comp_item_version_log_id),
    CONSTRAINT fk_map_comp_item_version_log FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item_desc_hist (
	csrimp_session_id					NUMBER(10)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_item_desc_hist_id			NUMBER(10)	 NOT NULL,
	new_comp_item_desc_hist_id			NUMBER(10)	 NOT NULL,
	CONSTRAINT pk_map_comp_item_desc_hist PRIMARY KEY (csrimp_session_id, old_comp_item_desc_hist_id),
	CONSTRAINT uk_map_comp_item_desc_hist UNIQUE (csrimp_session_id, new_comp_item_desc_hist_id),
	CONSTRAINT fk_map_comp_item_desc_hist FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_audit_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_audit_log_id		NUMBER(10, 0)	NOT NULL,
	new_compliance_audit_log_id		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT pk_compliance_audit_log_id PRIMARY KEY (csrimp_session_id, old_compliance_audit_log_id),
	CONSTRAINT uk_compliance_audit_log_id UNIQUE (csrimp_session_id, new_compliance_audit_log_id),
    CONSTRAINT fk_compliance_audit_log_id FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_compliance_item_rollout (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_compliance_item_rollout_id	NUMBER(10) NOT NULL,
	new_compliance_item_rollout_id	NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_compliance_item_rollout PRIMARY KEY (csrimp_session_id, old_compliance_item_rollout_id),
	CONSTRAINT uk_map_compliance_item_rollout UNIQUE (csrimp_session_id, new_compliance_item_rollout_id),
    CONSTRAINT fk_map_compliance_item_rollout FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_enhesa_error_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_error_log_id				NUMBER(10) NOT NULL,
	new_error_log_id				NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_enhesa_error_log PRIMARY KEY (csrimp_session_id, old_error_log_id),
	CONSTRAINT uk_map_enhesa_error_log UNIQUE (csrimp_session_id, new_error_log_id),
    CONSTRAINT fk_map_enhesa_error_log FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE csrimp.map_flow_item_audit_log (
	csrimp_session_id				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_flow_item_audit_log_id 		NUMBER(10) NOT NULL,
	new_flow_item_audit_log_id		NUMBER(10) NOT NULL,
	CONSTRAINT pk_map_flow_item_audit_log PRIMARY KEY (csrimp_session_id, old_flow_item_audit_log_id) USING INDEX,
	CONSTRAINT uk_map_flow_item_audit_log UNIQUE (csrimp_session_id, new_flow_item_audit_log_id) USING INDEX,
	CONSTRAINT fk_map_flow_item_audit_log_is FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IMAGE_UPLOAD_PORTLET (
	CSRIMP_SESSION_ID 			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IMAGE_UPLOAD_PORTLET_ID NUMBER(10) NOT NULL,
	NEW_IMAGE_UPLOAD_PORTLET_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IMAGE_UPLOAD_PORTLET PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IMAGE_UPLOAD_PORTLET_ID) USING INDEX,
	CONSTRAINT UK_MAP_IMAGE_UPLOAD_PORTLET UNIQUE (CSRIMP_SESSION_ID, NEW_IMAGE_UPLOAD_PORTLET_ID) USING INDEX,
	CONSTRAINT FK_MAP_IMAGE_UPLOAD_PORTLET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_IND_SET (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_IND_SET_ID NUMBER(10) NOT NULL,
	NEW_IND_SET_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_IND_SET PRIMARY KEY (CSRIMP_SESSION_ID, OLD_IND_SET_ID) USING INDEX,
	CONSTRAINT UK_MAP_IND_SET UNIQUE (CSRIMP_SESSION_ID, NEW_IND_SET_ID) USING INDEX,
	CONSTRAINT FK_MAP_IND_SET_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ISSU_METE_MISSI_DATA (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_METER_MISSIN_DATA_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_METER_MISSIN_DATA_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSU_METE_MISSI_DATA PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_METER_MISSIN_DATA_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSU_METE_MISSI_DATA UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_METER_MISSIN_DATA_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSU_METE_MISSI_DATA_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_ROUTE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ROUTE_LOG_ID NUMBER(10) NOT NULL,
	NEW_ROUTE_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ROUTE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ROUTE_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_ROUTE_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_ROUTE_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_ROUTE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SHEET_CHANGE_REQ (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SHEET_CHANGE_REQ_ID NUMBER(10) NOT NULL,
	NEW_SHEET_CHANGE_REQ_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SHEET_CHANGE_REQ PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SHEET_CHANGE_REQ_ID) USING INDEX,
	CONSTRAINT UK_MAP_SHEET_CHANGE_REQ UNIQUE (CSRIMP_SESSION_ID, NEW_SHEET_CHANGE_REQ_ID) USING INDEX,
	CONSTRAINT FK_MAP_SHEET_CHANGE_REQ_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SHEE_CHANG_REQ_ALERT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SHEET_CHANGE_REQ_ALERT_ID NUMBER(10) NOT NULL,
	NEW_SHEET_CHANGE_REQ_ALERT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SHEE_CHANG_REQ_ALERT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SHEET_CHANGE_REQ_ALERT_ID) USING INDEX,
	CONSTRAINT UK_MAP_SHEE_CHANG_REQ_ALERT UNIQUE (CSRIMP_SESSION_ID, NEW_SHEET_CHANGE_REQ_ALERT_ID) USING INDEX,
	CONSTRAINT FK_MAP_SHEE_CHANG_REQ_ALERT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_USER_MSG_FILE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_USER_MSG_FILE_ID NUMBER(10) NOT NULL,
	NEW_USER_MSG_FILE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_USER_MSG_FILE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_USER_MSG_FILE_ID) USING INDEX,
	CONSTRAINT UK_MAP_USER_MSG_FILE UNIQUE (CSRIMP_SESSION_ID, NEW_USER_MSG_FILE_ID) USING INDEX,
	CONSTRAINT FK_MAP_USER_MSG_FILE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_VAL_NOTE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_VAL_NOTE_ID NUMBER(10) NOT NULL,
	NEW_VAL_NOTE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_VAL_NOTE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_VAL_NOTE_ID) USING INDEX,
	CONSTRAINT UK_MAP_VAL_NOTE UNIQUE (CSRIMP_SESSION_ID, NEW_VAL_NOTE_ID) USING INDEX,
	CONSTRAINT FK_MAP_VAL_NOTE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CALENDAR_EVENT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CALENDAR_EVENT_ID NUMBER(10) NOT NULL,
	NEW_CALENDAR_EVENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CALENDAR_EVENT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CALENDAR_EVENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CALENDAR_EVENT UNIQUE (CSRIMP_SESSION_ID, NEW_CALENDAR_EVENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CALENDAR_EVENT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CLIENT_UTIL_SCRIPT (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CLIENT_UTIL_SCRIPT_ID NUMBER(10) NOT NULL,
	NEW_CLIENT_UTIL_SCRIPT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CLIENT_UTIL_SCRIPT PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CLIENT_UTIL_SCRIPT_ID) USING INDEX,
	CONSTRAINT UK_MAP_CLIENT_UTIL_SCRIPT UNIQUE (CSRIMP_SESSION_ID, NEW_CLIENT_UTIL_SCRIPT_ID) USING INDEX,
	CONSTRAINT FK_MAP_CLIENT_UTIL_SCRIPT_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CERT_TYPE (
	CSRIMP_SESSION_ID			NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CERT_TYPE_ID		NUMBER(10) NOT NULL,
	NEW_CERT_TYPE_ID		NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CERTIFICATION PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CERT_TYPE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CERTIFICATION UNIQUE (CSRIMP_SESSION_ID, NEW_CERT_TYPE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CERTIFICATION_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_ALT_COMPANY_NAME(
	CSRIMP_SESSION_ID				NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	NEW_ALT_COMPANY_NAME_ID			NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_ALT_COMPANY_NAME PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_ALT_COMPANY_NAME UNIQUE (CSRIMP_SESSION_ID, NEW_ALT_COMPANY_NAME_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_ALT_COMPANY_NAME FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_SUPP_REL_SCORE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_SUPPLIE_REL_SCORE_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_SUPPLIE_REL_SCORE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_SUPP_REL_SCORE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_SUPPLIE_REL_SCORE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_SUPP_REL_SCORE UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_SUPPLIE_REL_SCORE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_SUPP_REL_SCORE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);


CREATE TABLE CSRIMP.MAP_CHAIN_CUST_FILT_COL (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CUST_FILTER_COLUM_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CUST_FILTER_COLUM_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUST_FILT_COL PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CUST_FILTER_COLUM_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUST_FILT_COL UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CUST_FILTER_COLUM_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUST_FILT_COL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CUST_FILT_ITEM (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CUST_FILTER_ITEM_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CUST_FILTER_ITEM_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CUST_FILT_ITEM PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CUST_FILTER_ITEM_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CUST_FILT_ITEM UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CUST_FILTER_ITEM_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CUST_FILT_ITEM_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_CU_FI_IT_AG_TY (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_CHAIN_CU_FI_ITE_AGG_TYP_ID NUMBER(10) NOT NULL,
	NEW_CHAIN_CU_FI_ITE_AGG_TYP_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CU_FI_IT_AG_TY PRIMARY KEY (CSRIMP_SESSION_ID, OLD_CHAIN_CU_FI_ITE_AGG_TYP_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CU_FI_IT_AG_TY UNIQUE (CSRIMP_SESSION_ID, NEW_CHAIN_CU_FI_ITE_AGG_TYP_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CU_FI_IT_AG_TY_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);





CREATE TABLE CSRIMP.MAP_ISSUE_TEMPLATE (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_ISSUE_TEMPLATE_ID NUMBER(10) NOT NULL,
	NEW_ISSUE_TEMPLATE_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_ISSUE_TEMPLATE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_ISSUE_TEMPLATE_ID) USING INDEX,
	CONSTRAINT UK_MAP_ISSUE_TEMPLATE UNIQUE (CSRIMP_SESSION_ID, NEW_ISSUE_TEMPLATE_ID) USING INDEX,
	CONSTRAINT FK_MAP_ISSUE_TEMPLATE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_CHAIN_COMPANY_TYPE_ROLE(
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMPANY_TYPE_ROLE_ID		NUMBER(10, 0)	NOT NULL,
	NEW_COMPANY_TYPE_ROLE_ID		NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_COMPANY_TYPE_ROLE PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMPANY_TYPE_ROLE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_COMPANY_TYPE_ROLE UNIQUE (CSRIMP_SESSION_ID, NEW_COMPANY_TYPE_ROLE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_COMP_TYPE_ROLE_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE	
);

CREATE TABLE CSRIMP.MAP_CHAIN_CMP_TAB_CMP_TYP_ROLE(
	CSRIMP_SESSION_ID				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COMP_TAB_COMP_TYPE_ROLE_ID	NUMBER(10, 0)	NOT NULL,
	NEW_COMP_TAB_COMP_TYPE_ROLE_ID	NUMBER(10, 0)	NOT NULL,
	CONSTRAINT PK_MAP_CHAIN_CMP_TAB_CMP_TYP_R PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COMP_TAB_COMP_TYPE_ROLE_ID) USING INDEX,
	CONSTRAINT UK_MAP_CHAIN_CMP_TAB_CMP_TYP_R UNIQUE (CSRIMP_SESSION_ID, NEW_COMP_TAB_COMP_TYPE_ROLE_ID) USING INDEX,
	CONSTRAINT FK_MAP_CHAIN_CMP_TAB_TYP_RL_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_COOKIE_POLICY_CONSEN (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_COOKIE_POLICY_CONSENT_ID NUMBER(10) NOT NULL,
	NEW_COOKIE_POLICY_CONSENT_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_COOKIE_POLICY_CONSEN PRIMARY KEY (CSRIMP_SESSION_ID, OLD_COOKIE_POLICY_CONSENT_ID) USING INDEX,
	CONSTRAINT UK_MAP_COOKIE_POLICY_CONSEN UNIQUE (CSRIMP_SESSION_ID, NEW_COOKIE_POLICY_CONSENT_ID) USING INDEX,
	CONSTRAINT FK_MAP_COOKIE_POLICY_CONSEN_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SECONDARY_REGION_TREE_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_LOG_ID NUMBER(10) NOT NULL,
	NEW_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SCNDRY_RGN_TREE_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_SCNDRY_RGN_TREE_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_SCNDRY_RGN_TREE_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);

CREATE TABLE CSRIMP.MAP_SYS_TRANS_AUDIT_LOG (
	CSRIMP_SESSION_ID NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	OLD_SYS_TRANS_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	NEW_SYS_TRANS_AUDIT_LOG_ID NUMBER(10) NOT NULL,
	CONSTRAINT PK_MAP_SYS_TRANS_AUDIT_LOG PRIMARY KEY (CSRIMP_SESSION_ID, OLD_SYS_TRANS_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT UK_MAP_SYS_TRANS_AUDIT_LOG UNIQUE (CSRIMP_SESSION_ID, NEW_SYS_TRANS_AUDIT_LOG_ID) USING INDEX,
	CONSTRAINT FK_MAP_SYS_TRANS_AUDIT_LOG_IS FOREIGN KEY (CSRIMP_SESSION_ID) REFERENCES CSRIMP.CSRIMP_SESSION (CSRIMP_SESSION_ID) ON DELETE CASCADE
);
