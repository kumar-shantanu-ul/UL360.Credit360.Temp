CREATE OR REPLACE PACKAGE  BODY CSR.section_search_pkg
IS

/*
	After populating temp_section_search_result with matches
	adjust the score weighting to give preference to items that 
	have been added or changed more recently.
*/
PROCEDURE internal_WeightRecent
AS
	v_max			NUMBER := 20; -- weight best 20 results
	v_weight		NUMBER := 30; -- Max percent increase to score
	v_step			NUMBER;
	v_i				NUMBER;
	v_results		NUMBER;
BEGIN
	SELECT COUNT(*) INTO v_results FROM temp_section_search_result;
	-- Only weight results if there are any
	IF v_results > 0 THEN
		-- Split weighting 40 - 0 across result set based on number of results
		SELECT ROUND(v_weight / LEAST(v_results, v_max), 2) INTO v_step
		  FROM DUAL;

		v_i := 1;
		FOR r IN (
			SELECT section_sid, doc_id, title, result_score
			  FROM (
					SELECT section_sid, doc_id, title, NVL(changed_dtm, TO_DATE('01/01/1900', 'dd/mm/yyyy')) changed_dtm, result_score
					  FROM temp_section_search_result
					 ORDER BY result_score DESC
					)
			 WHERE rownum <= v_max
			 ORDER BY changed_dtm ASC
		)
		LOOP
			UPDATE temp_section_search_result
			   SET result_score = ROUND(r.result_score * (v_step * v_i)/100) + r.result_score
			 WHERE NVL(section_sid, 1) = NVL(r.section_sid, 1)
			   AND NVL(doc_id, 1) = NVL(r.doc_id, 1);

			v_i := v_i + 1;
		END LOOP;
	END IF;
END;

FUNCTION GetSectionSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2
IS
	v_return		VARCHAR2(3000);
BEGIN
	v_return := ctx_doc.SNIPPET(
					index_name => 'csr.ix_section_body_search', 
					textkey => ctx_doc.pkencode(in_app_sid, in_section_sid, in_version_number), 
					text_query => in_text_query, 
					starttag => '<span class="highlight">', 
					endtag => '</span>',
					entity_translation => FALSE,
					separator => '<span class="searchSep">...</span>'
				);
	RETURN v_return;
END;

FUNCTION GetDocDataSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_doc_data			IN security_pkg.T_SID_ID,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2
IS
	v_return		VARCHAR2(3000);
BEGIN
	v_return := ctx_doc.SNIPPET(
					index_name => 'csr.ix_doc_search', 
					textkey => ctx_doc.pkencode(in_app_sid, in_doc_data), 
					text_query => in_text_query, 
					starttag => '<span class="highlight">', 
					endtag => '</span>',
					entity_translation => FALSE,
					separator => '<span class="searchSep">...</span>'
				);
	RETURN v_return;
	EXCEPTION 
		WHEN OTHERS THEN -- ORACLE_TEXT_ERROR
			RETURN ''; -- certain encrypted or protected documents cause this to fail
END;

FUNCTION GetDocDescSnippet(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_doc_id			IN doc_version.doc_id%TYPE,
	in_version			IN doc_version.version%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2
IS
	v_return		VARCHAR2(3000);
BEGIN
	v_return := ctx_doc.SNIPPET(
					index_name => 'csr.ix_doc_desc_search', 
					textkey => ctx_doc.pkencode(in_app_sid, in_doc_id, in_version), 
					text_query => in_text_query, 
					starttag => '<span class="highlight">', 
					endtag => '</span>',
					entity_translation => FALSE,
					separator => '<span class="searchSep">...</span>'
				);
	RETURN v_return;
END;

FUNCTION GetMarkupTitle(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN VARCHAR2
IS
	v_return	CLOB;
BEGIN
	CTX_DOC.MARKUP(
			index_name	=> 'csr.ix_section_title_search',
			textkey		=> ctx_doc.pkencode(in_app_sid, in_section_sid, in_version_number),
			text_query	=> in_text_query,
			restab		=> v_return,
			plaintext	=> FALSE,
			tagset		=> 'TEXT_DEFAULT',
			starttag	=> '<span class="highlight">', 
			endtag		=> '</span>'
	);
	RETURN dbms_lob.substr(v_return, 2000, 1);
END;

FUNCTION GetMarkupBody(
	in_app_sid			IN security_pkg.T_SID_ID,
	in_section_sid		IN security_pkg.T_SID_ID,
	in_version_number	IN section_version.version_number%TYPE,
	in_text_query		IN VARCHAR2)
RETURN CLOB
IS
	v_return	CLOB;
BEGIN
	CTX_DOC.MARKUP(
			index_name	=> 'csr.ix_section_body_search',
			textkey		=> ctx_doc.pkencode(in_app_sid, in_section_sid, in_version_number),
			text_query	=> in_text_query,
			restab		=> v_return,
			plaintext	=> FALSE,
			tagset		=> 'HTML_DEFAULT',
			starttag	=> '<span class="highlight">', 
			endtag		=> '</span>'
	);
	RETURN v_return;
END;

FUNCTION InstrCount(
	in_text		IN VARCHAR2,
	in_contains	IN VARCHAR2
)
RETURN NUMBER
IS
	v_count NUMBER(10);
BEGIN
	-- in 11 g this can be done with: REGEXP_COUNT(in_text, in_contains)
	-- however, it might give different results because in_contains will be treated as a pattern instead of as literal text
	IF in_text IS NULL THEN
		RETURN 0;
	ELSE
		SELECT (LENGTH(in_text) - LENGTH(REPLACE(LOWER(in_text), LOWER(in_contains)))) / LENGTH(in_contains)
		  INTO v_count
		  FROM DUAL;
	END IF;
	RETURN v_count;
END;

/* PROCEDURES (INTERNAL) */
PROCEDURE INTERNAL_compileDocLibSearch
(
	in_contains_text		IN	VARCHAR2,
	in_like_text			IN VARCHAR2,
	in_editor_ids			IN	security_pkg.T_SID_IDS,
	in_last_modified_dtm	IN	SECTION_VERSION.changed_dtm%TYPE,
	in_last_modified_dir	IN	NUMBER,
	in_created_dtm			IN	SECTION_VERSION.changed_dtm%TYPE,
	in_created_dir			IN	NUMBER,
	in_filter_mime			IN	NUMBER
)
AS
	v_like_text				VARCHAR2(1000);
	v_sid_id				security_pkg.T_SID_ID;
	v_doclib_id				security_pkg.T_SID_ID;
	v_act_id				security_pkg.T_ACT_ID;
	t_editor_ids			security.T_SID_TABLE;
	v_has_editor_filter		NUMBER DEFAULT 1;
BEGIN
	v_act_id := SYS_CONTEXT('SECURITY', 'ACT');
	v_sid_id := SYS_CONTEXT('SECURITY', 'SID');
	v_doclib_id := securableobject_pkg.GetSidFromPath(v_act_id, SYS_CONTEXT('SECURITY', 'APP'), 'documents');
	v_like_text := REPLACE(in_like_text, '_', '^_');

	t_editor_ids		:= security_pkg.SidArrayToTable(in_editor_ids);
	IF in_editor_ids.COUNT = 0 OR (in_editor_ids.COUNT = 1 AND in_editor_ids(1) IS NULL) THEN
		v_has_editor_filter := 0;
	END IF;

	-- This hack works around the fact that Oracle crashes if you use a user function
	-- in a query containing CONTAINS:
	-- https://metalink.oracle.com/metalink/plsql/f?p=130:14:8256320231539974957::::p14_database_id,p14_docid,p14_show_header,p14_show_help,p14_black_frame,p14_font:NOT,6685261.8,1,0,1,helvetica
	-- bug 6685261
	-- there is a patch for linux-x86 but not for amd64
	-- NOTE: IF COMPILING THIS FAILS, CHECK YOU HAVE ORACLE TEXT, SEE https://fogbugz.credit360.com/default.asp?W289

	-- Get folders with read permission
	INSERT INTO temp_tree (sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, is_leaf, path)
		SELECT sid_id, parent_sid_id, dacl_id, class_id, name, flags, owner, so_level, is_leaf, path
		  FROM TABLE ( SecurableObject_pkg.GetTreeWithPermAsTable(security_pkg.GetACT(), v_doclib_id, security_pkg.PERMISSION_READ) )
		 WHERE sid_id NOT IN (
					SELECT so.sid_id
					  FROM security.securable_object so
					  START WITH so.sid_id IN (SELECT trash_folder_sid FROM doc_library WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP'))
					CONNECT BY PRIOR sid_id = parent_sid_id
				);

	-- Filter documents by editor last updated and created dates
	INSERT INTO temp_doc_id_path (doc_id, path)
	SELECT DISTINCT d.doc_id, tt.path
	  FROM v$doc_approved d
	  JOIN temp_tree tt ON d.parent_sid = tt.sid_id
	  JOIN doc_version dv ON d.doc_id = dv.doc_id -- All versions
	  JOIN doc_current dc ON d.doc_id = dc.doc_id -- get current version
	  LEFT JOIN doc_version dve ON d.doc_id = dv.doc_id -- Ever edited by
	  LEFT JOIN doc_version dvc -- created version
				 ON d.doc_id = dvc.doc_id
				AND dvc.version = 1
	  LEFT JOIN doc_version dvl -- Last modified version (current version)
				 ON d.doc_id = dvl.doc_id
				AND dc.doc_id = dvl.doc_id
	 WHERE(v_has_editor_filter = 0 OR dve.changed_by_sid IN (SELECT column_value FROM TABLE(t_editor_ids)))
	  AND (in_created_dtm IS NULL OR ((in_created_dir = 1 AND dvc.changed_dtm >= in_created_dtm) OR (in_created_dir != 1 AND dvc.changed_dtm <= in_created_dtm))) --created
	  AND (in_last_modified_dtm IS NULL OR ((in_last_modified_dir = 1 AND dvl.changed_dtm >= in_last_modified_dtm) OR (in_last_modified_dir != 1 AND dvl.changed_dtm <= in_last_modified_dtm))) --last edited
	  AND (in_filter_mime = 0 OR LOWER(d.mime_type) IN (SELECT mime_type FROM temp_mime_types));

	INSERT INTO temp_section_search_result
		(
		search_root,
		doc_id,
		doc_data_id,
		version_number,
		title,
		path,
		use_snippet,
		changed_by_sid,
		changed_dtm,
		result_type,
		mime_type,
		result_score
		)
	SELECT	SEARCH_ROOT_DOC_LIB,
			d.doc_id,
			d.doc_data_id,
			d.version, 
			d.filename,
			SUBSTR(td.path, 12), -- remove 'Documents/' at the beginning
			CASE WHEN d.description IS NOT NULL THEN 
					SNIPPET_ON_DESC
				ELSE
					SNIPPET_NONE
			 END,
			d.changed_by_sid,
			d.changed_dtm,
			SEARCH_RESULT_DOCUMENT,
			d.mime_type,
			SCORE(1) + SCORE(2) + (InstrCount(d.filename, in_contains_text) * SEARCH_INSTR_SCORE)
	  FROM v$doc_approved d
	  JOIN temp_doc_id_path td ON d.doc_id = td.doc_id
	 WHERE CONTAINS(d.data, in_contains_text, 1) > 0
	    OR CONTAINS(d.description, in_contains_text, 2) > 0
	    OR LOWER(d.filename) LIKE '%'||LOWER(v_like_text)||'%' ESCAPE '^';
END;

/* PROCEDURES */
PROCEDURE SearchSections(
	in_contains_text		IN	VARCHAR2,
	in_like_text			IN VARCHAR2,
	in_include_answers		IN	NUMBER,
	in_include_attachments	IN	NUMBER,
	in_include_documents	IN	NUMBER,
	in_module_ids			IN	security_pkg.T_SID_IDS,
	in_tag_ids				IN	security_pkg.T_SID_IDS,
	in_editor_ids			IN	security_pkg.T_SID_IDS,
	in_last_modified_dtm	IN	SECTION_VERSION.changed_dtm%TYPE,
	in_last_modified_dir	IN	NUMBER,
	in_created_dtm			IN	SECTION_VERSION.changed_dtm%TYPE,
	in_created_dir			IN	NUMBER,
	in_filter_mime			IN	NUMBER,
	in_min_rownum			IN NUMBER	DEFAULT 1,
	in_max_rownum			IN NUMBER	DEFAULT 50,
	out_result_count		OUT NUMBER,
	out_search_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur				OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_act_id				security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_app_sid				security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
	v_like_text				VARCHAR2(1000);
	v_section_sids			security_pkg.T_SID_IDS;
	v_module_root_sids		security_pkg.T_SID_IDS;
	t_module_root_sids		security.T_SID_TABLE;
	t_module_ids			security.T_SID_TABLE;
	t_tag_ids				security.T_SID_TABLE;
	t_editor_ids			security.T_SID_TABLE;
	v_has_module_filter		NUMBER DEFAULT 1;
	v_has_tag_filter		NUMBER DEFAULT 1;
	v_has_editor_filter		NUMBER DEFAULT 1;
BEGIN
	t_module_ids		:= security_pkg.SidArrayToTable(in_module_ids);
	t_tag_ids			:= security_pkg.SidArrayToTable(in_tag_ids);
	t_editor_ids		:= security_pkg.SidArrayToTable(in_editor_ids);
	v_like_text := REPLACE(in_like_text, '_', '^_');

	IF in_module_ids.COUNT = 0 OR (in_module_ids.COUNT = 1 AND in_module_ids(1) IS NULL) THEN
		v_has_module_filter := 0;
	END IF;
	IF in_tag_ids.COUNT = 0 OR (in_tag_ids.COUNT = 1 AND in_tag_ids(1) IS NULL) THEN
		v_has_tag_filter := 0;
	END IF;
	IF in_editor_ids.COUNT = 0 OR (in_editor_ids.COUNT = 1 AND in_editor_ids(1) IS NULL) THEN
		v_has_editor_filter := 0;
	END IF;

	-- Only return results for modules they have permission to read 
	SELECT module_root_sid
	  BULK COLLECT INTO v_module_root_sids
	  FROM section_module
	 WHERE security_pkg.SQL_IsAccessAllowedSID(v_act_id, module_root_sid, security.security_pkg.PERMISSION_READ) = 1
	   AND (v_has_module_filter = 0 OR module_root_sid IN (SELECT column_value FROM TABLE(t_module_ids)));

	t_module_root_sids	:= security_pkg.SidArrayToTable(v_module_root_sids);
	
	-- Run initial filter on sections before text search
	INSERT INTO temp_section_sid_filter (section_sid)
	SELECT DISTINCT s.section_sid
	  FROM section s
	  LEFT JOIN section_tag_member stm 
				 ON s.section_sid = stm.section_sid
				AND s.app_sid = stm.app_sid
	  LEFT JOIN section_version sv ON sv.section_sid = s.section_sid -- All versions
	  LEFT JOIN section_version sve ON sve.section_sid = s.section_sid -- Ever edited by
	  LEFT JOIN section_version svl -- Last modified version (current version)
				 ON svl.section_sid = sv.section_sid
				AND svl.version_number = s.visible_version_number
	  LEFT JOIN section_version svc -- created version
				 ON svc.section_sid = sv.section_sid
				AND svc.version_number = 1
	 WHERE s.module_root_sid IN (SELECT column_value FROM TABLE(t_module_root_sids))
	   AND (v_has_tag_filter = 0 OR stm.section_tag_id IN (SELECT column_value FROM TABLE(t_tag_ids)))
	   AND (v_has_editor_filter = 0 OR sve.changed_by_sid IN (SELECT column_value FROM TABLE(t_editor_ids)))
	   AND (in_last_modified_dtm IS NULL OR ((in_last_modified_dir = 1 AND svl.changed_dtm >= in_last_modified_dtm)
				OR (in_last_modified_dir != 1 AND svl.changed_dtm <= in_last_modified_dtm))) -- last modified
	   AND (in_created_dtm IS NULL OR ((in_created_dir = 1 AND svc.changed_dtm >= in_created_dtm)
				OR (in_created_dir != 1 AND svc.changed_dtm <= in_created_dtm))); --created
	
	-- can they see 'all' sections, or are they restricted to just routes they've been involved in?
	IF NOT csr.csr_data_pkg.CheckCapability('Search all sections') THEN
		DELETE FROM temp_section_sid_filter
		 WHERE section_sid NOT IN (
			-- anything they've been involved in or they've changed
			SELECT r.section_sid
			  FROM route r
			  JOIN route_step rs ON r.route_id = rs.route_id AND r.app_sid = rs.app_sid
			  JOIN route_step_user rsu ON rs.route_step_id = rsu.route_step_id AND rs.app_sid = rsu.app_sid AND rsu.csr_user_sid = SYS_CONTEXT('SECURITY','SID')
			  UNION
			SELECT section_sid
			  FROM section_version
			 WHERE changed_by_sid = SYS_CONTEXT('SECURITY','SID')
		 );
	END IF;

	-- Search on Sections
	INSERT INTO temp_section_search_result
		(
		search_root,
		section_sid,
		version_number,
		title,
		use_snippet,
		changed_by_sid,
		changed_dtm,
		result_type,
		result_score
		)
	SELECT	DISTINCT 
			SEARCH_ROOT_SECTION,
			sv.section_sid,
			sv.version_number,
			sv.title,
			CASE WHEN sv.body IS NULL OR LENGTH(sv.body)=0 THEN SNIPPET_NONE ELSE SNIPPET_ON_BODY END,
			sv.changed_by_sid,
			sv.changed_dtm,
			SEARCH_RESULT_SECTION,
			(SCORE(1) * SEARCH_WEIGHTING_TITLE) + (SCORE(2) * SEARCH_WEIGHTING_BODY) -- weight title match higher
	  FROM	section s
	  JOIN	section_version sv
				 ON s.section_sid = sv.section_sid 
				AND s.visible_version_number = sv.version_number 
				AND s.app_sid = sv.app_sid
	  JOIN	temp_section_sid_filter ts ON s.section_sid = ts.section_sid -- Join on pre-filtered sids
	 WHERE	(in_contains_text IS NULL 
					OR contains(sv.title, in_contains_text, 1) > 0
					OR in_include_answers = 1 AND 
						(
							(contains(sv.body, in_contains_text, 2) > 0) OR 
							(lower(sv.body) LIKE '%'||REPLACE(lower(trim(in_like_text)),' ','%')||'%')
						)
			)
	   AND	s.title_only = 0; -- excludes containers

	IF in_include_attachments = 1 THEN
		INSERT INTO temp_section_search_result
			(
			search_root,
			section_sid,
			doc_id,
			doc_data_id,
			attachment_id,
			version_number,
			title,
			use_snippet,
			result_type,
			changed_by_sid,
			changed_dtm,
			mime_type,
			result_score
			)
			SELECT	SEARCH_ROOT_SECTION,
					ah.section_sid,
					a.doc_id,
					dd.doc_data_id,
					ah.attachment_id,
					dv.version,
					a.filename,
					SNIPPET_NONE,
					SEARCH_RESULT_ATTACHMENT,
					dv.changed_by_sid,
					dv.changed_dtm,
					dd.mime_type,
					SCORE(1) + (InstrCount(a.filename, in_contains_text) * SEARCH_INSTR_SCORE)
			  FROM section s
			  JOIN temp_section_sid_filter ts ON s.section_sid = ts.section_sid -- Join on pre-filtered sids
			  JOIN section_version sv
						 ON s.section_sid = sv.section_sid
						AND sv.version_number = visible_version_number
			  JOIN attachment_history ah 
						 ON sv.section_sid = ah.section_sid
			  JOIN	attachment a ON ah.attachment_id = a.attachment_id
			  JOIN doc_current dc ON dc.doc_id = a.doc_id
			  JOIN doc_version dv 
						 ON dc.doc_id = dv.doc_id
						AND dc.version = dv.version
			  JOIN doc_data dd ON dv.doc_data_id = dd.doc_data_id
			 WHERE	(CONTAINS(dd.data, in_contains_text, 1) > 0 OR LOWER(a.filename) LIKE '%'||LOWER(v_like_text)||'%' ESCAPE '^')
			   AND	(in_filter_mime = 0 OR LOWER(dd.mime_type) IN (SELECT mime_type FROM temp_mime_types));
	END IF;

	-- search content_docs and doc library
	IF in_include_documents = 1 THEN

		INTERNAL_compileDocLibSearch
		(
			in_contains_text		=> in_contains_text,
			in_like_text			=> in_like_text,
			in_editor_ids			=> in_editor_ids,
			in_last_modified_dtm	=> in_last_modified_dtm,
			in_last_modified_dir	=> in_last_modified_dir,
			in_created_dtm			=> in_created_dtm,
			in_created_dir			=> in_created_dir,
			in_filter_mime			=> in_filter_mime
		);

		-- filter Corporate reporter documents on editor, created and last updated AND section module and tags
		INSERT INTO temp_doc_id
		SELECT DISTINCT dv.doc_id
		  FROM section s
		  LEFT JOIN section_tag_member stm 
					 ON s.section_sid = stm.section_sid
					AND s.app_sid = stm.app_sid
		  JOIN section_content_doc scd 
					ON scd.section_sid = s.section_sid
					AND scd.app_sid = s.app_sid
		  JOIN doc_version dv ON scd.doc_id = dv.doc_id -- All versions
		  JOIN doc_current dc ON scd.doc_id = dc.doc_id -- get current version
		  LEFT JOIN doc_version dve ON scd.doc_id = dv.doc_id -- Ever edited by
		  LEFT JOIN doc_version dvc -- created version
					 ON scd.doc_id = dvc.doc_id
					AND dvc.version = 1
		  LEFT JOIN doc_version dvl -- Last modified version (current version)
					 ON scd.doc_id = dvl.doc_id
					AND dc.doc_id = dvl.doc_id
		 WHERE s.module_root_sid IN (SELECT column_value FROM TABLE(t_module_root_sids)) -- is in a module they can read
		  AND (v_has_tag_filter = 0 OR stm.section_tag_id IN (SELECT column_value FROM TABLE(t_tag_ids)))
		  AND (v_has_editor_filter = 0 OR dve.changed_by_sid IN (SELECT column_value FROM TABLE(t_editor_ids)))
		  AND (in_created_dtm IS NULL OR ((in_created_dir = 1 AND dvc.changed_dtm >= in_created_dtm) OR (in_created_dir != 1 AND dvc.changed_dtm <= in_created_dtm))) --created
		  AND (in_last_modified_dtm IS NULL OR ((in_last_modified_dir = 1 AND dvl.changed_dtm >= in_last_modified_dtm) OR (in_last_modified_dir != 1 AND dvl.changed_dtm <= in_last_modified_dtm))); --last edited

		INSERT INTO temp_section_search_result
			(
			search_root,
			section_sid,
			doc_id,
			doc_data_id,
			version_number,
			title,
			use_snippet,
			changed_by_sid,
			changed_dtm,
			result_type,
			mime_type,
			result_score
			)
			SELECT	SEARCH_ROOT_SECTION,
					sv.section_sid,
					d.doc_id,
					d.doc_data_id,
					d.version,
					d.filename,
					CASE WHEN d.description IS NOT NULL THEN -- Only make snippets on descriptions when not null
							SNIPPET_ON_DESC
						ELSE
							SNIPPET_NONE
					END,
					d.changed_by_sid, 
					d.changed_dtm,
					SEARCH_RESULT_DOCUMENT,
					d.mime_type,
					SCORE(1) + SCORE(2) + (InstrCount(d.filename, in_contains_text) * SEARCH_INSTR_SCORE)
			  FROM	section_content_doc scd
			  JOIN temp_doc_id td ON td.doc_id = scd.doc_id
			  JOIN	section s ON s.section_sid = scd.section_sid
			  JOIN	section_version sv
						 ON s.section_sid = sv.section_sid 
						AND s.visible_version_number = sv.version_number 
						AND s.app_sid = sv.app_sid
			  JOIN	v$doc_approved d on scd.doc_id = d.doc_id
			 WHERE (
						CONTAINS(d.data, in_contains_text, 1) > 0 
						OR LOWER(d.filename) LIKE '%'||LOWER(v_like_text)||'%' ESCAPE '^'
						OR CONTAINS(d.description, in_contains_text, 2) > 0
					)
			   AND (in_filter_mime = 0 OR LOWER(d.mime_type) IN (SELECT mime_type FROM temp_mime_types));
		
		-- REMOVE DUPLICATE DOCUMENTS FROM SEARCH RESULTS GIVING PREFERENCE TO SECTION DOCS
		DELETE FROM temp_section_search_result
		 WHERE doc_id IN (
					SELECT doc_id 
					  FROM (
							SELECT doc_id, count(doc_id) doc_count
							  FROM temp_section_search_result
							 GROUP BY doc_id)
					WHERE doc_count > 1
				)
		   AND section_sid IS NULL
		   AND result_type = SEARCH_RESULT_DOCUMENT;
	END IF;

	SELECT COUNT(*) INTO out_result_count FROM temp_section_search_result;

	internal_WeightRecent;

	-- Call oracle text functions for snippets and highlighed text on final returned results only 
	OPEN out_search_cur FOR
		SELECT r.rn row_number,
				r.search_root,
				r.result_type,
				r.section_sid,
				r.doc_id,
				r.version_number,
				CASE 
					WHEN r.result_type = SEARCH_RESULT_SECTION THEN
						GetMarkupTitle(v_app_sid, r.section_sid, r.version_number, in_contains_text)
					ELSE r.title
				END title,
				CASE
					WHEN r.search_root = SEARCH_ROOT_SECTION THEN
						section_pkg.GetModuleName(r.section_sid)
					WHEN r.search_root = SEARCH_ROOT_DOC_LIB THEN
						'Document library'
				END module_name,
				CASE
					WHEN r.search_root = SEARCH_ROOT_SECTION AND (r.result_type = SEARCH_RESULT_ATTACHMENT OR r.result_type = SEARCH_RESULT_DOCUMENT) THEN
						section_pkg.GetPathFromSectionSID(v_act_id, r.section_sid, ' / ', 0) -- include section title
					WHEN r.search_root = SEARCH_ROOT_SECTION THEN
						section_pkg.GetPathFromSectionSID(v_act_id, r.section_sid, ' / ', 1)
					WHEN r.search_root = SEARCH_ROOT_DOC_LIB THEN
						r.path
				END path,
				CASE
				  WHEN r.result_type = SEARCH_RESULT_SECTION AND r.use_snippet = SNIPPET_ON_BODY THEN
						GetSectionSnippet(v_app_sid, r.section_sid, r.version_number, in_contains_text)
				  WHEN r.doc_id IS NOT NULL AND r.use_snippet = SNIPPET_ON_DESC THEN
						GetDocDescSnippet(v_app_sid, r.doc_id, r.version_number, in_contains_text)
--				  WHEN r.doc_id IS NOT NULL AND r.use_snippet = SNIPPET_ON_BODY THEN -- TOO SLOW
--						GetDocDataSnippet(v_app_sid, r.doc_data_id, in_contains_text)
				  ELSE ''
				END snippet,
				r.changed_by_sid,
				cu.full_name changed_by_name,
				r.changed_dtm,
				mime_type
		  FROM (
					SELECT ROWNUM rn, o.*
					  FROM (
							SELECT search_root,
									result_type,
									section_sid,
									doc_id,
									doc_data_id,
									version_number,
									title,
									use_snippet,
									path,
									changed_by_sid,
									changed_dtm,
									mime_type
							  FROM temp_section_search_result
							 ORDER BY result_score DESC
							) o
				) r,
				csr_user cu
		 WHERE cu.csr_user_sid (+)= r.changed_by_sid
		   AND r.rn >= in_min_rownum
		   AND r.rn <= in_max_rownum
		 ORDER BY r.rn;

	-- Get tags for sections returned above.
	SELECT DISTINCT section_sid
	  BULK COLLECT INTO v_section_sids
	  FROM temp_section_search_result
	 WHERE result_type = SEARCH_RESULT_SECTION;

	section_pkg.GetSectionsTags(v_section_sids, out_tag_cur);
END;

PROCEDURE SearchDocumentLib(
	in_contains_text		IN	VARCHAR2,
	in_like_text			IN VARCHAR2,
	in_editor_ids			IN	security_pkg.T_SID_IDS,
	in_last_modified_dtm	IN	SECTION_VERSION.changed_dtm%TYPE,
	in_last_modified_dir	IN	NUMBER,
	in_created_dtm			IN	SECTION_VERSION.changed_dtm%TYPE,
	in_created_dir			IN	NUMBER,
	in_filter_mime			IN	NUMBER,
	in_min_rownum			IN NUMBER	DEFAULT 1,
	in_max_rownum			IN NUMBER	DEFAULT 50,
	out_result_count		OUT NUMBER,
	out_cur					OUT	SYS_REFCURSOR
)
AS
	v_app_sid	security_pkg.T_SID_ID := SYS_CONTEXT('SECURITY', 'APP');
BEGIN
	INTERNAL_compileDocLibSearch
		(
			in_contains_text		=> in_contains_text,
			in_like_text			=> in_like_text,
			in_editor_ids			=> in_editor_ids,
			in_last_modified_dtm	=> in_last_modified_dtm,
			in_last_modified_dir	=> in_last_modified_dir,
			in_created_dtm			=> in_created_dtm,
			in_created_dir			=> in_created_dir,
			in_filter_mime			=> in_filter_mime
		);

	SELECT COUNT(doc_id) INTO out_result_count FROM temp_section_search_result;

	internal_WeightRecent;

	OPEN out_cur FOR
		SELECT r.search_root,
				r.result_type,
				r.doc_id,
				r.version_number,
				r.title,
				r.path,
				CASE
				  WHEN r.doc_id IS NOT NULL AND r.use_snippet = SNIPPET_ON_DESC THEN
						GetDocDescSnippet(v_app_sid, r.doc_id, r.version_number, in_contains_text)
--				  WHEN r.doc_id IS NOT NULL AND r.use_snippet = SNIPPET_ON_BODY THEN -- Too slow
--						GetDocDataSnippet(v_app_sid, r.doc_data_id, in_contains_text)
				  ELSE ''
				END snippet,
				r.changed_by_sid,
				cu.full_name changed_by_name,
				r.changed_dtm,
				r.mime_type
		  FROM 
				(
				SELECT ROWNUM rn, o.*
				  FROM (
						SELECT	search_root,
								result_type,
								doc_id,
								doc_data_id,
								version_number,
								title,
								path,
								use_snippet,
								changed_by_sid,
								changed_dtm,
								mime_type
						  FROM temp_section_search_result
						 ORDER BY result_score DESC
						)o
				) r,
				csr_user cu
		 WHERE r.rn >= in_min_rownum
		   AND r.rn <= in_max_rownum
		   AND r.changed_by_sid = cu.csr_user_sid;
END;

PROCEDURE GetSectionMarkUp(
	in_section_sid			IN security_pkg.T_SID_ID,
	in_highlight			IN VARCHAR2,
	out_section_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_tag_cur				OUT security_pkg.T_OUTPUT_CUR,
	out_attachment_cur		OUT security_pkg.T_OUTPUT_CUR,
	out_content_docs_cur	OUT security_pkg.T_OUTPUT_CUR,
	out_plugins_cur			OUT security_pkg.T_OUTPUT_CUR,
	out_paths_cur			OUT security_pkg.T_OUTPUT_CUR
)
AS
	v_section_sids		security_pkg.T_SID_IDS;
	v_act				security_pkg.T_ACT_ID := SYS_CONTEXT('SECURITY', 'ACT');
	v_module_root_sid	security_pkg.T_SID_ID;
	v_can_edit			NUMBER(1);
BEGIN
	SELECT in_section_sid
	  BULK COLLECT INTO v_section_sids
	  FROM DUAL;

	SELECT module_root_sid INTO v_module_root_sid
	  FROM section
	 WHERE section_sid = in_section_sid;

	IF security_pkg.IsAccessAllowedSID(v_act, v_module_root_sid, csr_data_pkg.PERMISSION_EDIT_SECTION_MODULE) THEN
		v_can_edit := 1;
	ELSE
		v_can_edit := 0;
	END IF;

	OPEN out_section_cur FOR
		SELECT	s.section_sid,
				s.parent_sid,
				sv.version_number version,
				s.title_only,
				GetMarkupTitle(sv.app_sid, sv.section_sid, sv.version_number, in_highlight) title,
				s.help_text,
				LENGTH(sv.body) body_length,
				CASE
					WHEN sv.body IS NOT NULL AND s.plugin IS NULL THEN -- don't markup section if a plugin is used, it might break it
						GetMarkupBody(sv.app_sid, sv.section_sid, sv.version_number, in_highlight) 
					ELSE sv.body 
				END body,
				section_pkg.GetModuleName(s.section_sid) module_name,
				CASE
					WHEN s.checked_out_to_sid IS NOT NULL THEN 1
					ELSE 0
				END is_locked,
				s.section_status_sid,
				s.checked_out_to_sid,
				sv.changed_by_sid,
				cu.full_name changed_by_name,
				cu.email changed_by_email,
				sv.changed_dtm,
				s.plugin,
				s.plugin_config,
				v_can_edit can_edit
		  FROM	section s
		  JOIN	section_version sv
					 ON s.section_sid = sv.section_sid 
					AND s.visible_version_number = sv.version_number 
					AND s.app_sid = sv.app_sid
		  LEFT JOIN csr_user cu ON sv.changed_by_sid = cu.csr_user_sid
		 WHERE	s.section_sid = in_section_sid;

	section_pkg.GetSectionsTags(v_section_sids, out_tag_cur);
	section_pkg.GetAttachments(v_section_sids, out_attachment_cur);
	section_pkg.GetContentDocs(v_section_sids, out_content_docs_cur);
	section_pkg.GetFormPlugins(v_section_sids, out_plugins_cur);
	section_pkg.GetSectionsPaths(v_section_sids, out_paths_cur);
END;

END section_search_Pkg;
/
