whenever sqlerror exit failure rollback 
whenever oserror exit failure rollback

DECLARE
  rootId number(10); -- FACTOR_TYPE_ID of root node
  parentId number(10); -- parent ID for factor we are about to insert
  factorName varchar2(10000);
  factorTypeId number(10);
  measureId number(10);
  
  TYPE NUMARRAY IS VARRAY(7) OF number(10);
  levelIds NUMARRAY; -- Array to store last FACTOR_TYPE_ID of each level
  lvl number(1); -- Level of Factor we are about to insert

  cursor newFactors is
       select *
       from csr.FACTOR_NEW
       order by factor_new_id;
     
BEGIN

  -- Initialise variables
  select MAX(FACTOR_TYPE_ID) + 1
  into factorTypeId
  from csr.FACTOR_TYPE;
  
  select FACTOR_TYPE_ID into rootId
  from csr.FACTOR_TYPE
  where PARENT_ID is null;
  
  levelIds := NUMARRAY(null, null, null, null, null, null, null);
  
  -- Loop over rows
  FOR fac in newFactors
  LOOP

    IF fac.LEVEL_1 IS NOT NULL THEN
       factorName := fac.LEVEL_1;
       parentId := rootId;
       lvl := 1;
    ELSIF fac.LEVEL_2 IS NOT NULL THEN
       factorName := fac.LEVEL_2;
       parentId := levelIds(1);
       lvl := 2;
    ELSIF fac.LEVEL_3 IS NOT NULL THEN
       factorName := fac.LEVEL_3;
       parentId := levelIds(2);
       lvl := 3;
    ELSIF fac.LEVEL_4 IS NOT NULL THEN
       factorName := fac.LEVEL_4;
       parentId := levelIds(3);
       lvl := 4;
    ELSIF fac.LEVEL_5 IS NOT NULL THEN
       factorName := fac.LEVEL_5;
       parentId := levelIds(4);
       lvl := 5;
    ELSIF fac.LEVEL_6 IS NOT NULL THEN
       factorName := fac.LEVEL_6;
       parentId := levelIds(5);
       lvl := 6;
    ELSIF fac.LEVEL_7 IS NOT NULL THEN
       factorName := fac.LEVEL_7;
       parentId := levelIds(6);
       lvl := 7;
    ELSIF fac.LEVEL_8 IS NOT NULL THEN
       factorName := fac.LEVEL_8;
       parentId := levelIds(7);
       lvl := 8;
    END IF;

    IF factorName IS NOT NULL THEN
      -- Set factor type id for this lvl and propagate down.
      IF lvl < 8 THEN
       FOR i IN lvl .. levelIds.COUNT LOOP
        levelIds(i) := factorTypeId;
       END LOOP;
      END IF;
      
      INSERT INTO csr.FACTOR_TYPE (PARENT_ID, NAME, FACTOR_TYPE_ID, STD_MEASURE_ID, EGRID)
      VALUES (parentId, factorName, factorTypeId, fac.MEASURE_ID, 0);
    
      factorName := NULL;
      factorTypeId := factorTypeId + 1;
    END IF;
  END LOOP;
  
  COMMIT;
END;