-- Please update version.sql too -- this keeps clean builds in sync
define version=3106
define minor_version=14
@update_header

-- *** DDL ***
-- Create tables

-- Alter tables

ALTER TABLE csr.doc_folder_name_translation ADD (
	parent_sid		NUMBER(10)
);

ALTER TABLE csrimp.doc_folder_name_translation ADD (
	parent_sid		NUMBER(10)
);

BEGIN
	security.user_pkg.LogonAdmin();
	
	UPDATE csr.doc_folder_name_translation t 
	   SET parent_sid = (
		SELECT parent_sid_id 
		  FROM security.securable_object
		 WHERE sid_id = t.doc_folder_sid);
		 
	UPDATE csrimp.doc_folder_name_translation t 
	   SET parent_sid = (
		SELECT parent_sid_id 
		  FROM security.securable_object
		 WHERE sid_id = t.doc_folder_sid);
END;
/
	
ALTER TABLE csr.doc_folder_name_translation MODIFY (
	parent_sid		NUMBER(10) NOT NULL
);	

ALTER TABLE csrimp.doc_folder_name_translation MODIFY (
	parent_sid		NUMBER(10) NOT NULL
);

DECLARE
	v_cnt			NUMBER;
	v_curr_lang		VARCHAR2(1024) := 'NOTALANG';
BEGIN
	security.user_pkg.LogonAdmin();
	
	
	FOR R IN (
		SELECT doc_folder_sid, t.translated, t.lang, cnt from (
			SELECT parent_sid, translated, lang, COUNT(*) cnt FROM CSR.DOC_FOLDER_NAME_TRANSLATION ft
			GROUP BY parent_sid, translated, lang
		) t
		JOIN csr.DOC_FOLDER_NAME_TRANSLATION dt
		ON dt.parent_sid = t.parent_sid AND dt.translated = t.translated AND dt.lang = t.lang
		WHERE t.cnt > 1
		ORDER BY t.parent_sid, t.translated, t.lang, doc_folder_sid ASC
	) LOOP
		IF v_curr_lang != r.lang THEN
			v_cnt := r.cnt;
			v_curr_lang := r.lang;
		END IF;
		
		IF r.translated = 'supporting_docs' THEN
			IF v_cnt != 1 THEN
				UPDATE csr.DOC_FOLDER_NAME_TRANSLATION 
				   SET translated = translated || ' (' || (v_cnt - 1) || ')'
				 WHERE doc_folder_sid = r.doc_folder_sid
				   AND lang = r.lang;
			END IF;
			
			v_cnt := v_cnt - 1;
		ELSE
			IF v_cnt != r.cnt THEN
				UPDATE csr.DOC_FOLDER_NAME_TRANSLATION 
				   SET translated = translated || ' (' || v_cnt || ')'
				 WHERE doc_folder_sid = r.doc_folder_sid
				   AND lang = r.lang;
			END IF;
			
			v_cnt := v_cnt - 1;
		END IF;
	END LOOP;
END;
/

	
ALTER TABLE csr.doc_folder_name_translation ADD CONSTRAINT UK_DOC_FOLDER_NAME UNIQUE (parent_sid, lang, translated);
ALTER TABLE csrimp.doc_folder_name_translation ADD CONSTRAINT UK_DOC_FOLDER_NAME UNIQUE (parent_sid, lang, translated);

-- *** Grants ***

-- ** Cross schema constraints ***

-- *** Views ***
-- Please paste the content of the view and add a comment referencing the path of the create_views file which will contain your view changes.

-- *** Data changes ***
-- RLS

-- Data

-- ** New package grants **

-- *** Conditional Packages ***

-- *** Packages ***
@../doc_folder_body
@../initiative_doc_body
@../schema_body

@../csrimp/imp_body

@update_tail
