create or replace type csr.stragg2_type as object
(
  string clob,
  first number(1),
  sep varchar2(1),
  
  static function ODCIAggregateInitialize
    ( sctx in out stragg2_type )
    return number ,

  member function ODCIAggregateIterate
    ( self  in out stragg2_type ,
      value in     clob
    ) return number ,

  member function ODCIAggregateTerminate
    ( self        in  stragg2_type,
      returnvalue out clob,
      flags in number
    ) return number ,

  member function ODCIAggregateMerge
    ( self in out stragg2_type,
      ctx2 in     stragg2_type
    ) return number
);
/

create or replace type body csr.stragg2_type
is

  static function ODCIAggregateInitialize
  ( sctx in out stragg2_type )
  return number
  is
  begin
  
	--check if there's any separator set, otherwise use default ',' 
    sctx := stragg2_type( null, 1, NVL(SYS_CONTEXT('SECURITY', 'STRAGG2_SEP'), ',') ) ;
    dbms_lob.createtemporary(sctx.string, TRUE, dbms_lob.call);
	dbms_lob.open(sctx.string, dbms_lob.lob_readwrite);

    return ODCIConst.Success ;

  end;

  member function ODCIAggregateIterate
  ( self  in out stragg2_type ,
    value in     clob
  ) return number
  is
  begin
	if self.first = 0 then
	  dbms_lob.writeappend(self.string, 1, self.sep);--',');
	end if;	
	self.first := 0;
	dbms_lob.append(self.string, value);

    return ODCIConst.Success;

  end;

  member function ODCIAggregateTerminate
  ( self        in  stragg2_type ,
    returnvalue out clob ,
    flags       in  number
  ) return number
  is
  begin

--  Can't close this, oh well...
--  dbms_lob.close(self.string);
    returnValue := self.string;

    return ODCIConst.Success;

  end;

  member function ODCIAggregateMerge
  ( self in out stragg2_type ,
    ctx2 in     stragg2_type
  ) return number
  is
  begin
	if self.first = 0 then
	  dbms_lob.writeappend(self.string, 1, self.sep);--',');
	end if;	
	-- Gets ORA-22922: nonexistent LOB value
	-- ORA-06512: at "SYS.DBMS_LOB", line 639
	-- ORA-06512: at "CSR.STRAGG3_TYPE", line 108
	-- 22922. 00000 -  "nonexistent LOB value"
	-- *Cause:    The LOB value associated with the input locator does not exist.
    --   The information in the locator does not refer to an existing LOB.
	-- *Action:   Repopulate the locator by issuing a select statement and retry
    --   the operation.
    -- I think the issue must the temporary lobs from the other parallel server
    -- session can't be seen (the lob value isn't null)
    -- Worked around by not marking the function as parallel_enable
    -- which seems to stop e.g.
    -- select /*+ parallel(ss 2) */ csr.stragg2(s) from mark.ss
    -- from failing at least.
	dbms_lob.append(self.string, ctx2.string);

    return ODCIConst.Success;

  end;

end;
/

create or replace function csr.stragg2
  ( input clob )
  return clob
  deterministic
--  parallel_enable
  aggregate using stragg2_type
;
/

CREATE OR REPLACE PROCEDURE csr.stragg2setSeparator(
	in_separator		IN		VARCHAR2 DEFAULT ','
)
AS
BEGIN
	security.security_pkg.SetContext('STRAGG2_SEP', in_separator);
END;
/