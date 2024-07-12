-- Please update version.sql too -- this keeps clean builds in sync
define version=41
@update_header

-- sorts out regions, global factors etc  
DECLARE
	v_act security_pkg.T_ACT_ID;
	v_regions_sid security_pkg.T_SID_ID;
	v_indicators_sid security_pkg.T_SID_ID;
BEGIN
	user_pkg.logonauthenticatedpath(0,'//builtin/administrator',500,v_act);
    -- ensure all users have a region + indicator mount point sid
    FOR r IN
    	(SELECT csr_root_sid, NAME FROM CUSTOMER WHERE NAME NOT IN ('National Grid','ING'))
    LOOP
    	DBMS_OUTPUT.PUT_LINE('doing '||r.NAME||' ('||r.csr_root_sid||')');
		v_indicators_sid := securableobject_pkg.getSidFromPath(v_act, r.csr_root_sid, 'Indicators');
		v_regions_sid := securableobject_pkg.getSidFromPath(v_act, r.csr_root_sid, 'Regions');
        UPDATE CSR_USER SET indicator_mount_point_sid = v_indicators_sid WHERE csr_root_sid = r.csr_root_sid AND indicator_mount_point_sid IS NULL;
		UPDATE CSR_USER SET region_mount_point_sid = v_regions_sid WHERE csr_root_sid = r.csr_root_sid AND region_mount_point_sid IS NULL;
		INSERT INTO REGION (region_sid, parent_sid, csr_root_sid, NAME, description, active, pos, info_xml, link_to_region_sid, pct_ownership)
			VALUES (v_regions_sid, r.csr_root_sid, r.csr_root_sid, 'regions', 'Regions', 1, 1, NULL, NULL, 1);
		INSERT INTO IND (ind_sid, parent_sid, csr_root_sid, NAME, description)
			VALUES (v_indicators_sid, r.csr_root_sid, r.csr_root_sid, 'indicators', 'Indicators');
		-- add all indicators and regions to the security group table
		INSERT INTO SECURITY.GROUP_TABLE (SID_ID, GROUP_TYPE)
			SELECT ind_sid, 1 FROM csr.IND WHERE Csr_root_sid = r.csr_root_sid;
		INSERT INTO SECURITY.GROUP_TABLE (SID_ID, GROUP_TYPE)
			SELECT region_sid, 1 FROM csr.REGION WHERE Csr_root_sid = r.csr_root_sid;
		-- now add users to the right groups
		INSERT INTO SECURITY.GROUP_MEMBERS (MEMBER_SID_ID, GROUP_SID_ID)
			SELECT DISTINCT * FROM (
				SELECT csr_user_sid, region_mount_point_sid
				  FROM CSR_USER
				 WHERE csr_root_Sid = r.csr_root_sid
				 UNION
				SELECT csr_user_sid, indicator_mount_point_sid
				  FROM CSR_USER
				 WHERE csr_root_Sid = r.csr_root_sid);
    END LOOP;
END;
/

SELECT * FROM SECURITY.GROUP_TABLE WHERE sid_id IN (SELECT ind_sid FROM ind WHERE csr_root_sid = 340540); 


@update_tail
