CREATE OR REPLACE TYPE csr.IntArray AS VARRAY(25) OF INTEGER;
/

CREATE OR REPLACE TYPE csr.Stack AS OBJECT ( 
   max_size INTEGER, 
   top      INTEGER,
   position IntArray,
   MEMBER PROCEDURE initialize,
   MEMBER FUNCTION full RETURN BOOLEAN,
   MEMBER FUNCTION empty RETURN BOOLEAN,
   MEMBER PROCEDURE push (n IN INTEGER),
   MEMBER PROCEDURE pop (n OUT INTEGER)
);
/


CREATE OR REPLACE TYPE BODY csr.Stack AS 
   MEMBER PROCEDURE initialize IS
   BEGIN
      top := 0;
      /* Call constructor for varray and set element 1 to NULL. */
      position := IntArray(NULL);
      max_size := position.LIMIT;  -- get varray size constraint
      position.EXTEND(max_size - 1, 1); -- copy element 1 into 2..25
   END initialize;

   MEMBER FUNCTION full RETURN BOOLEAN IS 
   BEGIN
      RETURN (top = max_size);  -- return TRUE if stack is full
   END full;

   MEMBER FUNCTION empty RETURN BOOLEAN IS 
   BEGIN
      RETURN (top = 0);  -- return TRUE if stack is empty
   END empty;

   MEMBER PROCEDURE push (n IN INTEGER) IS 
   BEGIN
      IF NOT full THEN
         top := top + 1;  -- push integer onto stack
         position(top) := n;
      ELSE  -- stack is full
         RAISE_APPLICATION_ERROR(-20101, 'stack overflow');
      END IF;
   END push;

   MEMBER PROCEDURE pop (n OUT INTEGER) IS
   BEGIN
      IF NOT empty THEN
         n := position(top);
         top := top - 1;  -- pop integer off stack
      ELSE  -- stack is empty
         RAISE_APPLICATION_ERROR(-20102, 'stack underflow');
      END IF;
   END pop;
END;
/

