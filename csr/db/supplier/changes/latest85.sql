-- Please update version.sql too -- this keeps clean builds in sync
define version=85
@update_header

DECLARE
	v_tag_id	tag.tag_id%TYPE;
BEGIN

	-- add new "prod category" -> actually a merchant type -> called "Cross Category"
	FOR r IN (
		SELECT tag_group_sid FROM supplier.tag_group WHERE app_sid in 
		(
			SELECT app_sid FROM csr.customer WHERE ((host = 'bootssupplier.credit360.com') OR (host = 'bootstest.credit360.com') OR (host = 'bs.credit360.com'))
		)
		AND name = 'merchant_type'
	) 
	LOOP
		INSERT INTO supplier.tag (tag_id, tag, explanation) values (supplier.tag_id_seq.nextval, 'Cross Category', 'Cross Category') 
			RETURNING tag_id INTO v_tag_id;
			
		INSERT INTO supplier.tag_group_member (tag_group_sid, tag_id, pos, is_visible) VALUES (r.tag_group_sid, v_tag_id, v_tag_id, 1);
	END LOOP;

END;
/

@update_tail
