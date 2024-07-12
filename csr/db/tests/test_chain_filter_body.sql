CREATE OR REPLACE PACKAGE BODY csr.test_chain_filter_pkg AS

m_compound_filter_id				NUMBER;
m_filter_id							NUMBER;
m_aggregation_type_id				NUMBER := 1;

PROCEDURE Trace(s VARCHAR2)
AS
BEGIN
	dbms_output.put_line(s);
	--NULL;
END;

PROCEDURE SetUpFixture(in_site_name VARCHAR2)
AS
BEGIN
	security.user_pkg.logonadmin(in_site_name);
END;

PROCEDURE SetUp AS
BEGIN	
	-- compound filter
	chain.filter_pkg.CreateCompoundFilter (
		in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_ISSUES,
		out_compound_filter_id		=> m_compound_filter_id
	);
	
	-- filter
	chain.filter_pkg.AddCardFilter (
		in_compound_filter_id		=> m_compound_filter_id,
		in_class_type				=> 'Credit360.Issues.Cards.StandardIssuesFilter',
		in_card_group_id			=> chain.filter_pkg.FILTER_TYPE_ISSUES,
		out_filter_id				=> m_filter_id
	);
	
	-- aggregate type / tt_filter_object_data
	DELETE FROM chain.tt_filter_object_data;
	INSERT INTO chain.tt_filter_object_data (data_type_id, object_id, agg_type_id, val_number)
	SELECT DISTINCT m_aggregation_type_id, l.object_id, chain.filter_pkg.AFUNC_COUNT, l.object_id
	  FROM (SELECT level object_id FROM dual CONNECT BY level < 1000) l; -- just stick 1000 rows with sequential ids in
END;

PROCEDURE TearDown AS
BEGIN
	chain.filter_pkg.DeleteCompoundFilter(m_compound_filter_id);
END;

PROCEDURE TearDownFixture AS
BEGIN 
	NULL;
END;

PROCEDURE CreateFilterField (
	in_level						IN  NUMBER,
	in_top_n						IN  NUMBER,
	out_filter_field_id				OUT NUMBER
)
AS
BEGIN
	chain.filter_pkg.AddFilterField (
		in_filter_id			=> m_filter_id,
		in_name					=> 'breakdown'||in_level,
		in_comparator			=> chain.filter_pkg.COMPARATOR_EQUALS,
		in_group_by_index		=> in_level,
		in_show_all				=> CASE WHEN in_top_n IS NULL THEN 0 ELSE 1 END,
		in_top_n				=> in_top_n,
		in_bottom_n				=> NULL,
		in_column_sid			=> NULL,
		in_show_other			=> 1,
		out_filter_field_id		=> out_filter_field_id
	);
END;

PROCEDURE CreateFilterFieldWithValues (
	in_level						IN  NUMBER,
	in_top_n						IN  NUMBER,
	in_value_count					IN  NUMBER,
	io_ids							IN OUT NOCOPY chain.T_FILTERED_OBJECT_TABLE,
	out_filter_field_id				OUT NUMBER
)
AS
	v_filter_value_id				NUMBER;	
	v_id_seq						NUMBER := 0;
BEGIN
	CreateFilterField(in_level, in_top_n, out_filter_field_id);
	
	FOR v_i IN 1..in_value_count LOOP
		chain.filter_pkg.AddNumberValue (
			in_filter_field_id		=> out_filter_field_id,
			in_value				=> v_i,
			in_description			=> 'Filter value '|| v_i,
			in_null_filter			=> 0,
			out_filter_value_id		=> v_filter_value_id
		);
		
		FOR v_j IN 1..v_i LOOP		
			v_id_seq := v_id_seq + 1;
			io_ids.extend;
			io_ids(io_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(v_id_seq, in_level, v_filter_value_id);
		END LOOP;
	END LOOP;
END;

-- Creates test data that looks like:
--					breakdown1		breakdown2
-- Filter value 1:	1, 2, 3			1, 2
-- Filter value 2:	4, 5			3, 4, 7
-- Filter value 3:	6				5, 6
-- Where the numbers in the grid are ids being passed through the filter machine
PROCEDURE CreateTestData (
	in_top_n						IN  NUMBER,
	out_ids							OUT chain.T_FILTERED_OBJECT_TABLE
)
AS
	v_filter_field_id				NUMBER;
	v_filter_value_id				NUMBER;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
BEGIN
	CreateFilterField(
		in_level			=> 1,
		in_top_n			=> in_top_n, 
		out_filter_field_id	=> v_filter_field_id
	);	
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 1,
		in_description			=> 'Filter value '|| 1,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(1, 1, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(2, 1, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(3, 1, v_filter_value_id);
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 2,
		in_description			=> 'Filter value '|| 2,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(4, 1, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(5, 1, v_filter_value_id);
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 3,
		in_description			=> 'Filter value '|| 3,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(6, 1, v_filter_value_id);
	
	CreateFilterField(
		in_level			=> 2,
		in_top_n			=> in_top_n, 
		out_filter_field_id	=> v_filter_field_id
	);
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 1,
		in_description			=> 'Filter value '|| 1,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(1, 2, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(2, 2, v_filter_value_id);
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 2,
		in_description			=> 'Filter value '|| 2,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(3, 2, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(4, 2, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(7, 2, v_filter_value_id);
	
	chain.filter_pkg.AddNumberValue (
		in_filter_field_id		=> v_filter_field_id,
		in_value				=> 3,
		in_description			=> 'Filter value '|| 3,
		in_null_filter			=> 0,
		out_filter_value_id		=> v_filter_value_id
	);
	
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(5, 2, v_filter_value_id);
	v_ids.extend;
	v_ids(v_ids.COUNT) := chain.T_FILTERED_OBJECT_ROW(6, 2, v_filter_value_id);
	
	out_ids := v_ids;
END;

FUNCTION GetFilterFieldId_ (
	in_filter_field_number			IN  NUMBER
) RETURN NUMBER
AS
	v_filter_field_id				NUMBER;
BEGIN
	SELECT filter_field_id
	  INTO v_filter_field_id
	  FROM chain.filter_field
	 WHERE filter_id = m_filter_id
	   AND name = 'breakdown'||in_filter_field_number;
	
	RETURN v_filter_field_id;
END;

FUNCTION GetFilterValueId (
	in_filter_field_number			IN  NUMBER,
	in_filter_value_number			IN  NUMBER
) RETURN NUMBER
AS
	v_filter_value_id				NUMBER;
BEGIN
	SELECT filter_value_id
	  INTO v_filter_value_id
	  FROM chain.filter_value
	 WHERE filter_field_id = GetFilterFieldId_(in_filter_field_number)
	   AND num_value = in_filter_value_number;
	
	RETURN v_filter_value_id;
END;

FUNCTION FormatTopNValues (
	in_top_n						IN  security.T_ORDERED_SID_TABLE
) RETURN VARCHAR2
AS
	v_top_n_values					VARCHAR2(1000);
BEGIN
	SELECT LISTAGG(ff.name||': '||NVL(fv.num_value, tn.pos), ', ') WITHIN GROUP (ORDER BY ff.name, fv.num_value, tn.pos)
	  INTO v_top_n_values
	  FROM TABLE(in_top_n) tn
	  LEFT JOIN chain.filter_value fv ON fv.filter_value_id = tn.pos
	  LEFT JOIN chain.filter_field ff ON tn.sid_id = ff.filter_field_id;
	
	RETURN v_top_n_values;
END;

PROCEDURE FindTopN1Field AS
	v_value_count					NUMBER := 5;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_filter_field_id				NUMBER;
	v_count							NUMBER;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateFilterFieldWithValues(
		in_level			=> 1,
		in_top_n			=> NULL, 
		in_value_count		=> v_value_count, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id
	);	
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: 2, breakdown1: 3, breakdown1: 4, breakdown1: 5', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN1TopNField AS
	v_value_count					NUMBER := 5;
	v_top_n_count					NUMBER := 3;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_filter_field_id				NUMBER;
	v_count							NUMBER;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_top_n_values					VARCHAR2(255);
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateFilterFieldWithValues(
		in_level			=> 1,
		in_top_n			=> v_top_n_count, 
		in_value_count		=> v_value_count, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id
	);	
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb
	);

	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 3, breakdown1: 4, breakdown1: 5, breakdown1: -1', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2Fields AS
	v_value_count_1					NUMBER := 3;
	v_value_count_2					NUMBER := 5;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_filter_field_id_1				NUMBER;
	v_filter_field_id_2				NUMBER;
	v_count							NUMBER;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateFilterFieldWithValues(
		in_level			=> 1,
		in_top_n			=> NULL, 
		in_value_count		=> v_value_count_1, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id_1
	);	
	CreateFilterFieldWithValues(
		in_level			=> 2,
		in_top_n			=> NULL, 
		in_value_count		=> v_value_count_2, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id_2
	);	
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual(
		'breakdown1: 1, breakdown1: 2, breakdown1: 3, breakdown2: 1, breakdown2: 2, breakdown2: 3, breakdown2: 4, breakdown2: 5', 
		FormatTopNValues(v_top_n), 
		'Expected top N to return the correct results'
	);
END;

PROCEDURE FindTopN2TopNFields AS
	v_value_count_1					NUMBER := 5;
	v_value_count_2					NUMBER := 6;
	v_top_n_count					NUMBER := 3;
	v_ids							chain.T_FILTERED_OBJECT_TABLE := chain.T_FILTERED_OBJECT_TABLE();
	v_filter_field_id_1				NUMBER;
	v_filter_field_id_2				NUMBER;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_top_n_values					VARCHAR2(255);
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateFilterFieldWithValues(
		in_level			=> 1,
		in_top_n			=> v_top_n_count, 
		in_value_count		=> v_value_count_1, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id_1
	);	
	
	CreateFilterFieldWithValues(
		in_level			=> 2,
		in_top_n			=> v_top_n_count, 
		in_value_count		=> v_value_count_2, 
		io_ids				=> v_ids, 
		out_filter_field_id	=> v_filter_field_id_2
	);	
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual(
		'breakdown1: 3, breakdown1: 4, breakdown1: 5, breakdown1: -1, breakdown2: 4, breakdown2: 5, breakdown2: 6, breakdown2: -2', 
		FormatTopNValues(v_top_n), 
		'Expected top N to return the correct results'
	);
END;

PROCEDURE FindTopN2TopNFldsWithNoCrumb AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	dbms_output.put_line('Calling with breadcrumb no breadcrumb');
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWithValCrumb AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := GetFilterValueId(1, 1);
	
	-- act
	dbms_output.put_line('Calling with breadcrumb 1');
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert	
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 1, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWthOtherCrumb AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := -GetFilterFieldId_(1);
	
	-- act
	dbms_output.put_line('Calling with breadcrumb "other"');
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 3, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs1 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb 1, 2 sequentially (like pie chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 1
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := GetFilterValueId(1, 1);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 1, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act	
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := GetFilterValueId(2, 2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs2 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb 1, "other" sequentially (like pie chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 1
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := GetFilterValueId(1, 1);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 1, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := -GetFilterFieldId_(2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 1, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs3 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN	
	dbms_output.put_line('Calling with breadcrumb "other", 3 sequentially (like pie chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 1
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := -GetFilterFieldId_(1);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 3, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := GetFilterValueId(2, 3);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 3', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs4 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb "other", "other" sequentially (like pie chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 1
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := -GetFilterFieldId_(1);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 3, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := -GetFilterFieldId_(2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 3, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs5 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb 1, 2 both at once (like bar chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);

	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := GetFilterValueId(1, 1);
	v_breadcrumb.extend(1);
	v_breadcrumb(v_breadcrumb.COUNT) := GetFilterValueId(2, 2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs6 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb 1, "other" both at once (like bar chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);

	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := GetFilterValueId(1, 1);
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := -GetFilterFieldId_(2);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs7 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN	
	dbms_output.put_line('Calling with breadcrumb "other", 2 both at once (like bar chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);

	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := -GetFilterFieldId_(1);
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := GetFilterValueId(2, 2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE FindTopN2TopNFldsWith2Crumbs8 AS
	v_top_n_count					NUMBER := 1;
	v_ids							chain.T_FILTERED_OBJECT_TABLE;
	v_top_n							security.T_ORDERED_SID_TABLE;
	v_breadcrumb					security.T_SID_TABLE := security.T_SID_TABLE();
BEGIN
	dbms_output.put_line('Calling with breadcrumb "other", "other" both at once (like bar chart)');
	
	-- arrange
	CreateTestData(v_top_n_count, v_ids);
	
	-- act
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);

	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
	
	-- act
	v_breadcrumb.extend(1);
	v_breadcrumb(1) := -GetFilterFieldId_(1);
	v_breadcrumb.extend(1);
	v_breadcrumb(2) := -GetFilterFieldId_(2);
	
	v_top_n := chain.filter_pkg.FindTopN (
		in_field_filter_id		=> m_compound_filter_id,
		in_aggregation_type		=> m_aggregation_type_id,
		in_ids					=> v_ids,
		in_breadcrumb			=> v_breadcrumb,
		in_max_group_by			=> 2
	);
	
	-- assert
	csr.unit_test_pkg.AssertAreEqual('breakdown1: 1, breakdown1: -1, breakdown2: 2, breakdown2: -2', FormatTopNValues(v_top_n), 'Expected top N to return the correct results');
END;

PROCEDURE TestGetAggregateDataWithFilter
AS
	v_card_group_id		NUMBER := NULL;
	v_field_filter_id	chain.compound_filter.compound_filter_id%TYPE := NULL;
	v_aggregation_types	security.T_SID_TABLE := NULL;
	v_breadcrumb		security.T_SID_TABLE := security.T_SID_TABLE();
	v_max_group_by		NUMBER := NULL;
	v_show_totals		NUMBER := NULL;
	v_object_id_list	chain.T_FILTERED_OBJECT_TABLE := NULL;
	v_top_n_values		security.T_ORDERED_SID_TABLE := NULL;

	v_field_cur			SYS_REFCURSOR;
	v_data_cur			SYS_REFCURSOR;

	v_filter_value_id1		NUMBER;
	v_filter_value_id2		NUMBER;
	v_filter_value_id3		NUMBER;
	v_filter_value_id4		NUMBER;
	v_is_total1				NUMBER;
	v_is_total2				NUMBER;
	v_is_total3				NUMBER;
	v_is_total4				NUMBER;
	v_cur_aggregation_type	NUMBER;
	v_cur_val_number		NUMBER;

	v_count					NUMBER;

	v_top_n_count					NUMBER := 1;
	--v_ids							chain.T_FILTERED_OBJECT_TABLE;

BEGIN
	TRACE('TestGetAggregateDataWithFilter');

	CreateTestData(v_top_n_count, v_object_id_list);

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.tt_filter_object_data;
	unit_test_pkg.AssertAreEqual(999, v_count, 'Expected some fod'); 

	v_field_filter_id := m_compound_filter_id;
	TRACE('Using compound_filter_id '||v_field_filter_id);

	chain.filter_pkg.GetAggregateData(
		in_card_group_id				=>	v_card_group_id,
		in_field_filter_id				=>	v_field_filter_id,
		in_aggregation_types			=>	v_aggregation_types,
		in_breadcrumb					=>	v_breadcrumb,
		in_max_group_by					=>	v_max_group_by,
		in_show_totals					=>	v_show_totals,
		in_object_id_list				=>	v_object_id_list,
		in_top_n_values					=>  v_top_n_values,
		out_field_cur					=>	v_field_cur,
		out_data_cur					=>	v_data_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is tt_filter_object_data.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_data_cur INTO
			v_filter_value_id1,
			v_filter_value_id2,
			v_filter_value_id3,
			v_filter_value_id4,
			v_is_total1,
			v_is_total2,
			v_is_total3,
			v_is_total4,
			v_cur_aggregation_type,
			v_cur_val_number
		;

		TRACE('cur contains filters '||v_filter_value_id1||','||v_filter_value_id2||','||v_filter_value_id3||','||v_filter_value_id4);
		TRACE('cur contains istotal '||v_is_total1||','||v_is_total2||','||v_is_total3||','||v_is_total4);
		TRACE('cur contains '||v_cur_aggregation_type||','||v_cur_val_number);

		--unit_test_pkg.AssertAreEqual(1, v_cur_aggregation_type, 'Expected aggregation_type to be 1'); 
		--unit_test_pkg.AssertAreEqual(999, v_cur_val_number, 'Expected val_number to be 999'); 

		v_count := v_count + 1;

		EXIT WHEN v_data_cur%NOTFOUND;
	END LOOP;

	unit_test_pkg.AssertAreEqual(1, v_count, 'Expected 1 cur entries'); 

END;

PROCEDURE TestGetAggregateDataWithNoFilter
AS
	v_card_group_id		NUMBER := NULL;
	v_field_filter_id	chain.compound_filter.compound_filter_id%TYPE := NULL;
	v_aggregation_types	security.T_SID_TABLE := NULL;
	v_breadcrumb		security.T_SID_TABLE := security.T_SID_TABLE();
	v_max_group_by		NUMBER := NULL;
	v_show_totals		NUMBER := NULL;
	v_object_id_list	chain.T_FILTERED_OBJECT_TABLE := NULL;
	v_top_n_values		security.T_ORDERED_SID_TABLE := NULL;

	v_field_cur			SYS_REFCURSOR;
	v_data_cur			SYS_REFCURSOR;

	v_cur_filter_value_id1	NUMBER;
	v_cur_aggregation_type	NUMBER;
	v_cur_val_number		NUMBER;

	v_count				NUMBER;
BEGIN
	TRACE('TestGetAggregateDataWithNoFilter');

	SELECT COUNT(*)
	  INTO v_count
	  FROM chain.tt_filter_object_data;
	unit_test_pkg.AssertAreEqual(999, v_count, 'Expected some fod'); 

	chain.filter_pkg.GetAggregateData(
		in_card_group_id				=>	v_card_group_id,
		in_field_filter_id				=>	v_field_filter_id,
		in_aggregation_types			=>	v_aggregation_types,
		in_breadcrumb					=>	v_breadcrumb,
		in_max_group_by					=>	v_max_group_by,
		in_show_totals					=>	v_show_totals,
		in_object_id_list				=>	v_object_id_list,
		in_top_n_values					=>  v_top_n_values,
		out_field_cur					=>	v_field_cur,
		out_data_cur					=>	v_data_cur
	);

	-- Simulate the 19c error by committing. Causes any temp tables to be deleted.
	-- The table involved here is tt_filter_object_data.
	COMMIT;

	v_count := 0;
	LOOP
		FETCH v_data_cur INTO
			v_cur_filter_value_id1,
			v_cur_aggregation_type,
			v_cur_val_number
		;

		TRACE('cur contains '||v_cur_filter_value_id1||','||v_cur_aggregation_type||','||v_cur_val_number);

		unit_test_pkg.AssertAreEqual(-1, v_cur_filter_value_id1, 'Expected filter_value_id1 to be -1'); 
		unit_test_pkg.AssertAreEqual(1, v_cur_aggregation_type, 'Expected aggregation_type to be 1'); 
		unit_test_pkg.AssertAreEqual(999, v_cur_val_number, 'Expected val_number to be 999'); 

		v_count := v_count + 1;

		EXIT WHEN v_data_cur%NOTFOUND;
	END LOOP;

	unit_test_pkg.AssertAreEqual(2, v_count, 'Expected 2 cur entries'); 

END;

END test_chain_filter_pkg;
/
