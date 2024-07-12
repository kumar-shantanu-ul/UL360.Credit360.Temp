CREATE OR REPLACE PACKAGE CSR.region_event_pkg
AS

PROCEDURE AddEvent(
	in_region_sid			IN security_pkg.T_SID_ID,
	in_label					IN event.label%TYPE,
	in_event_text			IN event.event_text%TYPE,
	in_event_dtm			IN event.event_dtm%TYPE,
	out_cur		     		OUT security_pkg.T_OUTPUT_CUR
);


PROCEDURE SetEvent(
	in_region_sid						IN security_pkg.T_SID_ID,
	in_event_id							IN security_pkg.T_SID_ID,
	in_label								IN event.label%TYPE,
	in_event_text						IN event.event_text%TYPE,
	in_event_dtm						IN event.event_dtm%TYPE
);

PROCEDURE GetEvents(
	in_region_sid			IN security_pkg.T_SID_ID,
	out_cur		     		OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE GetEvent(
	in_event_id 		IN security_pkg.T_SID_ID,
	in_region_sid 	IN security_pkg.T_SID_ID,
	out_cur					OUT security_pkg.T_OUTPUT_CUR
);

PROCEDURE RemoveEvent(
	in_event_id							IN security_pkg.T_SID_ID,
	in_region_sid						IN security_pkg.T_SID_ID
);

PROCEDURE CheckOwner(
	in_event_id IN security_pkg.T_SID_ID,
	in_region_sid	IN security_pkg.T_SID_ID
);

PROCEDURE InheritEvents(
	in_region_sid	IN security_pkg.T_SID_ID
);

END region_event_pkg;
/
