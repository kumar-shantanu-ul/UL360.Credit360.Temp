begin
	for r in (
		select af.app_sid, af.alert_frame_id,count(afb.alert_frame_id) from alert_frame af left join alert_frame_body afb on af.alert_frame_id = afb.alert_frame_id
		group by af.app_sid, af.alert_frame_id
		having count(afb.alert_frame_id)=0) loop
		insert into alert_frame_body (app_sid, alert_frame_id, lang, html)
			select r.app_sid, r.alert_frame_id, lang, html
			  from default_alert_frame_body
			 where lang='en-gb';
	end loop;
end;
/
