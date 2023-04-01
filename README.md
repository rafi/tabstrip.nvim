# tabstrip.nvim

> Unobtrusive tabline for Neovim.

## Overview

Minimal and opinionated tabline with enough features to be efficient, but
doesn't draw too much attention.

Features:

- Project base-name at the left-corner
- Highlights are adapted from current colorscheme
- File-type and modified icons
- Session name at the right-corner

## Install

Requirements:

- [Neovim] ≥0.8
- [nvim-web-devicons]
- [plenary.nvim]

Use your favorite package-manager:

<details>
<summary>With <a href="https://github.com/folke/lazy.nvim">lazy.nvim</a></summary>

```lua
{
  'rafi/tabstrip.nvim',
  dependencies = {
    'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim'
  },
  version = false,
  config = true,
},
```

</details>

<details>
<summary>With <a href="https://github.com/wbthomason/packer.nvim">packer.nvim</a></summary>

```lua
use {
  'rafi/tabstrip.nvim',
  requires = {
    'nvim-tree/nvim-web-devicons',
    'nvim-lua/plenary.nvim'
  }
}
```

</details>

## Setup

If you're using [lazy.nvim], set `config` or `opts` property (See
[Install](#install) instructions).

Otherwise, setup manually:

```lua
require('tabstrip').setup()
```

## Config

These are the default settings:

```lua
require('tabstrip').setup({
  -- Limit display of directories in path
  max_dirs = 1,
  -- Limit display of characters in each directory in path
  directory_max_chars = 5,

  icons = {
    modified = '+',
    session = '',
  },

  colors = {
    modified = '#cf6a4c',
  },

  numeric_charset = {'⁰','¹','²','³','⁴','⁵','⁶','⁷','⁸','⁹'},
})
```

If you are using [lazy.nvim], you can use the `opts` property, _e.g._:

```lua
{
  'rafi/tabstrip.nvim',
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  version = false,
  opts = {
    directory_max_chars = 8
  },
},
```

## See More

Alternatives:

- [romgrk/barbar.nvim](https://github.com/romgrk/barbar.nvim)
- [akinsho/bufferline.nvim](https://github.com/akinsho/bufferline.nvim)
- [nanozuki/tabby.nvim](https://github.com/nanozuki/tabby.nvim)
- [kdheepak/tabline.nvim](https://github.com/kdheepak/tabline.nvim)

Enjoy!

[Neovim]: https://github.com/neovim/neovim
[nvim-web-devicons]: https://github.com/nvim-tree/nvim-web-devicons
[plenary.nvim]: https://github.com/nvim-lua/plenary.nvim
[lazy.nvim]: https://github.com/folke/lazy.nvim
