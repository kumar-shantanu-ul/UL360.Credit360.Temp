-- Please update version.sql too -- this keeps clean builds in sync
define version=3155
define minor_version=0
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

-- Get rid of tag_group_description orphans
DELETE FROM csr.tag_group_description
 WHERE (app_sid, tag_group_id) NOT IN (SELECT app_sid, tag_group_id FROM csr.tag_group);

ALTER TABLE CSR.TAG_GROUP_DESCRIPTION ADD CONSTRAINT FK_TAG_GROUP_DESCRIPTION
	FOREIGN KEY (APP_SID, TAG_GROUP_ID)
	REFERENCES CSR.TAG_GROUP(APP_SID, TAG_GROUP_ID) ON DELETE CASCADE
;

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view.

-- *** Data changes ***
-- RLS

-- Data


-- Get rid of the duplicates.
DECLARE
	v_base_tag_group_id NUMBER;
	v_base_tag_id NUMBER;
	v_this_pos NUMBER;
BEGIN
	FOR r IN (
		SELECT a.app_sid, c.host, a.tag_group_id, a.name, a.lang
		  FROM csr.tag_group_description a
		  JOIN csr.tag_group_description b ON a.app_sid = b.app_sid AND a.name = b.name AND a.lang = b.lang AND a.tag_group_id != b.tag_group_id
		  JOIN csr.customer c ON c.app_sid = a.app_sid
		 GROUP BY a.app_sid, c.host, a.tag_group_id, a.name, a.lang
		 ORDER BY a.tag_group_id)
	LOOP
		SELECT MIN(tag_group_id) INTO v_base_tag_group_id
		  FROM csr.tag_group_description 
		 WHERE app_sid = r.app_sid AND
			name = r.name AND 
			lang = r.lang;

		IF r.tag_group_id = v_base_tag_group_id THEN
			--dbms_output.put_line('skip '||v_base_tag_group_id);
			CONTINUE;
		END IF;
		
		--dbms_output.put_line(r.host||' del '||r.tag_group_id);

		FOR i IN (SELECT tag_id, ind_sid FROM csr.ind_tag WHERE tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id))
		LOOP
			SELECT pos INTO v_this_pos FROM csr.tag_group_member WHERE tag_id = i.tag_id;
			SELECT tag_id INTO v_base_tag_id FROM csr.tag_group_member WHERE tag_group_id = v_base_tag_group_id AND pos = v_this_pos;

			--dbms_output.put_line('insert '||v_base_tag_id||','||i.ind_sid||' based on '||i.tag_id||' at '||v_this_pos);
			BEGIN
			INSERT INTO csr.ind_tag (tag_id, ind_sid, app_sid)
			VALUES (v_base_tag_id, i.ind_sid, r.app_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN 
					--dbms_output.put_line('insert ignored on dup');
					NULL;
			END;
		END LOOP;
		/*
		Tag group also ref'd by all these tables, but the ind_tag dupes shouldn't be used by any of them; 
		however, if there are somehow any stray ones referenced, rename the taggroup desc to something unique so we can 
		still set the unique index.
		TABLE_NAME                        FOREIGN_KEY
		----------                        -----------
		CSR.INTERNAL_AUDIT_LOCKED_TAG     FK_AUD_SURV_LOCK_TAG_TAG_GROUP
		CSR.INITIATIVE_HEADER_ELEMENT     FK_INIT_HEADER_EL_TAG_GRP
		CSR.INIT_CREATE_PAGE_EL_LAYOUT    FK_INIT_EL_LAYT_TAG_GRP
		CSR.INIT_TAB_ELEMENT_LAYOUT       FK_INIT_TAB_LAYT_TAG_GRP
		CHAIN.HIGG_MODULE_TAG_GROUP       FK_HIGG_MOD_TG
		CHAIN.DEDUPE_MERGE_LOG            FK_DEDUPE_MERGE_LOG_TAG_GROUP
		CSR.METER_HEADER_ELEMENT          FK_METER_HEADER_EL_TAG_GRP
		CSR.BENCHMARK_DASHBOARD_CHAR      FK_BENCHMARK_DAS_TAG_GRP
		CHAIN.COMPANY_TYPE_TAG_GROUP      FK_COMP_TYPE_TAG_GR_TAG_GROUP
		CSR.NON_COMPLIANCE_TYPE_TAG_GROUP FK_NON_COMPL_TYP_TAG_GR_TAG_GR
		CSR.INTERNAL_AUDIT_TYPE_TAG_GROUP FK_INT_AUDIT_TYP_TAG_GR_TAG_GR
		CHAIN.ACTIVITY_TYPE_TAG_GROUP     FK_ACT_TYP_TAG_GROUP_TAG_GRP
		CSR.METER_ELEMENT_LAYOUT          FK_METER_EL_LAYOUT_TAG_GRP
		CSR.PROPERTY_CHARACTER_LAYOUT     FK_PROPERTY_CHAR_LAYT_TAG_GRP
		CSR.PROPERTY_ELEMENT_LAYOUT       FK_PROPERTY_EL_LAYOUT_TAG_GRP
		CSR.PROJECT_TAG_GROUP             FK_TAG_GRP_PRJ_TAG_GRP
		CSR.DATAVIEW                      FK_DATAVIEW_TAG_GROUP
		CHAIN.COMPANY_TAG_GROUP           FK_COMP_TAG_GROUP_TAG_GROUP
		CSR.REGION_TYPE_TAG_GROUP         FK_REG_TYP_TG_TG
		DONATIONS.REGION_FILTER_TAG_GROUP REFTAG_GROUP253
		CSR.AXIS                          FK_REL_TAG_GROUP_AXIS
		CSR.AXIS                          FK_PRI_TAG_GROUP_AXIS
		CSR.SNAPSHOT_TAG_GROUP            REFTAG_GROUP1423
		CSR.DELEGATION                    FK_DELEG_TAG_GROUP_ID
		*/
		
		DELETE FROM csr.ind_tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM csr.tag_group_member WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM chain.dedupe_mapping WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		
		BEGIN
			DELETE FROM csr.tag_group_description WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
			DELETE FROM csr.tag_group WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		EXCEPTION
			WHEN OTHERS THEN
				dbms_output.put_line('update dupe '||'TG'||r.tag_group_id||'||_Dup:'||r.name);
				UPDATE csr.tag_group_description
				   SET name = 'TG'||r.tag_group_id||'||_Dup:'||r.name
				 WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		END;

	END LOOP;
END;
/

DECLARE
	v_exists	NUMBER;
BEGIN
	SELECT COUNT(*)
	  INTO v_exists
	  FROM all_indexes
	 WHERE owner = 'CSR'
	   AND table_name = 'TAG_GROUP_DESCRIPTION'
	   AND index_name = 'UK_TAG_GROUP_DESCRIPTION_NAME';
	 
	IF v_exists = 1 THEN
		EXECUTE IMMEDIATE 'DROP INDEX CSR.UK_TAG_GROUP_DESCRIPTION_NAME';
	END IF;
END;
/

CREATE UNIQUE INDEX CSR.UK_TAG_GROUP_DESCRIPTION_NAME ON CSR.TAG_GROUP_DESCRIPTION(APP_SID, NAME, LANG)
;


-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../csr_app_body

@update_tail
