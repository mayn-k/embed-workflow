-- lua/plugins/lspconfig.lua — nvim 0.11+ API
return {
    "neovim/nvim-lspconfig",
    dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
    },
    config = function()
        local capabilities = vim.lsp.protocol.make_client_capabilities()
        local ok_cmp, cmp_nvim_lsp = pcall(require, "cmp_nvim_lsp")
        if ok_cmp then
            capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
        end

        -- Configure clangd via the new vim.lsp.config API
        vim.lsp.config("clangd", {
            capabilities = capabilities,
            cmd = {
                "clangd",
                "--background-index",
                "--clang-tidy",
                "--header-insertion=never",
                "--completion-style=detailed",
                "--function-arg-placeholders",
                "--offset-encoding=utf-16",
                "--query-driver=/usr/bin/arm-none-eabi-*,/usr/local/bin/arm-none-eabi-*",
            },
            filetypes = { "c", "cpp", "h" },
            root_markers = { "compile_commands.json", "compile_flags.txt", ".git", "Makefile" },
            init_options = {
                usePlaceholders = true,
                completeUnimported = true,
                clangdFileStatus = true,
            },
        })

        -- Enable it (replaces the old lspconfig.clangd.setup{} call)
        vim.lsp.enable("clangd")

        -- LSP keymaps on attach
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local buf = args.buf
                local map = function(mode, lhs, rhs, desc)
                    vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc })
                end
                map("n", "gd",         vim.lsp.buf.definition,     "LSP: definition")
                map("n", "gD",         vim.lsp.buf.declaration,    "LSP: declaration")
                map("n", "gr",         vim.lsp.buf.references,     "LSP: references")
                map("n", "gi",         vim.lsp.buf.implementation, "LSP: implementation")
                map("n", "K",          vim.lsp.buf.hover,          "LSP: hover")
                map("n", "<C-k>",      vim.lsp.buf.signature_help, "LSP: signature")
                map("n", "<leader>rn", vim.lsp.buf.rename,         "LSP: rename")
                map("n", "<leader>ca", vim.lsp.buf.code_action,    "LSP: code action")
                map("n", "<leader>fo", function() vim.lsp.buf.format({ async = true }) end, "LSP: format")
                map("n", "[d",         vim.diagnostic.goto_prev,   "Diag: prev")
                map("n", "]d",         vim.diagnostic.goto_next,   "Diag: next")
            end,
        })

        vim.diagnostic.config({
            virtual_text = { prefix = "●" },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = { border = "rounded", source = true },
        })
    end,
}
