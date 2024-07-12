CREATE OR REPLACE PACKAGE BODY CSR.null_pkg AS

FUNCTION eq(
	in_a	IN	VARCHAR2,
	in_b	IN	VARCHAR2
) RETURN BOOLEAN
AS
BEGIN
	-- Note: not the same as RETURN in_a = in_b OR (in_a IS NULL AND in_b IS NULL)
	-- due to the tri-valued nature of SQL booleans
	IF in_a = in_b OR (in_a IS NULL AND in_b IS NULL) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;

FUNCTION eq(
	in_a	IN	CLOB,
	in_b	IN	CLOB
) RETURN BOOLEAN
AS
BEGIN
	IF in_a IS NULL AND in_b IS NULL THEN
		RETURN TRUE; -- Both null
	ELSIF in_a IS NULL OR in_b IS NULL THEN
		RETURN FALSE; -- 1 is null
	ELSIF dbms_lob.compare(in_a, in_b) = 0 THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;

FUNCTION eq(
	in_a	IN	DATE,
	in_b	IN	DATE
) RETURN BOOLEAN
AS
BEGIN
	IF in_a = in_b OR (in_a IS NULL AND in_b IS NULL) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;

FUNCTION eq(
	in_a	IN	NUMBER,
	in_b	IN	NUMBER
) RETURN BOOLEAN
AS
BEGIN
	IF in_a = in_b OR (in_a IS NULL AND in_b IS NULL) THEN
		RETURN TRUE;
	END IF;
	RETURN FALSE;
END;

FUNCTION ne(
	in_a	IN	VARCHAR2,
	in_b	IN	VARCHAR2
) RETURN BOOLEAN
AS
BEGIN
	RETURN NOT eq(in_a, in_b);
END;

FUNCTION ne(
	in_a	IN	CLOB,
	in_b	IN	CLOB
) RETURN BOOLEAN
AS
BEGIN
	RETURN NOT eq(in_a, in_b);
END;

FUNCTION ne(
	in_a	IN	DATE,
	in_b	IN	DATE
) RETURN BOOLEAN
AS
BEGIN
	RETURN NOT eq(in_a, in_b);
END;

FUNCTION ne(
	in_a	IN	NUMBER,
	in_b	IN	NUMBER
) RETURN BOOLEAN
AS
BEGIN
	RETURN NOT eq(in_a, in_b);
END;

FUNCTION btn(
	in_v	IN	BOOLEAN
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN CASE WHEN in_v THEN 1 ELSE 0 END;
END;

FUNCTION seq(
	in_a	IN	VARCHAR2,
	in_b	IN	VARCHAR2
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(eq(in_a, in_b));
END;

FUNCTION seq(
	in_a	IN	CLOB,
	in_b	IN	CLOB
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(eq(in_a, in_b));
END;

FUNCTION seq(
	in_a	IN	DATE,
	in_b	IN	DATE
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(eq(in_a, in_b));
END;

FUNCTION seq(
	in_a	IN	NUMBER,
	in_b	IN	NUMBER
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(eq(in_a, in_b));
END;

FUNCTION sne(
	in_a	IN	VARCHAR2,
	in_b	IN	VARCHAR2
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(ne(in_a, in_b));
END;

FUNCTION sne(
	in_a	IN	CLOB,
	in_b	IN	CLOB
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(ne(in_a, in_b));
END;

FUNCTION sne(
	in_a	IN	DATE,
	in_b	IN	DATE
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(ne(in_a, in_b));
END;

FUNCTION sne(
	in_a	IN	NUMBER,
	in_b	IN	NUMBER
) RETURN BINARY_INTEGER
AS
BEGIN
	RETURN btn(ne(in_a, in_b));
END;

END;
/
