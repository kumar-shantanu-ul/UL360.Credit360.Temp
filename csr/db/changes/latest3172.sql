define version=3172
define minor_version=0
define is_combined=1
@update_header

-- clean out junk in csrimp
begin
for r in (select table_name from all_tables where owner='CSRIMP' and table_name!='CSRIMP_SESSION') loop
execute immediate 'truncate table csrimp.'||r.table_name;
end loop;
delete from csrimp.csrimp_session;
commit;
end;
/
CREATE TABLE chain.supplier_relationship_source (
	app_sid							NUMBER(10) DEFAULT SYS_CONTEXT('SECURITY','APP') NOT NULL,
	purchaser_company_sid			NUMBER(10) NOT NULL,
	supplier_company_sid			NUMBER(10) NOT NULL,
	source_type						NUMBER(2) NOT NULL,
	object_id						NUMBER(10) NULL,
	CONSTRAINT uk_supplier_relationship_src UNIQUE (app_sid, purchaser_company_sid, supplier_company_sid, source_type, object_id),
	CONSTRAINT chk_supp_rel_src_type CHECK (source_type IN (0, 1, 2)),
	CONSTRAINT fk_supp_rel_src_supp_rel FOREIGN KEY (app_sid, purchaser_company_sid, supplier_company_sid)
	REFERENCES chain.supplier_relationship (app_sid, purchaser_company_sid, supplier_company_sid) ON DELETE CASCADE
);
CREATE INDEX chain.ix_supplier_relationship_src ON chain.supplier_relationship_source(app_sid, purchaser_company_sid, supplier_company_sid);
CREATE TABLE csrimp.chain_supp_rel_source (
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	purchaser_company_sid			NUMBER(10),
	supplier_company_sid			NUMBER(10),
	source_type						NUMBER(2),
	object_id						NUMBER(10),
	CONSTRAINT fk_supp_rel_src_session FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE
);
CREATE SEQUENCE chain.company_type_role_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;
CREATE SEQUENCE chain.comp_tab_comp_type_role_id_seq
	START WITH 1
	INCREMENT BY 1
	NOMINVALUE
	NOMAXVALUE
	CACHE 20
	NOORDER;
CREATE TABLE chain.company_tab_company_type_role(
	app_sid							NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'APP') NOT NULL,
	comp_tab_comp_type_role_id		NUMBER(10, 0)	NOT NULL,
	company_tab_id					NUMBER(10, 0)	NOT NULL,
	company_group_type_id			NUMBER(10, 0),
	company_type_role_id			NUMBER(10, 0)
);
CREATE TABLE csrimp.chain_comp_tab_comp_type_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	comp_tab_comp_type_role_id		NUMBER(10, 0)	NOT NULL,
	company_tab_id					NUMBER(10, 0)	NOT NULL,
	company_group_type_id			NUMBER(10, 0),
	company_type_role_id			NUMBER(10, 0)
);
CREATE TABLE csrimp.map_chain_company_type_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_company_type_role_id		NUMBER(10, 0)	NOT NULL,
	new_company_type_role_id		NUMBER(10, 0)	NOT NULL
);
CREATE TABLE csrimp.map_chain_cmp_tab_cmp_typ_role(
	csrimp_session_id				NUMBER(10, 0)	DEFAULT SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') NOT NULL,
	old_comp_tab_comp_type_role_id	NUMBER(10, 0)	NOT NULL,
	new_comp_tab_comp_type_role_id	NUMBER(10, 0)	NOT NULL
);


ALTER TABLE csr.issue_type ADD (
	region_is_mandatory NUMBER(1) DEFAULT 0 NOT NULL,
	CONSTRAINT chk_iss_type_reg_is_mand CHECK (region_is_mandatory IN (0,1))
);
ALTER TABLE csrimp.issue_type ADD region_is_mandatory NUMBER(1) DEFAULT 0 NOT NULL;
ALTER TABLE csr.compliance_item_rollout
  ADD SUPPRESS_ROLLOUT NUMBER(1,0) DEFAULT 0;
ALTER TABLE csrimp.compliance_item_rollout
  ADD SUPPRESS_ROLLOUT NUMBER(1,0) DEFAULT 0;
ALTER TABLE csr.tag
ADD parent_id NUMBER(10);
ALTER TABLE csr.tag
ADD CONSTRAINT FK_PARENT_TAG_ID FOREIGN KEY(app_sid, parent_id) REFERENCES csr.tag(app_sid, tag_id);
CREATE INDEX csr.ix_tag_parent_id ON csr.tag (app_sid, parent_id);
ALTER TABLE csrimp.tag
ADD parent_id NUMBER(10);
ALTER TABLE csr.tag_group
ADD is_hierarchical NUMBER(1, 0) DEFAULT 0 NOT NULL;
ALTER TABLE csr.tag_group
ADD CONSTRAINT CHK_IS_HIERARCHICAL CHECK (IS_HIERARCHICAL IN (0, 1));
ALTER TABLE csrimp.tag_group
ADD is_hierarchical NUMBER(1, 0) NOT NULL;
ALTER TABLE csrimp.tag_group
ADD CONSTRAINT CHK_IS_HIERARCHICAL CHECK (IS_HIERARCHICAL IN (0, 1));
ALTER TABLE chain.company_type_role
  ADD company_type_role_id	NUMBER(10, 0);
UPDATE chain.company_type_role
   SET company_type_role_id = chain.company_type_role_id_seq.NEXTVAL;
ALTER TABLE chain.company_type_capability
 DROP CONSTRAINT fk_ctc_company_type_role DROP INDEX;
ALTER TABLE chain.supplier_involvement_type
 DROP CONSTRAINT fk_supp_inv_type_co_type_role DROP INDEX;
ALTER TABLE chain.company_type_role
 DROP CONSTRAINT pk_company_type_role  DROP INDEX;
 ALTER TABLE chain.company_type_role
MODIFY company_type_role_id	NUMBER(10, 0) NOT NULL;
ALTER TABLE chain.company_type_role ADD CONSTRAINT pk_company_type_role
	PRIMARY KEY (app_sid, company_type_role_id);
ALTER TABLE chain.company_type_role ADD CONSTRAINT uk_company_type_role
	UNIQUE (app_sid, company_type_id, role_sid) USING INDEX;
  
ALTER TABLE chain.company_type_capability ADD CONSTRAINT fk_ctc_company_type_role
	FOREIGN KEY (app_sid, primary_company_type_id, primary_company_type_role_sid)
	REFERENCES chain.company_type_role(app_sid, company_type_id, role_sid);
ALTER TABLE chain.supplier_involvement_type ADD CONSTRAINT fk_supp_inv_type_co_type_role
	FOREIGN KEY (app_sid, user_company_type_id, restrict_to_role_sid)
	REFERENCES chain.company_type_role (app_sid, company_type_id, role_sid);
ALTER TABLE csrimp.chain_company_type_role
 DROP CONSTRAINT pk_chain_company_type_role DROP INDEX;
ALTER TABLE csrimp.chain_company_type_role
  ADD company_type_role_id NUMBER(10, 0) NOT NULL;
ALTER TABLE csrimp.chain_company_type_role ADD CONSTRAINT uk_chain_company_type_role
	UNIQUE (CSRIMP_SESSION_ID, COMPANY_TYPE_ID, ROLE_SID) USING INDEX;
ALTER TABLE csrimp.chain_company_type_role ADD CONSTRAINT pk_chain_company_type_role
	PRIMARY KEY (CSRIMP_SESSION_ID, COMPANY_TYPE_ROLE_ID);
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT chk_company_type_role_group
	CHECK ((company_group_type_id IS NOT NULL AND company_type_role_id IS NULL) OR (company_group_type_id IS NULL AND company_type_role_id IS NOT NULL));
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_tab
	FOREIGN KEY (app_sid, company_tab_id)
	REFERENCES chain.company_tab (app_sid, company_tab_id);
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_group_type
	FOREIGN KEY (company_group_type_id)
	REFERENCES chain.company_group_type (company_group_type_id);
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT fk_ctctr_company_type_role
	FOREIGN KEY (app_sid, company_type_role_id)
	REFERENCES chain.company_type_role (app_sid, company_type_role_id);
ALTER TABLE chain.company_tab_company_type_role ADD CONSTRAINT pk_comp_tab_comp_type_role
	PRIMARY KEY (app_sid, comp_tab_comp_type_role_id);
ALTER TABLE csrimp.chain_comp_tab_comp_type_role ADD CONSTRAINT pk_chain_cmp_tab_cmp_type_role
	PRIMARY KEY (csrimp_session_id, comp_tab_comp_type_role_id);
ALTER TABLE csrimp.chain_comp_tab_comp_type_role ADD CONSTRAINT fk_chain_cmp_tab_type_role_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT pk_map_chain_company_type_role
	PRIMARY KEY (csrimp_session_id, old_company_type_role_id) USING INDEX;
	
ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT uk_map_chain_company_type_role
	UNIQUE (csrimp_session_id, new_company_type_role_id) USING INDEX;
ALTER TABLE csrimp.map_chain_company_type_role ADD CONSTRAINT fk_map_chain_comp_type_role_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT pk_map_chain_cmp_tab_cmp_typ_r
	PRIMARY KEY (csrimp_session_id, old_comp_tab_comp_type_role_id) USING INDEX;
	
ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT uk_map_chain_cmp_tab_cmp_typ_r
	UNIQUE (csrimp_session_id, new_comp_tab_comp_type_role_id) USING INDEX;
ALTER TABLE csrimp.map_chain_cmp_tab_cmp_typ_role ADD CONSTRAINT fk_map_chain_cmp_tab_typ_rl_is
	FOREIGN KEY (csrimp_session_id) REFERENCES csrimp.csrimp_session (csrimp_session_id) ON DELETE CASCADE;
CREATE INDEX chain.ix_comp_tab_type_comp_type_rl ON chain.company_tab_company_type_role (app_sid, company_type_role_id);
CREATE INDEX chain.ix_comp_tab_type_comp_tab ON chain.company_tab_company_type_role (app_sid, company_tab_id);
CREATE INDEX chain.ix_comp_tab_type_comp_grp_type ON chain.company_tab_company_type_role (company_group_type_id);


grant select, insert, update on chain.supplier_relationship_source to csrimp;
grant select,insert,update,delete on csrimp.chain_supp_rel_source to tool_user;
grant select on chain.supplier_relationship_source to csr;
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_company_type_role to csr;
GRANT SELECT ON chain.company_type_role_id_seq TO csr;
GRANT SELECT ON chain.comp_tab_comp_type_role_id_seq TO csr;
GRANT SELECT ON chain.company_type_role_id_seq TO csrimp;
GRANT SELECT ON chain.comp_tab_comp_type_role_id_seq TO csrimp;
GRANT SELECT, INSERT, UPDATE ON chain.company_tab_company_type_role TO csrimp;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.chain_comp_tab_comp_type_role TO tool_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON csrimp.flow_item_region TO tool_user;




CREATE OR REPLACE VIEW CSR.V$TAG_GROUP AS
	SELECT tg.app_sid, tg.tag_group_id, NVL(tgd.name, tgden.name) name,
		tg.multi_select, tg.mandatory, tg.applies_to_inds,
		tg.applies_to_regions, tg.applies_to_non_compliances, tg.applies_to_suppliers,
		tg.applies_to_initiatives, tg.applies_to_chain, tg.applies_to_chain_activities,
		tg.applies_to_chain_product_types, tg.applies_to_chain_products, tg.applies_to_chain_product_supps,
		tg.applies_to_quick_survey, tg.applies_to_audits,
		tg.applies_to_compliances, tg.lookup_key, tg.is_hierarchical
	  FROM csr.tag_group tg
	LEFT JOIN csr.tag_group_description tgd ON tgd.app_sid = tg.app_sid AND tgd.tag_group_id = tg.tag_group_id AND tgd.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_group_description tgden ON tgden.app_sid = tg.app_sid AND tgden.tag_group_id = tg.tag_group_id AND tgden.lang = 'en';
CREATE OR REPLACE VIEW CSR.V$TAG AS
	SELECT t.app_sid, t.tag_id, NVL(td.tag, tden.tag) tag, NVL(td.explanation, tden.explanation) explanation,
		t.lookup_key, t.exclude_from_dataview_grouping, t.parent_id
	  FROM csr.tag t
	LEFT JOIN csr.tag_description td ON td.app_sid = t.app_sid AND td.tag_id = t.tag_id AND td.lang = SYS_CONTEXT('SECURITY', 'LANGUAGE')
	LEFT JOIN csr.tag_description tden ON tden.app_sid = t.app_sid AND tden.tag_id = t.tag_id AND tden.lang = 'en';




UPDATE csr.default_alert_frame_body
	   SET html = '<template>'||
		'<table width="700">'||
		'<tbody>'||
		'<tr>'||
		'<td>'||
		'<div style="font-size:9pt;color:#888888;font-family:Arial,Helvetica;border-bottom:4px solid #007987;margin-bottom:20px;padding-bottom:10px;">PURE'||unistr('\2122')||' Platform by UL EHS Sustainability</div>'||
		'<mergefield name="BODY" /><br />' ||
		'<div style="font-family:Arial,Helvetica;font-size:9pt;color:#888888;border-top:4px solid #007987;margin-top:20px;padding-top:10px;padding-bottom:10px;">For questions please email '||
		'<a href="mailto:support@credit360.com" style="color:#007987;text-decoration:none;">our support team</a>.</div>'||
		'</td>'||
		'</tr>'||
		'</tbody>'||
		'</table>'||
		'</template>';
INSERT INTO CSR.UTIL_SCRIPT (UTIL_SCRIPT_ID,UTIL_SCRIPT_NAME,DESCRIPTION,UTIL_SCRIPT_SP,WIKI_ARTICLE) VALUES (51, 'Restart failed campaign', 'Restarts a campaign that failed with an error and therefore cannot be re-processed. Should only be ran if the issue causing the error has been resolved.', 'RestartFailedCampaign', NULL);
INSERT INTO CSR.UTIL_SCRIPT_PARAM (UTIL_SCRIPT_ID,PARAM_NAME,PARAM_HINT,POS,PARAM_VALUE) VALUES (51, 'Campaign SID', 'The SID of the campaign that has errored', 1, NULL);
UPDATE CSR.UTIL_SCRIPT_PARAM 
   SET PARAM_NAME = 'Group Name',
       PARAM_HINT = 'The name of the group to add/remove'
 WHERE UTIL_SCRIPT_ID = 36
   AND POS = 1;
UPDATE csr.compliance_item_region reg
   SET out_of_scope = 1
 WHERE EXISTS (
		SELECT 1
		  FROM csr.compliance_item_rollout cirt 
		  JOIN csr.compliance_item ci on cirt.compliance_item_id = ci.compliance_item_id
		 WHERE (cirt.country_group = 'eu' or (cirt.country = 'gb' and cirt.region_group is null)) and ci.source = 1 AND reg.compliance_item_id = cirt.compliance_item_id);
BEGIN
	security.user_pkg.LogonAdmin;
	INSERT INTO csr.flow_inv_type_alert_class(app_sid, flow_involvement_type_id, flow_alert_class)
	SELECT app_sid, flow_involvement_type_id, 'audit'
	  FROM csr.flow_involvement_type
	 WHERE flow_involvement_type_id = 2 /* csr_data_pkg.FLOW_INV_TYPE_AUDIT_COMPANY */
	   AND (app_sid, flow_involvement_type_id, 'audit') NOT IN (SELECT app_sid, flow_involvement_type_id, flow_alert_class FROM csr.flow_inv_type_alert_class);
END;
/
BEGIN
	security.user_pkg.LogonAdmin;
	INSERT INTO chain.supplier_relationship_source (app_sid, purchaser_company_sid, supplier_company_sid, source_type)
	SELECT app_sid, purchaser_company_sid, supplier_company_sid, 0 /* chain_pkg.AUTO_REL_SRC */
	  FROM chain.supplier_relationship
	 WHERE active = 1 AND deleted = 0;
END;
/
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ALERT' WHERE table_name = 'COMPLIANCE_ALERT';
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ENHESA_MAP' WHERE table_name = 'COMPLIANCE_ENHESA_MAP';
UPDATE csr.schema_table SET csrimp_table_name = 'COMPLIANCE_ENHESA_MAP_ITEM' WHERE table_name = 'COMPLIANCE_ENHESA_MAP_ITEM';






@..\..\..\aspen2\cms\db\tab_pkg
@..\region_api_pkg
@..\issue_pkg
@..\compliance_pkg
@..\csrimp\imp_pkg
@..\util_script_pkg
@..\indicator_api_pkg
@..\tag_pkg
@..\chain\chain_pkg
@..\schema_pkg
@..\chain\company_pkg
@..\chain\plugin_pkg
@..\chain\type_capability_pkg


@..\..\..\aspen2\cms\db\tab_body
@..\enable_body
@..\..\..\yam\db\webmail_body
@..\region_api_body
@..\chain\filter_body
@..\issue_body
@..\schema_body
@..\csrimp\imp_body
@..\compliance_library_report_body
@..\compliance_body
@..\util_script_body
@..\indicator_api_body
@..\tag_body
@..\strategy_body
@..\integration_api_body
@..\chain\audit_request_body
@..\chain\business_relationship_body
@..\chain\company_body
@..\chain\company_dedupe_body
@..\chain\invitation_body
@..\chain\test_chain_utils_body
@..\chain\uninvited_body
@..\chain\chain_body
@..\chain\company_type_body
@..\chain\plugin_body



@update_tail
