My neovim configuration

Requirements:
1. nvim version 0.12.1.
    - In my linux distribution tree-sitter lib is already
      installed as part of the package's dependencies.
2. Tree-sitter grammar libs.
    - Since nvim itself has tree-sitter integration, it
      is better to just install the grammar libs to the
      system instead of relying on plugins.
    - According to the docs https://neovim.io/doc/user/treesitter/#treesitter-parsers, some grammar libs are included by default. The recipe I use follows these specs. The grammar libs are installed already:
      - tree-sitter-c
      - tree-sitter-lua
      - tree-sitter-markdown
      - tree-sitter-vim
