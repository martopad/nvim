My neovim configuration

Requirements:
1. nvim version 0.12.1.
    - In my linux distribution tree-sitter lib is already
      installed as part of the package's dependencies.
2. tree-sitter cli.
    - To make the setup more portable, I now use a tree-sitter grammar manager so I do not
      have to worry about installing each dialect when I use a different machine
3. luarocks
    - jsregexp (for luasnip-- bootstrapping in code)

Quick note on my remote machine at work:
1. The following packages are manually downloaded and installed
    - nvim 0.12.1
    - fzf
2. The following packages are installed via cargo
    - tree-sitter cli (version pinned 25.10) - machine has older glibc

