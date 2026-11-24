# podkop-subscriptions

OpenWrt/LuCI module that keeps Podkop's single URLTest section populated from
HTTPS subscriptions.  It downloads plain or Base64-encoded share links,
decodes links with the installed `sing-box`, filters them, validates a
candidate configuration, and only then applies it.

## Safety model

* the current working configuration is retained for every failed download,
  empty filtered result, or failed validation;
* invalid individual links are skipped and reported;
* source URLs and links are never written to syslog;
* all state is root-readable only;
* a lock prevents concurrent manual and scheduled updates;
* a restart is performed only after a semantic change in decoded outbounds.

The package owns `podkop.main.urltest_proxy_links`. Do not edit that option by
hand while subscriptions are enabled.

## Development

Run the portable test suite:

```sh
make test
```

Build an `.ipk` with the OpenWrt SDK image selected in `docker/Makefile`:

```sh
make sdk-build
```

No package installation is performed by either command.

