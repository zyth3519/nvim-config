return {
	"saghen/blink.cmp",
	dependencies = { "rafamadriz/friendly-snippets" },
	event = { "BufReadPost", "BufNewFile" },
	version = "1.*",
	opts = {
		keymap = {
			preset = "none",
			["<cr>"] = { "select_and_accept", "fallback" },
			["<Up>"] = { "select_prev", "fallback" },
			["<Down>"] = { "select_next", "fallback" },
			["<C-p>"] = { "select_prev", "fallback_to_mappings" },
			["<C-n>"] = { "select_next", "fallback_to_mappings" },
			["<C-b>"] = { "scroll_documentation_up", "fallback" },
			["<C-f>"] = { "scroll_documentation_down", "fallback" },
			["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
		},
		appearance = { nerd_font_variant = "mono" },
		completion = { documentation = { auto_show = true } },
		sources = { default = { "lsp", "path", "snippets", "buffer" } },
		signature = { enabled = true },
		fuzzy = {
			implementation = "prefer_rust_with_warning",
			sorts = {
				"exact",
				-- 降低下划线开头的条目优先级 (如 _private_var)
				function(a, b)
					local _, a_under = a.label:find("^_+")
					local _, b_under = b.label:find("^_+")
					a_under = a_under or 0
					b_under = b_under or 0
					if a_under > b_under then
						return false
					elseif a_under < b_under then
						return true
					end
				end,
				-- 当前缓冲区里的变量/字段，通常应当优先于同名的函数或模块项。
				function(a, b)
					local kinds = require("blink.cmp.types").CompletionItemKind
					local variable_like = {
						[kinds.Variable] = true,
						[kinds.Field] = true,
						[kinds.Property] = true,
						[kinds.Value] = true,
					}

					if variable_like[a.kind] and not variable_like[b.kind] then
						return true
					elseif not variable_like[a.kind] and variable_like[b.kind] then
						return false
					end
				end,
				"score",
				"sort_text",
			},
		},
	},
	opts_extend = { "sources.default" },
}
