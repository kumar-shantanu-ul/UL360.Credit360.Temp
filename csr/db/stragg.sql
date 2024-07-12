create or replace type csr.stragg_type as object
(
  string varchar2(4000),

  static function ODCIAggregateInitialize
    ( sctx in out stragg_type )
    return number ,

  member function ODCIAggregateIterate
    ( self  in out stragg_type ,
      value in     varchar2
    ) return number ,

  member function ODCIAggregateTerminate
    ( self        in  stragg_type,
      returnvalue out varchar2,
      flags in number
    ) return number ,

  member function ODCIAggregateMerge
    ( self in out stragg_type,
      ctx2 in     stragg_type
    ) return number
);
/

create or replace type body csr.stragg_type
is

  static function ODCIAggregateInitialize
  ( sctx in out stragg_type )
  return number
  is
  begin

    sctx := stragg_type( null ) ;

    return ODCIConst.Success ;

  end;

  member function ODCIAggregateIterate
  ( self  in out stragg_type ,
    value in     varchar2
  ) return number
  is
  BUFFER_TOO_SMALL			exception;
  pragma exception_init(BUFFER_TOO_SMALL, -6502);
  begin
  
    begin
        if substrb(self.string, -3, 3) != '...' or substrb(self.string, -3, 3) is null then
            self.string := self.string || ',' || value;
        end if;
    exception
        when BUFFER_TOO_SMALL then
                self.string := substrb(self.string, 1, 3997) || '...';
        when others then
            raise;
    end;

    return ODCIConst.Success;

  end;

  member function ODCIAggregateTerminate
  ( self        in  stragg_type ,
    returnvalue out varchar2 ,
    flags       in  number
  ) return number
  is
  begin

    returnValue := ltrim( self.string, ',' );

    return ODCIConst.Success;

  end;

  member function ODCIAggregateMerge
  ( self in out stragg_type ,
    ctx2 in     stragg_type
  ) return number
  is
  begin

    self.string := self.string || ctx2.string;

    return ODCIConst.Success;

  end;

end;
/

create or replace function csr.stragg
  ( input varchar2 )
  return varchar2
  deterministic
  parallel_enable
  aggregate using stragg_type
;
/

