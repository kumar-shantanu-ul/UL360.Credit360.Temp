CREATE OR REPLACE PACKAGE BODY csr.context_sensitive_help_pkg AS

PROCEDURE GetContextSensitiveHelpBase(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT client_help_root, internal_help_root
		  FROM context_sensitive_help_base;
END;

PROCEDURE GetContextSensitiveHelpRedirects(
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT source_path, help_path
		  FROM context_sensitive_help_redirect
		ORDER BY source_path;
END;

PROCEDURE GetContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE,
	out_cur					OUT	SYS_REFCURSOR
)
AS
BEGIN
	OPEN out_cur FOR
		SELECT source_path, help_path
		  FROM context_sensitive_help_redirect
		 WHERE UPPER(source_path) = UPPER(in_source_path);
END;


PROCEDURE UpsertContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE,
	in_help_path			IN	context_sensitive_help_redirect.help_path%TYPE
)
AS
BEGIN
	BEGIN
		UPDATE csr.context_sensitive_help_redirect
		   SET help_path = in_help_path
		 WHERE UPPER(source_path) = UPPER(in_source_path);

		IF SQL%ROWCOUNT = 0 THEN
				INSERT INTO csr.context_sensitive_help_redirect (source_path, help_path)
				VALUES (in_source_path, in_help_path);
		END IF;
	END;	
END;


PROCEDURE DeleteContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE
)
AS
BEGIN
	DELETE FROM context_sensitive_help_redirect
	 WHERE UPPER(source_path) = UPPER(in_source_path);
END;

END;
/
