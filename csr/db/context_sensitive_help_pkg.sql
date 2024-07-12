CREATE OR REPLACE PACKAGE csr.context_sensitive_help_pkg AS

PROCEDURE GetContextSensitiveHelpBase(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetContextSensitiveHelpRedirects(
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE GetContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE,
	out_cur					OUT	SYS_REFCURSOR
);

PROCEDURE UpsertContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE,
	in_help_path			IN	context_sensitive_help_redirect.help_path%TYPE
);

PROCEDURE DeleteContextSensitiveHelpRedirect(
	in_source_path			IN	context_sensitive_help_redirect.source_path%TYPE
);

END;
/
