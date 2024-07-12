CREATE OR REPLACE PACKAGE BODY SUPPLIER.document_pkg
IS

PROCEDURE CreateDocumentGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	out_group_id			OUT	document_group.document_group_id%TYPE
)
AS 
BEGIN
	SELECT document_group_id_seq.nextval 
	  INTO out_group_id 
	  FROM DUAL;

	INSERT INTO document_group
		(document_group_id)
		VALUES (out_group_id);
END;

PROCEDURE CopyDocumentsToNewGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_source_group_id		IN	document_group.document_group_id%TYPE,
	in_dest_group_id		IN  document_group.document_group_id%TYPE
)
AS 
BEGIN
	
	FOR r IN (
			SELECT document_id_seq.nextval document_id, title, description, file_name, mime_type, data, start_dtm, end_dtm FROM document d, document_group_member dgm
		    	WHERE d.document_id = dgm.document_id 
		    	AND dgm.document_group_id = in_source_group_id
		    )
	LOOP
		
		INSERT INTO document (document_id, title, description, file_name, mime_type, data, start_dtm, end_dtm)
			VALUES (r.document_id, r.title, r.description, r.file_name, r.mime_type, r.data, r.start_dtm, r.end_dtm);
			
		INSERT INTO document_group_member (document_id, document_group_id) VALUES (r.document_id, in_dest_group_id); -- will fail if new group doesn;t exist
		
	END LOOP;
	
END;

-- use this when coying parts beteeen products as means the save mech is the same 
-- and we can use the same mech for letting people view documents before they are saved
PROCEDURE CopyDocumentsToFilecache(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	out_cache_key			OUT aspen2.filecache.cache_key%TYPE
) 
AS 
BEGIN

	out_cache_key := SYS_GUID||'_copy_sustainable_sourcing_questionnaire';
	
	INSERT INTO aspen2.filecache (cache_key, filename, description, mime_type, object)
		SELECT out_cache_key, file_name, description, mime_type, data
		  FROM document 
		  WHERE document_id = in_document_id;
		  
END;

PROCEDURE CreateDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_group_id				IN	document_group.document_group_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_title				IN	document.title%TYPE,
	in_description			IN	document.description%TYPE,
	in_file_name			IN	document.file_name%TYPE,
	in_mime_type			IN	document.mime_type%TYPE,
	in_start_dtm			IN	document.start_dtm%TYPE,
	in_end_dtm				IN	document.end_dtm%TYPE,
	out_document_id			OUT	document.document_id%TYPE
)
AS
BEGIN
	SELECT document_id_seq.nextval 
	  INTO out_document_id 
	  FROM DUAL;

	INSERT INTO document
		(document_id, title, description, file_name, mime_type, start_dtm, end_dtm, data)
		SELECT out_document_id, in_title, in_description, in_file_name, in_mime_type, in_start_dtm, in_end_dtm, object
		  FROM aspen2.filecache 
		 WHERE cache_key = in_cache_key;
		 
	INSERT INTO document_group_member
		(document_id, document_group_id)
		VALUES (out_document_id, in_group_id);
END;

PROCEDURE UpdateDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	in_group_id				IN	document_group.document_group_id%TYPE,
	in_cache_key			IN	aspen2.filecache.cache_key%TYPE,
	in_title				IN	document.title%TYPE,
	in_description			IN	document.description%TYPE,
	in_file_name			IN	document.file_name%TYPE,
	in_mime_type			IN	document.mime_type%TYPE,
	in_start_dtm			IN	document.start_dtm%TYPE,
	in_end_dtm				IN	document.end_dtm%TYPE
)
AS
	v_data					aspen2.filecache.object%TYPE;
BEGIN

	SELECT object 
	  INTO v_data
	  FROM aspen2.filecache
	 WHERE cache_key = in_cache_key;

	UPDATE document
	   SET title = in_title, 
	   	   description = in_description, 
	   	   file_name = in_file_name, 
	   	   mime_type = in_mime_type, 
	   	   start_dtm = in_start_dtm, 
	   	   end_dtm = in_end_dtm, 
	   	   data = v_data
	WHERE document_id = in_document_id;
END;

PROCEDURE DeleteDocumentGroup(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_group_id	IN	document.document_id%TYPE
)
AS
BEGIN
	
	-- TO DO I'm not sure the constraints on the DG table are the best - 
	-- I think they should be document has an FK on document_id in document_group_member NOT document_group_member as an FK on document_id in document as currently can't delete a group by deleting docs, then dgm, then group
	FOR r IN (SELECT document_id FROM document_group_member WHERE document_group_id = in_document_group_id)
	LOOP
		-- one row at a time
		DeleteDocument(in_act_id, r.document_id);
	END LOOP;
	
	DELETE FROM document_group
	 WHERE document_group_id = in_document_group_id;
END;

PROCEDURE DeleteDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE
)
AS
BEGIN
	DELETE FROM document_group_member
	 WHERE document_id = in_document_id;
	
	DELETE FROM document
	 WHERE document_id = in_document_id;
END;


PROCEDURE DeleteAbsentDocs(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_group_id				IN document_group.document_group_id%TYPE,
	in_doc_ids				IN T_DOCUMENT_IDS
)
AS
	v_current_ids			T_DOCUMENT_IDS;
	v_idx					NUMBER;
BEGIN
	-- The in_doc_ids "array" contains all the part id's that 
	-- we want to keep, for this product - we want to Delete the rest.
	
	-- Get current ids
	FOR r IN (
		SELECT d.document_id
		  FROM document d, document_group_member m
		 WHERE d.document_id = m.document_id
		   AND m.document_group_id = in_group_id
	) LOOP
		v_current_ids(r.document_id) := r.document_id;
	END LOOP;
	
	-- Remove any part ids present in the input array
	IF in_doc_ids(1) IS NOT NULL THEN
		FOR i IN in_doc_ids.FIRST .. in_doc_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_doc_ids(i)) THEN
				v_current_ids.DELETE(in_doc_ids(i));
			END IF;
		END LOOP;
	END IF;
		
	-- Delete any ids remaining	
	IF v_current_ids.COUNT > 0 THEN -- can't use FIRST ... LAST as sparse array 
		  v_idx := v_current_ids.FIRST;
		  WHILE (v_idx IS NOT NULL) 
		  LOOP		
			DeleteDocument(in_act_id, v_current_ids(v_idx));
			v_idx := v_current_ids.NEXT(v_idx);
		END LOOP;
	END IF;
	
END;

PROCEDURE GetDocument(
	in_act_id				IN	security_pkg.T_ACT_ID,
	in_document_id			IN	document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT document_id, title, description, file_name, mime_type, start_dtm, end_dtm, data
		  FROM document
		 WHERE document_id = in_document_id;
END;

PROCEDURE GetDocumentList(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_group_id			IN document_group.document_group_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT d.document_id, d.title, d.description, d.file_name, d.mime_type, d.start_dtm, d.end_dtm
		  FROM document d, document_group_member gm
		 WHERE d.document_id = gm.document_id
		   AND gm.document_group_id = in_doc_group_id;
END;

PROCEDURE GetDocumentData(
	in_act_id				IN security_pkg.T_ACT_ID,
	in_doc_id				IN document.document_id%TYPE,
	out_cur 				OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT document_id, title, description, file_name, mime_type, start_dtm, end_dtm, data
		  FROM document
		 WHERE document_id = in_doc_id;
END;

END document_pkg;
/
