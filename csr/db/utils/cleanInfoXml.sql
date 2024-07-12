exec user_pkg.logonadmin('db.credit360.com');

set define off;

UPDATE customer
  SET ind_info_xml_fields = (
    WITH ind_fields AS (
        SELECT EXTRACT(VALUE(x), 'field/@name').getStringVal() field_name,
            EXTRACT(VALUE(x), 'field/@label').getStringVal() field_label
          FROM TABLE(
            XMLSEQUENCE(EXTRACT((SELECT ind_info_xml_fields FROM customer), '/ind-metadata/field'))
          )x
    )
    SELECT SYS_XMLAgg(
        XMLELEMENT("field", 
            XMLATTRIBUTES(
                field_name AS "name",
                field_label AS "label"
            )
        ),
        XMLFormat('ind-metadata'))
     FROM ind_fields
    WHERE field_name = 'Definition'
)
;

BEGIN
    FOR r IN (
        WITH ind_fields AS (
            SELECT ind_sid, EXTRACT(VALUE(x), 'field/@name').getStringVal() field_name,
                REGEXP_REPLACE(NVL(EXTRACTVALUE(VALUE(x), 'field/text()'),'Empty'),'^<!\[CDATA\[(.*)\]\]>$','\1', 1, 0, 'n') field_value        
              FROM ind, TABLE(
                 XMLSEQUENCE(EXTRACT(info_xml, '/fields/field'))
               )x
        ), fields AS (
            SELECT EXTRACT(VALUE(x), 'field/@name').getStringVal() field_name,
                EXTRACT(VALUE(x), 'field/@label').getStringVal() field_label
              FROM TABLE(
                XMLSEQUENCE(EXTRACT((SELECT ind_info_xml_fields FROM customer), '/ind-metadata/field'))
              )x
        )
        SELECT ind_sid,
            SYS_XMLAgg(
                 XMLElement("field", 
                     XMLATTRIBUTES(
                        inf.field_name AS "name"
                    ), inf.field_value
                ),
                XMLFormat('fields')
            ) info_xml
          FROM fields f JOIN ind_fields inf ON f.field_name = inf.field_name
         WHERE field_value IS NOT NULL
           AND inf.field_name = 'Definition'
           AND ind_sid =10932527
         GROUP BY ind_sid
    )
    LOOP
        UPDATE ind SET info_xml = r.info_xml WHERE ind_sid = r.ind_sid;
    END LOOP;
END;
/

