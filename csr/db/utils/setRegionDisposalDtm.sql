SET VERIFY OFF
SET SERVEROUTPUT ON
/*
 To set the disposal date(s) for given region(s).
 Initialize v_region_sids with list of region_sids and v_disposal_dtms with disposal/close dates.
 It will also set the active = 0.
*/
DECLARE
	TYPE T_REGION_SIDS		IS TABLE OF security.security_pkg.T_SID_ID;
	TYPE T_DP_DTMS			IS TABLE OF csr.region.disposal_dtm%TYPE;
	
	v_region_sids			T_REGION_SIDS;
	v_disposal_dtms			T_DP_DTMS;
BEGIN
	-- Initialize with region_sids to be updated
	v_region_sids := T_REGION_SIDS(
		/* Region_sid goes here */
	);
	-- Initialize with respective disposal dates to be set to
	v_disposal_dtms := T_DP_DTMS(
		/* Disposal_dtm goes here */
	);
	
	IF v_region_sids.COUNT != v_disposal_dtms.COUNT THEN
		RAISE_APPLICATION_ERROR(-20001, 'No of regions doesn''t match no of disposal dates');
	END IF;
	
	security.user_pkg.logonadmin('&host');
	
	FOR r IN 1..v_region_sids.COUNT
	LOOP
		IF v_region_sids(r) IS NULL OR v_disposal_dtms(r) IS NULL THEN
			SYS.dbms_output.put_line('Failed to update region, region_sid or disposal date is null.');
		ELSE
			SYS.dbms_output.put_line('Updating Region ' || v_region_sids(r) || ', Disposal Date -> ' || v_disposal_dtms(r));
			csr.region_pkg.DisposeRegion(
				v_region_sids(r), v_disposal_dtms(r)
			);
		END IF;
	END LOOP;
	COMMIT;
END;
/