CREATE OR REPLACE FUNCTION csrimp.SessionIDCheck (
	in_schema 						IN	VARCHAR2, 
	in_object 						IN	VARCHAR2
)
RETURN VARCHAR2
AS
BEGIN
	-- return '' if the CSRIMP_SESSION_ID is not set to prevent "ORA-28133: full table access is restricted by fine-grained security" errors in 11g when running update scripts
	IF SYS_CONTEXT('SECURITY', 'CSRIMP_SESSION_ID') IS NULL THEN
		RETURN '';
	END IF;
		
	RETURN 'csrimp_session_id = sys_context(''SECURITY'', ''CSRIMP_SESSION_ID'')';
END;
/
