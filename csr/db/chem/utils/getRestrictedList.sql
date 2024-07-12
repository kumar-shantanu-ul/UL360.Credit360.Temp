exec user_pkg.logonadmin('&&host');

PROMPT >> cas 1,2,3 and no waiver required (not the entire list)
select distinct s.substance_id, s.ref
from chem.substance s
join chem.substance_cas sc on sc.substance_id = s.substance_id
join chem.cas_restricted cr on cr.cas_code = sc.cas_code
where cr.category = 3 and s.substance_id not in (
	select s.substance_id
	from chem.substance s
	join chem.substance_cas sc on sc.substance_id = s.substance_id
	join chem.cas_restricted cr on cr.cas_code = sc.cas_code
	where cr.category <> 3	
);

PROMPT >> cas 1,2,3 and waiver required
select s.substance_id, s.ref
from chem.substance_region sr
join chem.substance s on sr.substance_id = s.substance_id
where waiver_status_id <> 0;
