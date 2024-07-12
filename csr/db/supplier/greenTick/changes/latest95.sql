-- Please update version.sql too -- this keeps clean builds in sync
define version=95
@update_header

-- ISSUE WITH 94 - this corrects it
BEGIN
	FOR r IN (
		select tag_id from tag where tag in (
				select '(Fm) ' || description from gt_product_type where gt_product_type_id in (
			2	,
			128	,
			80	,
			81	,
			82	,
			87	,
			88	,
			99	,
			102	,
			103	,
			104	,
			105	,
			106	,
			107	,
			108	,
			109	,
			110	,
			111	,
			119	,
			120	,
			121	,
			122	,
			123	,
			124	,
			125	,
			126	,
			127	,
			62	)
		)
	)
	LOOP
		DELETE FROM tag_tag_attribute WHERE tag_id = r.tag_id;			
		DELETE FROM tag_group_member WHERE tag_id = r.tag_id;	
		DELETE FROM questionnaire_tag WHERE tag_id = r.tag_id;	
		DELETE FROM gt_tag_product_type WHERE tag_id = r.tag_id;			
		DELETE FROM tag WHERE tag_id = r.tag_id;
		--DBMS_OUTPUT.PUT_LINE(r.tag_id);
	END LOOP;
END; 
/

@update_tail
