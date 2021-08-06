# lorem-nvim

A simple wrapper that adds a `lorem` keybind to insert mode, and types out placeholder text like in VS Code.

![lorem](./_examples/lorem.gif)

<br>



## Installation

Packer:

    use { 
        'derektata/lorem.nvim',
        requires = 'vim-scripts/loremipsum'
     }

<br>


## Setup
init.lua:
    
    require"lorem-nvim".setup()

<br>

## Usage

| Command | Mode   | Description                               |
|---------|--------|-------------------------------------------|
| `lorem` | insert | inserts placeholder text                  |
| `LI`    | normal | prompts user for how many words to insert |


<br>

## What this plugin doesn't do...yet 
It doesn't take in a number (while in insert mode) and print an exact amount of words specified.
    
- However, that's why the prompt exists...

    ![](./_examples/lorem-prompt.gif)

<br>

## Disclaimer
I'm a noob at writing neovim plugins, any tips on this would be greatly appreciated!

I only wrote this because I wanted a faster way of inserting dummy text, instead of working through a several dialog prompts.
