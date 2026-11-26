# Vendor plugins at build time instead of a runtime plugin manager

Plugins are pinned git checkouts copied into the image at build time, loaded from Neovim's native `pack/*/start/` directory. A runtime plugin manager such as lazy.nvim or `vim.pack` would fetch on startup, which needs network access and would break the air gap. Updates are deliberate rebuilds, so the trade-off is slower plugin updates in exchange for a container that behaves the same with or without a network.
