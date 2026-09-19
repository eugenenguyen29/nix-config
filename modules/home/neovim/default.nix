{
  pkgs,
  pkgs-unstable,
  ...
}:
{
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    sideloadInitLua = true;
    withPython3 = false;
    withRuby = false;
    withNodeJs = false;
    plugins = with pkgs.vimPlugins; [
      # C Sharp stuff
      roslyn-nvim
      rzls-nvim

      luasnip

      # Odin stuff
      # ols

      telescope-fzf-native-nvim
      telescope-nvim
      nvim-treesitter-textobjects
      (nvim-treesitter.withPlugins (
        plugins: with plugins; [
          nix
          lua
          luadoc
          c_sharp
          razor
          typescript
          javascript
          tsx
          vue
          jsdoc
          git_config
          gitignore
          html
          python
          htmldjango
          jq
          just
          markdown
          markdown_inline
          php
          sql
          toml
          yaml
          odin
        ]
      ))
    ];
    extraPackages = with pkgs; [
      # needed to compile fzf-native for telescope-fzf-native.nvim
      gcc
      gnumake
      tree-sitter

      # language servers
      pkgs-unstable.nixd
      lua-language-server
      pkgs-unstable.just-lsp
      pkgs-unstable.marksman

      # default formatter & linter
      pkgs-unstable.hujsonfmt
      pkgs-unstable.nixfmt
      stylua

      llvm
    ];
  };
}
