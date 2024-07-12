
DECLARE
    v_cnt NUMBER(10) := 0;
BEGIN
    user_pkg.logonadmin('imi.credit360.com');
    FOR r IN (
        SELECT region_sid, name, replace(replace(EXTRACT(VALUE(x),'field/text()').getStringVal(),'<![CDATA['),']]>') location_code
          FROM region, TABLE(XMLSEQUENCE(EXTRACT(INFO_XML,'/fields/field')))x
         WHERE EXTRACT(VALUE(x),'field/@name').getStringVal() = 'location_code'
           AND replace(replace(EXTRACT(VALUE(x),'field/text()').getStringVal(),'<![CDATA['),']]>') IS NOT NULL
           AND active = 1
    )
    LOOP
        UPDATE imp_region SET maps_to_region_sid = r.region_sid WHERE description = r.location_code;
        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO imp_region (imp_region_id, description, maps_to_region_sid, app_sid)
                VALUES (imp_region_id_seq.nextval, r.location_code, r.region_sid, SYS_CONTEXT('SECURITY','APP'));
        END IF;
        v_cnt := v_cnt + 1;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE(v_cnt||' mapped');
END;
/
