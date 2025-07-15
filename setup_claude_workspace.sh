#!/bin/bash

# Create new tmux session with 2x2 pane layout
tmux new-session -d -s claude_workspace

# Split window into 2x2 grid with equal sizes
tmux split-window -h -p 50
tmux split-window -v -p 50
tmux select-pane -t 0
tmux split-window -v -p 50

# Ensure all panes are equal size
tmux select-layout tiled

# Set pane titles and colors (eye-friendly dark backgrounds)
# CEO (top-left) - Dark purple/pink
tmux select-pane -t 0
tmux send-keys "echo 'CEO Pane'" C-m
tmux select-pane -P 'bg=#1a0d1a,fg=#dda0dd'

# Manager (top-right) - Dark orange/amber
tmux select-pane -t 1
tmux send-keys "echo 'Manager Pane'" C-m
tmux select-pane -P 'bg=#1f1611,fg=#ffb366'

# Review (bottom-left) - Dark blue
tmux select-pane -t 2
tmux send-keys "echo 'Review Pane'" C-m
tmux select-pane -P 'bg=#0f1419,fg=#87ceeb'

# Developer (bottom-right) - Dark green
tmux select-pane -t 3
tmux send-keys "echo 'Developer Pane'" C-m
tmux select-pane -P 'bg=#0d1b0d,fg=#90ee90'

# Start Claude with Sonnet model in CEO pane
tmux select-pane -t 0
tmux send-keys "claude --model sonnet" C-m
tmux send-keys "cat WorkFlow/instructions_ceo.md" C-m

# Start Claude with Sonnet model in Manager pane
tmux select-pane -t 1
tmux send-keys "claude --model sonnet" C-m
tmux send-keys "cat WorkFlow/instructions_manager.md" C-m

# Start Claude with Sonnet model in Review pane
tmux select-pane -t 2
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
tmux send-keys "cat WorkFlow/instructions_review.md" C-m

# Start Claude with Opus model in Developer pane
tmux select-pane -t 3
tmux send-keys "claude --dangerously-skip-permissions --model opus" C-m
tmux send-keys "cat WorkFlow/instructions_developer.md" C-m

# Attach to the session
tmux attach-session -t claude_workspace