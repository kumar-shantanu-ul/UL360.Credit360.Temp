CREATE OR REPLACE PACKAGE ct.stemmer_pkg AS

/* EIO search tree / classification */

PROCEDURE CreatePSCategory (
	in_ps_category_id				IN	ps_category.ps_category_id%TYPE,
	in_description					IN	ps_category.description%TYPE
);

PROCEDURE CreatePSSegment (
	in_description					IN	ps_segment.description%TYPE
);

PROCEDURE CreatePSFamily (
	in_description					IN	ps_family.description%TYPE,
	in_ps_segment					IN	ps_segment.description%TYPE
);

PROCEDURE CreatePSClass (
	in_description					IN	ps_class.description%TYPE,
	in_ps_family					IN	ps_family.description%TYPE
);

PROCEDURE CreatePSBrick (
	in_description					IN	ps_brick.description%TYPE,
	in_ps_class						IN	ps_class.description%TYPE,
	in_ps_category					IN	ps_category.description%TYPE,
	in_eio							IN	eio.description%TYPE
);

PROCEDURE CreatePSAttr (
	in_ps_brick						IN	ps_brick.description%TYPE,
	in_attribute					IN 	ps_attribute.attribute%TYPE, 
	in_ps_stem_method_id			IN  ps_attribute.ps_stem_method_id%TYPE, 
	in_ps_attribute_source_id		IN  ps_attribute.ps_attribute_source_id%TYPE, 
	in_words_in_phrase				IN  ps_attribute.words_in_phrase%TYPE
);

PROCEDURE CreatePSAttr (
	in_ps_brick_id					IN	ps_brick.ps_brick_id%TYPE,
	in_attribute					IN 	ps_attribute.attribute%TYPE, 
	in_ps_stem_method_id			IN  ps_attribute.ps_stem_method_id%TYPE, 
	in_ps_attribute_source_id		IN  ps_attribute.ps_attribute_source_id%TYPE, 
	in_words_in_phrase				IN  ps_attribute.words_in_phrase%TYPE
);

PROCEDURE CreatePSAttrSource (
	in_ps_attribute_source_id			IN	ps_attribute_source.ps_attribute_source_id%TYPE,
	in_description					IN	ps_attribute_source.description%TYPE
);

PROCEDURE CreatePSStemMethod (
	in_ps_stem_method_id			IN	ps_stem_method.ps_stem_method_id%TYPE,
	in_description					IN	ps_stem_method.description%TYPE
);

PROCEDURE ClearPSData ;

PROCEDURE ClearStemmedAttributes;

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
);

END stemmer_pkg;
/
