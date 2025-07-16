#!/bin/bash

# Create new tmux session with 5 horizontal panes
tmux new-session -d -s claude_workspace

# Create 5 horizontal panes with equal width (20% each)
tmux split-window -h -p 80    # Split: [CEO | remaining 80%]
tmux split-window -h -p 75    # Split: [CEO | Manager | remaining 60%] 
tmux split-window -h -p 67    # Split: [CEO | Manager | Reviewer | remaining 40%]
tmux split-window -h -p 50    # Split: [CEO | Manager | Reviewer | Developer | Status]

# Final layout: 5 equal horizontal panes
# 0: CEO (20%)  1: Manager (20%)  2: Reviewer (20%)  3: Developer (20%)  4: Status (20%)

# Set pane titles and colors (eye-friendly dark backgrounds)
# CEO (top-left) - Dark purple/pink
tmux select-pane -t 0
tmux send-keys "echo 'CEO Pane'" C-m
tmux select-pane -P 'bg=#1a0d1a,fg=#dda0dd'

# Manager (second from left) - Dark orange/amber
tmux select-pane -t 1
tmux send-keys "echo 'Manager Pane'" C-m
tmux select-pane -P 'bg=#1f1611,fg=#ffb366'

# Reviewer (middle) - Dark blue
tmux select-pane -t 2
tmux send-keys "echo 'Reviewer Pane'" C-m
tmux select-pane -P 'bg=#0f1419,fg=#87ceeb'

# Developer (second from right) - Dark green
tmux select-pane -t 3
tmux send-keys "echo 'Developer Pane'" C-m
tmux select-pane -P 'bg=#0d1b0d,fg=#90ee90'

# Status Pane (rightmost) - Dark gray
tmux select-pane -t 4
tmux send-keys "echo '=== 📊 進捗ステータス ==='" C-m
tmux send-keys "echo '待機中...'" C-m
tmux select-pane -P 'bg=#1a1a1a,fg=#ffffff'

# Start Claude with Sonnet model in CEO pane
tmux select-pane -t 0
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 3  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_ceo.md"
tmux send-keys C-m
sleep 2
tmux send-keys "cat WorkFlow/planning.txt"
tmux send-keys C-m
sleep 2
# Ensure Japanese language setting for CEO pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 1

# Start Claude with Sonnet model in Manager pane
tmux select-pane -t 1
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 3  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_manager.md"
tmux send-keys C-m
sleep 2
# Ensure Japanese language setting for Manager pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 1

# Start Claude with Sonnet model in Reviewer pane
tmux select-pane -t 2
tmux send-keys "claude --dangerously-skip-permissions --model sonnet" C-m
sleep 3  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_review.md"
tmux send-keys C-m
sleep 2
# Force Japanese language setting for Reviewer pane
tmux send-keys "必ず日本語で回答してください。英語での回答は絶対に禁止です。"
tmux send-keys C-m
sleep 1

# Start Claude with Opus model in Developer pane
tmux select-pane -t 3
tmux send-keys "claude --dangerously-skip-permissions --model opus" C-m
sleep 3  # Wait for Claude to start properly
tmux send-keys "cat WorkFlow/instructions_developer.md"
tmux send-keys C-m
sleep 2
# Ensure Japanese language setting for Developer pane
tmux send-keys "必ず日本語で回答してください。"
tmux send-keys C-m
sleep 1

# Focus on CEO pane to start the workflow
tmux select-pane -t 0

# Send initial message to CEO to start the workflow
sleep 5  # Wait for all panes to be ready
tmux send-keys "planning.txtを確認し、以下のBashコマンドを実行してManagerに初期指示を送信してください："
tmux send-keys C-m
sleep 1
tmux send-keys "./scripts/ceo_to_manager.sh planning.txtを確認しました。以下のアプリケーション開発を開始します。【プロジェクト内容】[planning.txtの内容を具体的に記述] 要件定義書と外部仕様書の作成を開始してください。一度で完成させず、議論を重ねて合意を形成していきます。まずは初期版を作成してください。"
tmux send-keys C-m

# Setup cleanup on exit
trap '/workspace/Demo/scripts/cleanup_progress.sh' EXIT

# Attach to the session
tmux attach-session -t claude_workspace

# Cleanup on session end
/workspace/Demo/scripts/cleanup_progress.sh