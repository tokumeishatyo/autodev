#!/bin/bash

# Create new tmux session with 2x2 grid layout (original design)
tmux new-session -d -s claude_workspace

# Create standard 2x2 grid
tmux split-window -h -p 50
tmux split-window -v -p 50  
tmux select-pane -t 0
tmux split-window -v -p 50

# Final 2x2 layout:
# 0: CEO (top-left)      1: Manager (top-right)
# 2: Reviewer (bottom-left) 3: Developer (bottom-right)

# Set pane titles and colors (eye-friendly dark backgrounds)
# CEO (top-left) - Dark purple/pink
tmux select-pane -t 0
tmux send-keys "echo 'CEO Pane'" C-m
tmux select-pane -P 'bg=#1a0d1a,fg=#dda0dd'

# Manager (top-right) - Dark orange/amber
tmux select-pane -t 1
tmux send-keys "echo 'Manager Pane'" C-m
tmux select-pane -P 'bg=#1f1611,fg=#ffb366'

# Reviewer (bottom-left) - Dark blue
tmux select-pane -t 2
tmux send-keys "echo 'Reviewer Pane'" C-m
tmux select-pane -P 'bg=#0f1419,fg=#87ceeb'

# Developer (bottom-right) - Dark green
tmux select-pane -t 3
tmux send-keys "echo 'Developer Pane'" C-m
tmux select-pane -P 'bg=#0d1b0d,fg=#90ee90'

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

# Focus on CEO pane to start the workflow
tmux select-pane -t 0

# Send initial message to CEO to start the workflow
sleep 5  # Wait for all panes to be ready
tmux send-keys "planning.txtを確認し、以下のBashコマンドを実行してManagerに初期指示を送信してください："
tmux send-keys C-m
sleep 5
tmux send-keys "./scripts/ceo_to_manager.sh planning.txtを確認しました。以下のアプリケーション開発を開始します。【プロジェクト内容】[planning.txtの内容を具体的に記述] 要件定義書と外部仕様書の作成を開始してください。一度で完成させず、議論を重ねて合意を形成していきます。まずは初期版を作成してください。"
tmux send-keys C-m

# Setup cleanup on exit
trap '/workspace/Demo/scripts/cleanup_progress.sh' EXIT

# Attach to the session
tmux attach-session -t claude_workspace

# Cleanup on session end
/workspace/Demo/scripts/cleanup_progress.sh