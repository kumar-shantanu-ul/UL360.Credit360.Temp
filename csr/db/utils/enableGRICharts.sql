DECLARE
    v_sid 					security_pkg.T_SID_ID;
    v_default_status_sid 	security_pkg.T_SID_ID;
BEGIN	
	user_pkg.LogonAdmin('&&1');

	-- show summary
	UPDATE section_module 
	   SET show_summary_tab = 1 
	 WHERE app_sid = SYS_CONTEXT('SECURITY','APP');
	
	-- update default status to be called 'Not covered'
	-- (red colour by default)
	SELECT DISTINCT default_status_sid INTO v_default_status_sid FROM section_module;
	UPDATE section_status
	   SET description = 'Not covered',
				 icon_path = '/csr/styles/images/griIcons/notCovered.gif',
				 pos = 3
	  WHERE section_status_sid = v_default_status_sid;
		
	-- create additional statuses and populate with icons  
	
	-- dark green
    section_status_pkg.CreateSectionStatus('Covered', 32768, 1, v_sid);
    UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/covered.gif'
	  WHERE section_status_sid = v_sid;
    
	-- light green
    section_status_pkg.CreateSectionStatus('Partly covered', 1107474, 2, v_sid);
	UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/partlyCovered.gif'
	  WHERE section_status_sid = v_sid;
	  
	  
		
	-- white
	section_status_pkg.CreateSectionStatus('Not applicable', 16777215, 4, v_sid);
	UPDATE section_status
	   SET icon_path = '/csr/styles/images/griIcons/notApplicable.gif'
	  WHERE section_status_sid = v_sid;
	  
	COMMIT;
end;
/

exit
