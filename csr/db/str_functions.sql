/**
 * Truncate a string to the given byte length so that
 * it fits in a column declared VARCHAR2(in_bytes)
 *
 * @param in_str		String to truncate
 * @param in_bytes		Number of bytes for result
 */
CREATE OR REPLACE FUNCTION CSR.TruncateString(
	in_str		VARCHAR2,
	in_bytes	BINARY_INTEGER
)
RETURN VARCHAR2
AS
	v_i 		BINARY_INTEGER;
	v_len		BINARY_INTEGER;
	v_bytes		BINARY_INTEGER;
BEGIN
	v_i := 1;
	v_bytes := 0;
	WHILE v_i <= LENGTH(in_str) LOOP
		v_len := LENGTHB(SUBSTR(in_str, v_i, 1));
		IF v_bytes + v_len > in_bytes THEN
			EXIT;
		END IF;
		v_i := v_i + 1;
		v_bytes := v_bytes + v_len;
	END LOOP;
	RETURN SUBSTR(in_str, 1, v_i - 1);
END;
/

/**
 * Join a table of strings together
 *
 * @param in_tab		Strings to join
 * @param in_delim		Delimiter for the list (defaults to comma)
 */
CREATE OR REPLACE FUNCTION CSR.JoinStrings(
	in_tab		IN	T_VARCHAR2_TABLE,
	in_delim	IN	VARCHAR2 DEFAULT ','
)
RETURN VARCHAR2
DETERMINISTIC 
AS
	v_s VARCHAR2(4000);
BEGIN
	IF in_tab.COUNT = 0 THEN -- needed otherwise we get an error from the FOR loop
		RETURN NULL;
	END IF;
	FOR v_i IN in_tab.FIRST .. in_tab.LAST LOOP
		IF v_i != in_tab.FIRST THEN
			v_s := v_s || in_delim;
		END IF;
		v_s := v_s || in_tab(v_i);
	END LOOP;
	RETURN v_s;
END;
/

/**
 * Join a table of strings together in reverse order
 *
 * @param in_tab		Strings to join
 * @param in_delim		Delimiter for the list (defaults to comma)
 */
CREATE OR REPLACE FUNCTION CSR.RJoinStrings(
	in_tab		IN	T_VARCHAR2_TABLE,
	in_delim	IN	VARCHAR2 DEFAULT ','
) 
RETURN VARCHAR2
DETERMINISTIC 
AS
	v_s VARCHAR2(4000);
BEGIN
	IF in_tab.COUNT = 0 THEN -- needed otherwise we get an error from the FOR loop
		RETURN NULL;
	END IF;
	FOR v_i IN in_tab.FIRST .. in_tab.LAST LOOP
		IF v_i != in_tab.FIRST THEN
			v_s := in_delim || v_s;
		END IF;
		v_s := in_tab(v_i) || v_s;
	END LOOP;
	RETURN v_s;
END;
/

/**
 * Join a table of strings together, and return as CLOB
 *
 * @param in_tab		Strings to join
 * @param in_delim		Delimiter for the list (defaults to comma)
 */
CREATE OR REPLACE FUNCTION CSR.JoinStringsToClob(
	in_tab		IN	T_VARCHAR2_TABLE,
	in_delim	IN	VARCHAR2 DEFAULT ','
)
RETURN CLOB
DETERMINISTIC 
AS
	v_use_clob NUMBER(1) := 0;
	v_s VARCHAR2(4000);
	v_clob CLOB;
BEGIN
	IF in_tab.COUNT = 0 THEN -- needed otherwise we get an error from the FOR loop
		RETURN NULL;
	END IF;
	
	dbms_lob.createtemporary(v_clob, TRUE, dbms_lob.call);
	dbms_lob.open(v_clob, dbms_lob.lob_readwrite);
	
	FOR v_i IN in_tab.FIRST .. in_tab.LAST LOOP
	
		IF v_use_clob = 1 OR LENGTHB(v_s||in_delim||in_tab(v_i)) > 4000 THEN
			IF v_use_clob = 0 THEN
				-- gone over 4000 bytes, start using clob
				dbms_lob.append(v_clob, v_s);
				v_use_clob := 1;
			END IF;
			
			dbms_lob.append(v_clob, in_delim || in_tab(v_i));
		ELSE
			-- continue using varchar2
			IF v_i != in_tab.FIRST THEN
				v_s := v_s || in_delim;
			END IF;
			
			v_s := v_s || in_tab(v_i);
		END IF;
			
	END LOOP;
	
	IF v_use_clob = 0 THEN
		-- Fitted in varchar2, so append string to clob before returning
		dbms_lob.append(v_clob, v_s);
	END IF;
	
	RETURN v_clob;
END;
/

/**
 * Prepare number for inclusion into SQL DML statement
 *
 * @param in_num Number value to include.
 *
 * @return The word 'null' if the value is null (as would be expected for a 
 * null value in an SQL DML statement), otherwise return number.
 */
CREATE OR REPLACE FUNCTION CSR.QuoteNumberString
(
    in_num  NUMBER
)
    return  varchar2
is
    v_retval    varchar2(50) default 'null';
BEGIN
    if in_num is not null then
        v_retval := in_num;
    end if;
    return v_retval;
END;
/

/**
 * Prepare text string for inclusion into SQL DML statement
 *
 * @param in_str String value to include.
 *
 * @return The word 'null' if the value is null (as would be expected for a 
 * null value in an SQL DML statement), return quoted string.
 */
CREATE OR REPLACE FUNCTION CSR.QuoteCharClob
(
    in_str  varchar2
)
    return  clob
is
BEGIN
    return case when in_str is null then 'null' else '''' || replace(in_str, '''', '''''') || '''' end;
END;
/

/**
 * Prepare XML for inclusion into SQL DML statement
 *
 * @param in_xml XML string value to include.
 *
 * @return The word 'null' if the value is null (as would be expected for a 
 * null value in an SQL DML statement), return quoted XML string appropriately cast.
 */
CREATE OR REPLACE FUNCTION CSR.QuoteXMLClob
(
    in_xml  xmltype
)
    return  clob
is
    v_retval varchar2(32767) default 'null';
BEGIN
    if in_xml is not null then
        v_retval := in_xml.GetClobVal();
        v_retval := 'xmltype(''' || replace(v_retval, '''', '''''') || ''')';
    end if;
    return v_retval;
END;
/

