" Displaying the correct wordcount for tex files in vim-airline

function! airline#extensions#wordcount#formatters#custom#to_string(wordcount)
    if exists('b:tex_wordcount')
        let l:wordcount = b:tex_wordcount
    elseif exists('b:vimtex')
        let b:tex_wordcount = vimtex#misc#wordcount()
        let l:wordcount = b:tex_wordcount
    else
        let l:wordcount = a:wordcount
    endif

    return airline#extensions#wordcount#formatters#default#to_string(l:wordcount)
endfunction
