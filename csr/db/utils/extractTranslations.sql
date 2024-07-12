exec user_pkg.logonadmin('volkerwessels.credit360.com');

select original, translated from (
select trim(replace(tl.original,CHR(10), '')) original, td.translated, 
	row_number() over (partition by trim(replace(tl.original,CHR(10), '')) order by trim(replace(tl.original,CHR(10), ''))) rn
  from aspen2.TRANSLATION tl
    join aspen2.translated td 
        ON tl.original_hash = td.original_hash
        and tl.application_sid = td.application_sid
 where tl.application_sid = security_pkg.getapp
   and td.lang like 'fr%'
    and original != translated
    ) where rn = 1
    order by original;