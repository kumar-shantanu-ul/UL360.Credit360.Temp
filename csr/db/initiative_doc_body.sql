CREATE OR REPLACE PACKAGE BODY CSR.initiative_doc_pkg
IS

PROCEDURE GetDocFolders(
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT df.project_sid, df.name, df.label, df.info_text
		  FROM initiative_project p, project_doc_folder df
		 WHERE p.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND security_pkg.SQL_IsAccessAllowedSid(SYS_CONTEXT('SECURITY', 'ACT'), p.project_sid, security_pkg.PERMISSION_READ) = 1
		   AND df.app_sid = SYS_CONTEXT('SECURITY', 'APP')
		   AND df.project_sid = p.project_sid
		;
END;

PROCEDURE INTERNAL_EnsureFolder(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_folder_name			IN	project_doc_folder.name%TYPE,
	out_folder_sid			OUT	security_pkg.T_SID_ID
)
AS
	v_doc_lib_sid			security_pkg.T_SID_ID;
	v_doc_sid				security_pkg.T_SID_ID;
BEGIN
	
	-- Check for the document library
	SELECT doc_library_sid
	  INTO v_doc_lib_sid
	  FROM initiative
	 WHERE app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND initiative_sid = in_initiative_sid;
	
	-- create if required
	IF v_doc_lib_sid IS NULL THEN
		initiative_pkg.CreateDocLib(
			in_initiative_sid,
			v_doc_lib_sid
		);
	END IF;
	
	BEGIN
		-- Use the library's 'Documents' node
		SELECT DISTINCT documents_sid
		  INTO v_doc_sid
		  FROM v$doc_folder_root
		 WHERE doc_library_sid = v_doc_lib_sid;
		
		--Folders are system managed so any lang should be fine.
		SELECT MIN(doc_folder_sid)
		  INTO out_folder_sid
		  FROM doc_folder_name_translation
		 WHERE translated = in_folder_name
		   AND parent_sid = v_doc_sid;
		
		--Min stops NO_DATA_FOUND so throw manually
		IF out_folder_sid IS NULL THEN
			RAISE NO_DATA_FOUND;
		END IF;
		
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			-- Create sub-folder if required
			doc_folder_pkg.CreateFolder(
				in_parent_sid => v_doc_sid, 
				in_name => in_folder_name, 
				out_sid_id => out_folder_sid
			);
	END;
END;

-- private
PROCEDURE GetFolder(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_folder_sid			OUT	security_pkg.T_SID_ID,
	out_folder_name			OUT	project_doc_folder.name%TYPE
)
AS
	v_doc_sid				security_pkg.T_SID_ID;
BEGIN
	SELECT df.name
	  INTO out_folder_name
	  FROM project_doc_folder df, initiative i
	 WHERE i.initiative_sid = in_initiative_sid
	   AND df.project_sid = i.project_sid;

	SELECT DISTINCT r.documents_sid
	  INTO v_doc_sid
	  FROM initiative i, v$doc_folder_root r
	 WHERE i.app_sid = SYS_CONTEXT('SECURITY', 'APP')
	   AND i.initiative_sid = in_initiative_sid
	   AND r.doc_library_sid = i.doc_library_sid;
	
	--Folders are system managed so any lang should be fine.
	SELECT MIN(doc_folder_sid)
	  INTO out_folder_sid
	  FROM doc_folder_name_translation
	 WHERE translated = out_folder_name
	   AND parent_sid = v_doc_sid;
	   
	--Min stops NO_DATA_FOUND so throw manually
	IF out_folder_sid IS NULL THEN
		RAISE NO_DATA_FOUND;
	END IF;
END;

PROCEDURE GetDocsForInitiative(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	out_cur					OUT	security_pkg.T_OUTPUT_CUR
)
AS
	v_folder_sid			security_pkg.T_SID_ID;
	v_folder_name			project_doc_folder.name%TYPE;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_initiative_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied trying to read initiative with sid ' || in_initiative_sid);
	END IF;

	BEGIN
		GetFolder(
			in_initiative_sid => in_initiative_sid,
			out_folder_sid => v_folder_sid,
			out_folder_name => v_folder_name
		);
		
		IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, v_folder_sid, security_pkg.PERMISSION_LIST_CONTENTS) THEN
			RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied getting the contents of the document folder with sid '||v_folder_sid);
		END IF;
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			NULL; -- This just means there's no project folder defined (no file uploads enabled)
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			NULL; -- This just means the folder  rhas not been created (no files uploaded for this initiative yet)
	END;

	OPEN out_cur FOR
		SELECT d.parent_sid folder_sid,  v_folder_name folder_name, d.doc_id, d.mime_type, d.filename
		  FROM v$doc_current_status d
		 WHERE d.parent_sid = v_folder_sid;
END;

PROCEDURE InsertDocFromCache(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_folder_name			IN	project_doc_folder.name%TYPE,
	out_doc_id				OUT	doc.doc_id%TYPE
)
AS
	v_folder_sid			security_pkg.T_SID_ID;
BEGIN
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_initiative_sid, security_pkg.PERMISSION_WRITE) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Access denied writing initiative with SID ' || in_initiative_sid);
	END IF;

	-- Ensure folder exists (and get the sid)
	INTERNAL_EnsureFolder(
		in_initiative_sid,
		in_folder_name,
		v_folder_sid
	);

	--security_pkg.DebugMsg('InsertDocFromCache');
	
	FOR r IN (
		SELECT filename, mime_type, object
		  FROM aspen2.filecache 
		 WHERE cache_key = in_cache_key
	) LOOP
		--security_pkg.DebugMsg('Save: '||r.filename);
		doc_pkg.SaveDoc(
			in_doc_id				=> NULL,
			in_parent_sid			=> v_folder_sid,
			in_filename				=> r.filename,
			in_mime_type			=> r.mime_type,
			in_data					=> r.object,
			in_description			=> 'Created by initiative',
			in_change_description	=> 'Created by initiative',
			out_doc_id				=> out_doc_id
		);
		
		-- Audit the change
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Document {0} added',
			r.filename
		);
	END LOOP;
END;

PROCEDURE DeleteAbsentDocs(
	in_initiative_sid		IN	security_pkg.T_SID_ID,
	in_doc_ids				IN	security_pkg.T_SID_IDS
)
AS
	v_folder_sid			security_pkg.T_SID_ID;
	v_folder_name			project_doc_folder.name%TYPE;
	t_doc_ids				security.T_SID_TABLE;
BEGIN
	BEGIN
		GetFolder(
			in_initiative_sid => in_initiative_sid,
			out_folder_sid => v_folder_sid,
			out_folder_name => v_folder_name
		);
	EXCEPTION
		WHEN NO_DATA_FOUND THEN
			RETURN; -- NOTHING TO DO
		WHEN security_pkg.OBJECT_NOT_FOUND THEN
			RETURN; -- NOTHING TO DO
	END;

	t_doc_ids := security_pkg.SidArrayToTable(in_doc_ids);

	FOR r IN (
		SELECT x.doc_id, d.filename
		  FROM v$doc_current_status d, (
			SELECT d.doc_id
			  FROM v$doc_current_status d
			 WHERE d.parent_sid = v_folder_sid
			MINUS
			SELECT column_value doc_id
			  FROM TABLE(t_doc_ids)
		 ) x
		 WHERE d.doc_id = x.doc_id
	) LOOP
		-- Trash the document
		doc_pkg.DeleteDoc(
			r.doc_id, 
			'Deleted by initiative'
		);
		
		-- Audit the change
		csr_data_pkg.WriteAuditLogEntry(
			security_pkg.GetACT,
			csr_data_pkg.AUDIT_TYPE_INITIATIVE,
			security_pkg.GetAPP,
			in_initiative_sid,
			'Document {0} deleted',
			r.filename
		);
	END LOOP;
END;

END initiative_doc_pkg;
/
