CREATE OR REPLACE PACKAGE BODY ct.stemmer_pkg AS



/* EIO search tree / classification */
PROCEDURE CreatePSCategory (
	in_ps_category_id				IN	ps_category.ps_category_id%TYPE,
	in_description					IN	ps_category.description%TYPE
)AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	BEGIN
		INSERT INTO ps_category(
			ps_category_id,
			description
		) VALUES(
			in_ps_category_id,
			in_description
		);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ps_category
			   SET description          = in_description
			 WHERE ps_category_id = in_ps_category_id;		
	END;

END;

PROCEDURE CreatePSSegment (
	in_description					IN	ps_segment.description%TYPE
)AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	BEGIN
		INSERT INTO ps_segment(
			ps_segment_id,
			description
		) VALUES(
			ps_segment_id_seq.nextval,
			in_description
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;	
	END;

END;

PROCEDURE CreatePSFamily (
	in_description					IN	ps_family.description%TYPE,
	in_ps_segment					IN	ps_segment.description%TYPE
)AS
	v_ps_segment_id						ps_segment.ps_segment_id%TYPE;
BEGIN
	-- TO DO - sec checks -- though not sensitive

	SELECT ps_segment_id INTO v_ps_segment_id FROM ps_segment WHERE description = in_ps_segment;

	BEGIN
		INSERT INTO ps_family(
			ps_family_id,
			description,
			ps_segment_id
		) VALUES(
			ps_family_id_seq.nextval,
			in_description,
			v_ps_segment_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;		
	END;

END;

PROCEDURE CreatePSClass (
	in_description					IN	ps_class.description%TYPE,
	in_ps_family					IN	ps_family.description%TYPE
)AS
	v_ps_family_id					ps_family.ps_family_id%TYPE;
BEGIN
	-- TO DO - sec checks -- though not sensitive
	SELECT ps_family_id INTO v_ps_family_id FROM ps_family WHERE description = in_ps_family;

	BEGIN
		INSERT INTO ps_class(
			ps_class_id,
			description,
			ps_family_id
		) VALUES(
			ps_class_id_seq.nextval,
			in_description,
			v_ps_family_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;
	END;

END;

PROCEDURE CreatePSBrick (
	in_description					IN	ps_brick.description%TYPE,
	in_ps_class						IN	ps_class.description%TYPE,
	in_ps_category					IN	ps_category.description%TYPE,
	in_eio							IN	eio.description%TYPE
)AS
	v_ps_class_id					ps_class.ps_class_id%TYPE;
	v_ps_category_id				ps_category.ps_category_id%TYPE;
	v_eio_id						eio.eio_id%TYPE;
BEGIN
	-- TO DO - sec checks -- though not sensitive

	SELECT ps_class_id INTO v_ps_class_id FROM ps_class WHERE description = in_ps_class;
	SELECT ps_category_id INTO v_ps_category_id FROM ps_category WHERE LOWER(description) = in_ps_category;
	SELECT eio_id INTO v_eio_id FROM eio WHERE LOWER(old_description) = in_eio; -- the tagged data files we have use the old desc

	BEGIN
		INSERT INTO ps_brick(
			ps_brick_id,
			description,
			ps_class_id,
			ps_category_id,
			eio_id
		) VALUES (
			ps_brick_id_seq.nextval, 
			in_description,
			v_ps_class_id,
			v_ps_category_id,
			v_eio_id
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;	
	END;

END;

PROCEDURE CreatePSAttr (
	in_ps_brick						IN	ps_brick.description%TYPE,
	in_attribute					IN 	ps_attribute.attribute%TYPE, 
	in_ps_stem_method_id			IN  ps_attribute.ps_stem_method_id%TYPE, 
	in_ps_attribute_source_id		IN  ps_attribute.ps_attribute_source_id%TYPE, 
	in_words_in_phrase				IN  ps_attribute.words_in_phrase%TYPE
)AS
	v_ps_brick_id					ps_attribute.ps_brick_id%TYPE;
BEGIN
	-- TO DO - sec checks -- though not sensitive
	SELECT ps_brick_id INTO v_ps_brick_id FROM ps_brick WHERE description = in_ps_brick;
	CreatePSAttr(v_ps_brick_id, in_attribute, in_ps_stem_method_id, in_ps_attribute_source_id, in_words_in_phrase);
END;

PROCEDURE CreatePSAttr (
	in_ps_brick_id					IN	ps_brick.ps_brick_id%TYPE,
	in_attribute					IN 	ps_attribute.attribute%TYPE, 
	in_ps_stem_method_id			IN  ps_attribute.ps_stem_method_id%TYPE, 
	in_ps_attribute_source_id		IN  ps_attribute.ps_attribute_source_id%TYPE, 
	in_words_in_phrase				IN  ps_attribute.words_in_phrase%TYPE
)AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	BEGIN
		INSERT INTO ps_attribute(
			ps_brick_id, 
			attribute, 
			ps_stem_method_id,
			ps_attribute_source_id, 
			words_in_phrase
		) VALUES (
			in_ps_brick_id, 
			in_attribute, 
			in_ps_stem_method_id,
			in_ps_attribute_source_id, 
			in_words_in_phrase
		);
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			NULL;	
	END;

END;

PROCEDURE CreatePSAttrSource (
	in_ps_attribute_source_id			IN	ps_attribute_source.ps_attribute_source_id%TYPE,
	in_description					IN	ps_attribute_source.description%TYPE
)AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	BEGIN
		INSERT INTO ps_attribute_source(
			ps_attribute_source_id,
			description
		) VALUES(
			in_ps_attribute_source_id,
			in_description
		);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ps_attribute_source
			   SET description          = in_description
			 WHERE ps_attribute_source_id = in_ps_attribute_source_id;		
	END;

END;



PROCEDURE CreatePSStemMethod (
	in_ps_stem_method_id			IN	ps_stem_method.ps_stem_method_id%TYPE,
	in_description					IN	ps_stem_method.description%TYPE
)AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	BEGIN
		INSERT INTO ps_stem_method(
			ps_stem_method_id,
			description
		) VALUES(
			in_ps_stem_method_id,
			in_description
		);	
	EXCEPTION
		WHEN DUP_VAL_ON_INDEX THEN
			UPDATE ps_stem_method
			   SET description          = in_description
			 WHERE ps_stem_method_id = in_ps_stem_method_id;		
	END;

END;

PROCEDURE ImportPSRow
(
    in_category          IN ps_import.category%TYPE,
    in_segment_code      IN ps_import.segment_code%TYPE,
    in_segment           IN ps_import.segment%TYPE,
    in_family_code       IN ps_import.family_code%TYPE,
    in_family            IN ps_import.family%TYPE,
    in_class_code        IN ps_import.class_code%TYPE,
    in_class             IN ps_import.class%TYPE,
    in_brick_code        IN ps_import.brick_code%TYPE,
    in_brick             IN ps_import.brick%TYPE,
    in_eio_raw         IN ps_import.eio_raw%TYPE,
    in_eio_code          IN ps_import.eio_code%TYPE,
    in_eio               IN ps_import.eio%TYPE,
    in_core_attribute_raw    IN ps_import.core_attribute_raw%TYPE,
    in_core_attribute_type    IN ps_import.core_attribute_type%TYPE,
    in_core_attribute    IN ps_import.core_attribute%TYPE
)
AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
    INSERT INTO ps_import(
			category,
			segment_code,
			segment,
			family_code,
			family,
			class_code,
			class,
			brick_code,
			brick,
			eio_raw,
			eio_code,
			eio, 
			core_attribute_type, 
			core_attribute_raw,
			core_attribute
	) VALUES(
		in_category,
		in_segment_code,
		in_segment,
		in_family_code,
		in_family,
		in_class_code,
		in_class,
		in_brick_code,
		in_brick,
		in_eio_raw,
		in_eio_code,
		in_eio, 
		in_core_attribute_type,
		in_core_attribute_raw,
		in_core_attribute
	);
END;

PROCEDURE ClearPSData 
AS
BEGIN
	-- TO DO - sec checks -- though not sensitive - this is just some term matching data from publicly available stuff
	DELETE FROM ps_attribute;
	DELETE FROM ps_attribute_source;	
	DELETE FROM ps_stem_method;
	DELETE FROM ps_brick;
	DELETE FROM ps_class;
	DELETE FROM ps_family;
	DELETE FROM ps_segment;
	DELETE FROM ps_category;
	DELETE FROM ps_import;	
END;

PROCEDURE ClearStemmedAttributes
AS
BEGIN
	-- TO DO - sec checks -- though not sensitive
	DELETE FROM ps_attribute
	 WHERE ps_stem_method_id <> classification_pkg.STEM_METHOD_NONE_ALL
	   AND ps_attribute_source_id <> classification_pkg.KEYWRD_SRC_CORE_ATTR;
END;

END  stemmer_pkg;
/
