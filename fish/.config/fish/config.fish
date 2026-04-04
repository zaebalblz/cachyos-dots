if status is-interactive
    # Starship custom prompt
    # Starship init fish | source

    # Direnv + Zoxide
    command -v direnv &> /dev/null && direnv hook fish | source
    command -v zoxide &> /dev/null && zoxide init fish --cmd cd | source

    # Better ls
    alias ls='eza --icons --group-directories-first -1'

    # Abbrs
    abbr lg 'lazygit'
    abbr gd 'git diff'
    abbr ga 'git add .'
    abbr gc 'git commit -am'
    abbr gl 'git log'
    abbr gs 'git status'
    abbr gst 'git stash'
    abbr gsp 'git stash pop'
    abbr gp 'git push'
    abbr gpl 'git pull'
    abbr gsw 'git switch'
    abbr gsm 'git switch main'
    abbr gb 'git branch'
    abbr gbd 'git branch -d'
    abbr gco 'git checkout'
    abbr gsh 'git show'

    abbr l 'ls'
    abbr ll 'ls -l'
    abbr la 'ls -a'
    abbr lla 'ls -la'
    abbr hs '~/Документы/scripts/hydra_saves.sh'
    abbr hss '~/Документы/scripts/hydra_saves.sh status'
    abbr hsb '~/Документы/scripts/hydra_saves.sh backup'
    abbr hsl '~/Документы/scripts/hydra_saves.sh list'
    abbr hsr '~/Документы/scripts/hydra_saves.sh restore'



    # Custom colours
#    cat ~/.local/state/caelestia/sequences.txt 2> /dev/null

    # For jumping between prompts in foot terminal
    function mark_prompt_start --on-event fish_prompt
        echo -en "\e]133;A\e\\"
    end
end


   alias pac='sudo pacman -S'
   alias ff='fastfetch'
   alias gt='git clone'
   alias cl='clear'
   alias key 'sudo nano ~/.config/hypr/hyprland/keybinds.conf'
   alias var 'sudo nano ~/.config/hypr/variables.conf'
   alias execs 'sudo nano ~/.config/hypr/hyprland/execs.conf'
   alias rule 'sudo nano ~/.config/hypr/hyprland/rules.conf'
   alias monitor 'sudo nano ~/.config/hypr/hyprland/monitor.conf'
   alias hyprconf 'sudo nano ~/.config/hypr/hyprland.conf'
   alias fishconf 'sudo nano ~/.config/fish/config.fish' 
   alias cm 'cmatrix'
   alias pipe 'pipes.sh'
   alias ttyc 'tty-clock -s -t -c -D'
   alias vimn 'nix run github:onelocked/vimmax/f6b0284d888ffd443195eb817fe1ce19fea30144'
   alias ksteam 'kill -9 steam'
   alias run-nsfw-ai 'ollama run nsfw-games'
   alias stop-nsfw-ai 'ollama stop nsfw-games'

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/linuxoed/.lmstudio/bin
# End of LM Studio CLI section
