# Mac Terminal Title Manager

A ZSH-based terminal title manager for macOS that maintains project context across local and SSH sessions. Designed to work seamlessly with time tracking software like Manictime by providing consistent, context-aware window titles.

## Features

- **Project Context**: Associates SSH hostnames with project names
- **Persistent Storage**: Maintains project mappings in a SQLite database
- **Dynamic Terminal Titles**: 
  - Updates terminal title based on current directory
  - Sets project-aware titles for SSH sessions
  - Automatically resets title when logging out of remote servers
- **Smart Hostname Detection**: Works with various SSH connection formats
- **Time Tracking Integration**: Consistent window titles for accurate time tracking with Manictime

## Installation

1. Clone this repository:
```bash
git clone https://github.com/ctodd/mac-term-title-manager.git
cd mac-term-title-manager
```

2. Make the script executable:
```bash
chmod +x ssh_wrapper.sh
```

3. Add to your ~/.zshrc:
```bash
# Terminal Title Management
autoload -Uz add-zsh-hook
add-zsh-hook chpwd my_cd_function
function my_cd_function() {
    printf "\e]0;$PWD\a"  # Both tab and window
    PS1="@%m %1~ %#"
    # Add any other commands you want to run here

}
my_cd_function # Update title on init

# Alternative option
# function set_title() {
#     echo -ne "\e]0;${PWD/#$HOME/~}\a"
# }
# precmd_functions+=(set_title)
```

4. Source the SSH wrapper
```bash
source /path/to/ssh_wrapper.sh
```

5. Reload your shell:
```bash
source ~/.zshrc
```

## Usage

### Local Terminal
Your terminal title will automatically update to show your current directory.

### SSH Sessions
Use SSH as you normally would. The wrapper will:
1. Detect when you use the SSH command
2. Ask for a project name if the hostname is new
3. Offer existing project names for selection
4. Update your terminal title with project context
5. Reset the title when you exit the SSH session

Example commands:
```bash
ssh user@hostname
ssh -i key.pem user@hostname
ssh -l user hostname
```

## Time Tracking Integration

The consistent terminal titles make it easy to track time spent on different projects using Manictime. The titles will:
- Show local directory when working locally
- Display project name and hostname during SSH sessions
- Reset appropriately when sessions end

## How it Works

The wrapper:
1. Intercepts SSH commands
2. Maintains a SQLite database of hostname-to-project mappings
3. Sets up remote shell PROMPT_COMMAND to update terminal titles
4. Preserves all SSH arguments and functionality
5. Handles title reset on session termination

## Requirements

- macOS
- ZSH shell
- SQLite3
- Standard Unix utilities (printf, etc.)

## Debugging

Debug messages are written to stderr and can be captured with:
```bash
ssh user@host 2>ssh_debug.log
```

## Support

If you encounter any issues or have feature requests, please [open an issue](https://github.com/ctodd/mac-term-title-manager/issues) on GitHub.

## License

MIT License - Copyright (c) 2024 Chris Miller

## Acknowledgments
Anthropic Claude Sonnet 3.5 v2

This project was inspired by:
- [Reddit discussion on iTerm2 window titles](https://www.reddit.com/r/zsh/comments/jp18n3/how_to_rename_iterm2_window_title_with_zsh/)
- [cbarrick's dotfiles](https://github.com/cbarrick/dotfiles/blob/master/home/.zsh/.zshrc)
