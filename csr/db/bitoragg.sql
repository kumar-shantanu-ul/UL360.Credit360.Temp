/* http://radino.eu/2008/05/31/bitwise-or-aggregate-function/ */
CREATE OR REPLACE TYPE csr.bitor_impl AS OBJECT
(
  bitor NUMBER,

  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER,

  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER
)
/

CREATE OR REPLACE TYPE BODY csr.bitor_impl IS
  STATIC FUNCTION ODCIAggregateInitialize(ctx IN OUT bitor_impl) RETURN NUMBER IS
  BEGIN
    ctx := bitor_impl(0);
    RETURN ODCIConst.Success;
  END ODCIAggregateInitialize;

  MEMBER FUNCTION ODCIAggregateIterate(SELF  IN OUT bitor_impl,
                                       VALUE IN NUMBER) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + VALUE - bitand(SELF.bitor, VALUE);
    RETURN ODCIConst.Success;
  END ODCIAggregateIterate;

  MEMBER FUNCTION ODCIAggregateMerge(SELF IN OUT bitor_impl,
                                     ctx2 IN bitor_impl) RETURN NUMBER IS
  BEGIN
    SELF.bitor := SELF.bitor + ctx2.bitor - bitand(SELF.bitor, ctx2.bitor);
    RETURN ODCIConst.Success;
  END ODCIAggregateMerge;

  MEMBER FUNCTION ODCIAggregateTerminate(SELF        IN OUT bitor_impl,
                                         returnvalue OUT NUMBER,
                                         flags       IN NUMBER) RETURN NUMBER IS
  BEGIN
    returnvalue := SELF.bitor;
    RETURN ODCIConst.Success;
  END ODCIAggregateTerminate;
END;
/

CREATE OR REPLACE FUNCTION csr.bitoragg(x IN NUMBER) RETURN NUMBER
PARALLEL_ENABLE
AGGREGATE USING bitor_impl;
/