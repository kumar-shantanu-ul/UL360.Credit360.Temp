CREATE OR REPLACE FUNCTION supplier.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- This is:
	--
	--    Allow data for superadmins (must exist for joins for names and so on, needs to be fixed);
	-- OR not logged on (i.e. needs to be fixed);
	-- OR logged on and data is for the current application
	--
	RETURN 'app_sid = 0 or app_sid = sys_context(''SECURITY'', ''APP'') or sys_context(''SECURITY'', ''APP'') is null';
END;
/
