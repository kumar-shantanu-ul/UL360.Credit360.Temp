CREATE OR REPLACE PACKAGE BODY csr.test_aspen2_utils_pkg AS

PROCEDURE TestConvertColourFromString
AS
	v_test_cases					t_test_cases;
BEGIN
	v_test_cases := t_test_cases (
		t_test_case('#000000', 0),
		t_test_case('#FFFFFF', 16777215),
		t_test_case('#1A2B3C', 1715004),
		t_test_case('#123456', 1193046),
		t_test_case('#abcdef', 11259375),
		t_test_case('#ABCDEF', 11259375),
		t_test_case('#000', 0),
		t_test_case('#AAA', 11184810),
		t_test_case('#aaa', 11184810),
		t_test_case('#FFF', 16777215),
		t_test_case('0x000000', 0),
		t_test_case('0xFFFFFF', 16777215),
		t_test_case('0x1A2B3C', 1715004),
		t_test_case('0x123456', 1193046),
		t_test_case('0xabcdef', 11259375),
		t_test_case('0xABCDEF', 11259375),
		t_test_case('0123456', 123456),
		t_test_case('7891011', 7891011)
	);
	
	FOR i IN 1 .. v_test_cases.COUNT LOOP
		unit_test_pkg.AssertAreEqual(
			v_test_cases(i).test_output, 
			aspen2.utils_pkg.ConvertColourFromString(in_colour => v_test_cases(i).test_input), 
			'Calling ConvertColourFromString with '||v_test_cases(i).test_input
		);
	END LOOP;	
END;

PROCEDURE TestSplitStringDefltDelim
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_TABLE;
BEGIN
	v_input := 'one,two,three';
	v_result := aspen2.utils_pkg.SplitString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitString with "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual('one', v_result(1).item, 'Calling SplitString with "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual('two', v_result(2).item, 'Calling SplitString with "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual('three', v_result(3).item, 'Calling SplitString with "'||v_input||'", checking items');
END;

PROCEDURE TestSplitStringDefltDelimSpcs
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_TABLE;
BEGIN
	v_input := 'one, two, three';
	v_result := aspen2.utils_pkg.SplitString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitString with default delimiter with spaces and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual('one', v_result(1).item, 'Calling SplitString with default delimiter with spaces and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(' two', v_result(2).item, 'Calling SplitString with default delimiter with spaces and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(' three', v_result(3).item, 'Calling SplitString with default delimiter with spaces and "'||v_input||'", checking items');
END;

PROCEDURE TestSplitStringDifferentDelim
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_TABLE;
BEGIN
	v_input := 'one~two~three';
	v_result := aspen2.utils_pkg.SplitString(in_string => v_input, in_delimiter => '~');
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitString with different delimiter and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual('one', v_result(1).item, 'Calling SplitString with different delimiter and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual('two', v_result(2).item, 'Calling SplitString with different delimiter and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual('three', v_result(3).item, 'Calling SplitString with different delimiter and "'||v_input||'", checking items');
END;

PROCEDURE TestSplitStringSingleInput
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_TABLE;
BEGIN
	v_input := 'one';
	v_result := aspen2.utils_pkg.SplitString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(1, CARDINALITY(v_result), 'Calling SplitString with single input and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual('one', v_result(1).item, 'Calling SplitString with single input and "'||v_input||'", checking items');	
END;

PROCEDURE TestSplitNumericDefltDelim
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_NUMERIC_TABLE;
BEGIN
	v_input := '1,2,3';
	v_result := aspen2.utils_pkg.SplitNumericString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitNumeric with "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual(1, v_result(1).item, 'Calling SplitNumeric with "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(2, v_result(2).item, 'Calling SplitNumeric with "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(3, v_result(3).item, 'Calling SplitNumeric with "'||v_input||'", checking items');
END;

PROCEDURE TestSplitNumericDefltDelimSpcs
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_NUMERIC_TABLE;
BEGIN
	v_input := '1, 2, 3';
	v_result := aspen2.utils_pkg.SplitNumericString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitNumeric with default delimiter with spaces and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual(1, v_result(1).item, 'Calling SplitNumeric with default delimiter with spaces and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(2, v_result(2).item, 'Calling SplitNumeric with default delimiter with spaces and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(3, v_result(3).item, 'Calling SplitNumeric with default delimiter with spaces and "'||v_input||'", checking items');
END;

PROCEDURE TestSplitNumericDifferentDelim
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_NUMERIC_TABLE;
BEGIN
	v_input := '1~2~3';
	v_result := aspen2.utils_pkg.SplitNumericString(in_string => v_input, in_delimiter => '~');
	
	unit_test_pkg.AssertAreEqual(3, CARDINALITY(v_result), 'Calling SplitNumeric with different delimiter and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual(1, v_result(1).item, 'Calling SplitNumeric with different delimiter and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(2, v_result(2).item, 'Calling SplitNumeric with different delimiter and "'||v_input||'", checking items');	
	unit_test_pkg.AssertAreEqual(3, v_result(3).item, 'Calling SplitNumeric with different delimiter and "'||v_input||'", checking items');
END;

PROCEDURE TestSplitNumericSingleInput
AS
	v_input							VARCHAR2(255);
	v_result						aspen2.T_SPLIT_NUMERIC_TABLE;
BEGIN
	v_input := '1';
	v_result := aspen2.utils_pkg.SplitNumericString(in_string => v_input);
	
	unit_test_pkg.AssertAreEqual(1, CARDINALITY(v_result), 'Calling SplitNumeric with single input and "'||v_input||'", checking result count');
	unit_test_pkg.AssertAreEqual(1, v_result(1).item, 'Calling SplitNumeric with single input and "'||v_input||'", checking items');	
END;

PROCEDURE TestJoinStringDefaultDelim
AS
	v_input							SYS_REFCURSOR;
	v_result						VARCHAR2(255);
BEGIN
	OPEN v_input FOR
		SELECT str
		  FROM (
			SELECT 'one' str, 1 rn FROM DUAL
			 UNION 
			SELECT 'two', 2 FROM DUAL
			 UNION 
			SELECT 'three', 3 FROM DUAL
		 )
		 ORDER BY rn;

	v_result := aspen2.utils_pkg.JoinString(in_cursor => v_input);
	
	unit_test_pkg.AssertAreEqual('one,two,three', v_result, 'Calling JoinString with default delimiter');	
END;

PROCEDURE TestJoinStringDifferentDelim
AS
	v_input							SYS_REFCURSOR;
	v_result						VARCHAR2(255);
BEGIN
	OPEN v_input FOR
		SELECT str
		  FROM (
			SELECT 'one' str, 1 rn FROM DUAL
			 UNION 
			SELECT 'two', 2 FROM DUAL
			 UNION 
			SELECT 'three', 3 FROM DUAL
		 )
		 ORDER BY rn;

	v_result := aspen2.utils_pkg.JoinString(in_cursor => v_input, in_delimiter => '~');
	
	unit_test_pkg.AssertAreEqual('one~two~three', v_result, 'Calling JoinString with ~ delimiter');	
END;

PROCEDURE TestJoinStringSingleInput
AS
	v_input							SYS_REFCURSOR;
	v_result						VARCHAR2(255);
BEGIN
	OPEN v_input FOR
		SELECT 'one' FROM DUAL;

	v_result := aspen2.utils_pkg.JoinString(in_cursor => v_input);
	
	unit_test_pkg.AssertAreEqual('one', v_result, 'Calling JoinString with single input');	
END;

END;
/