DECLARE
	v_act			security_pkg.T_ACT_ID;
	v_copy_sid		security_pkg.T_SID_ID := 9013026; -- the first delegation in the list (uses to make a copy, so set up the users correctly here
	v_new_name		delegation.name%TYPE := 'Environment 2008';
	v_strip_prefix	varchar2(32000) := 'Environment - ';
	v_strip_suffix	varchar2(32000) := ' (East) 2008';
	v_deleg_sid		security_pkg.T_SID_ID;
	v_xml			clob := EMPTY_CLOB;
	v_str 			varchar2(32000);
	v_max_pos		number(10) := 0;
BEGIN
	user_pkg.LogonAuthenticatedPath(0, '//csr/users/richard', 10000, v_act);
	delegation_pkg.CopyDelegation(v_act, v_copy_sid, v_new_name, v_deleg_sid);
	-- delete all inds
	DELETE FROM delegation_ind_description
	 WHERE delegation_sid = v_deleg_sid;
	DELETE FROM delegation_ind
	 WHERE delegation_sid = v_deleg_sid;
	-- copy all regions
	INSERT INTO delegation_region
         (delegation_sid, region_sid, mandatory, description, pos, aggregate_to_region_sid)
	    SELECT v_deleg_sid, region_sid, mandatory, description, pos, aggregate_to_region_sid
	      FROM delegation_region
	     WHERE delegation_sid = v_copy_sid;
	DBMS_LOB.CREATETEMPORARY( v_xml, true );
	DBMS_LOB.OPEN( v_xml, DBMS_LOB.LOB_READWRITE );
	v_str := '<sections>'; DBMS_LOB.WRITEAPPEND ( v_xml, LENGTH(v_str), v_str );
	FOR r IN (	
		SELECT delegation_sid, name, rownum-1 section_key
		  FROM delegation 
	     WHERE delegation_sid in (9013026,9013211,9013071,9013099,9013121,9013133,9013151,9013188,9013252,9013196)
	)
	LOOP
		-- NB doesn't make any effort to XML encode
		v_str := '<section description="'||replace(replace(r.name,v_strip_prefix,''),v_strip_suffix,'')||' " key="'||r.section_key||'">';
		DBMS_LOB.WRITEAPPEND ( v_xml, LENGTH(v_str), v_str );
		FOR j IN (
			SELECT ind_sid FROM delegation_ind WHERE delegation_sid = r.delegation_sid ORDER BY POS
		)
		LOOP
			v_str := '<ind sid="'||j.ind_sid||'"/>';
			DBMS_LOB.WRITEAPPEND ( v_xml, LENGTH(v_str), v_str );
		END LOOP;
		v_str := '</section>';
		DBMS_LOB.WRITEAPPEND ( v_xml, LENGTH(v_str), v_str );
		-- insert delegations
		INSERT INTO delegation_ind
            (delegation_sid, ind_sid, mandatory, description, pos, section_Key)
            SELECT v_deleg_sid, ind_sid, mandatory, description, v_max_pos+pos, r.section_key
              FROM delegation_ind
             WHERE delegation_sid = r.delegation_sid;
		SELECT MAX(pos)+1 INTO v_max_pos
		  FROM delegation_ind
		 WHERE delegation_sid = v_deleg_sid;
	END LOOP;
	v_str := '</sections>'; DBMS_LOB.WRITEAPPEND ( v_xml, LENGTH(v_str), v_str );
	DBMS_LOB.CLOSE (v_xml);
	-- update with section_xml clob
	UPDATE delegation 
	   SET section_xml = v_xml
	 WHERE delegation_sid = v_deleg_sid;
	DBMS_LOB.FREETEMPORARY ( v_xml );
	DBMS_OUTPUT.PUT_LINE('Created new delegation: '||v_deleg_sid);
END;

