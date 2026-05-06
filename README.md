<svg width="220" height="90" viewBox="0 0 220 90" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="10" y="10" width="200" height="70" fill="black"/>
<path d="M50 70H30V60H50V70Z" fill="#FFBD89"/>
<path d="M90 70H70V60H90V70Z" fill="#FFBD89"/>
<path d="M140 30H120V50H140V60H120V70H110V20H140V30Z" fill="#FFBD89"/>
<path d="M150 70H140V60H150V70Z" fill="#FFBD89"/>
<path d="M190 30H170V40H190V50H170V60H190V70H160V20H190V30Z" fill="#FFBD89"/>
<path d="M30 60H20V30H30V60Z" fill="#FFBD89"/>
<path d="M70 60H60V20H70V60Z" fill="#FFBD89"/>
<path d="M100 60H90V20H100V60Z" fill="#FFBD89"/>
<path d="M200 60H190V50H200V60Z" fill="#FFBD89"/>
<path d="M150 50H140V30H150V50Z" fill="#FFBD89"/>
<path d="M200 40H190V30H200V40Z" fill="#FFBD89"/>
<path d="M50 30H30V20H50V30Z" fill="#FFBD89"/>
<path fill-rule="evenodd" clip-rule="evenodd" d="M210 10H220V80H210V90H10V80H0V10H10V0H210V10ZM20 20H10V70H20V80H200V70H210V20H200V10H20V20Z" fill="#373737"/>
</svg>

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
