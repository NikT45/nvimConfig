local cmp = require('cmp')
local luasnip = require('luasnip')

-- Custom source for HTML tag completion
local html_source = {}
html_source.new = function()
  return setmetatable({}, { __index = html_source })
end

html_source.get_trigger_characters = function()
  return { '>' }
end

html_source.complete = function(self, request, callback)
  local line = request.context.cursor_before_line
  local tag_match = line:match('<(%w+)[^>]*>$')

  if tag_match then
    local items = {
      {
        label = '</' .. tag_match .. '>',
        kind = cmp.lsp.CompletionItemKind.Snippet,
        insertText = '</' .. tag_match .. '>',
        detail = 'Close HTML tag',
        preselect = true,
      }
    }
    callback({ items = items, isIncomplete = false })
  else
    callback({ items = {}, isIncomplete = false })
  end
end

cmp.setup({
  snippet = {
    expand = function(args)
      luasnip.lsp_expand(args.body)
    end,
  },

  mapping = cmp.mapping.preset.insert({
    ['<C-b>'] = cmp.mapping.scroll_docs(-4),
    ['<C-f>'] = cmp.mapping.scroll_docs(4),
    ['<C-Space>'] = cmp.mapping.complete(),
    ['<C-e>'] = cmp.mapping.abort(),
    ['<CR>'] = cmp.mapping.confirm({ select = true }),

    -- Cursor-style tab completion
    ['<Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.confirm({ select = true })
      elseif luasnip.expand_or_jumpable() then
        luasnip.expand_or_jump()
      else
        fallback()
      end
    end, { 'i', 's' }),

    ['<S-Tab>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.select_prev_item()
      elseif luasnip.jumpable(-1) then
        luasnip.jump(-1)
      else
        fallback()
      end
    end, { 'i', 's' }),

    -- Escape cancels completion and exits insert mode
    ['<Esc>'] = cmp.mapping(function(fallback)
      if cmp.visible() then
        cmp.abort()
      end
      fallback()
    end, { 'i' }),
  }),

  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
    { name = 'path', priority = 250 },
  }),

  -- Auto-trigger completion more aggressively
  completion = {
    completeopt = 'menu,menuone,noinsert',
    keyword_length = 1,
    trigger_characters = { '>' },
  },

  -- Custom formatting for better visibility
  formatting = {
    format = function(entry, vim_item)
      -- Add confidence indicator
      if entry.completion_item.score and entry.completion_item.score > 0.8 then
        vim_item.abbr = vim_item.abbr .. " ★"
      end
      return vim_item
    end
  },
})

-- Register custom HTML tag source
cmp.register_source('html_tags', html_source.new())

-- Configure per-filetype sources
cmp.setup.filetype('html', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('jsx', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('tsx', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('javascript', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('typescript', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('javascriptreact', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

cmp.setup.filetype('typescriptreact', {
  sources = cmp.config.sources({
    { name = 'html_tags', priority = 1100 },
    { name = 'nvim_lsp', priority = 1000 },
    { name = 'luasnip', priority = 750 },
    { name = 'buffer', priority = 500 },
  })
})

-- Enable autopairs integration
local status_ok, cmp_autopairs = pcall(require, 'nvim-autopairs.completion.cmp')
if status_ok then
  cmp.event:on(
    'confirm_done',
    cmp_autopairs.on_confirm_done()
  )
end

-- Setup nvim-ts-autotag for auto-closing tags
local autotag_ok, autotag = pcall(require, 'nvim-ts-autotag')
if autotag_ok then
  autotag.setup()
end