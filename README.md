# TackQuote for Shopware 6

Shopware 6 integrations for [TackQuote](https://tackquote.com) B2B quoting.

Part of the TackQuote integrations index:
[github.com/tackquote](https://github.com/tackquote).

| Directory | What it is | Release asset |
| --- | --- | --- |
| [`TackQuote/`](TackQuote/README.md) | Self-hosted platform plugin (storefront Request a Quote button, B2B quote-only mode) | [`tack-shopware.zip`](https://github.com/tackquote/shopware/releases/latest/download/tack-shopware.zip) |
| [`TackQuoteApp/`](TackQuoteApp/README.md) | App-system app, installable on Shopware Cloud | [`tack-shopware-app.zip`](https://github.com/tackquote/shopware/releases/latest/download/tack-shopware-app.zip) |

[`docs/SHOPWARE_APP_PROTOCOL.md`](docs/SHOPWARE_APP_PROTOCOL.md) documents the
app registration and signing protocol, verified against Shopware's own source.

## Building

```bash
bash scripts/package.sh        # -> dist/tack-shopware.zip, dist/tack-shopware-app.zip
```

Releases are built by `.github/workflows/release.yml` on every `v*` tag push;
never upload a hand-built zip. `tack-shopware-app.zip` is a template without the
app secret; see [`TackQuoteApp/README.md`](TackQuoteApp/README.md) for building a
signed zip.

## License

MIT, see [LICENSE](LICENSE).
