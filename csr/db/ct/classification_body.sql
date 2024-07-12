CREATE OR REPLACE PACKAGE BODY ct.classification_pkg AS



PROCEDURE GetOriginalTreeText(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TO DO - sec checks -- though not sensitive

	OPEN out_cur FOR 
		SELECT 
			DISTINCT
				ps_category_id,
				ps_category,
				ps_segment_id,
				ps_segment,
				ps_family_id,   
				ps_family,    
				ps_class_id, 
				ps_class,    
				t.ps_brick_id,   
				ps_brick,  
				eio_id,
				eio, 
				eio_long, 
				ps_attribute_source_id,
				ps_stem_method_id,
				attribute
		FROM v$ps_flat_tree t
		LEFT JOIN ps_attribute a ON t.ps_brick_id = a.ps_brick_id
	   WHERE NVL(ps_stem_method_id, STEM_METHOD_NONE_ALL) = STEM_METHOD_NONE_ALL
	     AND NVL(ps_attribute_source_id, KEYWRD_SRC_CORE_ATTR) = KEYWRD_SRC_CORE_ATTR
	   ORDER BY t.ps_brick_id;
END;

PROCEDURE GetBricks(
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN
	-- TO DO - sec checks -- though not sensitive

	OPEN out_cur FOR 
		SELECT 
			DISTINCT
				ps_category_id,
				ps_category,
				ps_segment_id,   
				ps_segment,
				ps_family_id, 
				ps_family,    
				ps_class_id,    
				ps_class,    
				ps_brick_id,
				ps_brick,  
				eio_id,
				eio, 
				eio_long
		FROM v$ps_flat_tree;
END;

PROCEDURE GetBrickMatchesForTerm(
	in_word							IN ps_attribute.attribute%TYPE,
	in_ps_attribute_source_id		IN ps_attribute.ps_attribute_source_id%TYPE,
	in_ps_stem_method_id			IN ps_attribute.ps_stem_method_id%TYPE,
	in_match_method_id				IN NUMBER,
	in_threshold					IN NUMBER,	
	out_cur 						OUT security_pkg.T_OUTPUT_CUR
)
AS
BEGIN 
	-- TO DO - sec checks -- though not sensitive

	OPEN out_cur FOR
		SELECT DISTINCT psb.ps_brick_id, psb.eio_id, psa.attribute, weight
		  FROM ps_attribute psa
		  JOIN ps_brick psb ON psb.ps_brick_id = psa.ps_brick_id
		  JOIN (
			-- words have different weightings
				SELECT attribute, round((1/cnt), 10) weight 
				  FROM 
					(		  
						 SELECT COUNT(*) cnt, attribute 
						   FROM 
							(
							SELECT DISTINCT e.eio_id, a.attribute
							  FROM ps_attribute a
							  JOIN ps_brick b ON a.ps_brick_id = b.ps_brick_id
							  JOIN eio e ON b.eio_id = e.eio_id
							 WHERE ps_attribute_source_id = in_ps_attribute_source_id
							   AND ps_stem_method_id = in_ps_stem_method_id
							) 
						 GROUP BY attribute
						 ORDER BY cnt DESC
					)
		  ) w ON w.attribute = psa.attribute
		 WHERE psa.ps_stem_method_id = in_ps_stem_method_id
           AND psa.ps_attribute_source_id = in_ps_attribute_source_id
           AND 	(((in_match_method_id = 1) AND (psa.attribute = in_word)) OR
				((in_match_method_id = 2) AND (UTL_MATCH.EDIT_DISTANCE_SIMILARITY(in_word, psa.attribute) >= in_threshold)) OR
				((in_match_method_id = 3) AND (UTL_MATCH.JARO_WINKLER_SIMILARITY(in_word, psa.attribute) >= in_threshold)));
				
				-- to do - change to use match score as weighting
END;

END  classification_pkg;
/
