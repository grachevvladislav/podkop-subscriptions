"use strict";
"require view";
"require form";
"require fs";
"require ui";
"require poll";
"require rpc";

const commitSubscriptions = rpc.declare({
	object: "uci",
	method: "commit",
	params: ["config"],
	reject: true,
});

const countryNames = {
	RU: /russia|росси/i, US: /usa|united states/i,
	DE: /germany|deutschland/i, NL: /netherlands|holland/i, FI: /finland/i,
};

function excludedCountry(code, name) {
	if (!/^[A-Z]{2}$/.test(code)) return false;
	const flag = String.fromCodePoint(...Array.from(code, c => 0x1f1e6 + c.charCodeAt(0) - 65));
	return name.includes(flag) || Boolean(countryNames[code]?.test(name));
}

function statusText(raw) {
	const [state, timestamp, detail, accepted, skipped, filtered, duplicates = "0"] = (raw || "").trim().split("|");
	if (state === "never") return _("No update has run yet.");
	const date = timestamp ? new Date(Number(timestamp) * 1000).toLocaleString() : _("unknown time");
	if (state === "error") return _("Last update failed at %s: %s").format(date, detail);
	return _("Last update: %s — %s. Unique: %s · invalid: %s · filtered: %s · duplicates: %s").format(date, detail, accepted, skipped, filtered, duplicates);
}

return view.extend({
	async load() {
		return Promise.all([
			fs.read_direct("/etc/podkop-subscriptions/status", "text").catch(() => "never|0|never|0|0|0"),
		]);
	},

	async render(data) {
		const frequencies = [["manual", _("Manual only")], ["15m", _("Every 15 minutes")], ["1h", _("Every hour")], ["3h", _("Every 3 hours")], ["6h", _("Every 6 hours")], ["12h", _("Every 12 hours")], ["1d", _("Daily")]];
		const status = E("p", { "class": "cbi-section-descr" }, statusText(data[0]));
		const statusCells = new Map();
		async function readSourceStatus(sectionId) {
			const value = await fs.read_direct("/etc/podkop-subscriptions/source-" + sectionId + ".status", "text").catch(() => "");
			if (!value) return _("No download yet");
			const [state, last, next, detail] = value.trim().split("|");
			const date = n => new Date(Number(n) * 1000).toLocaleString();
			return (state === "ok" ? _("Downloaded") : (detail || _("Download failed"))) + " · " + date(last) +
				(last === next ? "" : " · " + _("Next scheduled attempt") + " " + date(next));
		}
		async function refreshStatus() {
			const raw = await fs.read_direct("/etc/podkop-subscriptions/status", "text").catch(() => "never|0");
			status.textContent = statusText(raw);
			await Promise.all(Array.from(statusCells, async ([id, cell]) => {
				cell.textContent = await readSourceStatus(id);
			}));
		}
		poll.add(refreshStatus, 5);
		const update = E("button", { "class": "cbi-button cbi-button-apply", "click": ui.createHandlerFn(this, async () => {
			update.disabled = true;
			try {
				const queued = await fs.exec("/usr/sbin/podkop-subscriptions", [ "request-update" ]);
				if (queued.code !== 0) throw Error(_("Could not queue update"));
				update.textContent = _("Updating…");
				while (update.isConnected) {
					await new Promise(resolve => setTimeout(resolve, 2000));
					const state = await fs.exec("/usr/sbin/podkop-subscriptions", [ "update-state" ]);
					if (state.code !== 0) throw Error(_("Could not read update state"));
					if (state.stdout.trim() === "idle") break;
				}
				await refreshStatus();
			} catch (e) { ui.addNotification(null, E("p", {}, _(String(e))), "error"); }
			finally { update.disabled = false; update.textContent = _("Update now"); }
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
		s.option(form.Flag, "use_proxy_on_failure", _("Retry through Podkop proxy"),
			_("Try a direct download first. If it fails, retry through the running local Podkop proxy."));

		s = m.section(form.GridSection, "source", _( "Subscription sources"));
		s.anonymous = true; s.addremove = true; s.sortable = true;
		s.handleModalSave = async function(modalMap, ev) {
			await modalMap.save(null, true);
			await commitSubscriptions(m.config);
			await m.load();
			await m.reset();
			await this.handleModalCancel(modalMap, ev, true);
			await refreshStatus();
		};
		let enabled = s.option(form.Flag, "enabled", _( "Enabled")); enabled.default = "1";
		s.option(form.Value, "name", _( "Name"));
		let url = s.option(form.Value, "url", _("URL"));
		url.rmempty = false; url.datatype = "url";
		const sourceSchedule = s.option(form.ListValue, "schedule", _("Update frequency"));
		sourceSchedule.default = "manual";
		sourceSchedule.rmempty = false;
		frequencies.forEach(v => sourceSchedule.value(...v));
		sourceSchedule.modalonly = true;
		const countries = s.option(form.Value, "exclude_country", _("Exclude country codes"),
			_("Space-separated codes, e.g. RU DE. Matches flags and known country names in server labels."));
		const include = s.option(form.Value, "include_regex", _("Include name regex"));
		const exclude = s.option(form.Value, "exclude_regex", _("Exclude name regex"));
		for (const field of [countries, include, exclude]) field.modalonly = true;
		const sourceStatus = s.option(form.DummyValue, "_status", _("Download status"));
		sourceStatus.load = readSourceStatus;
		sourceStatus.textvalue = function(sectionId) {
			const cell = E("span", {}, this.cfgvalue(sectionId) || _("No download yet"));
			statusCells.set(sectionId, cell);
			return cell;
		};
		const preview = s.option(form.DummyValue, "_preview", _("Downloaded links"),
			_("Indicators show this source’s filter results. Disabled sources are ignored, and matching duplicates are merged across enabled sources."));
		preview.modalonly = true;
		preview.renderWidget = async function(sectionId) {
			const raw = await fs.read_direct("/etc/podkop-subscriptions/source-" + sectionId + ".preview", "text").catch(() => "[]");
			const entries = JSON.parse(raw);
			if (!entries.length) return E("p", {}, _("Save the source and run Update now to load its links."));
			const summary = E("p");
			const list = E("ol", { style: "max-height: 22rem; overflow: auto" });
			const panel = E("div", {}, [summary, list]);
			const fields = this.section.children;
			const refresh = () => {
				const value = name => {
					const field = fields.find(option => option.option === name);
					return field?.formvalue(sectionId) ?? field?.cfgvalue(sectionId) ?? "";
				};
				let allow, deny;
				try {
					const includePattern = value("include_regex");
					const excludePattern = value("exclude_regex");
					allow = includePattern ? new RegExp(includePattern, "i") : null;
					deny = excludePattern ? new RegExp(excludePattern, "i") : null;
				} catch (_) {
					summary.textContent = _("Invalid regular expression");
					return;
				}
				const codes = L.toArray(value("exclude_country")).join(" ").toUpperCase().split(/\s+/);
				const included = [];
				const excluded = [];
				for (const { name, scheme } of entries) {
					const keep = (!allow || allow.test(name)) && (!deny || !deny.test(name)) &&
						!codes.some(code => excludedCountry(code, name));
					const row = E("li", {}, [(keep ? "✓ " : "✕ ") + (name || _("Unnamed server")) + " · " + scheme]);
					(keep ? included : excluded).push(row);
				}
				list.replaceChildren(...excluded, ...included);
				summary.textContent = _("%s of %s links match the current filters").format(included.length, entries.length);
			};
			requestAnimationFrame(() => {
				const dialog = panel.closest(".modal");
				dialog?.addEventListener("input", refresh);
				dialog?.addEventListener("change", refresh);
				refresh();
			});
			return panel;
		};

		return E([], [ E("div", { "class": "cbi-section" }, [ status, E("div", { "class": "cbi-page-actions" }, [ update, " ", check ]) ]), await m.render() ]);
	},
});

