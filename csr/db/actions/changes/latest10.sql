alter table project add (next_id number(10) default 0  not null);

DECLARE
  TYPE T_MAX_TABLE is TABLE OF NUMBER INDEX BY PLS_INTEGER;
  t_max T_MAX_TABLE;
  v_num NUMBER;
  i PLS_INTEGER;
BEGIN
  FOR r IN (
    SELECT p.project_sid, t.internal_ref
      FROM project p, task t
     WHERE p.project_sid = t.project_sid
       AND t.internal_ref IS NOT NULL
  )
  LOOP
    BEGIN
      v_num := TO_NUMBER(r.internal_ref);
    EXCEPTION
      WHEN OTHERS THEN
        v_num := NULL;
    END;
    IF v_num IS NOT NULL THEN
      IF NOT t_max.EXISTS(r.project_sid) THEN
        t_max(r.project_sid) := v_num;
      ELSIF v_num > t_max(r.project_sid) THEN
        t_max(r.project_sid) := v_num;
      END IF;
    END IF;
  END LOOP;
  
  i := t_max.FIRST;  -- get subscript of first element
  WHILE i IS NOT NULL
  LOOP
     -- do something with courses(i) 
     DBMS_OUTPUT.PUT_LINE('Max for project sid '||i||' = '||t_max(i));
     UPDATE PROJECT SET next_id = t_max(i)+1 WHERE project_sid = i; 
     i := t_max.NEXT(i);  -- get subscript of next element
  END LOOP;
END;
/
commit;

