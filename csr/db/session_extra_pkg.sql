CREATE OR REPLACE PACKAGE CSR.session_extra_pkg IS

/**
 * Get some extra session data
 *
 * @param in_key		The key for the data
 * @param out_cur		The rowset containing the data
 */
PROCEDURE GetData(
	in_key				IN	session_extra.key%TYPE,
	out_cur				OUT	SYS_REFCURSOR
);

/**
 * Set some binary extra session data
 *
 * @param in_key		The key for the data
 * @param in_blob		Storage for the data
 */
PROCEDURE SetBinary(
	in_key				IN	session_extra.key%TYPE,
	in_blob				IN	session_extra.binary%TYPE
);


/**
 * Set some string extra session data
 *
 * @param in_key		The key for the data
 * @param in_clob		Storage for the data
 */
PROCEDURE SetString(
	in_key				IN	session_extra.key%TYPE,
	in_clob				IN	session_extra.text%TYPE
);

/**
 * Called from a job to clean up old session data
 */
PROCEDURE CleanOldData;

END session_extra_pkg;
/
