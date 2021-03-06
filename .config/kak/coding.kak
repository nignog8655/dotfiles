evaluate-commands %sh{kak-lsp --kakoune -s $kak_session}
lsp-auto-hover-insert-mode-enable
lsp-auto-hover-enable

set-option global grepcmd 'ag --column --hidden -f'

# Commands

define-command disable-autolint -docstring 'disable auto-lint' %{
    lint-disable
    unset-option window lintcmd
    remove-hooks window lint
}

define-command disable-autoformat -docstring 'disable auto-format' %{
    unset-option window formatcmd
    remove-hooks window format
}


# Hooks

hook global BufOpenFile  .* modeline-parse
hook global BufCreate    .* editorconfig-load
hook global BufWritePre  .* %{ nop %sh{ mkdir -p $(dirname "$kak_hook_param") }}
hook global BufWritePost .* %{ git show-diff }
hook global BufReload    .* %{ git show-diff }
hook global WinCreate    .* auto-pairs-enable
hook global WinDisplay   .* %{ evaluate-commands %sh{
    cd "$(dirname "$kak_buffile")"
    project_dir="$(git rev-parse --show-toplevel 2>/dev/null)"
    [ -n "$project_dir" ] && dir="$project_dir" || dir="${PWD%/.git}"
    printf "cd %%{%s}\n" "$dir"
    [ -n "$project_dir" ] && printf "git show-diff"
} }


hook global WinSetOption filetype=.* %{
    disable-autoformat
    disable-autolint

    hook window -group format BufWritePre .* %{ try %{ execute-keys -draft \%s\h+$<ret>d } }
}

hook global WinSetOption filetype=python %{
    set-option buffer formatcmd 'black -q -'
    hook window -group format BufWritePre .* format

    set-option window lintcmd 'pylint --msg-template="{path}:{line}:{column}: {category}: {msg}" -rn -sn'
    lint-enable
    lint
    hook window -group lint BufWritePost .* lint
}

hook global WinSetOption filetype=go %{
    hook window -group format BufWritePost .* %{ evaluate-commands %sh{ goimports -e -w "$kak_buffile" }; edit! }

    set-option window lintcmd "run() { golint $1; go vet $1 2>&1 | sed -E 's/: /: error: /'; } && run"
    lint-enable
    lint
    hook window -group lint BufWritePost .* lint
}

hook global WinSetOption filetype=(javascript|typescript|css|scss|json|markdown|yaml) %{
    set-option window formatcmd "prettier --stdin-filepath=${kak_buffile}"
    hook window -group format BufWritePre .* format
}

hook global WinSetOption filetype=markdown %{
    set-option -add buffer auto_pairs_surround _ _ * *
}

hook global WinSetOption filetype=sh %{
    set-option window lintcmd 'shellcheck -x -fgcc'
    lint-enable
    lint
}
