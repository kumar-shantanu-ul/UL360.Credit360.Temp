-- Please update version.sql too -- this keeps clean builds in sync
define version=378
@update_header

-- We've switched so it uses SIDs everywhere for the old section stuff
-- so it's a chance to get rid of /csr/site/g3
BEGIN
	FOR r IN (
		SELECT host, sm.sid_id 
		  FROM security.menu sm, security.securable_object so, customer c 
		 WHERE lower(action) = '/csr/site/g3/sectiontree.acds'
		   AND sm.sid_id =so.sid_Id 
		   AND so.application_sid_id = c.app_sid
	)
	LOOP
		DBMS_OUTPUT.PUT_LINE('Fixing G3 menu link on '||r.host);
		UPDATE security.menu SET action = '/csr/site/text/sectionTree.acds?module=g3' WHERE sid_id = r.sid_id;
	END LOOP;
END;
/

@../text/io_pkg
@../text/section_pkg
@../text/section_root_pkg

@../text/io_body
@../text/section_body
@../text/section_root_body

@update_tail
