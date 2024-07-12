-- Please update version.sql too -- this keeps clean builds in sync
define version=3150
define minor_version=20
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

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
			dbms_output.put_line('skip '||v_base_tag_group_id);
			CONTINUE;
		END IF;
		
		dbms_output.put_line(r.host||' del '||r.tag_group_id);

		FOR i IN (SELECT tag_id, ind_sid FROM csr.ind_tag WHERE tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id))
		LOOP
			SELECT pos INTO v_this_pos FROM csr.tag_group_member WHERE tag_id = i.tag_id;
			SELECT tag_id INTO v_base_tag_id FROM csr.tag_group_member WHERE tag_group_id = v_base_tag_group_id AND pos = v_this_pos;

			dbms_output.put_line('insert '||v_base_tag_id||','||i.ind_sid||' based on '||i.tag_id||' at '||v_this_pos);
			BEGIN
			INSERT INTO csr.ind_tag (tag_id, ind_sid, app_sid)
			VALUES (v_base_tag_id, i.ind_sid, r.app_sid);
			EXCEPTION
				WHEN DUP_VAL_ON_INDEX THEN 
					dbms_output.put_line('insert ignored on dup');
					NULL;
			END;
		END LOOP;

		DELETE FROM csr.ind_tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM csr.tag_group_member WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag WHERE app_sid = r.app_sid AND tag_id IN (SELECT tag_id FROM CSR.TAG_GROUP_MEMBER WHERE TAG_GROUP_ID = r.tag_group_id);
		DELETE FROM csr.tag_group WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
		DELETE FROM csr.tag_group_description WHERE app_sid = r.app_sid AND tag_group_id = r.tag_group_id;
	END LOOP;
END;
/


CREATE UNIQUE INDEX CSR.UK_TAG_GROUP_DESCRIPTION_NAME ON CSR.TAG_GROUP_DESCRIPTION(APP_SID, NAME, LANG)
;

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***

@update_tail
