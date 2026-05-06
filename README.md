<img width="220" height="90" alt="Group 24" src="https://github.com/user-attachments/assets/be1da57a-3116-4c35-96ea-315681611149" />

### C*ode* U*nder* R*igorous* B*oundary*

Curb provides a floating prompt for replacing the current visual selection.

## Installation

Install with your preferred plugin manager, then call:

```lua
require("curb").setup()
```

## Usage

Select text in visual mode and use one of the following:

- Run `:Curb`
- Press the configured trigger mapping

Inside the floating prompt, press the configured accept key to apply the
replacement.

## Default Configuration

```lua
require("curb").setup({
  trigger_key = "<leader>ai",
  accept_key = "<C-y>",
  highlights = {
    normal = "Normal",
    border = "Keyword",
    title_icon = "DiagnosticInfo",
    title_text = "Keyword",
    footer = "Comment",
  },
})
```

## Help

After installation, open the Neovim help with:

```vim
:help curb
```
