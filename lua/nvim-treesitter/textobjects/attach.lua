local configs = require "nvim-treesitter.configs"
local parsers = require "nvim-treesitter.parsers"
local queries = require "nvim-treesitter.query"
local api = vim.api
local M = {}

function M.make_attach(normal_mode_functions, submodule)
  return function(bufnr, lang)
    local config = configs.get_module("textobjects." .. submodule)
    lang = lang or parsers.get_buf_lang(bufnr)

    for _, function_call in pairs(normal_mode_functions) do
      for mapping, config_queries in pairs(config[function_call] or {}) do
        if not queries.get_query(lang, "textobjects") then
          config_queries = nil
        end
        if config_queries then
          local config_query_str
          if type(config_queries) == "string" then
            config_query_str = "'" .. config_queries .. "'"
          else
            config_query_str = "{'" .. table.concat(config_queries, "','") .. "'}"
          end

          local cmd = ":lua require'nvim-treesitter.textobjects."
            .. submodule
            .. "'."
            .. function_call
            .. "("
            .. config_query_str
            .. ")<CR>"
          api.nvim_buf_set_keymap(bufnr, "n", mapping, cmd, { silent = true, noremap = true })
        end
      end
    end
  end
end

function M.make_detach(normal_mode_functions, submodule)
  return function(bufnr)
    local config = configs.get_module("textobjects." .. submodule)
    local lang = parsers.get_buf_lang(bufnr)

    for mapping, query in pairs(config.keymaps or {}) do
      if not queries.get_query(lang, "textobjects") then
        query = nil
      end
      if query then
        api.nvim_buf_del_keymap(bufnr, "o", mapping)
        api.nvim_buf_del_keymap(bufnr, "v", mapping)
      end
    end
    for _, function_call in pairs(normal_mode_functions) do
      for mapping, query in pairs(config[function_call] or {}) do
        if type(query) == "table" then
          query = query[lang]
        elseif not queries.get_query(lang, "textobjects") then
          query = nil
        end
        if query then
          api.nvim_buf_del_keymap(bufnr, "n", mapping)
        end
      end
    end
  end
end

return M
