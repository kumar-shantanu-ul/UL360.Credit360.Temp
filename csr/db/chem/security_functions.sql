CREATE OR REPLACE FUNCTION chem.appSidCheck (
	in_schema 		IN	varchar2, 
	in_object 		IN	varchar2
)
RETURN VARCHAR2
AS
BEGIN
	-- Not logged on => see everything.  Needed for update scripts...
	IF SYS_CONTEXT('SECURITY', 'APP') IS NULL THEN
		RETURN '';
	END IF;
	
	-- Only show data if you are logged on and data is for the current application
	RETURN 'app_sid = sys_context(''SECURITY'', ''APP'')';	
END;
/