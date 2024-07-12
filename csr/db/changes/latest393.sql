-- Please update version.sql too -- this keeps clean builds in sync
define version=393
@update_header

-- we're trashing /csr/site/reports/gri.xml 
-- so make sure all the data is set up on the new indexes
DECLARE
    v_attachment_id NUMBER(10);
    v_exists         NUMBER(10);
    v_done          NUMBER(10) :=0;
BEGIN
	-- auto assign ref fields on all the indexes
	FOR m IN (
		SELECT module_root_sid 
		  FROM section_module sm 
		 WHERE sm.label = 'G3'
	)
	LOOP
		FOR r IN (
			SELECT section_sid, REGEXP_SUBSTR(title, '^([^.]*)') ref
			  FROM v$visible_version
			 WHERE module_root_sid = m.module_root_sid
			   AND REGEXP_SUBSTR(title, '^([^.]*)') IN (
				select REGEXP_SUBSTR(title, '^([^.]*)')
				  from v$visible_version  
				 where module_root_sid = m.module_root_sid
				   and INSTR(title,'.') BETWEEN 1 and 6
				 group by REGEXP_SUBSTR(title, '^([^.]*)')
				having count(*) = 1
			)
		)
		LOOP
			update section set ref = r.ref where section_sid = r.section_sid and ref is null;
		END LOOP;
	END LOOP;
	-- insert the right indicator sids into the text thing
    FOR r IN (
        SELECT * 
          FROM (
            SELECT i.ind_sid, r.section_sid, i.REF, version_number, i.app_Sid, 
                case when i.ref is not null and r.ref is null then 1 else 0 end not_found
              FROM (
                SELECT app_sid, ind_sid, description, upper(t.item) ref
                  FROM ind, TABLE(utils_pkg.SplitString(REPLACE(gri,' ',''),','))t
                 WHERE gri IS NOT NULL
              )i
              LEFT OUTER JOIN (
                SELECT DISTINCT s.REF, s.section_sid, sm.app_sid, s.version_number
                  FROM section_module sm, v$visible_version s
                 WHERE sm.label = 'G3'
                   AND sm.module_root_sid = s.module_root_sid
              )r ON i.ref = r.ref AND i.app_sid = r.app_sid
        )
        WHERE NOT_FOUND = 0
    )
    LOOP
        SELECT COUNT(*)
          INTO v_exists
          FROM attachment_history ah, attachment a
         WHERE ah.attachment_id = a.attachment_id
           AND a.indicator_sid = r.ind_sid;
        IF v_exists = 0 THEN
            SELECT attachment_id_seq.nextval
              INTO v_attachment_id
              FROM DUAL;
              
            INSERT INTO attachment
                (ATTACHMENT_ID, FILENAME, MIME_TYPE, INDICATOR_SID, APP_SID) 
                  SELECT v_attachment_id, description, 'application/indicator-sid', ind_sid, app_sid
                    FROM ind 
                    WHERE ind_sid = r.ind_sid
                    ;
                    
            INSERT INTO attachment_history
                (SECTION_SID, VERSION_NUMBER, ATTACHMENT_ID, APP_SID)
            VALUES (r.section_sid, r.version_number, v_attachment_id, r.app_sid);
            v_done := v_done +1;
        END IF;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_done||' processed');
END;
/

connect security/security@aspen

BEGIN    
    -- now fix up menus
	FOR r IN (
		SELECT host, sm.sid_id 
		  FROM security.menu sm, security.securable_object so, csr.customer c 
		 WHERE lower(action) like '/csr/site/reports/gri%'
		   AND sm.sid_id =so.sid_Id 
		   AND so.application_sid_id = c.app_sid
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('Fixing G3 menu link on '||r.host);
		UPDATE security.menu SET action = '/csr/site/text/overview/overview.acds?module=g3' WHERE sid_id = r.sid_id;
		UPDATE security.securable_object SET name = 'csr_text_overview_overview_g3' WHERE sid_id = r.sid_id;
	END LOOP;
END;
/


connect csr/csr@aspen
 
@update_tail
