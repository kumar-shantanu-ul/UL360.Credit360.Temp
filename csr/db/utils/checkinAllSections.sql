begin
	for r in (
		select section_sid, checked_out_version_number 
		  from section
		 where checked_out_version_number is not null
		   and module_root_sid = 10031757
	)
	loop
		-- Clear the checkout status from the section table
		UPDATE section
		   SET CHECKED_OUT_TO_SID = NULL, CHECKED_OUT_DTM = NULL, CHECKED_OUT_VERSION_NUMBER = NULL,
				VISIBLE_VERSION_NUMBER = r.checked_out_version_number
		 WHERE SECTION_SID = r.section_sid;
		 
		-- Update the verison table with the check-in information
		UPDATE section_version
		   SET CHANGED_BY_SID = security_pkg.GetSID, CHANGED_DTM = SYSDATE, REASON_FOR_CHANGE = 'Forced checkin'
		 WHERE SECTION_SID = r.section_sid
		   AND VERSION_NUMBER = r.checked_out_version_number;
	end loop;
end;
/
