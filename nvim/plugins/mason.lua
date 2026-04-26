-- lua/plugins/mason.lua
-- Installs and manages LSP servers, DAP adapters, linters, formatters.
-- You'll use Mason to install: clangd (C LSP), lua_ls (optional).
return {
    {
        "williamboman/mason.nvim",
        config = function()
            require("mason").setup({
                ui = {
                    border = "rounded",
                    icons = {
                        package_installed = "✓",
                        package_pending   = "➜",
                        package_uninstalled = "✗",
                    },
                },
            })
        end,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        dependencies = { "williamboman/mason.nvim" },
        config = function()
            require("mason-lspconfig").setup({
                ensure_installed = { "clangd" },
                automatic_installation = true,
                automatic_enable = true,  -- ← ADD THIS LINE
            })
        end,
    },
}
