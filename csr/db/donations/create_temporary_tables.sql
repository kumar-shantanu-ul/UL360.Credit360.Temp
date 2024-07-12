CREATE GLOBAL TEMPORARY TABLE donations.tag_condition
(
	tag_group_sid	number(10),
	tag_id			number(10)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE donations.recipient_tag_condition
(
	tag_group_sid	number(10),
	tag_id			number(10)
) ON COMMIT DELETE ROWS;

CREATE GLOBAL TEMPORARY TABLE donations.region_tag_condition
(
	tag_group_id	number(10),
	tag_id			number(10)
) ON COMMIT DELETE ROWS;





