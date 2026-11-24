"use strict";
"require view";
"require form";
"require fs";
"require ui";

function statusText(raw) {
	const [state, timestamp, detail, accepted, skipped, filtered] = (raw || "").trim().split("|");
	if (state === "never") return _("No update has run yet.");
	const date = timestamp ? new Date(Number(timestamp) * 1000).toLocaleString() : _("unknown time");
	if (state === "error") return _("Last update failed at %s: %s").format(date, detail);
	return _("Last update: %s — %s; applied: %s, skipped: %s, filtered: %s").format(date, detail, accepted, skipped, filtered);
}

return view.extend({
	async load() {
		return Promise.all([
			fs.read_direct("/etc/podkop-subscriptions/status", "text").catch(() => "never|0|never|0|0|0"),
		]);
	},

	async render(data) {
		const status = E("p", { "class": "cbi-section-descr" }, statusText(data[0]));
		const update = E("button", { "class": "cbi-button cbi-button-apply", "click": ui.createHandlerFn(this, async () => {
			update.disabled = true;
			try {
				await fs.exec("/usr/sbin/podkop-subscriptions", [ "update" ]);
				window.location.reload();
			} catch (e) { ui.addNotification(null, E("p", {}, _(String(e))), "error"); }
			finally { update.disabled = false; }
		}) }, _( "Update now"));
		const check = E("button", { "class": "cbi-button", "click": ui.createHandlerFn(this, async () => {
			check.disabled = true;
			try { await fs.exec("/usr/sbin/podkop-subscriptions", [ "check" ]); window.location.reload(); }
			catch (e) { ui.addNotification(null, E("p", {}, _(String(e))), "error"); }
			finally { check.disabled = false; }
		}) }, _( "Check configuration"));

		const m = new form.Map("podkop-subscriptions", _( "Podkop subscriptions"), _( "Subscription links are applied to Podkop's main URLTest section. A failed update keeps the currently working links."));
		let s = m.section(form.NamedSection, "main", "settings", _( "Update settings"));
		s.option(form.Flag, "enabled", _( "Enable subscriptions"));
		let schedule = s.option(form.ListValue, "schedule", _( "Update frequency"));
		[["manual", _( "Manual only")], ["15m", _( "Every 15 minutes")], ["1h", _( "Every hour")], ["3h", _( "Every 3 hours")], ["6h", _( "Every 6 hours")], ["12h", _( "Every 12 hours")], ["1d", _( "Daily")]].forEach(v => schedule.value(...v));
		s.option(form.Flag, "use_proxy_on_failure", _( "Retry through Podkop proxy"));
		let countries = s.option(form.DynamicList, "exclude_country", _( "Exclude countries"), _( "Country codes. Built-in labels: RU, US, DE, NL, FI. Use a regex below for all other countries."));
		countries.placeholder = "RU";
		let include = s.option(form.Value, "include_regex", _( "Include name regex")); include.optional = true;
		let exclude = s.option(form.Value, "exclude_regex", _( "Exclude name regex")); exclude.optional = true;

		s = m.section(form.GridSection, "source", _( "Subscription sources"));
		s.anonymous = true; s.addremove = true; s.sortable = true;
		let enabled = s.option(form.Flag, "enabled", _( "Enabled")); enabled.default = "1";
		s.option(form.Value, "name", _( "Name"));
		let url = s.option(form.Value, "url", _( "HTTPS URL"));
		url.rmempty = false; url.datatype = "url";

		return E([], [ E("div", { "class": "cbi-section" }, [ status, E("div", { "class": "cbi-page-actions" }, [ update, " ", check ]) ]), await m.render() ]);
	},
});

