/*  NB this orphans doc_id + doc_Data
 */
DECLARE
	v_act				security_pkg.T_ACT_ID;
	v_app_sid			security_pkg.T_SID_ID;
	v_host				varchar2(255) := '&&1';
    v_documents_sid     security_pkg.T_SID_ID;
    v_trash_folder_sid  security_pkg.T_SID_ID;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	v_app_sid := securableobject_pkg.GetSIDFromPath(v_act, security_pkg.SID_ROOT, '//aspen/applications/'||v_host);
	security_pkg.SetACT(v_act, v_app_sid);
    FOR r IN (
        SELECT doc_library_sid 
          FROM doc_library 
         WHERE app_sid = v_app_sid
    )
    LOOP
        -- get folders here so we don't have constraint violations later
        SELECT documents_sid, trash_folder_sid
          INTO v_documents_sid, v_trash_folder_sid
          FROM DOC_LIBRARY
         WHERE doc_library_sid = r.doc_library_sid;
        --
        -- delete basic data
        DELETE FROM DOC_DOWNLOAD WHERE DOC_ID IN (
            SELECT doc_id 
              FROM doc_current
             WHERE parent_sid in (
                SELECT doc_folder_sid FROM v$doc_folder_root 
                 WHERE doc_library_sid = r.doc_library_sid
            )
        );
        DELETE FROM DOC_NOTIFICATION WHERE DOC_ID IN (
            SELECT doc_id 
              FROM doc_current
             WHERE parent_sid in (
                SELECT doc_folder_sid FROM v$doc_folder_root 
                 WHERE doc_library_sid = r.doc_library_sid
            )
        );
        DELETE FROM DOC_SUBSCRIPTION WHERE DOC_ID IN (
            SELECT doc_id 
              FROM doc_current
             WHERE parent_sid in (
                SELECT doc_folder_sid FROM v$doc_folder_root 
                 WHERE doc_library_sid = r.doc_library_sid
            )
        );
        DELETE FROM DOC_VERSION WHERE DOC_ID IN (
            SELECT doc_id 
              FROM doc_current
             WHERE parent_sid in (
                SELECT doc_folder_sid FROM v$doc_folder_root 
                 WHERE doc_library_sid = r.doc_library_sid
            )
        );
        -- now current versions
        DELETE FROM DOC_CURRENT WHERE parent_sid in (
            SELECT doc_folder_sid FROM v$doc_folder_root 
             WHERE doc_library_sid = r.doc_library_sid
        );
        -- we have to delete from doc_Library first
        DELETE FROM DOC_LIBRARY 
         WHERE doc_library_sid = r.doc_library_sid;
        -- now clean up folder table
        DELETE FROM DOC_FOLDER WHERE doc_folder_sid in (
           SELECT so.sid_id
             FROM security.securable_object so
            START WITH sid_id in (v_trash_folder_sid, v_documents_sid)
          CONNECT BY PRIOR sid_id = parent_sid_id         
        );
    END LOOP;
END;
/
