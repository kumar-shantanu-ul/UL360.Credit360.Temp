CREATE OR REPLACE PACKAGE BODY CSR.procedures_pkg IS

PROCEDURE GetDocsForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for region sid '||in_region_sid);
	END IF;
 
 	OPEN out_cur FOR
 		SELECT dv.doc_id, dv.filename file_name, dv.description, 
 			dv.changed_dtm, dv.change_description, dv.version, rpd.inherited
 		  FROM doc_version dv, doc_current dc, region_proc_doc rpd
 		 WHERE dv.version = dc.version
 		   AND dv.doc_id = rpd.doc_id
 		   AND dc.doc_id = rpd.doc_id
 		   AND rpd.region_sid = in_region_sid;
END;

PROCEDURE SetDocsForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_doc_ids		IN	security_pkg.T_SID_IDS
)AS
	v_current_ids security_pkg.T_SID_IDS;
	v_insert_ids security_pkg.T_SID_IDS;
BEGIN
	
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied altering region with sid '||in_region_sid);
	END IF;
 
	
	-- Deal with 'empty' array
	IF in_doc_ids.COUNT = 1 AND in_doc_ids(1) IS NULL THEN
		-- Empty array
		-- Delete (only inherited) entries for children
		FOR rec IN (
			SELECT doc_id
			  FROM region_proc_doc
		 	 WHERE region_sid = in_region_sid
		 	   AND inherited = 0
		) LOOP
			DELETE FROM region_proc_doc
			 WHERE doc_id = rec.doc_id
			   AND inherited <> 0
			   AND region_sid IN (
			 	SELECT r.region_sid
			 	  FROM region r
			 	  	START WITH r.parent_sid = in_region_sid
			 	  	CONNECT BY PRIOR r.region_sid = r.parent_sid
			 );
		END LOOP;
		-- Delete entry for top-level region
		DELETE FROM region_proc_doc
		 WHERE region_sid = in_region_sid
		   AND inherited = 0;
		RETURN;
	END IF;

	-- Fetch existing top-level entries
	FOR r IN (
		SELECT doc_id
		  FROM region_proc_doc
		 WHERE region_sid = in_region_sid
		   AND inherited = 0
	)
	LOOP
		v_current_ids(r.doc_id) := r.doc_id;
	END LOOP;

	-- go through each ID that we want to set
	FOR i IN in_doc_ids.FIRST .. in_doc_ids.LAST
	LOOP
		IF v_current_ids.EXISTS(in_doc_ids(i)) THEN
			-- remove from current_ids so we don't try to delete
			v_current_ids.DELETE(in_doc_ids(i));
		ELSE
			-- mark for insertion
			v_insert_ids(v_insert_ids.COUNT) := in_doc_ids(i);
		END IF;
	END LOOP;

	-- delete what we don't want
	-- Note: we delete anything with the doc_id we are interested 
	-- in but it is possible that a child is associated directly 
	-- with the same document, in that case this will remove that 
	-- association. 
	-- TODO: We need to stop descending that branch when we hit 
	-- a document with the same ID that is not inherited
	FORALL i IN INDICES OF v_current_ids
		DELETE FROM region_proc_doc
		 WHERE doc_id = v_current_ids(i)
		   AND region_sid IN (
		   		SELECT region_sid
		   		  FROM region
		   		 	START WITH region_sid = in_region_sid
		   		 	CONNECT BY PRIOR region_sid = parent_sid
		);
		
	-- Insert the new documents
	-- Get numeric error if array is empty hence wrapping in COUNT > 0 check.
	-- We have a horrible nested loop here to ensure that documents are always added, 
	-- even if a document with the same ID has already been added some way down the tree.
	-- If we tried to insert in one go then this could cause a promary key violation and 
	-- roll back the entite insert statement.
	IF v_insert_ids.COUNT > 0 THEN
		FOR i IN v_insert_ids.FIRST .. v_insert_ids.LAST
		LOOP
			FOR r IN (
				SELECT r.region_sid, v_insert_ids(i) doc_id, 
					DECODE(r.region_sid, in_region_sid, 0, 1) inherited
				  FROM region r
				  	START WITH r.region_sid = in_region_sid
				  	CONNECT BY PRIOR r.region_sid = parent_sid
				 ) LOOP
				 	BEGIN
						INSERT INTO region_proc_doc
						  	(region_sid, doc_id, inherited)
						VALUES
							(r.region_sid, r.doc_id, r.inherited);
					EXCEPTION 
						WHEN DUP_VAL_ON_INDEX THEN
							NULL;
					END;
				END LOOP;
		END LOOP;
	END IF;			  

END;

PROCEDURE GetFilesForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	out_cur			OUT	security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
		-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied for region sid '||in_region_sid);
	END IF;
 
 	OPEN out_cur FOR
		SELECT d.meter_document_id, d.file_name, d.mime_type, f.inherited
		  FROM meter_document d, region_proc_file f
		 WHERE f.region_sid = in_region_sid
		   AND d.meter_document_id = f.meter_document_id;
END;

PROCEDURE SetFilesForRegion (
	in_region_sid	IN	security_pkg.T_SID_ID,
	in_file_ids		IN	security_pkg.T_SID_IDS,
	in_cache_keys	IN	T_CACHE_KEYS
)
AS
	v_file_id 		meter_document.meter_document_id%TYPE;
	v_current_ids 	security_pkg.T_SID_IDS;
	v_insert_ids 	security_pkg.T_SID_IDS;
BEGIN
	-- check for permissions on region sid
	IF NOT security_pkg.IsAccessAllowedSID(security_pkg.GetACT, in_region_sid, security_pkg.PERMISSION_READ) THEN
		RAISE_APPLICATION_ERROR(security_pkg.ERR_ACCESS_DENIED, 'Read access denied altering region with sid '||in_region_sid);
	END IF;
 
	-- Deal with 'empty' array
	IF in_file_ids.COUNT = 1 AND in_file_ids(1) IS NULL THEN
		-- Empty array
		-- Delete (only inherited) entries for children
		FOR rec IN (
			SELECT meter_document_id
			  FROM region_proc_file
			 WHERE region_sid = in_region_sid
			   AND inherited = 0
		) LOOP
			DELETE FROM region_proc_file
			 WHERE meter_document_id = rec.meter_document_id
			   AND inherited <> 0
			   AND region_sid IN (
			 	SELECT r.region_sid
			 	  FROM region r
			 	  	START WITH r.parent_sid = in_region_sid
			 	  	CONNECT BY PRIOR r.region_sid = r.parent_sid
			 );
		END LOOP;
		 -- Delete entry for top-level region
		DELETE FROM region_proc_file
		 WHERE region_sid = in_region_sid
		   AND inherited = 0;
	ELSE
		-- Fetch existing top-level entries
		FOR r IN (
			SELECT meter_document_id
			  FROM region_proc_file
			 WHERE region_sid = in_region_sid
			   AND inherited = 0
		)
		LOOP
			v_current_ids(r.meter_document_id) := r.meter_document_id;
		END LOOP;
	
		-- go through each ID that we want to set
		FOR i IN in_file_ids.FIRST .. in_file_ids.LAST
		LOOP
			IF v_current_ids.EXISTS(in_file_ids(i)) THEN
				-- remove from current_ids so we don't try to delete
				v_current_ids.DELETE(in_file_ids(i));
			ELSE
				-- mark for insertion
				v_insert_ids(v_insert_ids.COUNT) := in_file_ids(i);
			END IF;
		END LOOP;
	
		-- delete what we don't want
		-- Note: we delete anything with the meter_document_id we are interested 
		-- in but it is possible that a child is associated directly 
		-- with the same fileument, in that case this will remove that 
		-- association. 
		-- TODO: We need to stop descending that branch when we hit 
		-- a fileument with the same ID that is not inherited
		FORALL i IN INDICES OF v_current_ids
			DELETE FROM region_proc_file
			 WHERE meter_document_id = v_current_ids(i)
			   AND region_sid IN (
			   		SELECT region_sid
			   		  FROM region
			   		 	START WITH region_sid = in_region_sid
			   		 	CONNECT BY PRIOR parent_sid = region_sid
			);
	
		-- insert the new files
		FORALL i IN INDICES OF v_insert_ids
			INSERT INTO region_proc_file
			  (region_sid, meter_document_id, inherited)
				SELECT r.region_sid, v_insert_ids(i), 
					DECODE(r.region_sid, in_region_sid, 0, 1) inherited
				  FROM region r, region_proc_file d
				 WHERE d.region_sid(+) = r.region_sid
				   AND NVL(d.meter_document_id, -1) <> v_insert_ids(i)
				  	START WITH r.region_sid = in_region_sid
				  	CONNECT BY PRIOR r.region_sid = parent_sid;
	END IF; 
			  	
	-- Now insert all files from the cache key array
	IF NOT(in_cache_keys.COUNT = 1 AND in_cache_keys(1) IS NULL) THEN
		FOR i IN in_cache_keys.FIRST .. in_cache_keys.LAST
		LOOP
			-- Next file id
			SELECT meter_document_id_seq.NEXTVAL
			  INTO v_file_id
			  FROM dual;

			-- Insert the file data
			INSERT INTO meter_document
			  (meter_document_id, mime_type, file_name, data)
				SELECT v_file_id, mime_type, filename, object
			  	  FROM aspen2.filecache 
			 	 WHERE cache_key = in_cache_keys(i);
			 	 
			-- Insert the region relationships
			INSERT INTO region_proc_file
		  		(region_sid, meter_document_id, inherited)
			SELECT r.region_sid, v_file_id, 
				DECODE(r.region_sid, in_region_sid, 0, 1) inherited
			  FROM region r
			  	START WITH r.region_sid = in_region_sid
			  	CONNECT BY PRIOR r.region_sid = parent_sid;
		END LOOP;
	END IF;
			
END;

END procedures_pkg;
/
