CREATE OR REPLACE PACKAGE BODY CSR.session_extra_pkg IS

PROCEDURE GetData(
	in_key				IN	session_extra.key%TYPE,
	out_cur				OUT	SYS_REFCURSOR
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
BEGIN
	OPEN out_cur FOR
		SELECT text, binary
		  FROM session_extra
		 WHERE act_id = v_act_id AND key = in_key;
END;

PROCEDURE SetBinary(
	in_key				IN	session_extra.key%TYPE,
	in_blob				IN	session_extra.binary%TYPE
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
BEGIN
	BEGIN
		INSERT INTO session_extra (act_id, key, binary)
		VALUES (v_act_id, in_key, in_blob);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE session_extra
			   SET binary = in_blob, text = NULL
			 WHERE act_id = v_act_id AND key = in_key;
	END;
END;

PROCEDURE SetString(
	in_key				IN	session_extra.key%TYPE,
	in_clob				IN	session_extra.text%TYPE
)
AS
	v_act_id	security_pkg.T_ACT_ID DEFAULT security_pkg.GetACT();
BEGIN
	BEGIN
		INSERT INTO session_extra (act_id, key, text)
		VALUES (v_act_id, in_key, in_clob);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE session_extra
			   SET text = in_clob, binary = NULL
			 WHERE act_id = v_act_id AND key = in_key;
	END;
END;

PROCEDURE CleanOldData
AS
BEGIN
	-- This is less likely to leave stuff lying around
	-- than the session callback gubbins
	DELETE FROM session_extra
	 WHERE act_id NOT IN (SELECT act_id
	 						FROM security.act_timeout);
	COMMIT;
END;

END session_extra_pkg;
/
