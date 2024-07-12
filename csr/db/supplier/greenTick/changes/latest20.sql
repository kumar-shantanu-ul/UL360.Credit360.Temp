-- Please update version.sql too -- this keeps clean builds in sync
define version=20
@update_header

-- sorts out the ordering of tags in prod type drop down on product edit page
DECLARE
    v_pos_max NUMBER;
BEGIN

    FOR r IN (
        select tag_group_sid from tag_group where name = 'product_category'
    )
    LOOP

        FOR t IN (
            SELECT rownum rn, tag_id, tag
            FROM
            (
                SELECT t.tag_id, tag 
                  FROM tag_group_member tgm, tag t 
                 WHERE t.tag_id = tgm.tag_id 
                   AND tag_group_sid = r.tag_group_sid
                 ORDER BY UPPER(tag) asc
            )
        )
        LOOP
            UPDATE tag_group_member
               SET pos = t.rn + 6
             WHERE tag_id = t.tag_id
               AND tag_group_sid = r.tag_group_sid;
        END LOOP;
    
    END LOOP;

END;
/

UPDATE tag_group_member SET pos = 1 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'containsWood'
);

UPDATE tag_group_member SET pos = 2 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'containsPulp'
);

UPDATE tag_group_member SET pos = 3 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'containsPaper'
);

UPDATE tag_group_member SET pos = 4 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'containsNaturalProducts'
);

UPDATE tag_group_member SET pos = 5 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'needsGreenTick'
);

UPDATE tag_group_member SET pos = 6 WHERE tag_id IN 
(
    SELECT tag_id FROM tag WHERE tag = 'withoutPackaging'
);



@update_tail