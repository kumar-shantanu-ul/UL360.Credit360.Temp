create or replace type csr.product_type as object
(
  total number,


  static function ODCIAggregateInitialize
    ( sctx in out product_type )
    return number ,

  member function ODCIAggregateIterate
    ( self  in out product_type ,
      value in     number
    ) return number ,

  member function ODCIAggregateTerminate
    ( self        in  product_type,
      returnvalue out number,
      flags in number
    ) return number ,

  member function ODCIAggregateMerge
    ( self in out product_type,
      ctx2 in     product_type
    ) return number
);
/

create or replace type body csr.product_type
is

  static function ODCIAggregateInitialize
  ( sctx in out product_type )
  return number
  is
  begin

    sctx := product_type( null ) ;

    return ODCIConst.Success ;

  end;

  member function ODCIAggregateIterate
  ( self  in out product_type ,
    value in     number
  ) return number
  is
  begin

    self.total := nvl(self.total,1) * value;
    return ODCIConst.Success;

  end;

  member function ODCIAggregateTerminate
  ( self        in  product_type ,
    returnvalue out number ,
    flags       in  number
  ) return number
  is
  begin

    returnValue := self.total;
    return ODCIConst.Success;

  end;

  member function ODCIAggregateMerge
  ( self in out product_type ,
    ctx2 in     product_type
  ) return number
  is
  begin

    self.total := nvl(self.total,1) * nvl(ctx2.total,1);
    return ODCIConst.Success;

  end;

end;
/

create or replace function csr.product
  ( input number )
  return number
  deterministic
  parallel_enable
  aggregate using product_type
;
/

