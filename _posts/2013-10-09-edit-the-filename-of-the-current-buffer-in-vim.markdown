---
layout: post
title: "Edit the Filename of the Current Buffer in Vim"
date: 2013-10-09
comments: true
tags: [Tools, Vim, Tips]
---

This blog is generated from text files that are comprised of a section of YAML code then markdown-formatted text. To convert the text files for use with new blog software I had to edit each filename and put the date the blog post was published on the front of the filename, which was in the YAML section of the file. I was looking for a solution that allowed me to preserve focus on the file contents and minimize buffer navigation while performing the rename and file edits within vim. There are a couple of ways to accomplish this. If the file is controlled by git and [fugitive.vim](https://github.com/tpope/vim-fugitive) is installed, then `:Gmove` can be used.

## Using the File Explorer
If the file is not controlled by git, an approach without vim plugins is to bring up a file explorer with `:Ex`, put the cursor on top of the file and type `R` to rename the file. The disadvantage to this approach was that focus on the file being edited was lost. I needed to see a date in the file contents to rename the file with the date in the filename. Opening the file in a split window with `:Sex` would allow the file contents to be visible, but after renaming the file the buffer that was open with the old name is still open. The buffer can be closed, and the directory can be refreshed (with NERDTree `R` refreshes the directory contents) but that involves a couple of steps. I wanted to rename the file and continue editing it in the same buffer.

## Plugin Approach
The solution I went with was to use the [rename](https://github.com/danro/rename.vim.git) plugin and keyboard commands to insert the filename of the current buffer in command mode. The rename plugin makes it easy to rename a file with `:Rename new_name` but it doesn't show the current filename. To avoid retyping or accidentally mistyping the existing filename, the keyboard commands `Ctrl-r` then `%` in command-line mode can be used to insert the current filename. The arrow keys or `Ctrl-b` can be used to move the cursor to the front (`Ctrl-e` to go to the end of the line).

The complete steps together, with the rename plugin installed, to edit the filename of the current buffer in vim:

```sh
:                  # enter command-line mode
Ctrl-r %           # insert the filename 
Ctrl-b             # move cursor to start of line
:Rename filename   # edit the filename 
```

With this process I was able to move through 20 or so files and rename them fairly quickly and accurately.

I am still new to VIM so if you have corrections or suggestions please let me know.

**Update**: A small improvement would be to visually select the date and press `y` to yank it before entering command-line mode. Then after inserting the filename and moving the cursor to the front of the filename, `Ctrl-r "` can be used to paste the last yanked value (MacVim). Another useful shortcut is `Ctrl-r Ctrl-w` to paste a highlighted selection in command-line mode. To clear out the range characters when entering command-line mode with a highlighted selection, type `Ctrl-u`.
