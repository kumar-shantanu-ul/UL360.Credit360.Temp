-- Please update version.sql too -- this keeps clean builds in sync
define version=1891
@update_header

create or replace type csr.stragg3_type as object
(
  clob_string clob,
  string varchar2(4000),
  first number(1),
  sep varchar2(1),
  use_clob number(1),
  
  static function ODCIAggregateInitialize
    ( sctx in out stragg3_type )
    return number ,

  member function ODCIAggregateIterate
    ( self  in out stragg3_type ,
      value in     varchar2
    ) return number ,

  member function ODCIAggregateTerminate
    ( self        in  stragg3_type,
      returnvalue out clob,
      flags in number
    ) return number ,

  member function ODCIAggregateMerge
    ( self in out stragg3_type,
      ctx2 in     stragg3_type
    ) return number
);
/

create or replace type body csr.stragg3_type
is

  static function ODCIAggregateInitialize
  ( sctx in out stragg3_type )
  return number
  is
  begin
  
	--check if there's any separator set, otherwise use default ',' 
    sctx := stragg3_type( null, null, 1, NVL(SYS_CONTEXT('SECURITY', 'STRAGG3_SEP'), ','), 0 ) ;
	
    dbms_lob.createtemporary(sctx.clob_string, TRUE, dbms_lob.call);
	dbms_lob.open(sctx.clob_string, dbms_lob.lob_readwrite);

    return ODCIConst.Success ;

  end;

  member function ODCIAggregateIterate
  ( self  in out stragg3_type ,
    value in     varchar2
  ) return number
  is
  begin
	
	if self.use_clob = 1 or lengthb(self.string||self.sep||value) > 4000 then
		if (self.use_clob = 0) then
			-- Gone over 4000 bytes, use clob
			dbms_lob.append(self.clob_string, ltrim( self.string, self.sep ));
			self.use_clob := 1;
		end if;

		if self.first = 0 then
		  dbms_lob.writeappend(self.clob_string, 1, self.sep);
		end if;
		
		dbms_lob.append(self.clob_string, value);
	else
		self.string := self.string || self.sep || value ;
	end if;

	self.first := 0;
	
    return ODCIConst.Success;

  end;

  member function ODCIAggregateTerminate
  ( self        in  stragg3_type ,
    returnvalue out clob ,
    flags       in  number
  ) return number
  is
  begin
    returnValue := self.clob_string;

    if self.use_clob = 0 then
		-- Aggregate fitted in varchar2(4000)
		dbms_lob.append(returnValue, ltrim( self.string, self.sep ));
    end if;
	
    return ODCIConst.Success;

  end;

  member function ODCIAggregateMerge
  ( self in out stragg3_type ,
    ctx2 in     stragg3_type
  ) return number
  is
  begin
  
	if self.use_clob = 0 then
		-- Aggregate fitted in varchar2(4000)
		dbms_lob.append(self.clob_string, ltrim( self.string, self.sep ));
		self.use_clob := 1;
	end if;
	
	if ctx2.use_clob = 0 then
		-- Other aggregate fitted in varchar2(4000)
		dbms_lob.append(self.clob_string, ltrim( ctx2.string, ctx2.sep ));
	else
		-- Other aggregate required clob
		dbms_lob.append(self.clob_string, ctx2.clob_string);
	end if;

    return ODCIConst.Success;

  end;

end;
/

create or replace function csr.stragg3
  ( input varchar2 )
  return clob
  deterministic
  parallel_enable
  aggregate using stragg3_type
;
/

CREATE OR REPLACE PROCEDURE csr.stragg3setSeparator(
	in_separator		IN		VARCHAR2 DEFAULT ','
)
AS
BEGIN
	security.security_pkg.SetContext('STRAGG3_SEP', in_separator);
END;
/


@../region_body
 
@update_tail