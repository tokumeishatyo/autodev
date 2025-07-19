#!/bin/bash

# Create new tmux session with 3x2 grid layout for devcontainer
tmux new-session -d -s claude_workspace

# Create 3x2 grid
# First split horizontally to create 3 columns
tmux split-window -h -p 67  # Create right 1/3
tmux split-window -h -p 50  # Split left 2/3 into two halves

# Now split each column vertically
tmux select-pane -t 0
tmux split-window -v -p 50  # Split leftmost column
tmux select-pane -t 2
tmux split-window -v -p 50  # Split middle column  
tmux select-pane -t 4
tmux split-window -v -p 50  # Split rightmost column

# Final 3x2 layout:
# 0: CEO (top-left)      2: Reviewer (top-middle)     4: Progress (top-right)
# 1: Manager (bottom-left) 3: Developer (bottom-middle) 5: Usage (bottom-right)

# Set pane titles and colors (eye-friendly dark backgrounds)
# CEO (top-left) - Dark purple/pink
tmux select-pane -t 0
tmux send-keys "echo 'CEO Pane'" C-m
tmux select-pane -P 'bg=#1a0d1a,fg=#dda0dd'

# Manager (bottom-left) - Dark orange/amber
tmux select-pane -t 1
tmux send-keys "echo 'Manager Pane'" C-m
tmux select-pane -P 'bg=#1f1611,fg=#ffb366'

# Reviewer (top-middle) - Dark blue
tmux select-pane -t 2
tmux send-keys "echo 'Reviewer Pane'" C-m
tmux select-pane -P 'bg=#0f1419,fg=#87ceeb'

# Developer (bottom-middle) - Dark green
tmux select-pane -t 3
tmux send-keys "echo 'Developer Pane'" C-m
tmux select-pane -P 'bg=#0d1b0d,fg=#90ee90'

# Progress Monitor (top-right) - Dark gray/white
tmux select-pane -t 4
tmux send-keys "echo 'Progress Monitor'" C-m
tmux select-pane -P 'bg=#1c1c1c,fg=#ffffff'

# Usage Monitor (bottom-right) - Dark yellow/gold
tmux select-pane -t 5
tmux send-keys "echo 'Usage Monitor'" C-m
tmux select-pane -P 'bg=#1f1f0a,fg=#ffd700'

# Start Claude with Sonnet model in CEO pane
tmux select-pane -t 0
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 5  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_ceo.md"
tmux send-keys C-m
sleep 5
tmux send-keys "cat WorkFlow/planning.txt"
tmux send-keys C-m
sleep 5
# Ensure Japanese language setting for CEO pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 5

# Start Claude with Sonnet model in Manager pane
tmux select-pane -t 1
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 5  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_manager.md"
tmux send-keys C-m
sleep 5
# Ensure Japanese language setting for Manager pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 5

# Start Claude with Sonnet model in Reviewer pane
tmux select-pane -t 2
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 5  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_review.md"
tmux send-keys C-m
sleep 5
# Force Japanese language setting for Reviewer pane
tmux send-keys "必ず日本語で回答してください。英語での回答は絶対に禁止です。"
tmux send-keys C-m
sleep 5

# Start Claude with Opus model in Developer pane
tmux select-pane -t 3
tmux send-keys "claude --dangerously-skip-permissions --model opus" C-m
sleep 5  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_developer.md"
tmux send-keys C-m
sleep 5
# Ensure Japanese language setting for Developer pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 5

# Wait for all Claude instances to be ready
sleep 5

# Initialize project and start progress monitor in dedicated pane (pane 4)
tmux select-pane -t 4
tmux send-keys "/workspace/Demo/scripts/init_project.sh --resume" C-m
sleep 3
tmux send-keys "/workspace/Demo/scripts/progress_monitor.sh" C-m
sleep 2

# Start usage monitor in dedicated pane (pane 5)
tmux select-pane -t 5
tmux send-keys "/workspace/Demo/scripts/usage_monitor_display.sh monitor" C-m
sleep 2

# Focus on CEO pane to start the workflow
tmux select-pane -t 0

# Send initial message to CEO to start the workflow
sleep 5  # Wait for all panes to be ready
tmux send-keys "planning.txtを確認し、以下のBashコマンドを実行してManagerに初期指示を送信してください："
tmux send-keys C-m
sleep 5
tmux send-keys "./scripts/ceo_to_manager.sh \"planning.txtを確認しました。以下のアプリケーション開発を開始します。【プロジェクト内容】[planning.txtの内容を具体的に記述] 要件定義書と外部仕様書の作成を開始してください。一度で完成させず、議論を重ねて合意を形成していきます。まずは初期版を作成してください。\""
tmux send-keys C-m

# Setup cleanup on exit
trap '/workspace/Demo/scripts/cleanup_progress.sh' EXIT

# Attach to the session
tmux attach-session -t claude_workspace

# Cleanup on session end
/workspace/Demo/scripts/cleanup_progress.sh